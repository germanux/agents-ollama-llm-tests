#!/usr/bin/env bash
set -e

MODEL="ornith-cline-64k"
NODE_VERSION="22.23.1"

TASK_TIMEOUT_SECONDS=10800
RETRIES=20

PROMPT="Read AGENTS.md and BENCHMARK_TASK.md completely. Inspect the current repository state, continue the unfinished task, run mvn test, fix all remaining problems, and continue until BUILD SUCCESS. Do not create, modify, rename, or delete .clineignore."

CONFIG_DIR="$PWD/.cline-config"
STATE_DIR="$PWD/.cline-state"

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use --silent "$NODE_VERSION"

echo "[config] endpoint=http://192.168.1.7:11434 model=$MODEL cwd=$PWD"
echo "[config] settings=$CONFIG_DIR state=$STATE_DIR"

CLINE_SESSION_BACKEND_MODE=local \
cline \
  --config "$CONFIG_DIR" \
  --data-dir "$STATE_DIR" \
  --provider ollama \
  --model "$MODEL" \
  --thinking none \
  --auto-approve true \
  --timeout "$TASK_TIMEOUT_SECONDS" \
  --retries "$RETRIES" \
  --cwd "$PWD" \
  --verbose \
  "$PROMPT"
