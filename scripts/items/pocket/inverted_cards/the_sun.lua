local card = {}

card.ID = ARAOI.CardSubType.INVERTED_SUN
card.Replace = Card.CARD_REVERSE_SUN

ARAOI.Inverted_Cards.Sun = card

---@param player EntityPlayer
---@param set? boolean
local function CardEffect(player, set)
    return ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "CardEffectInvertedSun", {}, ARAOI.PlayerUtils.GetID(player), false, set)
end


local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end

    local level = game:GetLevel()

    local function numRoomsVisited()
        local visits = 0
        local rooms = level:GetRooms()
        for i = 1, rooms.Size - 1 do
            local map_room = rooms:Get(i)
            if map_room then
                visits = visits + map_room.VisitedCount
            end
        end

        return visits
    end

    if numRoomsVisited() ~= 1 then
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        return
    end

    player:AddCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)
    player:AddCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB)

    CardEffect(player, true)

    level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
    level:AddCurse(LevelCurse.CURSE_OF_MAZE, false)
    level:AddCurse(LevelCurse.CURSE_OF_THE_LOST, false)
    level:AddCurse(LevelCurse.CURSE_OF_THE_UNKNOWN, false)
    level:AddCurse(LevelCurse.CURSE_OF_BLIND, false)
end, card.ID)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if CardEffect(player) then
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB)
            CardEffect(player, false)
        end
    end
end)

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, function (_, selectedCollectible, poolType, decrease, seed)
    if selectedCollectible ~= CollectibleType.COLLECTIBLE_BLACK_CANDLE then return end

    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if CardEffect(player) then
            return game:GetItemPool():GetCollectible(poolType, decrease, seed)
        end
    end
end)

ARAOI.ReloadableDescription(function ()
    local damocles = CollectibleType.COLLECTIBLE_DAMOCLES
    EID:addCard(card.ID,
        "#{{Collectible"..damocles.."}} Gives Isaac all curses, Damocles and Sacred Orb for the floor"..
        "#!!! Only works at the start of a new floor, otherwise it will act like {{Card"..card.Replace.."}} The Sun?"
    )
end)

return card