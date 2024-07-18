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



---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")


local RAINBOW_HEADBAND = Isaac.GetItemIdByName("Rainbow Headband")

local oneSecond = 60 -- Frames


local function rainbowHeadbandPickedUp(player, set)
    return SaveData:Data(SaveData.RUN, "Rainbow Headband", {}, Helper.GetPlayerId(player), 0, set)
end


local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    local function onItemPickup(_,_,_,_,_,_,player)
        -- Store the time when the player picked up the item
        rainbowHeadbandPickedUp(player, game:GetFrameCount())
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, onItemPickup, RAINBOW_HEADBAND)

    -- Helper function for getting the creep timeout
    ---@param player EntityPlayer
    local function getCreepTimeout(player)
        -- Get the time elapsed since the item was picked up, then add the time modifier
        local time = (game:GetFrameCount() - rainbowHeadbandPickedUp(player) )+ (oneSecond * TIME_MODIFIER)

        -- Return the creep's timeout, which increases by INCREASE_TRAIL_TIMEOUT_BY every INCREASE_TRAIL_SIZE_EVERY seconds
        local timeout = math.ceil(time / (oneSecond * INCREASE_TRAIL_SIZE_EVERY)) * INCREASE_TRAIL_TIMEOUT_BY
        return timeout
    end


    --------------------
    -- CREEP RENDERER --
    --------------------

    local function onUpdate()
        -- Render creep for every player that is holding the item
        for _, player in ipairs(Helper.GetPlayersWithCollectible(RAINBOW_HEADBAND)) do
            -- Spawn the creep, the HOLYWATER_TRAIL is the only one that can have it's color consistently changed
            ---@type EntityEffect
            ---@diagnostic disable-next-line: undefined-field
            local creep = player:SpawnAquariusCreep():ToEffect()

            -- Set the creep's timeout, which increases by INCREASE_TRAIL_TIMEOUT_BY every INCREASE_TRAIL_SIZE_EVERY seconds
            local creepTimeout = getCreepTimeout(player)
            creep:SetTimeout(creepTimeout)

            -- Get the HUE for the current frame, then add the CREEP_COLOR_INTERVAL_MULTIPLIER to it
            local HUE = game:GetFrameCount() % 360
            HUE = HUE * CREEP_COLOR_INTERVAL_MULTIPLIER

            -- Turn the HUE into RGB format, we achieve that by using the Hue Saturation Lightness to RGB converter, only using the HUE parameter
            local R,G,B = Helper.HSLtoRGB(HUE)

            -- Set the creep's tint to the new RGB values
            creep:GetColor():SetOffset(R/255,G/255,B/255)

            -- We should only affect rendering for this item's creep, so we store some data for later
            local data = creep:GetData()
            data["Is Shooting Star Creep"] = true
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
                    if data["Is Shooting Star Creep"] then
                        -- Remove the creep if the timeout was reached
                        if effect.Timeout <= 0 and INSTANTLY_REMOVE_CREEP then
                            effect:Remove()
                        end
                    end
                end
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onUpdate)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then
        EID:addCollectible(RAINBOW_HEADBAND,
            "# Isaac leaves a trail of rainbow creep"..
            "#{{Damage}} The creep deals 66% of Isaac's damage per tick and inherits his tear effects"..
            "#{{Timer}} The trail gets longer by "..INCREASE_TRAIL_TIMEOUT_BY.." every "..INCREASE_TRAIL_SIZE_EVERY.." seconds"
        )
    end
end

return modded_item