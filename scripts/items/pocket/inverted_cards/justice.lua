---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Justice")
card.Replace = Card.CARD_REVERSE_JUSTICE

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()

        local rng = player:GetCardRNG(card.ID)
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
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Collectible}} Spawns 2-4 items to choose from"
        )
    end
end

return card