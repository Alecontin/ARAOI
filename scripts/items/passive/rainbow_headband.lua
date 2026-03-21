local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.TIME_MODIFIER = 0 -- *Default: `0` — Time added, in seconds, when calculating the amount of time you had this item for.*

Config.INCREASE_TRAIL_SIZE_EVERY = 25 -- *Default: `25` — Time it takes, in seconds, for the trail to get longer.*
Config.INCREASE_TRAIL_TIMEOUT_BY = 3  -- *Default: `3` — Time added every `INCREASE_TRAIL_SIZE_EVERY`, in frames, that it takes the trail to be removed.*

Config.CREEP_COLOR_INTERVAL_PERCENTAGE = 100 -- *Default: `100` — Percentage of the speed at which the creep changes color, higher values means the creep will switch colors quicker.*

Config.INSTANTLY_REMOVE_CREEP = true -- *Default: `true` — Should the creep be instantly removed? The animation of the creep disappearing does not do damage to enemies.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Rainbow_Headband = {}
ARAOI.Rainbow_Headband.Config = Config

local HEADBAND_CREEP_DATA_KEY = "IsRainbowHeadbandCreep"
local ONE_SECOND = 60 -- Frames


---------------
-- FUNCTIONS --
---------------

-- Gets the frame at which the player picked up the item, returns `-1` if the player hasn't picked up the item yet
--
-- If `set` is provided, it will change the stored timestamp to the provided value
---@param player any
---@param set? integer
---@return integer
function ARAOI.Rainbow_Headband.PickedUpTimestamp(player, set)
    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "RainbowHeadbandPickupTimestamp", {}, ARAOI.PlayerUtils.GetId(player), -1, set)
end

-- Calculates the creep timeout, after which it will disappear
---@param player EntityPlayer
---@return integer
function ARAOI.Rainbow_Headband.GetCreepTimeout(player)
    local time = (Game():GetFrameCount() - ARAOI.Rainbow_Headband.PickedUpTimestamp(player) )+ (ONE_SECOND * Config.TIME_MODIFIER)
    local timeout = math.ceil(time / (ONE_SECOND * Config.INCREASE_TRAIL_SIZE_EVERY)) * Config.INCREASE_TRAIL_TIMEOUT_BY
    return timeout
end

local function getRGB()
    -- Get the HUE for the current frame, then add the CREEP_COLOR_INTERVAL_MULTIPLIER to it
    local hue = Game():GetFrameCount() % 360
    hue = hue * (Config.CREEP_COLOR_INTERVAL_PERCENTAGE/100)

    -- Turn the HUE into RGB format, we achieve that by using the Hue Saturation Lightness to RGB converter, only using the HUE parameter
    local red, green, blue = ARAOI.MiscUtils.HSLtoRGB(hue)

    return red/255, green/255, blue/255
end

---@param player EntityPlayer
local function spawnCreep(player)
    -- Spawn the creep, the HOLYWATER_TRAIL is the only one that can have it's color consistently changed
    ---@type EntityEffect
    ---@diagnostic disable-next-line: assign-type-mismatch
    local creep = player:SpawnAquariusCreep()

    -- Set the creep's timeout, which increases by INCREASE_TRAIL_TIMEOUT_BY every INCREASE_TRAIL_SIZE_EVERY seconds
    local creep_timeout = ARAOI.Rainbow_Headband.GetCreepTimeout(player)
    creep:SetTimeout(creep_timeout)

    -- Set the creep's tint to the RGB values
    creep:GetColor():SetOffset(getRGB())

    -- We should only affect rendering for this item's creep, so we store some data for later
    local data = creep:GetData()
    data[HEADBAND_CREEP_DATA_KEY] = true

    -- Return the creep for later use
    return creep
end


--------------------
-- MISC FUNCTIONS --
--------------------

---@param player EntityPlayer
function ARAOI:_OnRainbowHeadbandPreAddCollectible(_,_,_,_,_,player)
    local game = Game()

    -- Store the time when the player picked up the item if it's the first time modifying the value
    if ARAOI.Rainbow_Headband.PickedUpTimestamp() == -1 then
        ARAOI.Rainbow_Headband.PickedUpTimestamp(player, game:GetFrameCount())
    end
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, ARAOI._OnRainbowHeadbandPreAddCollectible, ARAOI.CollectibleType.RAINBOW_HEADBAND)

---@param locust EntityFamiliar
function ARAOI:_OnRainbowHeadbandFamiliarInit(locust)
    local game = Game()

    -- Store the time when the player got the locust if it's the first time modifying the value
    if locust.SubType == ARAOI.CollectibleType.RAINBOW_HEADBAND then
        if ARAOI.Rainbow_Headband.PickedUpTimestamp() == -1 then
            ARAOI.Rainbow_Headband.PickedUpTimestamp(locust.SpawnerEntity:ToPlayer(), game:GetFrameCount())
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, ARAOI._OnRainbowHeadbandFamiliarInit, FamiliarVariant.ABYSS_LOCUST)


--------------------
-- CREEP RENDERER --
--------------------

function ARAOI:_OnRainbowHeadbandUpdate()
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- Render creep for every player that is holding the item
        if player:HasCollectible(ARAOI.CollectibleType.RAINBOW_HEADBAND) then
            spawnCreep(player)
        end

        -- Change locust colors if players have them
        local locusts = ARAOI.PlayerUtils.GetLocusts(player, ARAOI.CollectibleType.RAINBOW_HEADBAND)
        if locusts then
            for _, locust in ipairs(locusts) do
                -- Get the RGB values
                local r, g, b = getRGB()

                -- Change the locust's sprite tint
                locust:GetSprite().Color:SetTint(r, g, b, 1)

                -- Spawn the rainbow creep for the player
                local creep = spawnCreep(player)

                -- Change the creep's position to the locusts position
                creep.Position = locust.Position

                -- Scale down the creep
                creep:GetSprite().Scale = Vector(0.5, 0.5)
            end
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnRainbowHeadbandUpdate)

function ARAOI:_OnRainbowHeadbandEffectUpdate(effect)
    -- Get the effect's data
    local data = effect:GetData()

    -- Is the effect our creep?
    if data[HEADBAND_CREEP_DATA_KEY] then
        -- Remove the creep if the timeout was reached
        if effect.Timeout <= 0 and Config.INSTANTLY_REMOVE_CREEP then
            effect:Remove()
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, ARAOI._OnRainbowHeadbandEffectUpdate)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.RAINBOW_HEADBAND,
        "# Isaac leaves a trail of rainbow creep"..
        "#{{Damage}} The creep deals 66% of Isaac's damage per tick and inherits his tear effects"..
        "#{{Timer}} The trail gets longer by "..Config.INCREASE_TRAIL_TIMEOUT_BY.." frames every "..Config.INCREASE_TRAIL_SIZE_EVERY.." seconds"
    )
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.RAINBOW_HEADBAND, "1 locust, leaves creep (1x Isaac's Damage)")
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Passives", "Rainbow Headband")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Rainbow Headband", Config, "TIME_MODIFIER",
    ConfigDefaults, ConfigDefaults.TIME_MODIFIER .. "s", 0, 1000000, 60, function ()
        return "Time Modifier: " .. Config.TIME_MODIFIER .. "s"
    end, "Time added when calculating the amount of time Isaac had this item for")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Rainbow Headband", Config, "INCREASE_TRAIL_SIZE_EVERY",
    ConfigDefaults, ConfigDefaults.INCREASE_TRAIL_SIZE_EVERY .. "s", 1, 1000000, 60, function ()
        return "Increase Trail Size Every: " .. Config.INCREASE_TRAIL_SIZE_EVERY .. "s"
    end, "Time it takes for the trail to get longer")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Rainbow Headband", Config, "INCREASE_TRAIL_TIMEOUT_BY",
    ConfigDefaults, ConfigDefaults.INCREASE_TRAIL_TIMEOUT_BY .. " frames", 1, 1000000, 30, function ()
        return "Increase Trail Timeout By: " .. Config.INCREASE_TRAIL_TIMEOUT_BY .. " frames"
    end, "Frames added to the trail's timeout every time it gets longer")

    ModConfigMenu.AddSpace("ARAOI", "Passives")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Rainbow Headband", Config, "CREEP_COLOR_INTERVAL_PERCENTAGE",
    ConfigDefaults, ConfigDefaults.CREEP_COLOR_INTERVAL_PERCENTAGE .. "%", 1, 10000, 20, function ()
        return "Creep Color Interval Speed: " .. Config.CREEP_COLOR_INTERVAL_PERCENTAGE .. "%"
    end, "Speed at which the creep changes color, higher values means the creep will switch colors quicker")

    ARAOI.MCMUtils.AddBooleanSetting("Passives", "Rainbow Headband", Config, "INSTANTLY_REMOVE_CREEP", ConfigDefaults, function ()
        return "Instantly Remove Creep: "
    end, "Should the creep be instantly removed? The animation of the creep disappearing does not do damage to enemies")

    ARAOI.MCMUtils.AddReset("Passives", "Rainbow Headband")
end