#!/usr/bin/env bash
#
# Example project-specific commands for PR Review Automation
#
# To use this for your project:
# 1. Copy this file and rename it to match your GitHub repo
#    For example: mycompany-myrepo.sh (owner-repo format, slash replaced with dash)
# 2. Define the functions you want to run
# 3. List them in PROJECT_COMMANDS array
#
# These commands run in the worktree directory before Claude Code starts.
#

# Run TypeScript compiler (check for type errors)
run_tsc() {
    if [[ -f "tsconfig.json" ]]; then
        echo "Running TypeScript compiler..."
        npx tsc --noEmit 2>&1 || true
    fi
}

# Run ESLint
run_lint() {
    if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
        echo "Running linter..."
        npm run lint 2>&1 || true
    fi
}

# Run tests
run_tests() {
    if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
        echo "Running tests..."
        npm test 2>&1 || true
    fi
}

# Install dependencies
run_install() {
    if [[ -f "package-lock.json" ]]; then
        echo "Installing dependencies..."
        npm ci 2>&1 || true
    elif [[ -f "yarn.lock" ]]; then
        echo "Installing dependencies..."
        yarn install --frozen-lockfile 2>&1 || true
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Installing dependencies..."
        pnpm install --frozen-lockfile 2>&1 || true
    fi
}

# Rust: Run cargo check
run_cargo_check() {
    if [[ -f "Cargo.toml" ]]; then
        echo "Running cargo check..."
        cargo check 2>&1 || true
    fi
}

# Go: Run go vet
run_go_vet() {
    if [[ -f "go.mod" ]]; then
        echo "Running go vet..."
        go vet ./... 2>&1 || true
    fi
}

# Python: Run type checking
run_mypy() {
    if [[ -f "pyproject.toml" ]] || [[ -f "mypy.ini" ]]; then
        echo "Running mypy..."
        mypy . 2>&1 || true
    fi
}

# Define which commands to run (executed in order)
# Comment out or remove commands you don't need
PROJECT_COMMANDS=(
    # "run_install"
    # "run_tsc"
    # "run_lint"
    # "run_tests"
    # "run_cargo_check"
    # "run_go_vet"
    # "run_mypy"
)
