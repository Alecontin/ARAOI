local lovers = Isaac.GetCardIdByName("Inverted Lovers")
local reverse = Card.CARD_REVERSE_LOVERS

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
        local rng = player:GetCardRNG(lovers)

        local familiars = Helper.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST, {ItemType.ITEM_FAMILIAR})
        local familiar = Helper.Choice(Helper.Keys(familiars), nil, rng)
        if not familiar then
            player:UseCard(reverse, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        player:RemoveCollectible(familiar)
        Helper.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
    end, lovers)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return lovers
        end
    end)

    ---@class EID
    if EID then
        local altar = CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR
        EID:addCard(lovers,
            "#{{Collectible"..altar.."}} Removes a random familiar and spawns an item from the current room's item pool"..
            "#{{Card"..reverse.."}} If used without having any familiars, it will act like {{Card"..reverse.."}} The Lovers?"
        )
    end
end

return card