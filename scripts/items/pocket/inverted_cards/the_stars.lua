----------------------------
-- START OF CONFIGURATION -- Shoutout to Fiend Folio
----------------------------



local NUM_RANDOM_EFFECTS = 5 -- *Default: `5` — The number of random effects the glitched item will have.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Stars")
card.Replace = Card.CARD_REVERSE_STARS

---@class helper
local helper = include("scripts.helper")

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()

        local rng = player:GetCardRNG(card.ID)
        rng:RandomFloat()

        local item = ProceduralItemManager.CreateProceduralItem(rng:GetSeed(), NUM_RANDOM_EFFECTS)

        helper.item.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
    end, card.ID)

    ---@class EID
    if EID then
        local tmt = CollectibleType.COLLECTIBLE_TMTRAINER
        EID:addCard(card.ID,
            "#{{Collectible"..tmt.."}} Spawns a glitched item with "..NUM_RANDOM_EFFECTS.." random effects"
        )
        EID:addTarotClothMetadata(card.ID, {" a glitched item ", " two glitched items "})
    end
end

return card