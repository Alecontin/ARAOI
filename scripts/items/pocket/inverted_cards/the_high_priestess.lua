local card = {}

card.ID = Isaac.GetCardIdByName("Inverted High Priestess")
card.Replace = Card.CARD_REVERSE_HIGH_PRIESTESS

---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)

        for _ = 1, 8 do
            player:AddSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL, false)
            player:GetHistory():RemoveHistoryItemByIndex(#player:GetHistory():GetCollectiblesHistory() - 1)
        end

        SaveData:CreateTimerInFrames("Remove Inverted High Priestess Effect From Player", 1800, player:GetPlayerIndex())
    end, card.ID)

    ---@param player_index integer
    Mod:AddCallback("Remove Inverted High Priestess Effect From Player", function (_, player_index)
        local player = Isaac.GetPlayer(player_index)
        for _ = 1, 8 do
            player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL)
        end
    end)

    ---@class EID
    if EID then
        local toenail = TrinketType.TRINKET_MOMS_TOENAIL
        EID:addCard(card.ID,
            "#{{MomBoss}} Activates the effects of {{Card"..card.Replace.."}} The High Priestess? and 8 {{Trinket"..toenail.."}} Mom's Toenail"
        )
        EID:addTarotClothMetadata(card.ID, "Twice! Yippee...?")
    end
end

return card