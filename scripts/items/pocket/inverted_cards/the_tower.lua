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
        player:UseCard(Card.CARD_REVERSE_TOWER, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)

        Isaac.CreateTimer(function ()
            for _, entity in ipairs(Helper.GetRoomGridEntities()) do
                local rock = entity:ToRock()
                if rock then
                    rock:Destroy(true)
                end
            end
        end, 80, 1, false)
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
        EID:addCard(tower,
            "#{{Card"..reverse.."}} Uses The Tower? and destroys all rocks"
        )
    end
end

return card