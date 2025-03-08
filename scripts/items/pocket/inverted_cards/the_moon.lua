local card = {}

card.ID = ARAOI.CardSubType.INVERTED_MOON
card.Replace = Card.CARD_REVERSE_MOON

ARAOI.Inverted_Cards.Mood = card

local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end

    local rng = player:GetCardRNG(card.ID)
    local level = game:GetLevel()

    -- If we aren't in the normal or mirror dimension, do nothing
    if not ARAOI.TableUtils.IsValueInTable(level:GetDimension(), {Dimension.NORMAL, Dimension.MIRROR}) then
        return
    end

    -- If there's already a Dice Room, teleport to it instead
    local dice_room_idx = level:QueryRoomTypeIndex(RoomType.ROOM_DICE, false, rng)
    local spawned_dice_room = level:GetRoomByIdx(dice_room_idx)
    if spawned_dice_room.Data.Type == RoomType.ROOM_DICE then
        return game:StartRoomTransition(dice_room_idx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
    end

    local dice_room = RoomConfigHolder.GetRandomRoom(rng:Next(), false, StbType.SPECIAL_ROOMS, RoomType.ROOM_DICE)

    ---@type integer[]
    local location_indexes = level:FindValidRoomPlacementLocations(dice_room, nil, false)

    -- We need to curate the rooms since the Dice Room can spawn next to a secret room
    -- making the player use bombs to get out and potentially leading to a soft-lock
    local locations_curated = {}
    for _, index in ipairs(location_indexes) do
        local neighbors = level:GetNeighboringRooms(index, dice_room.Shape)
        for _, room_descriptor in pairs(neighbors) do
            if room_descriptor.Data.Type == RoomType.ROOM_SECRET or room_descriptor.Data.Type == RoomType.ROOM_SUPERSECRET then
                goto continue
            end
        end

        table.insert(locations_curated, index)
        ::continue::
    end

    local location = ARAOI.TableUtils.Choice(locations_curated, nil, rng)

    -- We couldn't find a valid location
    if location == nil then
        game:StartRoomTransition(level:GetRandomRoomIndex(true, rng:Next()), Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
        return
    end

    -- Place the room and teleport
    level:TryPlaceRoom(dice_room, location, Dimension.NORMAL)
    level:TryPlaceRoom(dice_room, location, Dimension.MIRROR)
    game:StartRoomTransition(location, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
end, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{DiceRoom}} Spawns a Dice Room and teleports Isaac to it"..
        "# If a Dice Room can't be generated, teleports Isaac to a random room"
    )
end)

return card