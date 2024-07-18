local strength = Isaac.GetCardIdByName("Inverted Strength")
local reverse = Card.CARD_REVERSE_STRENGTH

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
                    entity:AddWeakness(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddWeakness(EntityRef(player), 150)
                    end, 30, 10, false)
                else
                    entity:AddWeakness(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddWeakness(EntityRef(player), 150)
                    end, 30, 999999, false)
                end
            end
        end
    end, strength)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return strength
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(strength,
            "#{{Weakness}} Applies weakness to all enemies in the room"
        )
    end
end

return card