#!/usr/bin/env bash
set -euo pipefail

# Reanuda un benchmark dentro de su worktree existente, pero con una sesión
# nueva de OpenCode. No crea rama, worktree, alias ni agente nuevos.
#
# Uso:
#   ./opencode-scripts/run-opencode-recover-existing-worktree.sh
#   ./opencode-scripts/run-opencode-recover-existing-worktree.sh ./run-opencode-benchmark-worktree.sh
#
# Opcional:
#   RESUME_PROMPT='Prompt alternativo...' ./opencode-scripts/run-opencode-recover-existing-worktree.sh ...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
MAIN_SCRIPT="${1:-}"

find_main_script() {
  local candidates=()
  local candidate

  for candidate in \
    "$REPO_ROOT/run-opencode-benchmark-worktree.sh" \
    "$SCRIPT_DIR/run-opencode-benchmark-worktree.sh"
  do
    if [[ -f "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
  done

  shopt -s nullglob
  candidates=(
    "$REPO_ROOT"/run-opencode-benchmark-worktree*.sh
    "$SCRIPT_DIR"/run-opencode-benchmark-worktree*.sh
  )
  shopt -u nullglob

  # Elimina posibles duplicados manteniendo el orden.
  local unique=()
  local seen='|'
  for candidate in "${candidates[@]}"; do
    if [[ "$seen" != *"|$candidate|"* ]]; then
      unique+=("$candidate")
      seen+="$candidate|"
    fi
  done

  if [[ "${#unique[@]}" -eq 1 ]]; then
    printf '%s' "${unique[0]}"
    return
  fi

  if [[ "${#unique[@]}" -eq 0 ]]; then
    echo "No se encontró el script principal run-opencode-benchmark-worktree*.sh." >&2
  else
    echo "Hay varios scripts principales candidatos:" >&2
    printf '  %s\n' "${unique[@]}" >&2
  fi

  echo "Indica el script principal como primer argumento:" >&2
  echo "  $0 ./run-opencode-benchmark-worktree.sh" >&2
  exit 1
}

if [[ -z "$MAIN_SCRIPT" ]]; then
  MAIN_SCRIPT="$(find_main_script)"
fi

if [[ ! -f "$MAIN_SCRIPT" ]]; then
  echo "No existe el script principal: $MAIN_SCRIPT" >&2
  exit 1
fi

MAIN_SCRIPT="$(cd "$(dirname "$MAIN_SCRIPT")" && pwd)/$(basename "$MAIN_SCRIPT")"

# Extrae únicamente la PRIMERA asignación literal de cada parámetro.
# No hace source del script principal y, por tanto, no ejecuta sus funciones,
# sustituciones de comandos ni lógica de creación del worktree.
extract_literal_assignment() {
  local name="$1"
  local line rhs value

  line="$(awk -v key="$name" 'index($0, key "=") == 1 { print; exit }' "$MAIN_SCRIPT")"

  if [[ -z "$line" ]]; then
    echo "No se encontró ${name}=... en $MAIN_SCRIPT" >&2
    exit 1
  fi

  rhs="${line#*=}"

  if [[ "$rhs" =~ ^\"([^\"]*)\"[[:space:]]*(#.*)?$ ]]; then
    value="${BASH_REMATCH[1]}"
  elif [[ "$rhs" =~ ^([^[:space:]#]+)[[:space:]]*(#.*)?$ ]]; then
    value="${BASH_REMATCH[1]}"
  else
    echo "${name} debe tener una asignación literal simple en $MAIN_SCRIPT:" >&2
    echo "  ${name}=\"valor\"" >&2
    echo "  ${name}=valor" >&2
    echo "Línea encontrada: $line" >&2
    exit 1
  fi

  printf -v "$name" '%s' "$value"
}

for required_var in MODEL CONTEXT OUTPUT TEMPERATURE OLLAMA_SERVER; do
  extract_literal_assignment "$required_var"
done

normalize_machine() {
  case "${1^^}" in
    PC)
      printf 'PC'
      ;;
    LP|LPT|LAPTOP)
      printf 'LP'
      ;;
    *)
      echo "La máquina debe ser PC o LP; valor recibido: $1" >&2
      exit 1
      ;;
  esac
}

k_to_tokens() {
  local value="${1^^}"

  if [[ ! "$value" =~ ^([0-9]+)K$ ]]; then
    echo "CONTEXT y OUTPUT deben escribirse como 64K, 168K, 8K, etc." >&2
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

case "$(hostname -s)" in
  PC-GIGA-ZORUX)
    OPENCODE_HOST="PC"
    ;;
  PC-ASUS-ZORIN)
    OPENCODE_HOST="LP"
    ;;
  *)
    echo "Host no reconocido: $(hostname -s)" >&2
    exit 1
    ;;
esac

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

TEMP_TAG="t$(printf '%s' "$TEMPERATURE" | tr -d '.')"
HOST_TAG="$(printf '%s-%s' "$OPENCODE_HOST" "$OLLAMA_SERVER" | tr '[:upper:]' '[:lower:]')"
RUN_NAME="${MODEL_NAME}-${TEMP_TAG}-${CONTEXT_TAG}-${OUTPUT_TAG}-${HOST_TAG}"

BRANCH="benchmark/${RUN_NAME}"
WORKTREE_DIR="$REPO_ROOT/agents-harness-benchmark/$RUN_NAME"
AGENT_NAME="$RUN_NAME"
AGENT_REL=".opencode/agents/${AGENT_NAME}.md"

if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "No existe el worktree correspondiente a los parámetros del script principal:" >&2
  echo "  $WORKTREE_DIR" >&2
  exit 1
fi

if ! git -C "$WORKTREE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "La carpeta existe, pero no es un worktree Git válido:" >&2
  echo "  $WORKTREE_DIR" >&2
  exit 1
fi

ACTUAL_BRANCH="$(git -C "$WORKTREE_DIR" branch --show-current)"
if [[ "$ACTUAL_BRANCH" != "$BRANCH" ]]; then
  echo "El worktree está en una rama inesperada." >&2
  echo "  Esperada: $BRANCH" >&2
  echo "  Actual:   ${ACTUAL_BRANCH:-DETACHED}" >&2
  exit 1
fi

for required_file in \
  "$AGENT_REL" \
  "AGENTS.md" \
  "BENCHMARK_TASK.md" \
  "package.json"
do
  if [[ ! -f "$WORKTREE_DIR/$required_file" ]]; then
    echo "Falta $required_file en el worktree." >&2
    exit 1
  fi
done

command -v npm >/dev/null 2>&1 || {
  echo "No se encuentra npm en PATH." >&2
  exit 1
}

MAIN_NODE_MODULES="$REPO_ROOT/node_modules"
WORKTREE_NODE_MODULES="$WORKTREE_DIR/node_modules"

if [[ ! -e "$WORKTREE_NODE_MODULES" ]]; then
  if [[ ! -d "$MAIN_NODE_MODULES" ]]; then
    echo "No existe $MAIN_NODE_MODULES; ejecuta primero:" >&2
    echo "  node opencode-scripts/setup-opencode.mjs" >&2
    exit 1
  fi

  ln -s "$MAIN_NODE_MODULES" "$WORKTREE_NODE_MODULES"
fi

if [[ ! -x "$WORKTREE_NODE_MODULES/.bin/opencode" ]]; then
  echo "No se encuentra OpenCode en:" >&2
  echo "  $WORKTREE_NODE_MODULES/.bin/opencode" >&2
  exit 1
fi

DEFAULT_RESUME_PROMPT=$(cat <<'EOF_PROMPT'
Resume the interrupted benchmark from the current working tree in a fresh OpenCode session.
Read AGENTS.md and BENCHMARK_TASK.md completely. Inspect the existing worktree yourself using targeted commands and shallow directory listings. Do not assume which phase failed or which phases are complete. Determine the earliest incomplete, failing, or unvalidated phase from the current files, Git history, working-tree changes, and actual validation evidence. Read the BENCHMARK_*.md document required for that phase, and read later phase documents only when they become relevant.
Preserve completed, committed, and validated work. Do not redo a completed phase unless a current build or downstream validation proves that a minimal correction is required. Resume from the earliest incomplete or failing phase, validate it, create every required Git checkpoint, and continue through all remaining phases in task order.
Do not declare success from file presence alone. Run every validation required by the benchmark. Run notify-success.sh only after all required phases, builds, tests, and Git requirements succeed. Do not recreate the branch, worktree, Ollama model alias, or OpenCode agent configuration.
Limit initial reconnaissance to at most five tool calls.
Trust checkpoints for implementation progress, but never for current acceptance validation.
Run the pending phase validation early.

Browser acceptance is mandatory and must be proven in the current session.
Before running notify-success.sh:

1. Start the packaged JAR and capture its PID.
2. Wait until HTTP readiness succeeds.
3. Validate every required REST endpoint with curl -fS and record its HTTP status.
4. Fetch `/` and save the returned HTML.
5. Extract every local script src and stylesheet href from that HTML.
6. Request each extracted asset using its exact browser URL.
7. Require HTTP 200 for every HTML, JavaScript and CSS request.
8. Treat empty curl output, connection failure, timeout, 3xx, 4xx or 5xx as validation failure.
9. Stop exactly the captured PID.
10. Run notify-success.sh only if every command above exits with status 0.

Do not infer browser correctness from the build output, Git history, file presence,
JAR contents, application startup logs, or the existence of index.html.
EOF_PROMPT
)

RESUME_PROMPT="${RESUME_PROMPT:-$DEFAULT_RESUME_PROMPT}"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG="opencode-${RUN_NAME}-resume-${STAMP}.log"
RUNTIME_DIR="$WORKTREE_DIR/.opencode-runtime"
RUNTIME_REMOVED="no"

# Elimina solo el estado mutable de la sesión anterior. No toca código, commits,
# cambios sin confirmar, configuración del agente ni logs externos del worktree.
if [[ -e "$RUNTIME_DIR" ]]; then
  rm -rf -- "$RUNTIME_DIR"
  RUNTIME_REMOVED="sí"
fi

cd "$WORKTREE_DIR"

printf '%s\n' \
  "Script base:     $MAIN_SCRIPT" \
  "Repositorio:     $REPO_ROOT" \
  "Worktree:        $WORKTREE_DIR" \
  "Rama:            $BRANCH" \
  "Agente:          $AGENT_NAME" \
  "Modelo base:     $MODEL" \
  "Contexto:        $CONTEXT = $CONTEXT_TOKENS tokens" \
  "Salida:          $OUTPUT = $OUTPUT_TOKENS tokens" \
  "Temperatura:     $TEMPERATURE" \
  "OpenCode host:   $OPENCODE_HOST" \
  "Ollama server:   $OLLAMA_SERVER" \
  "Runtime borrado: $RUNTIME_REMOVED" \
  "Log:             $LOG" \
  "" \
  "Iniciando una sesión nueva sobre el worktree existente..." \
  ""

npm run opencode -- \
  --print-logs \
  --log-level INFO \
  run \
  --agent "$AGENT_NAME" \
  "$RESUME_PROMPT" \
  2>&1 | tee "$LOG"
