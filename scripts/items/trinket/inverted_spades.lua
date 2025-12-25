local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.REPLACE_CHANCE_ADDED = 15 -- *Default: `15` — Chance added to the replacement chance of Inverted Cards*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Inverted_Spades = {}
ARAOI.Inverted_Spades.Config = Config


---------------------
-- TRINKET SPAWNER --
---------------------

---@param trinketType TrinketType
function ARAOI:_OnInvertedSpadesGetTrinket(trinketType, _)
    -- Is the game trying to spawn our trinket without any reverse cards unlocked?
    if trinketType == ARAOI.TrinketType.INVERTED_SPADES and not ARAOI.MiscUtils.IsAnyReverseCardUnlocked() then
        -- Nuh uh! Try again!
        return Game():GetItemPool():GetTrinket()
    end
end
ARAOI:AddCallback(ModCallbacks.MC_GET_TRINKET, ARAOI._OnInvertedSpadesGetTrinket)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addTrinket(ARAOI.TrinketType.INVERTED_SPADES, "Increases chance for Reverse Cards to be replaced with Inverted Cards by "..Config.REPLACE_CHANCE_ADDED.."%")
    EID:addGoldenTrinketMetadata(ARAOI.TrinketType.INVERTED_SPADES, nil, Config.REPLACE_CHANCE_ADDED, 3)
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Trinkets", "Inverted Spades")

    ARAOI.MCMUtils.AddNumberSetting("Trinkets", "Inverted Spades", Config, "REPLACE_CHANCE_ADDED",
    ConfigDefaults, ConfigDefaults.REPLACE_CHANCE_ADDED .. "%", 0, 100, 10, function ()
        return "Chance Added: " .. Config.REPLACE_CHANCE_ADDED .. "%"
    end, "Chance added to the replacement chance of Inverted Cards")

    ARAOI.MCMUtils.AddReset("Trinkets", "Inverted Spades")
end