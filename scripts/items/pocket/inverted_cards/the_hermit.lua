local card = {}

card.ID = ARAOI.CardSubType.INVERTED_HERMIT
card.Replace = Card.CARD_REVERSE_HERMIT

ARAOI.Inverted_Cards.Hermit = card

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local collectibles = player:GetHistory():GetCollectiblesHistory()

    local collectible = collectibles[#collectibles]
    if collectible == nil then
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        return
    end

    local collectibleID = collectible:GetItemID()

    local config = Isaac.GetItemConfig():GetCollectible(collectibleID)

    if collectible:IsTrinket() then
        player:TryRemoveSmeltedTrinket(collectibleID)
        player:AnimateTrinket(collectibleID)
    else
        player:RemoveCollectible(collectibleID)
        player:AnimateCollectible(collectibleID)
    end

    if ARAOI.MiscUtils.isDevilItemPool(collectible:GetItemPoolType())
    and not ARAOI.PlayerUtils.IsKeeper(player) then
        player:AddMaxHearts(config.DevilPrice * 2, true)
    else
        local coins = config.ShopPrice
        if ARAOI.PlayerUtils.IsKeeper(player) then
            if ARAOI.MiscUtils.isDevilItemPool(collectible:GetItemPoolType()) then
                coins = coins * config.DevilPrice
            elseif player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B and ARAOI.MiscUtils.isAngelItemPool(collectible:GetItemPoolType()) then
                coins = coins * config.DevilPrice
            end
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
        "#{{Collectible"..restock.."}} Converts the last collectible picked up into {{Coin}} or {{EmptyHeart}} depending on the price and the pool it was picked up from"..
        "#{{Card"..card.Replace.."}} If used when not having any collectibles, it will act like {{Card"..card.Replace.."}} The Hermit?"
    )
end

return card