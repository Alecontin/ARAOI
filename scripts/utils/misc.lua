
---@class MiscUtils
local MiscUtils = {}

---@type TableUtils
local tableUtils = include("scripts.utils.table")

local game = Game()

-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isAngelItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_ANGEL or item_pool == ItemPoolType.POOL_GREED_ANGEL
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isBossItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_BOSS or item_pool == ItemPoolType.POOL_GREED_BOSS
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isCurseItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_CURSE or item_pool == ItemPoolType.POOL_GREED_CURSE
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isSecretItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_SECRET or item_pool == ItemPoolType.POOL_GREED_SECRET
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isShopItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_SHOP or item_pool == ItemPoolType.POOL_GREED_SHOP
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isTreasureItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_TREASURE or item_pool == ItemPoolType.POOL_GREED_TREASURE
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isDevilItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_DEVIL or item_pool == ItemPoolType.POOL_GREED_DEVIL
end

---@param H integer -- *Number between 0 and 360*
---@param S? number -- *Default: `1` — Number between 0 and 1*
---@param L? number -- *Default: `0.5` — Number between 0 and 1*
function MiscUtils.HSLtoRGB(H, S, L)
    H = H % 360
    S = S or 1
    L = L or 0.5

    -- C = (1 - |2L - 1|) × S
    local C = (1 - math.abs(2 * L - 1)) * S

    -- X = C × (1 - |(H / 60°) mod 2 - 1|)
    local X = C * (1 - math.abs((H / 60) % 2 - 1))

    -- m = L - C/2
    local m = L - C / 2

    local Rp, Gp, Bp

    if H >= 0 and H < 60 then
        Rp, Gp, Bp = C, X, 0
    elseif H >= 60 and H < 120 then
        Rp, Gp, Bp = X, C, 0
    elseif H >= 120 and H < 180 then
        Rp, Gp, Bp = 0, C, X
    elseif H >= 180 and H < 240 then
        Rp, Gp, Bp = 0, X, C
    elseif H >= 240 and H < 300 then
        Rp, Gp, Bp = X, 0, C
    elseif H >= 300 and H < 360 then
        Rp, Gp, Bp = C, 0, X
    else
        Rp, Gp, Bp = 0, 0, 0
    end

    return (Rp + m) * 255, (Gp + m) * 255, (Bp + m) * 255
end

function MiscUtils.Lerp(A, B, t)
    return A + (B - A) * t
end

function MiscUtils.IsAnyReverseCardUnlocked()
    local PGD = Isaac.GetPersistentGameData()
    for i = Achievement.REVERSED_FOOL, Achievement.REVERSED_WORLD, 1 do
        if PGD:Unlocked(i) == true then
            return true
        end
    end
    return false
end

---@param pennies integer
---@return integer dimes
---@return integer nickels
---@return integer pennies
function MiscUtils.PenniesToCoins(pennies)
    local dimes = math.floor(pennies / 10)
    pennies = pennies - dimes * 10

    local nickels = math.floor(pennies / 5)
    pennies = pennies - nickels * 5

    return dimes, nickels, pennies
end

---@param pennies integer
---@param position? Vector -- Default: `Game():GetRoom():FindFreePickupSpawnPosition(Game():GetRoom():GetCenterPos())`
---@param velocityMult? number -- Default: `1`
function MiscUtils.DropCompactedCoins(pennies, position, velocityMult)
    if position == nil then position = Game():GetRoom():FindFreePickupSpawnPosition(Game():GetRoom():GetCenterPos()) end
    if velocityMult == nil then velocityMult = 1 end

    dimes, nickels, pennies = MiscUtils.PenniesToCoins(pennies)

    local coins = dimes + nickels + pennies

    local function DropCoin()
        if dimes > 0 then
            dimes = dimes - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DIME, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        elseif nickels > 0 then
            nickels = nickels - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        else
            pennies = pennies - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        end
    end

    for _ = 1, coins do
        DropCoin()
    end
end

-- This function was directly copied from [The Official API](https://wofsauge.github.io/IsaacDocs/rep/Room.html#getdevilroomchance),
-- I changed the anyPlayerHasCollectible and anyPlayerHasTrinket functions with the Repentogon functions
---@return number DevilChance, number AngelChance
function MiscUtils.getDevilAngelRoomChance()
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local totalChance = math.min(room:GetDevilRoomChance(), 1.0)

    local angelRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_FAMINE_SPAWNED) -- repurposed
    local devilRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_SPAWNED)
    local devilRoomVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED)

    local devilRoomChance = 1.0
    if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_EUCHARIST) then
        devilRoomChance = 0.0
    elseif devilRoomSpawned and devilRoomVisited and game:GetDevilRoomDeals() > 0 then -- devil deals locked in
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or
        PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION) or
            level:GetAngelRoomChance() > 0.0 -- confessional, sac room
        then
            devilRoomChance = 0.5
        end
    elseif devilRoomSpawned or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or level:GetAngelRoomChance() > 0.0 then
        if not (devilRoomVisited or angelRoomSpawned) then
            devilRoomChance = 0.0
        else
            devilRoomChance = 0.5
        end
    end

    -- https://bindingofisaacrebirth.fandom.com/wiki/Angel_Room#Angel_Room_Generation_Chance
    if devilRoomChance == 0.5 then
        if PlayerManager.AnyoneHasTrinket(TrinketType.TRINKET_ROSARY_BEAD) then
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if game:GetDonationModAngel() >= 10 then -- donate 10 coins
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 - 0.1)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 + 0.1)
        end
        if level:GetAngelRoomChance() > 0.0 or
            (level:GetAngelRoomChance() < 0.0 and (PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION)))
        then
            devilRoomChance = devilRoomChance * (1.0 - level:GetAngelRoomChance())
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        devilRoomChance = math.max(0.0, math.min(devilRoomChance, 1.0))
    end

    local angelRoomChance = 1.0 - devilRoomChance
    return totalChance * devilRoomChance, totalChance * angelRoomChance
end

return MiscUtils