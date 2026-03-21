if not REPENTOGON then
    error("REPENTOGON IS MISSING! ARAOI WILL NOT WORK! PLEASE INSTALL REPENTOGON OR UNINSTALL THIS MOD!")
end

--[[

    This main file is only used for initializing all the different scripts
    If you want to modify the items, please look in the respective files

]]--

---@class ModReference
ARAOI = RegisterMod("ARAOI", 1)

include("ARAOI")

if ModConfigMenu then
    ModConfigMenu.RemoveCategory("ARAOI")
    include("scripts.ModConfigMenu")
end


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
    active.."recycle",
    active.."gamblecore",
    active.."katana",
    active.."soda", -- & Passive
    active.."void_die",

    --[[ PASSIVE ITEMS ]]--
    passive.."gambling_chips",
    passive.."sacrificial_heart",
    passive.."duality_halo",
    passive.."rainbow_headband",
    passive.."blessings_petal",
    passive.."voodoo_body",
    passive.."vampire_cloak",
    passive.."lucky_coin",
    passive.."chocolate_birthday_cake",
    passive.."lunchbox",

    --[[ TRINKETS ]]--
    trinket.."spare_battery",
    trinket.."solved_rubiks_cube",
    trinket.."inverted_spades",
    trinket.."bountiful_sack",

    --[[ POCKET ITEMS ]]--
    pocket.."inverted_cards",

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

ARAOI.EIDReload()
ARAOI.MCMReload()

Isaac.RunCallback(ARAOI.ModCallbacks.OnReload)