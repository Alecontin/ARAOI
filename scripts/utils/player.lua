
---@class PlayerUtils
local PlayerUtils = {}

---@type TableUtils
local TableUtils = include("scripts.utils.table")

---@class FireDirection
PlayerUtils.FireDirection = {
    DOWN  = 7,
    LEFT  = 4,
    RIGHT = 5,
    UP    = 6,
    NONE  = nil
}

---@param player EntityPlayer
---@param delay number
---@param respectTearCap? boolean
function PlayerUtils.ModifyFireDelay(player, delay, respectTearCap)
    -- Get current MaxFireDelay and TearDelay
    local currentMaxFireDelay = player.MaxFireDelay
    local currentTearDelay = PlayerUtils.FireDelayFormula(player)

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
function PlayerUtils.FireDelayFormula(player)
    return 30 / (player.MaxFireDelay + 1)
end

---@param player EntityPlayer
---@param range number
function PlayerUtils.ModifyTearRange(player, range)
    player.TearRange = player.TearRange + (range * 40)
end

---@param player EntityPlayer
function PlayerUtils.GetAproxDamageMultiplier(player)
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
function PlayerUtils.GetAproxTearRateMultiplier(player)
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

    if PlayerUtils.IsKeeper(player) then
        mult(0.42)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then mult(4)
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then mult(5.5) end

    if effects:HasNullEffect(NullItemID.ID_REVERSE_CHARIOT) or effects:HasNullEffect(NullItemID.ID_REVERSE_CHARIOT_ALT) then mult(4) end

    mult(player:GetD8FireDelayModifier())

    return multiplier
end

---@param ref EntityRef
---@return EntityPlayer | nil
function PlayerUtils.FromEntityRef(ref)
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
function PlayerUtils.TransformActiveItem(player, collectibleType, slot)
    if slot == nil then slot = ActiveSlot.SLOT_PRIMARY end

    local desc = player:GetActiveItemDesc(slot)
    desc.Item = collectibleType
end

---@param player EntityPlayer
function PlayerUtils.IsShooting(player)
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)  then return PlayerUtils.FireDirection.DOWN  end
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex)  then return PlayerUtils.FireDirection.LEFT  end
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then return PlayerUtils.FireDirection.RIGHT end
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex)    then return PlayerUtils.FireDirection.UP    end
end

---@param player EntityPlayer
function PlayerUtils.TriggeredShooting(player)
    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)  then return PlayerUtils.FireDirection.DOWN  end
    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex)  then return PlayerUtils.FireDirection.LEFT  end
    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then return PlayerUtils.FireDirection.RIGHT end
    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex)    then return PlayerUtils.FireDirection.UP    end
end

-- Checks if any player is at least one of the provided player types
--
-- For checking just one type, use `PlayerManager.AnyoneIsPlayerType(PlayerType)`
---@param ... PlayerType
---@return boolean
function PlayerUtils.AnyPlayerIs(...)
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
function PlayerUtils.GetPlayersOfType(...)
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
function PlayerUtils.IsEden(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_EDEN or t == PlayerType.PLAYER_EDEN_B
end

---@param player EntityPlayer
---@return boolean
function PlayerUtils.IsLost(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_THELOST or t == PlayerType.PLAYER_THELOST_B
end

---@param player EntityPlayer
---@return boolean
function PlayerUtils.IsKeeper(player)
    local t = player:GetPlayerType()
    return t == PlayerType.PLAYER_KEEPER or t == PlayerType.PLAYER_KEEPER_B
end

-- Gets the ID of the player in a reliable way that persists across closing and reopening the game
---- Might fail if other mods use the Collectible's RNG though
---@param player? EntityPlayer Default: Isaac.GetPlayer(0) — The `EntityPlayer` to get the ID for
---@param collectible? CollectibleType Default: 1 — Change this to another collectible if you want to get the ID of sub-players like Esau
function PlayerUtils.GetID(player, collectible)
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
function PlayerUtils.GetWisps(player, fromCollectible)
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

-- Returns a table with the amount of each collectible the player has without counting innate items.
---- This function has extra parameters for blacklisting certain items and tags.
---- Unlike `Isaac.GetPlayer():GetCollectiblesList()`, this table contains items the player ACTUALLY HAS.
---- If you only need the items without the amount, pass the result through `Helper.Keys()`
---@param player EntityPlayer
---@param itemTypeBlacklist? ItemType[]
---@param itemTagBlacklist? integer
---@param itemTypeWhitelist? ItemType[]
---@param itemTagWhitelist? integer
---@return table<CollectibleType, integer>
function PlayerUtils.GetCollectibleListCurated(player, itemTypeBlacklist, itemTagBlacklist, itemTypeWhitelist, itemTagWhitelist)
    ---@type table<CollectibleType, integer>
    local collectibles = {}

    local playerItems = player:GetCollectiblesList()
    local ItemConfig = Isaac.GetItemConfig()

    for collectibleType, collectibleAmount in pairs(playerItems) do
        local collectible = ItemConfig:GetCollectible(collectibleType)
        if collectibleAmount > 0 then
            if itemTypeBlacklist and TableUtils.IsValueInTable(collectible.Type, itemTypeBlacklist) then
                goto next_item
            end
            if itemTagBlacklist and collectible:HasTags(itemTagBlacklist) then
                goto next_item
            end

            if itemTypeWhitelist and not TableUtils.IsValueInTable(collectible.Type, itemTypeWhitelist) then
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
function PlayerUtils.GetCollectibleCountCurated(player, allowDuplicates, itemTypeBlacklist, itemTagBlacklist,  itemTypeWhitelist, itemTagWhitelist)
    local collectibles = 0

    if allowDuplicates == nil then allowDuplicates = true end

    local playerItems = PlayerUtils.GetCollectibleListCurated(player, itemTypeBlacklist, itemTagBlacklist, itemTypeWhitelist, itemTagWhitelist)

    for _, collectibleNumber in pairs(playerItems) do
        if allowDuplicates then
            collectibles = collectibles + collectibleNumber
        else
            collectibles = collectibles + 1
        end
    end

    return collectibles
end

---@param collectibleType CollectibleType
---@return EntityPlayer[]
function PlayerUtils.GetPlayersWithCollectible(collectibleType)
    ---@type EntityPlayer[]
    local players = {}

    for _, player in pairs(PlayerManager.GetPlayers()) do
        if player:HasCollectible(collectibleType) then
            table.insert(players, player)
        end
    end

    return players
end

return PlayerUtils