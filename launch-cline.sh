#!/usr/bin/env bash
set -e

WORKTREE="$HOME/Desarrollo/agents-harness-benchmark/cline-laptop-remote-01"

MODEL="ornith-cline-64k"
NODE_VERSION="22.23.1"
CONTEXT=65536
REQUEST_TIMEOUT_MS=300000
TASK_TIMEOUT_SECONDS=10800
RETRIES=20

PROMPT="Read AGENTS.md and BENCHMARK_TASK.md completely and execute the task until BUILD SUCCESS. Do not create, modify, rename or delete .clineignore."

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use --silent "$NODE_VERSION"

cd "$WORKTREE"

CLINE_SESSION_BACKEND_MODE=local \
cline \
  -s "ollama-api-options-ctx-num=$CONTEXT,request_timeout_ms=$REQUEST_TIMEOUT_MS" \
  --provider ollama \
  --model "$MODEL" \
  --auto-approve true \
  --timeout "$TASK_TIMEOUT_SECONDS" \
  --retries "$RETRIES" \
  --cwd "$WORKTREE" \
  --verbose \
  "$PROMPT"