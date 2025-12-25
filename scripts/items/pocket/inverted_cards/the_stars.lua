local Config = {}
----------------------------
-- START OF CONFIGURATION -- Shoutout to Fiend Folio
----------------------------



Config.NUM_RANDOM_EFFECTS = 5 -- *Default: `5` — The number of random effects the glitched item will have.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



local card = {}
card.Config = Config

card.ID = ARAOI.CardSubType.INVERTED_STARS
card.Replace = Card.CARD_REVERSE_STARS

ARAOI.Inverted_Cards.Stars = card

local game = Game()

---@param player EntityPlayer
function ARAOI:_OnInvertedCardStarsUse(_, player)
    local room = game:GetRoom()

    local rng = player:GetCardRNG(card.ID)
    rng:RandomFloat()

    local item = ProceduralItemManager.CreateProceduralItem(rng:GetSeed(), Config.NUM_RANDOM_EFFECTS)

    ARAOI.ItemUtils.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardStarsUse, card.ID)

ARAOI.EIDWrapper(function ()
    local tmt = CollectibleType.COLLECTIBLE_TMTRAINER
    EID:addCard(card.ID,
        "#{{Collectible"..tmt.."}} Spawns a glitched item with "..Config.NUM_RANDOM_EFFECTS.." random effects"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {" a glitched item ", " two glitched items "})
end)

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Inv. Cards", "Inverted Stars")

    ARAOI.MCMUtils.AddNumberSetting("Inv. Cards", "Inverted Stars", Config, "NUM_RANDOM_EFFECTS",
    ConfigDefaults, ConfigDefaults.NUM_RANDOM_EFFECTS, 1, 100, 10, function ()
        return "Num Random Effects: " .. Config.NUM_RANDOM_EFFECTS
    end, "The number of random effects the glitched item will have")

    ARAOI.MCMUtils.AddReset("Inv. Cards", "Inverted Stars")
end

return card