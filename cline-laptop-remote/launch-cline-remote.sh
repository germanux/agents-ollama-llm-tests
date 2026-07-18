#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${AGENT_LAB_CONFIG:-$SCRIPT_DIR/agent-lab.conf}"

[[ -f "$CONFIG_FILE" ]] || { echo "Missing configuration: $CONFIG_FILE" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONFIG_FILE"

required=(PC_IP OLLAMA_PORT OLLAMA_MODEL NODE_VERSION CLINE_TASK_TIMEOUT_SECONDS CLINE_RETRIES)
for key in "${required[@]}"; do
  [[ -n "${!key:-}" ]] || { echo "Missing $key in $CONFIG_FILE" >&2; exit 2; }
done

cd "$SCRIPT_DIR"
OLLAMA_URL="http://${PC_IP}:${OLLAMA_PORT}"

JAVA_HOME_CANDIDATE="/usr/lib/jvm/java-21-openjdk-amd64"
if [[ -d "$JAVA_HOME_CANDIDATE" ]]; then
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] || { echo "nvm is not installed. Run setup-cline-laptop.sh." >&2; exit 1; }
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"
nvm use --silent "$NODE_VERSION"

CLINE_BIN="$NVM_DIR/versions/node/v${NODE_VERSION}/bin/cline"
[[ -x "$CLINE_BIN" ]] || { echo "Cline not found: $CLINE_BIN" >&2; exit 1; }

curl -fsS --max-time 10 "$OLLAMA_URL/api/tags" >/dev/null || {
  echo "Remote Ollama is unavailable: $OLLAMA_URL" >&2
  exit 1
}

if ! curl -fsS --max-time 10 "$OLLAMA_URL/api/tags" \
  | jq -e --arg model "$OLLAMA_MODEL" '
      [.models[]?.name, .models[]?.model]
      | flatten | map(select(. != null))
      | any(. == $model or . == ($model + ":latest"))
    ' >/dev/null; then
  echo "Remote model not found: $OLLAMA_MODEL" >&2
  exit 1
fi

export CLINE_SESSION_BACKEND_MODE=local
LOG_DIR="$HOME/cline-agent-logs/$(basename "$SCRIPT_DIR")"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/cline-${STAMP}.log"
START_EPOCH="$(date +%s)"

echo "Start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Ollama: $OLLAMA_URL"
echo "Model: $OLLAMA_MODEL"
echo "Expected Cline runtime context: ${EXPECTED_REMOTE_CONTEXT:-32768}"
echo "Log: $LOG_FILE"

ARGS=(
  --provider ollama
  --model "$OLLAMA_MODEL"
  --auto-approve true
  --timeout "$CLINE_TASK_TIMEOUT_SECONDS"
  --retries "$CLINE_RETRIES"
  --cwd "$PWD"
  --verbose
)

if "$CLINE_BIN" --help 2>/dev/null | grep -q -- '--thinking'; then
  ARGS+=(--thinking none)
fi

set +e
"$CLINE_BIN" "${ARGS[@]}" \
  "Read AGENTS.md and BENCHMARK_TASK.md completely and execute the task until BUILD SUCCESS. Be careful with .clineignore." \
  2>&1 | tee "$LOG_FILE"
STATUS=${PIPESTATUS[0]}
set -e

END_EPOCH="$(date +%s)"
ELAPSED=$((END_EPOCH - START_EPOCH))
echo "End: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Elapsed: ${ELAPSED}s"
echo "Exit status: $STATUS"
exit "$STATUS"
