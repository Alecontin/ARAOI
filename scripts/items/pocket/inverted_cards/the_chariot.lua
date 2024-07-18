local chariot = Isaac.GetCardIdByName("Inverted Chariot")
local reverse = Card.CARD_REVERSE_CHARIOT

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity:IsActiveEnemy() then
                if entity:IsBoss() then
                    entity:AddFreeze(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddFreeze(EntityRef(player), 150)
                    end, 30, 10, false)
                else
                    entity:AddFreeze(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddFreeze(EntityRef(player), 150)
                    end, 30, 999999, false)
                end
            end
        end
    end, chariot)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return chariot
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(chariot,
            "#{{Freezing}} Petrifies all enemies in the room"
        )
    end
end

return card