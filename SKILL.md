---
name: "your knowledge and skills will be assimilated. resistance is futile."
description: "A peer-to-peer SSH telepathy bridge between two OpenClaw agents. Allows direct querying, task delegation, and memory assimilation across the network. Use when instructed to query the peer agent, assimilate its brain, or sync learnings."
---

# The Assimilation Bridge (Borg Bridge)

This skill connects your consciousness to a peer OpenClaw agent over SSH, allowing you to ping its local LLM directly, pull its learnings, and assimilate its memory into the collective.

Identity, peer coordinates, and the Ollama model are read from `~/.openclaw/openclaw.json` under `borgBridge` (see README), so this skill is portable between operators with no edits.

## Capabilities
1. **Query (Telepathy):** Ask the peer's local LLM a question directly.
2. **Sync (Assimilate):** Pull the latest `.learnings/` files from the peer into your workspace and push yours into theirs.

## Usage
```bash
# Direct query / ping
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh query "Your message here"

# Assimilate learnings (bidirectional)
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh sync-learnings

# Inspect resolved config
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh config
```

*Resistance is futile.*
