local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.PERMANENT_QUALITY = false -- *Default: `false` — Should the stored quality be permanent?*
Config.AFFECTS_ALL_ITEMS = false -- *Default: `false` — Should we affect all items? Stores the highest quality and rerolls all items into that quality*
Config.CHAOS_MODE = false -- *Default: `false` — Reroll into any pool?*

Config.CAR_BATTERY_CHANCE = 15 -- *Default: `15` — Chance of the Car Battery synergy to take effect*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------


ARAOI.VoidDie = {}

local SFX = SFXManager()
local ItemConfig = Isaac.GetItemConfig()
ItemConfig:GetCollectible(ARAOI.CollectibleType.VOID_DIE).GfxFileName = "gfx/ui/hud_void_die.png"


---------------
-- ON PICKUP --
---------------

---@param firstTime boolean
---@param slot ActiveSlot
---@param player EntityPlayer
function ARAOI:_OnVoidDieAddCollectible(_, _, firstTime, slot, _, player)
    if firstTime then
        player:GetActiveItemDesc(slot).VarData = -1
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, ARAOI._OnVoidDieAddCollectible, ARAOI.CollectibleType.VOID_DIE)


--------------
-- ITEM USE --
--------------

---@param player EntityPlayer
function ARAOI:_OnVoidDieUse(_, _, player, useFlag, slot)
    if useFlag & UseFlag.USE_CARBATTERY > 0 then return end

    -- Need this for later
    local desc = player:GetActiveItemDesc(slot)

    -- Function that tries to apply the Car Battery Synergy
    ---@param apply? boolean Default: `true` — Apply the quality upgrade to the VarData? If not, it will just run the check
    local function TryApplyQualityUpgrade(apply)
        -- Setting param defaults
        if apply == nil then apply = true end

        -- If we have Car Battery
        if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
            -- We get the rng of our item
            local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.VOID_DIE)
            -- Check if we hit the probability
            if rng:RandomFloat() <= Config.CAR_BATTERY_CHANCE/100 then
                -- Getting the new quality (max 4)
                local new_quality = math.min(4, desc.VarData + 1)
                -- If we need to apply it we do
                if apply then desc.VarData = new_quality end
                -- Let the player know by playing a sound
                SFX:Play(SoundEffect.SOUND_BATTERYCHARGE, 1, 2, false, 1.2)
                -- Return the new quality
                return new_quality
            end
        end
        -- We didn't hit the probability, return the current quality
        return desc.VarData
    end

    -- Function that tries to add the item wisp if we have Book of Virtues
    ---@param item ItemConfigItem
    local function TryAddItemWisp(item)
        -- Check if we have Book of Virtues
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            -- If the item we destroyed is an active item, add the normal wisp
            if item.Type == ItemType.ITEM_ACTIVE then
                player:AddWisp(item.ID, player.Position, true)
            -- If the item we destroyed is a passive item, add the item wisp
            elseif item.Type == ItemType.ITEM_PASSIVE then
                player:AddItemWisp(item.ID, player.Position, true)
            end
        end
    end

    -- If we currently don't have a quality selected
    if desc.VarData == -1 then
        -- If we don't need to affect all items then
        if not Config.AFFECTS_ALL_ITEMS then
            -- If we aren't holding a new collectible
            if player:IsItemQueueEmpty() then
                -- Get the closest one
                local closest_collectible = ARAOI.PlayerUtils.GetClosestCollectible(player)

                -- If we successfully found a collectible and it's free
                if closest_collectible and not closest_collectible:IsShopItem() then
                    -- Get it's id and quality, then change our item's stored quality
                    local collectible_id = closest_collectible.SubType
                    local quality = ItemConfig:GetCollectible(collectible_id).Quality
                    desc.VarData = quality

                    -- Try to add an item wisp, we need the ItemConfigItem for this
                    TryAddItemWisp(ItemConfig:GetCollectible(collectible_id))

                    -- Remove the collectible and delete the other items if it's a choice
                    closest_collectible:Remove()
                    closest_collectible:TriggerTheresOptionsPickup()

                    -- Spawning an effect and playing some sounds
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, closest_collectible.Position, Vector.Zero, nil):GetSprite().Color:SetTint(97/255, 82/255, 98/255, 1)
                    ---@diagnostic disable-next-line: param-type-mismatch
                    SFX:Play(913, 1, 2, false, 1, 0)

                    -- Try to apply the quality upgrade
                    TryApplyQualityUpgrade()
                end

            -- Seems like we are holding a collectible
            else
                -- Get the item we are holding, which is an ItemConfigItem
                local item = player.QueuedItem.Item
                -- Try to add the wisp
                TryAddItemWisp(item)

                -- Get the item's quality and set our stored quality to it
                local quality = item.Quality
                desc.VarData = quality

                -- Remove the item we were holding
                player:ClearQueueItem()

                -- Spawning an effect and playing some sounds
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector.Zero, nil):GetSprite().Color:SetTint(97/255, 82/255, 98/255, 1)
                ---@diagnostic disable-next-line: param-type-mismatch
                SFX:Play(913, 1, 2, false, 1, 0)

                -- Try to apply the quality upgrade
                TryApplyQualityUpgrade()
            end



        --? So, we do need to affect every item in the room
        else
            -- Variable stores the highest quality so far, -1 means there's no collectibles
            local highest_quality = -1
            -- Find every collectible in the room
            for _, collectible in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
                -- Turning it into a pickup for some additional checks
                local collectible_pickup = collectible:ToPickup()
                assert(collectible_pickup)
                -- Get the collectible's id and check if it's not an empty pedestal and if it's free
                local collectible_id = collectible.SubType
                if collectible_id ~= 0 and not collectible_pickup:IsShopItem() then
                    -- Check if the quality is higher than the highest one so far, if it is, update the highest one
                    local quality = ItemConfig:GetCollectible(collectible_id).Quality
                    if quality > highest_quality then highest_quality = quality end

                    -- Try to add the item wisp, again, we need the ItemConfigItem
                    TryAddItemWisp(ItemConfig:GetCollectible(collectible_id))

                    -- Destroy the collectible and spawn an effect
                    collectible:Remove()
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, collectible.Position, Vector.Zero, nil):GetSprite().Color:SetTint(97/255, 82/255, 98/255, 1)
                end
            end

            -- Also, if we have a collectible in our hands
            if not player:IsItemQueueEmpty() then
                -- Get the ItemConfigItem and try to add the wisp
                local item = player.QueuedItem.Item
                TryAddItemWisp(item)

                -- Get the quality and update the highest if needed
                local quality = item.Quality
                if quality > highest_quality then highest_quality = quality end

                -- Destroy the item with an effect
                player:ClearQueueItem()
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector.Zero, nil):GetSprite().Color:SetTint(97/255, 82/255, 98/255, 1)
            end

            -- Update our item's stored quality
            desc.VarData = highest_quality

            -- If we successfully updated our stored quality, play a sound and try to apply the upgrade
            if highest_quality > -1 then
                ---@diagnostic disable-next-line: param-type-mismatch
                SFX:Play(913, 1, 2, false, 1, 0)
                TryApplyQualityUpgrade()
            end
        end


    -- We do have a quality selected huh
    else
        -- Function to reroll the collectibles we need, to avoid copy-pasting
        local function RerollCollectible(collectible)
            -- Try to apply the quality upgrade and get the result
            local quality = TryApplyQualityUpgrade(false)
            -- Get the seed for RNG
            local seed = player:GetCollectibleRNG(ARAOI.CollectibleType.VOID_DIE):Next()
            -- Get the room's pool. If chaos mode is enabled, set it to null since we don't care about it
            local pool = ARAOI.RoomUtils:GetItemPool()
            if Config.CHAOS_MODE then pool = ItemPoolType.POOL_NULL end
            -- Get the collectible we are about to reroll into
            local reroll_item = ARAOI.ItemUtils.GetItemFromQuality(quality, seed, pool)
            -- Morph the collectible into the new one with an effect
            collectible:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, reroll_item, true)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, collectible.Position, Vector.Zero, nil)
        end

        -- If we don't need to affect all items in the room
        if Config.AFFECTS_ALL_ITEMS == false then
            -- Get the closest item, if we can reroll it we do
            local closest_collectible = ARAOI.PlayerUtils.GetClosestCollectible(player)
            if closest_collectible and closest_collectible:CanReroll() then
                RerollCollectible(closest_collectible)
            end

        -- If we do need to affect all items
        else
            -- For each collectible in the room, check if we can reroll it and it's not an empty pedestal, if so, reroll it
            for _, pickup in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
                local collectible = pickup:ToPickup()
                if collectible and collectible:CanReroll() and (collectible.SubType ~= 0) then
                    RerollCollectible(collectible)
                end
            end
        end

        -- Playing some sounds
        ---@diagnostic disable-next-line: param-type-mismatch
        SFX:Play(910, 1.5, nil, nil, 0.8) -- D6 sound
        ---@diagnostic disable-next-line: param-type-mismatch
        SFX:Play(913, 0.8, 2, false, 0.6)

        -- If Permanent Quality is not enabled, we get rid of the stored quality
        if Config.PERMANENT_QUALITY == false then
            desc.VarData = -1
        end
    end

    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnVoidDieUse, ARAOI.CollectibleType.VOID_DIE)



-------------------
-- ITEM RENDERER --
-------------------

---@param player EntityPlayer
---@param slot ActiveSlot
function ARAOI:_PreVoidDieActiveItemRender(player, slot)
    -- Get the desc for the var data
    local desc = player:GetActiveItemDesc(slot)

    -- Each quality number moves the cropped section to the right
    local crop_offset = Vector(32, 0) * (desc.VarData + 1)
    return {["CropOffset"] = crop_offset}
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, ARAOI._PreVoidDieActiveItemRender, ARAOI.CollectibleType.VOID_DIE)



----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    if Config.AFFECTS_ALL_ITEMS == false then
        EID:addCollectible(ARAOI.CollectibleType.VOID_DIE,
            "# Stores the quality of the closest item to Isaac and destroys it"..
            "# If there is a quality stored, rerolls the closest item to Isaac into an item of the stored quality"
        )
    else
        EID:addCollectible(ARAOI.CollectibleType.VOID_DIE,
            "# Destroys all pedestals and stores the highest quality among them"..
            "# If there is a quality stored, rerolls all items into the stored quality"
        )
    end

    ARAOI.EIDUtils.CarBatterySynergy(
        "Void Die Car Battery Synergy",
        ARAOI.CollectibleType.VOID_DIE,
        Config.CAR_BATTERY_CHANCE .. "% chance to upgrade the quality when storing and rerolling items"
    )
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "Void Die Book Of Virtues Synergy",
        ARAOI.CollectibleType.VOID_DIE,
        "Spawns the wisp of the destroyed item"
    )
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.VOID_DIE, "1 locust (1x Isaac's damage)")
end)

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Actives", "Void Die")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Void Die", Config, "PERMANENT_QUALITY",
    ConfigDefaults, function ()
        return "Permanent Quality: "
    end, "Should the stored quality be permanent?")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Void Die", Config, "AFFECTS_ALL_ITEMS",
    ConfigDefaults, function ()
        return "Affects All Items: "
    end, "Should we affect all items?", "Stores the highest quality and rerolls all items into that quality")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Void Die", Config, "CHAOS_MODE",
    ConfigDefaults, function ()
        return "Chaos Mode: "
    end, "Reroll into any pool?")

    ModConfigMenu.AddSpace("ARAOI", "Actives")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Void Die", Config, "CAR_BATTERY_CHANCE",
    ConfigDefaults, ConfigDefaults.CAR_BATTERY_CHANCE, 0, 100, 10, function ()
        return "Car Battery Upgrade Chance: " .. Config.CAR_BATTERY_CHANCE .. "%"
    end, "Chance of the Car Battery synergy to take effect")

    ARAOI.MCMUtils.AddReset("Actives", "Void Die")
end