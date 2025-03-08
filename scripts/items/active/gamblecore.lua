------------------------
-- CONSTANTS AND INIT --
------------------------

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
REWARDS_TYPE.Deal = 9


---------------
-- FUNCTIONS --
---------------

---@param rng? RNG
local function NewReelSprite(rng)
    if rng == nil then rng = GLOBAL_RNG end

    local slot = Sprite("gfx/ui/hud_gambling.anm2", true)
    slot:Play(tostring(rng:RandomInt(9)))
    slot.PlaybackSpeed = 30

    return slot
end

---@param player EntityPlayer
---@param type number
---@param add? number
local function PlayerReward(player, type, add)
    local reward = ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "gamblecoreStatAdditions", {}, ARAOI.PlayerUtils.GetID(player)..type, 0)
    if add then
        if type == REWARDS_TYPE.Angel then
            game:GetLevel():AddAngelRoomChance(add * 0.07)
        end
        return ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "gamblecoreStatAdditions", {}, ARAOI.PlayerUtils.GetID(player)..type, 0, reward+add)
    else
        return reward
    end
end

local gambling_players = {}

---@param player EntityPlayer
local function StartGambling(player)
    ARAOI.SaveData:Key(gambling_players, ARAOI.PlayerUtils.GetID(player), false, true)
end

---@param player EntityPlayer
local function IsGambling(player)
    return ARAOI.SaveData:Key(gambling_players, ARAOI.PlayerUtils.GetID(player), false)
end

local hud_reels = {}

---@param player EntityPlayer
---@param rng? RNG
local function CreateSlots(player, amount, rng)
    if not IsGambling(player) then
        StartGambling(player)
        local reels = {}
        for _ = 1,amount do
            local reel = NewReelSprite(rng)
            table.insert(reels, reel)
        end
        ARAOI.SaveData:Key(hud_reels, ARAOI.PlayerUtils.GetID(player), {}, reels)
    end
end

local function ClearGambling(player)
    gambling_players[ARAOI.PlayerUtils.GetID(player)] = nil
    hud_reels[ARAOI.PlayerUtils.GetID(player)] = nil
end

---@param player EntityPlayer
---@return Sprite[]
local function GetReels(player)
    return ARAOI.SaveData:Key(hud_reels, ARAOI.PlayerUtils.GetID(player), {})
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
    for i, reel in ipairs(GetReels(player)) do
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
                    table.insert(jackpots, table.remove(winnings, #winnings-1))
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
        sfx:Play(SFX_I_CANT_STOP_WINNING, 0.7)
        sfx:Play(SoundEffect.SOUND_POWERUP_SPEWER_AMPLIFIED)

    -- Else, do we have at least a win?
    elseif #winnings > 0 then
        -- Play a sound
        sfx:Play(SFX_I_CANT_STOP_WINNING, 0.7)

    -- If all else fails, we didn't win anything
    else
        sfx:Play(SFX_AW_DANG_IT, 0.7)
    end

    -- For every winning symbol
    for _,symbol in ipairs(winnings) do
        -- Add 1 level to the player's reward, based on the symbol
        PlayerReward(player, symbol, 1)
    end

    -- For every jackpot symbol
    for _,symbol in ipairs(jackpots) do
        -- Get everything for later
        local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLECORE)
        local room = game:GetRoom()
        local pos = room:FindFreePickupSpawnPosition(player.Position, 50)
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

        -- Spawn a collectible from the given pool
        ARAOI.ItemUtils.SpawnCollectibleFromPool(pool, pos, nil, nil, nil, rng)
    end

    -- Re-evaluate the player's cache so we can display the changed stats
    player:AddCacheFlags(CacheFlag.CACHE_ALL, true)

    -- Finally, de-spawn the reels
    ClearGambling(player)
end

-- Takes care of initializing everything
---@param rng RNG
---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, useFlags)
    -- If this is a car battery use, nothing should happen
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

    -- If we have at least 7 coins and we are not currently gambling
    if player:GetNumCoins() >= 7 and not IsGambling(player) then
        -- If the timeout for the sound effect is over
        if SFX_LETS_GO_GAMBLING_TIMEOUT == 0 then
            -- Play the sound effect
            sfx:Play(SFX_LETS_GO_GAMBLING, 0.7)
        end
        -- Reset the timeout
        SFX_LETS_GO_GAMBLING_TIMEOUT = SFX_LETS_GO_GAMBLING_COOLDOWN

        -- Remove 7 coins from the player
        player:AddCoins(-7)
        -- Create slots for the player, spawning more reels if the player has car battery
        CreateSlots(player, not player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) and 3 or 5, rng)
    end


    ---------------------
    -- BOOK OF VIRTUES --
    ---------------------

    -- If we have Book of Virtues
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
        -- Get the chance
        local chance = rng:RandomFloat()
        -- Did we land in that 7%?
        if chance <= 0.07 then
            -- Do this 7 times
            for _=1,7 do
                -- Spawn a wisp
                Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, ARAOI.CollectibleType.GAMBLECORE,
                player.Position, Vector.Zero, player)
                sfx:Play(SoundEffect.SOUND_SUMMON_POOF)
            end
        end
    end

    return true
end, ARAOI.CollectibleType.GAMBLECORE)

-- Function that takes care of the reel animations and detecting when they are finished
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    -- If the sfx is in timeout, decrease it
    if SFX_LETS_GO_GAMBLING_TIMEOUT > 0 then SFX_LETS_GO_GAMBLING_TIMEOUT = SFX_LETS_GO_GAMBLING_TIMEOUT - 1 end

    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- If the player is not gambling, we go to the next player
        if not IsGambling(player) then goto continue end

        -- Checking how many reels finished their animation
        local reels_finished = 0

        -- For every reel assigned to the player
        for _, reel in ipairs(GetReels(player)) do
            -- Get some data for later
            local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLECORE)
            local frame = reel:GetFrame()

            -- We update the reel
            reel:Update()

            -- We decrease the speed of the animation depending on how much time has passed
            if reel.PlaybackSpeed > 10 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - rng:RandomFloat()
            elseif reel.PlaybackSpeed > 7 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - rng:RandomFloat()*2
            elseif reel.PlaybackSpeed > 5 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - rng:RandomFloat()*4
            elseif reel.PlaybackSpeed > 4 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - rng:RandomFloat()*2
            elseif reel.PlaybackSpeed >= 0.3 then
                reel.PlaybackSpeed = reel.PlaybackSpeed - rng:RandomFloat()

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
                local random = Isaac.GetPlayer():GetCollectibleRNG(ARAOI.CollectibleType.GAMBLECORE):RandomInt(9)
                -- Play the new sprite animation
                reel:Play(tostring(random), true)
                -- Play a sound
                sfx:Play(SFX_TICK, 0.7)
            end
            -- If we passed through the middle
            if frame == 19 then
                -- Play a sound
                sfx:Play(SFX_TICK, 0.7)
            end
        end

        -- Check if the reels that finished is the same amount as the reels the player has
        if reels_finished == #GetReels(player) then
            -- If so, calculate the reward we should give
            CalculateReward(player)
        end

        ::continue::
    end
end)

-- Rendering of the slots
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- Get their reels
        local reels = GetReels(player)
        -- For every reel
        for i, reel in ipairs(reels) do
            -- Render it with an offset depending on their index
            reel:Render(Isaac.WorldToScreen(player.Position) - Vector(-28 * (i-math.ceil(#reels/2)), 57))
        end
    end
end)


-----------------
-- CACHE MAGIC --
-----------------

---@param player EntityPlayer
---@param flag CacheFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
    if flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + PlayerReward(player, REWARDS_TYPE.Speed) * 0.14
    end
    if flag == CacheFlag.CACHE_FIREDELAY then
        ARAOI.PlayerUtils.AddFireDelay(player, PlayerReward(player, REWARDS_TYPE.Tears) * -0.77, false)
    end
    if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + PlayerReward(player, REWARDS_TYPE.Damage) * (ARAOI.PlayerUtils.GetAproxDamageMultiplier(player) * 0.77)
    end
    if flag == CacheFlag.CACHE_RANGE then
        player.TearRange = player.TearRange + PlayerReward(player, REWARDS_TYPE.Range) * 7
    end
    if flag == CacheFlag.CACHE_SHOTSPEED then
        player.ShotSpeed = player.ShotSpeed + PlayerReward(player, REWARDS_TYPE.Shotspeed) * 0.21
    end
    if flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + PlayerReward(player, REWARDS_TYPE.Luck) * 2.64
    end
end)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_DEVIL_CALCULATE, function (_, chance)
    local reward_chance = 0
    for _,player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + PlayerReward(player, REWARDS_TYPE.Devil) * 0.07
    end
    return chance + reward_chance
end)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    local reward_chance = 0
    for _,player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + PlayerReward(player, REWARDS_TYPE.Angel) * 0.07
    end
    game:GetLevel():AddAngelRoomChance(reward_chance)
end)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_PLANETARIUM_CALCULATE, function (_, chance)
    local reward_chance = 0
    for _,player in ipairs(PlayerManager.GetPlayers()) do
        reward_chance = reward_chance + PlayerReward(player, REWARDS_TYPE.Planetarium) * 0.07
    end
    return chance + reward_chance
end)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.GAMBLECORE,
        "# Spawns 3 reels above Isaac"..
        "#{{ArrowUp}} Getting a line of 2 symbols gives Isaac a respective stat up"..
        "#{{Collectible}} Getting a line of 3 symbols spawns an item related to the respective stat"..
        "#{{Coin}} Costs 7 coins per use"
    )
    ARAOI.EIDUtils.CarBatterySynergy(
        "gamblecore car battery synergy",
        ARAOI.CollectibleType.GAMBLECORE,
        "Spawns 2 extra reels"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "gamblecore abyss synergy",
        ARAOI.CollectibleType.GAMBLECORE,
        "Spawns 7 small locusts that deal 0.14x Isaac's damage"
    )
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "gamblecore book of vietues synergy",
        ARAOI.CollectibleType.GAMBLECORE,
        "7% chance to spawn 7 wisps"
    )
end)