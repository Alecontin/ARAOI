local world = Isaac.GetCardIdByName("Inverted World")
local reverse = Card.CARD_REVERSE_WORLD

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local sfx = SFXManager()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(world)
        rng:RandomFloat()

        local room = RoomConfigHolder.GetRandomRoom(rng:GetSeed(), true, StbType.SPECIAL_ROOMS, RoomType.ROOM_BLACK_MARKET)

        Isaac.ExecuteCommand("goto s.blackmarket."..room.Variant)

        Isaac.CreateTimer(function ()
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TALL_LADDER, 0, player.Position, Vector.Zero, player)
        end, 1, 1, true)
    end, world)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return world
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(world,
            "#{{BlackSack}} Teleports Isaac to a random Black Market"
        )
    end
end

return card