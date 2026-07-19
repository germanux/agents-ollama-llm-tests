#!/usr/bin/env bash
set -euo pipefail

# Ejecución directa:
#   ./configure-ollama-models.sh
# Configura todos los modelos en el Ollama local.
#
# Ejecución remota:
#   OLLAMA_HOST=http://192.168.1.7:11434 ./configure-ollama-models.sh

export OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

shopt -s nullglob
MODELFILES=("$DIR"/Modelfile-*)

if (( ${#MODELFILES[@]} == 0 )); then
  echo "[error] No se encontraron ficheros Modelfile-* en: $DIR" >&2
  exit 1
fi

ALIASES=()

for modelfile in "${MODELFILES[@]}"; do
  filename="$(basename -- "$modelfile")"
  alias="${filename#Modelfile-}"

  if [[ -z "$alias" || "$alias" == "$filename" ]]; then
    echo "[error] Nombre de Modelfile no válido: $filename" >&2
    exit 1
  fi

  echo
  echo "==> Configurando $alias"
  echo "    Modelfile: $filename"
  echo "    Ollama:    $OLLAMA_HOST"

  ollama create "$alias" -f "$modelfile"
  ALIASES+=("$alias")
done

echo
echo "Modelos configurados en $OLLAMA_HOST:"

for alias in "${ALIASES[@]}"; do
  ollama list |
    awk -v model="$alias" \
      'NR == 1 || $1 == model || $1 == model ":latest"'
done
