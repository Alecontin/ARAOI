---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Tower")
card.Replace = Card.CARD_REVERSE_TOWER

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(card.ID)
        local room = game:GetRoom()

        for _ = 1, rng:RandomInt(2, 4) do
            local position = room:GetRandomPosition(50)
            Isaac.Spawn(EntityType.ENTITY_MOVABLE_TNT, 1, 0, position, Vector.Zero, player)
        end
    end, card.ID)

    ---@class EID
    if EID then
        local tnt = CollectibleType.COLLECTIBLE_MINE_CRAFTER
        EID:addCard(card.ID,
            "#{{Collectible"..tnt.."}} Spawns 2-4 TNT"
        )
    end
end

return card