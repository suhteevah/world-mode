# Phase 0 — Implementation Checklist

Pure Rust + Lua. No Python. No FLE.

## Step 1: Get Rust Compiling

```bash
cd world-mode
cargo build 2>&1
```

Fix any compile errors. The main areas:
- `wm-bridge`: RCON client (raw TCP), shared types
- `wm-core`: MCP server, tool handlers, config
- Type imports between crates

**Exit criterion:** `cargo build --release` succeeds.

## Step 2: Factorio Server Running

```bash
docker compose up -d
docker compose logs -f factorio
```

Wait for "Hosting game at port 34197".

Verify mod is loaded — check logs for "world-mode-bridge" in mod list.
If not, ensure the volume mount `./mod/world-mode-bridge:/factorio/mods/world-mode-bridge` works.

Connect with game client: Direct Connect → `localhost:34197`

**Exit criterion:** Matt can connect and walk around. Mod shows in mod list.

## Step 3: RCON Works

```bash
cargo run --bin wm-core -- status --config configs/world-mode.toml
```

Should show:
```
  Connected: YES
  Version:   2.x.x
  WM Mod:    Loaded (got state)
```

If "WM Mod: NOT loaded", the Lua mod isn't being picked up. Check:
- `mod/world-mode-bridge/info.json` exists and has valid JSON
- The Docker volume mount is correct
- Restart Factorio after adding the mod

**Exit criterion:** Status command connects and gets state.

## Step 4: Test execute_lua Manually

```bash
cargo run --bin wm-core -- exec 'wm.print("hello from Rust!")' --config configs/world-mode.toml
```

Should return `{"success":true,"stdout":"hello from Rust!"}`.

Then test placing something:
```bash
cargo run --bin wm-core -- exec 'local pos = wm.position() wm.print("Player at " .. pos.x .. ", " .. pos.y)' --config configs/world-mode.toml
```

**Exit criterion:** Lua executes and returns output through RCON.

## Step 5: MCP Handshake

Test by piping JSON-RPC:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1.0"}}}' | cargo run --bin wm-core -- mcp-serve --config configs/world-mode.toml 2>/dev/null
```

Should return JSON with serverInfo.

**Exit criterion:** MCP server responds to initialize.

## Step 6: Claude Code Connects

Open Claude Code in the `world-mode/` directory. The `.mcp.json` auto-registers.

Try:
```
Use the observe_state tool to see the current Factorio game state
```

Then:
```
Use execute_lua to build a boiler and steam engine for power
```

**EXIT CRITERION FOR PHASE 0:**
Claude Code observes real game state → writes Lua code → executes via RCON → Matt sees entities appear in-game. The loop works.

## Common Issues

**RCON connection refused:** Factorio not running or port 27015 not exposed.
**RCON auth failed:** Password mismatch between configs/world-mode.toml and server-settings.json.
**wm-exec: Unknown command:** The World Mode Bridge mod isn't loaded. Check mod directory.
**"No player found":** Nobody is connected to the server yet. Matt needs to join first.
**Lua nil errors:** Re-observe state. Entity positions change.
**Large state taking too long:** Increase timeout_seconds in config. Use `observe_state` with `include_entities: false` for compact mode.
