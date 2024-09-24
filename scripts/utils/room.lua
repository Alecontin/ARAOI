---@class RoomUtils
local RoomUtils = {}

-- RoomDescriptor doesn't have autocomplete, so I'm just
-- redefining the RoomDescriptor variables here for the code editor to help me out
RoomDescriptor.FLAG_CLEAR = 1 << 0
RoomDescriptor.FLAG_PRESSURE_PLATES_TRIGGERED = 1 << 1
RoomDescriptor.FLAG_SACRIFICE_DONE = 1 << 2
RoomDescriptor.FLAG_CHALLENGE_DONE = 1 << 3
RoomDescriptor.FLAG_SURPRISE_MINIBOSS = 1 << 4
RoomDescriptor.FLAG_HAS_WATER = 1 << 5
RoomDescriptor.FLAG_ALT_BOSS_MUSIC = 1 << 6
RoomDescriptor.FLAG_NO_REWARD = 1 << 7
RoomDescriptor.FLAG_FLOODED = 1 << 8
RoomDescriptor.FLAG_PITCH_BLACK = 1 << 9
RoomDescriptor.FLAG_RED_ROOM = 1 << 10
RoomDescriptor.FLAG_DEVIL_TREASURE = 1 << 11
RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP = 1 << 12
RoomDescriptor.FLAG_CURSED_MIST = 1 << 13
RoomDescriptor.FLAG_MAMA_MEGA = 1 << 14
RoomDescriptor.FLAG_NO_WALLS = 1 << 15
RoomDescriptor.FLAG_ROTGUT_CLEARED = 1 << 16
RoomDescriptor.FLAG_PORTAL_LINKED = 1 << 17
RoomDescriptor.FLAG_BLUE_REDIRECT = 1 << 18

-- Returns a list of all GridEntities in the current room
---@return GridEntity[]
function RoomUtils.GetGridEntities()
    local room = Game():GetRoom()

    local entities = {}

    for index = 1, room:GetGridSize() do
        local entity = room:GetGridEntity(index)
        if entity then
            table.insert(entities, entity)
        end
    end

    return entities
end

-- Returns a list of all Pickups in the current room
---@return EntityPickup[]
function RoomUtils.GetPickups()
    local pickups = {}

    for _, v in ipairs(Isaac.GetRoomEntities()) do
        local pickup = v:ToPickup()
        if pickup then
            table.insert(pickups, pickup)
        end
    end

    return pickups
end

return RoomUtils