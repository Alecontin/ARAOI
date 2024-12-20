-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.ThreeD_Glasses = {}

---@class ColorEnum
ARAOI.ThreeD_Glasses.ColorEnum = {
    NO_ITEM = 0,
    RED = 1,
    BLUE = 2,
    toggle = function (col)
        if col == 1 then return 2 else return 1 end
    end
}

-- How much white is added to the color
local w = 0.3

local COLOR_RED = Color(1, w, w, 1)
local COLOR_BLUE = Color(w, w, 1, 1)
local COLOR_WHITE = Color(1, 1, 1, 1)


---------------
-- FUNCTIONS --
---------------

-- Gets/Sets the player's current color
---@param player EntityPlayer
---@param set? ColorEnum | integer
---@return ColorEnum
function ARAOI.ThreeD_Glasses.PlayerColorData(player, set)
    return ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "3D Glasses", {}, ARAOI.PlayerUtils.GetID(player), ARAOI.ThreeD_Glasses.ColorEnum.NO_ITEM, set)
end

-- Does the player have the 20/20 effect applied from the car battery synergy?
---@param player EntityPlayer
---@param set? boolean
---@return boolean
function ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player, set)
    return ARAOI.SaveData:Data(ARAOI.SaveData.ROOM, "3D Glasses 20/20", {}, ARAOI.PlayerUtils.GetID(player), false, set)
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

---@param collectibleType CollectibleType
---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function (_, collectibleType, _, _, _, _, player)
    if collectibleType ~= ARAOI.CollectibleType.THREED_GLASSES then return end

    -- Initialize the player's color to RED
    if ARAOI.ThreeD_Glasses.PlayerColorData(player) == ARAOI.ThreeD_Glasses.ColorEnum.NO_ITEM then
        ARAOI.ThreeD_Glasses.PlayerColorData(player, ARAOI.ThreeD_Glasses.ColorEnum.RED)
    end
end)


-----------------
-- ON ITEM USE --
-----------------

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

    -- If the player's color is red, switch it to blue and viceversa
    if ARAOI.ThreeD_Glasses.PlayerColorData(player) == ARAOI.ThreeD_Glasses.ColorEnum.RED then
        ARAOI.ThreeD_Glasses.PlayerColorData(player, ARAOI.ThreeD_Glasses.ColorEnum.BLUE)
    else
        ARAOI.ThreeD_Glasses.PlayerColorData(player, ARAOI.ThreeD_Glasses.ColorEnum.RED)
    end

    -- Show the item animation
    return true
end, ARAOI.CollectibleType.THREED_GLASSES)


-----------------
-- EVERY FRAME --
-----------------

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        local effects = player:GetEffects()

        -- Add the 20/20 Collectible Effect if the player has both the glasses and car battery
        if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
        and player:HasCollectible(ARAOI.CollectibleType.THREED_GLASSES)
        and not ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player)
        then
            -- Add the 20/20 effect
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_20_20)

            -- Register the 20/20 effect for the player
            -- We do this so we only remove it once later. After all, other mods could add their own 20/20 effect
            ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player, true)
        end

        -- Change the player's color
        if ARAOI.ThreeD_Glasses.PlayerColorData(player) == ARAOI.ThreeD_Glasses.ColorEnum.RED then
            player:SetColor(COLOR_RED, 999999, 1, true, true)
        elseif ARAOI.ThreeD_Glasses.PlayerColorData(player) == ARAOI.ThreeD_Glasses.ColorEnum.BLUE then
            player:SetColor(COLOR_BLUE, 999999, 1, true, true)
        end

        -- If the player dropped or switched the item, schedule all effects to be removed
        if not player:HasCollectible(ARAOI.CollectibleType.THREED_GLASSES) and ARAOI.ThreeD_Glasses.PlayerColorData(player) ~= ARAOI.ThreeD_Glasses.ColorEnum.NO_ITEM then
            -- Set the player's color to be reset
            player:SetColor(COLOR_WHITE, 999999, 1, true, true)
            ARAOI.ThreeD_Glasses.PlayerColorData(player, ARAOI.ThreeD_Glasses.ColorEnum.NO_ITEM)

            -- Remove the 20/20 effect if the player has it
            if ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player) then
                effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_20_20)
                ARAOI.ThreeD_Glasses.PlayerHas2020Effect(player, false)
            end
        end
    end
end)


-------------------------
-- ON PROJECTILE SPAWN --
-------------------------

---@param projectile EntityProjectile
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function (_, projectile)
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.THREED_GLASSES) then return end

    local rng = RNG()
    rng:SetSeed(Game():GetFrameCount())

    -- Check if the frame is even
    local spawn_as_red = rng:RandomInt(0, 1) == 0 -- Game():GetFrameCount() % 2 == 0

    if spawn_as_red then
        -- If the frame is even, set the color to red
        projectile:SetColor(COLOR_RED, 999999, 1, true, true)
        projectile:GetData()["3D Glasses Color"] = ARAOI.ThreeD_Glasses.ColorEnum.RED
    else
        -- If the frame is odd, set the color to blue
        projectile:SetColor(COLOR_BLUE, 999999, 1, true, true)
        projectile:GetData()["3D Glasses Color"] = ARAOI.ThreeD_Glasses.ColorEnum.BLUE
    end
end)


-----------------------------
-- ON PROJECTILE COLLISION --
-----------------------------

---@param projectile EntityProjectile
---@param collider Entity
ARAOI.Mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, function (_, projectile, collider)
    -- Check if the collider is a player
    local player = collider:ToPlayer()
    if not player then return end

    -- Check if the player has the collectible
    if not player:HasCollectible(ARAOI.CollectibleType.THREED_GLASSES) then return end

    -- Get the player's color and the projectile's color
    local player_color = ARAOI.ThreeD_Glasses.PlayerColorData(player)
    local projectile_color = projectile:GetData()["3D Glasses Color"]
    if not projectile_color then return end

    -- If the colors are the same, don't do the collision
    if player_color == projectile_color then
        return true
    end
end)


-------------
-- LOCUSTS --
-------------

---@param locust EntityFamiliar
ARAOI.Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, locust)
    if locust.SubType == ARAOI.CollectibleType.THREED_GLASSES then
        local locusts = ARAOI.PlayerUtils.GetLocusts(locust.SpawnerEntity:ToPlayer(), ARAOI.CollectibleType.THREED_GLASSES)
        if locusts then
            if #locusts%2 == 1 then
                locust:GetSprite().Color:SetTint(1, 0, 0, 1)
            end
            if #locusts%2 == 0 then
                locust:GetSprite().Color:SetTint(0, 0, 1, 1)
            end
        end
    end
end, FamiliarVariant.ABYSS_LOCUST)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.THREED_GLASSES,
        "#{{Timer}} On use, toggles Isaac's color between {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
        "#{{Tearsize}} While holding the item, enemy projectiles will now be {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
        "#{{HolyMantle}} Isaac will not take damage from tears of the same color as him"
    )

    local TT = CollectibleType.COLLECTIBLE_20_20
    ARAOI.EIDUtils.SimpleSynergyModifier(
        "3D Glasses Car Battery Synergy",
        ARAOI.CollectibleType.THREED_GLASSES,
        CollectibleType.COLLECTIBLE_CAR_BATTERY,
        "Gives the 20/20{{Collectible"..TT.."}} effect while held"
    )
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "3D Glasses Book Of Virtues Synergy",
        ARAOI.CollectibleType.THREED_GLASSES,
        "Does nothing"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "3D Glasses Abyss Synergy",
        ARAOI.CollectibleType.THREED_GLASSES,
        "Small red and blue locusts that deal 0.5x Isaac's damage"
    )
end)