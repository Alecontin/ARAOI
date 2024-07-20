---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Chariot")
card.Replace = Card.CARD_REVERSE_CHARIOT

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity:IsActiveEnemy() then
                if entity:IsBoss() then
                    entity:AddFreeze(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddFreeze(EntityRef(player), 150)
                    end, 30, 10, false)
                else
                    entity:AddFreeze(EntityRef(player), 150)
                    Isaac.CreateTimer(function ()
                        entity:AddFreeze(EntityRef(player), 150)
                    end, 30, 999999, false)
                end
            end
        end
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Freezing}} Petrifies all enemies in the room"
        )
    end
end

return card