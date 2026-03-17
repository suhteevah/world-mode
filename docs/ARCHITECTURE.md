# ARCHITECTURE PIVOT: Claude Code as Brain (NOT Claude API)

## The Key Insight

We do NOT call the Anthropic API. Claude Code (running locally on Matt's machine
with its own OAuth subscription) IS the reasoning engine.

World Mode becomes an **MCP server** that Claude Code connects to. Claude Code
uses MCP tools to observe game state, execute programs, manage goals, etc.

## Why This Is Better

1. **Zero API cost** — Claude Code uses Matt's existing subscription/OAuth
2. **Claude Code is already agentic** — it has a REPL, can iterate, has memory
3. **MCP is the standard** — FLE already has MCP support, Claude Code speaks MCP natively
4. **Claude Code has tool use built in** — no need to parse markdown code fences
5. **FLE proved this works** — "Claude Code Plays Factorio" on Twitch uses this exact pattern

## Revised Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLAUDE CODE (LOCAL)                          │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │  OAuth-authenticated Claude instance                        ││
│  │  Running in terminal on kokonoe                              ││
│  │  Connected to World Mode MCP server                          ││
│  │  SOUL.md loaded as project context                           ││
│  └──────────┬───────────────────────────────────────────────────┘│
│             │ MCP Protocol (stdio or SSE)                        │
└─────────────┼───────────────────────────────────────────────────┘
              │
┌─────────────┴───────────────────────────────────────────────────┐
│              WORLD MODE MCP SERVER (Rust)                        │
│                                                                  │
│  MCP Tools Exposed:                                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ observe_state     — Get current game state (SENSE)         │  │
│  │ execute_program   — Run Python via FLE (ACT)               │  │
│  │ get_world_diff    — What changed since last observe (MODEL)│  │
│  │ get_production    — Production rates & trends              │  │
│  │ get_inventory     — Current player inventory               │  │
│  │ get_entities      — Query entities by type/area            │  │
│  │ get_power_status  — Power grid health                      │  │
│  │ push_goal         — Add a goal to the stack                │  │
│  │ list_goals        — View current goals                     │  │
│  │ complete_goal     — Mark a goal done                       │  │
│  │ list_abstractions — Available abstraction library functions │  │
│  │ save_abstraction  — Save a new reusable function           │  │
│  │ rcon_command      — Send RCON to Factorio server           │  │
│  │ send_chat         — In-game chat message                   │  │
│  │ get_map_image     — Current factory map render             │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Internal State:                                                 │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ World Model (SQLite) — entity index, state snapshots       │  │
│  │ Goal Stack — hierarchical goals with status                │  │
│  │ Abstraction Registry — Python functions Claude has written  │  │
│  │ Action History — log of all programs executed + results     │  │
│  │ Production History — time-series of throughput data         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  WebSocket Server (port 8421):                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Pushes real-time state to Next.js dashboard                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP
┌──────────────────────────┴──────────────────────────────────────┐
│              FLE ADAPTER (Python FastAPI)                        │
│  Wraps FLE SDK, exposes /state, /execute, /health               │
└──────────────────────────┬──────────────────────────────────────┘
                           │ FLE Protocol
┌──────────────────────────┴──────────────────────────────────────┐
│              FACTORIO HEADLESS SERVER                            │
│  Multiplayer enabled — Matt connects with game client           │
└─────────────────────────────────────────────────────────────────┘
```

## Claude Code Configuration

In Matt's `~/.claude/` or project `.claude/` config, add the MCP server:

```json
{
  "mcpServers": {
    "world-mode": {
      "command": "world-mode",
      "args": ["mcp-serve"],
      "env": {
        "WM_CONFIG": "configs/world-mode.toml"
      }
    }
  }
}
```

Or for SSE transport (if running as a persistent service):

```json
{
  "mcpServers": {
    "world-mode": {
      "type": "sse",
      "url": "http://localhost:8420/mcp/sse"
    }
  }
}
```

## What Changes From Previous Design

| Before (API-based)                | After (Claude Code + MCP)              |
|----------------------------------|----------------------------------------|
| Rust calls Claude API            | Claude Code calls Rust MCP tools       |
| Rust owns the agent loop         | Claude Code owns the reasoning loop    |
| Rust assembles prompts           | Claude Code has SOUL.md as context     |
| Rust parses code from responses  | Claude Code uses tools directly        |
| $$ per API call                  | $0 (OAuth subscription)               |
| wm-core is the orchestrator      | wm-core is the MCP server + state mgr |
| claude_client.rs                 | DELETED — not needed                   |

## What STAYS The Same

- FLE adapter (Python FastAPI wrapping FLE SDK)
- World model (SQLite state tracking)
- Abstraction Library (Python files Claude writes)
- Dashboard (Next.js + WebSocket)
- Factorio server (Docker headless)
- Goal system
- Error classification
- All the types in wm-bridge
