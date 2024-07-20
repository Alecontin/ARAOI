---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

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
    CollectibleType.COLLECTIBLE_R_KEY
}

local bag_of_holding = Isaac.GetItemIdByName("Bag of Holding")
local KEY_BOH_LAST_USE = "BagOfHoldingLastItemUse"
local KEY_BOH_RENDER_SPRITE = "BagOfHoldingSpriteHUD"
local KEY_BOH_LAST_SELECTION = "BagOfHoldingLastSelection"

---@param player EntityPlayer
---@param add? integer
---@param removeInstead? boolean
local function BagOfHoldingStoredItems(player, add, removeInstead)
    local data = SaveData:Data(SaveData.RUN, "BagOfHoldingStoredItems", {}, Helper.GetPlayerId(player), {})
    if add then
        if removeInstead == true then   
            local index = Helper.FindFirstInstanceInTable(add, data)
            if index > 0 then
                table.remove(data, index)
            end
        else
            table.insert(data, add)
        end
    end
    return SaveData:Data(SaveData.RUN, "BagOfHoldingStoredItems", {}, Helper.GetPlayerId(player), {}, data)
end

---@param player EntityPlayer
local function BagOfHoldingCycleItem(player)
    local slot = player:GetActiveItemSlot(bag_of_holding)
    local desc = player:GetActiveItemDesc(slot)

    local stored_items = BagOfHoldingStoredItems(player)

    desc.VarData = (desc.VarData + 1) % (#stored_items + 1)

    return desc.VarData
end

---@param player EntityPlayer
local function BagOfHoldingGetSelectedItem(player)
    local slot = player:GetActiveItemSlot(bag_of_holding)
    local desc = player:GetActiveItemDesc(slot)

    local stored_items = BagOfHoldingStoredItems(player)

    if stored_items[desc.VarData] == nil then
        desc.VarData = 0
    end

    return stored_items[desc.VarData] or 0
end

---@param player EntityPlayer
---@param set? number
local function BagOfHoldingLastItemUsed(player, set)
    return SaveData:Data(SaveData.RUN, "BagOfHoldingLastItemUse", {}, Helper.GetPlayerId(player), bag_of_holding, set)
end

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()
    local sfx = SFXManager()



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
        if (player:GetActiveItem() == bag_of_holding or player:GetActiveItem(ActiveSlot.SLOT_POCKET) == bag_of_holding)
        -- And if the player is pressing the drop key
        and Input.IsActionTriggered(buttonAction, player.ControllerIndex) then

            -- Cycle the object and get the current cycle index
            local cycle = BagOfHoldingCycleItem(player)

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

        local function Collapse()
            player:RemoveCollectible(bag_of_holding)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DOGMA_BLACKHOLE, 0, player.Position, Vector.Zero, nil)
        end

        -- Check if we have an item selected
        local selected = BagOfHoldingGetSelectedItem(player)

        -- We don't have an item selected
        if selected == 0 then
            -- Make the last item used be our item
            BagOfHoldingLastItemUsed(player, bag_of_holding)

            -- I couldn't find a way to boot the player out of
            -- death certificate upon absorbing an item so I had to make some sacrifices
            if game:GetLevel():GetDimension() == Dimension.DEATH_CERTIFICATE then
                Collapse()
                return true
            end

            -- Check every entity in the room
            for _, entity in ipairs(Isaac.GetRoomEntities()) do

                -- Is the entity a pickup
                local pickup = entity:ToPickup()

                -- Is the pickup a non-empty pedestal
                if pickup and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= 0 then

                    -- Make a reference to the subtype
                    local absorb_id = pickup.SubType

                    -- Get the absorbed item's config
                    local config = ItemConfig:GetCollectible(absorb_id)

                    -- Is the item an active, is the charge is not special, is not a quest item and is not for sale?
                    if config.Type == ItemType.ITEM_ACTIVE
                    and config.ChargeType ~= ChargeType.Special
                    and not config:HasTags(ItemTag.TAG_QUEST)
                    and not pickup:IsShopItem() then
                        -- Remove the collectible from the pedestal
                        pickup:TryRemoveCollectible()

                        -- If the item we are trying to absorb is another bag of holding, have a special interaction
                        if absorb_id == bag_of_holding then
                            pickup:Remove()
                            Collapse()

                        -- Otherwise, just absorb it
                        else
                            BagOfHoldingStoredItems(player, absorb_id)
                        end
                    end
                end
            end



        -- We have an item selected
        else

            -- Is it in the list of single use items and our active item isn't being mimicked?
            if Helper.IsValueInTable(selected, SINGLE_USE_ITEMS) and useFlags & UseFlag.USE_MIMIC == 0 then
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
            player:UseActiveItem(selected, UseFlag.USE_OWNED | UseFlag.USE_ALLOWWISPSPAWN)

            -- If we have book of virtues
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                -- For some reason wisps don't get spawned, so we do that artificially
                player:AddWisp(selected, player.Position)
                sfx:Play(SoundEffect.SOUND_CANDLE_LIGHT)
            end

            -- Store the last item to use it for the new charges
            BagOfHoldingLastItemUsed(player, selected)

            return false
        end

        return true
    end, bag_of_holding)



    ---------------------------------
    -- CHARGING AND REMOVING ITEMS --
    ---------------------------------

    ---@param collectibleType any
    ---@param player any
    Mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function (_, collectibleType, player, _)
        if collectibleType ~= bag_of_holding then return end

        -- Get and return the last item's max charge
        local config = ItemConfig:GetCollectible(BagOfHoldingLastItemUsed(player))
        return config.MaxCharges
    end)

    ---@param collectibleType any
    ---@param player any
    Mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function (_, player, collectibleType)
        -- Don't do anything if we don't have our item equipped
        if player:GetActiveItem() ~= bag_of_holding then return end

        -- Get all the stored items
        local stored_items = BagOfHoldingStoredItems(player)

        -- Check if the deleted item is among the stored items
        if Helper.IsValueInTable(collectibleType, stored_items) then

            -- Remove the stored item
            BagOfHoldingStoredItems(player, collectibleType, true)
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
    Mod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_ACTIVE_ITEM, function (_, player, slot, offset, alpha, scale)
        -- Don't render if the item is not ours
        local collectible_id = player:GetActiveItem(slot)
        if collectible_id ~= bag_of_holding then return end

        -- Get the currently selected item
        local selected_item = BagOfHoldingGetSelectedItem(player)

        -- The selected item is 0, which means we don't need to do anything
        if selected_item == 0 then return end

        -- Get a reference to the data
        local data = player:GetData()

        -- Keeping track of the render and the selected item
        -- That way we don't have to reload the sprite every render
        local hud_boh = data[KEY_BOH_RENDER_SPRITE]
        local last_boh_selection = data[KEY_BOH_LAST_SELECTION]

        -- First time rendering so we create the sprite
        if hud_boh == nil then
            hud_boh = Sprite("gfx/ui/hud_bag_of_holding.anm2", true)

            -- Make a reference to the sprite
            data[KEY_BOH_RENDER_SPRITE] = hud_boh

            -- Set some stuff to the defaults because for some reason the game doesn't do that
            hud_boh:SetOverlayRenderPriority(true)
            hud_boh:SetAnimation(hud_boh:GetDefaultAnimationName())
            hud_boh:SetFrame(1)
        end

        -- Setting some render options to be the same as what the game wants
        hud_boh.Scale = Vector(scale, scale)
        hud_boh.Color.A = alpha

        -- New item was selected
        if last_boh_selection ~= selected_item then

            -- Get the config of the newly selected item
            local selected_config = ItemConfig:GetCollectible(selected_item)

            -- Replace the spritesheet and load the graphics
            hud_boh:ReplaceSpritesheet(1, selected_config.GfxFileName)
            hud_boh:LoadGraphics()

            -- Store the selection
            player:GetData()[KEY_BOH_LAST_SELECTION] = selected_item
        end

        -- If the sprite is smaller we have to account for that
        local pos = Vector(16, 16) * scale

        -- Render the sprite to the screen
        hud_boh:Render(pos + offset)
    end)

    ---@class EID
    if EID then
        EID:addCollectible(bag_of_holding,
            "#{{Collectible"..CollectibleType.COLLECTIBLE_VOID.."}} Absorbs Active Items that don't have a special charge"..
            "#{{Collectible"..CollectibleType.COLLECTIBLE_RESTOCK.."}} Isaac can cycle between absorbed items with the drop button ({{ButtonRT}})"..
            "# Using Bag of Holding while an item is selected will use that item instead"..
            "#{{Battery}} Charge time varies depending on the last item used and updates with every use"
        )
    end
end


return modded_item