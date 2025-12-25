local card = {}

card.ID = ARAOI.CardSubType.INVERTED_HIGH_PRIESTESS
card.Replace = Card.CARD_REVERSE_HIGH_PRIESTESS

ARAOI.Inverted_Cards.High_Priestess = card

---@param player EntityPlayer
function ARAOI:_OnInvertedCardHighPriestessUse(_, player)
    player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)

    for _ = 1, 8 do
        player:AddSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL, false)
        ---@diagnostic disable-next-line: undefined-field
        player:GetHistory():RemoveHistoryItemByIndex(#player:GetHistory():GetCollectiblesHistory() - 1)
    end

    ARAOI.SaveDataManager:CreateTimerInFrames("Remove Inverted High Priestess Effect From Player", 1800, player:GetPlayerIndex())
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardHighPriestessUse, card.ID)

---@param player_index integer
function ARAOI:_OnInvertedCardHighPriestessRemoveEffect(_, player_index)
    local player = Isaac.GetPlayer(player_index)
    for _ = 1, 8 do
        player:TryRemoveSmeltedTrinket(TrinketType.TRINKET_MOMS_TOENAIL)
    end
end
ARAOI:AddCallback("Remove Inverted High Priestess Effect From Player", ARAOI._OnInvertedCardHighPriestessRemoveEffect)

ARAOI.EIDWrapper(function ()
    local toenail = TrinketType.TRINKET_MOMS_TOENAIL
    EID:addCard(card.ID,
        "#{{MomBoss}} Activates the effects of {{Card"..card.Replace.."}} The High Priestess? and 8 {{Trinket"..toenail.."}} Mom's Toenail"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, "Twice! Yippee...?")
end)

return card