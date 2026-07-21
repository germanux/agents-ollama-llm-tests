#!/usr/bin/env bash
set -euo pipefail

MODEL="qwen3-coder-next:latest"
CONTEXT=65536
OUTPUT=6144
TEMPERATURE=0.1

REPO_ROOT="$(git rev-parse --show-toplevel)"
BASE_BRANCH="main"
PROVIDER="ollama-pc"
SOURCE_AGENT_REL=".opencode/agents/benchmark-pc.md"

if (( CONTEXT % 1024 != 0 || OUTPUT % 1024 != 0 )); then
  echo "CONTEXT y OUTPUT deben ser múltiplos de 1024."
  exit 1
fi

case "$MODEL" in
  qwen3-coder-next|qwen3-coder-next:*)
    MODEL_NAME="qwen3-coder-next-80b"
    ;;
  qwen3-coder:30b|qwen3-coder:30b-*)
    MODEL_NAME="qwen3-coder-30b"
    ;;
  *)
    MODEL_NAME="$(printf '%s' "$MODEL" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/:latest$//; s/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    ;;
esac

CONTEXT_K=$((CONTEXT / 1024))
OUTPUT_K=$((OUTPUT / 1024))
TEMP_TAG="t$(printf '%s' "$TEMPERATURE" | tr -d '.')"
RUN_NAME="${MODEL_NAME}-${TEMP_TAG}-${CONTEXT_K}k-out${OUTPUT_K}k"
ALIAS="$RUN_NAME"
BRANCH="benchmark/${RUN_NAME}"
WORKTREE_DIR="$(dirname "$REPO_ROOT")/${RUN_NAME}"
AGENT_NAME="$RUN_NAME"
AGENT_REL=".opencode/agents/${AGENT_NAME}.md"
MODELFILE_REL=".ollama-modelfiles/Modelfile-${ALIAS}"

cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Main tiene cambios sin confirmar. Déjalo limpio antes de crear la prueba."
  exit 1
fi

if ! git rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null; then
  echo "No existe la rama base $BASE_BRANCH."
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Ya existe la rama $BRANCH."
  exit 1
fi

if [[ -e "$WORKTREE_DIR" ]]; then
  echo "Ya existe la carpeta $WORKTREE_DIR."
  exit 1
fi

# Primera modificación: crear un worktree limpio desde main.
git worktree add -b "$BRANCH" "$WORKTREE_DIR" "$BASE_BRANCH"

cd "$WORKTREE_DIR"

if [[ ! -f "$SOURCE_AGENT_REL" ]]; then
  echo "No existe el agente base $SOURCE_AGENT_REL."
  exit 1
fi

mkdir -p "$(dirname "$AGENT_REL")" "$(dirname "$MODELFILE_REL")"
cp "$SOURCE_AGENT_REL" "$AGENT_REL"

cat > "$MODELFILE_REL" <<EOF_MODEL
FROM $MODEL
PARAMETER num_ctx $CONTEXT
PARAMETER num_predict $OUTPUT
PARAMETER temperature $TEMPERATURE
EOF_MODEL

python3 - "$AGENT_REL" "$PROVIDER/$ALIAS" "$TEMPERATURE" "$RUN_NAME" <<'PY'
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

text = re.sub(
    r"(?m)^description:\s*.*$",
    f"description: Run benchmark {run_name}",
    text,
    count=1,
)
path.write_text(text, encoding="utf-8")
PY

CONFIGURE_SCRIPT=""
if [[ -x ".ollama-modelfiles/configure-ollama-models.sh" ]]; then
  CONFIGURE_SCRIPT=".ollama-modelfiles/configure-ollama-models.sh"
elif [[ -x "configure-ollama-models.sh" ]]; then
  CONFIGURE_SCRIPT="configure-ollama-models.sh"
elif [[ -f ".ollama-modelfiles/configure-ollama-models.sh" ]]; then
  chmod +x ".ollama-modelfiles/configure-ollama-models.sh"
  CONFIGURE_SCRIPT=".ollama-modelfiles/configure-ollama-models.sh"
elif [[ -f "configure-ollama-models.sh" ]]; then
  chmod +x "configure-ollama-models.sh"
  CONFIGURE_SCRIPT="configure-ollama-models.sh"
else
  echo "No existe configure-ollama-models.sh en la raíz ni en .ollama-modelfiles/."
  exit 1
fi

if [[ "$CONFIGURE_SCRIPT" == .ollama-modelfiles/* ]]; then
  (
    cd .ollama-modelfiles
    OLLAMA_HOST="http://127.0.0.1:11434" \
    OPENCODE_PROVIDER_ID="$PROVIDER" \
    OPENCODE_PROVIDER_NAME="Ollama PC" \
    ./configure-ollama-models.sh "$ALIAS"
  )
else
  OLLAMA_HOST="http://127.0.0.1:11434" \
  OPENCODE_PROVIDER_ID="$PROVIDER" \
  OPENCODE_PROVIDER_NAME="Ollama PC" \
  ./configure-ollama-models.sh "$ALIAS"
fi

if [[ ! -f "opencode.jsonc" ]]; then
  echo "No existe opencode.jsonc en el worktree."
  exit 1
fi

python3 - "opencode.jsonc" "$PROVIDER/$ALIAS" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
model = sys.argv[2]
text = path.read_text(encoding="utf-8")

for key in ("model", "small_model"):
    pattern = rf'(?m)^(\s{{2}}"{key}"\s*:\s*)"[^"]*"(\s*,?)$'
    text, count = re.subn(pattern, rf'\1"{model}"\2', text, count=1)
    if count != 1:
        raise SystemExit(f"No se encontró la clave raíz {key} en {path}")

path.write_text(text, encoding="utf-8")
PY

if [[ ! -f ".opencode/opencode.json" ]]; then
  echo "El configurador no generó .opencode/opencode.json."
  exit 1
fi

python3 - ".opencode/opencode.json" "$PROVIDER" "$ALIAS" "$CONTEXT" "$OUTPUT" <<'PY'
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
PY

git add -f \
  "$AGENT_REL" \
  "$MODELFILE_REL" \
  ".opencode/opencode.json" \
  "opencode.jsonc"

git commit -m "Configure benchmark ${RUN_NAME}"

STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG="opencode-${RUN_NAME}-${STAMP}.log"

echo "Worktree: $WORKTREE_DIR"
echo "Rama:     $BRANCH"
echo "Agente:   $AGENT_NAME"
echo "Modelo:   $PROVIDER/$ALIAS"
echo "Log:      $LOG"

npm run opencode -- \
  --print-logs \
  --log-level INFO \
  run \
  --agent "$AGENT_NAME" \
  "Start now. Read AGENTS.md and BENCHMARK_TASK.md completely and execute the benchmark autonomously." \
  2>&1 | tee "$LOG"
