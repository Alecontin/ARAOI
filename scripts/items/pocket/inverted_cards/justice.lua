local card = {}

card.ID = ARAOI.CardSubType.INVERTED_JUSTICE
card.Replace = Card.CARD_REVERSE_JUSTICE

ARAOI.Inverted_Cards.Justice = card

local game = Game()
local level = game:GetLevel()

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnInvertedCardJusticeUse(_, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH)
    local room = game:GetRoom()

    local rng = player:GetCardRNG(card.ID)
    rng:RandomFloat()

    local options_index = nil
    for _ = 1, tarotClothModifier and rng:RandomInt(4, 14) or rng:RandomInt(2, 4) do
        local item = ARAOI.ItemUtils.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position,50), Vector.Zero, player, false)
        if level:GetStage() ~= LevelStage.STAGE6 then
            if options_index == nil then
                options_index = item:SetNewOptionsPickupIndex()
            else
                item.OptionsPickupIndex = options_index
            end
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardJusticeUse, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{Collectible}} Spawns 2-4 items to choose from"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {4, 14, 2, 4})
end)

return card