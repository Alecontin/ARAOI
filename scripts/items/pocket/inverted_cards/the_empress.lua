local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.NUM_MINIISAAC = 10 -- *Default: `10` — The number of MiniIsaacs to spawn*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)




local card = {}
card.Config = Config

card.ID = ARAOI.CardSubType.INVERTED_EMPRESS
card.Replace = Card.CARD_REVERSE_EMPRESS

ARAOI.Inverted_Cards.Empress = card

---@param player EntityPlayer
function ARAOI:_OnInvertedCardEmpressUse(_, player)
    for _ = 1, Config.NUM_MINIISAAC, 1 do
        player:AddMinisaac(player.Position)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardEmpressUse, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{Player0}} Spawns "..Config.NUM_MINIISAAC.." MiniIsaacs"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {Config.NUM_MINIISAAC, Config.NUM_MINIISAAC*2})
end)

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Inv. Cards", "Inverted Empress")

    ARAOI.MCMUtils.AddNumberSetting("Inv. Cards", "Inverted Empress", Config, "NUM_MINIISAAC",
    ConfigDefaults, ConfigDefaults.NUM_MINIISAAC, 1, 1000, 10, function ()
        return "MiniIsaacs Spawned: " .. Config.NUM_MINIISAAC
    end, "The number of MiniIsaacs spawned by this card")

    ARAOI.MCMUtils.AddReset("Inv. Cards", "Inverted Empress")
end

return card