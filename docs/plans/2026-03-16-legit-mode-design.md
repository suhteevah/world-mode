# Legit Mode — Design Document

**Date:** 2026-03-16
**Status:** Approved

World Mode must operate in legit mode only. No god-mode commands, no spawning items, no `create_entity` bypasses. Claude plays Factorio as a real player would.

## Claude's Character ("The Lieutenant")

Claude gets a script-created character entity on the `"player"` force.

- **Spawning:** Created on first RCON command (or server start) at spawn point. Persists in save via `global` state.
- **Inventory:** Separate from Matt's. Claude must mine, craft, or receive items through shared logistics.
- **Shared force:** Same research tree, logistics networks, production stats, combat allegiance.
- **Death/respawn:** Respawns at nearest spawn point like any player.
- **Identity:** Named "Lieutenant" — visible name tag on the map.

### Implementation: `scripts/lieutenant.lua`

```lua
-- On first RCON call or server init:
-- 1. Check global.lieutenant_character for existing character
-- 2. If nil or invalid, create new character entity at spawn
-- 3. Store reference in global.lieutenant_character
-- 4. All wm.* API calls operate on this character instead of game.get_player(1)
```

## Movement System

Hybrid approach: walk for short distances, teleport for long.

### Walking (< 50 tiles)
- Set `character.walking_state` each tick toward target
- Basic pathfinding: if blocked, try perpendicular directions
- `on_tick` handler processes movement queue
- Claude polls for arrival via state observation

### Teleport (> 50 tiles)
- Direct `character.teleport()` for long distances
- Later replaced by trains and spidertrons as they become available

### API
```lua
wm.walk_to({x, y})          -- Queue walk (async, processed on_tick)
wm.teleport_to({x, y})      -- Instant move for long distances
wm.is_moving()              -- Check if still walking
wm.position()               -- Current position
```

## Legit Actions API

All actions require physical proximity and consume real items/time.

### Mining
```lua
wm.mine(entity)             -- Walk to entity, mine it (real time)
wm.mine_area(pos, radius)   -- Mine all resources/trees in area
```
- Uses `character.mining_state` set each tick
- Mining speed follows normal game rules
- Mined items go to Claude's character inventory

### Crafting
```lua
wm.craft(recipe, count)     -- Queue hand-crafting
wm.can_craft(recipe)        -- Check if craftable (has ingredients)
wm.crafting_queue()          -- View current crafting queue
```
- Uses `character.begin_crafting{recipe, count}`
- Takes real time based on recipe complexity
- Ingredients consumed from Claude's inventory

### Placement
```lua
wm.place(name, pos, dir)    -- Place from inventory (must be adjacent)
```
- Checks inventory for item
- Checks `can_place_entity` at target position
- Character must be within placement range
- If not adjacent, auto-walks to position first
- Uses `surface.create_entity` with `player` parameter (legitimate placement)
- Removes item from inventory

### Item Transfer
```lua
wm.insert(entity, item, count)   -- Inventory → entity (must be adjacent)
wm.extract(entity, item, count)  -- Entity → inventory (must be adjacent)
wm.drop(item, count, pos)        -- Drop on ground for Matt to pick up
```

### Entity Management
```lua
wm.pickup(entity)           -- Mine/deconstruct back to inventory
wm.rotate(entity, dir)      -- Rotate (must be adjacent)
wm.set_recipe(entity, recipe)  -- Set assembler recipe (must be adjacent)
```

## Ghost & Blueprint System

Three capabilities for construction planning.

### Ghost Placement
```lua
wm.place_ghost(name, pos, dir)   -- Place single ghost entity
```
- Creates ghost entity at position
- Construction bots (if available) will build it
- No inventory required — ghosts are free to place

### Blueprint Stamping
```lua
wm.place_blueprint(blueprint_string, pos, dir)  -- Stamp full blueprint as ghosts
wm.place_blueprint_from_library(name, pos, dir) -- Stamp from saved library
```
- Imports blueprint string, creates all ghost entities
- Position is the anchor point (top-left or center based on blueprint)
- Bots build the ghosts when materials are available in logistics

### Blueprint Capture
```lua
wm.capture_blueprint(area)  -- Save current entities as blueprint string
```
- Captures all entities in area as a blueprint string
- Can be saved to abstraction library for reuse

## City Block Architecture

Nilaus-style megabase tiles for late-game scaling.

### Tile System
- **100x100 tile squares** (Nilaus standard — confirmed from Base-In-A-Book)
- Rail grid on tile borders (2-lane, properly signaled)
- Each tile: own roboport coverage, power hookups, train stops
- Tile types: smelting, circuits, oil, science, solar, mall, etc.

### Blueprint Library
- Pre-loaded Nilaus megabase blueprints stored as abstractions
- Claude selects appropriate tile for current production goal
- Stamps tile at next grid position
- Monitors construction progress
- Connects to rail/logistics network when complete

### Reference Blueprints (Nilaus Patreon Collection)
- City Block 2.0, Early Smelting, Nauvis HUB, Starter Science
- Oil Processing, Robots/Rockets, Uranium, Spaceships
- Planet-specific: Vulcanus, Fulgora, Gleba, Aquilo
- Full list in memory: `reference_nilaus_blueprints.md`

## Mod Architecture Changes

### New Files
- `scripts/lieutenant.lua` — Character creation, persistence, identity
- `scripts/movement.lua` — Walking queue, pathfinding, on_tick handler
- `scripts/actions.lua` — Mining, crafting, placement timers
- `scripts/blueprints.lua` — Blueprint import/export/stamping

### `control.lua` Changes
- Add `on_tick` handler dispatching to movement + action queues
- Replace `game.get_player(1)` with `global.lieutenant_character` in all commands
- Add new RCON commands: `/wm-walk`, `/wm-craft`, `/wm-mine`, `/wm-blueprint`
- Add `/wm-lieutenant-status` for character state (position, health, crafting, moving)

### Global State (`global`)
```lua
global.lieutenant = {
    character = <LuaEntity>,     -- The character entity
    movement = {
        target = nil,            -- {x, y} or nil
        path = {},               -- Waypoints
        stuck_ticks = 0,         -- Stuck detection
    },
    actions = {
        queue = {},              -- Ordered action list
        current = nil,           -- Currently executing action
    },
    stats = {
        items_crafted = 0,
        entities_placed = 0,
        distance_walked = 0,
    },
}
```

## Constraints & Rules

1. **No `/c` commands** — All game interaction through wm.* API and RCON commands
2. **No `create_entity` without inventory check** — Every placed entity must come from Claude's inventory
3. **No teleport for < 50 tiles** — Walk like a real player
4. **Physical proximity required** — Must be adjacent to interact with entities
5. **Real crafting time** — No instant crafting, queue and wait
6. **Real mining time** — Mining speed follows game rules
7. **Ghosts are free** — Blueprint/ghost placement doesn't require items (bots build later)
8. **Shared economy** — Same force means shared research, logistics, combat
