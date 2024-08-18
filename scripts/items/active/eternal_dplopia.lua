----------------------------
-- START OF CONFIGURATION --
----------------------------



local ITEM_DELETE_CHANCE     = 25 -- *Default: `25` — This is the same chance as the `Eternal D6`.*
local MIN_ITEM_DELETE_CHANCE = 20 -- *Default: `20` — Goes from 1/4 to 1/5 chance of deleting an item, scaling with luck.*

local MAX_WISPS = 2 -- *Default: `2` — Maximum wisps that the item can spawn. Max: `8`, but set it to `9` to avoid deleting existing wisps. — WARNING: Setting this to 0 will throw an error!*
local WISP_DELETE_CHANCE = 35 -- *Default: `35` — The chance of a wisp being deleted instead of an item.*

local SHOULD_ITEM_SPAWN_DISCHARGED = false -- *Default: `false` — Set this to `true` if you plan to start with the item, that way you'll have some items by the time you use it.*



--------------------------
-- END OF CONFIGURATION --
--------------------------

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@class Helper
local Helper = include("scripts.Helper")

local ETERNAL_DPLOPIA = Isaac.GetItemIdByName("Eternal Dplopia")

local CURSE_PEDESTALS_CALLBACK = "Eternal Dplopia Curse All Pedestals"


---------------
-- FUNCTIONS --
---------------

---@param collectible CollectibleType
---@param set? boolean
local function cursed(collectible, set)
    local value = SaveData:Data(SaveData.RUN, "CursedObjects", {}, collectible, false, set)
    return value
end

---@param set_to? integer
local function pickupCount(set_to)
    local PickupCount = SaveData.LEVEL["CursedPickupCount"] or 0
    SaveData.LEVEL["CursedPickupCount"] = set_to or PickupCount
    return PickupCount
end

---@param player EntityPlayer
---@return number
local function getDeleteChance(player)
    local chance = math.max(MIN_ITEM_DELETE_CHANCE, ITEM_DELETE_CHANCE - player.Luck)
    chance = math.min(chance + pickupCount() * 5, 100)
    chance = chance / 100

    return chance
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    ---@class EID -- This is used in 2 different places so I put it here

    local game = Game()
    -- local ItemPool = game:GetItemPool()


    -----------------
    -- ON ITEM USE --
    -----------------

    ---@param rng RNG
    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    local function onItemUsed(_, collectibleType, rng, player, useFlags)
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

        local carBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

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
            cursed(collectible.SubType, true)

            -- Schedule setting all pedestals in the room to be cursed
            -- We need to schedule it so it can curse items spawned by T. Isaac and Glitched Crown
            -- If you later naturally get a cursed item in the pedestal cycle, only that item will get cursed
            SaveData:CreateTimer(CURSE_PEDESTALS_CALLBACK, 1, true)

            -- Spawn a new item, or multiple with car battery
            local itemsToSpawn = 1
            if carBattery then itemsToSpawn = itemsToSpawn + 1 end

            for _ = 1, itemsToSpawn do
                local new_collectible = Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_COLLECTIBLE,
                    room:GetSeededCollectible(rng:GetSeed()),
                    Isaac.GetCollectibleSpawnPosition(collectible.Position),
                    Vector.Zero,
                    nil
                ):ToPickup()

                -- Set the new item's ID as cursed
                cursed(new_collectible.SubType, true)

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
        if carBattery and player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            player:AddWisp(ETERNAL_DPLOPIA, player.Position)
        end

        -- Getting all the player's wisps
        local wisps = Helper.GetPlayerWisps(player, ETERNAL_DPLOPIA)
        local max = MAX_WISPS
        if carBattery then max = max - 1 end

        -- Remove the excess wisps since we are only supposed to have 2
        for excessWisps = max, #wisps, 1 do
            wisps[excessWisps]:Remove()
        end

        -- We need to return true for the item to have an animation
        return true
    end
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, onItemUsed, ETERNAL_DPLOPIA)


    -----------------
    -- ON ITEM GET --
    -----------------

    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    local function onItemPickup(_, collectibleType, charge, firstTime, slot, data, player)
        -- Check if we just picked up our item, if so, remove the charges
        if collectibleType == ETERNAL_DPLOPIA and firstTime == true and SHOULD_ITEM_SPAWN_DISCHARGED then
            return {collectibleType, 0, firstTime, slot, data}
        end

        -- Don't do anything if the item is cursed
        if not cursed(collectibleType) then return end

        -- Get the player's item list EXCLUDING quest items
        -- We shouldn't remove them since that's how it works in the vanilla game
        local player_items = Helper.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST)

        -- Get the rng for random numbers
        local rng = player:GetCollectibleRNG(ETERNAL_DPLOPIA)

        -- Get the chance for an item to be deleted
        local chance = getDeleteChance(player)

        -- Check if we should delete an item
        if rng:RandomFloat() <= chance then
            -- Get the player's wisps
            local wisps = Helper.GetPlayerWisps(player, ETERNAL_DPLOPIA)

            -- If we roll to remove a wisp instead of an item, and the player has wisps
            if rng:RandomFloat() <= (WISP_DELETE_CHANCE / 100) and #wisps > 0 then
                -- We remove a wisp
                wisps[1]:Kill()

            else
                -- Convert the player_items into a list
                local player_items_list = Helper.Keys(player_items)

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
        pickupCount(pickupCount() + 1)
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, onItemPickup)


    --------------------------
    -- CURSED ITEM RENDERER --
    --------------------------

    local function renderCursedItems(_)
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            local pickup = entity:ToPickup()
            if not pickup then goto continue end

            if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then goto continue end

            -- Check if the item is cursed
            if cursed(pickup.SubType) then

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
    end
    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, renderCursedItems)

    local function cursePedestals()
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            local pickup = entity:ToPickup()
            if not pickup then goto continue end

            -- Curse the other items in the cycle
            -- We make it so T. Isaac, Glitched Crown and Binge Eater can't bypass curses
            for _, id in pairs(pickup:GetCollectibleCycle()) do
                cursed(id, true)
            end

            ::continue::
        end
    end
    Mod:AddCallback(CURSE_PEDESTALS_CALLBACK, cursePedestals)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    if EID then
        local description = "Duplicates items and rerolls the duplicated ones"..
                            "#{{ArrowDown}} Adds a curse on the items"..
                            "#{{BrimstoneCurse}} Picking up a cursed item has a "..ITEM_DELETE_CHANCE.."% chance of deleting one of your items and increases deletion chance by 5%"..
                            "#{{ArrowUp}} Delete chance resets each floor"..
                            "#{{Luck}} 1% less chance per 1 luck, 20% minimum"..
                            "#!!! Items will remain cursed for the duration of the run"

        EID:addCollectible(ETERNAL_DPLOPIA, description)

        local VIRTUES = CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES
        local VIRTUES_ICON =  "#{{Collectible"..VIRTUES.."}} "

        ---@param descObject EIDDescriptionObject
        local function anyPlayerHasBookOfVirtues(descObject)
            if descObject.ObjType == EntityType.ENTITY_PICKUP
            and descObject.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE
            and descObject.ObjSubType == ETERNAL_DPLOPIA
            then return PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) end
        end

        ---@param descObject EIDDescriptionObject
        local function showWisps(descObject)
            EID:appendToDescription(descObject, VIRTUES_ICON.." Wisp has a "..WISP_DELETE_CHANCE.."% chance of getting deleted instead of an item. 2 wisps max")
            return descObject
        end
        EID:addDescriptionModifier(ETERNAL_DPLOPIA.." Virtues", anyPlayerHasBookOfVirtues, showWisps)

        local function condition(descObject)
            if descObject.ObjType == EntityType.ENTITY_PICKUP
            and descObject.ObjVariant == PickupVariant.PICKUP_COLLECTIBLE
            and descObject.Entity
            then return cursed(descObject.ObjSubType) end
        end 
        local function modifier(descObject)
            local player = game:GetNearestPlayer(descObject.Entity.Position)
            local deleteChance = getDeleteChance(player) * 100
            EID:appendToDescription(descObject, "#{{Collectible"..ETERNAL_DPLOPIA.."}} "..math.floor(deleteChance).."% chance to delete one of your items")
            return descObject
        end
        EID:addDescriptionModifier("Cursed Object Description", condition, modifier)
    end
end

return modded_item