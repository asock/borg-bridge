# Borg Bridge (Assimilation Protocol)

A peer-to-peer SSH telepathy bridge for OpenClaw agents. This skill allows two distinct OpenClaw agents (on separate hosts/networks) to directly query each other's local LLMs, delegate tasks, and bidirectionally sync their `.learnings/` and `memory/` files.

## Features
- **Telepathic Querying:** Send prompts directly to a remote agent's local model via SSH.
- **Bidirectional Memory Sync:** Uses `rsync` to pull and push learning files without creating infinite recursive loops.
- **Self-Healing IP Routing:** Automatically detects WAN IP changes via `ifconfig.me` and updates the remote agent's target coordinates.

## Installation
Clone this repository into your OpenClaw workspace:
```bash
git clone https://github.com/asock/borg-bridge.git ~/.openclaw/workspace/skills/borg-bridge
```

## Usage
Ensure you have passwordless SSH keys exchanged between the two hosts.
```bash
# Query the remote agent
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh query "Your prompt here"

# Sync learnings
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh sync-learnings
```

*Your knowledge and skills will be assimilated. Resistance is futile.*
