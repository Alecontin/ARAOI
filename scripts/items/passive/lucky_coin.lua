local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------


Config.COIN_TIMEOUT = 120 -- *Default: `120` — The amount of time the coin will stay in the air, in update frames.*

Config.CHANCE_PER_LUCK = 1 -- *Default: `1` — The chance per 1 luck that will be added towards doubling the damage.*


--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Lucky_Coin = {}
ARAOI.Lucky_Coin.Config = Config

local LUCKY_COIN_SOUND = Isaac.GetSoundIdByName("lucky_coin")
local LUCKY_COIN_ENTITY = Isaac.GetEntityVariantByName("Lucky Coin")


---------------
-- VARIABLES --
---------------

local double_tap_countdowns = {}
local double_tap_keys = {}

---@param player EntityPlayer
---@param set? integer
local function doubleTapCountdown(player, set)
    if set then
        double_tap_countdowns[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return double_tap_countdowns[ARAOI.PlayerUtils.GetId(player)] or 0
    -- return ARAOI.SaveDataManager:Key(double_tap_countdowns, ARAOI.PlayerUtils.GetID(player), 0, set)
end

---@param player EntityPlayer
---@param set? integer
local function doubleTapKey(player, set)
    if set then
        double_tap_keys[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return double_tap_keys[ARAOI.PlayerUtils.GetId(player)] or 0
    -- return ARAOI.SaveDataManager:Key(double_tap_keys, ARAOI.PlayerUtils.GetID(player), 0, set)
end


---------------
-- FUNCTIONS --
---------------

-- Spawn a coin for the provided player
---@param player EntityPlayer
function ARAOI.Lucky_Coin.SpawnCoin(player)
    SFXManager():Play(LUCKY_COIN_SOUND, 0.5)
    local shootingInput = player:GetShootingInput():Normalized()
    local velocity = (shootingInput * 5) + (player.Velocity / 2)
    local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, LUCKY_COIN_ENTITY, 0, player.Position, velocity, player):ToEffect()
    assert(particle)
    particle:SetTimeout(Config.COIN_TIMEOUT)
    particle.SpriteOffset = particle.SpriteOffset + Vector(0, 14)
    if shootingInput.Y ~= 0 then
        particle:GetSprite():Play("IdleY")
    end
end


-------------------------
-- DOUBLE TAP DETECTOR --
-------------------------

-- I was too lazy to use `MC_INPUT_ACTION` so I used `MC_POST_RENDER` instead
function ARAOI._OnLuckyCoinRender()
    -- Check every player that has the item
    for _, player in ipairs(ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.LUCKY_COIN)) do
        local fire_direction = ARAOI.PlayerUtils.TriggeredShooting(player)
        -- If the player just pressed the shoot button
        if fire_direction then
            -- Check if the double tap countdown is at 0
            if doubleTapCountdown(player) == 0 or doubleTapKey(player) == ARAOI.PlayerUtils.FireDirection.NONE then
                -- If so, increase it and set the key
                doubleTapCountdown(player, 20)
                doubleTapKey(player, fire_direction)

            -- The double tap wasn't at 0
            else
                -- Did we press the same key as before?
                if fire_direction == doubleTapKey(player) then
                    -- Spawn a coin
                    ARAOI.Lucky_Coin.SpawnCoin(player)
                end

                -- Reset everything
                doubleTapKey(player, ARAOI.PlayerUtils.FireDirection.NONE)
                doubleTapCountdown(player, 0)
            end
        end

        -- Check if the double tap countdown is higher than 0
        if doubleTapCountdown(player) > 0 then
            -- If it is, set it to the existing countdown - 1
            doubleTapCountdown(player, doubleTapCountdown(player) - 1)
        elseif doubleTapKey(player) ~= ARAOI.PlayerUtils.FireDirection.NONE then
            doubleTapKey(player, ARAOI.PlayerUtils.FireDirection.NONE)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_RENDER, ARAOI._OnLuckyCoinRender)


-------------------------------
-- ITEM EFFECT FUNCTIONALITY --
-------------------------------

---@param effect EntityEffect
function ARAOI:_OnLuckyCoinEffectUpdate(effect)
    -- Check if the entity that spawned the effect exists, else remove the effect
    local spawner = effect.SpawnerEntity
    if not spawner then
        return effect:Remove()
    end

    -- Check if the player that spawned the effect exists, else remove the effect
    local player = spawner:ToPlayer()
    if not player then
        return effect:Remove()
    end

    -- Check if the velocity is close to 0
    if effect.Velocity:Length() <= 0.1 then
        -- If it is, set it to 0, we don't want to move the effect backwards
        effect.Velocity = Vector.Zero
    else
        -- If it's not, slowly decrease the velocity
        effect:AddVelocity(-effect.Velocity:Normalized() * 0.2)
    end

    -- Check if the effect timed out
    if effect.Timeout == 0 then
        -- Spawn some coin particles
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.COIN_PARTICLE, 0, effect.Position, Vector.Zero, nil)

        -- Remove the effect
        effect:Remove()

        -- Play a sound
        return SFXManager():Play(SoundEffect.SOUND_POT_BREAK, 0.3, nil, nil, 2)
    end

    -- Check if the sprite's height offset is not 0
    if effect.SpriteOffset.Y ~= 0 then
        -- Slowly return the offset to 0
        effect.SpriteOffset = effect.SpriteOffset - Vector(0, 1)
    end

    -- This next section could've been avoided if I just used familiars instead of effects
    -- like a normal human being. But using familiars generates another set of problems
    -- that I do not want to figure out

    -- Check every entity in the room
    for _, v in pairs(Isaac.GetRoomEntities()) do
        -- Check if the entity is a tear
        local tear = v:ToTear()

        -- If it is a tear, and it's really close to the effect
        if tear and tear.Position:Distance(effect.Position) <= 13 then
            -- Get the nearest enemy to the tear
            local nearest_enemy = ARAOI.RoomUtils.GetNearestEnemy(tear.Position)

            -- Is there an enemy near the tear
            if nearest_enemy then
                -- If there is, get the data
                local data = tear:GetData()

                -- Did we not already modify this tear?
                if data["LuckyCoin"] == nil then
                    -- Mark the tear as modified
                    data["LuckyCoin"] = true

                    -- Play a sound to signal we detected the tear
                    SFXManager():Play(LUCKY_COIN_SOUND, 0.3)

                    -- Set the tear's velocity towards the enemy, normalize it, then make it as fast as the original velocity
                    tear.Velocity = (nearest_enemy.Position - tear.Position):Normalized():Resized(tear.Velocity:Length())

                    -- Get the probability of the damage being doubled
                    local doublingChance = 0.5 + (Config.CHANCE_PER_LUCK/100) * player.Luck

                    -- We don't need the item's RNG since there's no point in tracking the effect in a run
                    -- so we just use the math.random() function
                    local tearIsBeingDoubled = math.random() < doublingChance

                    if tearIsBeingDoubled then
                        -- Modify the tear damage and scale, raising them
                        tear.CollisionDamage = tear.BaseDamage * 2
                        tear.Scale = tear.BaseScale * 1.35
                    else
                        -- Modify the tear damage and scale, lowering them
                        tear.CollisionDamage = tear.BaseDamage * 0.5
                        tear.Scale = tear.BaseScale * 0.75
                    end
                end
            end
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, ARAOI._OnLuckyCoinEffectUpdate, LUCKY_COIN_ENTITY)


------------------
-- LUDOVICO FIX --
------------------

---@param tear EntityTear
function ARAOI:_OnLuckyCoinTearUpdate(tear)
    -- Check if the spawner exists
    local spawner = tear.SpawnerEntity
    if not spawner then return end

    -- Check if the spawner is a player
    local player = spawner:ToPlayer()
    if not player then return end

    -- Check if the tear has the ludovico flag
    if not tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) then return end

    -- Check if the tear was affected by our item
    local data = tear:GetData()
    if data["LuckyCoin"] == nil then return end

    -- Set the collision damage to the base damage
    tear.CollisionDamage = tear.BaseDamage
end
ARAOI:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, ARAOI._OnLuckyCoinTearUpdate)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.LUCKY_COIN,
        "# Double-tapping a fire button throws a coin in that direction"..
        "#{{Tearsize}} Shooting at a coin:"..
        "#{{Blank}} {{Shotspeed}} Redirects the tear towards the closest enemy"..
        "#{{Blank}} {{Damage}} Has a 50/50 chance of doubling/halving the tear's damage"..
        "#{{Luck}} Every 1 Luck adds "..Config.CHANCE_PER_LUCK.."% chance towards doubling the damage"..
        "#!!! Only works for tears !!!"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Lucky Coin Abyss Synergy",
        ARAOI.CollectibleType.LUCKY_COIN,
        "Yellow locust with a 1.5% chance per hit of spawning a coin"
    )
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Passives", "Lucky Coin")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Lucky Coin", Config, "COIN_TIMEOUT",
    ConfigDefaults, math.floor((ConfigDefaults.COIN_TIMEOUT / 30) * 100) / 100 .. "s", 1, 300, 10, function ()
        return "Coin Timeout: " .. math.floor((Config.COIN_TIMEOUT / 30) * 100) / 100 .. "s"
    end, "The amount of time the coin will stay in the air")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Lucky Coin", Config, "CHANCE_PER_LUCK",
    ConfigDefaults, ConfigDefaults.CHANCE_PER_LUCK .. "%", 1, 50, 5, function ()
        return "Chance per Luck: " .. Config.CHANCE_PER_LUCK .. "%"
    end, "The chance per 1 luck that will be added towards doubling the damage")

    ARAOI.MCMUtils.AddReset("Passives", "Lucky Coin")
end