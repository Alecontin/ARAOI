local card = {}

card.ID = ARAOI.CardSubType.INVERTED_JUSTICE
card.Replace = Card.CARD_REVERSE_JUSTICE

ARAOI.Inverted_Cards.Justice = card

local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) and 1 or 0
    local room = game:GetRoom()

    local rng = player:GetCardRNG(card.ID)
    rng:RandomFloat()

    local function NewItem()
        return ARAOI.ItemUtils.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position,50), Vector.Zero, player, false)
    end

    local item = NewItem()
    local options_index = item:SetNewOptionsPickupIndex()
    for _ = 1, rng:RandomInt(1 + tarotClothModifier, 3 + tarotClothModifier) do
        local choice_item = NewItem()
        choice_item.OptionsPickupIndex = options_index
    end
end, card.ID)

---@type EID
if EID then
    EID:addCard(card.ID,
        "#{{Collectible}} Spawns 2-4 items to choose from"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {2, 3, 4, 5})
end

return card