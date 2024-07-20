---@class ModReference
local Mod = RegisterMod("ARAOI", 1)

if not REPENTOGON then
    error("REPENTAGON IS MISSING, ARAOI WILL NOT WORK. PLEASE INSTALL REPENTAGON OR UNINSTALL THIS MOD!")
end

--[[

    This main file is only used for initializing all the different scripts
    If you want to modify the items, please look in the respective files

]]--

require("scripts.SaveDataManager"):init(Mod)

local item = "scripts.items."

local active  = item.."active."
local passive = item.."passive."
local pocket  = item.."pocket."
local trinket = item.."trinket."

local files = {
    --[[ ACTIVE ITEMS ]]--
    active.."eternal_dplopia",
    active.."rubiks_cube", -- + Trinket
    active.."3d_glasses",
    active.."bag_of_holding",

    --[[ PASSIVE ITEMS ]]--
    passive.."gambling_chips",
    passive.."sacrificial_heart",
    passive.."duality_halo",
    passive.."rainbow_headband",
    passive.."blessings_petal",

    --[[ POCKET ITEMS ]]--
    pocket.."inverted_cards",

    --[[ TRINKETS ]]--
    trinket.."spare_battery",

    --[[ DEBUGGING ]]--
    "debug.code"
}

for _, path in ipairs(files) do
    if path == "debug.code" then
        pcall(function ()
            include(path):init(Mod)
        end)
    else
        include(path):init(Mod)
    end
end