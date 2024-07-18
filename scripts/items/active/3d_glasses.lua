local modded_item = {}

local THREED_GLASSES =  Isaac.GetItemIdByName("3D Glasses")

---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

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

local ColorRed = Color(1, w, w, 1)
local ColorBlue = Color(w, w, 1, 1)
local ColorWhite = Color(1, 1, 1, 1)

---@param player EntityPlayer
---@param set? ColorEnum | integer
local function playerColorData(player, set)
    return SaveData:Data(SaveData.RUN, "3D Glasses", {}, Helper.GetPlayerId(player), ColorEnum.NO_ITEM, set)
end

---@param player EntityPlayer
---@param set? boolean
local function has2020Effect(player, set)
    return SaveData:Data(SaveData.ROOM, "3D Glasses 20/20", {}, Helper.GetPlayerId(player), false, set)
end

---@param Mod ModReference
function modded_item:init(Mod)

    --------------------
    -- ON ITEM PICKUP --
    --------------------

    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    local function onCollectiblePickup(_, collectibleType, _, _, _, _, player)
        if collectibleType ~= THREED_GLASSES then return end

        -- Initialize the player's color to RED
        if playerColorData(player) == ColorEnum.NO_ITEM then
            playerColorData(player, ColorEnum.RED)
        end
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, onCollectiblePickup)


    -----------------
    -- ON ITEM USE --
    -----------------

    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    local function onActiveItemUse(_, _, _, player, useFlags)
        if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

        -- If the player's color is red, switch it to blue and viceversa
        if playerColorData(player) == ColorEnum.RED then
            playerColorData(player, ColorEnum.BLUE)
        else
            playerColorData(player, ColorEnum.RED)
        end

        -- Show the item animation
        return true
    end
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, onActiveItemUse, THREED_GLASSES)


    -----------------
    -- EVERY FRAME --
    -----------------

    local function onRender()
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
                player:SetColor(ColorRed, 999999, 1, true, true)
            elseif playerColorData(player) == ColorEnum.BLUE then
                player:SetColor(ColorBlue, 999999, 1, true, true)
            end

            -- If the player dropped or switched the item, schedule all effects to be removed
            if not player:HasCollectible(THREED_GLASSES) and playerColorData(player) ~= ColorEnum.NO_ITEM then
                -- Set the player's color to be reset
                player:SetColor(ColorWhite, 999999, 1, true, true)
                playerColorData(player, ColorEnum.NO_ITEM)

                -- Remove the 20/20 effect if the player has it
                if has2020Effect(player) then
                    effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_20_20)
                    has2020Effect(player, false)
                end
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)


    -------------------------
    -- ON PROJECTILE SPAWN --
    -------------------------

    ---@param projectile EntityProjectile
    local function onProjectileSpawn(_, projectile)
        if not PlayerManager.AnyoneHasCollectible(THREED_GLASSES) then return end

        local rng = RNG()
        rng:SetSeed(Game():GetFrameCount())

        -- Check if the frame is even
        local spawnAsRed = rng:RandomInt(0, 1) == 0 -- Game():GetFrameCount() % 2 == 0

        if spawnAsRed then
            -- If the frame is even, set the color to red
            projectile:SetColor(ColorRed, 999999, 1, true, true)
            projectile:GetData()["3D Glasses Color"] = ColorEnum.RED
        else
            -- If the frame is odd, set the color to blue
            projectile:SetColor(ColorBlue, 999999, 1, true, true)
            projectile:GetData()["3D Glasses Color"] = ColorEnum.BLUE
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, onProjectileSpawn)


    -----------------------------
    -- ON PROJECTILE COLLISION --
    -----------------------------

    ---@param projectile EntityProjectile
    ---@param collider Entity
    local function preProjectileCollision(_, projectile, collider)
        -- Check if the collider is a player
        local player = collider:ToPlayer()
        if not player then return end

        -- Check if the player has the collectible
        if not player:HasCollectible(THREED_GLASSES) then return end

        -- Get the player's color and the projectile's color
        local playerColor = playerColorData(player)
        local projectileColor = projectile:GetData()["3D Glasses Color"]
        if not projectileColor then return end

        -- If the colors are the same, don't do the collision
        if playerColor == projectileColor then
            return true
        end
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, preProjectileCollision)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then
        EID:addCollectible(THREED_GLASSES,
            "#{{Timer}} On use, toggles the player's color between {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
            "#{{Tearsize}} Enemy tears will now be {{ColorRed}}Red{{ColorReset}} and {{ColorBlue}}Blue{{ColorReset}}"..
            "#{{HolyMantle}} Player will not take damage from tears of the same color"
        )

        local CB = CollectibleType.COLLECTIBLE_CAR_BATTERY
        local TT = CollectibleType.COLLECTIBLE_20_20

        ---@param descObject EID.DescriptionObject 
        local function check(descObject)
            return Helper.DescObjIs(descObject, 5, 100, THREED_GLASSES) and PlayerManager.AnyoneHasCollectible(CB)
        end
        ---@param descObject EID.DescriptionObject 
        local function modifier(descObject)
            EID:appendToDescription(descObject, "#{{Collectible"..CB.."}} Gives the 20/20{{Collectible"..TT.."}} effect while held")
            return descObject
        end
        EID:addDescriptionModifier("3D Glasses Car Battery", check, modifier)

        local BOV = CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES

        ---@param descObject EID.DescriptionObject 
        local function check(descObject)
            return Helper.DescObjIs(descObject, 5, 100, THREED_GLASSES) and PlayerManager.AnyoneHasCollectible(BOV)
        end
        ---@param descObject EID.DescriptionObject 
        local function modifier(descObject)
            EID:appendToDescription(descObject, "#{{Collectible"..BOV.."}} Does nothing")
            return descObject
        end
        EID:addDescriptionModifier("3D Glasses Book Of Virtues", check, modifier)
    end
end

return modded_item