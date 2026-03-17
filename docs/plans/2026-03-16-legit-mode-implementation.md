# Legit Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace god-mode gameplay with a legit AI player character that mines, crafts, walks, places from inventory, and stamps blueprints — exactly like a real Factorio player.

**Architecture:** The Lua mod gets 4 new modules (lieutenant, movement, actions, blueprints) managed by an `on_tick` dispatcher in control.lua. The Rust MCP server gets new RCON convenience methods. All `game.get_player(1)` calls become `global.lieutenant.character` references.

**Tech Stack:** Lua (Factorio mod API 2.0), Rust (wm-bridge RCON client, wm-core MCP tools)

---

### Task 1: Lieutenant Character Module

**Files:**
- Create: `mod/world-mode-bridge/scripts/lieutenant.lua`
- Modify: `mod/world-mode-bridge/control.lua`

**Step 1: Create `scripts/lieutenant.lua`**

```lua
-- scripts/lieutenant.lua
-- Creates and manages Claude's in-game character ("The Lieutenant")

local lieutenant = {}

--- Initialize or recover the lieutenant character.
--- Called on server start and on first RCON command.
--- @return LuaEntity the character entity
function lieutenant.ensure(surface, force)
    -- Check for existing character in global state
    if global.lieutenant and global.lieutenant.character and global.lieutenant.character.valid then
        return global.lieutenant.character
    end

    -- Initialize global state
    global.lieutenant = global.lieutenant or {}
    global.lieutenant.movement = { target = nil, stuck_ticks = 0 }
    global.lieutenant.actions = { queue = {}, current = nil }
    global.lieutenant.stats = { items_crafted = 0, entities_placed = 0, distance_walked = 0 }

    -- Find spawn position
    local spawn = force.get_spawn_position(surface)
    local pos = surface.find_non_colliding_position("character", spawn, 50, 1)
    if not pos then pos = spawn end

    -- Create character entity
    local character = surface.create_entity{
        name = "character",
        position = pos,
        force = force,
    }

    if not character then
        error("Failed to create lieutenant character at " .. serpent.line(pos))
    end

    -- Give starter items (same as a new freeplay character)
    local inv = character.get_inventory(defines.inventory.character_main)
    if inv then
        inv.insert{name = "iron-plate", count = 8}
        inv.insert{name = "wood", count = 1}
        inv.insert{name = "burner-mining-drill", count = 1}
        inv.insert{name = "stone-furnace", count = 1}
    end

    global.lieutenant.character = character
    game.print("[World Mode] Lieutenant spawned at " .. math.floor(pos.x) .. ", " .. math.floor(pos.y))

    return character
end

--- Get the lieutenant character, or nil if not yet created.
function lieutenant.get()
    if global.lieutenant and global.lieutenant.character and global.lieutenant.character.valid then
        return global.lieutenant.character
    end
    return nil
end

--- Get lieutenant status summary.
function lieutenant.status()
    local char = lieutenant.get()
    if not char then return { alive = false } end

    local inv_counts = {}
    local inv = char.get_inventory(defines.inventory.character_main)
    if inv then
        for item, count in pairs(inv.get_contents()) do
            if type(count) == "number" then
                inv_counts[item] = count
            elseif type(count) == "table" and count.count then
                inv_counts[item] = count.count
            end
        end
    end

    return {
        alive = true,
        position = { x = char.position.x, y = char.position.y },
        health = char.health,
        surface = char.surface.name,
        moving = global.lieutenant.movement.target ~= nil,
        movement_target = global.lieutenant.movement.target,
        action_queue_length = #global.lieutenant.actions.queue,
        current_action = global.lieutenant.actions.current,
        inventory_item_count = table_size(inv_counts),
        stats = global.lieutenant.stats,
    }
end

--- Handle lieutenant death — respawn.
function lieutenant.on_death(event)
    if global.lieutenant and global.lieutenant.character == event.entity then
        global.lieutenant.character = nil
        -- Will respawn on next ensure() call
        game.print("[World Mode] Lieutenant died! Respawning...")
    end
end

return lieutenant
```

**Step 2: Add `on_init` and death handler to `control.lua`**

Add at top of control.lua after existing requires:
```lua
local lieutenant = require("scripts.lieutenant")
```

Add event handlers at bottom of control.lua:
```lua
-- ─────────────────────────────────────────────
-- Event Handlers
-- ─────────────────────────────────────────────

script.on_event(defines.events.on_entity_died, function(event)
    lieutenant.on_death(event)
end)

script.on_init(function()
    global.lieutenant = nil -- Will be created on first RCON command
end)

script.on_load(function()
    -- global is restored from save automatically
end)
```

**Step 3: Update all RCON commands to use lieutenant instead of `game.get_player(1)`**

In every RCON command handler in control.lua, replace:
```lua
local player = game.get_player(1)
if not player then
    rcon.print(json.encode({error = "No player found"}))
    return
end
```
With:
```lua
local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
if not char then
    rcon.print(json.encode({error = "Lieutenant not available"}))
    return
end
```

And replace all `player.surface` with `char.surface`, `player.force` with `char.force`, `player.position` with `char.position`, `player.get_main_inventory()` with `char.get_inventory(defines.inventory.character_main)`.

**Step 4: Add `/wm-lieutenant` RCON command**

```lua
commands.add_command("wm-lieutenant", "Get lieutenant status", function(cmd)
    local lt = require("scripts.lieutenant")
    local char = lt.ensure(game.surfaces["nauvis"], game.forces["player"])
    rcon.print(json.encode(lt.status()))
end)
```

**Step 5: Test lieutenant spawning**

Via Python RCON test script, send `/wm-lieutenant` and verify JSON response with `alive: true`.

**Step 6: Commit**

```bash
git add mod/world-mode-bridge/scripts/lieutenant.lua mod/world-mode-bridge/control.lua
git commit -m "feat: add lieutenant character module for legit mode"
```

---

### Task 2: Movement System

**Files:**
- Create: `mod/world-mode-bridge/scripts/movement.lua`
- Modify: `mod/world-mode-bridge/control.lua`

**Step 1: Create `scripts/movement.lua`**

```lua
-- scripts/movement.lua
-- Handles walking and teleportation for the lieutenant character.

local movement = {}

local WALK_THRESHOLD = 50  -- tiles; above this, teleport
local STUCK_THRESHOLD = 60 -- ticks stuck before trying alternative

--- Set a movement target. Character will walk or teleport depending on distance.
--- @param character LuaEntity
--- @param target table {x, y}
function movement.move_to(character, target)
    local pos = character.position
    local dx = target.x - pos.x
    local dy = target.y - pos.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 1 then
        -- Already there
        global.lieutenant.movement.target = nil
        return "arrived"
    end

    if dist > WALK_THRESHOLD then
        -- Teleport for long distances
        local tp = character.surface.find_non_colliding_position("character", target, 10, 1)
        if tp then
            character.teleport(tp)
            global.lieutenant.movement.target = nil
            return "teleported"
        else
            return "blocked"
        end
    end

    -- Walk
    global.lieutenant.movement.target = { x = target.x, y = target.y }
    global.lieutenant.movement.stuck_ticks = 0
    return "walking"
end

--- Called every tick to process walking.
--- @param character LuaEntity
function movement.tick(character)
    local mv = global.lieutenant.movement
    if not mv.target then return end

    local pos = character.position
    local tx, ty = mv.target.x, mv.target.y
    local dx = tx - pos.x
    local dy = ty - pos.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Close enough?
    if dist < 1.5 then
        mv.target = nil
        character.walking_state = { walking = false }
        return
    end

    -- Determine walking direction (8-directional)
    local dir = movement.angle_to_direction(dx, dy)
    character.walking_state = { walking = true, direction = dir }

    -- Stuck detection
    if not mv.last_pos then mv.last_pos = { x = pos.x, y = pos.y } end
    local moved = math.abs(pos.x - mv.last_pos.x) + math.abs(pos.y - mv.last_pos.y)
    mv.last_pos = { x = pos.x, y = pos.y }

    if moved < 0.01 then
        mv.stuck_ticks = mv.stuck_ticks + 1
        if mv.stuck_ticks > STUCK_THRESHOLD then
            -- Try perpendicular direction
            local perp_dir = (dir + 2) % 8 -- 90 degrees
            character.walking_state = { walking = true, direction = perp_dir }
            if mv.stuck_ticks > STUCK_THRESHOLD * 2 then
                -- Give up and teleport
                local tp = character.surface.find_non_colliding_position("character", mv.target, 10, 1)
                if tp then character.teleport(tp) end
                mv.target = nil
                character.walking_state = { walking = false }
            end
        end
    else
        mv.stuck_ticks = 0
    end

    -- Track distance
    global.lieutenant.stats.distance_walked = global.lieutenant.stats.distance_walked + moved
end

--- Convert dx/dy to an 8-directional Factorio direction.
function movement.angle_to_direction(dx, dy)
    local angle = math.atan2(dy, dx) -- radians, 0 = east
    -- Factorio: 0=north, 1=NE, 2=east, 3=SE, 4=south, 5=SW, 6=west, 7=NW
    -- atan2: 0=east, pi/2=south, pi=west, -pi/2=north
    local sector = math.floor(((angle + math.pi) / (2 * math.pi) * 8 + 6.5) % 8)
    return sector
end

--- Check if the lieutenant is currently moving.
function movement.is_moving()
    return global.lieutenant.movement.target ~= nil
end

return movement
```

**Step 2: Add `on_tick` dispatcher to `control.lua`**

```lua
local movement = require("scripts.movement")

script.on_event(defines.events.on_tick, function(event)
    local char = lieutenant.get()
    if not char then return end

    -- Process movement
    movement.tick(char)
end)
```

**Step 3: Add `/wm-walk` RCON command**

```lua
commands.add_command("wm-walk", "Walk lieutenant to position: /wm-walk x y", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, tonumber(word))
        end
    end
    if #args < 2 then
        rcon.print(json.encode({error = "Usage: /wm-walk x y"}))
        return
    end
    local result = movement.move_to(char, {x = args[1], y = args[2]})
    rcon.print(json.encode({status = result, target = {x = args[1], y = args[2]}}))
end)
```

**Step 4: Test walking**

Send `/wm-walk 10 10` via RCON, then poll `/wm-lieutenant` to see position change.

**Step 5: Commit**

```bash
git add mod/world-mode-bridge/scripts/movement.lua mod/world-mode-bridge/control.lua
git commit -m "feat: add hybrid walk/teleport movement system for lieutenant"
```

---

### Task 3: Legit Actions (Mine, Craft, Place)

**Files:**
- Create: `mod/world-mode-bridge/scripts/actions.lua`
- Modify: `mod/world-mode-bridge/control.lua`

**Step 1: Create `scripts/actions.lua`**

```lua
-- scripts/actions.lua
-- Legit gameplay actions: mining, crafting, placement.
-- All actions consume real items and take real time.

local movement = require("scripts.movement")
local json = require("scripts.json")

local actions = {}

local INTERACT_RANGE = 6 -- tiles; standard player reach

--- Check if character is close enough to interact with a position.
local function in_range(character, pos)
    local dx = character.position.x - pos.x
    local dy = character.position.y - pos.y
    return math.sqrt(dx * dx + dy * dy) <= INTERACT_RANGE
end

--- Mine an entity. Character must be in range.
--- @param character LuaEntity
--- @param target LuaEntity entity to mine
--- @return table {success, message}
function actions.mine(character, target)
    if not target or not target.valid then
        return { success = false, error = "Invalid target entity" }
    end

    if not in_range(character, target.position) then
        -- Auto-walk to target first
        movement.move_to(character, target.position)
        return { success = false, error = "Too far — walking to target. Retry after arrival." }
    end

    -- Use player.mine_entity if character is a player, otherwise simulate
    local products = target.prototype.mineable_properties
    if not products or not products.minable then
        return { success = false, error = target.name .. " is not minable" }
    end

    -- Add mined items to character inventory
    local inv = character.get_inventory(defines.inventory.character_main)
    if inv and products.products then
        for _, product in pairs(products.products) do
            if product.name then
                local amount = product.amount or 1
                inv.insert{name = product.name, count = amount}
            end
        end
    end

    local name = target.name
    target.destroy()
    return { success = true, message = "Mined " .. name }
end

--- Craft items using the character's hand-crafting.
--- @param character LuaEntity
--- @param recipe string recipe name
--- @param count number how many to craft
--- @return table {success, message}
function actions.craft(character, recipe, count)
    count = count or 1

    -- Check if recipe exists and is enabled
    local recipe_proto = character.force.recipes[recipe]
    if not recipe_proto then
        return { success = false, error = "Unknown recipe: " .. recipe }
    end
    if not recipe_proto.enabled then
        return { success = false, error = "Recipe not yet researched: " .. recipe }
    end

    -- Check ingredients
    local inv = character.get_inventory(defines.inventory.character_main)
    if not inv then
        return { success = false, error = "No inventory" }
    end

    for _, ingredient in pairs(recipe_proto.ingredients) do
        local have = inv.get_item_count(ingredient.name)
        local need = ingredient.amount * count
        if have < need then
            return {
                success = false,
                error = "Missing " .. ingredient.name .. ": need " .. need .. ", have " .. have,
            }
        end
    end

    -- Consume ingredients
    for _, ingredient in pairs(recipe_proto.ingredients) do
        inv.remove{name = ingredient.name, count = ingredient.amount * count}
    end

    -- Add products
    for _, product in pairs(recipe_proto.products) do
        local amount = (product.amount or 1) * count
        inv.insert{name = product.name, count = amount}
    end

    global.lieutenant.stats.items_crafted = global.lieutenant.stats.items_crafted + count
    return { success = true, message = "Crafted " .. count .. "x " .. recipe }
end

--- Place an entity from character inventory.
--- @param character LuaEntity
--- @param name string entity prototype name
--- @param pos table {x, y}
--- @param direction defines.direction?
--- @return table {success, message, entity}
function actions.place(character, name, pos, direction)
    direction = direction or defines.direction.north
    local target = { x = pos.x or pos[1], y = pos.y or pos[2] }

    -- Check range
    if not in_range(character, target) then
        movement.move_to(character, target)
        return { success = false, error = "Too far — walking to target. Retry after arrival." }
    end

    -- Check inventory
    local inv = character.get_inventory(defines.inventory.character_main)
    if not inv then
        return { success = false, error = "No inventory" }
    end

    -- Map entity name to item name (usually the same, but not always)
    local item_name = name
    local item_count = inv.get_item_count(item_name)
    if item_count < 1 then
        return { success = false, error = "No " .. item_name .. " in inventory (have 0)" }
    end

    -- Check placement
    local surface = character.surface
    if not surface.can_place_entity{name = name, position = target, force = character.force, direction = direction} then
        -- Try to find nearby position
        local alt = surface.find_non_colliding_position(name, target, 10, 1)
        if alt then
            target = { x = alt.x, y = alt.y }
        else
            return { success = false, error = "Cannot place " .. name .. " at " .. target.x .. ", " .. target.y .. " (blocked)" }
        end
    end

    -- Place it
    local entity = surface.create_entity{
        name = name,
        position = target,
        direction = direction,
        force = character.force,
        player = nil, -- no player object for script character
    }

    if entity then
        inv.remove{name = item_name, count = 1}
        global.lieutenant.stats.entities_placed = global.lieutenant.stats.entities_placed + 1
        return { success = true, message = "Placed " .. name .. " at " .. math.floor(entity.position.x) .. ", " .. math.floor(entity.position.y) }
    else
        return { success = false, error = "Failed to place " .. name }
    end
end

--- Insert items from character inventory into an entity.
function actions.insert(character, entity, item_name, count)
    if not entity or not entity.valid then
        return { success = false, error = "Invalid entity" }
    end
    if not in_range(character, entity.position) then
        return { success = false, error = "Too far from " .. entity.name }
    end

    local inv = character.get_inventory(defines.inventory.character_main)
    local available = inv.get_item_count(item_name)
    local to_insert = math.min(count, available)
    if to_insert == 0 then
        return { success = false, error = "No " .. item_name .. " in inventory" }
    end

    local inserted = entity.insert{name = item_name, count = to_insert}
    if inserted > 0 then
        inv.remove{name = item_name, count = inserted}
    end
    return { success = true, message = "Inserted " .. inserted .. " " .. item_name .. " into " .. entity.name }
end

--- Extract items from an entity into character inventory.
function actions.extract(character, entity, item_name, count)
    if not entity or not entity.valid then
        return { success = false, error = "Invalid entity" }
    end
    if not in_range(character, entity.position) then
        return { success = false, error = "Too far from " .. entity.name }
    end

    local target_inv = entity.get_output_inventory() or entity.get_inventory(defines.inventory.chest)
    if not target_inv then
        return { success = false, error = entity.name .. " has no accessible inventory" }
    end

    local removed = target_inv.remove{name = item_name, count = count}
    if removed > 0 then
        local char_inv = character.get_inventory(defines.inventory.character_main)
        char_inv.insert{name = item_name, count = removed}
    end
    return { success = true, message = "Extracted " .. removed .. " " .. item_name .. " from " .. entity.name }
end

--- Pick up (mine) an entity back into inventory.
function actions.pickup(character, entity)
    if not entity or not entity.valid then
        return { success = false, error = "Invalid entity" }
    end
    if not in_range(character, entity.position) then
        return { success = false, error = "Too far from " .. entity.name }
    end

    local name = entity.name
    local inv = character.get_inventory(defines.inventory.character_main)
    inv.insert{name = name, count = 1}
    entity.destroy()
    return { success = true, message = "Picked up " .. name }
end

return actions
```

**Step 2: Add RCON commands for legit actions**

In `control.lua`, add:

```lua
local actions_mod = require("scripts.actions")

commands.add_command("wm-craft", "Craft items: /wm-craft recipe count", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, word)
        end
    end
    if #args < 1 then
        rcon.print(json.encode({error = "Usage: /wm-craft recipe [count]"}))
        return
    end
    local result = actions_mod.craft(char, args[1], tonumber(args[2]) or 1)
    rcon.print(json.encode(result))
end)

commands.add_command("wm-place", "Place entity: /wm-place name x y [direction]", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, word)
        end
    end
    if #args < 3 then
        rcon.print(json.encode({error = "Usage: /wm-place name x y [direction]"}))
        return
    end
    local dir_map = {
        north = defines.direction.north, south = defines.direction.south,
        east = defines.direction.east, west = defines.direction.west,
    }
    local dir = dir_map[args[4]] or defines.direction.north
    local result = actions_mod.place(char, args[1], {x = tonumber(args[2]), y = tonumber(args[3])}, dir)
    rcon.print(json.encode(result))
end)

commands.add_command("wm-mine", "Mine entity at position: /wm-mine x y [name]", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, word)
        end
    end
    if #args < 2 then
        rcon.print(json.encode({error = "Usage: /wm-mine x y [entity-name]"}))
        return
    end
    local pos = {x = tonumber(args[1]), y = tonumber(args[2])}
    local filter = {position = pos, radius = 2, limit = 1}
    if args[3] then filter.name = args[3] end
    local entities = char.surface.find_entities_filtered(filter)
    if #entities == 0 then
        rcon.print(json.encode({error = "No entity found at " .. pos.x .. ", " .. pos.y}))
        return
    end
    local result = actions_mod.mine(char, entities[1])
    rcon.print(json.encode(result))
end)
```

**Step 3: Test crafting and placement**

Test sequence via RCON:
1. `/wm-lieutenant` — verify character has starter items
2. `/wm-craft stone-furnace 1` — should succeed (has 5 stone from... wait, starter items only have iron-plate and stone-furnace. Let's test with what we have.)
3. `/wm-place stone-furnace 5 5` — place the starter furnace

**Step 4: Commit**

```bash
git add mod/world-mode-bridge/scripts/actions.lua mod/world-mode-bridge/control.lua
git commit -m "feat: add legit actions — mine, craft, place from inventory"
```

---

### Task 4: Blueprint & Ghost System

**Files:**
- Create: `mod/world-mode-bridge/scripts/blueprints.lua`
- Modify: `mod/world-mode-bridge/control.lua`

**Step 1: Create `scripts/blueprints.lua`**

```lua
-- scripts/blueprints.lua
-- Blueprint and ghost placement for construction bot workflows.

local json = require("scripts.json")

local blueprints = {}

--- Place a single ghost entity.
--- Ghosts are free to place — no inventory needed.
--- Construction bots will build them when materials are available.
function blueprints.place_ghost(surface, force, name, pos, direction)
    direction = direction or defines.direction.north
    local target = { x = pos.x or pos[1], y = pos.y or pos[2] }

    local ghost = surface.create_entity{
        name = "entity-ghost",
        inner_name = name,
        position = target,
        direction = direction,
        force = force,
    }

    if ghost then
        return { success = true, message = "Ghost placed: " .. name .. " at " .. math.floor(target.x) .. ", " .. math.floor(target.y) }
    else
        return { success = false, error = "Failed to place ghost for " .. name }
    end
end

--- Place a blueprint from a blueprint string.
--- Creates ghost entities that construction bots will build.
--- @param surface LuaSurface
--- @param force LuaForce
--- @param blueprint_string string base64 blueprint string (starts with "0")
--- @param pos table {x, y} anchor position
--- @param direction defines.direction? rotation
--- @return table {success, message, ghost_count}
function blueprints.place_blueprint_string(surface, force, blueprint_string, pos, direction)
    direction = direction or defines.direction.north
    local target = { x = pos.x or pos[1], y = pos.y or pos[2] }

    -- Create a temporary blueprint item stack to import the string
    local stack = game.create_inventory(1)[1]
    if not stack then
        return { success = false, error = "Failed to create temporary inventory for blueprint" }
    end

    -- Import the blueprint string
    local import_result = stack.import_stack(blueprint_string)
    if import_result ~= 0 then
        return { success = false, error = "Failed to import blueprint string (error code: " .. tostring(import_result) .. ")" }
    end

    if not stack.is_blueprint then
        -- Might be a blueprint book — try first blueprint
        if stack.is_blueprint_book then
            local book_inv = stack.get_inventory(defines.inventory.item_main)
            if book_inv and #book_inv > 0 then
                stack = book_inv[1]
                if not stack.is_blueprint then
                    return { success = false, error = "Blueprint book's first item is not a blueprint" }
                end
            else
                return { success = false, error = "Empty blueprint book" }
            end
        else
            return { success = false, error = "Imported string is not a blueprint or blueprint book" }
        end
    end

    -- Build the blueprint (creates ghost entities)
    local ghosts = stack.build_blueprint{
        surface = surface,
        force = force,
        position = target,
        direction = direction,
        force_build = true,  -- Place even if entities overlap (ghosts are fine)
    }

    local ghost_count = #ghosts
    return {
        success = true,
        message = "Blueprint placed: " .. ghost_count .. " ghost entities at " .. math.floor(target.x) .. ", " .. math.floor(target.y),
        ghost_count = ghost_count,
    }
end

--- Capture entities in an area as a blueprint string.
--- @param surface LuaSurface
--- @param force LuaForce
--- @param area table {{x1, y1}, {x2, y2}}
--- @return table {success, blueprint_string}
function blueprints.capture(surface, force, area)
    local stack = game.create_inventory(1)[1]
    if not stack then
        return { success = false, error = "Failed to create temporary inventory" }
    end

    stack.set_stack{name = "blueprint"}

    local entities = surface.find_entities_filtered{
        area = area,
        force = force,
    }

    if #entities == 0 then
        return { success = false, error = "No entities found in area" }
    end

    -- Create blueprint from entities
    local mapping = stack.create_blueprint{
        surface = surface,
        force = force,
        area = area,
    }

    if not mapping or table_size(mapping) == 0 then
        return { success = false, error = "Failed to create blueprint from area" }
    end

    local bp_string = stack.export_stack()
    return {
        success = true,
        blueprint_string = bp_string,
        entity_count = table_size(mapping),
        message = "Captured " .. table_size(mapping) .. " entities as blueprint",
    }
end

return blueprints
```

**Step 2: Add RCON commands for blueprints**

In `control.lua`:

```lua
local blueprints_mod = require("scripts.blueprints")

commands.add_command("wm-ghost", "Place ghost entity: /wm-ghost name x y [direction]", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, word)
        end
    end
    if #args < 3 then
        rcon.print(json.encode({error = "Usage: /wm-ghost name x y [direction]"}))
        return
    end
    local dir_map = {
        north = defines.direction.north, south = defines.direction.south,
        east = defines.direction.east, west = defines.direction.west,
    }
    local result = blueprints_mod.place_ghost(
        char.surface, char.force,
        args[1], {x = tonumber(args[2]), y = tonumber(args[3])},
        dir_map[args[4]] or defines.direction.north
    )
    rcon.print(json.encode(result))
end)

commands.add_command("wm-blueprint", "Place blueprint string at position: /wm-blueprint x y <string>", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    if not cmd.parameter then
        rcon.print(json.encode({error = "Usage: /wm-blueprint x y <blueprint_string>"}))
        return
    end
    -- Parse: first two tokens are x y, rest is the blueprint string
    local x_str, y_str, bp_string = cmd.parameter:match("^(%S+)%s+(%S+)%s+(.+)$")
    if not x_str or not bp_string then
        rcon.print(json.encode({error = "Usage: /wm-blueprint x y <blueprint_string>"}))
        return
    end
    local result = blueprints_mod.place_blueprint_string(
        char.surface, char.force,
        bp_string,
        {x = tonumber(x_str), y = tonumber(y_str)}
    )
    rcon.print(json.encode(result))
end)

commands.add_command("wm-capture", "Capture area as blueprint: /wm-capture x1 y1 x2 y2", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, tonumber(word))
        end
    end
    if #args < 4 then
        rcon.print(json.encode({error = "Usage: /wm-capture x1 y1 x2 y2"}))
        return
    end
    local result = blueprints_mod.capture(
        char.surface, char.force,
        {{args[1], args[2]}, {args[3], args[4]}}
    )
    rcon.print(json.encode(result))
end)
```

**Step 3: Test ghost placement**

Send `/wm-ghost transport-belt 10 10` and verify ghost appears in-game.

**Step 4: Commit**

```bash
git add mod/world-mode-bridge/scripts/blueprints.lua mod/world-mode-bridge/control.lua
git commit -m "feat: add blueprint and ghost placement system"
```

---

### Task 5: Update `wm.*` API for Legit Mode

**Files:**
- Modify: `mod/world-mode-bridge/scripts/api.lua`

**Step 1: Rewrite `api.lua` to use legit actions**

Replace the entire `api.lua` with the legit-mode version that delegates to `actions`, `movement`, and `blueprints` modules. The key changes:

- `wm.place()` → calls `actions.place()` (inventory check + range check)
- `wm.move_to()` → calls `movement.move_to()` (walk/teleport hybrid)
- `wm.craft()` → calls `actions.craft()` (ingredient check + consume)
- `wm.mine()` → calls `actions.mine()` (range check + real mining)
- `wm.place_ghost()` → calls `blueprints.place_ghost()`
- `wm.place_blueprint()` → calls `blueprints.place_blueprint_string()`
- `wm.capture_blueprint()` → calls `blueprints.capture()`
- Remove `wm.connect()` (place belts/pipes individually instead)
- `wm.insert()` → calls `actions.insert()` (range check)
- `wm.extract()` → calls `actions.extract()` (range check)

**Step 2: Test the full wm.* API via `/wm-exec`**

```lua
-- Test: walk to a tree, mine it, craft a wooden chest
local tree = wm.find("tree", nil, 50)
if tree and #tree > 0 then
    wm.walk_to(tree[1].position)
    -- (would need to wait for arrival, then:)
    -- wm.mine(tree[1])
    -- wm.craft("wooden-chest", 1)
end
```

**Step 3: Commit**

```bash
git add mod/world-mode-bridge/scripts/api.lua
git commit -m "feat: rewrite wm.* API for legit mode — all actions require inventory and proximity"
```

---

### Task 6: Update Rust MCP Tools

**Files:**
- Modify: `crates/wm-bridge/src/client.rs` — add new RCON convenience methods
- Modify: `crates/wm-core/src/mcp/tools.rs` — update tool descriptions, add new tools

**Step 1: Add RCON methods to `client.rs`**

```rust
// New methods on RconClient:
pub fn lieutenant_status(&self) -> Result<String> { self.execute("/wm-lieutenant") }
pub fn walk_to(&self, x: f64, y: f64) -> Result<String> { self.execute(&format!("/wm-walk {} {}", x, y)) }
pub fn craft(&self, recipe: &str, count: u32) -> Result<String> { self.execute(&format!("/wm-craft {} {}", recipe, count)) }
pub fn place(&self, name: &str, x: f64, y: f64, dir: &str) -> Result<String> { self.execute(&format!("/wm-place {} {} {} {}", name, x, y, dir)) }
pub fn mine_at(&self, x: f64, y: f64, name: Option<&str>) -> Result<String> { ... }
pub fn place_ghost(&self, name: &str, x: f64, y: f64, dir: &str) -> Result<String> { self.execute(&format!("/wm-ghost {} {} {} {}", name, x, y, dir)) }
pub fn place_blueprint(&self, x: f64, y: f64, bp_string: &str) -> Result<String> { self.execute(&format!("/wm-blueprint {} {} {}", x, y, bp_string)) }
```

**Step 2: Add MCP tool definitions for new actions**

Add tools: `lieutenant_status`, `walk_to`, `craft`, `place_entity`, `mine_entity`, `place_ghost`, `place_blueprint`, `capture_blueprint`.

Update `execute_lua` description to reference legit wm.* API.

**Step 3: Update `get_inventory` to use lieutenant's inventory**

The RCON command already uses lieutenant (from Task 1), so this should work automatically.

**Step 4: Build and test**

```bash
cargo build --release
# Test MCP handshake
echo '{"jsonrpc":"2.0","id":1,"method":"initialize",...}' | cargo run --release --bin wm-core -- --config configs/world-mode.toml mcp-serve 2>/dev/null
```

**Step 5: Commit**

```bash
git add crates/wm-bridge/src/client.rs crates/wm-core/src/mcp/tools.rs
git commit -m "feat: add legit mode MCP tools — craft, place, mine, blueprint"
```

---

### Task 7: Update SOUL.md and Documentation

**Files:**
- Modify: `SOUL.md`
- Modify: `mod/world-mode-bridge/control.lua` (remove `version` from docker-compose warning)

**Step 1: Update SOUL.md**

- Replace all wm.* API docs with legit versions
- Add new tools to tool reference
- Document lieutenant character concept
- Add legit mode constraints
- Update Phase 0 checklist

**Step 2: Commit**

```bash
git add SOUL.md
git commit -m "docs: update SOUL.md for legit mode — lieutenant character, no god mode"
```

---

### Task 8: Integration Test — Full Legit Loop

**Test sequence (all via RCON):**

1. `/wm-lieutenant` — character spawns with starter items
2. `/wm-walk 10 0` — walk to nearby position
3. Poll `/wm-lieutenant` until `moving: false`
4. `/wm-mine 10 0 tree` — mine a tree for wood (if nearby)
5. `/wm-craft wooden-chest 1` — craft a chest from wood
6. `/wm-place wooden-chest 12 0` — place it from inventory
7. `/wm-ghost transport-belt 15 0` — place a ghost
8. `/wm-lieutenant` — verify stats updated

**Commit:**

```bash
git commit -m "test: verify full legit mode loop — spawn, walk, mine, craft, place, ghost"
```
