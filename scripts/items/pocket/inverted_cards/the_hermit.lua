---@class helper
local helper = include("scripts.helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Hermit")
card.Replace = Card.CARD_REVERSE_HERMIT

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local collectibles = player:GetHistory():GetCollectiblesHistory()

        local collectible = collectibles[#collectibles]
        if collectible == nil then
            player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        local collectibleID = collectible:GetItemID()

        local config = Isaac.GetItemConfig():GetCollectible(collectibleID)

        player:RemoveCollectible(collectibleID)
        player:AnimateCollectible(collectibleID)

        if collectible:GetItemPoolType() == ItemPoolType.POOL_DEVIL
        and not helper.player.IsKeeper(player) then
            player:AddMaxHearts(config.DevilPrice * 2, true)
        else
            local coins = config.ShopPrice
            if helper.player.IsKeeper(player) then
                coins = coins * config.DevilPrice
            end
            if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_STEAM_SALE) then
                coins = math.floor(coins / 2)
            end

            local dimes = math.floor(coins / 10)
            coins = coins - dimes * 10

            local nickels = math.floor(coins / 5)
            local pennies = coins - nickels * 5

            coins = dimes + nickels + pennies

            local function DropCoin()
                ---@type Vector
                local velocity = EntityPickup.GetRandomPickupVelocity(player.Position) / 2

                if dimes > 0 then
                    dimes = dimes - 1
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DIME, player.Position, velocity, player)
                elseif nickels > 0 then
                    nickels = nickels - 1
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL, player.Position, velocity, player)
                else
                    pennies = pennies - 1
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, player.Position, velocity, player)
                end
            end

            for _ = 1, coins do
                DropCoin()
            end
        end
    end, card.ID)

    ---@type EID
    if EID then
        local restock = CollectibleType.COLLECTIBLE_RESTOCK
        EID:addCard(card.ID,
            "#{{Collectible"..restock.."}} Converts the last collectible picked up into {{Coin}} or {{EmptyHeart}} depending on the price and the room it was picked up"..
            "#{{Card"..card.Replace.."}} If used without having any collectibles, it will act like {{Card"..card.Replace.."}} The Hermit?"
        )
    end
end

return card