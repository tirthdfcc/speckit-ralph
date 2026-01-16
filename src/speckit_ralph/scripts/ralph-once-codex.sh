#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/ralph-env.sh"

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_SANDBOX="${CODEX_SANDBOX:-workspace-write}"
CODEX_APPROVAL_POLICY="${CODEX_APPROVAL_POLICY:-never}"
CODEX_EXTRA_ARGS=${CODEX_EXTRA_ARGS:-}

PROMISE="${RALPH_PROMISE:-COMPLETE}"

ARTIFACT_DIR="${RALPH_ARTIFACT_DIR:-}"

# Setup prompt and output files
if [[ -n "$ARTIFACT_DIR" ]]; then
  mkdir -p "$ARTIFACT_DIR"
  PROMPT_FILE="$ARTIFACT_DIR/prompt.md"
  LAST_MESSAGE="$ARTIFACT_DIR/last-message.txt"
  "$SCRIPT_DIR/build-prompt.sh" --output "$PROMPT_FILE" >/dev/null
else
  PROMPT_FILE="$($SCRIPT_DIR/build-prompt.sh)"
  LAST_MESSAGE="$(mktemp -t ralph-last-message.XXXXXX)"
fi

# Verify Codex CLI is available
if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  echo "ERROR: codex CLI not found (set CODEX_BIN to override)" >&2
  exit 1
fi

# Cleanup temporary files if not keeping artifacts
cleanup() {
  if [[ -z "$ARTIFACT_DIR" ]]; then
    rm -f "$PROMPT_FILE" "$LAST_MESSAGE"
  fi
}

# Allow Codex to fail without terminating script
set +e
"$CODEX_BIN" exec \
  -C "$REPO_ROOT" \
  -s "$CODEX_SANDBOX" \
  -c "approval_policy=\"$CODEX_APPROVAL_POLICY\"" \
  $CODEX_EXTRA_ARGS \
  --output-last-message "$LAST_MESSAGE" \
  < "$PROMPT_FILE"
CODEX_STATUS=$?
set -e

# Check for completion promise
if [[ -f "$LAST_MESSAGE" ]] && grep -q "<promise>${PROMISE}</promise>" "$LAST_MESSAGE"; then
  echo "[ralph] promise detected: ${PROMISE}"
  cleanup
  exit 0
fi

cleanup
exit "$CODEX_STATUS"
