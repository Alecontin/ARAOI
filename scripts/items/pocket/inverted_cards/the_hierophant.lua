local hierophant = Isaac.GetCardIdByName("Inverted Hierophant")
local reverse = Card.CARD_REVERSE_HIEROPHANT

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        for _ = 1, 2 do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK,
                        room:FindFreePickupSpawnPosition(player.Position,50), Vector.Zero, player)
        end
    end, hierophant)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return hierophant
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(hierophant,
            "#{{BlackHeart}} Spawns 2 Black Hearts"
        )
    end
end

return card