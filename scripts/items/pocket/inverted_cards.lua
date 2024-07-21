local cards = "scripts.items.pocket.inverted_cards."

-- The chance that a card will be overwritten
-- Cards might have a ReplaceChance inside their config, which will be used instead of this global chance
-- If they do, there will be "--" next to the file name below
local ReplaceChance = 0.25

local files = {
    --[[ Example of a card that has a ReplaceChance overwrite:
    cards.."card_script", --
                          ^^
    If a card is marked that way, go inside the script and
    search for "card.ReplaceChance = #.##" near the top, you can modify the value there
    or simply delete or comment the line
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

---@param Mod ModReference
function extension:init(Mod)
    for _, path in ipairs(files) do
        local card = include(path)
        card:init(Mod)

        if not card.Replace or not card.ID then
            error("Error loading card "..path)
        end

        ---@param rng RNG
        ---@param currentCard Card
        Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
            local chance = card.ReplaceChance or ReplaceChance
            if currentCard == card.Replace and rng:RandomFloat() <= chance then
                return card.ID
            end
        end)
    end
end

return extension