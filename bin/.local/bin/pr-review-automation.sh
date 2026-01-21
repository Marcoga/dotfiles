#!/usr/bin/env bash
#
# PR Review Automation Tool
# Checks for GitHub PRs requiring review, creates worktrees and tmux sessions,
# runs Claude Code for review assistance, and sends macOS notifications.
#

set -euo pipefail

# Configuration
CONFIG_FILE="${HOME}/.config/pr-review/config.sh"
PROJECT_SCRIPTS_DIR="${HOME}/.config/pr-review/project-scripts"
STATE_DIR="${HOME}/.local/state/pr-review"
LOG_FILE="${STATE_DIR}/pr-review.log"

# Defaults (can be overridden in config)
WORK_DIR="${HOME}/work"
CLAUDE_REVIEW_PROMPT="Review this PR for code quality, potential bugs, security issues, and suggest improvements"
TERMINAL_APP="Terminal"
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: pr-review-automation.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be done without making changes"
            echo "  --verbose,-v  Enable verbose output"
            echo "  --help,-h     Show this help message"
            echo ""
            echo "Commands:"
            echo "  status        Show active review sessions"
            echo "  cleanup       Remove old worktrees and sessions"
            exit 0
            ;;
        status)
            # Show status of active review sessions
            echo "Active PR Review Sessions:"
            tmux list-sessions 2>/dev/null | grep -E "pr-[0-9]+" || echo "  No active sessions"
            exit 0
            ;;
        cleanup)
            # Cleanup old worktrees and sessions
            echo "Cleaning up PR review worktrees and sessions..."
            for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -E "pr-[0-9]+"); do
                echo "  Killing session: $session"
                tmux kill-session -t "$session" 2>/dev/null || true
            done
            # Clean up worktrees and branches in each repo
            for repo_path in "$WORK_DIR"/*/; do
                [[ -d "${repo_path}/.git" ]] || continue
                # Prune stale worktrees
                git -C "$repo_path" worktree prune 2>/dev/null
                # Delete pr-* branches
                for branch in $(git -C "$repo_path" branch --list "pr-*" 2>/dev/null | sed 's/^[* +]*//' | grep -E "^pr-[0-9]+$")
                do
                    echo "  Deleting branch: $branch in $(basename "$repo_path")"
                    git -C "$repo_path" branch -D "$branch" &>/dev/null || true
                done
            done
            # Remove any leftover worktree directories
            find "$WORK_DIR" -maxdepth 1 -type d -name "*-pr-*" 2>/dev/null | while read -r worktree; do
                echo "  Removing directory: $worktree"
                rm -rf "$worktree"
            done
            echo "Cleanup complete."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$STATE_DIR"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    if [[ "$VERBOSE" == "true" ]] || [[ "$level" == "ERROR" ]]; then
        case "$level" in
            INFO)  echo -e "${BLUE}[INFO]${NC} $message" >&2 ;;
            WARN)  echo -e "${YELLOW}[WARN]${NC} $message" >&2 ;;
            ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
            OK)    echo -e "${GREEN}[OK]${NC} $message" >&2 ;;
        esac
    fi
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log "WARN" "No configuration file found at $CONFIG_FILE, using defaults"
    fi
}

# Check required dependencies
check_dependencies() {
    local missing=()
    local optional_missing=()

    # Required dependencies
    for cmd in gh tmux git; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    # Optional in dry-run mode
    if ! command -v terminal-notifier &> /dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
            optional_missing+=("terminal-notifier")
        else
            missing+=("terminal-notifier")
        fi
    fi

    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        log "WARN" "Optional dependencies missing (ok for dry-run): ${optional_missing[*]}"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing[*]}"
        echo "Install missing dependencies:"
        echo "  brew install ${missing[*]}"
        exit 1
    fi

    # Check gh auth status
    if ! gh auth status &> /dev/null; then
        log "ERROR" "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
}

# Extract GitHub owner/repo from git remote URL
get_github_repo() {
    local repo_path="$1"
    local remote_url

    remote_url=$(git -C "$repo_path" remote get-url origin 2>/dev/null) || return 1

    # Handle both HTTPS and SSH URLs
    # https://github.com/owner/repo.git -> owner/repo
    # git@github.com:owner/repo.git -> owner/repo
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

# Check if repo should be skipped
should_skip_repo() {
    local repo_path="$1"

    # Skip if .pr-review-ignore exists
    if [[ -f "${repo_path}/.pr-review-ignore" ]]; then
        return 0
    fi

    return 1
}

# Get PRs requiring review for a repo
get_prs_for_review() {
    local github_repo="$1"

    gh pr list --repo "$github_repo" --search "review-requested:@me" --json number,headRefName,author --jq '.[] | "\(.number)|\(.headRefName)|\(.author.login)"' 2>/dev/null
}

# Create worktree for PR
create_worktree() {
    local repo_path="$1"
    local pr_number="$2"
    local branch="$3"
    local worktree_path="${repo_path}-pr-${pr_number}"

    if [[ -d "$worktree_path" ]]; then
        log "INFO" "Worktree already exists: $worktree_path"
        echo "$worktree_path"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create worktree: $worktree_path"
        echo "$worktree_path"
        return 0
    fi

    log "INFO" "Creating worktree for PR #${pr_number} at $worktree_path"

    # Prune any stale worktrees and delete existing branch if present
    git -C "$repo_path" worktree prune &>/dev/null
    git -C "$repo_path" branch -D "pr-${pr_number}" &>/dev/null || true

    # Fetch the PR branch
    if ! git -C "$repo_path" fetch origin "pull/${pr_number}/head:pr-${pr_number}" &>/dev/null; then
        log "ERROR" "Failed to fetch PR #${pr_number}"
        return 1
    fi

    # Create worktree
    if ! git -C "$repo_path" worktree add "$worktree_path" "pr-${pr_number}" &>/dev/null; then
        log "ERROR" "Failed to create worktree for PR #${pr_number}"
        return 1
    fi

    echo "$worktree_path"
}

# Load and run project-specific scripts
run_project_scripts() {
    local github_repo="$1"
    local worktree_path="$2"

    # Convert owner/repo to owner-repo for filename
    local config_name="${github_repo//\//-}.sh"
    local config_path="${PROJECT_SCRIPTS_DIR}/${config_name}"

    if [[ ! -f "$config_path" ]]; then
        log "INFO" "No project-specific config found for $github_repo"
        return 0
    fi

    log "INFO" "Loading project-specific scripts from $config_path"

    # Source the config file
    # shellcheck source=/dev/null
    source "$config_path"

    # Run defined commands
    if [[ -n "${PROJECT_COMMANDS[*]:-}" ]]; then
        for cmd in "${PROJECT_COMMANDS[@]}"; do
            log "INFO" "Running project command: $cmd"
            if [[ "$DRY_RUN" == "true" ]]; then
                log "INFO" "[DRY-RUN] Would run: $cmd"
            else
                (cd "$worktree_path" && "$cmd") || log "WARN" "Command $cmd failed"
            fi
        done
    fi
}

# Create tmux session for PR review
create_tmux_session() {
    local session_name="$1"
    local worktree_path="$2"
    local github_repo="$3"
    local pr_number="$4"

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log "INFO" "Tmux session already exists: $session_name"
        return 1  # Return 1 to indicate session already existed
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create tmux session: $session_name"
        return 0
    fi

    log "INFO" "Creating tmux session: $session_name"

    # Create detached tmux session
    tmux new-session -d -s "$session_name" -c "$worktree_path"

    # Explicitly cd into worktree (in case shell rc changes directory)
    tmux send-keys -t "$session_name" "cd '$worktree_path'" Enter

    # Run project-specific scripts in the session
    run_project_scripts "$github_repo" "$worktree_path"

    # Start Claude Code with review prompt
    local claude_cmd="claude \"/review-pr ${pr_number}\""
    tmux send-keys -t "$session_name" "$claude_cmd" Enter

    return 0  # Return 0 to indicate new session was created
}

# Send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local subtitle="$3"
    local session_name="$4"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would send notification: $title - $message ($subtitle)"
        return 0
    fi

    # Create AppleScript to attach to tmux session
    local attach_script
    attach_script=$(cat <<EOF
tell application "${TERMINAL_APP}"
    activate
    do script "tmux attach -t ${session_name}"
end tell
EOF
)

    # Encode the script for terminal-notifier
    local encoded_script
    encoded_script=$(echo "$attach_script" | base64)

    # Create a temporary script to execute on click
    local click_script="${STATE_DIR}/open-${session_name}.sh"
    mkdir -p "$STATE_DIR"
    cat > "$click_script" <<EOF
#!/usr/bin/env bash
osascript -e 'tell application "${TERMINAL_APP}"
    activate
    do script "tmux attach -t ${session_name}"
end tell'
EOF
    chmod +x "$click_script"

    terminal-notifier \
        -title "$title" \
        -message "$message" \
        -subtitle "$subtitle" \
        -sound default \
        -execute "$click_script" \
        -group "pr-review-${session_name}"

    log "OK" "Notification sent for $session_name"
}

# Process a single repository
process_repo() {
    local repo_path="$1"
    local repo_name
    repo_name=$(basename "$repo_path")

    # Check if it's a git repo
    if [[ ! -d "${repo_path}/.git" ]]; then
        log "INFO" "Skipping non-git directory: $repo_name"
        return 0
    fi

    # Check if it should be skipped
    if should_skip_repo "$repo_path"; then
        log "INFO" "Skipping repo (ignored): $repo_name"
        return 0
    fi

    # Get GitHub repo identifier
    local github_repo
    github_repo=$(get_github_repo "$repo_path") || {
        log "INFO" "Skipping non-GitHub repo: $repo_name"
        return 0
    }

    log "INFO" "Processing repo: $github_repo"

    # Get PRs requiring review
    local prs
    prs=$(get_prs_for_review "$github_repo")

    if [[ -z "$prs" ]]; then
        log "INFO" "No PRs requiring review in $github_repo"
        return 0
    fi

    # Process each PR
    while IFS='|' read -r pr_number branch author; do
        [[ -z "$pr_number" ]] && continue

        log "INFO" "Found PR #${pr_number} by @${author} (branch: $branch)"

        # Create session name: owner-repo-pr-number
        local session_name="${github_repo//\//-}-pr-${pr_number}"

        # Create worktree
        local worktree_path
        worktree_path=$(create_worktree "$repo_path" "$pr_number" "$branch") || continue

        # Create tmux session (returns 0 if new, 1 if existing)
        if create_tmux_session "$session_name" "$worktree_path" "$github_repo" "$pr_number"; then
            # Only send notification for newly created sessions
            send_notification \
                "PR Review Ready" \
                "@${author} requires your review" \
                "${github_repo} #${pr_number}" \
                "$session_name"
        fi

    done <<< "$prs"
}

# Main function
main() {
    log "INFO" "Starting PR review automation"

    check_dependencies
    load_config

    # Verify work directory exists
    if [[ ! -d "$WORK_DIR" ]]; then
        log "ERROR" "Work directory does not exist: $WORK_DIR"
        exit 1
    fi

    # Process each directory in WORK_DIR
    for repo_path in "$WORK_DIR"/*/; do
        [[ -d "$repo_path" ]] || continue
        process_repo "${repo_path%/}"
    done

    log "INFO" "PR review automation complete"
}

# Run main
main
