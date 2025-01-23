local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.SOLVE_CHANCE = 10 -- *Default: `10` — Chance for the item to be solved and give you the Rubik's Cube trinket.*



--------------------------
-- END OF CONFIGURATION --
--------------------------


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Rubiks_Cube = {}
ARAOI.Rubiks_Cube.Config = Config


---------------
-- FUNCTIONS --
---------------

---@param set? boolean
---@return boolean
local function ScheduleReplaceNormalWisp(player, set)
    return ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "RubiksCubeDelete", {}, ARAOI.PlayerUtils.GetID(player), false, set)
end


-------------------
-- ON ACTIVE USE --
-------------------

---@param rng RNG
---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player)
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
    if chance <= Config.SOLVE_CHANCE / 100 or tries >= 10 then
        -- Remove the active item
        player:RemoveCollectible(ARAOI.CollectibleType.RUBIKS_CUBE)

        -- Schedule a wisp replacement since the book of virtues will spawn a different wisp when deleting the active
        ScheduleReplaceNormalWisp(player, true)

        -- Get the ID of the trinket we should spawn
        local trinket_id = ARAOI.TrinketType.SOLVED_RUBIKS_CUBE

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
end, ARAOI.CollectibleType.RUBIKS_CUBE)


-------------------
-- UPDATE METHOD --
-------------------

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        -- If the player has the item wisps, reevaluate the cache every update in case a wisp dies
        local locusts = ARAOI.PlayerUtils.GetLocusts(player, ARAOI.CollectibleType.RUBIKS_CUBE)
        local wisps = ARAOI.PlayerUtils.GetWisps(player, ARAOI.CollectibleType.RUBIKS_CUBE)
        if #wisps >= 1 then
            player:AddCacheFlags(CacheFlag.CACHE_ALL, true)
        end

        -- Here we delete the active item if it was scheduled
        if ScheduleReplaceNormalWisp(player) then
            ScheduleReplaceNormalWisp(player, false)

            local default_wisps = ARAOI.PlayerUtils.GetWisps(player, player:GetActiveItem())

            if #default_wisps >= 1 then
                default_wisps[1]:Remove()
                player:AddWisp(ARAOI.CollectibleType.RUBIKS_CUBE, player.Position)
            end
        end

        -- This is the code that makes the wisps change color!
        ---@param familiar EntityFamiliar
        local function changeColor(familiar)
            local interval = 30

            local possible_colors = {
                {1,0,0}, -- Red
                {0,1,0}, -- Green
                {0,0,1}, -- Blue
                {1,0.5,0}, -- Orange
                {1,1,0}, -- Yellow
                {1,1,1}, -- White
            }

            local data = familiar:GetData()
            local target_color = data["TargetColor"]
            local current_color = data["CurrentColor"] or {1.5, 1.5, 1.5}
            if familiar.FrameCount % interval == 1 then
                data["TargetColor"] = possible_colors[math.random(#possible_colors)]
            end
            if target_color then
                local amount = 0.2
                local red = ARAOI.MiscUtils.Lerp(current_color[1], target_color[1], amount)
                local green = ARAOI.MiscUtils.Lerp(current_color[2], target_color[2], amount)
                local blue = ARAOI.MiscUtils.Lerp(current_color[3], target_color[3], amount)
                familiar:GetColor():SetColorize(red, green, blue, 1)
                data["CurrentColor"] = {red, green, blue}
            end
        end
        for _,v in ipairs(wisps) do
            changeColor(v)
        end
        for _,v in ipairs(locusts) do
            changeColor(v)
        end
    end
end)


------------------
-- DESCRIPTIONS --
------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.RUBIKS_CUBE,
        "#{{Luck}} "..Config.SOLVE_CHANCE.."% chance of dropping a {{Trinket"..ARAOI.TrinketType.SOLVED_RUBIKS_CUBE.."}} Solved Rubik's Cube and destroying itself"
    )

    ARAOI.EIDUtils.BookOfVirtuesSynergy("Rubik's Cube Book Of Virtues", ARAOI.CollectibleType.RUBIKS_CUBE, "Each wisp will enhance the Solved Rubik's Cube stats by 10%")

    ARAOI.EIDUtils.AbyssSynergy(
        "Rubik's Cube Abyss Synergy",
        ARAOI.CollectibleType.RUBIKS_CUBE,
        "Color-changing locust that deals 1.2x Isaac's damage"
    )
end)