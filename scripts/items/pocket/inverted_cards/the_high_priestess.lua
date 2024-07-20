---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param player EntityPlayer
---@param set? integer
local function CardEffect(player, set)
    return SaveData:Data(SaveData.RUN, "CardEffectInvertedHighPriestess", {}, Helper.GetPlayerId(player), -1, set)
end

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted High Priestess")
card.Replace = Card.CARD_REVERSE_HIGH_PRIESTESS

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)

        CardEffect(player, 1800)

        for _ = 1, 8 do
            player:AddSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL, false)
        end
    end, card.ID)

    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if CardEffect(player) > 0 then
                CardEffect(player, CardEffect(player) - 1)
            elseif CardEffect(player) == 0 then
                for _ = 1, 8 do
                    player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL)
                end
                CardEffect(player, -1)
            end
        end
    end)

    ---@class EID
    if EID then
        local toenail = TrinketType.TRINKET_MOMS_TOENAIL
        EID:addCard(card.ID,
            "#{{MomBoss}} Activates the effects of {{Card"..card.Replace.."}} The High Priestess? and 8 {{Trinket"..toenail.."}} Mom's Toenail"
        )
    end
end

return card