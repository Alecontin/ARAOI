local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.STAT_BOOST_PER_WISP = 10 -- *Default: `10` — Percentage of the stat boost provided per wisp.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Solved_Rubiks_Cube = {}
ARAOI.Solved_Rubiks_Cube.Config = Config

ARAOI.TrinketType.SOLVED_RUBIKS_CUBE = Isaac.GetTrinketIdByName("Solved Rubik's Cube")


--------------
-- STATS UP --
--------------

---@param player EntityPlayer
---@param cacheFlag CacheFlag
function ARAOI:_OnSolvedRubiksCubeEvaluateCache(player, cacheFlag)
    -- Don't do any of this if the player doesn't have the trinket
    if not player:HasTrinket(ARAOI.TrinketType.SOLVED_RUBIKS_CUBE) then return end

    -- Multiplier to the base effect, based on how many copies you have, if the trinket is golden, if you have mom's box, etc.
    local effect_multiplier = player:GetTrinketMultiplier(ARAOI.TrinketType.SOLVED_RUBIKS_CUBE)
    effect_multiplier = effect_multiplier * (1 + #ARAOI.PlayerUtils.GetWisps(player, ARAOI.CollectibleType.RUBIKS_CUBE) * (Config.STAT_BOOST_PER_WISP / 100))

    -- I'm not commenting all this
    if cacheFlag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.20 * effect_multiplier * player:GetD8SpeedModifier()
    end
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        ARAOI.PlayerUtils.AddFireDelay(player, (-1 * effect_multiplier * ARAOI.PlayerUtils.GetAproxTearRateMultiplier(player)))
    end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + 1.5 * effect_multiplier * ARAOI.PlayerUtils.GetAproxDamageMultiplier(player)
    end
    if cacheFlag == CacheFlag.CACHE_RANGE then
        ARAOI.PlayerUtils.AddTearRange(player, 1.5 * effect_multiplier * player:GetD8RangeModifier())
    end
    if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
        player.ShotSpeed = player.ShotSpeed + 0.2 * effect_multiplier
    end
    if cacheFlag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + 3 * effect_multiplier
    end
end
ARAOI:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, ARAOI._OnSolvedRubiksCubeEvaluateCache)

ARAOI.EIDWrapper(function ()
    EID:addTrinket(ARAOI.TrinketType.SOLVED_RUBIKS_CUBE,
        "#{{ArrowUp}} All stats up"
    )
    EID:addGoldenTrinketMetadata(ARAOI.TrinketType.SOLVED_RUBIKS_CUBE, {"Effect doubled", "Effect tripled"})
end)

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Trinkets", "Solved Rubik's Cube")

    ARAOI.MCMUtils.AddNumberSetting("Trinkets", "Solved Rubik's Cube", Config, "STAT_BOOST_PER_WISP",
    ConfigDefaults, ConfigDefaults.STAT_BOOST_PER_WISP .. "%", 0, 10000, 20, function ()
        return "Stat Boost Per Wisp: " .. Config.STAT_BOOST_PER_WISP .. "%"
    end, "The percentage of the stat boost provided per wisp")

    ARAOI.MCMUtils.AddReset("Trinkets", "Solved Rubik's Cube")
end