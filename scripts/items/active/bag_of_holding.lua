-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------





---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")



---------------
-- CONSTANTS --
---------------

local BAG_OF_HOLDING = Isaac.GetItemIdByName("Bag of Holding")

local BAG_OF_HOLDING_SPRITE = Sprite("gfx/ui/hud_bag_of_holding.anm2")
BAG_OF_HOLDING_SPRITE:SetOverlayRenderPriority(true)
BAG_OF_HOLDING_SPRITE:SetAnimation(BAG_OF_HOLDING_SPRITE:GetDefaultAnimationName())
BAG_OF_HOLDING_SPRITE:SetFrame(1)

-- Single use items. Modded items do not need to be added as they trigger the RemoveCollectible function,
-- which will be detected automatically
---@type CollectibleType[]
local SINGLE_USE_ITEMS = {
    CollectibleType.COLLECTIBLE_FORGET_ME_NOW,
    CollectibleType.COLLECTIBLE_BLUE_BOX,
    CollectibleType.COLLECTIBLE_DIPLOPIA,
    CollectibleType.COLLECTIBLE_EDENS_SOUL,
    CollectibleType.COLLECTIBLE_MAMA_MEGA, --
    CollectibleType.COLLECTIBLE_MYSTERY_GIFT,
    CollectibleType.COLLECTIBLE_PLAN_C,
    CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR,
    CollectibleType.COLLECTIBLE_ALABASTER_BOX,
    CollectibleType.COLLECTIBLE_DAMOCLES,
    CollectibleType.COLLECTIBLE_DEATH_CERTIFICATE,
    CollectibleType.COLLECTIBLE_GENESIS,
    CollectibleType.COLLECTIBLE_R_KEY,

    -- Exploitable items:
    CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS
}



---------------
-- FUNCTIONS --
---------------

---@param player EntityPlayer
---@param add? integer
---@param removeInstead? boolean
---@return CollectibleType[]
local function bagOfHoldingStoredItems(player, add, removeInstead)
    local data = SaveData:Data(SaveData.RUN, "BagOfHoldingStoredItems", {}, helper.player.GetID(player), {})
    if add then
        if removeInstead == true then
            local index = helper.table.FindFirstInstanceInTable(add, data)
            if index > 0 then
                table.remove(data, index)
            end
        else
            table.insert(data, add)
        end

        SaveData:Data(SaveData.RUN, "BagOfHoldingStoredItems", {}, helper.player.GetID(player), {}, data)
    end
    return data
end

---@param player EntityPlayer
local function bagOfHoldingCycleItem(player)
    local slot = player:GetActiveItemSlot(BAG_OF_HOLDING)
    local desc = player:GetActiveItemDesc(slot)

    local stored_items = bagOfHoldingStoredItems(player)

    desc.VarData = (desc.VarData + 1) % (#stored_items + 1)

    return desc.VarData
end

---@param player EntityPlayer
---@return integer
local function bagOfHoldingGetSelectedItem(player)
    local slot = player:GetActiveItemSlot(BAG_OF_HOLDING)
    local desc = player:GetActiveItemDesc(slot)

    local stored_items = bagOfHoldingStoredItems(player)

    if stored_items[desc.VarData] == nil then
        desc.VarData = 0
    end

    return tonumber(stored_items[desc.VarData]) or 0
end

---@param player EntityPlayer
---@param set? number
local function bagOfHoldingLastItemUsed(player, set)
    return SaveData:Data(SaveData.RUN, "BagOfHoldingLastItemUse", {}, helper.player.GetID(player), BAG_OF_HOLDING, set)
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()
    local SFX = SFXManager()


    -----------------
    -- ITEM CHANGE --
    -----------------

    ---@param entity Entity
    ---@param inputHook InputHook
    ---@param buttonAction ButtonAction
    Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, inputHook, buttonAction)
        if not entity then return end

        local player = entity:ToPlayer()
        if not player then return end

        -- Only do stuff if the hook and action are what we are looking for
        if inputHook ~= InputHook.IS_ACTION_TRIGGERED or buttonAction ~= ButtonAction.ACTION_DROP then return end

        -- Only cycle if the player is holding the bag of crafting
        if (player:GetActiveItem() == BAG_OF_HOLDING or player:GetActiveItem(ActiveSlot.SLOT_POCKET) == BAG_OF_HOLDING)
        -- And if the player is pressing the drop key
        and Input.IsActionTriggered(buttonAction, player.ControllerIndex) then

            -- Cycle the object and get the current cycle index
            local cycle = bagOfHoldingCycleItem(player)

            -- If we returned to the start, do nothing
            -- We do this to trigger schoolbag and be able to change the selected card
            if cycle == 0 then
                return
            end

            -- This makes the game think we didn't press anything
            if inputHook == InputHook.GET_ACTION_VALUE then
                return 0
            else
                return false
            end
        end
    end)


    --------------
    -- ITEM USE --
    --------------

    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, useFlags)
        -- Don't do anything if it's a car battery use
        -- if we WERE to just ignore this, items would be used 4 times!
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

        -- Check if we have an item selected
        local selected = bagOfHoldingGetSelectedItem(player)

        -- We don't have an item selected
        if selected == 0 then
            -- Make the last item used be our item
            bagOfHoldingLastItemUsed(player, BAG_OF_HOLDING)

            local options_voided = {}

            -- Check every entity in the room
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                -- Is the entity a pickup
                local pickup = entity:ToPickup()

                -- Is the pickup a non-empty pedestal
                if pickup and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= 0 then

                    -- Check if we already voided an item from this option index, if so, we delete it
                    if helper.table.IsValueInTable(pickup.OptionsPickupIndex, options_voided) then
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pickup.Position, Vector.Zero, nil)
                        pickup:Remove()
                        goto continue
                    end

                    -- Make a reference to the subtype
                    local absorb_id = pickup.SubType

                    -- Get the absorbed item's config
                    local config = ItemConfig:GetCollectible(absorb_id)

                    -- Is the item an active, is the charge is not special, is not a quest item and is not for sale?
                    if config.Type == ItemType.ITEM_ACTIVE
                    and config.ChargeType ~= ChargeType.Special
                    and not config:HasTags(ItemTag.TAG_QUEST)
                    and not pickup:IsShopItem() then
                        -- If the item is part of an options index
                        if pickup.OptionsPickupIndex ~= 0 then
                            -- Add it to the list of voided options
                            table.insert(options_voided, pickup.OptionsPickupIndex)
                        end

                        -- If the item we are trying to absorb is another bag of holding, have a special interaction
                        if absorb_id == BAG_OF_HOLDING then
                            pickup:Remove()
                            player:RemoveCollectible(BAG_OF_HOLDING)
                            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DOGMA_BLACKHOLE, 0, player.Position, Vector.Zero, nil)

                            return true

                        -- Otherwise, just absorb it
                        else
                            -- Act as if the player picked up the item as if it was an option between various items
                            -- Thanks to Repentogon 1.0.11 😭
                            pickup:TriggerTheresOptionsPickup()

                            -- Remove the collectible from the pedestal, otherwise it would get "cloned"
                            pickup:TryRemoveCollectible()

                            -- Store the voided item
                            bagOfHoldingStoredItems(player, absorb_id)
                        end
                    end
                end
                ::continue::
            end



        -- We have an item selected
        else

            -- Is it in the list of single use items and our active item isn't being mimicked?
            if helper.table.IsValueInTable(selected, SINGLE_USE_ITEMS) and useFlags & UseFlag.USE_MIMIC == 0 then
                -- Is the selected item Mama Mega and do we have gold bombs?
                if selected == CollectibleType.COLLECTIBLE_MAMA_MEGA and player:HasGoldenBomb() then
                    -- Do nothing
                    -- This is because Mama Mega does not get used if you have Gold Bombs
                else
                    -- Proceed as normal
                    player:RemoveCollectible(selected)
                end
            end

            -- Use the active item as if it was owned by the player
            -- This for some reason does not spawn wisps, even after adding the corresponding flags
            player:UseActiveItem(selected)

            -- If we have book of virtues, we artificially spawn wisps
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                -- Spawn a wisp
                player:AddWisp(selected, player.Position)
                SFX:Play(SoundEffect.SOUND_CANDLE_LIGHT)
            end

            -- Store the last item used to set the new charges
            bagOfHoldingLastItemUsed(player, selected)

            return false
        end

        return true
    end, BAG_OF_HOLDING)


    ---------------------------------
    -- CHARGING AND REMOVING ITEMS --
    ---------------------------------

    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function (_, collectibleType, player, _)
        if collectibleType ~= BAG_OF_HOLDING then return end

        -- Get and return the last item's max charge
        local config = ItemConfig:GetCollectible(bagOfHoldingLastItemUsed(player))
        return config.MaxCharges
    end)

    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function (_, player, collectibleType)
        -- Don't do anything if we don't have our item equipped
        if player:GetActiveItem() ~= BAG_OF_HOLDING then return end

        -- If the player has the item in their inventory, don't trigger the removal from our item
        if player:HasCollectible(collectibleType) then return end

        -- Get all the stored items
        local stored_items = bagOfHoldingStoredItems(player)

        -- Check if the deleted item is among the stored items
        if helper.table.IsValueInTable(collectibleType, stored_items) then

            -- Remove the stored item
            bagOfHoldingStoredItems(player, collectibleType, true)
        end
    end)


    ---------------------------
    -- RENDERING OF THE ITEM --
    ---------------------------

    ---@param player EntityPlayer
    ---@param slot ActiveSlot
    ---@param offset Vector
    ---@param alpha number
    ---@param scale number
    Mod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_ACTIVE_ITEM, function (_, player, slot, offset, alpha, scale)-- Do not render if the game JUST started
        -- Don't render if the item is not ours
        local collectible_id = player:GetActiveItem(slot)
        if collectible_id ~= BAG_OF_HOLDING then return end

        -- Get the currently selected item
        local selected_item = bagOfHoldingGetSelectedItem(player)

        -- The selected item is 0, which means we don't need to do anything
        if selected_item == 0 then return end

        -- Setting some render options to be the same as what the game wants
        BAG_OF_HOLDING_SPRITE.Scale = Vector(scale, scale)
        BAG_OF_HOLDING_SPRITE.Color.A = alpha

        -- Get the config of the newly selected item
        local selected_config = ItemConfig:GetCollectible(selected_item)

        -- Replace the spritesheet and load the graphics
        BAG_OF_HOLDING_SPRITE:ReplaceSpritesheet(1, selected_config.GfxFileName)
        BAG_OF_HOLDING_SPRITE:LoadGraphics()

        -- Render the sprite to the screen
        BAG_OF_HOLDING_SPRITE:Render(offset)
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(BAG_OF_HOLDING,
            "#{{Collectible"..CollectibleType.COLLECTIBLE_VOID.."}} Absorbs Active Items that don't have a special charge"..
            "#{{Collectible"..CollectibleType.COLLECTIBLE_RESTOCK.."}} Isaac can cycle between absorbed items with the drop button ({{ButtonRT}})"..
            "# Using Bag of Holding while an item is selected will use that item instead"..
            "#{{Battery}} Charge time varies depending on the last item used and updates with every use"
        )

        helper.eid.BookOfVirtuesSynergy("Bag Of Holding Book Of Virtues", BAG_OF_HOLDING, "Spawn a wisp as if the selected item was used")
    end
end


return modded_item