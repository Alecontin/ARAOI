local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.REPLACE_CHANCE = 15 -- *Default: `15` — The % chance that a card will be overwritten*



--------------------------
-- END OF CONFIGURATION --
--------------------------


ARAOI.Inverted_Cards = {}
ARAOI.Inverted_Cards.Config = Config


local cards = "scripts.items.pocket.inverted_cards."

local files = {
    --[[ Example of a card that has a ReplaceChance overwrite:
    cards.."card_script", --
                          ^^
    If a card is marked that way, go inside the script and
    search for "card.ReplaceChance = #.##" near the top, you can
    modify the value there or simply delete or comment the line
    ]]
    cards.."the_fool",
    cards.."the_magician",
    cards.."the_high_priestess",
    cards.."the_empress",
    cards.."the_emperor",
    cards.."the_hermit",
    cards.."the_hierophant",
    cards.."the_lovers",
    cards.."the_chariot",
    cards.."justice",
    cards.."wheel_of_fortune",
    cards.."strength",
    cards.."the_hanged_man",
    cards.."death",
    cards.."temperance",
    cards.."the_devil",
    cards.."the_tower",
    cards.."the_stars",
    cards.."the_moon",
    cards.."the_sun",
    cards.."judgement",
    cards.."the_world",
}

local extension = {}

local ItemConfig = Isaac.GetItemConfig()
local inverted_cards_inline_sprite = Sprite("gfx/ui/eid_inline_cardfronts.anm2", true)

-- Gets a random inverted card
---@param rng? RNG
---@return integer
function ARAOI.Inverted_Cards.GetRandomCard(rng)
    if rng == nil then rng = RNG(math.random(9999999999)) end
    return rng:RandomInt(ARAOI.CardSubType.INVERTED_FOOL, ARAOI.CardSubType.INVERTED_FOOL + ARAOI.CardSubType.NUM_CARDS)
end

for _, path in ipairs(files) do
    local card = include(path)

    if not card.Replace or not card.ID then
        error("Error loading card "..path)
    end

    ---@param rng RNG
    ---@param currentCard Card
    ARAOI.Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == card.Replace then
            local multiplier = PlayerManager.GetTotalTrinketMultiplier(ARAOI.TrinketType.INVERTED_SPADES)

            local chance = card.REPLACE_CHANCE ~= nil and card.REPLACE_CHANCE or Config.REPLACE_CHANCE
            chance = chance + (ARAOI.Inverted_Spades.Config.REPLACE_CHANCE_ADDED * multiplier)
            if rng:RandomFloat() <= (chance/100) then
                return card.ID
            end
        end
    end)

    ---@type EID
    if EID then
        local card_name = ItemConfig:GetCard(card.ID).HudAnim
        EID:addIcon("Card"..card.ID, card_name, -1, 9, 9, 4, 7, inverted_cards_inline_sprite)
    end
end

return extension