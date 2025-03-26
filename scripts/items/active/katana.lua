
-----------------------------
-- CONSTANTS AND VARIABLES --
-----------------------------

local game = Game()

local EFFECT_SLASH = Isaac.GetEntityVariantByName("Katana Slash")

local MAX_BLOCK_TIME = 36
local PARRY_WINDOW = 4
local PARRY_DAMAGE_MULTIPLIER = 10
local PARRY_PATH_DAMAGE_MULTIPLIER = 3


---------------
-- FUNCTIONS --
---------------

local block_time = {}

---@param player EntityPlayer
---@param time? integer -- Time in update frames
local function SetBlockTime(player, time)
    ARAOI.SaveData:Key(block_time, ARAOI.PlayerUtils.GetID(player), 0, time == nil and MAX_BLOCK_TIME or time)
end
---@param player EntityPlayer
local function GetBlockTime(player)
    return ARAOI.SaveData:Key(block_time, ARAOI.PlayerUtils.GetID(player), 0)
end
---@param player EntityPlayer
local function StopBlocking(player)
    ARAOI.SaveData:Key(block_time, ARAOI.PlayerUtils.GetID(player), 0, 0)
end

---@param player EntityPlayer
local function GetParryWindow(player)
    if ARAOI.PlayerUtils.HasShield(player) or player:GetDamageCooldown() > 0 then
        return -1
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
        return PARRY_WINDOW * 2
    else
        return PARRY_WINDOW
    end
end

---@param player EntityPlayer
---@param from Vector
---@param to Vector
---@param parried Entity
---@param enemies Entity[]
local function ProcessSynergies(player, from, to, parried, enemies)
    -- Get the direction towards our target position
    local direction = -(from - to):Normalized()

    -- For every enemy that we hit
    for _, enemy in ipairs(enemies) do
        -- If the enemy is not an active enemy, skip it
        if not enemy:IsActiveEnemy() then goto continue end
        -- If the current enemy is the parried enemy, keep track of it and add multipliers
        local is_parried_enemy = GetPtrHash(enemy) == GetPtrHash(parried)
        local damage_multiplier = is_parried_enemy and PARRY_DAMAGE_MULTIPLIER or PARRY_PATH_DAMAGE_MULTIPLIER
        local size_multiplier = is_parried_enemy and 2 or 1

        -- Keeping track of the final damage we should deal
        local final_damage = player.Damage * damage_multiplier

        -- Getting the current distance from our starting position
        local distance = from:Distance(enemy.Position)

        -- If we have Dr. Fetus or Epic Fetus
        if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)
        or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
            -- Create an explosion on top of the enemy
            game:BombExplosionEffects(enemy.Position, (player.Damage/2) * damage_multiplier, nil, nil, nil, 0.5 * size_multiplier)
        end

        -- Function to get a multiplier depending on distance
        local function GetMultiplier(dist, min_distance, max_distance, min_multiplier, max_multiplier)
            local d = dist
            local mult = 1
            if d <= min_distance then
                mult = max_multiplier
            elseif d >= max_distance then
                mult = min_multiplier
            else
                t = (dist - min_distance) / (max_distance - min_distance)
                mult = max_multiplier - (t * (max_multiplier - min_multiplier))
            end

            return mult
        end
        -- If we have proptosis/lump of coal, apply a multiplier depending on distance
        if player:HasCollectible(CollectibleType.COLLECTIBLE_PROPTOSIS) then
            final_damage = final_damage * GetMultiplier(distance, 35, 150, 0.3, 2)
        end
        if player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then
            final_damage = final_damage * GetMultiplier(distance, 35, 150, 2, 0.3)
        end

        -- If we have holy light
        if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then
            -- Spawn a holy light on top of the enemy
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, enemy.Position, Vector.Zero, player).CollisionDamage = player.Damage
            -- If the enemy is our parried enemy
            if is_parried_enemy then
                -- Do this 5 times
                for _ = 1,5 do
                    -- Spawn a holy light around the enemy
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0,
                    enemy.Position + Vector(math.random(200)-100, math.random(200)-100),
                    Vector.Zero, player).CollisionDamage = player.Damage
                end
            end
        end

        -- If we have ocular rift
        if player:HasCollectible(CollectibleType.COLLECTIBLE_OCULAR_RIFT) then
            -- Spawn a rift on top of the enemy
            local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0, enemy.Position, Vector.Zero, player):ToEffect()
            assert(rift)
            -- If the enemy is the parried enemy, increase the scale and damage
            rift.SpriteScale = is_parried_enemy and Vector(2.5, 2.5) or Vector(1, 1)
            rift.CollisionDamage = (player.Damage / 2)
            rift:SetTimeout(90)
        end

        -- Deal damage and apply tear effects
        ARAOI.MiscUtils.DamageWithTearEffects(player,enemy,final_damage,nil,DamageFlag.DAMAGE_IGNORE_ARMOR,nil,nil,player:GetCollectibleRNG(ARAOI.CollectibleType.KATANA))
        ::continue::
    end

    if -- The player has any technology item
    (player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_2)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_5)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_ZERO))
    then
        -- Fire technology lasers in an octagon
        local rotation = 0
        local steps = 8
        for _ = 0, steps do
            player:FireTechLaser(parried.Position, LaserOffset.LASER_TECH1_OFFSET, Vector.FromAngle(rotation), nil, nil, player, 10)
            rotation = rotation + 360/steps
        end
    end

    -- If the player has brimstone
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
        -- Fire a brimstone laser
        local laser = player:FireBrimstone(direction, player, 1)
        -- Disable following
        laser:SetDisableFollowParent(true)
        -- Change the position to the start position
        laser.Position = from
        -- Add the Anti Gravity tear effect
        laser:AddTearFlags(TearFlags.TEAR_WAIT)
    end
end


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

-- Starting the chain reaction
---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
    -- Show the item
    player:AnimateCollectible(ARAOI.CollectibleType.KATANA)

    -- Set the block time so everything works
    SetBlockTime(player)

    -- Do not show the default item animation
    return false
end, ARAOI.CollectibleType.KATANA)

-- Decreasing the block time and updating the item's counter cooldown
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- Get the player's block time
        local time = GetBlockTime(player)
        -- If they are blocking
        if time > 0 then
            -- Decrease the block time
            SetBlockTime(player, time - 1)
        end

        -- If the player has our item
        if player:HasCollectible(ARAOI.CollectibleType.KATANA) then
            -- Get the item's data, aka the counter cooldown
            local data = player:GetActiveItemDesc(player:GetActiveItemSlot(ARAOI.CollectibleType.KATANA))
            -- If the counter is on cooldown
            if data.VarData > 0 then
                -- Decrease it
                data.VarData = data.VarData - 1
            end
        end
    end
end)

-- Function that adds effects to the counter
---@param effect EntityEffect
---@param entity Entity
ARAOI.Mod:AddCallback("ARAOI MELEE WOOSH ENTITY DAMAGED", function (_, effect, entity)
    -- Checking if the attack is from our item
    local data = effect:GetData()
    -- If it's not, stop right here
    if not data["IsKatanaMelee"] then return end

    -- If the attacked entity is an enemy and is vulnerable
    if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
        -- We can get the player
        local player = effect.Parent:ToPlayer()
        if player then
            -- If the enemy would die from this attack
            if entity.HitPoints - effect.HitPoints <= 0 then
                -- Add some charge to our item
                ARAOI.PlayerUtils.AddActiveCharge(player, player:GetActiveItemSlot(ARAOI.CollectibleType.KATANA), 60, false, false, true)
            end
            -- Apply appropriate tear effects to the entity
            ARAOI.MiscUtils.DamageWithTearEffects(player,entity,effect.HitPoints,nil,DamageFlag.DAMAGE_FAKE,nil,nil,player:GetCollectibleRNG(ARAOI.CollectibleType.KATANA))
        end
    end
end)

-- Main item functionality: countering and parrying
---@param player EntityPlayer
---@param damageFlags DamageFlag
---@param source EntityRef
ARAOI.Mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player, _, damageFlags, source, _)
    -- Getting the block time for later
    local TIME = GetBlockTime(player)

    -- If the damage was self inflicted like Dull Razor,
    -- was because of the second player like Esau,
    -- was inflicted by IV Bag,
    -- bypassed the player's invincibility.
    if damageFlags & DamageFlag.DAMAGE_FAKE > 0
    or damageFlags & DamageFlag.DAMAGE_CLONES > 0
    or damageFlags & DamageFlag.DAMAGE_IV_BAG > 0
    or damageFlags & DamageFlag.DAMAGE_INVINCIBLE > 0
    or damageFlags & DamageFlag.DAMAGE_NO_PENALTIES > 0
    or TIME <= 0
    or source.Entity == nil
    -- We let the game handle the damage.
    then return end

    -- Getting the parried entity
    local PARRIED_ENTITY = source.Entity
    -- If the parried entity was spawned
    if PARRIED_ENTITY.SpawnerEntity then
        -- Target the spawner entity instead
        PARRIED_ENTITY = PARRIED_ENTITY.SpawnerEntity
        assert(PARRIED_ENTITY)
    end

    -- Function to stop the item hold animation
    local function InterruptAnimation()
        -- Make the player take fake damage
        player:TakeDamage(0, DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 0)
        -- Stop the hurt sound
        SFXManager():Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT)
        -- Stop the hurt animation
        player:StopExtraAnimation()
    end

    -- Function that spawns the visible slashes after parrying
    ---@param from Vector
    ---@param to Vector
    local function SpawnEffects(from, to)
        -- Function to spawn an individual slash
        ---@param position Vector
        local function SpawnSlash(position)
            -- Spawn the slash
            local slash = Isaac.Spawn(1000, EFFECT_SLASH, 0, position, Vector.Zero, nil):ToEffect()
            assert(slash)
            -- Give it a random rotation and offset
            slash:GetSprite().Rotation = math.random(360)
            slash:GetSprite().Offset = Vector(0, -20)
            slash:GetSprite().PlaybackSpeed = math.random(0,1) / 2 + 0.75
        end

        -- Setting some data
        local step = 30
        local current = from
        local offset = Vector.Zero
        local distance = from:Distance(to)

        -- While we still have distance to travel to our targer
        while distance > 0 do
            -- Spawn 3 slashes
            for _ = 1, 3 do
                offset = Vector(math.random(100) - 50, math.random(100) - 50)
                SpawnSlash(current + offset)
            end
            -- Decrease the current distance and keep track of the remaining distance
            current = current - (from - to):Normalized() * step
            distance = distance - step
        end

        -- Get a list of all enemies hit by our effect and return it
        local enemies = Isaac.FindInCapsule(Capsule(from, to, 40))
        return enemies
    end

    -- Did we get damaged while on our parry window?
    if TIME >= (MAX_BLOCK_TIME - GetParryWindow(player)) then
        -- Interrupt the item animation and stop blocking
        InterruptAnimation()
        StopBlocking(player)

        -- Add invincibility so we don't get instantly hit after teleporting
        ARAOI.PlayerUtils.AddShield(player, 30)

        -- Store our current position
        local original_position = player.Position

        -- Get the direction of our teleport
        local enemy_direction = (player.Position - PARRIED_ENTITY.Position):Normalized()

        -- Get the new position to teleport to
        local position = PARRIED_ENTITY.Position - enemy_direction * 50 * (PARRIED_ENTITY:IsBoss() and 2 or 1)

        -- If we are flying, we can ignore obstacles
        if player:IsFlying() then
            player.Position = PARRIED_ENTITY.Position - position

        else
            -- Raycasting to find the closest available position
            ---@type boolean, Vector
            ---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
            _, player.Position = Game():GetRoom():CheckLine(PARRIED_ENTITY.Position, position, LineCheckMode.ENTITY)
        end

        -- Spawn the slash effects and get the hit enemies
        local hit_enemies = SpawnEffects(original_position, player.Position)

        -- Play a sound for feedback and recharge our item
        SFXManager():Play(SoundEffect.SOUND_TOOTH_AND_NAIL, nil, nil, nil, 2)
        ARAOI.PlayerUtils.AddActiveCharge(player,  player:GetActiveItemSlot(ARAOI.CollectibleType.KATANA), 265, false, false, true)

        -- Process the synergies, which is also where damage is done
        ProcessSynergies(player, original_position, player.Position, PARRIED_ENTITY, hit_enemies)

    -- We got hit outside our parry window, but we still blocked
    else
        -- Check our counter cooldown
        local data = player:GetActiveItemDesc(player:GetActiveItemSlot(ARAOI.CollectibleType.KATANA))
        -- If we're not in cooldown
        if data.VarData <= 0 then
            -- Reset the cooldown
            data.VarData = 3

            -- Spawn an attack
            local woosh = ARAOI.PlayerUtils.FireMelee(player, 1.5, -(player.Position - PARRIED_ENTITY.Position):Normalized(), nil, false)

            -- Mark the attack as our item's
            local woosh_data = woosh:GetData()
            woosh_data["IsKatanaMelee"] = true

            -- Play a sound for feedback
            SFXManager():Play(SoundEffect.SOUND_TOOTH_AND_NAIL, nil, nil, nil, 2)
        end
    end
    return false
end)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.KATANA,
        "# Isaac holds the sword and counters incoming damage"..
        "# Countering just before getting hit will {{ColorYellow}}Parry{{CR}} instead"..
        "# {{ColorYellow}}Parrying{{CR}} an attack will teleport Isaac behind the attacker and deal {{Damage}} "..PARRY_DAMAGE_MULTIPLIER.."x Isaac's damage"..
        "#{{Battery}} Countering and {{ColorYellow}}Parrying{{CR}} restore some charge"..
        "#!!! Using the item while invincible {{ColorYellow}}disables parrying{{CR}}"
    )
    ARAOI.EIDUtils.CarBatterySynergy(
        "KATANA CAR BATTERY SYNERGY",
        ARAOI.CollectibleType.KATANA,
        "Doubles parry window"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "KATANA ABYSS SYNERGY",
        ARAOI.CollectibleType.KATANA,
        "Gray locust thad does 3x damage"
    )
end)