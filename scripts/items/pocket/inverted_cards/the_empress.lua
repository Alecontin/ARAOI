local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.NUM_MINIISAAC = 10 -- *Default: `10` — The number of MiniIsaacs to spawn*



--------------------------
-- END OF CONFIGURATION --
--------------------------




local card = {}
card.Config = Config

card.ID = ARAOI.CardSubType.INVERTED_EMPRESS
card.Replace = Card.CARD_REVERSE_EMPRESS

ARAOI.Inverted_Cards.Empress = card

---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    for _ = 1, Config.NUM_MINIISAAC, 1 do
        player:AddMinisaac(player.Position)
    end
end, card.ID)

ARAOI.ReloadableDescription(function ()
    EID:addCard(card.ID,
        "#{{Player0}} Spawns "..Config.NUM_MINIISAAC.." MiniIsaacs"
    )
    EID:addTarotClothMetadata(card.ID, {Config.NUM_MINIISAAC, Config.NUM_MINIISAAC*2})
end)

return card