--[[

I made this helper class to store code that I know I would reuse for different items and/or features

Feel free to use it if you want, you WILL need Repentagon for some of the stuff here
unless you want to make your own implementations

I do think you should make your own Helper script
After all, if you don't already have one that means you just started coding, so you won't learn
anything if you just blindly copy-paste everything from another random person on the internet
If you do want to do that, I won't judge. After all, there was a time when I also did that
But please, at least take a look at the functions to understand how they work

]]--




local game = Game()

---@class Helper
local Helper = {}

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


-- RoomDescriptor doesn't have autocomplete, so I'm just redefining the RoomDescriptor variables
-- here for the code editor to help me out
RoomDescriptor.FLAG_CLEAR = 1 << 0
RoomDescriptor.FLAG_PRESSURE_PLATES_TRIGGERED = 1 << 1
RoomDescriptor.FLAG_SACRIFICE_DONE = 1 << 2
RoomDescriptor.FLAG_CHALLENGE_DONE = 1 << 3
RoomDescriptor.FLAG_SURPRISE_MINIBOSS = 1 << 4
RoomDescriptor.FLAG_HAS_WATER = 1 << 5
RoomDescriptor.FLAG_ALT_BOSS_MUSIC = 1 << 6
RoomDescriptor.FLAG_NO_REWARD = 1 << 7
RoomDescriptor.FLAG_FLOODED = 1 << 8
RoomDescriptor.FLAG_PITCH_BLACK = 1 << 9
RoomDescriptor.FLAG_RED_ROOM = 1 << 10
RoomDescriptor.FLAG_DEVIL_TREASURE = 1 << 11
RoomDescriptor.FLAG_USE_ALTERNATE_BACKDROP = 1 << 12
RoomDescriptor.FLAG_CURSED_MIST = 1 << 13
RoomDescriptor.FLAG_MAMA_MEGA = 1 << 14
RoomDescriptor.FLAG_NO_WALLS = 1 << 15
RoomDescriptor.FLAG_ROTGUT_CLEARED = 1 << 16
RoomDescriptor.FLAG_PORTAL_LINKED = 1 << 17
RoomDescriptor.FLAG_BLUE_REDIRECT = 1 << 18

---@class EIDDescriptionObject
-- Helper table to type the DescriptionObject so I don't have to check the wiki every time.
EIDDescriptionObject = {
    -- Type of the described entity. Example: `5`
    ---@type integer
    ObjType = 0,

    -- Variant of the described entity. Example: `100`
    ---@type integer
    ObjVariant = 0,

    -- SubType of the described entity. Example for Sad Onion: `1`
    ---@type integer
    ObjSubType = 0,

    -- Combined string that describes the entity. Example for Sad Onion: `"5.100.1"`
    ---@type string
    fullItemString = "",

    -- Translated EID object name. Example for Sad Onion: `"Sad Onion"` or `"悲伤洋葱"` when chinese language is active
    ---@type string
    Name = "",

    -- Unformatted but translated EID description. Example for Sad Onion: "↑ +0.7 Tears up" or ↑ +0.7射速" when chinese language is active
    ---@type string
    Description = "",

    -- EID Transformation information object.
    ---@type unknown
    Transformation = nil,

    -- Name of the mod this item comes from. Can be nil!
    ---@type string
    ModName = nil,

    -- Quality of the displayed object. Number between 0 and 4. Set to nil to remove it.
    ---@type number
    Quality = 0,

    -- Object icon displayed in the top left of the description. Set to nil to not display it. Format like any EID icon: `{Animationname, Frame, Width, Height, LeftOffset [Default: -1], TopOffset [Default: 0], SpriteObject [Default: EID.InlineIconSprite]}`
    ---@type table
    Icon = table,

    -- Entity Object which currently is described.
    ---@type Entity
    Entity = nil,

    -- Allows description modifiers to be shown when the pill is still unidentified
    ---@type boolean
    ShowWhenUnidentified = false
}

---@param descObj EIDDescriptionObject
---@param entityType? integer
---@param entityVariant? integer
---@param entitySubtype? integer
function Helper.DescObjIs(descObj, entityType, entityVariant, entitySubtype)
    return (descObj.ObjType == entityType    or entityType == nil)
    and (descObj.ObjVariant == entityVariant or entityVariant == nil)
    and (descObj.ObjSubType == entitySubtype or entitySubtype == nil)
end
















---@param player EntityPlayer
---@param delay number
---@param respectTearCap? boolean
function Helper.ModifyFireDelay(player, delay, respectTearCap)
    -- Get current MaxFireDelay and TearDelay
    local currentMaxFireDelay = player.MaxFireDelay
    local currentTearDelay = Helper.FireDelayFormula(player)

    -- Calculate the target TearDelay
    local targetTearDelay = currentTearDelay - delay

    if targetTearDelay > 5 and not respectTearCap then
        targetTearDelay = math.max(5, currentTearDelay)
    end

    -- Calculate the target MaxFireDelay
    local targetMaxFireDelay = (30 / targetTearDelay) - 1

    -- Calculate the decrease in MaxFireDelay needed
    local fireDelayToDecrease = currentMaxFireDelay - targetMaxFireDelay

    player.MaxFireDelay = player.MaxFireDelay - fireDelayToDecrease
end

---@param player EntityPlayer
function Helper.FireDelayFormula(player)
    return 30 / (player.MaxFireDelay + 1)
end

---@param player EntityPlayer
---@param range number
function Helper.ModifyTearRange(player, range)
    player.TearRange = player.TearRange + (range * 40)
end

---@param player EntityPlayer
function Helper.GetAproxDamageMultiplier(player)
    local multiplier = 1
    local effects = player:GetEffects()

    ---@param n number
    local function mult(n)
        multiplier = multiplier * n
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_ODD_MUSHROOM_THIN) then mult(0.9) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS) then mult(2) end
    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MEGA_MUSH) then mult(4) end

    if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BRIMSTONE) >= 2 then mult(1.2) end

    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) then mult(2) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) then mult(2.3) end

    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HALLOWED_GROUND)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_HEART)
    or effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM)
    then mult(1.2) end

    if player:GetPlayerType() == PlayerType.PLAYER_AZAZEL
    and player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE)
    then mult(0.5) end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY)
    and not player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BRIMSTONE) >= 2 then
        mult(1.5)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
        mult(1.5)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then mult(0.8) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then mult(0.3) end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_CRICKETS_HEAD)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
    or (effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL) and player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_OF_THE_MARTYR))
    then mult(1.5) end

    mult(player:GetD8DamageModifier())

    mult(1 + (player:GetDeadEyeCharge() / 8))

    if player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) then mult(2) end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and not player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then mult(0.2)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then mult(0.3) end

    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM) then mult(1.5) end

    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_SUCCUBUS) then mult(1.5) end

    if player:HasTrinket(TrinketType.TRINKET_CRACKED_CROWN) and player.Damage > 3.5 then mult(1.2) end

    return multiplier
end


---@param player EntityPlayer
function Helper.GetAproxTearRateMultiplier(player)
    local multiplier = 1
    local effects = player:GetEffects()

    ---@param n number
    local function mult(n)
        multiplier = multiplier * n
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then mult(1/3) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then mult(1/3) end -- Since haemolacria modifies TearDelay, this is an aproximation
    if player:HasTrinket(TrinketType.TRINKET_CRACKED_CROWN) then mult(1.2) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then mult(0.4) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIPHORA) then mult(1 + (math.floor(player:GetEpiphoraCharge() / 90) / 3)) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) then mult(0.66) end
    if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HALLOWED_GROUND) then mult(2.5) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then mult(1/3) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then mult(1/4.3) end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_2) then mult(0.66) end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then mult(0.42)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS) then mult(0.42)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE)
        or effects:HasNullEffect(NullItemID.ID_REVERSE_HANGED_MAN)
    then mult(0.42) end

    if Helper.IsKeeper(player) then
        mult(0.42)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then mult(4)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then mult(5.5) end

    if effects:HasNullEffect(NullItemID.ID_REVERSE_CHARIOT) or effects:HasNullEffect(NullItemID.ID_REVERSE_CHARIOT_ALT) then mult(4) end

    mult(player:GetD8FireDelayModifier())

    return multiplier
end














---@param H any -- *Number between 0 and 360*
---@param S? any -- *Default: `1` — Number between 0 and 1*
---@param L? any -- *Default: `0.5` — Number between 0 and 1*
function Helper.HSLtoRGB(H, S, L)
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



function Helper.Lerp(A, B, t)
    return A + (B - A) * t
end


---@param t table
---@return integer
function Helper.FindFirstInstanceInTable(value, t)
    for i, item in ipairs(t) do
        if value == item then
            return i
        end
    end

    return 0
end


---@param t table
---@return boolean
function Helper.IsValueInTable(value, t)
    for _, item in ipairs(t) do
        if value == item then
            return true
        end
    end

    return false
end


---@param t table
---@return table
function Helper.Keys(t)
    local keys = {}

    for key,_ in pairs(t) do
        table.insert(keys, key)
    end

    return keys
end

---@param t table
---@return table
function Helper.Values(t)
    local values = {}

    for _,value in ipairs(t) do
        table.insert(values, value)
    end

    return values
end

---@param t table
---@return table, table
function Helper.KeysAndValues(t)
    local keys = {}
    local values = {}

    for key,value in pairs(t) do
        table.insert(keys, key)
        table.insert(values, value)
    end

    return keys, values
end

---@param t table
---@return table
function Helper.ShallowCopy(t)
    local new = {}

    for i,v in pairs(t) do
        new[i] = v
    end

    return new
end

---@param t table
---@param weights? table
---@param rng? RNG
---@return any
function Helper.Choice(t, weights, rng)
    if rng == nil then
        rng = RNG()
        rng:SetSeed(math.random(99999999999))
    end

    -- If weights are not provided, initialize equal weights
    if weights == nil then
        weights = {}
        for i = 1, #t do
            weights[i] = 1
        end
    end

    -- Normalize the weights to avoid precision issues
    local weight_sum = 0
    for _, weight in ipairs(weights) do
        weight_sum = weight_sum + weight
    end

    -- Compute the cumulative sum of normalized weights
    local cumulative_weights = {}
    local cumulative_sum = 0
    for i, weight in ipairs(weights) do
        cumulative_sum = cumulative_sum + (weight / weight_sum)
        cumulative_weights[i] = cumulative_sum
    end

    -- Generate a random number in the range [0, 1)
    local random_number = rng:RandomFloat()

    -- Find the index corresponding to the random number
    for i, cumulative_weight in ipairs(cumulative_weights) do
        if random_number < cumulative_weight then
            return t[i]
        end
    end
end

function Helper.SplitTable(t, num_sublists)
    local sublists = {}
    for _ = 1, num_sublists do
        table.insert(sublists, {})
    end

    for i, item in ipairs(t) do
        local sublist_index = ((i - 1) % num_sublists) + 1
        table.insert(sublists[sublist_index], item)
    end

    return sublists
end

---@param rng? RNG
function Helper.ShuffleTable(t, rng)
    local n = #t
    for i = n, 2, -1 do
        local j
        if rng then
            j = rng:RandomInt(1, i)
        else
            j = math.random(i)
        end
        t[i], t[j] = t[j], t[i]
    end
end

function Helper.Split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function Helper.Join(t, sep)
    if sep == nil then
        sep = " "
    end
    local str = ""
    for i, v in ipairs(t) do
        if i > 0 then
            str = str..sep
        end
        str = str..v
    end
    return str
end


















-------------------------------------------
-- CODE THAT HAS TO DO WITH COLLECTIBLES --
-------------------------------------------

---@param entity Entity
---@param allowEmpty? boolean -- *Default: `false` — Should we count empty pedestals as collectibles?*
---@return boolean
function Helper.IsCollectible(entity, allowEmpty)
    if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        if allowEmpty == true then
            return true
        elseif entity.SubType ~= 0 then
            return true
        end
    end
    return false
end

---@param collectibleType CollectibleType
---@return EntityPlayer[]
function Helper.GetPlayersWithCollectible(collectibleType)
    ---@type EntityPlayer[]
    local players = {}

    for _, player in pairs(PlayerManager.GetPlayers()) do
        if player:HasCollectible(collectibleType) then
            table.insert(players, player)
        end
    end

    return players
end

-- Returns a table with the amount of each collectible the player has without counting innate items.
---- This function has extra parameters for blacklisting certain items and tags.
---- Unlike `Isaac.GetPlayer():GetCollectiblesList()`, this table contains items the player ACTUALLY HAS.
---- If you only need the items without the amount, pass the result through `Helper.Keys()`
---@param player EntityPlayer
---@param itemTypeBlacklist? ItemType[]
---@param itemTagBlacklist? integer
---@return table<CollectibleType, integer>
function Helper.GetCollectibleListCurated(player, itemTypeBlacklist, itemTagBlacklist, itemTypeWhitelist, itemTagWhitelist)
    ---@type table<CollectibleType, integer>
    local collectibles = {}

    local playerItems = player:GetCollectiblesList()
    local ItemConfig = Isaac.GetItemConfig()

    for collectibleType, collectibleAmount in pairs(playerItems) do
        local collectible = ItemConfig:GetCollectible(collectibleType)
        if collectibleAmount > 0 then
            if itemTypeBlacklist and Helper.IsValueInTable(collectible.Type, itemTypeBlacklist) then
                goto next_item
            end
            if itemTagBlacklist and collectible:HasTags(itemTagBlacklist) then
                goto next_item
            end

            if itemTypeWhitelist and not Helper.IsValueInTable(collectible.Type, itemTypeWhitelist) then
                goto next_item
            end
            if itemTagWhitelist and not collectible:HasTags(itemTagWhitelist) then
                goto next_item
            end

            collectibles[collectibleType] = collectibleAmount
        end
        ::next_item::
    end

    return collectibles
end

-- Returns the number of collectibles the player is holding without counting innate items.
---- This function has extra parameters for ignoring duplicates and blacklisting certain items and tags.
---@param player EntityPlayer
---@param allowDuplicates? boolean -- Default: `true`
---@param itemTypeBlacklist? ItemType[]
---@param itemTagBlacklist? integer
---@param itemTypeWhitelist? ItemType[]
---@param itemTagWhitelist? integer
---@return integer
function Helper.GetCollectibleCountCurated(player, allowDuplicates, itemTypeBlacklist, itemTagBlacklist,  itemTypeWhitelist, itemTagWhitelist)
    local collectibles = 0

    if allowDuplicates == nil then allowDuplicates = true end

    local playerItems = Helper.GetCollectibleListCurated(player, itemTypeBlacklist, itemTagBlacklist, itemTypeWhitelist, itemTagWhitelist)

    for _, collectibleNumber in pairs(playerItems) do
        if allowDuplicates then
            collectibles = collectibles + collectibleNumber
        else
            collectibles = collectibles + 1
        end
    end

    return collectibles
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
function Helper.SpawnCollectible(SubType, Position, Velocity, Spawner, IgnoreModifiers, KeepPrice, KeepSeed)
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
function Helper.GetCollectibleCycle(ItemPool, NumCollectibles, IgnoreModifiers, Decrease, Seed, DefaultItem)
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
function Helper.SpawnCollectiblePool(ItemPool, Position, Velocity, Spawner, Decrease, Seed, DefaultItem)
    local room = game:GetRoom()

    local max = 10000000000

    local rng = RNG()
    if Seed then
        rng = Seed
    else
        rng:SetSeed(math.random(max))
    end

    if Decrease == nil then Decrease = true end

    local collectibles = Helper.GetCollectibleCycle(ItemPool or room:GetItemPool(rng:GetSeed()), nil, nil, Decrease, rng, DefaultItem)

    ---@type EntityPickup
    local pedestal
    for i, collectible in ipairs(collectibles) do
        if i == 1 then
            pedestal = Helper.SpawnCollectible(collectible, Position, Velocity, Spawner, true)
        else
            pedestal:AddCollectibleCycle(collectible)
        end
    end

    -- We ALWAYS return a pickup, but the code editor yells at me to check
    -- the entity because IT COULD BE NIL! (it can't)
    ---@diagnostic disable-next-line: return-type-mismatch
    return pedestal
end















-----------------------------------------
-- CODE THAT HAS TO DO WITH THE PLAYER --
-----------------------------------------

---@param ref EntityRef
---@return EntityPlayer | nil
function Helper.EntityRefToPlayer(ref)
    local player
    if ref.Entity then
        player = ref.Entity:ToPlayer()
    end

    if not player and ref.Entity.Parent then
        player = ref.Entity.Parent:ToPlayer()
    end

    if not player and ref.Entity.Parent and ref.Entity.Parent:ToEffect() and ref.Entity.Parent.SpawnerEntity then
        player = ref.Entity.Parent.SpawnerEntity:ToPlayer()
    end

    if not player and ref.Entity:ToTear() and ref.Entity.SpawnerEntity then
        player = ref.Entity.SpawnerEntity:ToPlayer()
    end

    return player
end

-- Transforms the player's active item into another item
---@param player EntityPlayer
---@param collectibleType CollectibleType
---@param slot? ActiveSlot -- *Default: `ActiveSlot.SLOT_PRIMARY`*
function Helper.TransformPlayerActiveItem(player, collectibleType, slot)
    if slot == nil then slot = ActiveSlot.SLOT_PRIMARY end

    local desc = player:GetActiveItemDesc(slot)
    desc.Item = collectibleType
end

---@param player EntityPlayer
function Helper.IsPlayerShooting(player)
    local triggers = player:GetLastActionTriggers()
    return triggers & ActionTriggers.ACTIONTRIGGER_SHOOTING > 0
end

-- Checks if any player is at least one of the provided player types
--
-- For checking just one type, use `PlayerManager.AnyoneIsPlayerType(PlayerType)`
---@param ... PlayerType
---@return boolean
function Helper.AnyPlayerIs(...)
    local playerTypes = { ... }

    for _, playerType in pairs(playerTypes) do
        if PlayerManager.AnyoneIsPlayerType(playerType) then
            return true
        end
    end

    return false
end

---@param ... PlayerType
---@return EntityPlayer[]
function Helper.GetPlayersOfType(...)
    ---@type EntityPlayer[]
    local players = {}

    local types = { ... }

    for _, player in pairs(PlayerManager.GetPlayers()) do
        for _, playerType in ipairs(types) do
            if player:GetPlayerType() == playerType then
                table.insert(players, player)
                goto next_player
            end
        end

        ::next_player::
    end

    return players
end

---@param player EntityPlayer
---@return boolean
function Helper.IsEden(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_EDEN or t == PlayerType.PLAYER_EDEN_B
end

---@param player EntityPlayer
---@return boolean
function Helper.IsLost(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_THELOST or t == PlayerType.PLAYER_THELOST_B
end

---@param player EntityPlayer
---@return boolean
function Helper.IsKeeper(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_KEEPER or t == PlayerType.PLAYER_KEEPER_B
end

-- Gets the ID of the player in a reliable way that persists across closing and reopening the game
---- Might fail if other mods use the Collectible's RNG though
---@param player? EntityPlayer Default: Isaac.GetPlayer(0) — The `EntityPlayer` to get the ID for
---@param collectible? CollectibleType Default: 1 — Change this to another collectible if you want to get the ID of sub-players like Esau
function Helper.GetPlayerId(player, collectible)
    if type(player) == "string" then
        return player
    end

    player = player or Isaac.GetPlayer()
    return tostring(player:GetCollectibleRNG(collectible or 1):GetSeed())
end

-- Gets all the wisps spawned by players, index ordered from oldest to newest.
---@param player? EntityPlayer -- The player to get the wisps from
---@param fromCollectible? CollectibleType -- Only get wisps spawned from using this collectible
---@return EntityFamiliar[]
function Helper.GetPlayerWisps(player, fromCollectible)
    ---@type EntityFamiliar[]
    local wisps = {}

    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        local wisp = entity:ToFamiliar()
        if not wisp then goto continue end

        if wisp.Variant ~= FamiliarVariant.WISP then goto continue end

        if player and wisp.Player.ControllerIndex ~= player.ControllerIndex then goto continue end

        if fromCollectible and wisp.SubType ~= fromCollectible then goto continue end

        table.insert(wisps, wisp)

        ::continue::
    end

    table.sort(wisps, function (a, b)
        return a.Index > b.Index
    end)

    return wisps
end














-- Returns a list of all GridEntities in the current room
---@return GridEntity[]
function Helper.GetRoomGridEntities()
    local room = Game():GetRoom()

    local entities = {}

    for index = 1, room:GetGridSize() do
        local entity = room:GetGridEntity(index)
        if entity then
            table.insert(entities, entity)
        end
    end

    return entities
end














-- This function was directly copied from [The Official API](https://wofsauge.github.io/IsaacDocs/rep/Room.html#getdevilroomchance),
-- I changed the anyPlayerHasCollectible and anyPlayerHasTrinket functions with the Repentagon functions
---@return number[] -- List where the first item is the devil chance and the second the angel chance
function Helper.getDevilAngelRoomChance()
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
    if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_DUALITY) then
        angelRoomChance = devilRoomChance
    end
    return {totalChance * devilRoomChance, totalChance * angelRoomChance}
end

return Helper