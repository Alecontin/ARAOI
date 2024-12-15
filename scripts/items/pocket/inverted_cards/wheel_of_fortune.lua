local card = {}

card.ID = ARAOI.CardSubType.INVERTED_WHEEL_OF_FORTUNE
card.Replace = Card.CARD_REVERSE_WHEEL_OF_FORTUNE

ARAOI.Inverted_Cards.Wheel_of_Fortune = card

local game = Game()
local ItemConfig = Isaac.GetItemConfig()
local HUD = game:GetHUD()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) and 0.03 or 0
    local ItemPool = game:GetItemPool()

    local rng = player:GetCardRNG(card.ID)

    local use_card = ItemPool:GetCardEx(rng:Next(), 0, 0, 0, false)

    local config = ItemConfig:GetCard(use_card)
    HUD:ShowItemText(Isaac.GetString("pocketitems", config.Name), Isaac.GetString("pocketitems", config.Description))

    player:UseCard(use_card, UseFlag.USE_NOANNOUNCER)

    if rng:RandomFloat() > 0.1 - tarotClothModifier then
        player:AddCard(card.ID)
    end
end, card.ID)

ARAOI.ReloadableDescription(function ()
    EID:addCard(card.ID,
        "#{{Card}} Mimics a random card on use"..
        "# Has a 10% chance to destroy itself with each use"
    )
    EID:addTarotClothMetadata(card.ID, {10, 7})
end)

return card