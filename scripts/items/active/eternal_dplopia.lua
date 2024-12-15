local Config = {}

----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.ITEM_DELETE_CHANCE      = 25 -- *Default: `25` — This is the same chance as the `Eternal D6`.*
Config.MIN_ITEM_DELETE_CHANCE  = 20 -- *Default: `20` — Goes from 1/4 to 1/5 chance of deleting an item, scaling with luck.*
Config.ITEM_DELETE_CHANCE_STEP = 5  -- *Default: `5`  — Added chance for an item to getting deleted after picking up a cursed item.*

Config.LUCK_DECREASE_DELETION_CHANCE = 1 -- *Default: `1` — By how much should 1 luck decrease the chance of an item being deleted?*

Config.MAX_WISPS          = 2  -- *Default: `2` — Maximum wisps that the item can spawn. Max: `8`, but set it to `9` to avoid deleting existing wisps. — WARNING: Setting this to 0 will throw an error!*
Config.WISP_DELETE_CHANCE = 35 -- *Default: `35` — The chance of a wisp being deleted instead of an item.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Eternal_Dplopia = {}
ARAOI.Eternal_Dplopia.Config = Config

local CURSE_PEDESTALS_CALLBACK = "Eternal Dplopia Curse All Pedestals"


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
    local value = ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "EternalDplopiaCursedObjects", {}, collectible, false, set)
    return value
end

-- Get the amount of cursed items we picked up in the current floor
--
-- If `set` is passed, it sets the amount of collectibles picked up to the provided integer
---@param set? integer
---@return integer
function ARAOI.Eternal_Dplopia.CursedPickupCountForFloor(set)
    local pickup_count = ARAOI.SaveData:Key(ARAOI.SaveData.LEVEL, "EternalDplopiaCursedPickupCount", 0, set)
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

---@param rng RNG
---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, useFlags)
    local game = Game()

    if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

    local car_battery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

    local room = game:GetRoom()

    -- Keeping track of option indexes
    local translated_indexes = {}

    -- Get all entities in the room
    for _, entity in pairs(Isaac.GetRoomEntities()) do
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
            local new_collectible = Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_COLLECTIBLE,
                room:GetSeededCollectible(rng:GetSeed()),
                Isaac.GetCollectibleSpawnPosition(collectible.Position),
                Vector.Zero,
                nil
            ):ToPickup()
            assert(new_collectible)

            -- Set the new item's ID as cursed
            ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(new_collectible.SubType, true)

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

    -- Schedule setting all pedestals in the room to be cursed
    -- We need to schedule it so it can curse items spawned by T. Isaac and Glitched Crown
    -- If you later naturally get a cursed item in the pedestal cycle, only that item will get cursed
    ARAOI.SaveData:CreateTimer(CURSE_PEDESTALS_CALLBACK, 1)

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
end, ARAOI.CollectibleType.ETERNAL_DPLOPIA)


-----------------
-- ON ITEM GET --
-----------------

---@param collectibleType CollectibleType
---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function (_, collectibleType, _, _, _, _, player)

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
end)


--------------------------
-- CURSED ITEM RENDERER --
--------------------------

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        local pickup = entity:ToPickup()
        if not pickup then goto continue end

        -- If the pickup is not a collectible, we skip it
        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then goto continue end

        -- Check if the item is cursed
        if ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(pickup.SubType) then

            -- Setting the values for the tint
            local tint = {1.8, 1.8, 1.8, 1.0}

            -- Set the pickup tint to white
            pickup:GetColor():SetTint(table.unpack(tint))
        else
            -- Reset the color if the item is not cursed
            pickup:GetColor():Reset()
        end

        ::continue::
    end
end)

ARAOI.Mod:AddCallback(CURSE_PEDESTALS_CALLBACK, function ()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        local pickup = entity:ToPickup()
        if not pickup then goto continue end

        -- Curse the other items in the cycle
        -- We make it so T. Isaac, Glitched Crown and Binge Eater can't bypass curses
        for _, id in pairs(pickup:GetCollectibleCycle()) do
            ARAOI.Eternal_Dplopia.IsCollectibleTypeCursed(id, true)
        end

        ::continue::
    end
end)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.ReloadableDescription(function ()
    EID:addCollectible(ARAOI.CollectibleType.ETERNAL_DPLOPIA,
        "Duplicates items into random ones from the current pool"..
        "#{{BrimstoneCurse}} Items will become cursed, having a "..Config.ITEM_DELETE_CHANCE.."% "..
            "chance of deleting one of your items and increasing it by "..Config.ITEM_DELETE_CHANCE_STEP.."% "..
            "for each item picked up"..
        "#{{ArrowUp}} Chance resets each floor"..
        "#{{Luck}} "..Config.LUCK_DECREASE_DELETION_CHANCE.."% less chance per 1 luck"
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
        EID:appendToDescription(descObject, "#{{Collectible"..ARAOI.CollectibleType.ETERNAL_DPLOPIA.."}} "..math.floor(deleteChance).."% chance to delete one of your items")
        return descObject
    end
    EID:addDescriptionModifier("Cursed Object Description", condition, modifier)
end)