local card = {}

card.ID = ARAOI.CardSubType.INVERTED_DEVIL
card.Replace = Card.CARD_REVERSE_DEVIL

ARAOI.Inverted_Cards.Devil = card

local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end

    local level = game:GetLevel()

    local rng = player:GetCardRNG(card.ID)

    local treasure_room_idx = level:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, rng)
    local treasure_room = level:GetRoomByIdx(treasure_room_idx)

    if treasure_room.Data.Type == RoomType.ROOM_TREASURE and treasure_room.VisitedCount == 0 then
        treasure_room.Flags = treasure_room.Flags | RoomDescriptor.FLAG_DEVIL_TREASURE
    end

    game:StartRoomTransition(treasure_room_idx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT)
end, card.ID)

ARAOI.ReloadableDescription(function ()
    local devils_crown = TrinketType.TRINKET_DEVILS_CROWN

    EID:addCard(card.ID,
        "#{{RedTreasureRoom}} Teleports Isaac to the Treasure Room, turning it into a {{Trinket"..devils_crown.."}} Devil Treasure Room if it hasn't been visited yet"
    )
end)

return card