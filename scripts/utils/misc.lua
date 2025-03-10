
---@class MiscUtils
local MiscUtils = {}

---@type TableUtils
local tableUtils = include("scripts.utils.table")

local game = Game()

-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isAngelItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_ANGEL or item_pool == ItemPoolType.POOL_GREED_ANGEL
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isBossItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_BOSS or item_pool == ItemPoolType.POOL_GREED_BOSS
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isCurseItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_CURSE or item_pool == ItemPoolType.POOL_GREED_CURSE
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isSecretItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_SECRET or item_pool == ItemPoolType.POOL_GREED_SECRET
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isShopItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_SHOP or item_pool == ItemPoolType.POOL_GREED_SHOP
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isTreasureItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_TREASURE or item_pool == ItemPoolType.POOL_GREED_TREASURE
end
-- This function returns true when checking for the normal item pool and its greed counterpart
---@param item_pool ItemPoolType | ItemPool
function MiscUtils.isDevilItemPool(item_pool)
    return item_pool == ItemPoolType.POOL_DEVIL or item_pool == ItemPoolType.POOL_GREED_DEVIL
end

---@param H integer -- *Number between 0 and 360*
---@param S? number -- *Default: `1` — Number between 0 and 1*
---@param L? number -- *Default: `0.5` — Number between 0 and 1*
function MiscUtils.HSLtoRGB(H, S, L)
    H = H % 360
    S = S or 1
    L = L or 0.5

    -- C = (1 - |2L - 1|) × S
    local C = (1 - math.abs(2 * L - 1)) * S

    -- X = C × (1 - |(H / 60°) mod 2 - 1|)
    local X = C * (1 - math.abs((H / 60) % 2 - 1))

    -- m = L - C/2
    local m = L - C / 2

    local Rp, Gp, Bp

    if H >= 0 and H < 60 then
        Rp, Gp, Bp = C, X, 0
    elseif H >= 60 and H < 120 then
        Rp, Gp, Bp = X, C, 0
    elseif H >= 120 and H < 180 then
        Rp, Gp, Bp = 0, C, X
    elseif H >= 180 and H < 240 then
        Rp, Gp, Bp = 0, X, C
    elseif H >= 240 and H < 300 then
        Rp, Gp, Bp = X, 0, C
    elseif H >= 300 and H < 360 then
        Rp, Gp, Bp = C, 0, X
    else
        Rp, Gp, Bp = 0, 0, 0
    end

    return (Rp + m) * 255, (Gp + m) * 255, (Bp + m) * 255
end

function MiscUtils.Lerp(A, B, t)
    return A + (B - A) * t
end

function MiscUtils.IsAnyReverseCardUnlocked()
    local PGD = Isaac.GetPersistentGameData()
    for i = Achievement.REVERSED_FOOL, Achievement.REVERSED_WORLD, 1 do
        if PGD:Unlocked(i) == true then
            return true
        end
    end
    return false
end

---@param pennies integer
---@return integer dimes
---@return integer nickels
---@return integer pennies
function MiscUtils.PenniesToCoins(pennies)
    local dimes = math.floor(pennies / 10)
    pennies = pennies - dimes * 10

    local nickels = math.floor(pennies / 5)
    pennies = pennies - nickels * 5

    return dimes, nickels, pennies
end

---@param pennies integer
---@param position? Vector -- Default: `Game():GetRoom():FindFreePickupSpawnPosition(Game():GetRoom():GetCenterPos())`
---@param velocityMult? number -- Default: `1`
function MiscUtils.DropCompactedCoins(pennies, position, velocityMult)
    if position == nil then position = Game():GetRoom():FindFreePickupSpawnPosition(Game():GetRoom():GetCenterPos()) end
    if velocityMult == nil then velocityMult = 1 end

    dimes, nickels, pennies = MiscUtils.PenniesToCoins(pennies)

    local coins = dimes + nickels + pennies

    local function DropCoin()
        if dimes > 0 then
            dimes = dimes - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DIME, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        elseif nickels > 0 then
            nickels = nickels - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        else
            pennies = pennies - 1
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, position, EntityPickup.GetRandomPickupVelocity(position) * velocityMult, nil)
        end
    end

    for _ = 1, coins do
        DropCoin()
    end
end

---@param player EntityPlayer
---@param enemy Entity
---@param damage? number -- Default: `player.Damage`
---@param source? Entity -- Default: `player`
---@param damageFlag? DamageFlag|integer -- Default: `DamageFlag.DAMAGE_COUNTDOWN`
---@param tearFlags? TearFlags -- Default: `player:GetTearHitParams(WeaponType.WEAPON_TEARS).TearFlags`
---@param rotation? number -- Default: `rng:PhantomInt(360)`
---@param rng? RNG -- Default: `math.random(999999999999)`
---@param effectDuration? integer -- Default: `75`
function MiscUtils.DamageWithTearEffects(player, enemy, damage, source, damageFlag, tearFlags, rotation, rng, effectDuration)
    damage = damage or player.Damage
    source = source or player
    damageFlag = damageFlag or DamageFlag.DAMAGE_COUNTDOWN
    tearFlags = tearFlags or player:GetTearHitParams(WeaponType.WEAPON_TEARS).TearFlags
    rng = rng or RNG(math.random(999999999999))
    rotation = rotation or rng:RandomInt(360)
    effectDuration = effectDuration or 75

    local reference = EntityRef(source)

    if not (damageFlag & DamageFlag.DAMAGE_FAKE > 0) then
        enemy:TakeDamage(damage, damageFlag, reference, 0)
    end

    -- Function that checks if the enemy would die, since the damage dealt doesn't immediately update
    local function EnemyWouldDie()
        return (enemy.HitPoints - damage) <= 0 and not enemy:IsDead()
    end

    -- Apply some effects based on each tear flag
    if tearFlags & TearFlags.TEAR_SLOW > 0 then
        enemy:AddSlowing(reference, 60, 0.513, Color(2, 2, 2, 1, 0.196, 0.196, 0.196))
    end
    if tearFlags & TearFlags.TEAR_POISON > 0 then
        enemy:AddPoison(reference, 30, damage)
    end
    if tearFlags & TearFlags.TEAR_FREEZE > 0 then
        enemy:AddFreeze(reference, 30)
    end
    if tearFlags & TearFlags.TEAR_MULLIGAN > 0 then
        player:AddBlueFlies(1, player.Position, enemy)
    end
    if tearFlags & TearFlags.TEAR_EXPLOSIVE > 0 then
        Isaac.Explode(enemy.Position, enemy, damage)
    end
    if tearFlags & TearFlags.TEAR_CHARM > 0 then
        enemy:AddCharmed(reference, 150)
    end
    if tearFlags & TearFlags.TEAR_CONFUSION > 0 then
        enemy:AddConfusion(reference, 120, true)
    end
    if tearFlags & TearFlags.TEAR_HP_DROP > 0 and EnemyWouldDie() then
        if rng:RandomFloat() < 0.33 then
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, player.Position, Vector.Zero, player)
        end
    end
    if tearFlags & TearFlags.TEAR_FEAR > 0 then
        enemy:AddFear(reference, 150)
    end
    if tearFlags & TearFlags.TEAR_BURN > 0 then
        enemy:AddBurn(reference, 30, damage)
    end
    if tearFlags & TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP > 0 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_GREEN, 0, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_LIGHT_FROM_HEAVEN > 0 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_COIN_DROP > 0 then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_BLACK_HP_DROP > 0 and EnemyWouldDie() then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_EGG > 0 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_WHITE, 0, enemy.Position, Vector.Zero, player)
        if rng:RandomFloat() <= 0.5 then
            player:AddBlueSpider(player.Position)
        else
            player:AddBlueFlies(1, player.Position, player)
        end
    end
    if tearFlags & TearFlags.TEAR_PUNCH > 0 then
        enemy:AddKnockback(reference, Vector.FromAngle(rotation) * 30, effectDuration, true)
        SFXManager():Play(SoundEffect.SOUND_PUNCH)
    end
    if tearFlags & TearFlags.TEAR_ICE > 0 then
        enemy:AddIce(reference, effectDuration)
    end
    if tearFlags & TearFlags.TEAR_MAGNETIZE > 0 then
        enemy:AddMagnetized(reference, effectDuration)
    end
    if tearFlags & TearFlags.TEAR_BAIT > 0 then
        enemy:AddBaited(reference, 150)
    end
    if tearFlags & TearFlags.TEAR_BLOOD_BOMB > 0 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_COIN_DROP_DEATH > 0 and EnemyWouldDie() then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, enemy.Position, Vector.Zero, player)
    end
    if tearFlags & TearFlags.TEAR_RIFT > 0 then
        local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0, enemy.Position, Vector.Zero, player):ToEffect()
        assert(rift)
        rift.SpriteScale = source.SpriteScale
        rift.CollisionDamage = damage
        rift:SetTimeout(90)
    end
    if tearFlags & TearFlags.TEAR_BACKSTAB > 0 and rng:RandomFloat() <= 0.2 then
        enemy:SetBleedingCountdown(0)
        enemy:AddBleeding(reference, 150)
        enemy:TakeDamage(damage, DamageFlag.DAMAGE_IGNORE_ARMOR, reference, 0)
        SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS)
    end
    if tearFlags & TearFlags.TEAR_CARD_DROP_DEATH > 0 and EnemyWouldDie() then
        local card = ItemPool:GetCardEx(rng:GetSeed(), 0, 0, 0, false)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, card, enemy.Position, Vector.Zero, nil)
    end
    if tearFlags & TearFlags.TEAR_RUNE_DROP_DEATH > 0 and EnemyWouldDie() then
        local rune = ItemPool:GetCard(rng:GetSeed(), false, true, true)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, rune, enemy.Position, Vector.Zero, nil)
    end
end

---@param position Vector
---@param damage? number -- The damage of the attack
---@param mirrored? boolean -- Should the attack animation be mirrored
---@param sizeMultiplier? number -- Size of the attack
---@param rotation? number -- Rotation of the attack
---@param spriteOffset? Vector -- The offset of the attack's sprite
---@param playSound? boolean -- Should the attack play the sound when spawning
function MiscUtils.SpawnMeleeWoosh(position, mirrored, damage, sizeMultiplier, rotation, spriteOffset, playSound)
    damage = damage or 0
    mirrored = mirrored or false
    sizeMultiplier = sizeMultiplier or 1
    rotation = rotation or 0
    spriteOffset = spriteOffset or Vector.Zero
    if playSound == nil then playSound = true end

    local woosh = Isaac.Spawn(1000, 202, 0, position, Vector.Zero, nil):ToEffect()
    assert(woosh)
    woosh.HitPoints = damage or 0

    local sprite = woosh:GetSprite()
    sprite.Rotation = rotation

    sprite.Scale = Vector(sizeMultiplier, sizeMultiplier) or Vector.One
    sprite.Offset = spriteOffset or Vector.Zero
    sprite.FlipX = mirrored

    if playSound ~= false then
        SFXManager():Play(SoundEffect.SOUND_SHELLGAME, nil, nil, nil, 1 - (1 - sizeMultiplier) * -0.3)
    end

    return woosh
end

---@param effect EntityEffect
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (_, effect)
    if not effect:GetSprite():IsFinished() then
        local data = effect:GetData()
        local offset = Vector(0, 27 * effect:GetSprite().Scale.X):Rotated(effect:GetSprite().Rotation)
        local radius = 30 * effect:GetSprite().Scale.X

        for _, enemy in ipairs(Isaac.FindInRadius(effect.Position + offset, radius)) do
            if (enemy.Type ~= EntityType.ENTITY_PLAYER or enemy.Type ~= EntityType.ENTITY_FAMILIAR
            or enemy:GetCharmedCountdown() < 0)
            and enemy:IsVulnerableEnemy()
            and not ARAOI.TableUtils.IsValueInTable(enemy.InitSeed, data) then
                table.insert(data, enemy.InitSeed)
                if effect.Parent.Type == EntityType.ENTITY_PLAYER then
                    local player = effect.Parent:ToPlayer()
                    if player then
                        enemy:TakeDamage(effect.HitPoints, 0, EntityRef(effect), 300)
                        Isaac.RunCallback("ARAOI MELEE WOOSH ENTITY DAMAGED", effect, enemy)
                    end
                end
            end
        end
    else
        effect:Remove()
    end
end, Isaac.GetEntityVariantByName("Melee Woosh"))

-- This function was directly copied from [The Official API](https://wofsauge.github.io/IsaacDocs/rep/Room.html#getdevilroomchance),
-- I changed the anyPlayerHasCollectible and anyPlayerHasTrinket functions with the Repentogon functions
---@return number DevilChance, number AngelChance
function MiscUtils.getDevilAngelRoomChance()
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local totalChance = math.min(room:GetDevilRoomChance(), 1.0)

    local angelRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_FAMINE_SPAWNED) -- repurposed
    local devilRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_SPAWNED)
    local devilRoomVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED)

    local devilRoomChance = 1.0
    if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_EUCHARIST) then
        devilRoomChance = 0.0
    elseif devilRoomSpawned and devilRoomVisited and game:GetDevilRoomDeals() > 0 then -- devil deals locked in
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or
        PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION) or
            level:GetAngelRoomChance() > 0.0 -- confessional, sac room
        then
            devilRoomChance = 0.5
        end
    elseif devilRoomSpawned or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or level:GetAngelRoomChance() > 0.0 then
        if not (devilRoomVisited or angelRoomSpawned) then
            devilRoomChance = 0.0
        else
            devilRoomChance = 0.5
        end
    end

    -- https://bindingofisaacrebirth.fandom.com/wiki/Angel_Room#Angel_Room_Generation_Chance
    if devilRoomChance == 0.5 then
        if PlayerManager.AnyoneHasTrinket(TrinketType.TRINKET_ROSARY_BEAD) then
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if game:GetDonationModAngel() >= 10 then -- donate 10 coins
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 - 0.1)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 + 0.1)
        end
        if level:GetAngelRoomChance() > 0.0 or
            (level:GetAngelRoomChance() < 0.0 and (PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION)))
        then
            devilRoomChance = devilRoomChance * (1.0 - level:GetAngelRoomChance())
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        devilRoomChance = math.max(0.0, math.min(devilRoomChance, 1.0))
    end

    local angelRoomChance = 1.0 - devilRoomChance
    return totalChance * devilRoomChance, totalChance * angelRoomChance
end

return MiscUtils