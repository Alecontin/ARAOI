local Config = {}

----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.ITEM_DELETE_CHANCE      = 25 -- *Default: `25` — This is the same chance as the `Eternal D6`.*
Config.MIN_ITEM_DELETE_CHANCE  = 20 -- *Default: `20` — Goes from 1/4 to 1/5 chance of deleting an item, scaling with luck.*
Config.ITEM_DELETE_CHANCE_STEP = 5  -- *Default: `5`  — Added chance for an item of getting deleted after picking up a cursed item.*

Config.LUCK_DECREASE_DELETION_CHANCE = 1 -- *Default: `1` — By how much should 1 luck decrease the chance of an item being deleted?*

Config.MAX_WISPS          = 2  -- *Default: `2` — Maximum wisps that the item can spawn. Max: `8`, but set it to `9` to avoid deleting existing wisps. — WARNING: Setting this to 0 will throw an error!*
Config.WISP_DELETE_CHANCE = 35 -- *Default: `35` — The chance of a wisp being deleted instead of an item.*


--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Eternal_Dplopia = {}
ARAOI.Eternal_Dplopia.Config = Config


---------------
-- FUNCTIONS --
---------------

-- Checks if the collectible is cursed for the current run
--
-- If `set` is passed, it sets the collectible's cursed state to the provided boolean
---@param collectible CollectibleType
---@param set? boolean
---@return boolean
function ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(collectible, set)
    local value = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "EternalDplopiaCursedObjects", {}, collectible, false, set)
    return value
end

-- Get the amount of cursed items we picked up in the current floor
--
-- If `set` is passed, it sets the amount of collectibles picked up to the provided integer
---@param set? integer
---@return integer
function ARAOI.Eternal_Dplopia.CursedPickupCountForFloor(set)
    local pickup_count = ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.LEVEL, "EternalDplopiaCursedPickupCount", 0, set)
    return pickup_count
end

-- Gets the current delete chance for the provided player, calculating it based on luck and cursed pickup count for the current floor
---@param player EntityPlayer
---@return number float From 0 to 1
function ARAOI.Eternal_Dplopia.GetCollectibleDeleteChanceForPlayer(player)
    local chance = math.max(Config.MIN_ITEM_DELETE_CHANCE, (Config.ITEM_DELETE_CHANCE + ARAOI.Eternal_Dplopia.CursedPickupCountForFloor() * Config.ITEM_DELETE_CHANCE_STEP) - player.Luck * Config.LUCK_DECREASE_DELETION_CHANCE)
    chance = math.min(chance, 100)
    chance = chance / 100

    return chance
end


-----------------
-- ON ITEM USE --
-----------------

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnEternalDplopiaUse(_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

    local car_battery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

    -- Keeping track of option indexes
    local translated_indexes = {}

    -- Get all entities in the room
    for _, entity in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, nil, true)) do
        -- Check if entity is a pickup
        local collectible = entity:ToPickup()
        if not collectible then goto next_entity end

        -- Check if entity is a collectible, and it's not an empty pedestal
        if collectible.Variant ~= PickupVariant.PICKUP_COLLECTIBLE
        or collectible.SubType == CollectibleType.COLLECTIBLE_NULL
        then goto next_entity end

        -- Set the item's ID as cursed
        ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(collectible.SubType, true)

        -- Spawn a new item, or multiple with car battery
        local items_to_spawn = 1
        if car_battery then items_to_spawn = items_to_spawn + 1 end

        for _ = 1, items_to_spawn do
            -- Get a list of items to spawn
            local items = ARAOI.ItemUtils.GetCollectibleCycle()

            -- Set the items we want to spawn as cursed
            for _, id in ipairs(items) do
                ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(id, true)
            end

            -- Spawn the item pedestal
            local new_collectible = ARAOI.ItemUtils.SpawnCollectible(items, Isaac.GetCollectibleSpawnPosition(collectible.Position), nil, nil, true)

            -- Account for item choice
            if collectible.OptionsPickupIndex ~= 0 then
                -- If this choice was already translated to a new one, use that one
                -- What I mean is, we get the first option index, and change it to 2
                -- then, when we get the other option with the same index, we use the changed one
                local translated = translated_indexes[collectible.OptionsPickupIndex]

                -- If we didn't translate this index, we do it now
                if not translated then
                    translated = new_collectible:SetNewOptionsPickupIndex()
                    translated_indexes[collectible.OptionsPickupIndex] = translated
                end

                -- Finally, give the new index to the item
                new_collectible.OptionsPickupIndex = translated
            end
        end
        ::next_entity::
    end

    ---------------------
    -- BOOK OF VIRTUES --
    ---------------------

    -- Spawn an extra wisp due to car battery
    if car_battery and player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
        player:AddWisp(ARAOI.CollectibleType.ETERNAL_DPLOPIA, player.Position)
    end

    -- Getting all the player's wisps
    local wisps = ARAOI.PlayerUtils.GetWisps(player, ARAOI.CollectibleType.ETERNAL_DPLOPIA)
    local max = Config.MAX_WISPS
    if car_battery then max = max - 1 end

    -- Remove the excess wisps since we are only supposed to have 2
    for excess_wisps = max, #wisps, 1 do
        wisps[excess_wisps]:Remove()
    end

    -- We need to return true for the item to have an animation
    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnEternalDplopiaUse, ARAOI.CollectibleType.ETERNAL_DPLOPIA)


-----------------
-- ON ITEM GET --
-----------------

---@param collectibleType CollectibleType
---@param player EntityPlayer
function ARAOI:_OnEternalDplopiaPreAddCollectible(collectibleType, _, _, _, _, player)
    -- Don't do anything if the item is not cursed
    if not ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(collectibleType) then return end

    -- Get the player's item list EXCLUDING quest items
    -- We shouldn't remove them since that's how it works in the vanilla game
    local player_items = ARAOI.PlayerUtils.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST)

    -- Get the rng for random numbers
    local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.ETERNAL_DPLOPIA)

    -- Get the chance for an item to be deleted
    local chance = ARAOI.Eternal_Dplopia.GetCollectibleDeleteChanceForPlayer(player)

    -- Check if we should delete an item
    if rng:RandomFloat() <= chance then
        -- Get the player's wisps
        local wisps = ARAOI.PlayerUtils.GetWisps(player, ARAOI.CollectibleType.ETERNAL_DPLOPIA)

        -- If we roll to remove a wisp instead of an item, and the player has wisps
        if rng:RandomFloat() <= (Config.WISP_DELETE_CHANCE / 100) and #wisps > 0 then
            -- We remove a wisp
            wisps[1]:Kill()

        else
            -- Convert the player_items into a list
            local player_items_list = ARAOI.TableUtils.Keys(player_items)

            -- Removing an item from an empty list gives an error
            if #player_items_list > 0 then 
                -- Get a random position in the list
                local remove_position = rng:RandomInt(#player_items_list) + 1 -- Random Int is 0-indexed while tables are 1-indexed

                -- Get the item ID of the position selected
                local item_to_be_removed = player_items_list[remove_position]

                -- Remove the item
                player:RemoveCollectible(item_to_be_removed, true)

                -- Show the player what item was lost
                player:AnimateCollectible(item_to_be_removed)

                -- Play a sound for the removal
                SFXManager():Play(SoundEffect.SOUND_FLASHBACK)  -- SOUND FLASHBACK
            end
        end
    end

    -- Lastly, increase delete chance
    ARAOI.Eternal_Dplopia.CursedPickupCountForFloor(ARAOI.Eternal_Dplopia.CursedPickupCountForFloor() + 1)
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, ARAOI._OnEternalDplopiaPreAddCollectible)


--------------------------
-- CURSED ITEM RENDERER --
--------------------------

function ARAOI:_OnEternalDplopiaUpdate()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        local pickup = entity:ToPickup()
        if not pickup then goto continue end

        -- If the pickup is not a collectible, we skip it
        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then goto continue end

        -- Setting the values for the tint
        local tint = {1.8, 1.8, 1.8, 1.0}
        local item_tint = pickup:GetColor():GetTint()

        -- Check if the item is cursed
        if ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(pickup.SubType) then
            -- Set the pickup tint to white
            pickup:GetColor():SetTint(table.unpack(tint))
        elseif item_tint.R == tint[0] and item_tint.G == tint[1] and item_tint.B == tint[2] then
            -- If the item is not cursed, and our tint is applied, reset the tint
            pickup:GetColor():Reset()
        end

        ::continue::
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnEternalDplopiaUpdate)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.ETERNAL_DPLOPIA,
        "Doubles pedestals on use"..
        "#{{BrimstoneCurse}} Items will become cursed"..
        "# Picking up a cursed item has a "..Config.ITEM_DELETE_CHANCE.."% chance of deleting "..
            "one of Isaac's items, which increases by "..Config.ITEM_DELETE_CHANCE_STEP.."%  with every cursed item picked up"..
        "# Chance resets each floor"..
        "#{{Luck}} "..Config.LUCK_DECREASE_DELETION_CHANCE.."% less chance per 1 luck"
    )

    ARAOI.EIDUtils.CarBatterySynergy(
        "Eternal Dplopia Car Battery Synergy",
        ARAOI.CollectibleType.ETERNAL_DPLOPIA,
        "Triplicates items into random ones from the current pool"
    )
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "Eternal Dplopia Book Of Virtues Synergy",
        ARAOI.CollectibleType.ETERNAL_DPLOPIA,
        Config.WISP_DELETE_CHANCE.."% chance of a wisp getting deleted instead of an item"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Eternal Dplopia Abyss Synergy",
        ARAOI.CollectibleType.ETERNAL_DPLOPIA,
        "2 white locusts that deal normal damage"
    )

    local function condition(descObject)
        if descObject.ObjType == EntityType.ENTITY_PICKUP
        and descObject.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE
        and descObject.Entity
        then return ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(descObject.ObjSubType) end
    end
    local function modifier(descObject)
        local game = Game()
        local player = game:GetNearestPlayer(descObject.Entity.Position)
        local deleteChance = ARAOI.Eternal_Dplopia.GetCollectibleDeleteChanceForPlayer(player) * 100
        EID:appendToDescription(descObject, "#{{Collectible"..ARAOI.CollectibleType.ETERNAL_DPLOPIA.."}} "..math.floor(deleteChance).."% chance to delete one of Isaac's items")
        return descObject
    end
    EID:addDescriptionModifier("Cursed Object Description", condition, modifier)
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Actives", "Eternal Dplopia")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "ITEM_DELETE_CHANCE",
    ConfigDefaults, ConfigDefaults.ITEM_DELETE_CHANCE .. "%", 0, 100, 10, function ()
        return "Item Delete Chance: " .. Config.ITEM_DELETE_CHANCE .. "%"
    end, "Chance of an item being deleted when picking up a cursed item")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "MIN_ITEM_DELETE_CHANCE",
    ConfigDefaults, ConfigDefaults.MIN_ITEM_DELETE_CHANCE .. "%", 0, 100, 10, function ()
        return "Min Item Delete Chance: " .. Config.MIN_ITEM_DELETE_CHANCE .. "%"
    end, "The minimum chance of an item being deleted when picking up a cursed item")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "ITEM_DELETE_CHANCE_STEP",
    ConfigDefaults, ConfigDefaults.ITEM_DELETE_CHANCE_STEP .. "%", 0, 100, 10, function ()
        return "Item Delete Chance Step: +" .. Config.ITEM_DELETE_CHANCE_STEP .. "%"
    end, "Added chance for an item of getting deleted after picking up a cursed item")

    ModConfigMenu.AddSpace("ARAOI", "Actives")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "LUCK_DECREASE_DELETION_CHANCE",
    ConfigDefaults, ConfigDefaults.LUCK_DECREASE_DELETION_CHANCE .. "% per 1 luck", 0, 100, 10, function ()
        return "Luck Decrease Modifier: -" .. Config.LUCK_DECREASE_DELETION_CHANCE .. "% per 1 luck"
    end, "By how much should 1 luck decrease the chance of an item being deleted?")

    ModConfigMenu.AddSpace("ARAOI", "Actives")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "WISP_DELETE_CHANCE",
    ConfigDefaults, ConfigDefaults.WISP_DELETE_CHANCE .. "%", 0, 100, 10, function ()
        return "Wisp Delete Chance: " .. Config.WISP_DELETE_CHANCE .. "%"
    end, "Chance of a wisp getting deleted instead of an item")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Eternal Dplopia", Config, "MAX_WISPS",
    ConfigDefaults, ConfigDefaults.MAX_WISPS, 0, 8, 1, function ()
        return "Max Wisps: " .. Config.MAX_WISPS
    end, "Maximum wisps that the item can spawn")

    ARAOI.MCMUtils.AddReset("Actives", "Eternal Dplopia")
end