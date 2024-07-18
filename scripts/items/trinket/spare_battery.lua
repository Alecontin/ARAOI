
---@class Helper
local Helper = include("scripts.Helper")

-- Getting the trinket in question
local SPARE_BATTERY = Isaac.GetTrinketIdByName("Spare Battery")

local modded_item = {}

function modded_item:init(Mod)
    local game = Game()

    --------------------------------
    -- MAIN TRINKET FUNCTIONALITY --
    --------------------------------

    ---@param entity Entity
    local function onSpacebarPressed(_, entity, _, _)
        -- Noone pressed anything
        if not entity then return end

        -- Getting the player that pressed the active button
        local player = entity:ToPlayer()
        if not player then return end

        -- End the function prematurely if the player doesn't have the trinket
        if not player:HasTrinket(SPARE_BATTERY) then return end

        -- Check if the button pressed is actually the active button
        if not Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then return end

        -- Get the slot and the item_id of the active
        local slot = ActiveSlot.SLOT_PRIMARY
        local item_id = player:GetActiveItem(slot)

        -- If the player has no active item then we stop here
        if not item_id or item_id == CollectibleType.COLLECTIBLE_NULL then return end

        -- Encasing the functionality inside a function to use it in a timer
        -- this is because there's a lot of edge cases regarding sharp plug
        local function spawnBatteries()
            -- Get some charging information
            local min_charges = player:GetActiveMinUsableCharge(slot)
            local current_charge = player:GetTotalActiveCharge(ActiveSlot.SLOT_PRIMARY)

            -- Getting more charging information
            local config = Isaac.GetItemConfig()
            local item = config:GetCollectible(item_id)
            local charge_type = item.ChargeType

            -- We shouldn't spawn batteries for a item that can't use them
            if charge_type == ChargeType.Special then return end

            -- Same for an item that doesn't need them
            if current_charge >= min_charges then return end

            -- Check if the player is currently holding an item above their head
            -- This acts more like a debounce for the trinket more than anything
            if player:IsHoldingItem() then return end

            -- Getting the room so we can later find a free space to spawn the pickups
            local room = game:GetRoom()

            -- How many batteries should we spawn?
            local batteries = player:GetTrinketMultiplier(SPARE_BATTERY)

            -- For every battery that we need to spawn...
            for _ = 1, batteries do
                -- Spawn a battery
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_LIL_BATTERY,
                    BatterySubType.BATTERY_NORMAL,
                    room:FindFreePickupSpawnPosition(player.Position, 50, true, false),
                    Vector.Zero,
                    player
                ):ToPickup()
            end

            -- Lastly, show an animation and remove the trinket
            player:AnimateTrinket(SPARE_BATTERY, "UseItem") -- "UseItem" is a bit faster than default
            player:TryRemoveTrinket(SPARE_BATTERY)
        end

        -- Check for sharp plug
        if player:HasCollectible(CollectibleType.COLLECTIBLE_SHARP_PLUG) then
            Isaac.CreateTimer(spawnBatteries, 1, 1, false)

        -- No sharp plug, spawn the batteries immediately
        else
            spawnBatteries()
        end

    end
    Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, onSpacebarPressed)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then
        EID:addTrinket(SPARE_BATTERY,
            "#!!! SINGLE USE !!!"..
            "#Spawns 1 battery when you try to use an active item without enough charges"
        )
        EID:addGoldenTrinketMetadata(SPARE_BATTERY, {"Spawns 1 extra battery", "Spawns 2 extra batteries"})
    end
end

return modded_item