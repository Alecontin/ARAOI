local card = {}

card.ID = Isaac.GetCardIdByName("Inverted World")
card.Replace = Card.CARD_REVERSE_WORLD

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
        if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
        local level = game:GetLevel()
        local crawlspace = level:GetRoomByIdx(-4)

        if crawlspace.VisitedCount == 0 then
            local leading_to_blackmarket = RoomConfigHolder.GetRoomByStageTypeAndVariant(StbType.SPECIAL_ROOMS, RoomType.ROOM_DUNGEON, 1)
            crawlspace.Data = leading_to_blackmarket
        end

        Isaac.GridSpawn(GridEntityType.GRID_STAIRS, 0, player.Position)
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{BlackSack}} Spawns a crawlspace leading to a Black Market"..
            "#{{LadderRoom}} If the floor's crawlspace has already been visited, it will lead there instead"
        )
    end
end

return card