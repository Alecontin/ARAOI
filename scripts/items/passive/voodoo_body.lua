local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.DAMAGE_SCALE    = 35 -- *Default: `35` — The number that the player's damage will be multiplied by when doing damage with the pin.*
Config.VOODOO_HEAD_ADD = 35 -- *Default: `35` — The number that will be added to the `DAMAGE_SCALE` when the player is holding Voodoo Head.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Voodoo_Body = {}
ARAOI.Voodoo_Body.Config = Config

local CURSE_PIN = Isaac.GetEntityVariantByName("Curse Pin")


---------------
-- FUNCTIONS --
---------------

-- Spawns a curse pin on the provided attacker
---@param attack Entity
---@param spawner Entity
---@param damage number
---@param spriteScale? number
---@param effects? TearFlags
function ARAOI.Voodoo_Body.SpawnCursePin(attack, spawner, damage, spriteScale, effects)
    local pin = Isaac.Spawn(EntityType.ENTITY_EFFECT, CURSE_PIN, 0, attack.Position + Vector(0, 0.1), Vector.Zero, spawner):ToEffect()
    assert(pin)

    pin:SetTimeout(20)
    pin:FollowParent(attack)
    pin.MaxHitPoints = damage
    pin:GetSprite().Rotation = math.random(360)
    pin:GetSprite().Scale = Vector(spriteScale or 0.75, spriteScale or 0.75)
    pin:GetData()["TearEffects"] = effects

    return pin
end

local function ColorizeEffect(effect)
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end

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
end

local function TryDamageParent(effect)
    -- Check if we are still attached to an enemy
    if effect.Parent then
        -- Check if we were spawned by a player
        if not effect.SpawnerEntity then return end
        local player = effect.SpawnerEntity:ToPlayer()
        if not player then return end

        -- Check if we are still attached to an enemy, I was having some issues before
        if not effect.Parent then return end

        -- Spawn some effects
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, effect.Position, Vector.Zero, nil)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, effect.Position, Vector.Zero, nil)

        -- Set some data
        local sprite = effect:GetSprite()
        local scale = sprite.Scale.X
        local damage = effect.MaxHitPoints
        local enemy = effect.Parent
        local rotation = effect:GetSprite().Rotation + 90

        -- Check if we have some custom effects set
        local customEffects = effect:GetData()["TearEffects"]

        -- Get the RNG
        local rng = RNG(effect.InitSeed)

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

        ARAOI.MiscUtils.DamageWithTearEffects(player, enemy, damage, effect, DamageFlag.DAMAGE_IGNORE_ARMOR, flags, rotation, rng)

        if flags & TearFlags.TEAR_BURSTSPLIT > 0 then
            for i = 1, rng:RandomInt(6, 11) do
                Isaac.CreateTimer(function ()
                    ARAOI.Voodoo_Body.SpawnCursePin(enemy, player, damage * (rng:RandomInt(5000,8333) / 10000), scale, flags ~ TearFlags.TEAR_BURSTSPLIT)
                end, i, 1, false)
            end
        elseif flags & TearFlags.TEAR_BONE > 0 then
            for i = 1, rng:RandomInt(1, 3) do
                Isaac.CreateTimer(function ()
                    ARAOI.Voodoo_Body.SpawnCursePin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_BONE)
                end, i, 1, false)
            end
        elseif flags & TearFlags.TEAR_QUADSPLIT > 0 then
            for i = 1, 4 do
                Isaac.CreateTimer(function ()
                    ARAOI.Voodoo_Body.SpawnCursePin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_QUADSPLIT)
                end, i, 1, false)
            end
        elseif flags & TearFlags.TEAR_SPLIT > 0 then
            for i = 1, 2 do
                Isaac.CreateTimer(function ()
                    ARAOI.Voodoo_Body.SpawnCursePin(enemy, player, damage / 2, scale, flags ~ TearFlags.TEAR_SPLIT)
                end, i, 1, false)
            end
        end
    end
end

---@param player EntityPlayer
local function getDamageScale(player)
    local damage_scale = Config.DAMAGE_SCALE/100
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD) then damage_scale = damage_scale + (Config.VOODOO_HEAD_ADD/ 100) end

    return damage_scale
end


---------------------
-- DAMAGE DETECTOR --
---------------------

---@param entity Entity
---@param damage number
---@param source EntityRef
function ARAOI:_OnVoodooBodyEntityTakeDamage(entity, damage, _, source)
    -- If the enemy we damaged is an active enemy and the source is also an entity that exists
    if not (entity:IsActiveEnemy() and entity:IsVulnerableEnemy()) then return end
    if not source.Entity then return end

    -- Initialize player and tear variables for later
    local player = nil
    local tear = nil

    -- Check if the entity that caused the damage was an abyss locust made from our item
    if source.Entity.Type == EntityType.ENTITY_FAMILIAR
    and source.Entity.Variant == FamiliarVariant.ABYSS_LOCUST
    and source.Entity.SubType == ARAOI.CollectibleType.VOODOO_BODY then
        -- Get the player that way, making sure it exists
        player = source.Entity.SpawnerEntity:ToPlayer()
        if not player then return end
    else
        -- Get the player from the reference, check if it exists, and check if they have our item
        player = ARAOI.PlayerUtils.FromEntityRef(source)
        if not player or not player:HasCollectible(ARAOI.CollectibleType.VOODOO_BODY) then return end

        -- Get the tear
        tear = source.Entity:ToTear()
    end

    -- Initialize scale and flags variables for later
    local scale
    local flags

    -- Check if we have a tear
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
    local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.VOODOO_BODY)


    -- Initialize the list of enemies in the room
    ---@type Entity[]
    local enemies = {}

    -- For every entity in the room
    for _, v in ipairs(Isaac.GetRoomEntities()) do
        -- Check if the entity is an active enemy that is able to be damaged
        if v:IsActiveEnemy() and v:IsVulnerableEnemy() and not v:HasMortalDamage() then

            -- Insert it to the list of enemies
            table.insert(enemies, v)
        end
    end


    -- Get a random enemy from the list
    ---@type Entity
    local random_enemy = ARAOI.TableUtils.Choice(enemies, nil, rng)
    if not random_enemy then return end

    -- Get the damage sale
    local damage_scale = getDamageScale(player)

    -- Multiply the damage by the damage scale
    damage = damage * damage_scale

    -- Get the effect's scale
    local sprite_scale = math.max(scale * damage_scale, 0.3)

    -- Spawn the effect
    local pin = ARAOI.Voodoo_Body.SpawnCursePin(random_enemy, player, damage, sprite_scale, flags)

    -- Offset the effect if the enemy is in the air
    if random_enemy:IsFlying() then
        pin.SpriteOffset = Vector(0, -17)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, ARAOI._OnVoodooBodyEntityTakeDamage)


----------------------------------------
-- CURSE PIN UPDATE AND DAMAGE DEALER --
----------------------------------------

---@param effect EntityEffect
function ARAOI:_OnVoodooBodyEffectUpdate(effect)
    local SFX = SFXManager()

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
        TryDamageParent(effect)
        SFX:Play(SoundEffect.SOUND_POT_BREAK, 0.5, nil, nil, 2)
    end

    if effect.FrameCount == 1 then
        ColorizeEffect(effect)
    end

    -- Remove the effect when the timeout reaches 0
    if effect.Timeout <= 0 then
        effect:Remove()
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, ARAOI._OnVoodooBodyEffectUpdate, CURSE_PIN)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(
        ARAOI.CollectibleType.VOODOO_BODY,
        "#{{BlackHeart}} +1 Black Heart"..
        "# Damaging an enemy will spawn a pin on a random enemy"..
        "# Pins deal {{Damage}} "..(Config.DAMAGE_SCALE).."% of the damage and ignore armor"..
        "#{{Tearsize}} Pins copy the majority of Isaac's tear effects"..
        "#{{Collectible"..CollectibleType.COLLECTIBLE_VOODOO_HEAD.."}} If Isaac has Voodo Head, the pins will deal {{Damage}} "..(Config.DAMAGE_SCALE + Config.VOODOO_HEAD_ADD).."% damage instead"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Voodoo Body Abyss Synergy",
        ARAOI.CollectibleType.VOODOO_BODY,
        "Gray locust that spawns pins on random enemies on hit"
    )
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Passives", "Voodoo Body")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Voodoo Body", Config, "DAMAGE_SCALE",
    ConfigDefaults, ConfigDefaults.DAMAGE_SCALE/100 .. "x", 0, 10000, 20, function ()
        return "Damage Scale: " .. Config.DAMAGE_SCALE/100 .. "x"
    end, "The damage scale of the pins spawned by Voodoo Body")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Voodoo Body", Config, "VOODOO_HEAD_ADD",
    ConfigDefaults, "+" .. ConfigDefaults.VOODOO_HEAD_ADD/100 .. "x", 0, 10000, 20, function ()
        return "Voodoo Head Damage Add: " .. "+" .. Config.VOODOO_HEAD_ADD/100 .. "x"
    end, "The damage added to the damage scale when the player has Voodoo Head")

    ARAOI.MCMUtils.AddReset("Passives", "Voodoo Body")
end