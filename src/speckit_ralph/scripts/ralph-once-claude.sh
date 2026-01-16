#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/ralph-env.sh"

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CLAUDE_EXTRA_ARGS=${CLAUDE_EXTRA_ARGS:-}

PROMISE="${RALPH_PROMISE:-COMPLETE}"

ARTIFACT_DIR="${RALPH_ARTIFACT_DIR:-}"

# Setup prompt and output files
if [[ -n "$ARTIFACT_DIR" ]]; then
  mkdir -p "$ARTIFACT_DIR"
  PROMPT_FILE="$ARTIFACT_DIR/prompt.md"
  OUTPUT_FILE="$ARTIFACT_DIR/output.txt"
  "$SCRIPT_DIR/build-prompt.sh" --output "$PROMPT_FILE" >/dev/null
else
  PROMPT_FILE="$($SCRIPT_DIR/build-prompt.sh)"
  OUTPUT_FILE="$(mktemp -t ralph-output.XXXXXX)"
fi

# Verify Claude CLI is available
if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  echo "ERROR: claude CLI not found (set CLAUDE_BIN to override)" >&2
  exit 1
fi

# Cleanup temporary files if not keeping artifacts
cleanup() {
  if [[ -z "$ARTIFACT_DIR" ]]; then
    rm -f "$PROMPT_FILE" "$OUTPUT_FILE"
  fi
}

# Allow Claude to fail without terminating script
set +e
"$CLAUDE_BIN" \
  --print \
  --dangerously-skip-permissions \
  --output-format text \
  $CLAUDE_EXTRA_ARGS \
  "$(cat "$PROMPT_FILE")" > "$OUTPUT_FILE" 2>&1
CLAUDE_STATUS=$?
set -e

# Show output for debugging
cat "$OUTPUT_FILE"

# Check for completion promise
if grep -q "<promise>${PROMISE}</promise>" "$OUTPUT_FILE"; then
  echo ""
  echo "[ralph] promise detected: ${PROMISE}"
  cleanup
  exit 0
fi

cleanup
exit "$CLAUDE_STATUS"
