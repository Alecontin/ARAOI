-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------





---@type helper
local helper = include("scripts.helper")


---------------
-- CONSTANTS --
---------------

local WIRE_CUTTER = Isaac.GetItemIdByName("Wire Cutter")
local CUT_SOUND = Isaac.GetSoundIdByName("wire_cut")
local BREAK_SOUND = Isaac.GetSoundIdByName("tool_break")


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local SFX = SFXManager()
    local ItemConfig = Isaac.GetItemConfig()

    ----------------------
    -- ITEM MIN CHARGES --
    ----------------------

    Mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MIN_USABLE_CHARGE, function (_)
        return 1
    end, WIRE_CUTTER)


    ------------------------
    -- MAIN FUNCTIONALITY --
    ------------------------

    ---@param player EntityPlayer
    ---@param rng RNG
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, useFlags)
        -- Disabling car battery
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

        -- Getting the current room
        local room = game:GetRoom()

        -- Getting the max charges for later
        local max_charge = ItemConfig:GetCollectible(WIRE_CUTTER).MaxCharges

        -- Getting how many uses the item has left
        local uses = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY)

        -- Getting the pickups in the room, shuffled
        local pickups = helper.room.GetPickups()
        helper.table.ShuffleTable(pickups, rng)

        -- Function to avoid copy-pasting
        local function breakAndRemoveItem()
            -- Remove the item from the player
            player:RemoveCollectible(WIRE_CUTTER)

            -- Play a sound to notify the player
            SFX:Play(BREAK_SOUND, 2)
        end

        -- What happens when the item is used by The Lost inside a Devil Deal / Black Market
        local function makeEverythingFreeAndBreak()
            -- Go through every pickup
            for _, pickup in ipairs(pickups) do
                -- Set the option to 0
                pickup.OptionsPickupIndex = 0

                -- Make it free
                pickup.Price = 0
            end

            -- Remove the item
            breakAndRemoveItem()

            -- Play the item animation
            return true
        end

        -- Go through every pickup
        for _, pickup in ipairs(pickups) do
            -- If the player that used the item is The Lost
            -- and we are in a Devil Deal, Black Market or in the dark room
            -- and there are pickups that cost hearts
            if helper.player.IsLost(player)
            and (helper.table.IsValueInTable(room:GetType(), {RoomType.ROOM_DEVIL, RoomType.ROOM_BLACK_MARKET}) or game:GetLevel():GetStage() == LevelStage.STAGE6)
            and pickup.Price < 0 then
                -- Return this function, which handles this situation
                return makeEverythingFreeAndBreak()
            end

            -- If we still have uses left
            if uses > 0 and pickup.OptionsPickupIndex > 0 then
                -- Decrease the uses left by 1
                uses = uses - 1

                -- Set the pickup's option to 0
                pickup.OptionsPickupIndex = 0

                -- Spawn 3 gibs at the pickup's position
                for _ = 1, 3 do
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, pickup.Position, Vector(math.random(-3, 3),math.random(-3, 3)), nil)
                end
            end
        end

        -- If we don't have any uses left
        if uses <= 0 then
            -- Remove the item
            breakAndRemoveItem()

        else
            -- Custom item discharge, which sets the item's charge to the max charge + the uses left
            -- then, when the item gets discharged, it will get rid of the max charge and leave the uses
            player:SetActiveCharge(max_charge + uses, ActiveSlot.SLOT_PRIMARY)

            -- Play a sound
            SFX:Play(CUT_SOUND, 2)
        end

        -- Play the item animation
        return true
    end, WIRE_CUTTER)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(WIRE_CUTTER,
            "# Allows Isaac to collect all pickups instead of choosing between them"..
            "#{{Battery}} Each pickup consumes 1 charge"..
            "#!!! Can't be recharged !!!"
        )

        helper.eid.PlayerBasedModifier(
            "Wire Cutter The Lost Description",
            WIRE_CUTTER,
            {PlayerType.PLAYER_THELOST, PlayerType.PLAYER_THELOST_B},
            PlayerType.PLAYER_THELOST,
            "When used within a {{DevilRoom}} Devil Deal or Black Market, consumes all charges and makes all items free"
        )
    end
end


return modded_item