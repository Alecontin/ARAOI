local judgement = Isaac.GetCardIdByName("Inverted Judgement")
local reverse = Card.CARD_REVERSE_JUDGEMENT

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

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
    end, judgement)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return judgement
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(judgement,
            "#{{Confessional}} Spawns a Confessional"
        )
    end
end

return card