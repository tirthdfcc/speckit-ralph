#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH="" cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
  cat <<EOF
Usage: $0 [--detach] [--log PATH] [--pid PATH] <iterations>

Options:
  --detach, -d   Run in background (detached via nohup)
  --log PATH     Write stdout/stderr to PATH (detach mode only)
  --pid PATH     Write PID to PATH (detach mode only)
  --help, -h     Show this help
EOF
}

# --- Argument Parsing ---

DETACH=0
LOG_FILE=""
PID_FILE=""
ITERATIONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --detach|-d)
      DETACH=1
      shift
      ;;
    --log)
      LOG_FILE="${2:-}"
      if [[ -z "$LOG_FILE" ]]; then
        echo "ERROR: --log requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --pid)
      PID_FILE="${2:-}"
      if [[ -z "$PID_FILE" ]]; then
        echo "ERROR: --pid requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$ITERATIONS" ]]; then
        ITERATIONS="$1"
        shift
      else
        echo "ERROR: unexpected argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$ITERATIONS" ]]; then
  usage >&2
  exit 1
fi

# --- Detach Mode ---

detach_loop() {
  if ! command -v nohup >/dev/null 2>&1; then
    echo "ERROR: nohup is required for --detach mode" >&2
    exit 1
  fi

  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  LOG_FILE="${LOG_FILE:-$REPO_ROOT/logs/ralph-codex-$TIMESTAMP.log}"
  PID_FILE="${PID_FILE:-$REPO_ROOT/logs/ralph-codex.pid}"

  mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"

  nohup "$0" "$ITERATIONS" >"$LOG_FILE" 2>&1 &
  PID=$!
  echo "$PID" > "$PID_FILE"

  echo "[ralph] detached: pid $PID"
  echo "[ralph] log: $LOG_FILE"
  echo "[ralph] pid file: $PID_FILE"
  exit 0
}

if [[ "$DETACH" -eq 1 ]]; then
  detach_loop
fi

# --- Artifact Management ---

PROMISE="${RALPH_PROMISE:-COMPLETE}"
KEEP_ARTIFACTS="${RALPH_ARTIFACT_DIR:+1}"
ARTIFACT_DIR="${RALPH_ARTIFACT_DIR:-$(mktemp -d -t ralph-codex-loop.XXXXXX)}"
mkdir -p "$ARTIFACT_DIR"

cleanup_artifacts() {
  if [[ -z "$KEEP_ARTIFACTS" ]]; then
    rm -rf "$ARTIFACT_DIR"
  else
    echo "[ralph] artifacts kept at: $ARTIFACT_DIR"
  fi
}

check_promise() {
  if [[ -f "$ARTIFACT_DIR/last-message.txt" ]] && \
    grep -q "<promise>${PROMISE}</promise>" "$ARTIFACT_DIR/last-message.txt"; then
    echo "[ralph] promise detected: ${PROMISE}"
    cleanup_artifacts
    exit 0
  fi
}

# --- Main Iteration Loop ---

for ((i=1; i<=ITERATIONS; i++)); do
  echo ""
  echo "========================================"
  echo "[ralph] iteration ${i}/${ITERATIONS}"
  echo "========================================"

  RALPH_ARTIFACT_DIR="$ARTIFACT_DIR" "$SCRIPT_DIR/ralph-once-codex.sh"
  check_promise

  sleep "${RALPH_SLEEP_SECONDS:-1}"
done

echo "[ralph] max iterations reached (${ITERATIONS})"
cleanup_artifacts
