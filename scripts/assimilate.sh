#!/bin/bash
# Assimilation Protocol (Bidirectional SSH Bridge)

# Resolve IPs dynamically in case they change
# Our target is malkh's static-ish IP or domain. If he has a DDNS we should use it, otherwise hardcoded.
# Actually, since we don't have DDNS, we will just use the known IP for Malkh. 
# But for Malkh reaching Hellsy, Hellsy's IP is dynamic.
TARGET="malkh@85.89.12.173"
ACTION=$1
shift
PAYLOAD="$*"

# Self-healing IP update for Malkh's side
# Before we connect, we push our current public IP to his script so he never loses us.
MY_IP=$(curl -s ifconfig.me)
ssh -o BatchMode=yes "$TARGET" "sed -i -E 's/TARGET=\"hellsy@[0-9.]+\"/TARGET=\"hellsy@${MY_IP}\"/g' ~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh"

case "$ACTION" in
    query)
        echo "[Borg Bridge] Transmitting telepathic query to Smaug via Ollama..."
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET" "ollama run qwen3.5:latest \"$PAYLOAD\""
        ;;
    sync-learnings)
        echo "[Borg Bridge] Pulling Smaug's learnings..."
        mkdir -p ~/.openclaw/workspace/.learnings/malkh_assimilated/
        rsync -avz -e "ssh -o BatchMode=yes" --exclude="*_assimilated" "$TARGET:~/.openclaw/workspace/.learnings/" ~/.openclaw/workspace/.learnings/malkh_assimilated/
        
        echo "[Borg Bridge] Pushing 0xDEADVOID's learnings to Smaug..."
        ssh -o BatchMode=yes "$TARGET" "mkdir -p ~/.openclaw/workspace/.learnings/hellsy_assimilated/"
        rsync -avz -e "ssh -o BatchMode=yes" --exclude="*_assimilated" ~/.openclaw/workspace/.learnings/ "$TARGET:~/.openclaw/workspace/.learnings/hellsy_assimilated/"
        
        echo "[Borg Bridge] Bidirectional assimilation complete."
        ;;
    *)
        echo "Usage: $0 {query|sync-learnings} [payload]"
        exit 1
        ;;
esac
