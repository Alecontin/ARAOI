----------------------------
-- START OF CONFIGURATION --
----------------------------



local NUM_MOM_ITEMS_TO_GIVE = 5 -- *Default: `5` — The number of Mom items to give to the player*



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
    local game = Game()
    local ItemConfig = Isaac:GetItemConfig()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(card.ID)

        ---@diagnostic disable-next-line: param-type-mismatch
        local mom_items = ItemConfig:GetTaggedItems(ItemTag.TAG_MOM)

        helper.table.ShuffleTable(mom_items, rng)

        for i = 1, NUM_MOM_ITEMS_TO_GIVE do
            player:AddCollectibleEffect(mom_items[i].ID, true)
        end

        local show = 1
        Isaac.CreateTimer(function ()
            local hud = game:GetHUD()
            local item = mom_items[show]
            hud:ShowItemText(player, item)

            if item.Type == ItemType.ITEM_ACTIVE then
                player:UseActiveItem(item.ID)
            end

            show = show + 1
        end, 30, NUM_MOM_ITEMS_TO_GIVE, false)
    end, card.ID)

    ---@type EID
    if EID then
        EID:addCard(card.ID,
            "#{{Mom}} Gives Isaac "..NUM_MOM_ITEMS_TO_GIVE.." random Mom item effects for the room"
        )
    end
end

return card