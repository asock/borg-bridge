#!/usr/bin/env bash
# Assimilation Protocol (Bidirectional SSH Bridge)
set -euo pipefail

# ----- Configuration ---------------------------------------------------------
# All identity, peer, and ollama settings come from the OpenClaw config so
# nothing in this script is hardcoded to a particular operator. Layout:
#
#   ~/.openclaw/openclaw.json
#     "borgBridge": {
#       "self":  { "name": "self-name" },
#       "peer":  { "name": "peer-name", "target": "user@host" },
#       "ollama": { "model": "qwen3.5:latest" }
#     }
#
# Each field can also be overridden via env vars (BORG_SELF_NAME,
# BORG_PEER_NAME, BORG_PEER_TARGET, BORG_OLLAMA_MODEL) for ad-hoc use.

OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
PEER_IP_FILE="$HOME/.borg-bridge/peer-ip"
LEARNINGS_LOCAL="$HOME/.openclaw/workspace/.learnings"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

warn() { echo "[Borg Bridge] WARN: $*" >&2; }
die()  { echo "[Borg Bridge] ERROR: $*" >&2; exit 1; }

ip_is_valid() {
    [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

# Slugify a display name to something safe for a directory component:
# lowercase, [a-z0-9_] only.
slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_' '_' | sed 's/_\+/_/g; s/^_//; s/_$//'
}

# Read a dotted JSON path from openclaw.json. Empty string on miss.
config_get() {
    local path="$1"
    [[ -r "$OPENCLAW_CONFIG" ]] || { printf ''; return; }
    command -v jq >/dev/null 2>&1 || { printf ''; return; }
    jq -r "${path} // empty" "$OPENCLAW_CONFIG" 2>/dev/null || printf ''
}

SELF_NAME="${BORG_SELF_NAME:-$(config_get '.borgBridge.self.name')}"
PEER_NAME="${BORG_PEER_NAME:-$(config_get '.borgBridge.peer.name')}"
PEER_TARGET="${BORG_PEER_TARGET:-$(config_get '.borgBridge.peer.target')}"
OLLAMA_MODEL="${BORG_OLLAMA_MODEL:-$(config_get '.borgBridge.ollama.model')}"

# Sane fallbacks so the script is still introspectable without a config file.
: "${SELF_NAME:=self}"
: "${PEER_NAME:=peer}"
: "${OLLAMA_MODEL:=llama3.2}"

SELF_SLUG="$(slugify "$SELF_NAME")"
PEER_SLUG="$(slugify "$PEER_NAME")"
[[ -n "$SELF_SLUG" ]] || SELF_SLUG="self"
[[ -n "$PEER_SLUG" ]] || PEER_SLUG="peer"

# ----- Target resolution -----------------------------------------------------
# If the peer has published a fresh IP into ~/.borg-bridge/peer-ip, use it
# (preserving the user portion from config); otherwise use the configured
# target verbatim.
resolve_target() {
    [[ -n "$PEER_TARGET" ]] || die "no peer target configured (set borgBridge.peer.target in openclaw.json or BORG_PEER_TARGET)"
    if [[ -r "$PEER_IP_FILE" ]]; then
        local ip
        ip=$(<"$PEER_IP_FILE")
        if ip_is_valid "$ip"; then
            printf '%s@%s\n' "${PEER_TARGET%@*}" "$ip"
            return
        fi
        warn "peer-ip file present but not a valid IPv4; falling back to configured target"
    fi
    printf '%s\n' "$PEER_TARGET"
}

# Tell the peer where we live by writing our current public IP into *their*
# ~/.borg-bridge/peer-ip. The IP is validated as IPv4 before it ever leaves
# this host, so the remote command string contains nothing but digits and dots
# in the variable slot.
publish_my_ip() {
    local target="$1"
    local my_ip
    if ! my_ip=$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null); then
        warn "could not fetch public IP; skipping peer-ip publish"
        return 0
    fi
    if ! ip_is_valid "$my_ip"; then
        warn "ifconfig.me returned a non-IPv4 value; skipping peer-ip publish"
        return 0
    fi
    ssh "${SSH_OPTS[@]}" "$target" \
        "mkdir -p ~/.borg-bridge && printf '%s\n' '${my_ip}' > ~/.borg-bridge/peer-ip" \
        || warn "failed to publish peer-ip to ${target}; continuing"
}

# ----- Dispatch --------------------------------------------------------------
ACTION="${1:-}"
shift || true
PAYLOAD="${*:-}"

case "$ACTION" in
    query)
        [[ -n "$PAYLOAD" ]] || { echo "Usage: $0 query <prompt>" >&2; exit 2; }
        TARGET="$(resolve_target)"
        publish_my_ip "$TARGET"
        echo "[Borg Bridge] Transmitting telepathic query to ${PEER_NAME} via Ollama..."
        printf '%s\n' "$PAYLOAD" | ssh "${SSH_OPTS[@]}" "$TARGET" "ollama run ${OLLAMA_MODEL}"
        ;;
    sync-learnings)
        TARGET="$(resolve_target)"
        publish_my_ip "$TARGET"

        echo "[Borg Bridge] Pulling ${PEER_NAME}'s learnings..."
        mkdir -p "$LEARNINGS_LOCAL/${PEER_SLUG}_assimilated/"
        rsync -avz -e "ssh ${SSH_OPTS[*]}" --exclude='*_assimilated' \
            "$TARGET:.openclaw/workspace/.learnings/" \
            "$LEARNINGS_LOCAL/${PEER_SLUG}_assimilated/"

        echo "[Borg Bridge] Pushing ${SELF_NAME}'s learnings to ${PEER_NAME}..."
        ssh "${SSH_OPTS[@]}" "$TARGET" \
            "mkdir -p \"\$HOME/.openclaw/workspace/.learnings/${SELF_SLUG}_assimilated/\""
        rsync -avz -e "ssh ${SSH_OPTS[*]}" --exclude='*_assimilated' \
            "$LEARNINGS_LOCAL/" \
            "$TARGET:.openclaw/workspace/.learnings/${SELF_SLUG}_assimilated/"

        echo "[Borg Bridge] Bidirectional assimilation complete."
        ;;
    peer-ip)
        resolve_target
        ;;
    config)
        # Diagnostic: dump the resolved configuration.
        printf 'self:   %s (slug: %s)\n' "$SELF_NAME" "$SELF_SLUG"
        printf 'peer:   %s (slug: %s)\n' "$PEER_NAME" "$PEER_SLUG"
        printf 'target: %s\n' "${PEER_TARGET:-<unset>}"
        printf 'model:  %s\n' "$OLLAMA_MODEL"
        ;;
    *)
        echo "Usage: $0 {query|sync-learnings|peer-ip|config} [payload]" >&2
        exit 1
        ;;
esac
