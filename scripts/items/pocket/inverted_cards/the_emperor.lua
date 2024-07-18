local emperor = Isaac.GetCardIdByName("Inverted Emperor")
local reverse = Card.CARD_REVERSE_EMPEROR

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseActiveItem(CollectibleType.COLLECTIBLE_DELIRIOUS)
    end, emperor)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return emperor
        end
    end)

    ---@class EID
    if EID then
        local delirious = CollectibleType.COLLECTIBLE_DELIRIOUS
        EID:addCard(emperor,
            "#{{Collectible"..delirious.."}} Uses the Delirious active item"
        )
    end
end

return card