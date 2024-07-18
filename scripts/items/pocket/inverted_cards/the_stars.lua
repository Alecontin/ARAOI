----------------------------
-- START OF CONFIGURATION -- Shoutout to Fiend Folio
----------------------------



local NUM_RANDOM_EFFECTS = 5 -- *Default: `5` — The number of random effects the glitched item will have.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



local stars = Isaac.GetCardIdByName("Inverted Stars")
local reverse = Card.CARD_REVERSE_STARS

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()

        local rng = player:GetCardRNG(stars)
        rng:RandomFloat()

        local item = ProceduralItemManager.CreateProceduralItem(rng:GetSeed(), NUM_RANDOM_EFFECTS)

        Helper.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
    end, stars)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return stars
        end
    end)

    ---@class EID
    if EID then
        local tmt = CollectibleType.COLLECTIBLE_TMTRAINER
        EID:addCard(stars,
            "#{{Collectible"..tmt.."}} Spawns a glitched item with "..NUM_RANDOM_EFFECTS.." random effects"
        )
    end
end

return card