
----------------------------
-- START OF CONFIGURATION --
----------------------------



local SOLVE_CHANCE = 10 -- *Default: `10` — Chance for the item to be solved and give you the Rubik's Cube trinket.*
local STAT_BOOST_PER_WISP = 10 -- *Default: `10` — Percentage of the stat boost provided per wisp when holding the Solved Rubik's Cube.*



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

local RUBIKS_CUBE = Isaac.GetItemIdByName("Rubik's Cube")
local SOLVED_RUBIKS_CUBE = Isaac.GetTrinketIdByName("Solved Rubik's Cube")


---------------
-- FUNCTIONS --
---------------

---@param set? boolean
---@return boolean
local function scheduleReplaceNormalWisp(player, set)
    return SaveData:Data(SaveData.RUN, "RubiksCubeDelete", {}, helper.player.GetID(player), false, set)
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)

    -------------------
    -- ON ACTIVE USE --
    -------------------

    ---@param rng RNG
    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, useFlags)
        -- Don't do anything if the item was used by car battery
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

        -- Reevaluate cache
        player:AddCacheFlags(CacheFlag.CACHE_ALL, true)

        -- Get the item's description
        local desc = player:GetActiveItemDesc(ActiveSlot.SLOT_PRIMARY)

        -- Get the var data, these are the tries
        local tries = desc.VarData

        -- Get the chance to spawn the Solved Cube
        local chance = rng:RandomFloat()

        -- Check the chance against the rolled number
        -- If it's the 10th attempt, give the trinket to the player
        if chance <= SOLVE_CHANCE / 100 or tries >= 10 then
            -- Remove the active item
            player:RemoveCollectible(RUBIKS_CUBE)

            -- Schedule a wisp replacement since the book of virtues will spawn a different wisp when deleting the active
            scheduleReplaceNormalWisp(player, true)

            -- Get the ID of the trinket we should spawn
            local trinket_id = SOLVED_RUBIKS_CUBE

            -- If the player solved it in his first try, might aswell spawn the golden variant
            if tries == 0 and Isaac.GetPersistentGameData():Unlocked(Achievement.GOLDEN_TRINKET) then
                trinket_id = trinket_id + TrinketType.TRINKET_GOLDEN_FLAG
            end

            -- Spawn the trinket
            -- We don't want to give the player the trinket directly because it will
            -- overwrite the trinket the player is holding, also because of other trinkets such as tick
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinket_id, player.Position,
            EntityPickup.GetRandomPickupVelocity(player.Position)/3, player):ToPickup()

            -- Play the happy animation 👍
            player:AnimateHappy()

            -- Don't animate the player using the collectible
            return false
        else
            -- Play a sound to let the player know that the cube was not solved
            SFXManager():Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)

            -- Add 1 to the tries
            desc.VarData = tries + 1
        end

        -- Play the item animation
        return true
    end, RUBIKS_CUBE)


    -----------------------
    -- ON PICKUP SPAWNED --
    -----------------------

    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            -- If the player has the item wisps, reevaluate the cache every update in case a wisp dies
            local wisps = helper.player.GetWisps(player, RUBIKS_CUBE)
            if #wisps >= 1 then
                player:AddCacheFlags(CacheFlag.CACHE_ALL, true)
            end

            -- Here we delete the active item if it was scheduled
            if scheduleReplaceNormalWisp(player) then
                scheduleReplaceNormalWisp(player, false)

                local default_wisps = helper.player.GetWisps(player, player:GetActiveItem())

                if #default_wisps >= 1 then
                    default_wisps[1]:Remove()
                    player:AddWisp(RUBIKS_CUBE, player.Position)
                end
            end

            -- This is the code that makes the wisps change color!
            for _,v in ipairs(wisps) do
                local interval = 30

                local possible_colors = {
                    {1,0,0}, -- Red
                    {0,1,0}, -- Green
                    {0,0,1}, -- Blue
                    {1,0.5,0}, -- Orange
                    {1,1,0}, -- Yellow
                    {1,1,1}, -- White
                }

                local data = v:GetData()
                local target_color = data["TargetColor"]
                local current_color = data["CurrentColor"] or {1.5, 1.5, 1.5}
                if v.FrameCount % interval == 1 then
                    data["TargetColor"] = possible_colors[math.random(#possible_colors)]
                end
                if target_color then
                    local amount = 0.2
                    local red = helper.misc.Lerp(current_color[1], target_color[1], amount)
                    local green = helper.misc.Lerp(current_color[2], target_color[2], amount)
                    local blue = helper.misc.Lerp(current_color[3], target_color[3], amount)
                    v:GetColor():SetColorize(red, green, blue, 1)
                    data["CurrentColor"] = {red, green, blue}
                end
            end
        end
    end)


    --------------------------
    -- WHEN HOLDING TRINKET --
    --------------------------

    ---@param player EntityPlayer
    ---@param cacheFlag CacheFlag
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, cacheFlag)
        -- Don't do any of this if the player doesn't have the trinket
        if not player:HasTrinket(SOLVED_RUBIKS_CUBE) then return end

        -- Multiplier to the base effect, based on how many copies you have, if the trinket is golden, if you have mom's box, etc.
        local effect_multiplier = player:GetTrinketMultiplier(SOLVED_RUBIKS_CUBE)
        effect_multiplier = effect_multiplier * (1 + #helper.player.GetWisps(player, RUBIKS_CUBE) * (STAT_BOOST_PER_WISP / 100))

        -- I'm not commenting all this
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + 0.20 * effect_multiplier * player:GetD8SpeedModifier()
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            helper.player.ModifyFireDelay(player, (-1 * effect_multiplier * helper.player.GetAproxTearRateMultiplier(player)))
        end
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + 1.5 * effect_multiplier * helper.player.GetAproxDamageMultiplier(player)
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            helper.player.ModifyTearRange(player, 1.5 * effect_multiplier * player:GetD8RangeModifier())
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.2 * effect_multiplier
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 3 * effect_multiplier
        end
    end)


    ------------------
    -- DESCRIPTIONS --
    ------------------

    ---@type EID
    if EID then
        EID:addCollectible(RUBIKS_CUBE,
            "#{{Luck}} "..SOLVE_CHANCE.."% chance of solving the cube and destroying itself"..
            "#{{Trinket"..SOLVED_RUBIKS_CUBE.."}} When solved, drops a Solved Rubik's Cube trinket"
        )

        helper.eid.BookOfVirtuesSynergy("Rubik's Cube Book Of Virtues", RUBIKS_CUBE, "Each wisp will enhance the Solved Rubik's Cube stats by 10%")

        EID:addTrinket(SOLVED_RUBIKS_CUBE,
            "#{{ArrowUp}} All stats up"
        )
        EID:addGoldenTrinketMetadata(SOLVED_RUBIKS_CUBE, {"Effect doubled", "Effect tripled"})
    end
end

return modded_item