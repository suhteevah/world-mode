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
    global.lieutenant.stats = global.lieutenant.stats or { items_crafted = 0, entities_placed = 0, distance_walked = 0 }

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
        game.print("[World Mode] ERROR: Failed to create lieutenant character")
        return nil
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
