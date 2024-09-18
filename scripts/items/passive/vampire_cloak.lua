-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------





---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")


---------------
-- CONSTANTS --
---------------

local VAMPIRE_CLOAK = Isaac.GetItemIdByName("Vampire Cloak")
local BAT_PARTICLE_ID = Isaac.GetEntityVariantByName("Bat Particle")
local WING_FLAPS = Isaac.GetSoundIdByName("wing_flaps")


---------------
-- VARIABLES --
---------------

---@type EntityEffect[]
local Bats = {}


---------------
-- FUNCTIONS --
---------------

---@param player EntityPlayer
---@param amount integer
---@param offset number
local function addBats(player, amount, offset)
    for _ = 1, amount do
        local bat = Isaac.Spawn(
            1000, BAT_PARTICLE_ID, 0,
            player.Position + Vector(math.random(-offset, offset), math.random(-offset, offset)),
            Vector.Zero, player
        ):ToEffect()
        bat:SetTimeout(35)
        bat.Color.R = 1
        bat.RenderZOffset = 10000000

        table.insert(Bats, bat)
    end
end

local CloakInvincibility = {}

---@param player EntityPlayer
---@param set? boolean
local function playerHasInvincibility(player, set)
    return SaveData:Key(CloakInvincibility, helper.player.GetID(player), false, set)
end

---@param player EntityPlayer
---@param set? boolean
local function playerHasVampireCloakCharge(player, set)
    if not player:HasCollectible(VAMPIRE_CLOAK) then return false end

    return SaveData:Data(SaveData.RUN, "Vampire Cloak Charge", {}, helper.player.GetID(player), true, set)
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local SFX = SFXManager()


    --------------------
    -- DAMAGE BLOCKER --
    --------------------

    ---@param player EntityPlayer
    ---@param damageFlags DamageFlag
    Mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player, _, damageFlags, _)
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
        or not playerHasVampireCloakCharge(player)
        then return end

        -- Otherwise:

        -- Play some sounds for feedback
        SFX:Play(SoundEffect.SOUND_BLACK_POOF, 1, nil, nil, 2)
        SFX:Play(WING_FLAPS, 5, 0)

        -- Add some bat particles
        addBats(player, 20, 20)

        -- Set the player's damage cooldown, during the cooldown, the player can not take damage
        player:SetMinDamageCooldown(90)

        -- Revoke the item's charge and add invincibility to the player
        playerHasVampireCloakCharge(player, false)
        playerHasInvincibility(player, true)

        -- Create a timer that will later revoke the invincibility
        SaveData:CreateTimerInFrames("Remove Vampire Cloak Invincibility", 45, {helper.player.GetID(player)})

        -- This will cause the player to not take damage
        return false
    end)

    Mod:AddCallback("Remove Vampire Cloak Invincibility", function (_, playerID)
        playerHasInvincibility(playerID, false)
    end)


    -----------------------
    -- COLLISION HANDLER --
    -----------------------

    ---@param player EntityPlayer
    ---@param collider Entity
    Mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function (_, player, collider)
        -- Do we have our item,
        -- the entity we collided with was a pickup,
        -- the variant was a heart,
        -- the subtype was one of the red heart types,
        -- and our item is discrarged?
        local pickup = collider:ToPickup()
        if player:HasCollectible(VAMPIRE_CLOAK)
        and pickup
        and pickup.Variant == PickupVariant.PICKUP_HEART
        and (pickup.SubType == HeartSubType.HEART_FULL or pickup.SubType == HeartSubType.HEART_HALF or pickup.SubType == HeartSubType.HEART_DOUBLEPACK)
        and not playerHasVampireCloakCharge(player) then
            -- Add a wait to the pickup to prevent the player from picking it up
            pickup.Wait = 5

            -- Remove the pickup
            pickup:Remove()

            -- Add a charge to our item
            playerHasVampireCloakCharge(player, true)

            -- Add a bat for visual feedback
            addBats(player, 1, 0)

            -- Play a sound for audio feedback
            SFX:Play(SoundEffect.SOUND_VAMP_GULP)

            -- End the execution here, as the rest is only for enemies
            return
        end

        -- The entity we collided with was an enemy, and we are currently invincible?
        if collider:IsEnemy() and playerHasInvincibility(player) then
            -- Do not handle the collision, this will allow us to pass through the enemies
            -- Kind of weird to return true, would make more sense to return false
            return true
        end
    end)


    -----------------
    -- BAT UPDATER --
    -----------------

    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
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
                        if playerHasVampireCloakCharge(player) and bat.Timeout > 30 then
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
                        elseif not playerHasVampireCloakCharge(player) and bat.Timeout > 30 then
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
    end)


    ------------------
    -- BAT RESETTER --
    ------------------

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
        -- Reset the bat list
        Bats = {}

        -- For each player with our item
        for _, player in ipairs(helper.player.GetPlayersWithCollectible(VAMPIRE_CLOAK)) do
            -- If the player has a charge
            if playerHasVampireCloakCharge(player) then
                -- Spawn a bat as an indicator
                addBats(player, 1, 0)
            end
        end
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(VAMPIRE_CLOAK, 
            "# Negates the first hit taken once per room and will ignore enemy collision"..
            "#{{Heart}} Requires Red Heart pickups to recharge"..
            "#{{Collectible"..(CollectibleType.COLLECTIBLE_HOLY_MANTLE).."}} Holy Mantle will get used first"
        )
    end
end

return modded_item