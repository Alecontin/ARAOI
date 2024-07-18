local fool = Isaac.GetCardIdByName("Inverted Fool")
local reverse = Card.CARD_REVERSE_FOOL

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(fool)
        local room = game:GetRoom()

        local items = {}
        for item, amount in pairs(Helper.GetCollectibleListCurated(player, {ItemType.ITEM_ACTIVE}, ItemTag.TAG_QUEST)) do
            for _ = 1, amount do
                table.insert(items, item)
            end
        end

        Helper.ShuffleTable(items, rng)

        local pedestals = Helper.SplitTable(items, 10)

        for _, pedestal in ipairs(pedestals) do
            ---@type EntityPickup
            local collectible_pedestal
            for _, item in ipairs(pedestal) do
                player:RemoveCollectible(item)
                if collectible_pedestal == nil then
                    collectible_pedestal = Helper.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
                else
                    collectible_pedestal:AddCollectibleCycle(item)
                end
            end
        end
    end, fool)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return fool
        end
    end)

    ---@class EID
    if EID then
        local restock = CollectibleType.COLLECTIBLE_RESTOCK
        EID:addCard(fool,
            "#{{Collectible}} Drops all of Isaac's collectibles into 10 pedestals"..
            "#{{Collectible"..restock.."}} Excess items will be added to the pedestal's item cycle"
        )
    end
end

return card