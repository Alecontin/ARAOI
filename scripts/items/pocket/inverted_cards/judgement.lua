local card = {}

card.ID = ARAOI.CardSubType.INVERTED_JUDGEMENT
card.Replace = Card.CARD_REVERSE_JUDGEMENT

ARAOI.Inverted_Cards.Judgement = card

local game = Game()
local SFX = SFXManager()

---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    local room = game:GetRoom()

    local spawn = Isaac.Spawn(EntityType.ENTITY_SLOT, SlotVariant.CONFESSIONAL, 0, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 3, spawn.Position, Vector.Zero, nil)
    SFX:Play(SoundEffect.SOUND_SUMMONSOUND)
end, card.ID)

ARAOI.ReloadableDescription(function ()
    EID:addCard(card.ID,
        "#{{Confessional}} Spawns a Confessional{{Blank}}"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {" a ", " two ", "{{Blank}}", "s{{Blank}}"})
end)

return card