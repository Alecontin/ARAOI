---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Judgement")
card.Replace = Card.CARD_REVERSE_JUDGEMENT

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local sfx = SFXManager()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()

        local spawn = Isaac.Spawn(EntityType.ENTITY_SLOT, SlotVariant.CONFESSIONAL, 0, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 3, spawn.Position, Vector.Zero, nil)
        sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Confessional}} Spawns a Confessional"
        )
    end
end

return card