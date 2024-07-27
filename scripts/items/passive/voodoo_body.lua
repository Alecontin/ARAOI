----------------------------
-- START OF CONFIGURATION --
----------------------------



local DAMAGE_SCALE  = 0.35 -- *Default: `0.35` — The number that the player's damage will be multiplied by when doing damage with the pin.*
local VOODOO_HEAD_ADD = 0.15 -- *Default: `0.20` — The number that will be added to the `DAMAGE_SCALE` when the player is holding Voodoo Head.*



--------------------------
-- END OF CONFIGURATION --
--------------------------






---@class Helper
local Helper = include("scripts.Helper")

local voodoo_body = Isaac.GetItemIdByName("Voodoo Body")
local curse_pin = Isaac.GetEntityVariantByName("Curse Pin")

---@param attack Entity
---@param spawner Entity
---@param damage number
---@param spriteScale? number
---@param effects? TearFlags
local function SpawnPin(attack, spawner, damage, spriteScale, effects)
    local pin = Isaac.Spawn(EntityType.ENTITY_EFFECT, curse_pin, 0, attack.Position, Vector.Zero, spawner):ToEffect()

    pin:SetTimeout(20)
    pin:FollowParent(attack)
    pin.MaxHitPoints = damage
    pin:GetSprite().Rotation = math.random(360)
    pin:GetSprite().Scale = Vector(spriteScale or 0.75, spriteScale or 0.75)
    pin:GetData()["TearEffects"] = effects

    return pin
end

---@param player EntityPlayer
local function GetDamageScale(player)
    local damage_scale = DAMAGE_SCALE
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD) then damage_scale = damage_scale + VOODOO_HEAD_ADD end

    return damage_scale
end


local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local sfx = SFXManager()
    local ItemPool = game:GetItemPool()

    ---@param entity Entity
    ---@param damage number
    ---@param source EntityRef
    Mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, function (_, entity, damage, _, source)
        -- If the enemy we damaged is an active enemy and the source is also an entity that exists
        if not (entity:IsActiveEnemy() and entity:IsVulnerableEnemy()) then return end
        if not source.Entity then return end

        -- Get the player from the reference, check if it exists, and check if they have our item
        local player = Helper.EntityRefToPlayer(source)
        if not player or not player:HasCollectible(voodoo_body) then return end

        -- Get the tear and it's scale
        local tear = source.Entity:ToTear()
        local scale

        -- Get the tear flags for tear effects
        local flags

        -- If the source entity was a tear then
        if tear then
            -- Set the parameters to the tear ones
            scale = tear.Scale
            flags = tear.TearFlags
        else
            -- Else, set the parameters to the player's tear parameters
            local params = player:GetTearHitParams(player:GetWeapon(1):GetWeaponType())
            flags = params.TearFlags
            scale = params.TearScale
        end

        -- If there are no flags, something went wrong, we return
        if flags == nil then return end

        -- Get the rng for later
        local rng = player:GetCollectibleRNG(voodoo_body)


        -- Delcare the list of enemies in the room
        ---@type Entity[]
        local enemies = {}

        -- For every entity in the room
        for _, v in ipairs(Isaac.GetRoomEntities()) do
            -- Check if the entity is an active enemy that is able to be damaged
            if v:IsActiveEnemy() and v:IsVulnerableEnemy() then

                -- Insert it to the list of enemies
                table.insert(enemies, v)
            end
        end


        -- Get a random enemy from the list
        ---@type Entity
        local random_enemy = Helper.Choice(enemies, nil, rng)
        if not random_enemy then return end

        -- Get the damage sale
        local damage_scale = GetDamageScale(player)

        -- Multiply the damage by the damage scale
        damage = damage * damage_scale

        -- Get the effect's scale
        local sprite_scale = math.max(scale * damage_scale, 0.3)

        -- Spawn the effect
        local pin = SpawnPin(random_enemy, player, damage, sprite_scale, flags)

        -- Offset the effect if the enemy is in the air
        if random_enemy:IsFlying() then
            pin.SpriteOffset = Vector(0, -17)
        end
    end)

    ---@param effect EntityEffect
    Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (_, effect)
        if effect.SpawnerEntity then
            local player = effect.SpawnerEntity:ToPlayer()
            if not player then goto skip end

            if player:HasCollectible(CollectibleType.COLLECTIBLE_ANTI_GRAVITY)
            and player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_SHOOTING > 0
            and effect.Timeout >= 19 then
                effect:SetTimeout(20)
                effect:GetSprite():SetFrame(1)
            end

            ::skip::
        end

        -- Check if the effect triggered the event
        if effect:GetSprite():IsEventTriggered("Blood") then
            -- Check if we are still attached to an enemy
            if effect.Parent then
                -- Spawn some effects
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, effect.Position, Vector.Zero, nil)
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, effect.Position, Vector.Zero, nil)

                -- Set some data
                local sprite = effect:GetSprite()
                local scale = sprite.Scale.X
                local damage = effect.MaxHitPoints
                local enemy = effect.Parent
                local eref = EntityRef(effect)

                -- Check if we have some custom effects set
                local customEffects = effect:GetData()["TearEffects"]

                -- Check if we are still attached to an enemy, I was having some issues before
                if not effect.Parent then goto skip end

                -- Damage the enemy
                enemy:TakeDamage(damage, DamageFlag.DAMAGE_IGNORE_ARMOR, eref, 0)

                -- Check if we were spawned by a player
                if not effect.SpawnerEntity then goto skip end
                local player = effect.SpawnerEntity:ToPlayer()
                if not player then goto skip end

                -- Get the RNG
                local rng = RNG(effect.InitSeed)

                -- Set the global effect duration
                local effectDuration = 75

                -- Get the tear flags, preferably the custom ones
                local flags = customEffects or player:GetTearHitParams(WeaponType.WEAPON_TEARS, nil, nil, player).TearFlags

                -- Get a reference to the player
                local pref = EntityRef(player)

                -- Item-specifig synergies
                if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
                    enemy:AddBrimstoneMark(pref, 150)
                end

                local function playerHasDrFetus()
                    return (player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS))
                end

                if playerHasDrFetus() and not (flags & TearFlags.TEAR_EXPLOSIVE > 0) then
                    flags = flags | TearFlags.TEAR_EXPLOSIVE
                end

                -- Apply some effects based on each tear flag
                if flags & TearFlags.TEAR_SLOW > 0 then
                    enemy:AddSlowing(eref, 60, 0.513, Color(2, 2, 2, 1, 0.196, 0.196, 0.196))
                end
                if flags & TearFlags.TEAR_POISON > 0 then
                    enemy:AddPoison(eref, 30, damage)
                end
                if flags & TearFlags.TEAR_FREEZE > 0 then
                    enemy:AddFreeze(eref, 30)
                end
                if flags & TearFlags.TEAR_MULLIGAN > 0 then
                    player:AddBlueFlies(1, player.Position, enemy)
                end
                if flags & TearFlags.TEAR_EXPLOSIVE > 0 then
                    Isaac.Explode(enemy.Position, effect, damage)
                end
                if flags & TearFlags.TEAR_CHARM > 0 then
                    enemy:AddCharmed(eref, 150)
                end
                if flags & TearFlags.TEAR_CONFUSION > 0 then
                    enemy:AddConfusion(eref, 120, true)
                end
                if flags & TearFlags.TEAR_HP_DROP > 0 then
                    if rng:RandomFloat() < 0.33 then
                        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, player.Position, Vector.Zero, player)
                    end
                end
                if flags & TearFlags.TEAR_FEAR > 0 then
                    enemy:AddFear(eref, 150)
                end
                if flags & TearFlags.TEAR_BURN > 0 then
                    enemy:AddBurn(eref, 30, damage)
                end
                if flags & TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP > 0 then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_GREEN, 0, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_LIGHT_FROM_HEAVEN > 0 then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_COIN_DROP > 0 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_BLACK_HP_DROP > 0 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_EGG > 0 then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_WHITE, 0, enemy.Position, Vector.Zero, player)
                    if rng:RandomFloat() <= 0.5 then
                        player:AddBlueSpider(player.Position)
                    else
                        player:AddBlueFlies(1, player.Position, player)
                    end
                end
                if flags & TearFlags.TEAR_PUNCH > 0 then
                    enemy:AddKnockback(eref, Vector.FromAngle(effect:GetSprite().Rotation + 90) * 30, effectDuration, true)
                    sfx:Play(SoundEffect.SOUND_PUNCH)
                end
                if flags & TearFlags.TEAR_ICE > 0 then
                    enemy:AddIce(eref, effectDuration)
                end
                if flags & TearFlags.TEAR_MAGNETIZE > 0 then
                    enemy:AddMagnetized(eref, effectDuration)
                end
                if flags & TearFlags.TEAR_BAIT > 0 then
                    enemy:AddBaited(eref, 150)
                end
                if flags & TearFlags.TEAR_BLOOD_BOMB > 0 then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_COIN_DROP_DEATH > 0 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, enemy.Position, Vector.Zero, player)
                end
                if flags & TearFlags.TEAR_RIFT > 0 then
                    local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0, enemy.Position, Vector.Zero, player):ToEffect()
                    rift.SpriteScale = effect.SpriteScale
                    rift.CollisionDamage = damage
                    rift:SetTimeout(90)
                end
                if flags & TearFlags.TEAR_BACKSTAB > 0 and rng:RandomFloat() <= 0.2 then
                    enemy:SetBleedingCountdown(0)
                    enemy:AddBleeding(eref, 150)
                    enemy:TakeDamage(damage, DamageFlag.DAMAGE_IGNORE_ARMOR, eref, 0)
                    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
                end


                if flags & TearFlags.TEAR_BURSTSPLIT > 0 then
                    for i = 1, rng:RandomInt(6, 11) do
                        Isaac.CreateTimer(function ()
                            SpawnPin(enemy, player, damage * (rng:RandomInt(5000,8333) / 10000), scale, flags ~ TearFlags.TEAR_BURSTSPLIT)
                        end, i, 1, false)
                    end
                elseif flags & TearFlags.TEAR_BONE > 0 then
                    for i = 1, rng:RandomInt(1, 3) do
                        Isaac.CreateTimer(function ()
                            SpawnPin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_BONE)
                        end, i, 1, false)
                    end
                elseif flags & TearFlags.TEAR_QUADSPLIT > 0 then
                    for i = 1, 4 do
                        Isaac.CreateTimer(function ()
                            SpawnPin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_QUADSPLIT)
                        end, i, 1, false)
                    end
                elseif flags & TearFlags.TEAR_SPLIT > 0 then
                    for i = 1, 2 do
                        Isaac.CreateTimer(function ()
                            SpawnPin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_SPLIT)
                        end, i, 1, false)
                    end
                end
            end

            -- Play the hit sound for some feedback
            ::skip::
            sfx:Play(SoundEffect.SOUND_POT_BREAK, 0.5, nil, nil, 2)
        end

        if effect.FrameCount == 1 then
            if not effect.SpawnerEntity then goto skip end
            local player = effect.SpawnerEntity:ToPlayer()
            if not player then goto skip end

            local customEffects = effect:GetData()["TearEffects"]

            local col = effect:GetSprite().Color

            local flags = customEffects or player:GetTearHitParams(WeaponType.WEAPON_TEARS, nil, nil, player).TearFlags

            -- Recolor the effect if it has a tear effect
            if flags & TearFlags.TEAR_SLOW > 0 then
                col:SetColorize(2, 2, 2, 1)
                col:SetOffset(0.196, 0.196, 0.196)
            end
            if flags & TearFlags.TEAR_POISON > 0 then
                col:SetColorize(0.4, 0.97, 0.5, 1)
            end
            if flags & TearFlags.TEAR_FREEZE > 0 then
                col:SetColorize(1.25, 0.05, 0.15, 1)
            end
            if flags & TearFlags.TEAR_SPLIT > 0 then
                col:SetColorize(0.9, 0.3, 0.08, 1)
            end
            if flags & TearFlags.TEAR_EXPLOSIVE > 0 then
                col:SetColorize(0.5, 0.9, 0.4, 1)
            end
            if flags & TearFlags.TEAR_CHARM > 0 then
                col:SetColorize(1, 0, 1, 1)
                col:SetOffset(0.196, 0, 0)
            end
            if flags & TearFlags.TEAR_CONFUSION > 0 then
                col:SetColorize(0.5, 0.5, 0.5, 1)
            end
            if flags & TearFlags.TEAR_FEAR > 0 then
                col:SetColorize(1, 1, 0.455, 1)
                col:SetOffset(0.169, 0.145, 0)
            end
            if flags & TearFlags.TEAR_BURN > 0 then
                col:SetColorize(1, 1, 1, 1)
                col:SetOffset(0.3, 0, 0)
            end
            if flags & TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP > 0 then
                col:SetColorize(1, 1, 1, 1)
                col:SetOffset(0, 0.2, 0)
            end
            if flags & TearFlags.TEAR_BAIT > 0 then
                col:SetColorize(0.7, 0.14, 0.1, 1)
                col:SetOffset(0.3, 0, 0)
            end
            if flags & TearFlags.TEAR_RIFT > 0 then
                col:SetColorize(0, 0, 0, 1)
            end


            ::skip::
        end

        -- Remove the effect when the timeout reaches 0
        if effect.Timeout <= 0 then
            effect:Remove()
        end
    end, curse_pin)

    ---@class EID
    if EID then
        EID:addCollectible(
            voodoo_body,
            "#{{BlackHeart}} +1 Black Heart"..
            "# Damaging an enemy will spawn a pin on a random enemy that deals {{Damage}} "..math.floor(DAMAGE_SCALE * 100).."% of the original damage and ignores armor"..
            "#{{Tearsize}} Pins copy the majority of Isaac's tear effects"..
            "#{{Collectible"..CollectibleType.COLLECTIBLE_VOODOO_HEAD.."}} If Isaac has Voodo Head, the pin will deal {{Damage}} "..math.floor((DAMAGE_SCALE+VOODOO_HEAD_ADD) * 100).."% damage instead"
        )
    end
end


return modded_item