local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.ITEM_SPEED           = 70    -- *Default: `70` — The player's speed when set by the item. This value will be divided by 100.*
Config.SPEED_ADDED_PER_TICK = 10    -- *Default: `1` — The amount added to the player's speed. This value will be divided by 1000.*
Config.TICK_EVERY           = 150   -- *Default: `150` — The amount of frames it takes the item to add the speed.*
Config.PLAY_HEARTBEAT_SOUND = true  -- *Default: `true` — Should the item play a heartbeat sound when approaching deadly speed levels?*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Soda = {}
ARAOI.Soda.Config = Config

local SFX = SFXManager()

local DamageMultiplayerCache = {}


---------------
-- FUNCTIONS --
---------------

local function ItemSpeed()
    return Config.ITEM_SPEED / 100
end

local function SpeedAddedPerTick()
    return Config.SPEED_ADDED_PER_TICK / 1000
end

local function TickEvery()
    return Config.TICK_EVERY
end

---@param player EntityPlayer
---@param set? number
local function DamageMultiplier(player, set)
    if set then
        DamageMultiplayerCache[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return DamageMultiplayerCache[ARAOI.PlayerUtils.GetId(player)] or 1
end

---@param player EntityPlayer
---@return number
function ARAOI.Soda.GetSpeed(player)
    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SodaPlayerSpeed", {}, ARAOI.PlayerUtils.GetId(player), Config.ITEM_SPEED/100)
end

---@param player EntityPlayer
---@param set? number
---@return number
function ARAOI.Soda.SetSpeed(player, set)
    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SodaPlayerSpeed", {}, ARAOI.PlayerUtils.GetId(player), Config.ITEM_SPEED/100, set)
end

---@param player EntityPlayer
---@param add? number
function ARAOI.Soda.AddSpeed(player, add)
    return ARAOI.Soda.SetSpeed(player, (ARAOI.Soda.GetSpeed(player) or 0) + add)
end

---@param player EntityPlayer
local function AddCacheFlags(player)
    player:AddCacheFlags(CacheFlag.CACHE_SPEED)
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    player:EvaluateItems()
end


------------------------
-- ITEM FUNCTIONALITY --
------------------------

function ARAOI:_OnSodaUse(_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

    ARAOI.Soda.SetSpeed(player, ItemSpeed())

    if not player:HasCollectible(ARAOI.CollectibleType.SODA_PASSIVE) then
        player:AddCollectible(ARAOI.CollectibleType.SODA_PASSIVE)
    end

    player:RemoveCollectible(ARAOI.CollectibleType.SODA)

    SFX:Play(Isaac.GetSoundIdByName("glass_bottle_open_sound"), 2)

    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnSodaUse, ARAOI.CollectibleType.SODA)


-- function ARAOI:_OnSodaNewRoom()
--     local room = Game():GetRoom()
--     if room:IsFirstVisit() then
--         for _, player in ipairs(ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.SODA_PASSIVE)) do
--             ARAOI.Soda.AddSpeed(player, Config.SPEED_ADDED_PER_TICK/1000)
--         end
--     end
-- end
-- ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnSodaNewRoom)


-- Updates the player's stats
---@param player EntityPlayer
---@param flag CacheFlag
function ARAOI:_OnSodaEvaluateCache(player, flag)
    if not player:HasCollectible(ARAOI.CollectibleType.SODA_PASSIVE) then return end

    if flag == CacheFlag.CACHE_SPEED then
        DamageMultiplier(player, player.MoveSpeed)
        player.MoveSpeed = ARAOI.Soda.GetSpeed(player) or player.MoveSpeed
    end

    if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * DamageMultiplier(player)
    end
end
ARAOI:AddPriorityCallback(ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.LATE, ARAOI._OnSodaEvaluateCache)

-- Responsible for sending a signal to update the player's stats and killing the player
---@param player EntityPlayer
function ARAOI:_OnSodaPEffectUpdate(player)
    if player:HasCollectible(ARAOI.CollectibleType.SODA_PASSIVE) then
        AddCacheFlags(player)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, ARAOI._OnSodaPEffectUpdate)

-- Heartbeat sound effects when approaching speed limit
function ARAOI:_OnSodaUpdate()
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.SODA_PASSIVE) then return end

    local frame = Game():GetFrameCount()

    local highest_speed = 0
    for _, player in ipairs(ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.SODA_PASSIVE)) do
        if frame % TickEvery() == 0 then
            ARAOI.Soda.AddSpeed(player, SpeedAddedPerTick())
        end

        local speed = player.MoveSpeed
        if speed >= 2 then
            player:Kill()
            player:RemoveCollectible(ARAOI.CollectibleType.SODA_PASSIVE)
        elseif speed > highest_speed then
            highest_speed = speed
        end
    end

    if Config.PLAY_HEARTBEAT_SOUND == true then
        if highest_speed >= 1.97 then
            if frame % 12 == 0 then
                SFX:Play(SoundEffect.SOUND_HEARTBEAT_FASTER)
            end
        elseif highest_speed >= 1.93 then
            if frame % 17 == 0 then
                SFX:Play(SoundEffect.SOUND_HEARTBEAT_FASTER)
            end
        elseif highest_speed >= 1.87 then
            if frame % 27 == 0 then
                SFX:Play(SoundEffect.SOUND_HEARTBEAT)
            end
        elseif highest_speed >= 1.80 then
            if frame % 45 == 0 then
                SFX:Play(SoundEffect.SOUND_HEARTBEAT)
            end
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnSodaUpdate)

ARAOI.EIDWrapper(function ()
    local description =
    "#{{Speed}} Sets Isaac's speed to "..(Config.ITEM_SPEED/100)..
    "#{{ArrowUp}} +".. SpeedAddedPerTick() .." Speed every ".. math.ceil(TickEvery()/30) .."s"..
    "#{{ArrowUp}} Speed Ups get converted to equivalent Damage Multipliers"..
    "#{{DeathMark}} Isaac dies when reaching max speed, which happens after ~".. math.floor((((2 - ItemSpeed()) * TickEvery()) / (SpeedAddedPerTick() * 30)) / 60) .. " minutes"


    EID:addCollectible(ARAOI.CollectibleType.SODA,
        "!!! SINGLE USE !!!"..description
    )
    EID:addCollectible(ARAOI.CollectibleType.SODA_PASSIVE,
        description
    )
end)

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Actives", "Soda")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Soda", Config, "ITEM_SPEED", ConfigDefaults, ConfigDefaults.ITEM_SPEED / 100, 10, 200, 20, function ()
        return "Item Speed: " .. ItemSpeed()
    end, "The player's speed when set by the item")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Soda", Config, "SPEED_ADDED_PER_TICK", ConfigDefaults, ConfigDefaults.SPEED_ADDED_PER_TICK / 1000, 0, 2000, 10, function ()
        return "Speed Added: " .. SpeedAddedPerTick()
    end, "The amount added to the player's speed")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Soda", Config, "TICK_EVERY", ConfigDefaults, ConfigDefaults.TICK_EVERY, 0, 2000, 30, function ()
        return "Add Every: " .. TickEvery() .. " frames"
    end, "The amount of frames it takes the item to add the speed")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Soda", Config, "PLAY_HEARTBEAT_SOUND", ConfigDefaults, function ()
        return "Play Heartbeat Sound: "
    end, "Should the item play a heartbeat sound when approaching deadly speed levels?")

    ARAOI.MCMUtils.AddReset("Actives", "Soda")
end

