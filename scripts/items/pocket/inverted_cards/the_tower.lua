---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Tower")
card.Replace = Card.CARD_REVERSE_TOWER

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(card.ID)

        for _ = 1, rng:RandomInt(2, 4) do
            local velocity = EntityPickup.GetRandomPickupVelocity(player.Position) / 2
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_THROWABLEBOMB, 0, player.Position, velocity, player)
        end
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Bomb}} Spawns 2-4 throwable bombs"
        )
    end
end

return card