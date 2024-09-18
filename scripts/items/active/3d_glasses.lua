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

local THREED_GLASSES =  Isaac.GetItemIdByName("3D Glasses")

---@class ColorEnum
local ColorEnum = {
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

---@param player EntityPlayer
---@param set? ColorEnum | integer
local function playerColorData(player, set)
    return SaveData:Data(SaveData.RUN, "3D Glasses", {}, helper.player.GetID(player), ColorEnum.NO_ITEM, set)
end

---@param player EntityPlayer
---@param set? boolean
local function has2020Effect(player, set)
    return SaveData:Data(SaveData.ROOM, "3D Glasses 20/20", {}, helper.player.GetID(player), false, set)
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)

    --------------------
    -- ON ITEM PICKUP --
    --------------------

    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function (_, collectibleType, _, _, _, _, player)
        if collectibleType ~= THREED_GLASSES then return end

        -- Initialize the player's color to RED
        if playerColorData(player) == ColorEnum.NO_ITEM then
            playerColorData(player, ColorEnum.RED)
        end
    end)


    -----------------
    -- ON ITEM USE --
    -----------------

    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, useFlags)
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

        -- If the player's color is red, switch it to blue and viceversa
        if playerColorData(player) == ColorEnum.RED then
            playerColorData(player, ColorEnum.BLUE)
        else
            playerColorData(player, ColorEnum.RED)
        end

        -- Show the item animation
        return true
    end, THREED_GLASSES)


    -----------------
    -- EVERY FRAME --
    -----------------

    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            local effects = player:GetEffects()

            -- Add the 20/20 Collectible Effect if the player has both the glasses and car battery
            if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
            and player:HasCollectible(THREED_GLASSES)
            and not has2020Effect(player)
            then
                -- Add the 20/20 effect
                effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_20_20)

                -- Register the 20/20 effect for the player
                -- We do this so we only remove it once later. After all, other mods could add their own 20/20 effect
                has2020Effect(player, true)
            end

            -- Change the player's color
            if playerColorData(player) == ColorEnum.RED then
                player:SetColor(COLOR_RED, 999999, 1, true, true)
            elseif playerColorData(player) == ColorEnum.BLUE then
                player:SetColor(COLOR_BLUE, 999999, 1, true, true)
            end

            -- If the player dropped or switched the item, schedule all effects to be removed
            if not player:HasCollectible(THREED_GLASSES) and playerColorData(player) ~= ColorEnum.NO_ITEM then
                -- Set the player's color to be reset
                player:SetColor(COLOR_WHITE, 999999, 1, true, true)
                playerColorData(player, ColorEnum.NO_ITEM)

                -- Remove the 20/20 effect if the player has it
                if has2020Effect(player) then
                    effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_20_20)
                    has2020Effect(player, false)
                end
            end
        end
    end)


    -------------------------
    -- ON PROJECTILE SPAWN --
    -------------------------

    ---@param projectile EntityProjectile
    Mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function (_, projectile)
        if not PlayerManager.AnyoneHasCollectible(THREED_GLASSES) then return end

        local rng = RNG()
        rng:SetSeed(Game():GetFrameCount())

        -- Check if the frame is even
        local spawn_as_red = rng:RandomInt(0, 1) == 0 -- Game():GetFrameCount() % 2 == 0

        if spawn_as_red then
            -- If the frame is even, set the color to red
            projectile:SetColor(COLOR_RED, 999999, 1, true, true)
            projectile:GetData()["3D Glasses Color"] = ColorEnum.RED
        else
            -- If the frame is odd, set the color to blue
            projectile:SetColor(COLOR_BLUE, 999999, 1, true, true)
            projectile:GetData()["3D Glasses Color"] = ColorEnum.BLUE
        end
    end)


    -----------------------------
    -- ON PROJECTILE COLLISION --
    -----------------------------

    ---@param projectile EntityProjectile
    ---@param collider Entity
    Mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, function (_, projectile, collider)
        -- Check if the collider is a player
        local player = collider:ToPlayer()
        if not player then return end

        -- Check if the player has the collectible
        if not player:HasCollectible(THREED_GLASSES) then return end

        -- Get the player's color and the projectile's color
        local player_color = playerColorData(player)
        local projectile_color = projectile:GetData()["3D Glasses Color"]
        if not projectile_color then return end

        -- If the colors are the same, don't do the collision
        if player_color == projectile_color then
            return true
        end
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(THREED_GLASSES,
            "#{{Timer}} On use, toggles the Isaac's color between {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
            "#{{Tearsize}} Enemy tears will now be {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
            "#{{HolyMantle}} Isaac will not take damage from tears of the same color as him"
        )

        local TT = CollectibleType.COLLECTIBLE_20_20
        helper.eid.SimpleSynergyModifier(
            "3D Glasses Car Battery Synergy",
            THREED_GLASSES,
            CollectibleType.COLLECTIBLE_CAR_BATTERY,
            "Gives the 20/20{{Collectible"..TT.."}} effect while held"
        )
        helper.eid.BookOfVirtuesSynergy(
            "3D Glasses Book Of Virtues Synergy",
            THREED_GLASSES,
            "Does nothing"
        )
    end
end

return modded_item