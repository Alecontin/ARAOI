
-----------------------------
-- CONSTANTS AND VARIABLES --
-----------------------------

local game = Game()

local EFFECT_SLASH = Isaac.GetEntityVariantByName("Katana Slash")

local KATANA_MARK_ID = "KatanaEnemyMark"

local SWING_DAMAGE_MULTIPLIER = 0.8
local TELEPORT_DAMAGE_MULTIPLIER = 5
local INVINCIBILITY_TIME = 30

---------------
-- FUNCTIONS --
---------------

local TEAR_RATE = {}
---@param player EntityPlayer
---@param set? integer
local function FireDelay(player, set)
    if set then
        TEAR_RATE[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return TEAR_RATE[ARAOI.PlayerUtils.GetId(player)] or 0
    -- return ARAOI.SaveDataManager:Key(TEAR_RATE, ARAOI.PlayerUtils.GetID(player), 0, set)
end

local LAST_DAMAGED_ENEMY = {}
---@param player EntityPlayer
---@param set? Entity
---@return Entity
local function LastDamagedEnemy(player, set)
    if set then
        LAST_DAMAGED_ENEMY[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return LAST_DAMAGED_ENEMY[ARAOI.PlayerUtils.GetId(player)]
    -- return ARAOI.SaveDataManager:Key(LAST_DAMAGED_ENEMY, ARAOI.PlayerUtils.GetID(player), nil, set)
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_NEW_ROOM, function ()
    LAST_DAMAGED_ENEMY = {}
end)

---@param player EntityPlayer
---@param from Vector
---@param to Vector
---@param target Entity
---@param enemies Entity[]
local function ProcessSynergies(player, from, to, target, enemies)
    -- Get the direction towards our target position
    local direction = -(from - to):Normalized()

    -- For every enemy that we hit
    for _, enemy in ipairs(enemies) do
        -- If the enemy is not an active enemy, skip it
        if not enemy:IsActiveEnemy() then goto continue end
        -- If the current enemy is the parried enemy, keep track of it and add multipliers
        local is_parried_enemy = GetPtrHash(enemy) == GetPtrHash(target)
        local size_multiplier = is_parried_enemy and 2 or 1

        -- Keeping track of the final damage we should deal
        local final_damage = player.Damage * TELEPORT_DAMAGE_MULTIPLIER

        -- Getting the current distance from our starting position
        local distance = from:Distance(enemy.Position)

        -- If we have Dr. Fetus or Epic Fetus
        if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)
        or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
            -- Create an explosion on top of the enemy
            game:BombExplosionEffects(enemy.Position, (player.Damage/2) * TELEPORT_DAMAGE_MULTIPLIER, nil, nil, nil, 0.5 * size_multiplier)
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
            player:FireTechLaser(target.Position, LaserOffset.LASER_TECH1_OFFSET, Vector.FromAngle(rotation), nil, nil, player, 10)
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

    return slash
end

-- Function that spawns the visible slashes after teleporting
---@param from Vector
---@param to Vector
local function SpawnEffects(from, to)
    -- Setting some data
    local step = 30
    local current = from
    local offset = Vector.Zero
    local distance = from:Distance(to)

    -- While we still have distance to travel to our target
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
    local enemies = Isaac.FindInCapsule(Capsule(from, to, 50))
    return enemies
end

-- Responsible for spawning and keeping track of the Katana marks
local function UpdateEnemyMark(player, reset)
    local data = player:GetData()

    -- Checking if we have a mark placed
    ---@type EntityEffect
    local slash = data[KATANA_MARK_ID]
    if slash then
        -- If we do and we need to get rid of it, we do just that
        if slash.Parent == nil or slash.Parent:IsDead() or reset then
            slash:Remove()
            data[KATANA_MARK_ID] = nil
        end
    else
        -- If we don't, and we have an active target
        local enemy = LastDamagedEnemy(player)
        if enemy and not enemy:IsDead() then
            -- Spawn a mark
            slash = SpawnSlash(enemy.Position + Vector(0, 1))
            data[KATANA_MARK_ID] = slash

            -- Make it follow the enemy
            slash:FollowParent(enemy)

            -- Making sure it doesn't despawn and does not obstruct vision
            slash:GetSprite().PlaybackSpeed = 0
            slash:GetSprite().Scale = Vector(0.5, 0.5)
        end
    end
end


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

-- Starting the chain reaction
---@param player EntityPlayer
function ARAOI:_OnKatanaUse(_, _, player, useFlag, slot)
    if useFlag & UseFlag.USE_CARBATTERY ~= 0 then return end

    -- Store our current position
    local original_position = player.Position

    -- Checking if we have a target
    local TARGET_ENTITY = LastDamagedEnemy(player)
    if TARGET_ENTITY == nil or TARGET_ENTITY:IsDead() then
        -- If we don't, return the charges and stop here
        ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)
        return false
    end

    -- Add invincibility so we don't get instantly hit after teleporting
    ARAOI.PlayerUtils.AddShield(player, INVINCIBILITY_TIME)

    -- Get the direction of our teleport
    local enemy_direction = (player.Position - TARGET_ENTITY.Position):Normalized()

    -- Get the new position to teleport to
    local offset = 30
    local boss_multiplier = TARGET_ENTITY:IsBoss() and 2 or 1
    local position = TARGET_ENTITY.Position - enemy_direction * offset * boss_multiplier

    -- If we are flying, we can ignore obstacles
    if player:IsFlying() then
        player.Position = position

    else
        -- Raycasting to find the closest available position
        ---@type boolean, Vector
        ---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
        _, player.Position = Game():GetRoom():CheckLine(player.Position, position, LineCheckMode.ENTITY)
    end

    -- Spawn the slash effects and get the hit enemies
    local hit_enemies = SpawnEffects(original_position, player.Position)

    -- Process the synergies, which is also where damage is done
    ProcessSynergies(player, original_position, player.Position, TARGET_ENTITY, hit_enemies)

    -- Sound effect for the item use
    Isaac.CreateTimer(function ()
        SFXManager():Play(SoundEffect.SOUND_TOOTH_AND_NAIL, 1, 0, nil, 2)
    end, 1, 5, false)

    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnKatanaUse, ARAOI.CollectibleType.KATANA)

-- Function that adds effects to the counter
---@param effect EntityEffect
---@param entity Entity
function ARAOI:_OnKatanaWooshEntityCollision(effect, entity)
    -- Checking if the attack is from our item
    local data = effect:GetData()
    -- If it's not, stop right here
    if not data["IsKatanaMelee"] then return end

    -- If the attacked entity is an active enemy
    if entity:IsEnemy() and entity:IsActiveEnemy() then
        -- We can get the player
        local player = effect.Parent:ToPlayer()
        if player then
            -- Set the last damaged enemy to the hit enemy
            LastDamagedEnemy(player, entity)
            -- Update the mark
            UpdateEnemyMark(player, true)
            -- Apply appropriate tear effects to the entity
            ARAOI.MiscUtils.DamageWithTearEffects(player,entity,effect.HitPoints,effect,nil,nil,nil,player:GetCollectibleRNG(ARAOI.CollectibleType.KATANA))
        end
    -- If the entity is a pickup that is not being sold in the shop
    elseif (entity.Type == EntityType.ENTITY_PICKUP and not entity:ToPickup():IsShopItem()) then
        -- If the pickup is not a collectible
        if entity.Variant ~= 100 then
            -- Collide with the pickup
            effect.Parent:ForceCollide(entity, false)
        end
    end
end
ARAOI:AddCallback(ARAOI.ModCallbacks.WooshEntityCollided, ARAOI._OnKatanaWooshEntityCollision)

-- Function responsible for updating the mark and spawning the slashes
function ARAOI:_OnKatanaUpdate()
    for _, player in ipairs(ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.KATANA)) do
        -- Update the enemy mark
        UpdateEnemyMark(player)

        -- Updating the slash cooldown
        local playerFireDelay = FireDelay(player)
        if playerFireDelay > 0 then
            FireDelay(player, playerFireDelay - 1)
        end

        -- If we are not pressing a fire button or we are dead, end here
        if (ARAOI.PlayerUtils.GetCurrentShootingDirection(player) == ARAOI.PlayerUtils.FireDirection.NONE) or player:IsDead() then return end

        -- If the cooldown ended
        if playerFireDelay <= 0 then
            -- Get the shooting direction
            local direction = Vector.FromAngle(90 * ARAOI.PlayerUtils.GetCurrentShootingDirection(player))

            -- Spawn a slash
            local swing = ARAOI.PlayerUtils.FireMelee(player, player:GetTearHitParams(player:GetWeapon(1):GetWeaponType()).TearScale * 1.2, direction, false)
            swing.HitPoints = player.Damage * SWING_DAMAGE_MULTIPLIER

            -- Setting it's data so we can identify it later
            local swing_data = swing:GetData()
            swing_data["IsKatanaMelee"] = true

            -- Play a sound
            SFXManager():Play(SoundEffect.SOUND_TOOTH_AND_NAIL, 0.3, 3, nil, 2)

            -- Setting a cooldown
            FireDelay(player, player.MaxFireDelay)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnKatanaUpdate)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.KATANA,
        "# Isaac swings the Katana in the direction he shoots, doing {{Damage}} "..SWING_DAMAGE_MULTIPLIER.."x Isaac's damage"..
        "#{{BrimstoneCurse}} Swings mark the last enemy hit"..
        "#{{Timer}} Using the item gives Isaac a 1 second shield and teleports him behind the marked enemy, doing {{Damage}} "..TELEPORT_DAMAGE_MULTIPLIER.."x Isaac's damage to enemies in between"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "KATANA ABYSS SYNERGY",
        ARAOI.CollectibleType.KATANA,
        "Gray locust that does 3x damage"
    )
end)