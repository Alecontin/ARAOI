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
        player:AddSmeltedTrinket(TrinketType.TRINKET_DEVILS_CROWN)
        queueRemoveDevilsCrown(player, true)

        local level = game:GetLevel()

        local treasure_idx = level:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, player:GetCardRNG(card.ID))

        game:StartRoomTransition(treasure_idx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT)
    end, card.ID)

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function (_)
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if queueRemoveDevilsCrown(player) then
                player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_DEVILS_CROWN)
                queueRemoveDevilsCrown(player, false)
            end
        end
    end)

    ---@type EID
    if EID then
        local devils_crown = TrinketType.TRINKET_DEVILS_CROWN
        EID:addCard(card.ID,
            "#{{TreasureRoom}} Teleports Isaac to the {{Trinket"..devils_crown.."}} Devil's Crown Treasure Room"
        )
    end
end

return card