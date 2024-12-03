----------------------------
-- START OF CONFIGURATION --
----------------------------



-- The chance that a card will be overwritten
-- Cards might have a REPLACE_CHANCE inside their config, which will be used instead of this global chance
-- If they do, there will be "--" next to the file name below
local REPLACE_CHANCE = 0.15

local TRINKET_CHANCE_ADDED = 0.1 -- Default: `0.1` — Chance added when holding the Inverted Spades trinket, which is doubled with the golden variant and tripled if also holding Mom's Box



--------------------------
-- END OF CONFIGURATION --
--------------------------

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

local INVERTED_SPADES = Isaac.GetTrinketIdByName("Inverted Spades")

---@return boolean
local function IsAnyReverseCardUnlocked()
    local PGD = Isaac.GetPersistentGameData()
    for i = Achievement.REVERSED_FOOL, Achievement.REVERSED_WORLD, 1 do
        if PGD:Unlocked(i) == true then
            return true
        end
    end
    return false
end

local extension = {}

---@param Mod ModReference
function extension:init(Mod)
    local ItemConfig = Isaac.GetItemConfig()
    local inverted_cards_inline_sprite = Sprite("gfx/ui/eid_inline_cardfronts.anm2", true)

    for _, path in ipairs(files) do
        local card = include(path)
        card:init(Mod)

        if not card.Replace or not card.ID then
            error("Error loading card "..path)
        end

        ---@param rng RNG
        ---@param currentCard Card
        Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
            if currentCard == card.Replace then
                local chance = card.REPLACE_CHANCE or REPLACE_CHANCE
                chance = chance + (TRINKET_CHANCE_ADDED * (PlayerManager.AnyoneHasTrinket(INVERTED_SPADES) and 1 or 0) * PlayerManager.GetTotalTrinketMultiplier(INVERTED_SPADES))
                print(chance)
                if rng:RandomFloat() <= chance then
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

    ---@param trinketType TrinketType
    Mod:AddCallback(ModCallbacks.MC_GET_TRINKET, function (_, trinketType, _)
        if trinketType == INVERTED_SPADES and not IsAnyReverseCardUnlocked() then
            return Game():GetItemPool():GetTrinket()
        end
    end)

    ---@type EID
    if EID then
        local floored_chance = math.floor(TRINKET_CHANCE_ADDED*100)
        EID:addTrinket(INVERTED_SPADES, "Increases chance for Reverse Cards to be replaced with Inverted Cards by "..floored_chance.."%")
        EID:addGoldenTrinketMetadata(INVERTED_SPADES, nil, floored_chance, 3)
    end
end

return extension