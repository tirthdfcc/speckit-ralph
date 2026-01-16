#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Path Resolution
# =============================================================================

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"
COMMON_SCRIPT="$REPO_ROOT/.specify/scripts/bash/common.sh"

# =============================================================================
# Helper Functions
# =============================================================================

# Validates that a required file exists, exits with helpful message if not
# Arguments:
#   $1 - file path to check
#   $2 - file description for error message
#   $3 - suggestion command to run
require_file() {
  local file_path="$1"
  local description="$2"
  local suggestion="$3"

  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: $description not found at $file_path" >&2
    echo "Run $suggestion first." >&2
    exit 1
  fi
}

# Extracts repository slug (owner/repo) from git remote URL
# Supports both SSH and HTTPS GitHub URLs
# Sets: REPO_REMOTE_URL, REPO_SLUG
extract_repo_slug() {
  REPO_REMOTE_URL=""
  REPO_SLUG=""

  if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  if ! git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1; then
    return
  fi

  REPO_REMOTE_URL="$(git -C "$REPO_ROOT" remote get-url origin)"

  case "$REPO_REMOTE_URL" in
    git@github.com:*)
      REPO_SLUG="${REPO_REMOTE_URL#git@github.com:}"
      REPO_SLUG="${REPO_SLUG%.git}"
      ;;
    https://github.com/*)
      REPO_SLUG="${REPO_REMOTE_URL#https://github.com/}"
      REPO_SLUG="${REPO_SLUG%.git}"
      ;;
  esac
}

# =============================================================================
# Load Common Utilities
# =============================================================================

require_file "$COMMON_SCRIPT" ".specify common script" "speckit setup"

# shellcheck source=/dev/null
source "$COMMON_SCRIPT"

eval "$(get_feature_paths)"

# =============================================================================
# Branch Validation
# =============================================================================

if [[ "${RALPH_SKIP_BRANCH_CHECK:-}" != "1" ]]; then
  check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" || exit 1
fi

# =============================================================================
# Required Files Validation
# =============================================================================

require_file "$IMPL_PLAN" "plan.md" "/speckit.plan"
require_file "$FEATURE_SPEC" "spec.md" "/speckit.specify"
require_file "$TASKS" "tasks.md" "/speckit.tasks"

# =============================================================================
# Progress File Setup
# =============================================================================

PROGRESS_FILE_DEFAULT="$FEATURE_DIR/progress.txt"
PROGRESS_FILE="${RALPH_PROGRESS_FILE:-$PROGRESS_FILE_DEFAULT}"

if [[ ! -f "$PROGRESS_FILE" ]]; then
  cat <<'HEADER' > "$PROGRESS_FILE"
# Ralph Progress Log
#
# Append entries after each completed task:
# - Task ID and description
# - Decisions and rationale
# - Files changed
# - Tests run and results
# - Blockers/notes
HEADER
fi

# =============================================================================
# Repository Information
# =============================================================================

extract_repo_slug

# =============================================================================
# Export Environment Variables
# =============================================================================

export REPO_ROOT
export CURRENT_BRANCH
export FEATURE_DIR
export FEATURE_SPEC
export IMPL_PLAN
export TASKS
export RESEARCH
export DATA_MODEL
export QUICKSTART
export CONTRACTS_DIR
export PROGRESS_FILE
export REPO_REMOTE_URL
export REPO_SLUG
