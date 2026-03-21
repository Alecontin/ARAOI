local Config = {}

----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.ALL_REELS_AT_ONCE     = false -- *Default: `false` — Should all reels be animated and stopped at the same time?*
Config.DIFFERENT_REEL_SOUNDS = true  -- *Default: `true`  — Use different sounds when rolling and stopping reels?*
Config.ARTIFICIAL_PITY       = 0     -- *Default: `0`     — Pity added before the calculation. Increases chance of payout.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Gamblecore = {}

local game = Game()
local sfx = SFXManager()

local SEED = game:GetSeeds():GetNextSeed()
local GLOBAL_RNG = RNG(SEED)

local SFX_LETS_GO_GAMBLING = Isaac.GetSoundIdByName("gc_letsgogambling")
local SFX_TICK = Isaac.GetSoundIdByName("gc_tick")
local SFX_AW_DANG_IT = Isaac.GetSoundIdByName("gc_awdangit")
local SFX_I_CANT_STOP_WINNING = Isaac.GetSoundIdByName("gc_icantstopwinning")

local SFX_LETS_GO_GAMBLING_COOLDOWN = 30*5
local SFX_LETS_GO_GAMBLING_TIMEOUT = 0

local REWARDS_TYPE = {}
REWARDS_TYPE.Speed = 0
REWARDS_TYPE.Tears = 1
REWARDS_TYPE.Damage = 2
REWARDS_TYPE.Range = 3
REWARDS_TYPE.Shotspeed = 4
REWARDS_TYPE.Luck = 5
REWARDS_TYPE.Devil = 6
REWARDS_TYPE.Angel = 7
REWARDS_TYPE.Planetarium = 8
REWARDS_TYPE.Treasure = 9
local num_rewards = 10

local NULL_EFFECTS = {
    Isaac.GetNullItemIdByName("Gamblecore Speed"),
    Isaac.GetNullItemIdByName("Gamblecore Tears"),
    Isaac.GetNullItemIdByName("Gamblecore Damage"),
    Isaac.GetNullItemIdByName("Gamblecore Range"),
    Isaac.GetNullItemIdByName("Gamblecore Shotspeed"),
    Isaac.GetNullItemIdByName("Gamblecore Luck")
}

ARAOI.Gamblecore.REWARDS_TYPE = REWARDS_TYPE


---------------
-- FUNCTIONS --
---------------

---@param rng? RNG
local function NewReelSprite(rng)
    if rng == nil then rng = GLOBAL_RNG end

    local slot = Sprite("gfx/ui/hud_gambling.anm2", true)
    slot:Play(tostring(rng:RandomInt(num_rewards)))
    slot.PlaybackSpeed = 30

    return slot
end

---@param player EntityPlayer
---@param reward_type number -- The type of the reward. Use `ARAOI.Gamblecore.REWARDS_TYPE`
---@param add? integer -- How many to add. Leave at `nil` to get the current reward level. `0` to reset
---@return integer
function ARAOI.Gamblecore.PlayerReward(player, reward_type, add)
    if reward_type <= 5 then -- We can manage stats up to luck with null effects
        local effects = player:GetEffects()
        local null_id = NULL_EFFECTS[reward_type+1]
        if add then
            if add <= 0 then
                effects:RemoveNullEffect(null_id, add == 0 and -1 or -add)
            else
                effects:AddNullEffect(null_id, false, add)
            end
        end
        return effects:GetNullEffectNum(null_id)
    else -- Other stats we need to change on the fly and can not be set through null effects
        local reward = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "gamblecoreStatAdditions", {}, ARAOI.PlayerUtils.GetId(player).."/"..reward_type, 0)
        if add then
            if reward_type == REWARDS_TYPE.Angel then
                game:GetLevel():AddAngelRoomChance(add * 0.07)
            end
            return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "gamblecoreStatAdditions", {}, ARAOI.PlayerUtils.GetId(player).."/"..reward_type, 0, add ~= 0 and (reward+add) or add)
        else
            return reward
        end
    end
end

---@param player EntityPlayer
---@param add? integer -- How much to add. Leave at `nil` to get the current pity level. `0` to reset
---@return integer
function ARAOI.Gamblecore.PlayerPity(player, add)
    local pity = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "gamblecoreFailurePity", {}, ARAOI.PlayerUtils.GetId(player), 0)
    if add then
        return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "gamblecoreFailurePity", {}, ARAOI.PlayerUtils.GetId(player), 0, add ~= 0 and (pity+add) or add)
    else
        return pity
    end
end

local gambling_players = {}

---@param player EntityPlayer
local function StartGambling(player)
    gambling_players[ARAOI.PlayerUtils.GetId(player)] = true
    -- ARAOI.SaveDataManager:Key(gambling_players, ARAOI.PlayerUtils.GetID(player), false, true)
end

---@param player EntityPlayer
local function IsGambling(player)
    return gambling_players[ARAOI.PlayerUtils.GetId(player)] or false
    -- return ARAOI.SaveDataManager:Key(gambling_players, ARAOI.PlayerUtils.GetID(player), false)
end

local hud_reels = {}

-- Starts the gambling interaction by creating reels and rolling them
---@param player EntityPlayer
---@param amount integer -- Please use only odd numbers!
---@param rng? RNG
function ARAOI.Gamblecore.CreateSlots(player, amount, rng)
    if rng == nil then rng = GLOBAL_RNG end
    if not IsGambling(player) then
        StartGambling(player)
        local reels = {}
        for i = 1, amount do
            local reel = NewReelSprite(rng)
            if Config.ALL_REELS_AT_ONCE == false then
                reel.PlaybackSpeed = reel.PlaybackSpeed + (i - 1) * 6
            end
            table.insert(reels, reel)
        end
        ARAOI.SaveDataManager:Key(hud_reels, ARAOI.PlayerUtils.GetId(player), {}, reels)
    end
end

-- Clears the gambling interaction, this is done automatically
function ARAOI.Gamblecore.ClearGambling(player)
    gambling_players[ARAOI.PlayerUtils.GetId(player)] = nil
    hud_reels[ARAOI.PlayerUtils.GetId(player)] = nil
end

-- Get the current player's reels
---@param player EntityPlayer
---@return Sprite[]
function ARAOI.Gamblecore.GetReels(player)
    return hud_reels[ARAOI.PlayerUtils.GetId(player)] or {}
    -- return ARAOI.SaveDataManager:Key(hud_reels, ARAOI.PlayerUtils.GetID(player), {})
end


----------------------------
-- ITEM USE FUNCTIONALITY --
----------------------------

-- Calculates the rewards that the player should gain
---@param player EntityPlayer
local function CalculateReward(player)

    -- Keeping track of all the data

    local same_symbols = 1
    ---@type number[]
    local winnings = {}
    ---@type number[]
    local jackpots = {}
    ---@type number[]
    local symbols = {}

    -- For every reel assigned to the player
    for i, reel in ipairs(ARAOI.Gamblecore.GetReels(player)) do
        -- Get the current symbol
        local symbol = tonumber(reel:GetAnimation())
        -- Keep track of it
        table.insert(symbols, symbol)
        -- If this is not the first reel
        if i > 0 then
            -- If the current symbol is the same as the one before it
            if symbols[i-1] == symbol then
                -- It's the same
                same_symbols = same_symbols + 1
                -- Add it to our winnings, since we only require 2 symbols to get a reward
                table.insert(winnings, symbol)
                -- If this is the 3rd symbol in a row
                if same_symbols == 3 then
                    -- Remove the symbol from our winnings and add it to out jackpots instead
                    table.insert(jackpots, table.remove(winnings, #winnings))
                    -- Reset the symbols
                    same_symbols = 1
                end
            else
                -- Resetting the symbols since it's not the same as the before it
                same_symbols = 1
            end
        end
    end

    -- If we have at least a jackpot
    if #jackpots > 0 then
        -- Play some sounds
        sfx:Play(SFX_I_CANT_STOP_WINNING, 0.5)
        sfx:Play(SoundEffect.SOUND_POWERUP_SPEWER_AMPLIFIED)
        ARAOI.Gamblecore.PlayerPity(player, 0)

    -- Else, do we have at least a win?
    elseif #winnings > 0 then
        -- Play a sound
        sfx:Play(SFX_I_CANT_STOP_WINNING, 0.5)
        ARAOI.Gamblecore.PlayerPity(player, 0)

    -- If all else fails, we didn't win anything
    else
        ARAOI.Gamblecore.PlayerPity(player, 1)
        sfx:Play(SFX_AW_DANG_IT, 0.5)
    end

    -- For every winning symbol
    for _,symbol in ipairs(winnings) do
        -- Add 1 level to the player's reward, based on the symbol
        ARAOI.Gamblecore.PlayerReward(player, symbol, 1)

        -- If we landed the special treasure win
        if symbol == REWARDS_TYPE.Treasure then
            -- Spawn an item
            ARAOI.ItemUtils.SpawnCollectible(CollectibleType.COLLECTIBLE_NULL, Isaac.GetCollectibleSpawnPosition(player.Position))
        end
    end

    -- For every jackpot symbol
    for _,symbol in ipairs(jackpots) do
        -- Get everything for later
        local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLECORE)
        local pos = game:GetRoom():FindFreePickupSpawnPosition(player.Position, 30)
        local pool = ItemPoolType.POOL_TREASURE

        -- Get a pool depending on the jackpot
        if symbol == REWARDS_TYPE.Speed then
            pool = Isaac.GetPoolIdByName("gamblecoreSpeedUp")
        end
        if symbol == REWARDS_TYPE.Tears then
            pool = Isaac.GetPoolIdByName("gamblecoreTearsUp")
        end
        if symbol == REWARDS_TYPE.Damage then
            pool = Isaac.GetPoolIdByName("gamblecoreDamageUp")
        end
        if symbol == REWARDS_TYPE.Range then
            pool = Isaac.GetPoolIdByName("gamblecoreRangeUp")
        end
        if symbol == REWARDS_TYPE.Shotspeed then
            pool = Isaac.GetPoolIdByName("gamblecoreShotspeedUp")
        end
        if symbol == REWARDS_TYPE.Luck then
            pool = Isaac.GetPoolIdByName("gamblecoreLuckUp")
        end
        if symbol == REWARDS_TYPE.Devil then
            pool = ItemPoolType.POOL_DEVIL
        end
        if symbol == REWARDS_TYPE.Angel then
            pool = ItemPoolType.POOL_ANGEL
        end
        if symbol == REWARDS_TYPE.Planetarium then
            pool = ItemPoolType.POOL_PLANETARIUM
        end
        if symbol == REWARDS_TYPE.Treasure then
            local room = game:GetRoom()
            pool = (room:GetItemPool(1) == -1 and room:GetType() == RoomType.ROOM_DEFAULT) and 0 or room:GetItemPool(1) -- ! BAND AID FIX !
            ARAOI.ItemUtils.SpawnCollectibleFromPool(pool, pos, nil, nil, nil, rng)
            ARAOI.ItemUtils.SpawnCollectibleFromPool(pool, pos, nil, nil, nil, rng)
        end

        -- Spawn a collectible from the given pool
        ARAOI.ItemUtils.SpawnCollectibleFromPool(pool, pos, nil, nil, nil, rng)
    end

    -- Re-evaluate the player's cache so we can display the changed stats
    player:AddCacheFlags(CacheFlag.CACHE_ALL, true)

    -- Finally, de-spawn the reels
    ARAOI.Gamblecore.ClearGambling(player)
end

---@param player EntityPlayer
function ARAOI:_OnGamblecoreGetActiveMinUsableCharge(_, player)
    if player:GetNumCoins() >= 7 then
        return 0
    end
end
ARAOI:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MIN_USABLE_CHARGE, ARAOI._OnGamblecoreGetActiveMinUsableCharge, ARAOI.CollectibleType.GAMBLECORE)

-- Takes care of initializing everything
---@param rng RNG
---@param player EntityPlayer
---@param useFlags UseFlag
---@param slot ActiveSlot
function ARAOI:_OnGamblecoreUse(_, rng, player, useFlags, slot)
    -- If this is a car battery use, nothing should happen
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

    -- If we are not currently gambling
    if not IsGambling(player) then
        -- If the timeout for the sound effect is over
        if SFX_LETS_GO_GAMBLING_TIMEOUT == 0 then
            -- Play the sound effect
            sfx:Play(SFX_LETS_GO_GAMBLING, 0.5)
        end
        -- Reset the timeout
        SFX_LETS_GO_GAMBLING_TIMEOUT = SFX_LETS_GO_GAMBLING_COOLDOWN

        -- We used our item but we didn't have enough charges
        if player:GetActiveCharge(slot) < player:GetActiveMaxCharge(slot) then
            -- Remove 7 coins from the player
            player:AddCoins(-7)
            ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)
        end

        -- Create slots for the player, spawning more reels if the player has car battery
        ARAOI.Gamblecore.CreateSlots(player, not player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) and 3 or 5, rng)


        ---------------------
        -- BOOK OF VIRTUES --
        ---------------------

        -- If we have Book of Virtues
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            -- Get the chance
            local chance = rng:RandomFloat()
            -- Did we land in that 21%?
            if chance <= 0.21 then
                -- Do this 7 times
                for _=1,7 do
                    -- Spawn a wisp
                    Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, ARAOI.CollectibleType.GAMBLECORE,
                    player.Position, Vector.Zero, player)
                    sfx:Play(SoundEffect.SOUND_SUMMON_POOF)
                end
            end
        end
    else
        ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)
    end

    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnGamblecoreUse, ARAOI.CollectibleType.GAMBLECORE)

-- Function that takes care of the reel animations and detecting when they are finished
function ARAOI:_OnGamblecoreUpdate()
    -- If the sfx is in timeout, decrease it
    if SFX_LETS_GO_GAMBLING_TIMEOUT > 0 then SFX_LETS_GO_GAMBLING_TIMEOUT = SFX_LETS_GO_GAMBLING_TIMEOUT - 1 end

    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- If the player is not gambling, we go to the next player
        if not IsGambling(player) then goto continue end

        -- Checking how many reels finished their animation
        local reels_finished = 0

        -- For every reel assigned to the player
        for i, reel in ipairs(ARAOI.Gamblecore.GetReels(player)) do
            -- Get some data for later
            local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLECORE)
            local frame = reel:GetFrame()

            -- We update the reel
            reel:Update()

            -- We decrease the speed of the animation depending on how much time has passed
            if reel.PlaybackSpeed > 10 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - 1
            elseif reel.PlaybackSpeed > 7 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - 2
            elseif reel.PlaybackSpeed > 5 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - 3
            elseif reel.PlaybackSpeed > 3 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - 2
            elseif reel.PlaybackSpeed >= 0.3 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - 1

            -- We reached the end of the animation
            elseif reel.PlaybackSpeed ~= -10 then
                -- Pause the animation so it stops moving
                reel.PlaybackSpeed = 0
                -- Putting the symbol in the middle
                if frame ~= 19 then
                    if frame > 19 then
                        reel:SetFrame(reel:GetFrame() - 1)
                    else
                        reel:SetFrame(reel:GetFrame() + 1)
                    end

                -- Now that the symbol is in the middle, we signal the end of the animation
                else
                    reel.PlaybackSpeed = -10
                end
            else
                -- Mark this reel as finished
                reels_finished = reels_finished + 1
            end

            -- If the sprite animation finished
            if reel:IsFinished(reel:GetAnimation()) then
                -- Get a new random sprite animation
                local set_same = rng:RandomFloat() < (0.0264 * (ARAOI.Gamblecore.PlayerPity(player) + Config.ARTIFICIAL_PITY))

                local choice = nil
                if set_same and i > 1 then
                    choice = ARAOI.Gamblecore.GetReels(player)[i-1]:GetAnimation()
                else
                    choice = rng:RandomInt(num_rewards - 1)
                end

                -- Play the new sprite animation
                reel:Play(tostring(choice), true)
            end

            -- If we passed the center
            if reel:IsEventTriggered("Click") then
                -- Play a sound
                if reel.PlaybackSpeed == 0 or Config.DIFFERENT_REEL_SOUNDS == false then
                    sfx:Play(SFX_TICK, 0.5)
                else
                    sfx:Play(SFX_TICK, 0.3, 0, false, 0.9, 0)
                end
            end

            ::next_reel::
        end

        -- Check if the reels that finished is the same amount as the reels the player has
        if reels_finished == #ARAOI.Gamblecore.GetReels(player) then
            -- If so, calculate the reward we should give
            CalculateReward(player)
        end

        ::continue::
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnGamblecoreUpdate)

-- Rendering of the slots
function ARAOI:_OnGamblecoreRender()
    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- Get their reels
        local reels = ARAOI.Gamblecore.GetReels(player)
        -- For every reel
        for i, reel in ipairs(reels) do
            -- Render it with an offset depending on their index
            reel:Render(Isaac.WorldToScreen(player.Position) - Vector(-28 * (i-math.ceil(#reels/2)), 57))
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_RENDER, ARAOI._OnGamblecoreRender)


-----------------
-- CACHE MAGIC --
-----------------

-- ---@param player EntityPlayer
-- ---@param flag CacheFlag
-- function ARAOI:_OnGamblecoreEvaluateCache(player, flag)
--     if flag == CacheFlag.CACHE_SPEED then
--         player.MoveSpeed = player.MoveSpeed + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Speed) * 0.21
--     end
--     if flag == CacheFlag.CACHE_FIREDELAY then
--         player.FireDelay = ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Tears) * -0.77 * player:GetStatMultiplier()
--     end
--     if flag == CacheFlag.CACHE_DAMAGE then
--         player.Damage = player.Damage + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Damage) * (ARAOI.PlayerUtils.GetAproxDamageMultiplier(player) * 0.77)
--     end
--     if flag == CacheFlag.CACHE_RANGE then
--         player.TearRange = player.TearRange + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Range) * 7
--     end
--     if flag == CacheFlag.CACHE_SHOTSPEED then
--         player.ShotSpeed = player.ShotSpeed + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Shotspeed) * 0.21
--     end
--     if flag == CacheFlag.CACHE_LUCK then
--         player.Luck = player.Luck + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Luck) * 2.64
--     end
-- end
-- ARAOI:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, ARAOI._OnGamblecoreEvaluateCache)

function ARAOI:_OnGamblecoreDevilCalculate(chance)
    local reward_chance = 0
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Devil) * 0.07
    end
    return chance + reward_chance
end
ARAOI:AddCallback(ModCallbacks.MC_POST_DEVIL_CALCULATE, ARAOI._OnGamblecoreDevilCalculate)

function ARAOI:_OnGamblecoreNewLevel()
    local reward_chance = 0
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Angel) * 0.07
    end
    game:GetLevel():AddAngelRoomChance(reward_chance)
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ARAOI._OnGamblecoreNewLevel)

function ARAOI:_OnGamblecorePlanetariumCalculate(chance)
    local reward_chance = 0
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + ARAOI.Gamblecore.PlayerReward(player, REWARDS_TYPE.Planetarium) * 0.07
    end
    return chance + reward_chance
end
ARAOI:AddCallback(ModCallbacks.MC_POST_PLANETARIUM_CALCULATE, ARAOI._OnGamblecorePlanetariumCalculate)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.GAMBLECORE,
        "#{{Coin}} +7 Coins"..
        "# Spawns 3 reels above Isaac"..
        "#{{ArrowUp}} Getting a 2 symbols in a row gives Isaac a respective stat up"..
        "#{{Collectible}} Getting a 3 symbols in a row spawns an item related to the respective stat"..
        "#{{Coin}} Costs 7 coins to use if it's not fully charged"
    )

    EID:addCarBatteryCondition(ARAOI.CollectibleType.GAMBLECORE, "Spawns 2 extra reels")
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.GAMBLECORE, "7 locusts (0.14x Isaac's damage)")
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "gamblecore book of vietues synergy",
        ARAOI.CollectibleType.GAMBLECORE,
        "21% chance to spawn 7 wisps"
    )
end)


if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Actives", "Gamblecore")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Gamblecore", Config, "ALL_REELS_AT_ONCE",
    ConfigDefaults, function ()
        return "All Reels At Once: "
    end, "Should all reels be animated and stopped at the same time?")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Gamblecore", Config, "DIFFERENT_REEL_SOUNDS",
    ConfigDefaults, function ()
        return "Different Reel Sounds: "
    end, "Use different sounds when rolling and stopping reels?")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Gamblecore", Config, "ARTIFICIAL_PITY",
    ConfigDefaults, ConfigDefaults.ARTIFICIAL_PITY, 0, 38, 5, function ()
        return "Artificial Pity: " .. (Config.ARTIFICIAL_PITY == 0 and "" or "aprox. ") .. math.floor((Config.ARTIFICIAL_PITY / 38) * 100) ..  "%"
    end, "Pity added before the calculation", "Increases chance of payout")

    ARAOI.MCMUtils.AddReset("Actives", "Gamblecore")
end