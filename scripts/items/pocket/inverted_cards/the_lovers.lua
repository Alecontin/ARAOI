---@class helper
local helper = include("scripts.helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Lovers")
card.Replace = Card.CARD_REVERSE_LOVERS
card.REPLACE_CHANCE = 0.7

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local rng = player:GetCardRNG(card.ID)

        local familiars = helper.player.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST, {ItemType.ITEM_FAMILIAR})
        if #helper.table.Keys(familiars) == 0 then
            player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        -- Store this for later, so we can bypass damocles
        local removed_familiars = 0
        for familiar_id, familiar_amount in pairs(familiars) do
            for _ = 1, familiar_amount do
                player:RemoveCollectible(familiar_id)
                removed_familiars = removed_familiars + 1
            end
        end
        for _ = 1, removed_familiars do
            helper.item.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
        end
    end, card.ID)

    ---@class EID
    if EID then
        local altar = CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR
        EID:addCard(card.ID,
            "#{{Collectible"..altar.."}} Removes all familiars and spawns an item from the current room's item pool for each familiar removed"..
            "#{{Card"..card.Replace.."}} If used without having any familiars, it will act like {{Card"..card.Replace.."}} The Lovers?"
        )
    end
end

return card