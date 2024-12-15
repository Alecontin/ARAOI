local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.REPLACE_CHANCE_ADDED = 15 -- *Default: `15` — Chance added to the replacement chance of Inverted Cards*



--------------------------
-- END OF CONFIGURATION --
--------------------------


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Inverted_Spades = {}
ARAOI.Inverted_Spades.Config = Config


---------------------
-- TRINKET SPAWNER --
---------------------

---@param trinketType TrinketType
ARAOI.Mod:AddCallback(ModCallbacks.MC_GET_TRINKET, function (_, trinketType, _)
    -- Is the game trying to spawn our trinket without any reverse cards unlocked?
    if trinketType == ARAOI.TrinketType.INVERTED_SPADES and not ARAOI.MiscUtils.IsAnyReverseCardUnlocked() then
        -- Nuh uh! Try again!
        return Game():GetItemPool():GetTrinket()
    end
end)


----------------------
-- ITEM DESCRIPTION --
----------------------

---@type EID
if EID then
    EID:addTrinket(ARAOI.TrinketType.INVERTED_SPADES, "Increases chance for Reverse Cards to be replaced with Inverted Cards by "..Config.REPLACE_CHANCE_ADDED.."%")
    EID:addGoldenTrinketMetadata(ARAOI.TrinketType.INVERTED_SPADES, nil, Config.REPLACE_CHANCE_ADDED, 3)
end