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

    storage.lieutenant.stats.items_crafted = storage.lieutenant.stats.items_crafted + count
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
        storage.lieutenant.stats.entities_placed = storage.lieutenant.stats.entities_placed + 1
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
        movement.move_to(character, entity.position)
        return { success = false, error = "Too far from " .. entity.name .. " — walking to target. Retry after arrival." }
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
        movement.move_to(character, entity.position)
        return { success = false, error = "Too far from " .. entity.name .. " — walking to target. Retry after arrival." }
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
        movement.move_to(character, entity.position)
        return { success = false, error = "Too far from " .. entity.name .. " — walking to target. Retry after arrival." }
    end

    local name = entity.name
    local inv = character.get_inventory(defines.inventory.character_main)
    inv.insert{name = name, count = 1}
    entity.destroy()
    return { success = true, message = "Picked up " .. name }
end

return actions
