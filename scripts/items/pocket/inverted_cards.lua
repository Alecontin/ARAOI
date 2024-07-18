local card = "scripts.items.pocket.inverted_cards."

local files = {
    card.."the_fool",
    card.."the_magician",
    card.."the_high_priestess",
    card.."the_empress",
    card.."the_emperor",
    card.."the_hermit",
    card.."the_hierophant",
    card.."the_lovers",
    card.."the_chariot",
    card.."justice",
    card.."wheel_of_fortune",
    card.."strength",
    card.."the_hanged_man",
    card.."death",
    card.."temperance",
    card.."the_devil",
    card.."the_tower",
    card.."the_stars",
    card.."the_moon",
    card.."the_sun",
    card.."judgement",
    card.."the_world",
}

local extension = {}

extension.ReplaceChance = 0.25

---@param Mod ModReference
function extension:init(Mod)
    for _, path in ipairs(files) do
        include(path):init(Mod)
    end
end

return extension