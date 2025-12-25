-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Vampire_Cloak = {}

local BAT_PARTICLE_ID = Isaac.GetEntityVariantByName("Bat Particle")
local WING_FLAPS = Isaac.GetSoundIdByName("wing_flaps")
-- local CloakSprite = Isaac.GetItemConfig():GetCollectible(ARAOI.CollectibleType.VAMPIRE_CLOAK):

local SFX = SFXManager()


---------------
-- VARIABLES --
---------------

---@type EntityEffect[]
local Bats = {}


---------------
-- FUNCTIONS --
---------------

-- Creates a bat particle that follows the player
---@param player EntityPlayer
---@param amount integer
---@param offset number
---@param poof? boolean
function ARAOI.Vampire_Cloak.AddBatParticles(player, amount, offset, poof)
    for _ = 1, amount do
        local bat = Isaac.Spawn(
            1000, BAT_PARTICLE_ID, 0,
            player.Position + Vector(math.random(-offset, offset), math.random(-offset, offset)),
            Vector.Zero, player
        ):ToEffect()
        assert(bat)
        bat:SetTimeout(35)
        bat.RenderZOffset = 10000000

        table.insert(Bats, bat)

        if poof then
            local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 1, bat.Position, Vector.Zero, nil):ToEffect()
            assert(effect)
            effect:GetSprite().Color:SetTint(0.2, 0.2, 0.2, 1)
        end

        local trail = Isaac.Spawn(1000, EffectVariant.SPRITE_TRAIL, 0, bat.Position, Vector.Zero, bat):ToEffect()
        assert(trail)
        trail:FollowParent(bat)
        trail:GetSprite().Color:SetTint(0.2, 0.1, 0.1, 0.6)
    end
end


local CloakInvincibility = {}

-- Checks if the player has invincibility
---@param player EntityPlayer
---@param set? boolean
function ARAOI.Vampire_Cloak.PlayerHasInvincibility(player, set)
    if set ~= nil then
        CloakInvincibility[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return CloakInvincibility[ARAOI.PlayerUtils.GetId(player)] or false
    -- return ARAOI.SaveDataManager:Key(CloakInvincibility, ARAOI.PlayerUtils.GetID(player), false, set)
end


-- Checks if the player has a Vampire Cloak charge
---@param player EntityPlayer
---@param set? boolean
function ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player, set)
    if not player:HasCollectible(ARAOI.CollectibleType.VAMPIRE_CLOAK) then return false end

    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "Vampire Cloak Charge", {}, ARAOI.PlayerUtils.GetId(player), true, set)
end
function ARAOI:_OnVampireCloakRemoveInvincibility(playerId)
    CloakInvincibility[playerId] = false
end
ARAOI:AddCallback("Remove Vampire Cloak Invincibility", ARAOI._OnVampireCloakRemoveInvincibility)



--------------------
-- DAMAGE BLOCKER --
--------------------

---@param player EntityPlayer
---@param damageFlags DamageFlag
function ARAOI:_OnVampireCloakPrePlayerTakeDamage(player, _, damageFlags, _)
    -- If the damage was self inflicted like Dull Razor,
    -- was because of the second player like Esau,
    -- was inflicted by IV Bag,
    -- bypassed the player's invincibility,
    -- the player still had cooldown when he was damaged,
    -- has the holy mantle effect,
    -- or the player doesn't have our item.
    -- We let the game handle the damage.
    if damageFlags & DamageFlag.DAMAGE_FAKE > 0
    or damageFlags & DamageFlag.DAMAGE_CLONES > 0
    or damageFlags & DamageFlag.DAMAGE_IV_BAG > 0
    or damageFlags & DamageFlag.DAMAGE_INVINCIBLE > 0
    or player:GetDamageCooldown() > 0
    or player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
    or not ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player)
    then return end

    -- Otherwise:

    -- Play some sounds for feedback
    SFX:Play(SoundEffect.SOUND_BLACK_POOF, 1, nil, nil, 2)
    SFX:Play(WING_FLAPS, 5, 0)

    -- Add some bat particles
    ARAOI.Vampire_Cloak.AddBatParticles(player, 20, 20)

    -- Set the player's damage cooldown, during the cooldown, the player can not take damage
    player:SetMinDamageCooldown(90)

    -- Revoke the item's charge and add invincibility to the player
    ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player, false)
    ARAOI.Vampire_Cloak.PlayerHasInvincibility(player, true)

    -- Create a timer that will later revoke the invincibility
    ARAOI.SaveDataManager:CreateTimerInFrames("Remove Vampire Cloak Invincibility", 45, ARAOI.PlayerUtils.GetId(player))

    -- This will cause the player to not take damage
    return false
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, ARAOI._OnVampireCloakPrePlayerTakeDamage)


-----------------------
-- COLLISION HANDLER --
-----------------------

---@param player EntityPlayer
---@param collider Entity
function ARAOI:_OnVampireCloakPrePlayerCollision(player, collider)
    -- Do we have our item,
    -- the entity we collided with was a pickup,
    -- the variant was a heart,
    -- the subtype was one of the red heart types,
    -- and our item is discrarged?
    local pickup = collider:ToPickup()
    if player:HasCollectible(ARAOI.CollectibleType.VAMPIRE_CLOAK)
    and pickup
    and pickup.Variant == PickupVariant.PICKUP_HEART
    and (pickup.SubType == HeartSubType.HEART_FULL or pickup.SubType == HeartSubType.HEART_HALF or pickup.SubType == HeartSubType.HEART_DOUBLEPACK)
    and not ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player) then
        -- Add a wait to the pickup to prevent the player from picking it up
        pickup.Wait = 5

        -- Remove the pickup
        pickup:Remove()

        -- Add a charge to our item
        ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player, true)

        -- Add a bat for visual feedback
        ARAOI.Vampire_Cloak.AddBatParticles(player, 1, 0, true)

        -- Play a sound for audio feedback
        SFX:Play(SoundEffect.SOUND_VAMP_GULP)

        -- End the execution here, as the rest is only for enemies
        return
    end

    -- The entity we collided with was an enemy, and we are currently invincible?
    if collider:IsEnemy() and ARAOI.Vampire_Cloak.PlayerHasInvincibility(player) then
        -- Do not handle the collision, this will allow us to pass through the enemies
        -- Kind of weird to return true, would make more sense to return false
        return true
    end
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, ARAOI._OnVampireCloakPrePlayerCollision)


-----------------
-- BAT UPDATER --
-----------------

function ARAOI:_OnVampireCloakUpdate()
    -- Function to avoid copy-pasting
    local function batDistanceToSpawner(bat)
        return (bat.SpawnerEntity.Position - Vector(0, 20)):Distance(bat.Position)
    end

    -- For every bat in our list of spawned bats
    for _, bat in ipairs(Bats) do
        -- If the bat actually exists
        if bat ~= nil then
            -- If the entity which spawned the bat exists
            if bat.SpawnerEntity then
                -- Try to convert the spawner entity into a player
                local player = bat.SpawnerEntity:ToPlayer()
                if player then
                    -- If the bat is too far away, that means it's out of control.
                    if batDistanceToSpawner(bat) > 100 then
                        -- Reset the velocity
                        bat.Velocity = Vector.Zero
                    end

                    -- Add some velocity towards the player
                    bat:AddVelocity((bat.SpawnerEntity.Position - Vector(0, 20) - bat.Position):Normalized() * 10)

                    -- If we have the item charged and the bat's timeout didn't tick down
                    if ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player) and bat.Timeout > 30 then
                        -- Make the bat slow, as this means that the bat was spawned while we still have a charge
                        -- meaning, this is the "item charged" bat
                        bat.Velocity = bat.Velocity:Normalized() * 5

                        -- If we got too close to the player
                        if batDistanceToSpawner(bat) < 30 then
                            -- Reset the velocity
                            bat.Velocity = Vector.Zero
                        end

                        -- Reset the timeout
                        bat.Timeout = 35

                        -- Check the next bat
                        goto continue

                    -- If we don't have the item charged and the timeout didn't tick down
                    elseif not ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player) and bat.Timeout > 30 then
                        -- We force the bat to start ticking down
                        bat.Timeout = 30
                    end

                end
            end

            -- If the bat's timeout reached 0
            if bat.Timeout <= 0 then
                -- Remove the spawner entity, which will make the bats go in a straight line
                bat.SpawnerEntity = nil

                -- Make the bat transparent
                -- This will eventually stack and make the bat invisible
                bat:GetSprite().Color.A = bat:GetSprite().Color.A - 0.05
            end

            -- If the bat is no longer visible
            if bat:GetSprite().Color.A <= 0 then
                -- We remove the bat
                bat:Remove()
            end
        end
        ::continue::
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnVampireCloakUpdate)


------------------
-- BAT RESETTER --
------------------

function ARAOI:_OnVampireCloakNewRoom()
    -- Reset the bat list
    Bats = {}

    -- For each player with our item
    for _, player in ipairs(ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.VAMPIRE_CLOAK)) do
        -- If the player has a charge
        if ARAOI.Vampire_Cloak.PlayerHasVampireCloakCharge(player) then
            -- Spawn a bat as an indicator
            ARAOI.Vampire_Cloak.AddBatParticles(player, 1, 0)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnVampireCloakNewRoom)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.VAMPIRE_CLOAK,
        "# Negates the next hit taken"..
        "#{{Heart}} Requires Red Heart pickups to recharge"..
        "#{{Collectible"..(CollectibleType.COLLECTIBLE_HOLY_MANTLE).."}} Holy Mantle has priority"
    )
end)