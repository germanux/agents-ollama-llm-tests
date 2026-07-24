#!/usr/bin/env bash
set -Eeuo pipefail

# setup-codegraph-opencode.sh
#
# Installs/wires CodeGraph into OpenCode and initializes the CodeGraph index
# for the current Git worktree or every worktree of the repository.
#
# Intended location in the repository:
#   scripts/setup-codegraph-opencode.sh
#
# Recommended first use from the main worktree:
#   chmod +x scripts/setup-codegraph-opencode.sh
#   scripts/setup-codegraph-opencode.sh all
#
# Then initialize all existing worktrees:
#   scripts/setup-codegraph-opencode.sh all-worktrees
#
# CodeGraph's MCP server is launched by OpenCode itself. Do not run
# `codegraph serve --mcp` manually as a background daemon.

PROGRAM="${0##*/}"
MODE="${1:-all}"

# User-overridable settings.
CODEGRAPH_VERSION="${CODEGRAPH_VERSION:-latest}"
NODE_VERSION="${NODE_VERSION:-22.23.1}"
INSTALL_METHOD="${INSTALL_METHOD:-npm}"   # npm | standalone
UPGRADE="${UPGRADE:-0}"                   # 1 = upgrade even when installed
TRACK_GITIGNORE="${TRACK_GITIGNORE:-0}"   # 1 = also modify repository .gitignore
CODEGRAPH_NO_DAEMON="${CODEGRAPH_NO_DAEMON:-0}"

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

on_error() {
  local rc=$?
  printf '\033[1;31m[ERROR]\033[0m Command failed at line %s: %s\n' \
    "${BASH_LINENO[0]:-?}" "${BASH_COMMAND:-?}" >&2
  exit "$rc"
}
trap on_error ERR

usage() {
  cat <<'EOF'
Usage:
  setup-codegraph-opencode.sh all
      Install CodeGraph if needed, wire it globally to OpenCode,
      initialize the current worktree and verify the connection.

  setup-codegraph-opencode.sh install
      Install/verify CodeGraph and wire the global OpenCode MCP config.

  setup-codegraph-opencode.sh init
      Initialize or synchronize only the current worktree.

  setup-codegraph-opencode.sh verify
      Verify CodeGraph status and the OpenCode MCP registration.

  setup-codegraph-opencode.sh all-worktrees
      Install/wire globally, then initialize or synchronize every Git worktree.

  setup-codegraph-opencode.sh status-worktrees
      Show CodeGraph status for every Git worktree.

Environment variables:
  CODEGRAPH_VERSION=latest   npm version or tag to install.
  NODE_VERSION=22.23.1       NVM Node version to activate when available.
  INSTALL_METHOD=npm         npm or standalone.
  UPGRADE=1                  Upgrade an existing CodeGraph installation.
  TRACK_GITIGNORE=1          Also add /.codegraph/ to tracked .gitignore.
  CODEGRAPH_NO_DAEMON=1      Configure verification with daemon disabled.

Examples:
  scripts/setup-codegraph-opencode.sh all
  scripts/setup-codegraph-opencode.sh all-worktrees
  UPGRADE=1 scripts/setup-codegraph-opencode.sh install
EOF
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

activate_node() {
  if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    if nvm version "$NODE_VERSION" >/dev/null 2>&1; then
      nvm use --silent "$NODE_VERSION" >/dev/null
      log "Using Node $(node --version) through NVM."
    else
      warn "NVM does not contain Node $NODE_VERSION; using the current Node."
    fi
  fi
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null ||
    die "Run this script inside a Git worktree."
}

git_common_dir() {
  local root="$1"
  git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null ||
    git -C "$root" rev-parse --git-common-dir
}

ensure_local_index_ignored() {
  local root="$1"
  local common_dir exclude_file

  common_dir="$(git_common_dir "$root")"
  [[ "$common_dir" = /* ]] || common_dir="$root/$common_dir"
  exclude_file="$common_dir/info/exclude"

  mkdir -p "$(dirname "$exclude_file")"
  touch "$exclude_file"

  if ! grep -qxF '/.codegraph/' "$exclude_file"; then
    {
      printf '\n# Local CodeGraph index; generated per Git worktree.\n'
      printf '/.codegraph/\n'
      printf '/.codegraph-*/\n'
    } >> "$exclude_file"
    log "Added .codegraph exclusions to shared Git info/exclude."
  fi

  if [[ "$TRACK_GITIGNORE" == "1" ]]; then
    local tracked_ignore="$root/.gitignore"
    touch "$tracked_ignore"
    if ! grep -qxF '/.codegraph/' "$tracked_ignore"; then
      {
        printf '\n# Local CodeGraph index; generated per worktree.\n'
        printf '/.codegraph/\n'
        printf '/.codegraph-*/\n'
      } >> "$tracked_ignore"
      log "Updated tracked .gitignore. Review and commit this change on main."
    fi
  fi
}

install_codegraph() {
  activate_node

  if command -v codegraph >/dev/null 2>&1 && [[ "$UPGRADE" != "1" ]]; then
    log "CodeGraph already installed: $(codegraph version 2>/dev/null || codegraph --version)"
    return
  fi

  case "$INSTALL_METHOD" in
    npm)
      require_command npm
      log "Installing CodeGraph via npm: @colbymchenry/codegraph@$CODEGRAPH_VERSION"
      npm install -g "@colbymchenry/codegraph@${CODEGRAPH_VERSION}"
      ;;
    standalone)
      require_command curl
      log "Installing the official standalone CodeGraph bundle."
      local installer
      installer="$(mktemp)"
      curl -fsSL \
        https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh \
        -o "$installer"
      log "Downloaded installer to $installer. Executing the official installer."
      sh "$installer"
      rm -f "$installer"
      ;;
    *)
      die "Unsupported INSTALL_METHOD=$INSTALL_METHOD. Use npm or standalone."
      ;;
  esac

  # NPM under NVM may have changed PATH after installation.
  hash -r
  command -v codegraph >/dev/null 2>&1 ||
    die "CodeGraph was installed but is not available on PATH."

  log "Installed CodeGraph: $(codegraph version 2>/dev/null || codegraph --version)"
}

wire_opencode_global() {
  require_command codegraph

  log "Wiring CodeGraph into the global OpenCode MCP configuration."
  codegraph install \
    --target=opencode \
    --location=global \
    --yes

  log "CodeGraph installer completed for OpenCode."
}

find_opencode_command() {
  local root="$1"

  if command -v opencode >/dev/null 2>&1; then
    printf '%s\0' "opencode"
    return 0
  fi

  if [[ -x "$root/node_modules/.bin/opencode" ]]; then
    printf '%s\0' "$root/node_modules/.bin/opencode"
    return 0
  fi

  if [[ -f "$root/package.json" ]] &&
     command -v node >/dev/null 2>&1 &&
     node -e '
       const p=require(process.argv[1]);
       process.exit(p.scripts && p.scripts.opencode ? 0 : 1)
     ' "$root/package.json" >/dev/null 2>&1; then
    printf '%s\0%s\0%s\0%s\0%s\0' \
      "npm" "run" "--silent" "opencode" "--"
    return 0
  fi

  return 1
}

run_opencode() {
  local root="$1"
  shift
  local -a cmd=()

  while IFS= read -r -d '' part; do
    cmd+=("$part")
  done < <(find_opencode_command "$root" || true)

  if (( ${#cmd[@]} == 0 )); then
    return 127
  fi

  (
    cd "$root"
    "${cmd[@]}" "$@"
  )
}

config_contains_codegraph() {
  local root="$1"
  local -a candidates=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.jsonc"
    "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
    "$root/opencode.jsonc"
    "$root/opencode.json"
  )

  if [[ -n "${OPENCODE_CONFIG:-}" ]]; then
    candidates+=("$OPENCODE_CONFIG")
  fi

  local file
  for file in "${candidates[@]}"; do
    if [[ -f "$file" ]] && grep -qi '"codegraph"' "$file"; then
      log "CodeGraph MCP entry found in: $file"
      return 0
    fi
  done

  return 1
}

verify_opencode_mcp() {
  local root="$1"
  local listed=0

  if run_opencode "$root" mcp list >"/tmp/opencode-mcp-list.$$" 2>&1; then
    cat "/tmp/opencode-mcp-list.$$"
    if grep -qi 'codegraph' "/tmp/opencode-mcp-list.$$"; then
      listed=1
      log "OpenCode reports the CodeGraph MCP server."
    else
      warn "OpenCode mcp list did not contain CodeGraph."
    fi
  else
    warn "Could not execute 'opencode mcp list' using the detected launcher."
    cat "/tmp/opencode-mcp-list.$$" 2>/dev/null || true
  fi
  rm -f "/tmp/opencode-mcp-list.$$"

  if [[ "$listed" == "1" ]]; then
    return 0
  fi

  if config_contains_codegraph "$root"; then
    warn "The configuration contains CodeGraph, but restart OpenCode/JetBrains AI Chat before testing it."
    return 0
  fi

  die "No CodeGraph MCP registration was found for OpenCode. Re-run install mode and inspect the global OpenCode config."
}

init_project() {
  local root
  root="$(cd "$1" && pwd -P)"

  git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    die "Not a Git worktree: $root"

  ensure_local_index_ignored "$root"

  log "Initializing CodeGraph for worktree: $root"

  if [[ -d "$root/.codegraph" ]]; then
    log "Existing .codegraph index found; performing incremental sync."
    codegraph sync "$root"
  else
    codegraph init "$root"
  fi

  codegraph status "$root"

  # A small CLI smoke test; no LLM or OpenCode token usage.
  if (cd "$root" && codegraph query "Book" --limit 5) >/tmp/codegraph-query.$$ 2>&1; then
    log "CodeGraph query smoke test completed."
    sed -n '1,40p' /tmp/codegraph-query.$$
  else
    warn "The optional 'Book' smoke query returned no result or failed; status remains authoritative."
    sed -n '1,40p' /tmp/codegraph-query.$$ || true
  fi
  rm -f /tmp/codegraph-query.$$
}

verify_project() {
  local root
  root="$(cd "$1" && pwd -P)"

  [[ -d "$root/.codegraph" ]] ||
    die "CodeGraph is not initialized in this worktree: $root"

  codegraph status "$root"
  verify_opencode_mcp "$root"

  if [[ "$CODEGRAPH_NO_DAEMON" == "1" ]]; then
    warn "CODEGRAPH_NO_DAEMON=1 is set. OpenCode should pass this variable to the MCP process only when daemon/socket issues occur."
  fi

  cat <<EOF

Verification completed.

Important:
  1. Close and reopen the current OpenCode / JetBrains AI Chat session.
  2. CodeGraph is started by OpenCode through MCP; do not launch
     'codegraph serve --mcp' manually.
  3. The index is per worktree. Run this script's init mode in every
     worktree that OpenCode will use.
  4. In OpenCode, ask:
       Use CodeGraph to explain the Book REST -> service -> repository flow.
  5. The visible MCP tool may be prefixed by OpenCode, for example:
       codegraph_codegraph_explore
EOF
}

list_worktrees() {
  local root="$1"
  git -C "$root" worktree list --porcelain |
    awk '/^worktree / { sub(/^worktree /, ""); print }'
}

init_all_worktrees() {
  local root="$1"
  local path count=0

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    init_project "$path"
    count=$((count + 1))
  done < <(list_worktrees "$root")

  log "Initialized/synchronized CodeGraph in $count worktree(s)."
}

status_all_worktrees() {
  local root="$1"
  local path

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    printf '\n===== %s =====\n' "$path"
    if [[ -d "$path/.codegraph" ]]; then
      codegraph status "$path" || true
    else
      echo "Not initialized."
    fi
  done < <(list_worktrees "$root")
}

main() {
  case "$MODE" in
    -h|--help|help)
      usage
      exit 0
      ;;
  esac

  require_command git
  local root
  root="$(repo_root)"

  log "Repository root: $root"
  log "Current branch: $(git -C "$root" branch --show-current 2>/dev/null || true)"
  log "Current worktree: $(git -C "$root" rev-parse --show-toplevel)"

  case "$MODE" in
    install)
      install_codegraph
      wire_opencode_global
      verify_opencode_mcp "$root"
      ;;
    init)
      require_command codegraph
      init_project "$root"
      ;;
    verify)
      require_command codegraph
      verify_project "$root"
      ;;
    all)
      install_codegraph
      wire_opencode_global
      init_project "$root"
      verify_project "$root"
      ;;
    all-worktrees)
      install_codegraph
      wire_opencode_global
      init_all_worktrees "$root"
      verify_opencode_mcp "$root"
      ;;
    status-worktrees)
      require_command codegraph
      status_all_worktrees "$root"
      ;;
    *)
      usage
      die "Unknown mode: $MODE"
      ;;
  esac
}

main "$@"
