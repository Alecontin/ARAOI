-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------





---@type SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@type helper
local helper = include("scripts.helper")


---------------
-- CONSTANTS --
---------------

local LUCKY_COIN = Isaac.GetItemIdByName("Lucky Coin")
local LUCKY_COIN_SOUND = Isaac.GetSoundIdByName("lucky_coin")
local LUCKY_COIN_ENTITY = Isaac.GetEntityVariantByName("Lucky Coin")


---------------
-- VARIABLES --
---------------

local double_tap_data = {}

---@param player EntityPlayer
---@param set? integer
local function doubleTap(player, set)
    return SaveData:Key(double_tap_data, helper.player.GetID(player), 0, set)
end


---------------
-- FUNCTIONS --
---------------

---@param player EntityPlayer
local function spawnCoin(player)
    SFXManager():Play(LUCKY_COIN_SOUND)
    local shootingInput = player:GetShootingInput()
    local velocity = (shootingInput * 6) + (player.Velocity / 2)
    local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, LUCKY_COIN_ENTITY, 0, player.Position, velocity, player):ToEffect()
    particle:SetTimeout(90)
    particle.SpriteOffset = particle.SpriteOffset + Vector(0, 14)
    if shootingInput.Y ~= 0 then
        particle:GetSprite():Play("IdleY")
    end
end

---@param position Vector
local function getNearestEnemy(position)
    local nearest_distance = 99999999
    local nearest_enemy = nil
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            local distance = (position - entity.Position):Length()
            if distance < nearest_distance then
                nearest_distance = distance
                nearest_enemy = entity
            end
        end
    end
    return nearest_enemy
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)


    -------------------------
    -- DOUBLE TAP DETECTOR --
    -------------------------

    -- I was too lazy to use `MC_INPUT_ACTION` so I used `MC_POST_RENDER` instead
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
        -- Check every player that has the item
        for _, player in ipairs(helper.player.GetPlayersWithCollectible(LUCKY_COIN)) do
            -- If the player just press the shoot button
            if helper.player.TriggeredShooting(player) then
                -- Check if the double tap countdown is at 0
                if doubleTap(player) == 0 then
                    -- If so, increase it
                    doubleTap(player, 15)

                -- The double tap wasn't at 0
                else
                    -- Set it to 0
                    doubleTap(player, 0)

                    -- Spawn a coin
                    spawnCoin(player)
                end
            end

            -- Check if the double tap countdown is higher than 0
            if doubleTap(player) > 0 then
                -- If it is, set it to the existing countdown - 1
                doubleTap(player, doubleTap(player) - 1)
            end
        end
    end)


    -------------------------------
    -- ITEM EFFECT FUNCTIONALITY --
    -------------------------------

    ---@param effect EntityEffect
    Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (_, effect)
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
            SFXManager():Play(SoundEffect.SOUND_POT_BREAK, 0.4, nil, nil, 2)
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
                local nearest_enemy = getNearestEnemy(tear.Position)

                -- Is there an enemy near the tear
                if nearest_enemy then
                    -- If there is, get the data
                    local data = tear:GetData()

                    -- Did we not already modify this tear?
                    if data["LuckyCoin"] == nil then
                        -- Mark the tear as modified
                        data["LuckyCoin"] = true

                        -- Play a sound to signal we detected / the player hit the tear
                        SFXManager():Play(LUCKY_COIN_SOUND, 0.6)

                        -- Set the tear's velocity towards the enemy, normalize it, then make it as fast as the original velocity
                        tear.Velocity = (nearest_enemy.Position - tear.Position):Normalized():Resized(tear.Velocity:Length())

                        -- We don't need the item's RNG since there's no point in tracking the effect in a run
                        -- so we just use the math.random() function
                        if math.random() < 0.5 then
                            -- Modify the tear damage and scale, lowering them
                            tear.CollisionDamage = tear.BaseDamage * 0.5
                            tear.Scale = tear.BaseScale * 0.75
                        else
                            -- Modify the tear damage and scale, raising them
                            tear.CollisionDamage = tear.BaseDamage * 2
                            tear.Scale = tear.BaseScale * 1.35
                        end
                    end
                end
            end
        end
    end, LUCKY_COIN_ENTITY)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(LUCKY_COIN,
            "# Double tapping a shooting key throws a coin in that direction"..
            "#{{Tearsize}} Shooting at a coin:"..
            "#{{Blank}} {{Shotspeed}} Redirects the tear towards the closest enemy"..
            "#{{Blank}} {{Damage}} Has a 50/50 chance of doubling/halving the tear's damage"..
            "#!!! Only works for tears !!!"
        )
    end
end



return modded_item