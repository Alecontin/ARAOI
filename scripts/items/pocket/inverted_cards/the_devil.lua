---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param player EntityPlayer
local function queueRemoveDevilsCrown(player, set)
    return SaveData:Data(SaveData.RUN, "InvertedDevilUseQueueDelete", {}, helper.player.GetID(player), false, set)
end

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Devil")
card.Replace = Card.CARD_REVERSE_DEVIL

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local level = game:GetLevel()

        local rng = player:GetCardRNG(card.ID)

        local treasure_room_idx = level:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, rng)
        local treasure_room = level:GetRoomByIdx(treasure_room_idx)

        if treasure_room.Data.Type == RoomType.ROOM_TREASURE and treasure_room.VisitedCount == 0 then
            treasure_room.Flags = treasure_room.Flags | RoomDescriptor.FLAG_DEVIL_TREASURE
        end

        game:StartRoomTransition(treasure_room_idx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT)
    end, card.ID)

    ---@class EID
    if EID then
        local devils_crown = TrinketType.TRINKET_DEVILS_CROWN

        EID:addCard(card.ID,
            "#{{RedTreasureRoom}} Teleports Isaac to the Treasure Room, turning it into a {{Trinket"..devils_crown.."}} Devil Treasure Room if it hasn't been visited yet"
        )
    end
end

return card