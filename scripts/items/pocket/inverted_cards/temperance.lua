local card = {}

card.ID = ARAOI.CardSubType.INVERTED_TEMPERANCE
card.Replace = Card.CARD_REVERSE_TEMPERANCE

ARAOI.Inverted_Cards.Temperance = card

local function HeartsLost(player, add)
    local lost = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.LEVEL, "InvertedTemperanceHeartsLost", {}, ARAOI.PlayerUtils.GetId(player), 0)
    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.LEVEL, "InvertedTemperanceHeartsLost", {}, ARAOI.PlayerUtils.GetId(player), 0, lost + (add or 0))
end

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnInvertedCardTemperanceUse(_, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) and 2 or 1
    if player:GetHealthType() ~= HealthType.RED and player:GetHealthType() ~= HealthType.BONE then return end
    if player:GetHearts() == 0 then return end

    local hearts_to_lose = player:GetHearts()
    player:AddHearts(-hearts_to_lose)
    player:TryPreventDeath()
    local hearts_lost = (hearts_to_lose * tarotClothModifier) - player:GetHearts()

    if hearts_lost == 0 then
        return
    end

    -- local effects = player:GetEffects()
    -- effects:AddNullEffect(NullItemID.ID_BLOOD_OATH, true, hearts_lost)

    for _ = 1, hearts_lost do
        player:AddNullItemEffect(NullItemID.ID_BLOOD_OATH, true)
        player:TakeDamage(0, DamageFlag.DAMAGE_FAKE, EntityRef(player), 0)
    end
    player:SetMinDamageCooldown(60)

    HeartsLost(player, hearts_lost)
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardTemperanceUse, card.ID)

function ARAOI:_OnInvertedCardTemperanceNewRoom()
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        for _ = 1, HeartsLost(player) do
            player:AddNullItemEffect(NullItemID.ID_BLOOD_OATH, true)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnInvertedCardTemperanceNewRoom)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{EmptyHeart}} Drains all of Isaac's Red Hearts"..
        "#{{ArrowUp}} Damage & Speed up for every {{HalfHeart}} Half a Heart lost"..
        "#{{HalfHeart}} Every Half Heart lost triggers on-hit effects"..
        "#{{Collectible"..CollectibleType.COLLECTIBLE_BLOOD_OATH.."}} Same effect as Blood Oath"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, "Effect calculated as if Isaac had double his current health!")
end)

return card