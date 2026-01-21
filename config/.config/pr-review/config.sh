#!/usr/bin/env bash
#
# PR Review Automation Configuration
# This file is sourced by pr-review-automation.sh
#

# Work directory containing git repos to scan for PRs
WORK_DIR="$HOME/work"

# Check interval in seconds (used in launchd plist, not by script directly)
CHECK_INTERVAL_SECONDS=1800  # 30 minutes

# Default Claude Code review prompt
# This prompt is passed to Claude when starting a review session
CLAUDE_REVIEW_PROMPT="Review this PR for code quality, potential bugs, security issues, and suggest improvements"

# Terminal application to use for opening review sessions
# Options: "Terminal" or "iTerm"
TERMINAL_APP="Terminal"

# Enable verbose logging (can also use --verbose flag)
# VERBOSE=true
