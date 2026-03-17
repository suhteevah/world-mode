-- World Mode Bridge — control.lua
-- RCON command interface for AI-cooperative Factorio gameplay.
-- Exposes game state observation and structured command execution.
--
-- Architecture: Rust MCP server → RCON → this mod → Factorio API
-- Claude Code generates Lua using the wm.* helper library (see scripts/api.lua)

local json = require("scripts.json")
local api = require("scripts.api")
local lieutenant = require("scripts.lieutenant")

-- ─────────────────────────────────────────────
-- State tracking
-- ─────────────────────────────────────────────

-- Cached state for diffing
local last_snapshot = nil
local snapshot_count = 0
local action_log = {}

-- ─────────────────────────────────────────────
-- RCON Commands
-- ─────────────────────────────────────────────

-- /wm-state [compact]
-- Returns full game state as JSON.
-- With "compact" arg, omits entity details (just counts).
commands.add_command("wm-state", "Get full game state as JSON", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    if not char then
        rcon.print(json.encode({error = "Lieutenant not available"}))
        return
    end

    local compact = cmd.parameter == "compact"
    local surface = char.surface
    local force = char.force

    -- Entities
    local entities = {}
    local entity_counts = {}
    if not compact then
        local all_entities = surface.find_entities_filtered{force = force}
        for _, ent in pairs(all_entities) do
            if ent.valid then
                local entry = {
                    name = ent.name,
                    type = ent.type,
                    position = {x = ent.position.x, y = ent.position.y},
                    direction = ent.direction,
                    health = ent.health,
                    energy = ent.energy or 0,
                }

                -- Entity-specific properties
                if ent.type == "assembling-machine" and ent.get_recipe() then
                    entry.recipe = ent.get_recipe().name
                end
                if ent.type == "mining-drill" and ent.mining_target then
                    entry.mining_target = ent.mining_target.name
                end

                -- Inventory contents for containers
                local inv = ent.get_output_inventory()
                if inv then
                    local contents = inv.get_contents()
                    if next(contents) then
                        entry.output_inventory = {}
                        for item_name, item_data in pairs(contents) do
                            -- Factorio 2.0: contents returns {name, count} or similar
                            if type(item_data) == "number" then
                                entry.output_inventory[item_name] = item_data
                            elseif type(item_data) == "table" and item_data.count then
                                entry.output_inventory[item_name] = item_data.count
                            end
                        end
                    end
                end

                -- Warnings / status
                entry.status = ent.status and ent.status.name or nil

                table.insert(entities, entry)
                entity_counts[ent.name] = (entity_counts[ent.name] or 0) + 1
            end
        end
    else
        -- Compact mode: just count entities
        local all_entities = surface.find_entities_filtered{force = force}
        for _, ent in pairs(all_entities) do
            if ent.valid then
                entity_counts[ent.name] = (entity_counts[ent.name] or 0) + 1
            end
        end
    end

    -- Lieutenant inventory
    local inventory = {}
    local main_inv = char.get_inventory(defines.inventory.character_main)
    if main_inv then
        local contents = main_inv.get_contents()
        for item_name, item_data in pairs(contents) do
            if type(item_data) == "number" then
                inventory[item_name] = item_data
            elseif type(item_data) == "table" and item_data.count then
                inventory[item_name] = item_data.count
            end
        end
    end

    -- Production statistics
    local production = {
        input = {},
        output = {},
    }
    local input_stats = force.get_item_production_statistics("input")
    local output_stats = force.get_item_production_statistics("output")
    -- Note: production_statistics API varies by Factorio version
    -- This is a simplified version

    -- Research
    local research = {
        current = force.current_research and force.current_research.name or nil,
        progress = force.research_progress or 0,
        researched = {},
    }
    for name, tech in pairs(force.technologies) do
        if tech.researched then
            table.insert(research.researched, name)
        end
    end

    -- Build response
    local state = {
        tick = game.tick,
        elapsed_time = game.tick / 60.0,
        player_position = {x = char.position.x, y = char.position.y},
        entities = compact and nil or entities,
        entity_counts = entity_counts,
        entity_total = compact and table_size(entity_counts) or #entities,
        inventory = inventory,
        research = research,
        surface_name = surface.name,
        daytime = surface.daytime,
        snapshot_id = snapshot_count,
    }

    snapshot_count = snapshot_count + 1
    last_snapshot = state

    rcon.print(json.encode(state))
end)


-- /wm-inventory
-- Returns just the player inventory (lightweight).
commands.add_command("wm-inventory", "Get lieutenant inventory as JSON", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    if not char then
        rcon.print(json.encode({error = "Lieutenant not available"}))
        return
    end

    local inventory = {}
    local main_inv = char.get_inventory(defines.inventory.character_main)
    if main_inv then
        local contents = main_inv.get_contents()
        for item_name, item_data in pairs(contents) do
            if type(item_data) == "number" then
                inventory[item_name] = item_data
            elseif type(item_data) == "table" and item_data.count then
                inventory[item_name] = item_data.count
            end
        end
    end

    rcon.print(json.encode(inventory))
end)


-- /wm-entities [type] [x] [y] [radius]
-- Query entities by type and/or area.
commands.add_command("wm-entities", "Query entities by type/area", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    if not char then
        rcon.print(json.encode({error = "Lieutenant not available"}))
        return
    end

    local args = {}
    if cmd.parameter then
        for word in cmd.parameter:gmatch("%S+") do
            table.insert(args, word)
        end
    end

    local filter = {force = char.force}
    if args[1] and args[1] ~= "*" then
        filter.name = args[1]
    end
    if args[2] and args[3] and args[4] then
        local cx, cy, r = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
        if cx and cy and r then
            filter.area = {
                {cx - r, cy - r},
                {cx + r, cy + r}
            }
        end
    end

    local entities = {}
    local found = char.surface.find_entities_filtered(filter)
    for _, ent in pairs(found) do
        if ent.valid then
            table.insert(entities, {
                name = ent.name,
                type = ent.type,
                position = {x = ent.position.x, y = ent.position.y},
                direction = ent.direction,
                health = ent.health,
                energy = ent.energy or 0,
                status = ent.status and ent.status.name or nil,
            })
        end
    end

    rcon.print(json.encode({count = #entities, entities = entities}))
end)


-- /wm-exec <lua code>
-- Execute arbitrary Lua code in the game context.
-- The code has access to the wm.* API library (see scripts/api.lua).
-- Output is captured via wm.print() and returned as JSON.
commands.add_command("wm-exec", "Execute Lua code with wm.* API", function(cmd)
    if not cmd.parameter or cmd.parameter == "" then
        rcon.print(json.encode({success = false, error = "No code provided"}))
        return
    end

    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])

    -- Set up execution environment with the wm API
    local output_buffer = {}
    local env = setmetatable({
        wm = api.create_context(char, output_buffer),
        game = game,
        print = function(...)
            local parts = {}
            for _, v in ipairs({...}) do
                table.insert(parts, tostring(v))
            end
            table.insert(output_buffer, table.concat(parts, "\t"))
        end,
        assert = assert,
        error = error,
        pairs = pairs,
        ipairs = ipairs,
        tostring = tostring,
        tonumber = tonumber,
        type = type,
        table = table,
        string = string,
        math = math,
    }, {__index = _G})

    local fn, err = load(cmd.parameter, "wm-exec", "t", env)
    if not fn then
        rcon.print(json.encode({
            success = false,
            error = "Syntax error: " .. tostring(err),
            stdout = table.concat(output_buffer, "\n"),
        }))
        return
    end

    local ok, result = pcall(fn)
    local response = {
        success = ok,
        stdout = table.concat(output_buffer, "\n"),
    }
    if not ok then
        response.error = tostring(result)
    end

    -- Log action
    table.insert(action_log, {
        tick = game.tick,
        success = ok,
        code_preview = cmd.parameter:sub(1, 200),
    })
    -- Keep last 100 actions
    if #action_log > 100 then
        table.remove(action_log, 1)
    end

    rcon.print(json.encode(response))
end)


-- /wm-power
-- Get power grid status.
commands.add_command("wm-power", "Get power grid status", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    if not char then
        rcon.print(json.encode({error = "Lieutenant not available"}))
        return
    end

    local surface = char.surface
    local generators = surface.find_entities_filtered{
        force = char.force,
        type = {"generator", "solar-panel"},
    }

    local power_info = {
        generator_count = #generators,
        generators = {},
    }

    for _, gen in pairs(generators) do
        if gen.valid then
            table.insert(power_info.generators, {
                name = gen.name,
                position = {x = gen.position.x, y = gen.position.y},
                energy = gen.energy or 0,
            })
        end
    end

    -- Electric network stats (if available)
    local networks = {}
    for _, gen in pairs(generators) do
        if gen.valid and gen.electric_network_id then
            networks[gen.electric_network_id] = true
        end
    end
    power_info.network_count = 0
    for _ in pairs(networks) do
        power_info.network_count = power_info.network_count + 1
    end

    rcon.print(json.encode(power_info))
end)


-- /wm-chat <message>
-- Send a chat message from World Mode.
commands.add_command("wm-chat", "Send in-game chat from World Mode", function(cmd)
    if cmd.parameter then
        game.print("[World Mode] " .. cmd.parameter)
        rcon.print(json.encode({success = true}))
    end
end)


-- /wm-action-log
-- Get recent action history.
commands.add_command("wm-action-log", "Get recent action log", function(cmd)
    rcon.print(json.encode(action_log))
end)


-- /wm-lieutenant
-- Get lieutenant status.
commands.add_command("wm-lieutenant", "Get lieutenant status", function(cmd)
    local char = lieutenant.ensure(game.surfaces["nauvis"], game.forces["player"])
    rcon.print(json.encode(lieutenant.status()))
end)


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
