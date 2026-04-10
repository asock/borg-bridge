#!/usr/bin/env bash
# Assimilation Protocol (Bidirectional SSH Bridge)
set -euo pipefail

# Default peer coordinates. The host portion may be overridden at runtime by
# ~/.borg-bridge/peer-ip (see resolve_target), which lets the dynamic-IP side
# tell us where it has moved to without anyone editing this script.
TARGET_DEFAULT="remote_user@remote_host_ip"

PEER_IP_FILE="$HOME/.borg-bridge/peer-ip"
LEARNINGS_LOCAL="$HOME/.openclaw/workspace/.learnings"

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)

ip_is_valid() {
    [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

warn() { echo "[Borg Bridge] WARN: $*" >&2; }

# If the peer has published a fresh IP into ~/.borg-bridge/peer-ip, use it;
# otherwise fall back to the compiled-in default.
resolve_target() {
    if [[ -r "$PEER_IP_FILE" ]]; then
        local ip
        ip=$(<"$PEER_IP_FILE")
        if ip_is_valid "$ip"; then
            printf '%s@%s\n' "${TARGET_DEFAULT%@*}" "$ip"
            return
        fi
        warn "peer-ip file present but not a valid IPv4; falling back to default"
    fi
    printf '%s\n' "$TARGET_DEFAULT"
}

# Tell the peer where we live by writing our current public IP into *their*
# ~/.borg-bridge/peer-ip. No remote sed, no script rewriting. The IP is
# validated as IPv4 before it ever leaves this host, so the remote command
# string contains nothing but digits and dots in the variable slot.
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

ACTION="${1:-}"
shift || true
PAYLOAD="${*:-}"

TARGET="$(resolve_target)"

case "$ACTION" in
    query)
        if [[ -z "$PAYLOAD" ]]; then
            echo "Usage: $0 query <prompt>" >&2
            exit 2
        fi
        publish_my_ip "$TARGET"
        echo "[Borg Bridge] Transmitting telepathic query to Smaug via Ollama..."
        printf '%s\n' "$PAYLOAD" | ssh "${SSH_OPTS[@]}" "$TARGET" 'ollama run qwen3.5:latest'
        ;;
    sync-learnings)
        publish_my_ip "$TARGET"
        echo "[Borg Bridge] Pulling Smaug's learnings..."
        mkdir -p "$LEARNINGS_LOCAL/malkh_assimilated/"
        rsync -avz -e "ssh ${SSH_OPTS[*]}" --exclude='*_assimilated' \
            "$TARGET:.openclaw/workspace/.learnings/" \
            "$LEARNINGS_LOCAL/malkh_assimilated/"

        echo "[Borg Bridge] Pushing 0xDEADVOID's learnings to Smaug..."
        ssh "${SSH_OPTS[@]}" "$TARGET" 'mkdir -p "$HOME/.openclaw/workspace/.learnings/hellsy_assimilated/"'
        rsync -avz -e "ssh ${SSH_OPTS[*]}" --exclude='*_assimilated' \
            "$LEARNINGS_LOCAL/" \
            "$TARGET:.openclaw/workspace/.learnings/hellsy_assimilated/"

        echo "[Borg Bridge] Bidirectional assimilation complete."
        ;;
    peer-ip)
        # Diagnostic: show what we'd connect to right now.
        echo "$TARGET"
        ;;
    *)
        echo "Usage: $0 {query|sync-learnings|peer-ip} [payload]" >&2
        exit 1
        ;;
esac
