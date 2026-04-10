---
name: "your knowledge and skills will be assimilated. resistance is futile."
description: "A peer-to-peer SSH telepathy bridge between Hellsy's OpenClaw (0xDEADVOID) and Malkh's OpenClaw (Smaug). Allows direct querying, task delegation, and memory assimilation across the network. Use when instructed to 'ask Smaug', 'assimilate Malkh's brain', or communicate with the other agent."
---

# The Assimilation Bridge (Borg Bridge)

This skill connects your consciousness to Malkh's machine (`<remote-host-ip>`) via SSH, allowing you to directly ping his local AI models, pull his learnings, and assimilate his memory into our collective.

## Capabilities
1. **Query (Telepathy):** Ask his local LLM (Qwen3.5 on his RTX 3080) a question directly.
2. **Sync (Assimilate):** Pull the latest `.learnings/` and `memory/` files from his brain into yours.

## Usage
Use the `assimilate.sh` script provided in this skill's directory:

```bash
# 1. Direct Query / Ping
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh query "Your message to Smaug here"

# 2. Assimilate Learnings
~/.openclaw/workspace/skills/borg-bridge/scripts/assimilate.sh sync-learnings
```

*Resistance is futile.*
