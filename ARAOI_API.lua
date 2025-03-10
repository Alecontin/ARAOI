---@diagnostic disable: missing-return

--[[

    This does not contain code! It contains the definitions of the actual code!

    To use this API with VSCode, go into your mod and paste this file in there

    Next, go into the .luarc.json file created by `Binding of Isaac Lua API`, which I assume you are using

    Add "ARAOI" into the "diagnostics.globals" list, make sure to save your change!

    Now go into your mod and type "ARAOI." (without quotes)

    There you go! Now you should be getting autocomplete suggestions!

    If you don't, I noticed that adding the API script into the .gitignore file can mess
    with API autocompletion. To fix this, simply open the API file in a new tab

    Make sure to check if the user does actually have my mod installed:

    if ARAOI then
        -- Your code that requires ARAOI to run here!
    else
        error("ARAOI is not installed!")
    end

    Side note: DO NOT INCLUDE THIS FILE IN YOUR MOD! THE USER DOES NOT NEED IT!
]]

---@class ARAOI
ARAOI = {}

---@class CollectibleType
---@field THREED_GLASSES integer
---@field BAG_OF_HOLDING integer
---@field ETERNAL_DPLOPIA integer
---@field GLASS_DIE integer
---@field RUBIKS_CUBE integer
---@field SPELLBOOK integer
---@field WIRE_CUTTER integer
---@field BLESSINGS_PETAL integer
---@field DUALITY_HALO integer
---@field GAMBLING_CHIPS integer
---@field LUCKY_COIN integer
---@field RAINBOW_HEADBAND integer
---@field SACRIFICIAL_HEART integer
---@field VAMPIRE_CLOAK integer
---@field VOODOO_BODY integer
---@field RECYCLE integer
---@field GAMBLECORE integer
---@field CHOCOLATE_BIRTHDAY_CAKE integer
---@field LUNCHBOX integer
---@field KATANA integer
ARAOI.CollectibleType = {}
ARAOI.CollectibleType.NUM_COLLECTIBLES = 20

---@class TrinketType
---@field SPARE_BATTERY integer
---@field SOLVED_RUBIKS_CUBE integer
---@field INVERTED_SPADES integer
---@field BOUNTIFUL_SACK integer
ARAOI.TrinketType = {}
ARAOI.TrinketType.NUM_TRINKETS = 4

---@class Card
---@field INVERTED_FOOL integer
---@field INVERTED_MAGICIAN integer
---@field INVERTED_HIGH_PRIESTESS integer
---@field INVERTED_EMPRESS integer
---@field INVERTED_EMPEROR integer
---@field INVERTED_HERMIT integer
---@field INVERTED_HIEROPHANT integer
---@field INVERTED_LOVERS integer
---@field INVERTED_CHARIOT integer
---@field INVERTED_JUSTICE integer
---@field INVERTED_WHEEL_OF_FORTUNE integer
---@field INVERTED_STRENGTH integer
---@field INVERTED_HANGED_MAN integer
---@field INVERTED_DEATH integer
---@field INVERTED_TEMPERANCE integer
---@field INVERTED_DEVIL integer
---@field INVERTED_TOWER integer
---@field INVERTED_STARS integer
---@field INVERTED_MOON integer
---@field INVERTED_SUN integer
---@field INVERTED_JUDGEMENT integer
---@field INVERTED_WORLD integer
ARAOI.CardSubType = {}
ARAOI.CardSubType.NUM_CARDS = 22






---@class SaveDataManager
local SaveDataManager = {}

-- Function that initializes the SaveDataManager
---@param Mod ModReference
---@return self
function SaveDataManager:init(Mod)
end

-- Creates a timer that will run the callback in the amount of defined seconds
---- "But couldn't I just use Isaac.CreateTimer() instead?"
--
-- Well, yes, but this persists across saving and loading.
---@param callbackID string -- The ID of the callback to be ran
---@param time number -- Time, in seconds, after which the callback will run
---@param ... any -- Parameters to pass to the callback
function SaveDataManager:CreateTimer(callbackID, time, ...)
end

-- Creates a timer that will run the callback in the amount of defined update frames
---- "But couldn't I just use Isaac.CreateTimer() instead?"
--
-- Well, yes, but this persists across saving and loading.
---@param callbackID string -- The ID of the callback to be ran
---@param time number -- Time, in seconds, after which the callback will run
---@param ... any -- Parameters to pass to the callback
function SaveDataManager:CreateTimerInFrames(callbackID, time, ...)
end

-- Get/Set data from/to an access point
---@param access any -- Can be anywhere, as long as it's a table, like `save.RUN`
---@param point any -- What point to access from the table, for example: `"CursedObjects"`
---@param default any -- What should the default value of the access point (`save.RUN["CursedObjects"]`) be, for example: `{}`
---@param key any -- Should be a string, it will be automatically converted to one
---@param default_value any -- What should the default returned value be?
---@param value? any -- The value to set the key to, leave blank to not set the value
---@return any
function SaveDataManager:Data(access, point, default, key, default_value, value)
end

-- Get/Set data from/to an access point
---@param access any -- Can be anywhere, as long as it's a table, like `save.RUN`
---@param key any -- Should be a string, it will be automatically converted to one
---@param default any -- What should the default value of the access point (`save.RUN["CursedObjects"]`) be, for example: `{}`
---@param value? any -- The value to set the key to, leave blank to not set the value
---@return any
function SaveDataManager:Key(access, key, default, value)
end

ARAOI.SaveData = SaveDataManager






---@class EIDUtils
local EIDUtils = {}

-- Function that matches the given descObj parameters to the ones given
---@param descObj any
---@param entityType? integer -- Default: `any`
---@param entityVariant? integer -- Default: `any`
---@param entitySubtype? integer -- Default: `any`
---@return boolean
function EIDUtils.DescObjIs(descObj, entityType, entityVariant, entitySubtype)
end

-- Function that makes it easier to append Book Of Virtues synergies to items
--
-- The `Book Of Virtues` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
function EIDUtils.BookOfVirtuesSynergy(modifier_id, to_this_item, description)
end

-- Function that makes it easier to append Abyss synergies to items
--
-- The `Abyss` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
function EIDUtils.AbyssSynergy(modifier_id, to_this_item, description)
end

-- Function that makes it easier to append Car Battery synergies to items
--
-- The `Car Battery` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
function EIDUtils.CarBatterySynergy(modifier_id, to_this_item, description)
end

-- Function that makes it easier to append a synergy description to items
---@param modifier_id string
---@param to_this_item CollectibleType
---@param if_player_has_this_item CollectibleType
---@param append_to_description string
function EIDUtils.SimpleSynergyModifier(modifier_id, to_this_item, if_player_has_this_item, append_to_description)
end

-- Function that makes it easier to append some player-based information to items
---@param modifier_id string
---@param to_this_item CollectibleType
---@param if_player_is PlayerType[]
---@param player_icon PlayerType
---@param append_to_description string
function EIDUtils.PlayerBasedModifier(modifier_id, to_this_item, if_player_is, player_icon, append_to_description)
end

-- @_param_ `changes`
--
-- _type_ `string` — Text will be appended to the description
--
-- _type_ `string[]` — Replaces index 1 with 2, 3 with 4, etc. So passing in `{" a ", " a lot ", " an ", " two "}` will replace `" a "` with `" a lot "` and `" an "` with `" two "`
--
-- _type_ `number[]` — Replaces index 1 with 2, 3 with 4, etc. So passing in `{1, 2, 0.6, 0.8}` will replace `1` with `2` and `0.6` with `0.8`
---@param id Card
---@param changes string | string[] | number[]
---@param language any?
function EIDUtils.TarotClothMetadata(id, changes, language)
end

ARAOI.EIDUtils = EIDUtils






---@class ItemUtils
local ItemUtils = {}

-- Checks if the given entity is a collectible
---@param entity Entity
---@param allowEmpty? boolean -- *Default: `false` — Should we count empty pedestals as collectibles?*
---@return boolean
function ItemUtils.IsCollectible(entity, allowEmpty)
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
end

-- Returns a random pickup for you to spawn
---@param rng? RNG
---@param allowHearts? boolean -- Default: `true`
---@param allowCoins? boolean -- Default: `true`
---@param allowKeys? boolean -- Default: `true`
---@param allowBombs? boolean -- Default: `true`
---@param allowBatteries? boolean -- Default: `true`
---@param allowChests? boolean -- Default: `true`
---@param allowExtremelyRareOccurrences? boolean -- Default: `false` — Should we allow extremely rare occurrences? Like spawning Mom's Chest.
---@return PickupVariant
function ItemUtils.GetRandomPickup(rng, allowHearts, allowCoins, allowKeys, allowBombs, allowBatteries, allowChests, allowExtremelyRareOccurrences)
end

ARAOI.ItemUtils = ItemUtils






---@class MiscUtils
local MiscUtils = {}

-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isAngelItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isBossItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isCurseItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isSecretItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isShopItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isTreasureItemPool(item_pool)
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
---@return boolean
function MiscUtils.isDevilItemPool(item_pool)
end

-- Function that converts HSL to RGB
---@param H integer -- *Number between 0 and 360*
---@param S? number -- *Default: `1` — Number between 0 and 1*
---@param L? number -- *Default: `0.5` — Number between 0 and 1*
---@return number
---@return number
---@return number
function MiscUtils.HSLtoRGB(H, S, L)
end

-- Function that linearly interpolates between 2 numbers
---@return number
function MiscUtils.Lerp(A, B, t)
end

-- Function that checks whether any reverse card is unlocked, used for Inverted Spades
---@return boolean
function MiscUtils.IsAnyReverseCardUnlocked()
end

-- Converts pennies into dimes, nickels and pennies
---@param pennies integer
---@return integer dimes
---@return integer nickels
---@return integer pennies
function MiscUtils.PenniesToCoins(pennies)
end

-- Function that drops the specified amount of pennies into dimes, nickels and pennies
---@param pennies integer
---@param position? Vector -- Default: `Game():GetRoom():FindFreePickupSpawnPosition(Game():GetRoom():GetCenterPos())`
---@param velocityMult? number -- Default: `1`
function MiscUtils.DropCompactedCoins(pennies, position, velocityMult)
end

---@param player EntityPlayer
---@param enemy Entity
---@param damage? number -- Default: `player.Damage`
---@param source? Entity -- Default: `player`
---@param damageFlag? DamageFlag|integer -- Default: `DamageFlag.DAMAGE_COUNTDOWN`
---@param tearFlags? TearFlags -- Default: `player:GetTearHitParams(WeaponType.WEAPON_TEARS).TearFlags`
---@param rotation? number -- Default: `rng:PhantomInt(360)`
---@param rng? RNG -- Default: `math.random(999999999999)`
---@param effectDuration? integer -- Default: `75`
function MiscUtils.DamageWithTearEffects(player, enemy, damage, source, damageFlag, tearFlags, rotation, rng, effectDuration)
end

---@param position Vector
---@param damage? number -- The damage of the attack
---@param mirrored? boolean -- Should the attack animation be mirrored
---@param sizeMultiplier? number -- Size of the attack
---@param rotation? number -- Rotation of the attack
---@param spriteOffset? Vector -- The offset of the attack's sprite
---@param playSound? boolean -- Should the attack play the sound when spawning
function MiscUtils.SpawnMeleeWoosh(position, mirrored, damage, sizeMultiplier, rotation, spriteOffset, playSound)
end

-- This function was directly copied from [The Official API](https://wofsauge.github.io/IsaacDocs/rep/Room.html#getdevilroomchance),
-- I changed the anyPlayerHasCollectible and anyPlayerHasTrinket functions with the Repentogon functions
---@return number DevilChance, number AngelChance
function MiscUtils.getDevilAngelRoomChance()
end

ARAOI.MiscUtils = MiscUtils






---@class PlayerUtils
local PlayerUtils = {}

---@class FireDirection
PlayerUtils.FireDirection = {
    DOWN  = 7,
    LEFT  = 4,
    RIGHT = 5,
    UP    = 6,
    NONE  = nil
}

-- Function that modifies the player fire delay (tears stat) using the fire delay formula, which means that +1 tears up will be +1 tears up
---@param player EntityPlayer
---@param delay number
---@param respectTearCap? boolean
function PlayerUtils.AddFireDelay(player, delay, respectTearCap)
end

-- Function that returns the player's current tear delay using the fire delay formula
---@param player EntityPlayer
---@return number
function PlayerUtils.GetTearDelay(player)
end

-- Function that modifies the players range using the range formula, which means that +1 range up will be +1 range up
---@param player EntityPlayer
---@param range number
function PlayerUtils.ModifyTearRange(player, range)
end

-- Gets the approximate damage multiplier for the player using the data from the wiki
--
-- I am not confident enough to say that I did this 100% right
---@param player EntityPlayer
---@return number
function PlayerUtils.GetAproxDamageMultiplier(player)
end

-- Gets the approximate tear rate multiplier for the player using the data from the wiki
--
-- I am not confident enough to say that I did this 100% right
---@param player EntityPlayer
---@return number
function PlayerUtils.GetAproxTearRateMultiplier(player)
end

-- Tries to get the player from an EntityRef, going through every possible reference
---@param ref EntityRef
---@return EntityPlayer | nil
function PlayerUtils.FromEntityRef(ref)
end

-- Gets the player's current shooting direction
---@param player EntityPlayer
---@return FireDirection
function PlayerUtils.GetCurrentShootingDirection(player)
end

-- Returns the direction of the player's shooting direction only if it's just been triggered
---@param player EntityPlayer
---@return FireDirection
function PlayerUtils.TriggeredShooting(player)
end

-- Checks if any player is at least one of the provided player types
--
-- For checking just one type, use `PlayerManager.AnyoneIsPlayerType(PlayerType)`
---@param ... PlayerType
---@return boolean
function PlayerUtils.AnyPlayerIs(...)
end

-- Returns all the players that match the provided player types
---@param ... PlayerType
---@return EntityPlayer[]
function PlayerUtils.GetPlayersOfType(...)
end

-- Checks if the player is Eden or T. Eden
---@param player EntityPlayer
---@return boolean
function PlayerUtils.IsEden(player)
end

---@param player EntityPlayer
---@param accountForCurses boolean -- Should we account for the white fire curse and T. Jacob?
---@return boolean
function PlayerUtils.IsLost(player, accountForCurses)
end

-- Checks if the player is Keeper or T. Keeper
---@param player EntityPlayer
---@return boolean
function PlayerUtils.IsKeeper(player)
end

-- Gets the ID of the player in a reliable way that persists across closing and reopening the game
---- Will fail if other mods use the Collectible's RNG though
---@param player? EntityPlayer Default: Isaac.GetPlayer(0) — The `EntityPlayer` to get the ID for
---@param collectible? CollectibleType Default: 1 — Change this to another collectible if you want to get the ID of sub-players like Esau
---@return integer
function PlayerUtils.GetID(player, collectible)
end

-- Gets all the wisps spawned by the player, index ordered from oldest to newest.
---@param player? EntityPlayer -- The player to get the wisps from
---@param fromCollectible? CollectibleType -- Only get wisps spawned from using this collectible
---@return EntityFamiliar[]
function PlayerUtils.GetWisps(player, fromCollectible)
end

-- Gets all the locusts spawned by the player, index ordered from oldest to newest.
---@param player? EntityPlayer -- The player to get the locusts from
---@param fromCollectible? CollectibleType -- Only get locusts spawned from using this collectible
---@return EntityFamiliar[]
function PlayerUtils.GetLocusts(player, fromCollectible)
end

-- Returns a table with the amount of each collectible the player has without counting innate items.
---- This function has extra parameters for blacklisting certain items and tags.
---- Unlike `Isaac.GetPlayer():GetCollectiblesList()`, this table contains items the player ACTUALLY HAS.
---- If you only need the items without the amount, pass the result through `TableUtils.Keys()`
---@param player EntityPlayer
---@param itemTypeBlacklist? ItemType[]
---@param itemTagBlacklist? integer
---@param itemTypeWhitelist? ItemType[]
---@param itemTagWhitelist? integer
---@return table<CollectibleType, integer>
function PlayerUtils.GetCollectibleListCurated(player, itemTypeBlacklist, itemTagBlacklist, itemTypeWhitelist, itemTagWhitelist)
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
end

-- Returns a list with all the players that have the specified collectible
---@param collectibleType CollectibleType
---@return EntityPlayer[]
function PlayerUtils.GetPlayersWithCollectible(collectibleType)
end

-- Function that adds a charge to the active item
--
-- I don't like the default ways of adding a charge since I found them confusing to use
---@param player EntityPlayer -- The player who's item will get charged
---@param charge integer -- The amount of charge to add
---@param slot ActiveSlot -- The slot of the active item to charge
---@param force boolean? -- Default: `false` — Should the item be overcharged even if the player doesn't have The Battery?
---@param ignore_limit boolean? -- Default: `false` — Should the item be overcharged even past its limit?
---@param flashHUD boolean? -- Default: `false` — Should the player be notified of this recharge?
function PlayerUtils.AddActiveCharge(player, slot, charge, force, ignore_limit, flashHUD)
end

-- Function that keeps the active item's charge unchanged after item use
--
-- To be called on `ModCallbacks.MC_USE_ITEM`
---@param player EntityPlayer -- The player who's item will get freezed
---@param slot ActiveSlot? -- The slot of the active item to freeze
function PlayerUtils.FreezeActiveCharge(player, slot)
end

---@param player EntityPlayer
---@param cooldown integer -- Amount of time, in frames, that the shield should last
function PlayerUtils.AddShield(player, cooldown)
end

---@param player EntityPlayer
function PlayerUtils.HasShield(player)
end

-- Wrapper to make Car Battery synergies easier to write
-- Calls the provided function twice:
---- First time calls it with the parameter being 0
---- Second time it calls it with the flag UseFlag.USE_CARBATTERY as a parameter if Car Battery was used, otherwise it doesn't call the function at all
--
-- You should use this function like this:
-- ```
-- ARAOI.PlayerUtils.CarBatteryWrapper(player, function (car_battery_flag)
--     player:UseActiveItem(105, car_battery_flag)
-- end)
-- ```
---@param player EntityPlayer
---@param func function
function PlayerUtils.CarBatteryWrapper(player, func)
end

---@param player EntityPlayer
---@param sizeMultiplier? number -- The size of the attack
---@param direction? Vector -- The direction to spawn the attack towards
---@param mirror? boolean -- Should the attack be mirrored
---@param playSound? boolean -- Should we play the attack sound
function PlayerUtils.FireMelee(player, sizeMultiplier, direction, mirror, playSound)
end

ARAOI.PlayerUtils = PlayerUtils






---@class RoomUtils
local RoomUtils = {}

-- Returns a list of all GridEntities in the current room
---@return GridEntity[]
function RoomUtils.GetGridEntities()
end

-- Returns a list of all Pickups in the current room
---@return EntityPickup[]
function RoomUtils.GetPickups()
end

-- Returns the nearest enemy to the provided position
---@return Entity, number
function RoomUtils.GetNearestEnemy(position)
end

ARAOI.RoomUtils = RoomUtils






---@class TableUtils
local TableUtils = {}

-- Returns the index of the provided value
---@param t table
---@return integer
function TableUtils.FindFirstInstanceInTable(value, t)
end

-- Checks if the provided value is in the table
---@param t table
---@return boolean
function TableUtils.IsValueInTable(value, t)
end

-- Returns a list of all the table's keys
---@param t table
---@return table
function TableUtils.Keys(t)
end

-- Returns a list of all the table's values
---@param t table
---@return table
function TableUtils.Values(t)
end

-- Returns the keys and values of the provided table
---@param t table
---@return table, table
function TableUtils.KeysAndValues(t)
end

-- Returns a shallow copy of the table
---@param t table
---@return table
function TableUtils.ShallowCopy(t)
end

-- Returns one item random item from the table
---@param t table
---@param weights? table
---@param rng? RNG
---@return any
function TableUtils.Choice(t, weights, rng)
end

-- Splits a list into a number of other lists
---@return table[]
function TableUtils.SplitTable(t, num_sublists)
end

-- Shuffles the table in place
---@param rng? RNG
function TableUtils.ShuffleTable(t, rng)
end

-- Reverses the provided list
---@param list any[]
---@return any[]
function TableUtils.ReverseList(list)
end

ARAOI.TableUtils = TableUtils






-- Wrapper for the description reloaded callback
---@param func function
function ARAOI.EIDWrapper(func)
end

-- Calls the callback responsible for reloading the EID descriptions
function ARAOI.EIDReload()
end

---@class ModCallbacks
---@field OnReload string
---@field EIDReload string
ARAOI.ModCallbacks = {}






ARAOI.ThreeD_Glasses = {}

---@class ColorEnum
---@field NO_ITEM 0
---@field RED 1
---@field BLUE 2
---@field toggle function
ARAOI.ThreeD_Glasses.ColorEnum = {}

-- Gets/Sets the player's current color
---@param player EntityPlayer
---@param set? ColorEnum | integer
---@return ColorEnum
function ARAOI.ThreeD_Glasses.PlayerColorData(player, set)
end

-- Does the player have the 20/20 effect applied from the car battery synergy?
---@param player EntityPlayer
---@param set? boolean
---@return boolean
function ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player, set)
end

ARAOI.Bag_of_Holding = {}

-- Single use items. Modded items do not need to be added as they trigger
-- the RemoveCollectible function, which will be detected automatically
---@type CollectibleType[]
ARAOI.Bag_of_Holding.SingleUseItems = {}

-- Gets the player's stored items
--
-- If `add` is set, adds the item to the player's stored items and returns them
--
-- If `removeInstead` is set, removes the item defined in `add` from the player's stored items and returns them
---@param player EntityPlayer
---@param add? CollectibleType
---@param removeInstead? boolean -- Default: `false`
---@return CollectibleType[]
function ARAOI.Bag_of_Holding.StoredItems(player, add, removeInstead)
end

-- Cycles to the next item from the player's stored items. If we reached the end, it automatically wraps around
---@param player EntityPlayer
---@return integer
function ARAOI.Bag_of_Holding.CycleItem(player)
end

-- Gets the currently selected item, returns `nil` if no item is selected
---@param player EntityPlayer
---@return CollectibleType | nil
function ARAOI.Bag_of_Holding.GetSelectedItem(player)
end

---@param player EntityPlayer
---@param set? CollectibleType
---@return CollectibleType
function ARAOI.Bag_of_Holding.LastItemUsed(player, set)
end

ARAOI.Eternal_Dplopia = {}

ARAOI.Eternal_Dplopia.Config = {
    ITEM_DELETE_CHANCE      = 25, -- *Default: `25` — This is the same chance as the `Eternal D6`.*
    MIN_ITEM_DELETE_CHANCE  = 20, -- *Default: `20` — Goes from 1/4 to 1/5 chance of deleting an item, scaling with luck.*
    ITEM_DELETE_CHANCE_STEP = 5,  -- *Default: `5`  — Added chance for an item to getting deleted after picking up a cursed item.*

    LUCK_DECREASE_DELETION_CHANCE = 1, -- *Default: `1` — By how much should 1 luck decrease the chance of an item being deleted?*

    MAX_WISPS          = 2,  -- *Default: `2` — Maximum wisps that the item can spawn. Max: `8`, but set it to `9` to avoid deleting existing wisps. — WARNING: Setting this to 0 will throw an error!*
    WISP_DELETE_CHANCE = 35 -- *Default: `35` — The chance of a wisp being deleted instead of an item.*
}

-- Checks if the collectible is cursed for the current run
--
-- If `set` is passed, it sets the collectible's cursed state to the provided boolean
---@param collectible CollectibleType
---@param set? boolean
---@return boolean
function ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(collectible, set)
end

-- Get the amount of cursed items we picked up in the current floor
--
-- If `set` is passed, it sets the amount of collectibles picked up to the provided integer
---@param set? integer
---@return integer
function ARAOI.Eternal_Dplopia.CursedPickupCountForFloor(set)
end

-- Gets the current delete chance for the provided player, calculating it based on luck and cursed pickup count for the current floor
---@param player EntityPlayer
---@return number float From 0 to 1
function ARAOI.Eternal_Dplopia.GetCollectibleDeleteChanceForPlayer(player)
end

ARAOI.Glass_Die = {}

-- Function to add modded icons to the Glass Die
--
-- Sprites added this way will be rendered in the middle of the die with an offset of `Vector(16, 16)`, which means you should place the sprite in the middle of the green cursor when creating the ANM2 file
---@param sprite Sprite
---@param pool_id ItemPoolType
---@param sprite_frame integer
---@param sprite_offset? Vector
---@param sprite_scale? integer
---@param do_initial_setup? boolean -- Default: `true` — Sets some initial sprite variables just in case. Set this to `false` if it's giving errors
function ARAOI.Glass_Die.RegisterPoolSprite(sprite, pool_id, sprite_frame, sprite_offset, sprite_scale, do_initial_setup)
end

ARAOI.Rubiks_Cube = {}

ARAOI.Rubiks_Cube.Config = {
    SOLVE_CHANCE = 10 -- *Default: `10` — Chance for the item to be solved and give you the Rubik's Cube trinket.*
}

ARAOI.Spellbook = {}
ARAOI.Spellbook.Config = {
    ENABLE_EID_HISTORY = true, -- *Default: `true` — Enables the External Item Descriptions history.*
    MAX_EID_HISTORY = 10, -- *Default: `10` — Maximum number of items displayed on the External Item Descriptions history.*

    -- If we get these items, we roll again.
    -- This can be because the game just crashes, or the item just doesn't work.
    REROLL_ITEMS = {
        CollectibleType.COLLECTIBLE_DELIRIOUS
    },

    -- If you feel like an item should have a default spell that never changes, you can add it here
    --
    -- 1 = LEFT
    --
    -- 2 = UP
    --
    -- 3 = RIGHT
    --
    -- 4 = DOWN
    SPELL_OVERWRITE = {
        -- ["22441313"] = CollectibleType.COLLECTIBLE_DEATH_CERTIFICATE
    }
}

-- Checks if the player is writing a spell
--
-- If `is_writing` is passed, sets the current state to the provided boolean
---@param player EntityPlayer
---@param is_writing? boolean
---@return boolean
function ARAOI.Spellbook.IsPlayerWritingSpell(player, is_writing)
end

-- Gets the player's currently written spell
--
-- If `spell` is passed, sets the currently written spell to the provided string
---@param player EntityPlayer
---@param spell? string
---@return string
function ARAOI.Spellbook.PlayerWrittenSpell(player, spell)
end

-- Adds a temporary item to the player, which will be deleted on the next floor
---@param player EntityPlayer
---@param item CollectibleType
---@return nil
function ARAOI.Spellbook.AddTemporaryItemToPlayer(player, item)
end

-- Removes the temporary items from the player
---@param player EntityPlayer
---@return nil
function ARAOI.Spellbook.RemoveTemporaryItemsFromPlayer(player)
end

-- Returns the known spells for use with EID
--
-- If `spell` and `item` are passed, adds them to the known spells
---@param spell string?
---@param item CollectibleType?
---@return table table -- `{{spell: str, item: CollectibleType}, ...}`
function ARAOI.Spellbook.EIDRegisteredSpells(spell, item)
end

-- Converts the passed spell into a string of EID Inline Icons
---@param spell string
---@return string
function ARAOI.Spellbook.SpellToEIDInlineArrows(spell)
end

-- Function to add overwrites from other scripts or mods more easily
---@param spell string -- The spell which, when entered, will give the specified item. `1 = LEFT`, `2 = UP`, `3 = RIGHT`, `4 = DOWN`
---@param item CollectibleType
function ARAOI.Spellbook.AddSpellOverwrite(spell, item)
end

-- Function to add an item to the blacklist from other scripts or mods more easily
---@param item CollectibleType
function ARAOI.Spellbook.AddItemToBlacklist(item)
end

ARAOI.Blessings_Petal = {}

---@param add? integer -- How many pickups to add. Set to `0` to reset, `nil` to get the current value
---@return boolean
function ARAOI.Blessings_Petal.PickupCount(add)
end

ARAOI.Duality_Halo = {}

-- Spawns the collectibles
---@param ignoreChances boolean -- Should we ignore the deal spawn chance?
function ARAOI.Duality_Halo.SpawnCollectibles(ignoreChances)
end

ARAOI.Gambling_Chips = {}

ARAOI.Gambling_Chips.Config = {
    MAX_CHANCE  = 30, -- *Default: `30` — The maximum chance for a slot to spawn.*
    BASE_CHANCE = 15, -- *Default: `15` — The base chance for a slot to spawn, scales with luck using the `LUCK_MODIFIER` up uo `MAX_CHANCE`.*

    LUCK_MODIFIER = 0.75, -- *Default: `0.75` — Player's luck will be multiplied by this and added to the `BASE_CHANCE`.*

    COIN_CHANCE   = 10, -- *Default: `10` — Chance to spawn a coin on enemy kill.*
}

-- Gets a random slot machine that is considered "gambling"
---@param rng? RNG
---@param allowSelfDamage? boolean
---@return SlotVariant
function ARAOI.Gambling_Chips.GetRandomGamblingSlot(rng, allowSelfDamage)
end

ARAOI.Lucky_Coin = {}

ARAOI.Lucky_Coin.Config = {
    COIN_TIMEOUT = 120, -- *Default: `120` — The amount of time the coin will stay in the air, in update frames.*

    CHANCE_PER_LUCK = 1, -- *Default: `1` — The chance per 1 luck that will be added towards doubling the damage.*
}

-- Spawn a coin for the provided player
---@param player EntityPlayer
function ARAOI.Lucky_Coin.SpawnCoin(player)
end

ARAOI.Rainbow_Headband = {}

ARAOI.Rainbow_Headband.Config = {
    TIME_MODIFIER = 0, -- *Default: `0` — Time added, in seconds, when calculating the amount of time you had this item for.*

    INCREASE_TRAIL_SIZE_EVERY = 25, -- *Default: `25` — Time it takes, in seconds, for the trail to get longer.*
    INCREASE_TRAIL_TIMEOUT_BY = 3,  -- *Default: `3` — Time added every `INCREASE_TRAIL_SIZE_EVERY`, in frames, that it takes the trail to be removed.*

    CREEP_COLOR_INTERVAL_MULTIPLIER = 1, -- *Default: `1` — Multiplier for the color change of the creep, higher values means the creep will switch colors quicker.*

    INSTANTLY_REMOVE_CREEP = true -- *Default: `true` — Should the creep be instantly removed? The animation of the creep disappearing does not do damage to enemies.*
}

-- Gets the frame at which the player picked up the item, returns `-1` if the player hasn't picked up the item yet
--
-- If `set` is provided 
---@param player any
---@param set? any
function ARAOI.Rainbow_Headband.PickedUpTimestamp(player, set)
end

-- Calculates the creep timeout, after which it will disappear
---@param player EntityPlayer
function ARAOI.Rainbow_Headband.GetCreepTimeout(player)
end


ARAOI.Sacrificial_Heart = {}
ARAOI.Sacrificial_Heart.Config = {
    BROKEN_HEARTS = 2 -- *Default: `2` — The amount of broken hearts the player will get. T. Magdalene will multiply this by 2.*
}

ARAOI.Vampire_Cloak = {}

-- Creates a bat particle that follows the player
---@param player EntityPlayer
---@param amount integer
---@param offset number
function ARAOI.Vampire_Cloak.AddBatParticles(player, amount, offset)
end

-- Checks if the player has invincibility
---@param player EntityPlayer
---@param set? boolean
function ARAOI.Vampire_Cloak.PlayerHasInvincibility(player, set)
end

-- Checks if the player has a Vampire Cloak charge
---@param player EntityPlayer
---@param set? boolean
function ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player, set)
end

ARAOI.Voodoo_Body = {}

ARAOI.Voodoo_Body.Config = {
    DAMAGE_SCALE    = 0.65, -- *Default: `0.65` — The number that the player's damage will be multiplied by when doing damage with the pin.*
    VOODOO_HEAD_ADD = 0.35, -- *Default: `0.35` — The number that will be added to the `DAMAGE_SCALE` when the player is holding Voodoo Head.*
}

-- Spawns a curse pin on the provided attacker
---@param attack Entity
---@param spawner Entity
---@param damage number
---@param spriteScale? number
---@param effects? TearFlags
function ARAOI.Voodoo_Body.SpawnCursePin(attack, spawner, damage, spriteScale, effects)
end

ARAOI.Inverted_Spades = {}

ARAOI.Inverted_Spades.Config = {
    REPLACE_CHANCE_ADDED = 15 -- *Default: `15` — Chance added to the replacement chance of Inverted Cards*
}

ARAOI.Solved_Rubiks_Cube = {}

ARAOI.Solved_Rubiks_Cube.Config = {
    STAT_BOOST_PER_WISP = 10 -- *Default: `10` — Percentage of the stat boost provided per wisp.*
}

ARAOI.Inverted_Cards = {}

ARAOI.Inverted_Cards.Config = {
    REPLACE_CHANCE = 15 -- *Default: `15` — The % chance that a card will be overwritten*
}

local CardData = {
    ID = ARAOI.CardSubType,
    Replace = -1,
    ReplaceChance = nil
}

ARAOI.Inverted_Cards.Fool = CardData
ARAOI.Inverted_Cards.Magician = CardData
ARAOI.Inverted_Cards.High_Priestess = CardData
ARAOI.Inverted_Cards.Empress = CardData
ARAOI.Inverted_Cards.Emperor = CardData
ARAOI.Inverted_Cards.Hermit = CardData
ARAOI.Inverted_Cards.Hierophant = CardData
ARAOI.Inverted_Cards.Lovers = CardData
ARAOI.Inverted_Cards.Chariot = CardData
ARAOI.Inverted_Cards.Justice = CardData
ARAOI.Inverted_Cards.Wheel_of_Fortune = CardData
ARAOI.Inverted_Cards.Strength = CardData
ARAOI.Inverted_Cards.Hanged_Man = CardData
ARAOI.Inverted_Cards.Death = CardData
ARAOI.Inverted_Cards.Temperance = CardData
ARAOI.Inverted_Cards.Devil = CardData
ARAOI.Inverted_Cards.Tower = CardData
ARAOI.Inverted_Cards.Stars = CardData
ARAOI.Inverted_Cards.Moon = CardData
ARAOI.Inverted_Cards.Sun = CardData
ARAOI.Inverted_Cards.Judgement = CardData
ARAOI.Inverted_Cards.World = CardData

ARAOI.Inverted_Cards.Temperance.Config = {
    DAMAGE_GIVEN = 0.75 -- *Default: `0.75` — Amount of damage that will be given per half a heart drained.*
}

ARAOI.Inverted_Cards.Empress.Config = {
    NUM_MINIISAAC = 10 -- *Default: `10` — The number of MiniIsaacs to spawn*
}

ARAOI.Inverted_Cards.Stars.Config = {
    NUM_RANDOM_EFFECTS = 5 -- *Default: `5` — The number of random effects the glitched item will have.*
}



---@param player EntityPlayer
function ARAOI.Inverted_Cards.Magician.GetEffectCountdown(player)
end

---@param player EntityPlayer
---@param set number -- Time in seconds that the effect should last
function ARAOI.Inverted_Cards.Magician.SetEffectCountdown(player, set)
end

---@param player EntityPlayer
---@param add number -- Time in seconds that should be added to the effect duration
function ARAOI.Inverted_Cards.Magician.AddEffectCountdown(player, add)
end



-- Register a curse to be added when this card is used
---@param curse LevelCurse
function ARAOI.Inverted_Cards.Sun.AddCurse(curse)
end