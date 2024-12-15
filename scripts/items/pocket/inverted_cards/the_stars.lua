local Config = {}
----------------------------
-- START OF CONFIGURATION -- Shoutout to Fiend Folio
----------------------------



Config.NUM_RANDOM_EFFECTS = 5 -- *Default: `5` — The number of random effects the glitched item will have.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



local card = {}
card.Config = Config

card.ID = ARAOI.CardSubType.INVERTED_STARS
card.Replace = Card.CARD_REVERSE_STARS

ARAOI.Inverted_Cards.Stars = card

local game = Game()

---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    local room = game:GetRoom()

    local rng = player:GetCardRNG(card.ID)
    rng:RandomFloat()

    local item = ProceduralItemManager.CreateProceduralItem(rng:GetSeed(), Config.NUM_RANDOM_EFFECTS)

    ARAOI.ItemUtils.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
end, card.ID)

ARAOI.ReloadableDescription(function ()
    local tmt = CollectibleType.COLLECTIBLE_TMTRAINER
    EID:addCard(card.ID,
        "#{{Collectible"..tmt.."}} Spawns a glitched item with "..Config.NUM_RANDOM_EFFECTS.." random effects"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {" a glitched item ", " two glitched items "})
end)

return card