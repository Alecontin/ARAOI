local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.DAMAGE_GIVEN = 0.75 -- *Default: `0.75` — Amount of damage that will be given per half a heart drained.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



local card = {}
card.Config = Config

card.ID = Isaac.GetCardIdByName("Inverted Temperance")
card.Replace = Card.CARD_REVERSE_TEMPERANCE

ARAOI.Inverted_Cards.Temperance = card

---@param player EntityPlayer
local function heartsLost(player, set)
    return ARAOI.SaveData:Data(ARAOI.SaveData.LEVEL, "InvertedTemperanceDamageBoost", {}, ARAOI.PlayerUtils.GetID(player), 0, set)
end

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
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

    heartsLost(player, heartsLost(player) + 0.5 * hearts_lost)
    print(heartsLost(player))

    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    player:EvaluateItems()
end, card.ID)

---@param player EntityPlayer
---@param flag CacheFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
    if flag == CacheFlag.CACHE_DAMAGE then
        local hearts_lost = heartsLost(player)
        player.Damage = player.Damage + (Config.DAMAGE_GIVEN * hearts_lost) * ARAOI.PlayerUtils.GetAproxDamageMultiplier(player)
    end
end)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function (_)
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end)

---@type EID
if EID then
    EID:addCard(card.ID,
        "#{{EmptyHeart}} Drains all of Isaac's Red Hearts"..
        "#{{ArrowUp}} +"..Config.DAMAGE_GIVEN.." Damage for every {{HalfHeart}} Half a Heart lost"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, "Effect calculated as if Isaac had double his current health!")
end

return card