local magician = Isaac.GetCardIdByName("Inverted Magician")
local reverse = Card.CARD_REVERSE_MAGICIAN

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseCard(Card.CARD_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        player:UseCard(Card.CARD_REVERSE_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_FATE, true)
    end, magician)

    ---@param player EntityPlayer
    ---@param flag CacheFlag
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
        if flag == CacheFlag.CACHE_FLYING then
            if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_FATE) then
                player.CanFly = true
            end
        end
    end)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return magician
        end
    end)

    ---@class EID
    if EID then
        local the_magician = Card.CARD_MAGICIAN
        EID:addCard(magician,
            "#{{ArrowUp}} Activates the effects of both {{Card"..the_magician.."}} The Magician and {{Card"..reverse.."}} The Magician?, also gives you flight for the room"
        )
    end
end

return card