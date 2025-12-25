local card = {}

card.ID = ARAOI.CardSubType.INVERTED_MAGICIAN
card.Replace = Card.CARD_REVERSE_MAGICIAN

ARAOI.Inverted_Cards.Magician = card

local game = Game()
local sfx = SFXManager()

local ActiveEffects = {}

local frame_since_last_sound = 0
local sound = 0

---@param player EntityPlayer
---@return integer
function ARAOI.Inverted_Cards.Magician.GetEffectCountdown(player)
    local player_id = ARAOI.PlayerUtils.GetId(player)
    return ActiveEffects[player_id] or 0
    -- return ARAOI.SaveDataManager:Key(ActiveEffects, player_id, 0)
end

---@param player EntityPlayer
---@param set number -- Time in seconds that the effect should last
function ARAOI.Inverted_Cards.Magician.SetEffectCountdown(player, set)
    frame_since_last_sound = 0
    local player_id = ARAOI.PlayerUtils.GetId(player)
    ActiveEffects[player_id] = set
    -- return ARAOI.SaveDataManager:Key(ActiveEffects, player_id, 0, set * 30)
end

---@param player EntityPlayer
---@param add number -- Time in seconds that should be added to the effect duration
function ARAOI.Inverted_Cards.Magician.AddEffectCountdown(player, add)
    frame_since_last_sound = 0
    local player_id = ARAOI.PlayerUtils.GetId(player)
    ActiveEffects[player_id] = ARAOI.Inverted_Cards.Magician.GetEffectCountdown(player) + (add * 30)
    -- return ARAOI.SaveDataManager:Key(ActiveEffects, player_id, 0, ARAOI.SaveDataManager:Key(ActiveEffects, player_id, 0) + add * 30)
end

local function PlayUltraInstinctSound()
    local frame_count = game:GetFrameCount()
    local count = frame_count - frame_since_last_sound

    sound = (sound % 12)

    if count <= 3 then
        return
    elseif count <= 90 then
        sound = sound + 1
    else
        sound = 1
    end

    local instinct = Isaac.GetSoundIdByName("inverted_magician_"..tostring(sound))
    sfx:Play(instinct)

    frame_since_last_sound = frame_count
end

---@param player EntityPlayer
function ARAOI:_OnInvertedCardMagicianUse(_, player)
    ARAOI.Inverted_Cards.Magician.AddEffectCountdown(player, 15)
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardMagicianUse, card.ID)

function ARAOI:_OnInvertedCardMagicianUpdate()
    for player_id, effect_frames in pairs(ActiveEffects) do
        ActiveEffects[player_id] = effect_frames - 1
        if effect_frames <= 0 then
            ActiveEffects[player_id] = nil
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_UPDATE, ARAOI._OnInvertedCardMagicianUpdate)

---@param player EntityPlayer
---@param damageFlags DamageFlag
function ARAOI:_OnInvertedCardMagicianPrePlayerTakeDMG(player, _, damageFlags)
    if damageFlags & DamageFlag.DAMAGE_FAKE > 0
    or damageFlags & DamageFlag.DAMAGE_CLONES > 0
    or damageFlags & DamageFlag.DAMAGE_IV_BAG > 0
    or damageFlags & DamageFlag.DAMAGE_INVINCIBLE > 0
    or damageFlags & DamageFlag.DAMAGE_NO_PENALTIES > 0
    or player:GetDamageCooldown() > 0
    or ARAOI.Inverted_Cards.Magician.GetEffectCountdown(player) == 0
    then return end

    local offset = Vector(0, 10)

    local is_clear, pos = nil, Vector.Zero

    local tries = 0
    while (is_clear == nil or is_clear == false) do
        local position = game:GetRoom():GetRandomPosition(1)
        ---@type boolean, Vector
        ---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
        is_clear, pos = game:GetRoom():CheckLine(player.Position, position, LineCheckMode.ENTITY)

        if player:IsFlying() or tries > 10 then
            is_clear, pos = true, position
        end

        tries = tries + 1
    end

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKED_ORB_POOF, 0, player.Position+offset, Vector.Zero, player):ToEffect()
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKED_ORB_POOF, 0, pos+offset, Vector.Zero, nil):ToEffect()

    ---@diagnostic disable-next-line: assign-type-mismatch
    player.Position = pos
    PlayUltraInstinctSound()

    return false
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, ARAOI._OnInvertedCardMagicianPrePlayerTakeDMG)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{ArrowUp}} Activates Ultra Instinct for 15 seconds"
    )
    ARAOI.EIDUtils.TarotClothMetadata(ARAOI.CardSubType.INVERTED_MAGICIAN, {15, 30})
end)

return card