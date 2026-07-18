#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${AGENT_LAB_CONFIG:-$SCRIPT_DIR/agent-lab.conf}"

[[ -f "$CONFIG_FILE" ]] || { echo "Missing configuration: $CONFIG_FILE" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONFIG_FILE"

required=(PC_IP OLLAMA_PORT OLLAMA_MODEL NODE_VERSION NVM_VERSION CLINE_REQUEST_TIMEOUT_MS)
for key in "${required[@]}"; do
  [[ -n "${!key:-}" ]] || { echo "Missing $key in $CONFIG_FILE" >&2; exit 2; }
done

OLLAMA_URL="http://${PC_IP}:${OLLAMA_PORT}"
REPO_DIR="$SCRIPT_DIR"

if [[ ! -f /etc/os-release ]]; then
  echo "Cannot detect the Linux distribution." >&2
  exit 1
fi
. /etc/os-release
case "${ID_LIKE:-$ID}" in
  *debian*|*ubuntu*) ;;
  *) echo "Prepared for Zorin/Ubuntu/Debian. Detected: ${PRETTY_NAME:-unknown}" >&2; exit 1 ;;
esac

echo "==> Installing Java 21, Maven and support tools"
sudo apt-get update
sudo apt-get install -y \
  openjdk-21-jdk \
  maven \
  git \
  curl \
  jq \
  ca-certificates \
  build-essential

# Avoid the npm prefix conflict already observed on the main PC.
if [[ -f "$HOME/.npmrc" ]]; then
  cp -a "$HOME/.npmrc" "$HOME/.npmrc.backup.$(date +%Y%m%d-%H%M%S)"
fi
npm config delete prefix --location=user >/dev/null 2>&1 || true
npm config delete globalconfig --location=user >/dev/null 2>&1 || true
npm uninstall -g cline --prefix "$HOME/.npm-global" >/dev/null 2>&1 || true

export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo "==> Installing nvm ${NVM_VERSION}"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
fi
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"

nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use "$NODE_VERSION"

echo "==> Installing Cline CLI"
npm install -g cline@latest
hash -r

CLINE_BIN="$NVM_DIR/versions/node/v${NODE_VERSION}/bin/cline"
[[ -x "$CLINE_BIN" ]] || { echo "Cline was not installed at $CLINE_BIN" >&2; exit 1; }

SETTINGS_DIR="$HOME/.cline/data/settings"
PROVIDERS_FILE="$SETTINGS_DIR/providers.json"
mkdir -p "$SETTINGS_DIR"

if [[ -s "$PROVIDERS_FILE" ]] && jq empty "$PROVIDERS_FILE" >/dev/null 2>&1; then
  cp -a "$PROVIDERS_FILE" "$PROVIDERS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  INPUT_JSON="$PROVIDERS_FILE"
else
  INPUT_JSON="$(mktemp)"
  printf '%s\n' '{"version":1,"providers":{}}' > "$INPUT_JSON"
fi

TMP_JSON="$(mktemp)"
jq \
  --arg url "$OLLAMA_URL" \
  --arg model "$OLLAMA_MODEL" \
  --argjson timeout "$CLINE_REQUEST_TIMEOUT_MS" \
  '
    .version = (.version // 1)
    | .lastUsedProvider = "ollama"
    | .providers = (.providers // {})
    | .providers.ollama = (.providers.ollama // {})
    | .providers.ollama.settings = {
        provider: "ollama",
        model: $model,
        protocol: "openai-chat",
        client: "ai-sdk-community",
        baseUrl: $url,
        timeout: $timeout,
        reasoning: {enabled: false}
      }
    | .providers.ollama.updatedAt = (now | todateiso8601)
    | .providers.ollama.tokenSource = "migration"
  ' "$INPUT_JSON" > "$TMP_JSON"
install -m 600 "$TMP_JSON" "$PROVIDERS_FILE"
rm -f "$TMP_JSON"
[[ "$INPUT_JSON" == /tmp/* ]] && rm -f "$INPUT_JSON"

echo "==> Testing remote Ollama"
TAGS_FILE="$(mktemp)"
trap 'rm -f "$TAGS_FILE"' EXIT
curl -fsS --max-time 10 "$OLLAMA_URL/api/tags" > "$TAGS_FILE" || {
  echo "Cannot reach $OLLAMA_URL/api/tags" >&2
  echo "Run configure-ollama-lan.sh on the PC first." >&2
  exit 1
}

if jq -e --arg model "$OLLAMA_MODEL" '
  [.models[]?.name, .models[]?.model]
  | flatten | map(select(. != null))
  | any(. == $model or . == ($model + ":latest"))
' "$TAGS_FILE" >/dev/null; then
  echo "Remote model found: $OLLAMA_MODEL"
else
  echo "WARNING: Ollama responds, but model '$OLLAMA_MODEL' was not found."
fi

chmod 755 "$SCRIPT_DIR/configure-ollama-lan.sh" \
          "$SCRIPT_DIR/setup-cline-laptop.sh" \
          "$SCRIPT_DIR/launch-cline-remote.sh"

CLINEIGNORE="$REPO_DIR/.clineignore"
touch "$CLINEIGNORE"
for entry in \
  "/agent-lab.conf" \
  "/configure-ollama-lan.sh" \
  "/setup-cline-laptop.sh" \
  "/launch-cline-remote.sh"; do
  grep -Fxq "$entry" "$CLINEIGNORE" || printf '%s\n' "$entry" >> "$CLINEIGNORE"
done

echo "==> Installed versions"
JAVA_HOME_CANDIDATE="/usr/lib/jvm/java-21-openjdk-amd64"
if [[ -d "$JAVA_HOME_CANDIDATE" ]]; then
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
java -version
javac -version
mvn -version
node --version
npm --version
"$CLINE_BIN" --version

echo
echo "Setup complete. Run: ./launch-cline-remote.sh"
