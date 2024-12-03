---@class helper
local helper = include("scripts.helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Wheel of Fortune")
card.Replace = Card.CARD_REVERSE_WHEEL_OF_FORTUNE

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()
    local HUD = game:GetHUD()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local ItemPool = game:GetItemPool()

        local rng = player:GetCardRNG(card.ID)

        local use_card = ItemPool:GetCardEx(rng:Next(), 0, 0, 0, false)

        local config = ItemConfig:GetCard(use_card)
        HUD:ShowItemText(Isaac.GetString("pocketitems", config.Name), Isaac.GetString("pocketitems", config.Description))

        player:UseCard(use_card, UseFlag.USE_NOANNOUNCER)

        if rng:RandomFloat() > 0.1 then
            player:AddCard(card.ID)
        end
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Card}} Mimics a random card on use"..
            "# Has a 10% chance to destroy itself with each use"
        )
    end
end

return card