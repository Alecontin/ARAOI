---@class ModReference
local Mod = RegisterMod("ARAOI", 1)

if not REPENTOGON then
    error("REPENTAGON IS MISSING, ARAOI WILL NOT WORK. PLEASE INSTALL REPENTAGON OR UNINSTALL THIS MOD!")
end

-- There's no EID:addGoldenTrinketMetadata() for cards? That's weird... Or maybe I'm the weird one...
if EID then
    -- @_param_ `changes`
    --
    -- _type_ `string` — Text will be appended to the description
    --
    -- _type_ `string[]` — Replaces index 1 with 2, 3 with 4, etc. So passing in `{" a ", " a lot ", " an ", " two "}` will replace `" a "` with `" a lot "` and `" an "` with `" two "`
    --
    -- _type_ `number[]` — Replaces index 1 with 2, 3 with 4, etc. So passing in `{1, 2, 0.6, 0.8}` will replace `1` with `2` and `0.6` with `0.8`
    ---@param id Card
    ---@param changes string | string[] | number[]
    ---@param language any?
    function EID:addTarotClothMetadata(id, changes, language)
        include("scripts.utils.eidutils").TarotClothMetadata(id, changes, language)
    end
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
    pocket.."inverted_cards", -- + Trinket

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