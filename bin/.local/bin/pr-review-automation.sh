#!/usr/bin/env bash
#
# PR Review Automation Tool
# Syncs PRs to Obsidian notes, creates worktrees and tmux sessions,
# runs Claude Code for review assistance (only when needed), and sends macOS notifications.
#

set -euo pipefail

# Configuration
CONFIG_FILE="${HOME}/.config/pr-review/config.sh"
PROJECT_SCRIPTS_DIR="${HOME}/.config/pr-review/project-scripts"
STATE_DIR="${HOME}/.local/state/pr-review"
LOG_FILE="${STATE_DIR}/pr-review.log"
VAULT_PATH="${HOME}/obsidian-vault"

# Defaults (can be overridden in config)
WORK_DIR="${HOME}/work"
CLAUDE_REVIEW_PROMPT="Review this PR for code quality, potential bugs, security issues, and suggest improvements"
TERMINAL_APP="iTerm"
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
            # Remove any leftover worktree directories (old structure: ~/work/*-pr-*)
            find "$WORK_DIR" -maxdepth 1 -type d -name "*-pr-*" 2>/dev/null | while read -r worktree; do
                echo "  Removing directory: $worktree"
                rm -rf "$worktree"
            done
            # Remove any leftover worktree directories (new structure: ~/work/*/pr-*)
            find "$WORK_DIR" -maxdepth 2 -type d -name "pr-*" 2>/dev/null | while read -r worktree; do
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

    gh pr list --repo "$github_repo" --search "review-requested:@me" --json number,headRefName,author --jq '.[] | "\(.number)|\(.headRefName)|\(.author.login)|review"' 2>/dev/null
}

# Get PRs authored by me for a repo
get_authored_prs() {
    local github_repo="$1"

    gh pr list --repo "$github_repo" --author "@me" --state open --json number,headRefName,author --jq '.[] | "\(.number)|\(.headRefName)|\(.author.login)|authored"' 2>/dev/null
}

# Sync/create Obsidian note for a PR
sync_obsidian_note() {
    local github_repo="$1"
    local pr_number="$2"
    local branch="$3"
    local author="$4"
    local pr_type="$5"

    local repo_name="${github_repo#*/}"
    local note_dir="$VAULT_PATH/PRs"
    [[ "$pr_type" == "authored" ]] && note_dir="$VAULT_PATH/PRs/authored"
    [[ "$pr_type" == "review" ]] && note_dir="$VAULT_PATH/PRs/reviews"

    mkdir -p "$note_dir"
    local note_file="$note_dir/pr-${pr_number}.md"

    # Get PR details from GitHub
    local pr_json
    pr_json=$(gh pr view "$pr_number" --repo "$github_repo" --json title,url,updatedAt,isDraft 2>/dev/null) || return 1

    local title url updated draft
    title=$(echo "$pr_json" | jq -r '.title')
    url=$(echo "$pr_json" | jq -r '.url')
    updated=$(echo "$pr_json" | jq -r '.updatedAt | split("T")[0]')
    draft=$(echo "$pr_json" | jq -r '.isDraft')

    if [[ ! -f "$note_file" ]]; then
        log "INFO" "Creating Obsidian note: $note_file"

        local draft_line=""
        [[ "$draft" == "true" ]] && draft_line=$'\ndraft: true'

        local author_line=""
        [[ -n "$author" ]] && author_line=$'\nauthor: '"$author"

        cat > "$note_file" << EOF
---
pr_number: $pr_number
title: "$title"
repo: $repo_name
url: $url
status: open${draft_line}
type: $pr_type
branch: $branch${author_line}
created: $(date +%Y-%m-%d)
updated: $updated
claude_last_review:
labels: []
reviewers: []
my_review_status: pending
---

# PR #$pr_number: $title

## Quick Actions
- [Open in GitHub]($url)

## Summary

## My Notes

## Claude Sessions

## Review Comments

## Checklist
- [ ] Code reviewed
- [ ] Tests passing
- [ ] Conflicts resolved
- [ ] Ready to merge
EOF
    else
        # Update existing note
        sed -i '' "s/^updated: .*/updated: $updated/" "$note_file"
        if [[ "$draft" == "true" ]]; then
            grep -q "^draft:" "$note_file" || sed -i '' "/^status:/a\\
draft: true" "$note_file"
        else
            sed -i '' "/^draft: true/d" "$note_file"
        fi
        log "INFO" "Updated Obsidian note: $note_file"
    fi

    echo "$note_file"
}

# Get the last commit date for a PR
get_pr_last_commit_date() {
    local github_repo="$1"
    local pr_number="$2"

    # Get the last commit date from the PR
    local commit_date
    commit_date=$(gh pr view "$pr_number" --repo "$github_repo" --json commits --jq '.commits[-1].committedDate' 2>/dev/null) || return 1

    # Convert to timestamp for comparison
    if [[ -n "$commit_date" ]]; then
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$commit_date" "+%s" 2>/dev/null || \
        date -j -f "%Y-%m-%dT%H:%M:%S" "${commit_date%Z}" "+%s" 2>/dev/null || \
        echo "0"
    else
        echo "0"
    fi
}

# Get the claude_last_review timestamp from Obsidian note
get_claude_last_review() {
    local note_file="$1"

    if [[ ! -f "$note_file" ]]; then
        echo "0"
        return
    fi

    local review_date
    review_date=$(grep "^claude_last_review:" "$note_file" | sed 's/^claude_last_review: *//')

    if [[ -z "$review_date" || "$review_date" == "null" ]]; then
        echo "0"
        return
    fi

    # Convert to timestamp
    date -j -f "%Y-%m-%dT%H:%M:%S" "$review_date" "+%s" 2>/dev/null || echo "0"
}

# Update claude_last_review in Obsidian note
update_claude_review_timestamp() {
    local note_file="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%dT%H:%M:%S")

    if [[ -f "$note_file" ]]; then
        # Check if field exists
        if grep -q "^claude_last_review:" "$note_file"; then
            sed -i '' "s/^claude_last_review:.*/claude_last_review: $timestamp/" "$note_file"
        else
            # Add field after updated: line
            sed -i '' "/^updated:/a\\
claude_last_review: $timestamp" "$note_file"
        fi
        log "INFO" "Updated claude_last_review in $note_file"
    fi
}

# Append Claude review output to Obsidian note
append_claude_review_to_note() {
    local note_file="$1"
    local review_output="$2"
    local pr_number="$3"

    if [[ ! -f "$note_file" ]]; then
        log "WARN" "Note file not found: $note_file"
        return 1
    fi

    # Use append-to-note.sh for consistent append behavior
    echo "$review_output" | ~/scripts/append-to-note.sh "$note_file" "## Claude Sessions" -

    log "INFO" "Appended Claude review to $note_file"
}

# Check if Claude review is needed (new commits since last review)
needs_claude_review() {
    local github_repo="$1"
    local pr_number="$2"
    local note_file="$3"

    local last_commit_ts last_review_ts
    last_commit_ts=$(get_pr_last_commit_date "$github_repo" "$pr_number")
    last_review_ts=$(get_claude_last_review "$note_file")

    log "INFO" "PR #${pr_number}: last_commit=$last_commit_ts, last_review=$last_review_ts"

    # If never reviewed or new commits since last review
    if [[ "$last_review_ts" == "0" ]] || [[ "$last_commit_ts" -gt "$last_review_ts" ]]; then
        return 0  # true - needs review
    fi

    return 1  # false - no review needed
}

# Create worktree for PR
create_worktree() {
    local repo_path="$1"
    local pr_number="$2"
    local branch="$3"
    local repo_name
    repo_name=$(basename "$repo_path")
    # For repos in new structure (e.g., ~/work/i360/main), use parent dir
    # For repos in old structure (e.g., ~/work/other-repo), use sibling
    local parent_dir
    parent_dir=$(dirname "$repo_path")
    local parent_name
    parent_name=$(basename "$parent_dir")
    local worktree_path
    if [[ "$repo_name" == "main" ]]; then
        # New structure: ~/work/i360/main -> ~/work/i360/pr-{number}
        worktree_path="${parent_dir}/pr-${pr_number}"
    else
        # Old structure: ~/work/repo -> ~/work/repo-pr-{number}
        worktree_path="${repo_path}-pr-${pr_number}"
    fi

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
# Returns: 0 = new session created, 1 = session already existed, 2 = new session but no claude needed
create_tmux_session() {
    local session_name="$1"
    local worktree_path="$2"
    local github_repo="$3"
    local pr_number="$4"
    local run_claude="$5"  # "true" or "false"
    local note_file="$6"

    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log "INFO" "Tmux session already exists: $session_name"
        return 1  # Return 1 to indicate session already existed
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create tmux session: $session_name (run_claude=$run_claude)"
        return 0
    fi

    log "INFO" "Creating tmux session: $session_name"

    # Create detached tmux session
    tmux new-session -d -s "$session_name" -c "$worktree_path"

    # Wait for shell to initialize (nvm, etc.)
    sleep 2

    # Explicitly cd into worktree (in case shell rc changes directory)
    tmux send-keys -t "$session_name" "cd '$worktree_path'" Enter

    # Run project-specific scripts in the session
    run_project_scripts "$github_repo" "$worktree_path"

    # Wait for cd to complete before sending claude command
    sleep 1

    if [[ "$run_claude" == "true" ]]; then
        # Run the review script that captures output and appends to note
        tmux send-keys -t "$session_name" "~/scripts/run-claude-review.sh '${worktree_path}' '${pr_number}' '${note_file}'" Enter

        # Update the Obsidian note with review timestamp
        update_claude_review_timestamp "$note_file"

        return 0  # Return 0 to indicate new session with claude
    else
        log "INFO" "Skipping Claude review (no new commits since last review)"
        return 2  # Return 2 to indicate new session without claude
    fi
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

    # Create a temporary script to execute on click
    local click_script="${STATE_DIR}/open-${session_name}.sh"
    mkdir -p "$STATE_DIR"
    cat > "$click_script" <<EOF
#!/usr/bin/env bash
osascript -e 'tell application "${TERMINAL_APP}"
    activate
    create window with default profile command "tmux attach -t ${session_name}"
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

    # Get PRs requiring review and authored PRs
    local review_prs authored_prs all_prs
    review_prs=$(get_prs_for_review "$github_repo")
    authored_prs=$(get_authored_prs "$github_repo")

    # Combine both lists (authored PRs may overlap with review PRs, dedup by PR number)
    all_prs=$(echo -e "${review_prs}\n${authored_prs}" | sort -t'|' -k1,1 -u | grep -v '^$' || true)

    if [[ -z "$all_prs" ]]; then
        log "INFO" "No PRs to process in $github_repo"
        return 0
    fi

    # Process each PR
    while IFS='|' read -r pr_number branch author pr_type; do
        [[ -z "$pr_number" ]] && continue

        log "INFO" "Found PR #${pr_number} by @${author} (branch: $branch, type: $pr_type)"

        # Sync/create Obsidian note
        local note_file
        note_file=$(sync_obsidian_note "$github_repo" "$pr_number" "$branch" "$author" "$pr_type") || {
            log "WARN" "Failed to sync Obsidian note for PR #${pr_number}"
            continue
        }

        # Create session name: owner-repo-pr-number
        local session_name="${github_repo//\//-}-pr-${pr_number}"

        # Create worktree
        local worktree_path
        worktree_path=$(create_worktree "$repo_path" "$pr_number" "$branch") || continue

        # Check if Claude review is needed
        local run_claude="false"
        if needs_claude_review "$github_repo" "$pr_number" "$note_file"; then
            run_claude="true"
            log "INFO" "Claude review needed for PR #${pr_number} (new commits)"
        else
            log "INFO" "Claude review not needed for PR #${pr_number} (no new commits)"
        fi

        # Create tmux session (returns 0 if new with claude, 1 if existing, 2 if new without claude)
        local session_result=0
        create_tmux_session "$session_name" "$worktree_path" "$github_repo" "$pr_number" "$run_claude" "$note_file" || session_result=$?

        if [[ $session_result -eq 0 ]]; then
            # New session with Claude review
            if [[ "$pr_type" == "review" ]]; then
                send_notification \
                    "PR Review Ready" \
                    "@${author} requires your review (Claude reviewing)" \
                    "${github_repo} #${pr_number}" \
                    "$session_name"
            else
                send_notification \
                    "PR Session Ready" \
                    "Your PR #${pr_number} is ready (Claude reviewing)" \
                    "${github_repo}" \
                    "$session_name"
            fi
        elif [[ $session_result -eq 2 ]]; then
            # New session without Claude review
            if [[ "$pr_type" == "review" ]]; then
                send_notification \
                    "PR Review Ready" \
                    "@${author} requires your review" \
                    "${github_repo} #${pr_number}" \
                    "$session_name"
            else
                send_notification \
                    "PR Session Ready" \
                    "Your PR #${pr_number} is ready" \
                    "${github_repo}" \
                    "$session_name"
            fi
        fi
        # session_result == 1 means session already existed, no notification

    done <<< "$all_prs"
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
        repo_path="${repo_path%/}"

        # Check for new structure: ~/work/repo/main/
        if [[ -d "${repo_path}/main/.git" ]]; then
            process_repo "${repo_path}/main"
        elif [[ -d "${repo_path}/.git" ]]; then
            # Old structure: ~/work/repo/
            process_repo "$repo_path"
        fi
    done

    # Sync Obsidian notes with GitHub PR status
    log "INFO" "Syncing Obsidian notes with GitHub..."
    if [[ -x "${HOME}/scripts/sync-prs-to-obsidian.sh" ]]; then
        "${HOME}/scripts/sync-prs-to-obsidian.sh" >/dev/null 2>&1 || log "WARN" "PR sync script failed"
    fi

    log "INFO" "PR review automation complete"
}

# Run main
main
