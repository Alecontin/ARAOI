---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Lovers")
card.Replace = Card.CARD_REVERSE_LOVERS

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local rng = player:GetCardRNG(card.ID)

        local familiars = Helper.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST, {ItemType.ITEM_FAMILIAR})
        local familiar = Helper.Choice(Helper.Keys(familiars), nil, rng)
        if not familiar then
            player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        player:RemoveCollectible(familiar)
        Helper.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
    end, card.ID)

    ---@class EID
    if EID then
        local altar = CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR
        EID:addCard(card.ID,
            "#{{Collectible"..altar.."}} Removes a random familiar and spawns an item from the current room's item pool"..
            "#{{Card"..card.Replace.."}} If used without having any familiars, it will act like {{Card"..card.Replace.."}} The Lovers?"
        )
    end
end

return card