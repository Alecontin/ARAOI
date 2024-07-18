local hermit = Isaac.GetCardIdByName("Inverted Hermit")
local reverse = Card.CARD_REVERSE_HERMIT

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local collectibles = player:GetHistory():GetCollectiblesHistory()

        local collectible = collectibles[#collectibles]
        if collectible == nil then
            player:UseCard(reverse, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        local collectibleID = collectible:GetItemID()

        local config = Isaac.GetItemConfig():GetCollectible(collectibleID)

        player:RemoveCollectible(collectibleID)
        player:AnimateCollectible(collectibleID)

        if collectible:GetRoomType() == RoomType.ROOM_DEVIL and not Helper.IsKeeper(player) then
            player:AddMaxHearts(config.DevilPrice, true)
        else
            local coins = config.ShopPrice
            if Helper.IsKeeper(player) then
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
    end, hermit)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return hermit
        end
    end)

    ---@class EID
    if EID then
        local restock = CollectibleType.COLLECTIBLE_RESTOCK
        EID:addCard(hermit,
            "#{{Collectible"..restock.."}} Converts the last collectible picked up into {{Coin}} or {{EmptyHeart}} depending on the price and the room it was picked up"..
            "#{{Card"..reverse.."}} If used without having any collectibles, it will act like {{Card"..reverse.."}} The Hermit?"
        )
    end
end

return card