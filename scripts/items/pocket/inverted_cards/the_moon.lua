local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Moon")
card.Replace = Card.CARD_REVERSE_MOON

---@type helper
local helper = include("scripts.helper")

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(card.ID)
        local level = game:GetLevel()

        -- If we aren't in the normal or mirror dimension, do nothing
        if not helper.table.IsValueInTable(level:GetDimension(), {Dimension.NORMAL, Dimension.MIRROR}) then
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

        local location = helper.table.Choice(locations_curated, nil, rng)

        -- We couldn't fint a valid location
        if location == nil then
            game:StartRoomTransition(level:GetRandomRoomIndex(true, rng:Next()), Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
            return
        end

        -- Place the room and teleport
        level:TryPlaceRoom(dice_room, location, Dimension.NORMAL)
        level:TryPlaceRoom(dice_room, location, Dimension.MIRROR)
        game:StartRoomTransition(location, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{DiceRoom}} Spawns a Dice Room and teleports Isaac to it"..
            "# If a Dice Room can't be generated, teleports Isaac to a random room"
        )
    end
end

return card