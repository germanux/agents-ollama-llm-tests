#!/usr/bin/env bash
set -euo pipefail

# Continúa una ejecución existente en una sesión nueva de OpenCode.
# Reutiliza MODEL, CONTEXT, OUTPUT, TEMPERATURE y OLLAMA_SERVER del
# script principal, pero NO crea ni modifica la rama, el worktree,
# el alias Ollama ni el agente.
#
# Uso:
#   ./run-opencode-continue.sh
#   ./run-opencode-continue.sh ./run-opencode-benchmark-worktree.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${1:-}"

find_main_script() {
  local conventional="$SCRIPT_DIR/run-opencode-benchmark-worktree.sh"
  local candidates=()

  if [[ -f "$conventional" ]]; then
    printf '%s' "$conventional"
    return
  fi

  while IFS= read -r -d '' candidate; do
    candidates+=("$candidate")
  done < <(
    find "$SCRIPT_DIR" -maxdepth 1 -type f \
      -name 'run-opencode-benchmark-worktree*.sh' \
      -print0
  )

  if [[ "${#candidates[@]}" -eq 1 ]]; then
    printf '%s' "${candidates[0]}"
    return
  fi

  if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "No se encontró el script principal." >&2
  else
    echo "Hay varios scripts principales candidatos:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
  fi

  echo "Indícalo como primer argumento:" >&2
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
MAIN_SCRIPT_DIR="$(dirname "$MAIN_SCRIPT")"
REPO_ROOT="$(git -C "$MAIN_SCRIPT_DIR" rev-parse --show-toplevel)"

# Carga únicamente las cinco asignaciones de configuración. No ejecuta el
# script principal ni ninguna de sus acciones de creación/configuración.
CONFIG_LINES="$(
  grep -m 5 -E '^(MODEL|CONTEXT|OUTPUT|TEMPERATURE|OLLAMA_SERVER)=' "$MAIN_SCRIPT" || true
)"

for required_var in MODEL CONTEXT OUTPUT TEMPERATURE OLLAMA_SERVER; do
  if ! grep -qE "^${required_var}=" <<<"$CONFIG_LINES"; then
    echo "No se encontró ${required_var}=... en $MAIN_SCRIPT" >&2
    exit 1
  fi
done

# shellcheck disable=SC1090
source /dev/stdin <<<"$CONFIG_LINES"

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
      echo "OLLAMA_SERVER debe ser PC o LP." >&2
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

OPENCODE_HOST="$(normalize_machine "$OPENCODE_HOST")"
OLLAMA_SERVER="$(normalize_machine "$OLLAMA_SERVER")"

CONTEXT_TOKENS="$(k_to_tokens "$CONTEXT")"
OUTPUT_TOKENS="$(k_to_tokens "$OUTPUT")"
CONTEXT_TAG="$(printf '%s' "$CONTEXT" | tr '[:upper:]' '[:lower:]')"
OUTPUT_TAG="$(printf '%s' "$OUTPUT" | tr '[:upper:]' '[:lower:]')"
MODEL_NAME="$(normalize_model_name)"
TEMP_TAG="t$(printf '%s' "$TEMPERATURE" | tr -d '.')"
HOST_TAG="$(printf '%s-%s' "$OPENCODE_HOST" "$OLLAMA_SERVER" | tr '[:upper:]' '[:lower:]')"
RUN_NAME="${MODEL_NAME}-${TEMP_TAG}-${CONTEXT_TAG}-${OUTPUT_TAG}-${HOST_TAG}"

BRANCH="benchmark/${RUN_NAME}"
WORKTREE_DIR="$REPO_ROOT/agents-harness-benchmark/$RUN_NAME"
AGENT_NAME="$RUN_NAME"
AGENT_REL=".opencode/agents/${AGENT_NAME}.md"

if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "No existe el worktree que corresponde a esos parámetros:" >&2
  echo "  $WORKTREE_DIR" >&2
  echo "No se ha creado nada. Revisa los parámetros del script principal." >&2
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
  "BENCHMARK_ANGULAR.md" \
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
    echo "No existe $MAIN_NODE_MODULES; ejecuta primero setup-opencode.mjs." >&2
    exit 1
  fi

  ln -s "$MAIN_NODE_MODULES" "$WORKTREE_NODE_MODULES"
fi

if [[ ! -x "$WORKTREE_NODE_MODULES/.bin/opencode" ]]; then
  echo "No se encuentra OpenCode en:" >&2
  echo "  $WORKTREE_NODE_MODULES/.bin/opencode" >&2
  exit 1
fi

CONTINUE_PROMPT="${CONTINUE_PROMPT:-Continue from the current working tree in a fresh session. Do not recreate the branch or worktree, and do not redo completed persistence or REST phases. Read AGENTS.md, BENCHMARK_TASK.md and BENCHMARK_ANGULAR.md completely. Inspect git status, the existing Angular implementation and the latest build failure. Fix the current Angular build error, beginning with frontend/src/app/app.component.html. When using the read tool, offset and limit must be integer JSON numbers, never decimal values. Then complete Angular, frontend-backend integration, final validation and the required Git checkpoint. Run notify-success.sh only after every required build and test succeeds.}"

STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG="opencode-${RUN_NAME}-continue-${STAMP}.log"

cd "$WORKTREE_DIR"

printf '%s\n' \
  "Script base:   $MAIN_SCRIPT" \
  "Repositorio:   $REPO_ROOT" \
  "Worktree:      $WORKTREE_DIR" \
  "Rama:          $BRANCH" \
  "Agente:        $AGENT_NAME" \
  "Modelo base:   $MODEL" \
  "Contexto:      $CONTEXT = $CONTEXT_TOKENS tokens" \
  "Salida:        $OUTPUT = $OUTPUT_TOKENS tokens" \
  "Temperatura:   $TEMPERATURE" \
  "OpenCode host: $OPENCODE_HOST" \
  "Ollama server: $OLLAMA_SERVER" \
  "Log:           $LOG" \
  "" \
  "Estado actual del worktree:"

git status --short
printf '\nIniciando una sesión nueva de OpenCode sobre el worktree existente...\n\n'

npm run opencode -- \
  --print-logs \
  --log-level INFO \
  run \
  --agent "$AGENT_NAME" \
  "$CONTINUE_PROMPT" \
  2>&1 | tee "$LOG"
