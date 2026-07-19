#!/usr/bin/env bash
set -e

# Modelos principales:
# ornith-cline-64k
# qwen3-30b-direct:latest
# qwen3-coder-next-direct:latest
MODEL="ornith-cline-64k"

# Servidores:
# PC      = Ollama del PC grande: 192.168.1.7
# LOCAL   = Ollama del mismo equipo que ejecuta este script
# LAPTOP  = Ollama del portátil mediante su IP LAN
OLLAMA_SERVER="LOCAL"

TASK_TIMEOUT_SECONDS=10800
RETRIES=20
NODE_VERSION="22.23.1"

PROMPT="Read AGENTS.md and BENCHMARK_TASK.md completely. Inspect the current repository state, continue the unfinished task, run mvn test, fix all remaining problems, and continue until BUILD SUCCESS. Do not create, modify, rename, or delete .clineignore."
case "$OLLAMA_SERVER" in
  PC)
    OLLAMA_URL="http://192.168.1.7:11434"
    ;;
  LOCAL)
    OLLAMA_URL="http://127.0.0.1:11434"
    ;;
  LAPTOP)
    OLLAMA_URL="http://192.168.1.9:11434"
    ;;
  *)
    echo "OLLAMA_SERVER debe ser PC, LOCAL o LAPTOP." >&2
    exit 1
    ;;
esac

BASE_CONFIG_DIR="$PWD/.cline-config"
CONFIG_DIR="$PWD/.cline-runtime"
STATE_DIR="$PWD/.cline-state/${OLLAMA_SERVER,,}"

rm -rf "$CONFIG_DIR" "$STATE_DIR"
mkdir -p "$CONFIG_DIR" "$STATE_DIR"

cp "$BASE_CONFIG_DIR/"*.json "$CONFIG_DIR/"

sed -E -i \
  "s#http://[^\"/]+:11434#$OLLAMA_URL#g" \
  "$CONFIG_DIR/providers.json" \
  "$CONFIG_DIR/models.json"

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use --silent "$NODE_VERSION"

echo "[config] server=$OLLAMA_SERVER endpoint=$OLLAMA_URL"
echo "[config] model=$MODEL cwd=$PWD"
echo "[config] settings=$CONFIG_DIR state=$STATE_DIR"

echo ">>> Inicio CLINE: $(date '+%d/%m/%Y %H:%M:%S %Z')"
trap 'echo ">>> Fin CLINE:    $(date "+%d/%m/%Y %H:%M:%S %Z")"' EXIT

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

echo ">>> Fin CLINE:    $(date '+%d/%m/%Y %H:%M:%S %Z')"
