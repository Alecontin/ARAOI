----------------------------
-- START OF CONFIGURATION --
----------------------------



local NUM_MINIISAAC = 10 -- *Default: `10` — The number of MiniIsaacs to spawn*



--------------------------
-- END OF CONFIGURATION --
--------------------------




---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Empress")
card.Replace = Card.CARD_REVERSE_EMPRESS

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        for _ = 1, NUM_MINIISAAC, 1 do
            player:AddMinisaac(player.Position)
        end
    end, card.ID)

    ---@type EID
    if EID then
        EID:addCard(card.ID,
            "#{{Player0}} Spawns "..NUM_MINIISAAC.." MiniIsaacs"
        )
    end
end

return card