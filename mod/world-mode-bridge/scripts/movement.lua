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
