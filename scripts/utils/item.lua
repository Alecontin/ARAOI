---@class ItemUtils
local ItemUtils = {}

ChargeType = {
    Normal = 0,
    Timed = 1,
    Special = 2
}

ItemTag = {
    TAG_DEAD = 1 << 0,
    TAG_SYRINGE = 1 << 1,
    TAG_MOM = 1 << 2,
    TAG_TECH = 1 << 3,
    TAG_BATTERY = 1 << 4,
    TAG_GUPPY = 1 << 5,
    TAG_FLY = 1 << 6,
    TAG_BOB = 1 << 7,
    TAG_MUSHROOM = 1 << 8,
    TAG_BABY = 1 << 9,
    TAG_ANGEL = 1 << 10,
    TAG_DEVIL = 1 << 11,
    TAG_POOP = 1 << 12,
    TAG_BOOK = 1 << 13,
    TAG_SPIDER = 1 << 14,
    TAG_QUEST = 1 << 15,
    TAG_MONSTER_MANUAL = 1 << 16,
    TAG_NO_GREED = 1 << 17,
    TAG_FOOD = 1 << 18,
    TAG_TEARS_UP = 1 << 19,
    TAG_OFFENSIVE = 1 << 20,
    TAG_NO_KEEPER = 1 << 21,
    TAG_NO_LOST_BR = 1 << 22,
    TAG_STARS = 1 << 23,
    TAG_SUMMONABLE = 1 << 24,
    TAG_NO_CANTRIP = 1 << 25,
    TAG_WISP = 1 << 26,
    TAG_UNIQUE_FAMILIAR = 1 << 27,
    TAG_NO_CHALLENGE = 1 << 28,
    TAG_NO_DAILY = 1 << 29,
    TAG_LAZ_SHARED = 1 << 30,
    TAG_LAZ_SHARED_GLOBAL = 1 << 31,
    TAG_NO_EDEN = 1 << 32
}

local game = Game()

---@param entity Entity
---@param allowEmpty? boolean -- *Default: `false` — Should we count empty pedestals as collectibles?*
---@return boolean
function ItemUtils.IsCollectible(entity, allowEmpty)
    if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        if allowEmpty == true then
            return true
        elseif entity.SubType ~= 0 then
            return true
        end
    end
    return false
end

-- Helper function for spawning collectibles.
-- Should feel exactly like using Isaac.Spawn() only this
-- function has an IgnoreModifiers parameter which should keep items such as Glitched Crown
-- and players like T. Isaac from affecting the item.
--
-- This works by first spawning a dummy pickup (5.42.0) and then using the Morph() function
-- to change it into the desired collectible. If we were to first spawn the collectible then T. Isaac,
-- Glitched Crown, etc. would be able to add an item to the cycle of the pedestal, which
-- would remove that item from the pool.
--
-- Basically, this function spawns the desired item, and **ONLY** the desired item.
---@param SubType CollectibleType
---@param Position? Vector *Default: `Game():GetRoom():GetCenterPos()`*
---@param Velocity? Vector *Default: `Vector.Zero`*
---@param Spawner? Entity | nil *Default: `nil`*
---@param IgnoreModifiers? boolean *Default: `false`*
---@param KeepPrice? boolean *Default: `false`*
---@param KeepSeed? boolean *Default: `false`*
---@return EntityPickup
function ItemUtils.SpawnCollectible(SubType, Position, Velocity, Spawner, IgnoreModifiers, KeepPrice, KeepSeed)
    local entity = Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_POOP,
        PoopPickupSubType.POOP_SMALL,
        Position or game:GetRoom():GetCenterPos(),
        Velocity or Vector.Zero,
        Spawner or nil
    ):ToPickup()

    -- The sprite can be flipped so we are preventing that
    entity:GetSprite().FlipX = false

    entity:Morph(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        SubType,
        KeepPrice or false,
        KeepSeed or false,
        IgnoreModifiers or false
    )

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)

    -- We ALWAYS return a pickup, but the code editor yells at me to check
    -- the entity because IT COULD BE NIL! (it can't)
    ---@diagnostic disable-next-line: return-type-mismatch
    return entity
end

-- Gives a list of items as if the player had Glitched Crown, Binge Eater, Isaac's Birthright, etc.
--
-- If you plan on using this function to spawn a set amount of items then set `IgnoreModifiers` to `true`.
---@param ItemPool? ItemPoolType
---@param NumCollectibles? integer *Default: `1`*
---@param IgnoreModifiers? integer *Default: `false`*
---@param Decrease? boolean *Default: `true`*
---@param Seed? RNG *Default: `math.random(10000000000)`*
---@param DefaultItem? integer *Default: `CollectibleType.COLLECTIBLE_BREAKFAST`*
---@return CollectibleType[]
function ItemUtils.GetCollectibleCycle(ItemPool, NumCollectibles, IgnoreModifiers, Decrease, Seed, DefaultItem)
    local pool = game:GetItemPool()
    local config = Isaac.GetItemConfig()
    local room = game:GetRoom()

    local max = 10000000000

    local rng = RNG()
    if Seed then
        rng = Seed
    else
        rng:SetSeed(math.random(max))
    end

    if Decrease == nil then Decrease = true end

    if NumCollectibles == nil or NumCollectibles < 1 then NumCollectibles = 1 end

    if IgnoreModifiers ~= true then
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_GLITCHED_CROWN) then
            NumCollectibles = NumCollectibles + 4

        ---@diagnostic disable-next-line: param-type-mismatch
        elseif PlayerManager.AnyPlayerTypeHasCollectible(PlayerType.PLAYER_ISAAC, CollectibleType.COLLECTIBLE_BIRTHRIGHT, false)
        or PlayerManager.AnyoneIsPlayerType(PlayerType.PLAYER_ISAAC_B) then
            NumCollectibles = NumCollectibles + 1
        end
    end

    local collectibles = {}
    for _ = 1, NumCollectibles do
        local collectible = pool:GetCollectible(ItemPool or room:GetItemPool(rng:GetSeed()), Decrease, rng:RandomInt(max), DefaultItem)
        table.insert(collectibles, collectible)
    end

    if IgnoreModifiers ~= true and PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BINGE_EATER) then
        ---@diagnostic disable-next-line: param-type-mismatch
        local item_config_items = config:GetTaggedItems(ItemConfig.TAG_FOOD)
        local food_items = {}
        for _, item in ipairs(item_config_items) do
            table.insert(food_items, item.ID)
        end
        local food_item = pool:GetCollectibleFromList(food_items, rng:RandomInt(max), DefaultItem, Decrease, false)
        table.insert(collectibles, food_item)
    end

    return collectibles
end


-- This function spawns a collectible from the given pool, and will add item cycles respecting Glitched Crown, Binge Eater, T. Isaac and Isaac's Birthright.
---@param ItemPool? ItemPoolType
---@param Position? Vector *Default: `Game():GetRoom():GetCenterPos()`*
---@param Velocity? Vector *Default: `Vector.Zero`*
---@param Spawner? Entity | nil *Default: `nil`*
---@param Decrease? boolean *Default: `true`*
---@param Seed? RNG *Default: `math.random(10000000000)`*
---@param DefaultItem? integer *Default: `CollectibleType.COLLECTIBLE_BREAKFAST`*
---@return EntityPickup
function ItemUtils.SpawnCollectibleFromPool(ItemPool, Position, Velocity, Spawner, Decrease, Seed, DefaultItem)
    local room = game:GetRoom()

    local max = 10000000000

    local rng = RNG()
    if Seed then
        rng = Seed
    else
        rng:SetSeed(math.random(max))
    end

    if Decrease == nil then Decrease = true end

    local collectibles = ItemUtils.GetCollectibleCycle(ItemPool or room:GetItemPool(rng:GetSeed()), nil, nil, Decrease, rng, DefaultItem)

    ---@type EntityPickup
    local pedestal
    for i, collectible in ipairs(collectibles) do
        if i == 1 then
            pedestal = ItemUtils.SpawnCollectible(collectible, Position, Velocity, Spawner, true)
        else
            pedestal:AddCollectibleCycle(collectible)
        end
    end

    -- We ALWAYS return a pickup, but the code editor yells at me to check
    -- the entity because IT COULD BE NIL! (it can't)
    ---@diagnostic disable-next-line: return-type-mismatch
    return pedestal
end

return ItemUtils