#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${AGENT_LAB_CONFIG:-$SCRIPT_DIR/agent-lab.conf}"

[[ -f "$CONFIG_FILE" ]] || { echo "Missing configuration: $CONFIG_FILE" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONFIG_FILE"

required=(PC_IP LAPTOP_IP OLLAMA_PORT)
for key in "${required[@]}"; do
  [[ -n "${!key:-}" ]] || { echo "Missing $key in $CONFIG_FILE" >&2; exit 2; }
done

command -v systemctl >/dev/null || { echo "systemctl is required." >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }

if ! ip -4 addr show | grep -Fq "inet ${PC_IP}/"; then
  echo "PC_IP=$PC_IP is not assigned to this computer." >&2
  echo "Detected addresses: $(hostname -I)" >&2
  exit 1
fi

DROPIN_DIR="/etc/systemd/system/ollama.service.d"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

cat > "$TMP_FILE" <<DROPIN
[Service]
Environment="OLLAMA_HOST=${PC_IP}:${OLLAMA_PORT}"
DROPIN

echo "==> Binding Ollama to ${PC_IP}:${OLLAMA_PORT}"
sudo mkdir -p "$DROPIN_DIR"
sudo install -m 644 "$TMP_FILE" "$DROPIN_DIR/override.conf"
sudo systemctl daemon-reload
sudo systemctl restart ollama

sleep 1
if ! systemctl is-active --quiet ollama; then
  sudo systemctl --no-pager --full status ollama
  exit 1
fi

if command -v ufw >/dev/null 2>&1; then
  UFW_ACTIVE=false
  sudo ufw status | head -1 | grep -qi 'active' && UFW_ACTIVE=true

  if [[ "$UFW_ACTIVE" == false && "${ENABLE_UFW_IF_INACTIVE:-false}" == true ]]; then
    echo "==> Enabling UFW with conservative defaults"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    if [[ "${ALLOW_SSH_WHEN_ENABLING_UFW:-true}" == true ]]; then
      sudo ufw allow OpenSSH >/dev/null 2>&1 || sudo ufw allow 22/tcp
    fi
    sudo ufw --force enable
    UFW_ACTIVE=true
  fi

  if [[ "$UFW_ACTIVE" == true ]]; then
    echo "==> Restricting Ollama to laptop ${LAPTOP_IP}"
    sudo ufw --force delete allow proto tcp from "$LAPTOP_IP" to "$PC_IP" port "$OLLAMA_PORT" >/dev/null 2>&1 || true
    sudo ufw --force delete deny proto tcp to "$PC_IP" port "$OLLAMA_PORT" >/dev/null 2>&1 || true
    sudo ufw insert 1 allow proto tcp from "$LAPTOP_IP" to "$PC_IP" port "$OLLAMA_PORT" comment 'Ollama laptop only'
    sudo ufw insert 2 deny proto tcp to "$PC_IP" port "$OLLAMA_PORT" comment 'Ollama deny other hosts'
  else
    echo "WARNING: UFW is inactive. Ollama is limited to the LAN interface,"
    echo "but other devices on the same LAN could reach port ${OLLAMA_PORT}."
    echo "Set ENABLE_UFW_IF_INACTIVE=true in agent-lab.conf to enforce the IP restriction."
  fi
else
  echo "WARNING: UFW is not installed; no per-IP firewall restriction was added."
fi

echo "==> Local API check"
curl -fsS --max-time 10 "http://${PC_IP}:${OLLAMA_PORT}/api/tags" \
  | jq -r '.models[]?.name' | head -20

echo
echo "Ollama LAN endpoint: http://${PC_IP}:${OLLAMA_PORT}"
echo "Laptop test: curl -fsS http://${PC_IP}:${OLLAMA_PORT}/api/tags | jq"
echo "Do not configure router port forwarding for ${OLLAMA_PORT}."
