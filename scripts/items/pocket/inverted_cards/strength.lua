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
                entity:ToNPC():MakeChampion(entity.InitSeed)
            end
        end
    end, card.ID)


    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Crown}} Transforms all enemies in the room into their champion variants"
        )
    end
end

return card