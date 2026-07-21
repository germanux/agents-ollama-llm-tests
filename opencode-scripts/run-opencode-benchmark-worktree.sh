#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen3-coder:30B"
CONTEXT="32K"
OUTPUT="4K"
TEMPERATURE=0.3
OLLAMA_SERVER="LP"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
BASE_BRANCH="main"
SOURCE_AGENT_REL=".opencode/agents/benchmark-pc.md"
CONFIGURE_SCRIPT_REL=".ollama-modelfiles/configure-ollama-models.sh"

HOSTNAME_SHORT="$(hostname -s)"

case "$HOSTNAME_SHORT" in
  PC-GIGA-ZORUX)
    OPENCODE_HOST="PC"
    ;;
  PC-ASUS-ZORIN)
    OPENCODE_HOST="LP"
    ;;
  *)
    echo "Host no reconocido: $HOSTNAME_SHORT" >&2
    exit 1
    ;;
esac

normalize_machine() {
  case "${1^^}" in
    PC)
      printf 'PC'
      ;;
    LP|LPT|LAPTOP)
      printf 'LP'
      ;;
    *)
      echo "OPENCODE_HOST y OLLAMA_SERVER deben ser PC o LP." >&2
      exit 1
      ;;
  esac
}

k_to_tokens() {
  local value="${1^^}"

  if [[ ! "$value" =~ ^([0-9]+)K$ ]]; then
    echo "CONTEXT y OUTPUT deben escribirse como 64K, 128K, 6K, etc." >&2
    exit 1
  fi

  printf '%s' "$((10#${BASH_REMATCH[1]} * 1024))"
}

normalize_model_name() {
  case "$MODEL" in
    qwen3-coder-next|qwen3-coder-next:*)
      printf 'qwen3-coder-next-80b'
      ;;
    qwen3-coder:30b|qwen3-coder:30b-*)
      printf 'qwen3-coder-30b'
      ;;
    *)
      printf '%s' "$MODEL" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/:latest$//; s/[^a-z0-9]+/-/g; s/^-+|-+$//g'
      ;;
  esac
}

OPENCODE_HOST="$(normalize_machine "$OPENCODE_HOST")"
OLLAMA_SERVER="$(normalize_machine "$OLLAMA_SERVER")"

CONTEXT_TOKENS="$(k_to_tokens "$CONTEXT")"
OUTPUT_TOKENS="$(k_to_tokens "$OUTPUT")"
CONTEXT_TAG="$(printf '%s' "$CONTEXT" | tr '[:upper:]' '[:lower:]')"
OUTPUT_TAG="$(printf '%s' "$OUTPUT" | tr '[:upper:]' '[:lower:]')"
MODEL_NAME="$(normalize_model_name)"

if [[ -z "$MODEL_NAME" ]]; then
  echo "No se pudo construir un nombre válido a partir de MODEL=$MODEL." >&2
  exit 1
fi

case "$OLLAMA_SERVER" in
  PC)
    PROVIDER="ollama-pc"
    PROVIDER_NAME="Ollama PC"

    if [[ "$OPENCODE_HOST" == "PC" ]]; then
      OLLAMA_URL="http://127.0.0.1:11434"
    else
      OLLAMA_URL="http://PC-GIGA-ZORUX:11434"
    fi
    ;;
  LP)
    PROVIDER="ollama-lp"
    PROVIDER_NAME="Ollama Laptop"

    if [[ "$OPENCODE_HOST" == "LP" ]]; then
      OLLAMA_URL="http://127.0.0.1:11434"
    else
      OLLAMA_URL="http://PC-ASUS-ZORIN:11434"
    fi
    ;;
esac

TEMP_TAG="t$(printf '%s' "$TEMPERATURE" | tr -d '.')"
HOST_TAG="$(printf '%s-%s' "$OPENCODE_HOST" "$OLLAMA_SERVER" | tr '[:upper:]' '[:lower:]')"
RUN_NAME="${MODEL_NAME}-${TEMP_TAG}-${CONTEXT_TAG}-${OUTPUT_TAG}-${HOST_TAG}"

ALIAS="$RUN_NAME"
BRANCH="benchmark/${RUN_NAME}"
WORKTREE_DIR="$(dirname "$REPO_ROOT")/${RUN_NAME}"
AGENT_NAME="$RUN_NAME"
AGENT_REL=".opencode/agents/${AGENT_NAME}.md"
MODELFILE_REL=".ollama-modelfiles/Modelfile-${ALIAS}"

cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "La rama main tiene cambios sin confirmar. Déjala limpia antes de ejecutar la prueba." >&2
  exit 1
fi

if ! git rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null; then
  echo "No existe la rama base $BASE_BRANCH." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Ya existe la rama $BRANCH." >&2
  exit 1
fi

if [[ -e "$WORKTREE_DIR" ]]; then
  echo "Ya existe la carpeta $WORKTREE_DIR." >&2
  exit 1
fi

# Primera modificación: crear el worktree limpio desde main.
git worktree add -b "$BRANCH" "$WORKTREE_DIR" "$BASE_BRANCH"

cd "$WORKTREE_DIR"

if [[ ! -f "$SOURCE_AGENT_REL" ]]; then
  echo "No existe el agente base $SOURCE_AGENT_REL." >&2
  exit 1
fi

if [[ ! -f "$CONFIGURE_SCRIPT_REL" ]]; then
  echo "No existe $CONFIGURE_SCRIPT_REL." >&2
  exit 1
fi

chmod +x "$CONFIGURE_SCRIPT_REL"
mkdir -p "$(dirname "$AGENT_REL")" "$(dirname "$MODELFILE_REL")"
cp "$SOURCE_AGENT_REL" "$AGENT_REL"

cat > "$MODELFILE_REL" <<EOF_MODEL
FROM $MODEL
PARAMETER num_ctx $CONTEXT_TOKENS
PARAMETER num_predict $OUTPUT_TOKENS
PARAMETER temperature $TEMPERATURE
EOF_MODEL

python3 - "$AGENT_REL" "$PROVIDER/$ALIAS" "$TEMPERATURE" "$RUN_NAME" <<'PY_AGENT'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
model = sys.argv[2]
temperature = sys.argv[3]
run_name = sys.argv[4]
text = path.read_text(encoding="utf-8")

text, count = re.subn(
    r"(?m)^model:\s*.*$",
    f"model: {model}",
    text,
    count=1,
)
if count != 1:
    raise SystemExit(f"No se encontró una línea model: en {path}")

if re.search(r"(?m)^temperature:\s*.*$", text):
    text = re.sub(
        r"(?m)^temperature:\s*.*$",
        f"temperature: {temperature}",
        text,
        count=1,
    )
else:
    text = re.sub(
        r"(?m)^(model:\s*.*)$",
        rf"\1\ntemperature: {temperature}",
        text,
        count=1,
    )

text, count = re.subn(
    r"(?m)^description:\s*.*$",
    f"description: Run benchmark {run_name}",
    text,
    count=1,
)
if count != 1:
    raise SystemExit(f"No se encontró una línea description: en {path}")

path.write_text(text, encoding="utf-8")
PY_AGENT

(
  cd .ollama-modelfiles

  OLLAMA_HOST="$OLLAMA_URL" \
  OPENCODE_PROVIDER_ID="$PROVIDER" \
  OPENCODE_PROVIDER_NAME="$PROVIDER_NAME" \
  ./configure-ollama-models.sh "$ALIAS"
)

if [[ ! -f "opencode.jsonc" ]]; then
  echo "No existe opencode.jsonc en el worktree." >&2
  exit 1
fi

python3 - "opencode.jsonc" "$PROVIDER/$ALIAS" <<'PY_JSONC'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
model = sys.argv[2]
text = path.read_text(encoding="utf-8")

for key in ("model", "small_model"):
    pattern = rf'(?m)^(\s*"{key}"\s*:\s*)"[^"]*"(\s*,?)$'
    text, count = re.subn(pattern, rf'\1"{model}"\2', text, count=1)

    if count != 1:
        raise SystemExit(f"No se encontró la clave {key} en {path}")

path.write_text(text, encoding="utf-8")
PY_JSONC

if [[ ! -f ".opencode/opencode.json" ]]; then
  echo "El configurador no generó .opencode/opencode.json." >&2
  exit 1
fi

python3 - ".opencode/opencode.json" "$PROVIDER" "$ALIAS" "$CONTEXT_TOKENS" "$OUTPUT_TOKENS" <<'PY_CATALOG'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
provider = sys.argv[2]
alias = sys.argv[3]
context = int(sys.argv[4])
output = int(sys.argv[5])

data = json.loads(path.read_text(encoding="utf-8"))
model = data.get("provider", {}).get(provider, {}).get("models", {}).get(alias)

if model is None:
    raise SystemExit(f"El catálogo no contiene {provider}/{alias}")

limit = model.get("limit", {})

if limit.get("context") != context or limit.get("output") != output:
    raise SystemExit(
        f"Límites incorrectos para {provider}/{alias}: {limit}"
    )
PY_CATALOG

git add -f \
  "$AGENT_REL" \
  "$MODELFILE_REL" \
  ".opencode/opencode.json" \
  "opencode.jsonc"

git commit -m "Configure benchmark ${RUN_NAME}"

STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG="opencode-${RUN_NAME}-${STAMP}.log"

echo "Worktree:      $WORKTREE_DIR"
echo "Rama:          $BRANCH"
echo "Agente:        $AGENT_NAME"
echo "OpenCode host: $OPENCODE_HOST"
echo "Ollama server: $OLLAMA_SERVER ($OLLAMA_URL)"
echo "Modelo:        $PROVIDER/$ALIAS"
echo "Contexto:      $CONTEXT = $CONTEXT_TOKENS tokens"
echo "Salida:        $OUTPUT = $OUTPUT_TOKENS tokens"
echo "Log:           $LOG"

npm run opencode -- \
  --print-logs \
  --log-level INFO \
  run \
  --agent "$AGENT_NAME" \
  "Start now. Read AGENTS.md and BENCHMARK_TASK.md completely and execute the benchmark autonomously." \
  2>&1 | tee "$LOG"
