local justice = Isaac.GetCardIdByName("Inverted Justice")
local reverse = Card.CARD_REVERSE_JUSTICE

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

        local rng = player:GetCardRNG(justice)
        rng:RandomFloat()

        local function NewItem()
            return Helper.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position,50), Vector.Zero, player, false)
        end

        local item = NewItem()
        local options_index = item:SetNewOptionsPickupIndex()
        for _ = 1, rng:RandomInt(1, 3) do
            local choice_item = NewItem()
            choice_item.OptionsPickupIndex = options_index
        end
    end, justice)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return justice
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(justice,
            "#{{Collectible}} Spawns 2-4 items to choose from"
        )
    end
end

return card