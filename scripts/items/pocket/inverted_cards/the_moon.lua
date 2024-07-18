local moon = Isaac.GetCardIdByName("Inverted Moon")
local reverse = Card.CARD_REVERSE_MOON

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local rng = player:GetCardRNG(moon)

        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DICE_FLOOR, rng:RandomInt(6), room:GetCenterPos(), Vector.Zero, player)
    end, moon)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return moon
        end
    end)

    ---@class EID
    if EID then
        local tmt = CollectibleType.COLLECTIBLE_TMTRAINER
        EID:addCard(moon,
            "#{{DiceRoom}} Spawns a random Dice Room floor"
        )
    end
end

return card