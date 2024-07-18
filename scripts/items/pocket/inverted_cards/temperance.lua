local temperance = Isaac.GetCardIdByName("Inverted Temperance")
local reverse = Card.CARD_REVERSE_TEMPERANCE

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param player EntityPlayer
local function HeartsLost(player, set)
    return SaveData:Data(SaveData.LEVEL, "InvertedTemperanceDamageBoost", {}, Helper.GetPlayerId(player), 0, set)
end

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local max_hearts = player:GetHearts()

        if player:GetHealthType() ~= HealthType.RED and player:GetHealthType() ~= HealthType.BONE then return end

        local hearts_to_lose = max_hearts - 1

        player:AddHearts(-hearts_to_lose)

        HeartsLost(player, HeartsLost(player) + 0.5 * hearts_to_lose)

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end, temperance)

    ---@param player EntityPlayer
    ---@param flag CacheFlag
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
        if flag == CacheFlag.CACHE_DAMAGE then
            local hearts_lost = HeartsLost(player)
            player.Damage = player.Damage + (0.2 * hearts_lost ^ 2) * Helper.GetAproxDamageMultiplier(player)
        end
    end)

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function (_)
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end
    end)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return temperance
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(temperance,
            "#{{Heart}} Sets Isaac's health to {{HalfHeart}} Half a Heart"..
            "#{{ArrowUp}} Damage Up for every heart lost"
        )
    end
end

return card