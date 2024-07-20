---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Strength")
card.Replace = Card.CARD_REVERSE_STRENGTH

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity:IsActiveEnemy() then
                if entity:IsBoss() then
                    entity:AddWeakness(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddWeakness(EntityRef(player), 150)
                    end, 30, 10, false)
                else
                    entity:AddWeakness(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddWeakness(EntityRef(player), 150)
                    end, 30, 999999, false)
                end
            end
        end
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Weakness}} Applies weakness to all enemies in the room"
        )
    end
end

return card