---@class ModReference
local Mod = RegisterMod("ARAOI", 1)

if not REPENTOGON then
    error("REPENTOGON IS MISSING! ARAOI WILL NOT WORK! PLEASE INSTALL REPENTOGON OR UNINSTALL THIS MOD!")
end

--[[

    This main file is only used for initializing all the different scripts
    If you want to modify the items, please look in the respective files

]]--

---@class ARAOI
ARAOI = {}
ARAOI.Mod = Mod

include("ARAOI")


local item = "scripts.items."

local active  = item.."active."
local passive = item.."passive."
local pocket  = item.."pocket."
local trinket = item.."trinket."

local files = {
    --[[ ACTIVE ITEMS ]]--
    active.."eternal_dplopia",
    active.."rubiks_cube",
    active.."3d_glasses",
    active.."bag_of_holding",
    active.."glass_die",
    active.."spellbook",
    active.."wire_cutter",

    --[[ PASSIVE ITEMS ]]--
    passive.."gambling_chips",
    passive.."sacrificial_heart",
    passive.."duality_halo",
    passive.."rainbow_headband",
    passive.."blessings_petal",
    passive.."voodoo_body",
    passive.."vampire_cloak",
    passive.."lucky_coin",

    --[[ POCKET ITEMS ]]--
    pocket.."inverted_cards",

    --[[ TRINKETS ]]--
    trinket.."spare_battery",
    trinket.."solved_rubiks_cube",
    trinket.."inverted_spades",

    --[[ DEBUGGING ]]--
    "debug.code"
}

for _, path in ipairs(files) do
    if path == "debug.code" then
        pcall(function ()
            include(path)
        end)
    else
        include(path)
    end
end

ARAOI.ReloadDescriptions()