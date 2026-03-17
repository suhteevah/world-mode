-- World Mode API Library (scripts/api.lua)
-- Provides high-level helper functions for Claude to use when generating Lua.
-- Called via wm.* in /wm-exec context.
--
-- Legit mode: all actions require inventory items and character proximity.
-- The character parameter is a LuaEntity (type "character"), NOT a LuaPlayer.
--
-- Example usage in /wm-exec:
--   wm.move_to({x=10, y=20})
--   local pos = wm.nearest_resource("iron-ore")
--   local ent = wm.place("boiler", pos, defines.direction.north)
--   wm.insert(ent, "coal", 20)
--   wm.craft("iron-gear-wheel", 5)
--   wm.print("Setup complete!")

local movement = require("scripts.movement")
local actions = require("scripts.actions")
local blueprints = require("scripts.blueprints")

local api = {}

--- Create a new API context bound to a specific character entity.
--- @param character LuaEntity  character entity (type "character")
--- @param output_buffer table  print() messages go here
--- @return table  -- the wm.* namespace
function api.create_context(character, output_buffer)
    local wm = {}
    local surface = character.surface
    local force = character.force

    --- Helper: unwrap an action result, printing message/error and returning appropriate value.
    local function unwrap(result, return_field)
        if result.success then
            if result.message then wm.print(result.message) end
            if return_field then return result[return_field] end
            return true
        else
            wm.print("ERROR: " .. (result.error or "unknown error"))
            return nil
        end
    end

    -- ── Output ──

    function wm.print(...)
        local parts = {}
        for _, v in ipairs({...}) do
            table.insert(parts, tostring(v))
        end
        table.insert(output_buffer, table.concat(parts, "\t"))
    end

    -- ── Movement ──

    --- Move the character to a position (walks short distances, teleports long ones).
    --- @param pos table {x, y}
    function wm.move_to(pos)
        local target = {x = pos.x or pos[1], y = pos.y or pos[2]}
        local result = movement.move_to(character, target)
        wm.print("Move to " .. target.x .. ", " .. target.y .. " — " .. result)
    end

    --- Walk to a position (alias for move_to).
    --- @param pos table {x, y}
    function wm.walk_to(pos)
        wm.move_to(pos)
    end

    -- ── Resource Finding ──

    --- Find the nearest resource of a given type.
    --- @param resource_name string e.g. "iron-ore", "copper-ore", "coal", "stone", "crude-oil"
    --- @param search_radius number? default 200
    --- @return table|nil {x, y} position of nearest resource
    function wm.nearest_resource(resource_name, search_radius)
        search_radius = search_radius or 200
        local pos = character.position
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
        local pos = character.position
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

    --- Place an entity from character inventory. Character must be in range and have the item.
    --- @param name string prototype name (e.g. "boiler", "steam-engine", "transport-belt")
    --- @param pos table {x, y}
    --- @param direction defines.direction? default north
    --- @return LuaEntity|nil
    function wm.place(name, pos, direction)
        local result = actions.place(character, name, pos, direction)
        if result.success then
            wm.print(result.message)
            return result.entity
        else
            wm.print("ERROR: " .. result.error)
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

    --- Insert items into an entity from character inventory. Character must be in range.
    --- @param entity LuaEntity
    --- @param item_name string
    --- @param count number
    --- @return number items actually inserted
    function wm.insert(entity, item_name, count)
        local result = actions.insert(character, entity, item_name, count)
        if result.success then
            wm.print(result.message)
            -- Parse the inserted count from the message
            local n = tonumber(string.match(result.message, "^Inserted (%d+)"))
            return n or count
        else
            wm.print("ERROR: " .. result.error)
            return 0
        end
    end

    --- Extract items from an entity into character inventory. Character must be in range.
    --- @param entity LuaEntity
    --- @param item_name string
    --- @param count number
    --- @return number items extracted
    function wm.extract(entity, item_name, count)
        local result = actions.extract(character, entity, item_name, count)
        if result.success then
            wm.print(result.message)
            local n = tonumber(string.match(result.message, "^Extracted (%d+)"))
            return n or count
        else
            wm.print("ERROR: " .. result.error)
            return 0
        end
    end

    --- Pick up (mine) an entity back into character inventory. Character must be in range.
    --- @param entity LuaEntity
    function wm.pickup(entity)
        unwrap(actions.pickup(character, entity))
    end

    -- ── Crafting ──

    --- Hand-craft items. Requires ingredients in character inventory.
    --- @param recipe string recipe name (e.g. "iron-gear-wheel")
    --- @param count number? how many to craft (default 1)
    function wm.craft(recipe, count)
        unwrap(actions.craft(character, recipe, count))
    end

    -- ── Mining ──

    --- Mine an entity or the entity at a position. Character must be in range.
    --- @param entity_or_pos LuaEntity|table  entity to mine, or {x, y} position to find entity at
    function wm.mine(entity_or_pos)
        local target = entity_or_pos
        -- If it looks like a position (table with x/y or numeric indices, but no .valid), find entity there
        if type(entity_or_pos) == "table" and not entity_or_pos.valid then
            local pos = {x = entity_or_pos.x or entity_or_pos[1], y = entity_or_pos.y or entity_or_pos[2]}
            local entities = surface.find_entities_filtered{
                position = pos,
                radius = 1,
                limit = 1,
            }
            if #entities == 0 then
                wm.print("ERROR: No entity found at " .. pos.x .. ", " .. pos.y)
                return
            end
            target = entities[1]
        end
        unwrap(actions.mine(character, target))
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

    -- ── Blueprints ──

    --- Place a ghost entity (free, no inventory needed). Construction bots will build it.
    --- @param name string entity prototype name
    --- @param pos table {x, y}
    --- @param direction defines.direction?
    function wm.place_ghost(name, pos, direction)
        unwrap(blueprints.place_ghost(surface, force, name, pos, direction))
    end

    --- Place a blueprint from a blueprint string. Creates ghost entities.
    --- @param blueprint_string string base64 blueprint string
    --- @param pos table {x, y} anchor position
    --- @param direction defines.direction? rotation
    --- @return number|nil ghost_count
    function wm.place_blueprint(blueprint_string, pos, direction)
        local result = blueprints.place_blueprint_string(surface, force, blueprint_string, pos, direction)
        if result.success then
            wm.print(result.message)
            return result.ghost_count
        else
            wm.print("ERROR: " .. result.error)
            return nil
        end
    end

    --- Capture entities in an area as a blueprint string.
    --- @param area table {{x1, y1}, {x2, y2}}
    --- @return string|nil blueprint_string
    function wm.capture_blueprint(area)
        local result = blueprints.capture(surface, force, area)
        if result.success then
            wm.print(result.message)
            return result.blueprint_string
        else
            wm.print("ERROR: " .. result.error)
            return nil
        end
    end

    -- ── Timing ──

    --- Wait for a number of ticks. NOTE: This is NOT a real sleep — it's synchronous.
    --- For async waits, use on_nth_tick handlers in the mod.
    function wm.wait_ticks(ticks)
        wm.print("Note: wait_ticks is a no-op in RCON exec. Use observe_state to check progress.")
    end

    -- ── Utility ──

    --- Get character's current position.
    --- @return table {x, y}
    function wm.position()
        return {x = character.position.x, y = character.position.y}
    end

    --- Get count of an item in character inventory.
    --- @param item_name string
    --- @return number
    function wm.count(item_name)
        local inv = character.get_inventory(defines.inventory.character_main)
        if not inv then return 0 end
        return inv.get_item_count(item_name)
    end

    --- Get all entities of a type in an area.
    --- @param name string? entity name filter
    --- @param center table? {x,y} search center (default: character pos)
    --- @param radius number? search radius (default: 50)
    --- @return table[] list of entities
    function wm.find(name, center, radius)
        center = center or character.position
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
