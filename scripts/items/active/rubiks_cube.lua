
----------------------------
-- START OF CONFIGURATION --
----------------------------



local SOLVE_CHANCE = 10 -- *Default: `10` — Chance for the item to be solved and give you the Rubik's Cube trinket.*
local STAT_BOOST_PER_WISP = 10 -- *Default: `10` — Percentage of the stat boost provided per wisp when holding the Solved Rubik's Cube.*



--------------------------
-- END OF CONFIGURATION --
--------------------------




---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local RUBIKS_CUBE = Isaac.GetItemIdByName("Rubik's Cube")
local SOLVED_RUBIKS_CUBE = Isaac.GetTrinketIdByName("Solved Rubik's Cube")

---@param set? number
---@return number
local function rubiksCubeSolveTries(player, set)
    return SaveData:Data(SaveData.RUN, "RubiksCubeTries", {}, Helper.GetPlayerId(player), 0, set)
end

---@param set? boolean
---@return boolean
local function scheduleReplaceNormalWisp(player, set)
    return SaveData:Data(SaveData.RUN, "RubiksCubeDelete", {}, Helper.GetPlayerId(player), false, set)
end

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)

    -------------------
    -- ON ACTIVE USE --
    -------------------

    ---@param rng RNG
    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    local function onItemUsed(_, _, rng, player, useFlags)
        -- Don't do anything if the item was used by car battery
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return false end

        -- Reevaluate cache
        player:AddCacheFlags(CacheFlag.CACHE_ALL, true)

        -- Add a try to the rubik's cube
        rubiksCubeSolveTries(player, rubiksCubeSolveTries(player) + 1)

        -- Get the chance to spawn the Solved Cube
        local chance = rng:RandomFloat()

        -- Check the chance against the rolled number
        if chance <= SOLVE_CHANCE / 100 then
            -- Remove the active item
            player:RemoveCollectible(RUBIKS_CUBE)

            -- Schedule a wisp replacement since the book of virtues will spawn a different wisp when deleting the active
            scheduleReplaceNormalWisp(player, true)

            -- Get the ID of the trinket we should spawn
            local trinketID = SOLVED_RUBIKS_CUBE

            -- If the player solved it in his first try, might aswell spawn the golden variant
            if rubiksCubeSolveTries(player) <= 1 and Isaac.GetPersistentGameData():Unlocked(Achievement.GOLDEN_TRINKET) then
                trinketID = trinketID + TrinketType.TRINKET_GOLDEN_FLAG
            end

            -- Spawn the trinket
            -- We don't want to give the player the trinket directly because it will
            -- overwrite the trinket the player is holding, also because of other trinkets such as tick
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinketID, player.Position,
            EntityPickup.GetRandomPickupVelocity(player.Position)/3, player):ToPickup()

            -- Play the happy animation 👍
            player:AnimateHappy()

            -- Don't animate the player using the collectible
            return false
        else
            -- Play a sound to let the player know that the cube was not solved
            SFXManager():Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
        end

        -- Play the item animation
        return true
    end
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, onItemUsed, RUBIKS_CUBE)


    -----------------------
    -- ON PICKUP SPAWNED --
    -----------------------

    local function onUpdate()
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            -- If the player has the item wisps, reevaluate the cache every update in case a wisp dies
            local wisps = Helper.GetPlayerWisps(player, RUBIKS_CUBE)
            if #wisps >= 1 then
                player:AddCacheFlags(CacheFlag.CACHE_ALL, true)
            end

            -- Here we delete the active item if it was scheduled
            if scheduleReplaceNormalWisp(player) then
                scheduleReplaceNormalWisp(player, false)

                local defaultWisps = Helper.GetPlayerWisps(player, player:GetActiveItem())

                if #defaultWisps >= 1 then
                    defaultWisps[1]:Remove()
                    player:AddWisp(RUBIKS_CUBE, player.Position)
                end
            end

            -- This is the code that makes the wisps change color!
            for _,v in ipairs(wisps) do
                local interval = 30

                local possibleColors = {
                    {1,0,0}, -- Red
                    {0,1,0}, -- Green
                    {0,0,1}, -- Blue
                    {1,0.5,0}, -- Orange
                    {1,1,0}, -- Yellow
                    {1,1,1}, -- White
                }

                local data = v:GetData()
                local targColor = data["TargetColor"]
                local currColor = data["CurrentColor"] or {1.5, 1.5, 1.5}
                if v.FrameCount % interval == 1 then
                    data["TargetColor"] = possibleColors[math.random(#possibleColors)]
                end
                if targColor then
                    local t = 0.2
                    local r = Helper.Lerp(currColor[1], targColor[1], t)
                    local g = Helper.Lerp(currColor[2], targColor[2], t)
                    local b = Helper.Lerp(currColor[3], targColor[3], t)
                    v:GetColor():SetColorize(r, g, b, 1)
                    data["CurrentColor"] = {r,g,b}
                end
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onUpdate)


    --------------------------
    -- WHEN HOLDING TRINKET --
    --------------------------

    ---@param player EntityPlayer
    ---@param cacheFlag CacheFlag
    local function updateCache(_, player, cacheFlag)
        -- Don't do any of this if the player doesn't have the trinket
        if not player:HasTrinket(SOLVED_RUBIKS_CUBE) then return end

        -- Multiplier to the base effect, based on how many copies you have, if the trinket is golden, if you have mom's box, etc.
        local effectMultiplier = player:GetTrinketMultiplier(SOLVED_RUBIKS_CUBE)
        effectMultiplier = effectMultiplier * (1 + #Helper.GetPlayerWisps(player, RUBIKS_CUBE) * (STAT_BOOST_PER_WISP / 100))

        -- I'm not commenting all this
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + 0.20 * effectMultiplier * player:GetD8SpeedModifier()
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            Helper.ModifyFireDelay(player, (-1 * effectMultiplier * Helper.GetAproxTearRateMultiplier(player)))
        end
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + 1.5 * effectMultiplier * Helper.GetAproxDamageMultiplier(player)
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            Helper.ModifyTearRange(player, 1.5 * effectMultiplier * player:GetD8RangeModifier())
        end
        if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.2 * effectMultiplier
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 3 * effectMultiplier
        end
    end
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, updateCache)


    ------------------
    -- DESCRIPTIONS --
    ------------------

    ---@class EID
    if EID then
        EID:addCollectible(RUBIKS_CUBE,
            "#{{Luck}} "..SOLVE_CHANCE.."% chance of solving the cube and destroying itself"..
            "#{{Trinket"..SOLVED_RUBIKS_CUBE.."}} When solved, drops a Solved Rubik's Cube trinket"
        )

        local BOV = CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES

        ---@param descObject EIDDescriptionObject 
        local function check(descObject)
            return Helper.DescObjIs(descObject, 5, 100, RUBIKS_CUBE) and PlayerManager.AnyoneHasCollectible(BOV)
        end
        ---@param descObject EIDDescriptionObject
        local function modifier(descObject)
            EID:appendToDescription(descObject, "#{{Collectible"..BOV.."}} Each wisp will enhance the Solved Rubik's Cube stats by 10%")
            return descObject
        end
        EID:addDescriptionModifier("Rubik's Cube Book Of Virtues", check, modifier)

        EID:addTrinket(SOLVED_RUBIKS_CUBE,
            "#{{ArrowUp}} All stats up"
        )
        EID:addGoldenTrinketMetadata(SOLVED_RUBIKS_CUBE, {"Effect doubled", "Effect tripled"})
    end
end

return modded_item