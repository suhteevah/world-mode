-- scripts/lieutenant.lua
-- Creates and manages Claude's in-game character ("The Lieutenant")

local lieutenant = {}

--- Dump all items from character inventory into a chest near the character.
--- Creates a wooden chest if needed. Used before destroying the character
--- so items aren't lost on mod updates.
--- @param character LuaEntity
local function dump_inventory_to_chest(character)
    if not character or not character.valid then return end

    local inv = character.get_inventory(defines.inventory.character_main)
    if not inv or inv.is_empty() then return end

    local surface = character.surface
    local force = character.force
    local pos = character.position

    -- Find or create a chest near LT
    local chests = surface.find_entities_filtered{
        name = "wooden-chest",
        position = pos,
        radius = 10,
        force = force,
        limit = 1,
    }

    local chest = chests[1]
    if not chest then
        -- Create a chest at LT's position
        local chest_pos = surface.find_non_colliding_position("wooden-chest", pos, 10, 1)
        if chest_pos then
            chest = surface.create_entity{
                name = "wooden-chest",
                position = chest_pos,
                force = force,
            }
        end
    end

    if not chest then
        game.print("[World Mode] WARNING: Could not create chest to store LT inventory!")
        return
    end

    local chest_inv = chest.get_inventory(defines.inventory.chest)
    if not chest_inv then return end

    -- Transfer everything
    local transferred = 0
    for i = 1, #inv do
        local stack = inv[i]
        if stack and stack.valid_for_read then
            local inserted = chest_inv.insert(stack)
            if inserted > 0 then
                stack.count = stack.count - inserted
                transferred = transferred + inserted
            end
        end
    end

    if transferred > 0 then
        game.print("[World Mode] Stored " .. transferred .. " items in chest at " ..
            math.floor(chest.position.x) .. ", " .. math.floor(chest.position.y) ..
            " before mod update")
        -- Remember where we stored items so we can recover them
        storage.lieutenant_stash = {
            x = chest.position.x,
            y = chest.position.y,
        }
    end
end

--- Recover items from stash chest after respawning.
--- @param character LuaEntity
local function recover_stash(character)
    if not storage.lieutenant_stash then return end

    local stash_pos = storage.lieutenant_stash
    local surface = character.surface

    local chests = surface.find_entities_filtered{
        name = "wooden-chest",
        position = {x = stash_pos.x, y = stash_pos.y},
        radius = 2,
        limit = 1,
    }

    if #chests == 0 then
        storage.lieutenant_stash = nil
        return
    end

    local chest = chests[1]
    local chest_inv = chest.get_inventory(defines.inventory.chest)
    if not chest_inv then return end

    -- Move to the chest
    local dist = math.sqrt(
        (character.position.x - chest.position.x)^2 +
        (character.position.y - chest.position.y)^2
    )
    if dist > 6 then
        local tp = surface.find_non_colliding_position("character", chest.position, 5, 1)
        if tp then character.teleport(tp) end
    end

    -- Transfer everything back
    local char_inv = character.get_inventory(defines.inventory.character_main)
    if not char_inv then return end

    local recovered = 0
    for i = 1, #chest_inv do
        local stack = chest_inv[i]
        if stack and stack.valid_for_read then
            local inserted = char_inv.insert(stack)
            if inserted > 0 then
                stack.count = stack.count - inserted
                recovered = recovered + inserted
            end
        end
    end

    if recovered > 0 then
        game.print("[World Mode] Recovered " .. recovered .. " items from stash chest")
    end

    -- Clean up empty chest
    if chest_inv.is_empty() then
        chest.destroy()
        game.print("[World Mode] Stash chest cleaned up")
    end

    storage.lieutenant_stash = nil
end

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

    -- Give starter items only if there's no stash to recover
    if not storage.lieutenant_stash then
        local inv = character.get_inventory(defines.inventory.character_main)
        if inv then
            inv.insert{name = "iron-plate", count = 8}
            inv.insert{name = "wood", count = 1}
            inv.insert{name = "burner-mining-drill", count = 1}
            inv.insert{name = "stone-furnace", count = 1}
        end
    end

    storage.lieutenant.character = character
    game.print("[World Mode] Lieutenant spawned at " .. math.floor(pos.x) .. ", " .. math.floor(pos.y))

    -- Recover stashed items from previous mod update
    recover_stash(character)

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
        has_stash = storage.lieutenant_stash ~= nil,
    }
end

--- Dump inventory to chest before destroying the character.
--- Call this before any operation that will invalidate the character.
function lieutenant.prepare_for_removal()
    local char = lieutenant.get()
    if char then
        dump_inventory_to_chest(char)
    end
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
