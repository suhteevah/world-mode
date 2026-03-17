-- scripts/lieutenant.lua
-- Creates and manages Claude's in-game character ("The Lieutenant")

local lieutenant = {}

--- Initialize or recover the lieutenant character.
--- Called on server start and on first RCON command.
--- @return LuaEntity the character entity
function lieutenant.ensure(surface, force)
    -- Check for existing character in storage
    if storage.lieutenant and storage.lieutenant.character and storage.lieutenant.character.valid then
        return storage.lieutenant.character
    end

    -- Initialize storage state
    storage.lieutenant = storage.lieutenant or {}
    storage.lieutenant.movement = { target = nil, stuck_ticks = 0 }
    storage.lieutenant.actions = { queue = {}, current = nil }
    storage.lieutenant.stats = storage.lieutenant.stats or { items_crafted = 0, entities_placed = 0, distance_walked = 0 }

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

    storage.lieutenant.character = character
    game.print("[World Mode] Lieutenant spawned at " .. math.floor(pos.x) .. ", " .. math.floor(pos.y))

    return character
end

--- Get the lieutenant character, or nil if not yet created.
function lieutenant.get()
    if storage.lieutenant and storage.lieutenant.character and storage.lieutenant.character.valid then
        return storage.lieutenant.character
    end
    return nil
end

--- Get lieutenant status summary.
function lieutenant.status()
    local char = lieutenant.get()
    if not char then return { alive = false } end

    -- Factorio 2.0: get_contents() returns array of {name, quality, count}
    local inv_counts = {}
    local inv = char.get_inventory(defines.inventory.character_main)
    if inv then
        for _, stack in pairs(inv.get_contents()) do
            inv_counts[stack.name] = (inv_counts[stack.name] or 0) + stack.count
        end
    end

    return {
        alive = true,
        position = { x = char.position.x, y = char.position.y },
        health = char.health,
        surface = char.surface.name,
        moving = storage.lieutenant.movement.target ~= nil,
        movement_target = storage.lieutenant.movement.target,
        action_queue_length = #storage.lieutenant.actions.queue,
        current_action = storage.lieutenant.actions.current,
        inventory_item_count = table_size(inv_counts),
        stats = storage.lieutenant.stats,
    }
end

--- Handle lieutenant death — respawn.
function lieutenant.on_death(event)
    if storage.lieutenant and storage.lieutenant.character == event.entity then
        storage.lieutenant.character = nil
        -- Will respawn on next ensure() call
        game.print("[World Mode] Lieutenant died! Respawning...")
    end
end

return lieutenant
