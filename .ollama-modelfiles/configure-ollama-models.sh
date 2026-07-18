#!/usr/bin/env bash
set -euo pipefail

# Por defecto, configura los modelos en el Ollama del PC.
# Para usar otro servidor, ejecuta:
# OLLAMA_HOST=http://127.0.0.1:11434 ./configure-ollama-models.sh
export OLLAMA_HOST="${OLLAMA_HOST:-http://192.168.1.7:11434}"

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ollama create ornith-cline-64k   -f "$DIR/Modelfile.ornith-cline-64k"

ollama create qwen3-30b-direct   -f "$DIR/Modelfile-qwen3-30b-direct"

ollama create qwen3-coder-next-direct   -f "$DIR/Modelfile-qwen3-coder-next-direct"

echo
echo "Modelos configurados en $OLLAMA_HOST:"
ollama list | grep -E 'ornith-cline-64k|qwen3-30b-direct|qwen3-coder-next-direct' || true
