# Borg Bridge (Assimilation Protocol)

A peer-to-peer SSH telepathy bridge for OpenClaw agents. This skill lets two OpenClaw agents (on separate hosts/networks) directly query each other's local LLMs, delegate tasks, and bidirectionally sync their `.learnings/` files.

## Features
- **Telepathic Querying:** Send prompts directly to a remote agent's local model via SSH.
- **Bidirectional Memory Sync:** Uses `rsync` to pull and push learning files without creating recursive loops.
- **Self-Healing IP Routing:** Detects WAN IP changes via `ifconfig.me` and publishes them to the peer's `~/.borg-bridge/peer-ip`, which the peer reads on startup. No remote script rewriting.
- **Config-driven identity:** All operator/peer names, target, and model live in `~/.openclaw/openclaw.json` — nothing in the script is hardcoded.

## Installation
Clone this repository into your OpenClaw workspace:
```bash
git clone https://github.com/asock/borg-bridge.git ~/.openclaw/workspace/skills/borg-bridge
```

## Configuration
Add a `borgBridge` block to `~/.openclaw/openclaw.json`:

```json
{
  "borgBridge": {
    "self":  { "name": "your-handle" },
    "peer":  { "name": "peer-handle", "target": "peer_user@peer.host.example" },
    "ollama": { "model": "qwen3.5:latest" }
  }
}
```

Each field can also be overridden at the shell with `BORG_SELF_NAME`, `BORG_PEER_NAME`, `BORG_PEER_TARGET`, `BORG_OLLAMA_MODEL`. Requires `jq` to read the JSON config (falls back to env vars / defaults if `jq` is missing).

The peer's display name is slugified to derive the directory it lands in under `.learnings/<peer>_assimilated/`, so renaming a peer is purely a config edit.

## Usage
Ensure passwordless SSH keys are exchanged between the two hosts.

```bash
# Query the remote agent
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh query "Your prompt here"

# Sync learnings (bidirectional)
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh sync-learnings

# Show resolved peer target (with peer-ip override applied)
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh peer-ip

# Show resolved config
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh config
```

*Your knowledge and skills will be assimilated. Resistance is futile.*
