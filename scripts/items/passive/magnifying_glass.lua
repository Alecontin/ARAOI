----------------------------
-- START OF CONFIGURATION --
----------------------------



local PICKUP_SCALE  = 1.25 -- *Default: `1.25` — The scale that the pickups will be set to.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



local MAGNIFYING_GLASS = Isaac.GetItemIdByName("Magnifying Glass")

local modded_item = {}

function modded_item:init(Mod)
    ---@param pickup EntityPickup
    Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function (_, pickup)
        if not PlayerManager.AnyoneHasCollectible(MAGNIFYING_GLASS) then return end

        -- The amount of times to apply the scale
        local multi = PlayerManager.GetNumCollectibles(MAGNIFYING_GLASS)

        -- The actual amount of scale to apply
        local offset = (PICKUP_SCALE ^ multi)

        -- Convert the scale to a vector
        local vec = Vector(offset, offset)

        -- Apply the scale to the hitbox and the sprite respectively
        pickup.SizeMulti = vec
        pickup:GetSprite().Scale = vec
    end)

    ---@class EID
    if EID then
        EID:addCollectible(MAGNIFYING_GLASS,
            "# Makes all pickups "..PICKUP_SCALE.."x bigger"
        )
    end
end

return modded_item