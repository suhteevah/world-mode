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
