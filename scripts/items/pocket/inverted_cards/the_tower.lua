local tower = Isaac.GetCardIdByName("Inverted Tower")
local reverse = Card.CARD_REVERSE_TOWER

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(tower)
        local room = game:GetRoom()

        for _ = 1, rng:RandomInt(2, 4) do
            local position = room:GetRandomPosition(50)
            Isaac.Spawn(EntityType.ENTITY_MOVABLE_TNT, 1, 0, position, Vector.Zero, player)
        end
    end, tower)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return tower
        end
    end)

    ---@class EID
    if EID then
        local tnt = CollectibleType.COLLECTIBLE_MINE_CRAFTER
        EID:addCard(tower,
            "#{{Collectible"..tnt.."}} Spawns 2-4 TNT"
        )
    end
end

return card