local devil = Isaac.GetCardIdByName("Inverted Devil")
local reverse = Card.CARD_REVERSE_DEVIL

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param player EntityPlayer
local function QueueRemoveDevilsCrown(player, set)
    return SaveData:Data(SaveData.RUN, "InvertedDevilUseQueueDelete", {}, Helper.GetPlayerId(player), false, set)
end

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:AddSmeltedTrinket(TrinketType.TRINKET_DEVILS_CROWN)
        QueueRemoveDevilsCrown(player, true)

        local level = game:GetLevel()

        local treasure_idx = level:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, player:GetCardRNG(devil))

        game:StartRoomTransition(treasure_idx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT)
    end, devil)

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function (_)
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if QueueRemoveDevilsCrown(player) then
                player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_DEVILS_CROWN)
                QueueRemoveDevilsCrown(player, false)
            end
        end
    end)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return devil
        end
    end)

    ---@class EID
    if EID then
        local devils_crown = TrinketType.TRINKET_DEVILS_CROWN
        EID:addCard(devil,
            "#{{TreasureRoom}} Teleports Isaac to the {{Trinket"..devils_crown.."}} Devil's Crown Treasure Room"
        )
    end
end

return card