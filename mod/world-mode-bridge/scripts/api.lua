-- World Mode API Library (scripts/api.lua)
-- Provides high-level helper functions for Claude to use when generating Lua.
-- Called via wm.* in /wm-exec context.
--
-- Example usage in /wm-exec:
--   wm.move_to({x=10, y=20})
--   local pos = wm.nearest_resource("iron-ore")
--   local ent = wm.place("boiler", pos, defines.direction.north)
--   wm.insert(ent, "coal", 20)
--   wm.connect(pump, boiler, "pipe")
--   wm.print("Power setup complete!")

local api = {}

--- Create a new API context bound to a specific player.
--- @param player LuaPlayer
--- @param output_buffer table  -- print() messages go here
--- @return table  -- the wm.* namespace
function api.create_context(player, output_buffer)
    local wm = {}
    local surface = player.surface
    local force = player.force

    -- ── Output ──

    function wm.print(...)
        local parts = {}
        for _, v in ipairs({...}) do
            table.insert(parts, tostring(v))
        end
        table.insert(output_buffer, table.concat(parts, "\t"))
    end

    -- ── Movement ──

    --- Teleport the player to a position.
    --- @param pos table {x, y}
    function wm.move_to(pos)
        local target = {x = pos.x or pos[1], y = pos.y or pos[2]}
        player.teleport(target, surface)
        wm.print("Moved to " .. target.x .. ", " .. target.y)
    end

    -- ── Resource Finding ──

    --- Find the nearest resource of a given type.
    --- @param resource_name string e.g. "iron-ore", "copper-ore", "coal", "stone", "crude-oil"
    --- @param search_radius number? default 200
    --- @return table|nil {x, y} position of nearest resource
    function wm.nearest_resource(resource_name, search_radius)
        search_radius = search_radius or 200
        local pos = player.position
        local resources = surface.find_entities_filtered{
            name = resource_name,
            area = {{pos.x - search_radius, pos.y - search_radius},
                    {pos.x + search_radius, pos.y + search_radius}},
            limit = 1,
        }
        if #resources > 0 then
            local r = resources[1]
            wm.print("Found " .. resource_name .. " at " .. r.position.x .. ", " .. r.position.y)
            return {x = r.position.x, y = r.position.y}
        end
        wm.print("WARNING: No " .. resource_name .. " found within " .. search_radius .. " tiles")
        return nil
    end

    --- Find nearest water tile.
    --- @param search_radius number? default 200
    --- @return table|nil {x, y}
    function wm.nearest_water(search_radius)
        search_radius = search_radius or 200
        local pos = player.position
        -- Search in expanding rings
        for r = 1, search_radius, 2 do
            for dx = -r, r, 2 do
                for dy = -r, r, 2 do
                    local tp = {x = pos.x + dx, y = pos.y + dy}
                    local tile = surface.get_tile(tp.x, tp.y)
                    if tile and tile.valid and (
                        tile.name == "water" or
                        tile.name == "deepwater" or
                        tile.name == "water-green" or
                        tile.name == "deepwater-green"
                    ) then
                        wm.print("Found water at " .. tp.x .. ", " .. tp.y)
                        return tp
                    end
                end
            end
        end
        wm.print("WARNING: No water found within " .. search_radius .. " tiles")
        return nil
    end

    --- Find a buildable position near a reference point.
    --- @param entity_name string prototype name
    --- @param near table {x, y} reference position
    --- @param search_radius number? default 50
    --- @return table|nil {x, y}
    function wm.find_buildable(entity_name, near, search_radius)
        search_radius = search_radius or 50
        local ref = {x = near.x or near[1], y = near.y or near[2]}
        for r = 0, search_radius, 1 do
            for dx = -r, r do
                for _, dy in ipairs({-r, r}) do
                    local test_pos = {ref.x + dx, ref.y + dy}
                    if surface.can_place_entity{name = entity_name, position = test_pos, force = force} then
                        return {x = test_pos[1], y = test_pos[2]}
                    end
                end
            end
        end
        wm.print("WARNING: No buildable position for " .. entity_name .. " near " .. ref.x .. ", " .. ref.y)
        return nil
    end

    -- ── Entity Placement ──

    --- Place an entity from player inventory.
    --- @param name string prototype name (e.g. "boiler", "steam-engine", "transport-belt")
    --- @param pos table {x, y}
    --- @param direction defines.direction? default north
    --- @return LuaEntity|nil
    function wm.place(name, pos, direction)
        direction = direction or defines.direction.north
        local target = {x = pos.x or pos[1], y = pos.y or pos[2]}

        -- Check if player has the item
        local count = player.get_item_count(name)
        if count < 1 then
            wm.print("ERROR: No " .. name .. " in inventory (have " .. count .. ")")
            return nil
        end

        -- Check if position is buildable
        if not surface.can_place_entity{name = name, position = target, force = force, direction = direction} then
            -- Try to find a nearby buildable spot
            local alt = wm.find_buildable(name, target, 10)
            if alt then
                wm.print("Position blocked, using nearby spot: " .. alt.x .. ", " .. alt.y)
                target = alt
            else
                wm.print("ERROR: Cannot place " .. name .. " at " .. target.x .. ", " .. target.y .. " (blocked)")
                return nil
            end
        end

        local entity = surface.create_entity{
            name = name,
            position = target,
            direction = direction,
            force = force,
            player = player,
        }

        if entity then
            -- Remove from player inventory
            player.remove_item{name = name, count = 1}
            wm.print("Placed " .. name .. " at " .. entity.position.x .. ", " .. entity.position.y)
            return entity
        else
            wm.print("ERROR: Failed to place " .. name .. " (unknown reason)")
            return nil
        end
    end

    --- Place an entity adjacent to another entity.
    --- @param name string prototype name
    --- @param reference LuaEntity the entity to place next to
    --- @param direction defines.direction which side
    --- @param gap number? tiles of gap, default 0
    --- @return LuaEntity|nil
    function wm.place_next_to(name, reference, direction, gap)
        gap = gap or 0
        local ref_pos = reference.position
        local offset = {x = 0, y = 0}

        -- Calculate offset based on direction + entity sizes
        -- Simplified — assumes 1-tile offset, Claude can adjust
        local d = gap + 2
        if direction == defines.direction.north then offset.y = -d
        elseif direction == defines.direction.south then offset.y = d
        elseif direction == defines.direction.east then offset.x = d
        elseif direction == defines.direction.west then offset.x = -d
        end

        local target = {x = ref_pos.x + offset.x, y = ref_pos.y + offset.y}
        return wm.place(name, target, direction)
    end

    -- ── Item Management ──

    --- Insert items into an entity from player inventory.
    --- @param entity LuaEntity
    --- @param item_name string
    --- @param count number
    --- @return number items actually inserted
    function wm.insert(entity, item_name, count)
        if not entity or not entity.valid then
            wm.print("ERROR: Invalid entity for insert")
            return 0
        end

        local available = player.get_item_count(item_name)
        local to_insert = math.min(count, available)
        if to_insert == 0 then
            wm.print("ERROR: No " .. item_name .. " in inventory")
            return 0
        end

        local inserted = entity.insert{name = item_name, count = to_insert}
        if inserted > 0 then
            player.remove_item{name = item_name, count = inserted}
        end
        wm.print("Inserted " .. inserted .. " " .. item_name .. " into " .. entity.name)
        return inserted
    end

    --- Extract items from an entity into player inventory.
    --- @param entity LuaEntity
    --- @param item_name string
    --- @param count number
    --- @return number items extracted
    function wm.extract(entity, item_name, count)
        if not entity or not entity.valid then
            wm.print("ERROR: Invalid entity for extract")
            return 0
        end

        local inv = entity.get_output_inventory() or entity.get_inventory(defines.inventory.chest)
        if not inv then
            wm.print("ERROR: Entity has no accessible inventory")
            return 0
        end

        local removed = inv.remove{name = item_name, count = count}
        if removed > 0 then
            player.insert{name = item_name, count = removed}
        end
        wm.print("Extracted " .. removed .. " " .. item_name .. " from " .. entity.name)
        return removed
    end

    -- ── Entity Management ──

    --- Get an entity at a specific position.
    --- @param name string? filter by name (nil = any)
    --- @param pos table {x, y}
    --- @return LuaEntity|nil
    function wm.get_entity(name, pos)
        local target = {x = pos.x or pos[1], y = pos.y or pos[2]}
        local entities = surface.find_entities_filtered{
            position = target,
            radius = 1,
            name = name,
            limit = 1,
        }
        return entities[1]
    end

    --- Set the recipe on an assembling machine.
    --- @param entity LuaEntity
    --- @param recipe_name string
    function wm.set_recipe(entity, recipe_name)
        if entity and entity.valid and entity.type == "assembling-machine" then
            entity.set_recipe(recipe_name)
            wm.print("Set recipe on " .. entity.name .. " to " .. recipe_name)
        else
            wm.print("ERROR: Cannot set recipe — entity is not an assembling machine")
        end
    end

    --- Rotate an entity.
    --- @param entity LuaEntity
    --- @param direction defines.direction
    function wm.rotate(entity, direction)
        if entity and entity.valid then
            entity.direction = direction
            wm.print("Rotated " .. entity.name .. " to direction " .. direction)
        end
    end

    --- Pick up (destroy) an entity back into inventory.
    --- @param entity LuaEntity
    function wm.pickup(entity)
        if entity and entity.valid then
            local name = entity.name
            player.insert{name = name, count = 1}
            entity.destroy()
            wm.print("Picked up " .. name)
        end
    end

    -- ── Connection Helpers ──

    --- Connect two entities with pipes, belts, or power poles.
    --- This is a simplified version — draws a straight line of the connector entity.
    --- @param from LuaEntity source
    --- @param to LuaEntity destination
    --- @param connector_name string e.g. "pipe", "transport-belt", "medium-electric-pole"
    --- @return number entities placed
    function wm.connect(from, to, connector_name)
        if not from or not from.valid or not to or not to.valid then
            wm.print("ERROR: Invalid entities for connect")
            return 0
        end

        local fx, fy = from.position.x, from.position.y
        local tx, ty = to.position.x, to.position.y
        local placed = 0

        -- Determine primary direction
        local dx = tx - fx
        local dy = ty - fy

        -- Place along X axis first, then Y
        local step_x = dx > 0 and 1 or (dx < 0 and -1 or 0)
        local step_y = dy > 0 and 1 or (dy < 0 and -1 or 0)

        local cx, cy = fx, fy

        -- Walk X
        while math.abs(cx - fx) < math.abs(dx) do
            cx = cx + step_x
            local pos = {cx, cy}
            if surface.can_place_entity{name = connector_name, position = pos, force = force} then
                local count = player.get_item_count(connector_name)
                if count > 0 then
                    local ent = surface.create_entity{
                        name = connector_name,
                        position = pos,
                        force = force,
                        player = player,
                    }
                    if ent then
                        player.remove_item{name = connector_name, count = 1}
                        placed = placed + 1
                    end
                else
                    wm.print("WARNING: Ran out of " .. connector_name .. " after placing " .. placed)
                    return placed
                end
            end
        end

        -- Walk Y
        while math.abs(cy - fy) < math.abs(dy) do
            cy = cy + step_y
            local pos = {cx, cy}
            if surface.can_place_entity{name = connector_name, position = pos, force = force} then
                local count = player.get_item_count(connector_name)
                if count > 0 then
                    local ent = surface.create_entity{
                        name = connector_name,
                        position = pos,
                        force = force,
                        player = player,
                    }
                    if ent then
                        player.remove_item{name = connector_name, count = 1}
                        placed = placed + 1
                    end
                else
                    wm.print("WARNING: Ran out of " .. connector_name .. " after placing " .. placed)
                    return placed
                end
            end
        end

        wm.print("Connected with " .. placed .. " " .. connector_name)
        return placed
    end

    -- ── Timing ──

    --- Wait for a number of ticks. NOTE: This is NOT a real sleep — it's synchronous.
    --- For async waits, use on_nth_tick handlers in the mod.
    function wm.wait_ticks(ticks)
        wm.print("Note: wait_ticks is a no-op in RCON exec. Use observe_state to check progress.")
    end

    -- ── Utility ──

    --- Get player's current position.
    --- @return table {x, y}
    function wm.position()
        return {x = player.position.x, y = player.position.y}
    end

    --- Get count of an item in player inventory.
    --- @param item_name string
    --- @return number
    function wm.count(item_name)
        return player.get_item_count(item_name)
    end

    --- Get all entities of a type in an area.
    --- @param name string? entity name filter
    --- @param center table? {x,y} search center (default: player pos)
    --- @param radius number? search radius (default: 50)
    --- @return table[] list of entities
    function wm.find(name, center, radius)
        center = center or player.position
        radius = radius or 50
        local filter = {
            force = force,
            area = {{center.x - radius, center.y - radius},
                    {center.x + radius, center.y + radius}},
        }
        if name then filter.name = name end
        return surface.find_entities_filtered(filter)
    end

    return wm
end

return api
