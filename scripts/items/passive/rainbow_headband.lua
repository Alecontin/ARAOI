----------------------------
-- START OF CONFIGURATION --
----------------------------



local TIME_MODIFIER = 0 -- *Default: `0` — Time added, in seconds, when calculating the amount of time you had this item for.*

local INCREASE_TRAIL_SIZE_EVERY = 25 -- *Default: `25` — Time it takes, in seconds, for the trail to get longer.*
local INCREASE_TRAIL_TIMEOUT_BY = 3  -- *Default: `3` — Time added every `INCREASE_TRAIL_SIZE_EVERY`, in frames, that it takes the trail to be removed.*

local CREEP_COLOR_INTERVAL_MULTIPLIER = 1 -- *Default: `1` — Multiplier for the color change of the creep, higher values means the creep will switch colors quicker.*

local INSTANTLY_REMOVE_CREEP = true -- *Default: `true` — Should the creep be instantly removed? The animation of the creep disappearing does not do damage to enemies.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")


---------------
-- CONSTANTS --
---------------

local RAINBOW_HEADBAND = Isaac.GetItemIdByName("Rainbow Headband")
local HEADBAND_CREEP_DATA_KEY = "IsRainbowHeadbandCreep"
local ONE_SECOND = 60 -- Frames


---------------
-- FUNCTIONS --
---------------

local function rainbowHeadbandPickedUp(player, set)
    return SaveData:Data(SaveData.RUN, "RainbowHeadbandPickupTimestamp", {}, helper.player.GetID(player), 0, set)
end

---@param player EntityPlayer
local function getCreepTimeout(player)
    local time = (Game():GetFrameCount() - rainbowHeadbandPickedUp(player) )+ (ONE_SECOND * TIME_MODIFIER)
    local timeout = math.ceil(time / (ONE_SECOND * INCREASE_TRAIL_SIZE_EVERY)) * INCREASE_TRAIL_TIMEOUT_BY
    return timeout
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()


    --------------------
    -- MISC FUNCTIONS --
    --------------------

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function (_,_,_,_,_,_,player)
        -- Store the time when the player picked up the item
        rainbowHeadbandPickedUp(player, game:GetFrameCount())
    end, RAINBOW_HEADBAND)


    --------------------
    -- CREEP RENDERER --
    --------------------

    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
        -- Render creep for every player that is holding the item
        for _, player in ipairs(helper.player.GetPlayersWithCollectible(RAINBOW_HEADBAND)) do
            -- Spawn the creep, the HOLYWATER_TRAIL is the only one that can have it's color consistently changed
            ---@type EntityEffect
            ---@diagnostic disable-next-line: undefined-field
            local creep = player:SpawnAquariusCreep():ToEffect()

            -- Set the creep's timeout, which increases by INCREASE_TRAIL_TIMEOUT_BY every INCREASE_TRAIL_SIZE_EVERY seconds
            local creep_timeout = getCreepTimeout(player)
            creep:SetTimeout(creep_timeout)

            -- Get the HUE for the current frame, then add the CREEP_COLOR_INTERVAL_MULTIPLIER to it
            local hue = game:GetFrameCount() % 360
            hue = hue * CREEP_COLOR_INTERVAL_MULTIPLIER

            -- Turn the HUE into RGB format, we achieve that by using the Hue Saturation Lightness to RGB converter, only using the HUE parameter
            local red, green, blue = helper.misc.HSLtoRGB(hue)

            -- Set the creep's tint to the new RGB values
            creep:GetColor():SetOffset(red/255, green/255, blue/255)

            -- We should only affect rendering for this item's creep, so we store some data for later
            local data = creep:GetData()
            data[HEADBAND_CREEP_DATA_KEY] = true
        end

        -- If any player has the collectible, that means creep is currently spawning
        if PlayerManager.AnyoneHasCollectible(RAINBOW_HEADBAND) then
            -- For every entity in the room
            for _,entity in ipairs(Isaac.GetRoomEntities()) do
                -- Check if the entity is an effect
                local effect = entity:ToEffect()
                if effect then
                    -- Get the effect's data
                    local data = effect:GetData()

                    -- Is the effect our creep?
                    if data[HEADBAND_CREEP_DATA_KEY] then
                        -- Remove the creep if the timeout was reached
                        if effect.Timeout <= 0 and INSTANTLY_REMOVE_CREEP then
                            effect:Remove()
                        end
                    end
                end
            end
        end
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(RAINBOW_HEADBAND,
            "# Isaac leaves a trail of rainbow creep"..
            "#{{Damage}} The creep deals 66% of Isaac's damage per tick and inherits his tear effects"..
            "#{{Timer}} The trail gets longer by "..INCREASE_TRAIL_TIMEOUT_BY.." every "..INCREASE_TRAIL_SIZE_EVERY.." seconds"
        )
    end
end

return modded_item