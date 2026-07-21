#!/usr/bin/env bash
set -euo pipefail

# Servidor Ollama donde se crearán los aliases.
export OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"

# Identificador que tendrá el proveedor dentro de OpenCode.
OPENCODE_PROVIDER_ID="${OPENCODE_PROVIDER_ID:-ollama-local}"
OPENCODE_PROVIDER_NAME="${OPENCODE_PROVIDER_NAME:-Ollama local}"

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$DIR/.." && pwd)"

OPENCODE_DIR="$ROOT/.opencode"
OPENCODE_GENERATED_CONFIG="$OPENCODE_DIR/opencode.json"

shopt -s nullglob

MODELFILES=()

# Sin argumentos: procesa todos los Modelfile-*.
# Con argumentos: procesa solo los aliases indicados.
#
# Ejemplo:
#   ./configure-ollama-models.sh qwen3-30b-coder-16k
#
# Equivale a:
#   Modelfile-qwen3-30b-coder-16k

if (( $# > 0 )); then
  for alias in "$@"; do
    modelfile="$DIR/Modelfile-$alias"

    if [[ ! -f "$modelfile" ]]; then
      echo "[error] No existe: $modelfile" >&2
      exit 1
    fi

    MODELFILES+=("$modelfile")
  done
else
  MODELFILES=("$DIR"/Modelfile-*)
fi

if (( ${#MODELFILES[@]} == 0 )); then
  echo "[error] No se encontraron ficheros Modelfile-* en $DIR" >&2
  exit 1
fi

ALIASES=()

for modelfile in "${MODELFILES[@]}"; do
  filename="$(basename -- "$modelfile")"
  alias="${filename#Modelfile-}"

  if [[ -z "$alias" || "$alias" == "$filename" ]]; then
    echo "[error] Nombre inválido: $filename" >&2
    exit 1
  fi

  echo
  echo "==> Creando modelo"
  echo "    Alias:      $alias"
  echo "    Modelfile:  $filename"
  echo "    Ollama:     $OLLAMA_HOST"

  ollama create "$alias" -f "$modelfile"
  ALIASES+=("$alias")
done

mkdir -p "$OPENCODE_DIR"

python3 - \
  "$OPENCODE_GENERATED_CONFIG" \
  "$OLLAMA_HOST" \
  "$OPENCODE_PROVIDER_ID" \
  "$OPENCODE_PROVIDER_NAME" \
  "${MODELFILES[@]}" <<'PY'
import json
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
ollama_host = sys.argv[2].rstrip("/")
provider_id = sys.argv[3]
provider_name = sys.argv[4]
modelfiles = [Path(value) for value in sys.argv[5:]]

base_url = ollama_host
if not base_url.endswith("/v1"):
    base_url += "/v1"

if config_path.exists():
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(
            f"[error] {config_path} no contiene JSON válido: {exc}"
        )
else:
    config = {
        "$schema": "https://opencode.ai/config.json"
    }

providers = config.setdefault("provider", {})

models = {}

def read_integer_parameter(text: str, name: str):
    pattern = rf"^\s*PARAMETER\s+{re.escape(name)}\s+(\d+)\s*$"
    match = re.search(pattern, text, flags=re.MULTILINE | re.IGNORECASE)
    return int(match.group(1)) if match else None

for modelfile in sorted(modelfiles, key=lambda path: path.name):
    alias = modelfile.name.removeprefix("Modelfile-")
    text = modelfile.read_text(encoding="utf-8")

    num_ctx = read_integer_parameter(text, "num_ctx")
    num_predict = read_integer_parameter(text, "num_predict")

    model_config = {
        "name": alias,
        "temperature": True,
    }

    if (num_ctx is None) != (num_predict is None):
        missing = "num_predict" if num_predict is None else "num_ctx"
        raise SystemExit(
            f"[error] {modelfile.name}: falta PARAMETER {missing}. "
            "OpenCode exige context y output cuando se declara limit."
        )

    if num_ctx is not None and num_predict is not None:
        model_config["limit"] = {
            "context": num_ctx,
            "output": num_predict,
        }

    models[alias] = model_config

# Este proveedor queda sincronizado exactamente con los Modelfiles
# seleccionados en esta ejecución.
providers[provider_id] = {
    "npm": "@ai-sdk/openai-compatible",
    "name": provider_name,
    "options": {
        "baseURL": base_url,
        "timeout": 600000
    },
    "models": models
}

config_path.write_text(
    json.dumps(config, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8"
)

print()
print(f"[ok] Configuración OpenCode actualizada: {config_path}")
print(f"[ok] Proveedor: {provider_id}")
print(f"[ok] Endpoint:  {base_url}")

for alias in models:
    print(f"     {provider_id}/{alias}")
PY

echo
echo "Modelos disponibles en $OLLAMA_HOST:"

for alias in "${ALIASES[@]}"; do
  ollama list |
    awk -v model="$alias" \
      'NR == 1 || $1 == model || $1 == model ":latest"'
done
