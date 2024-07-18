local death = Isaac.GetCardIdByName("Inverted Death")
local reverse = Card.CARD_REVERSE_DEATH

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
        local entity = Isaac.Spawn(EntityType.ENTITY_DEATH, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
        entity:AddCharmed(EntityRef(player), -1)
    end, death)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return death
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(death,
            "#{{DeathMark}} Spawns a friendly Death Horseman"
        )
    end
end

return card