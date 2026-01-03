local card = {}

card.ID = ARAOI.CardSubType.INVERTED_SUN
card.Replace = Card.CARD_REVERSE_SUN

ARAOI.Inverted_Cards.Sun = card

local CursesToAdd = {
    LevelCurse.CURSE_OF_DARKNESS,
    LevelCurse.CURSE_OF_MAZE,
    LevelCurse.CURSE_OF_THE_LOST,
    LevelCurse.CURSE_OF_THE_UNKNOWN,
    LevelCurse.CURSE_OF_BLIND
}

-- Register a curse to be added when this card is used
---@param curse LevelCurse
function ARAOI.Inverted_Cards.Sun.AddCurse(curse)
    table.insert(CursesToAdd, curse)
end

---@param player EntityPlayer
---@param set? boolean
local function CardEffect(player, set)
    return ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "CardEffectInvertedSun", {}, ARAOI.PlayerUtils.GetId(player), false, set)
end


local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnInvertedCardSunUse(_, player, useFlags)
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
        ---@diagnostic disable-next-line: param-type-mismatch
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        return
    end

    player:AddCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)
    player:AddCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB)

    CardEffect(player, true)

    for _, curse in ipairs(CursesToAdd) do
        level:AddCurse(curse, false)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardSunUse, card.ID)

function ARAOI:_OnInvertedCardSunNewLevel()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if CardEffect(player) then
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)
            player:RemoveCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB)
            CardEffect(player, false)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ARAOI._OnInvertedCardSunNewLevel)

function ARAOI:_OnInvertedCardSunGetCollectible(selectedCollectible, poolType, decrease, seed)
    if selectedCollectible ~= CollectibleType.COLLECTIBLE_BLACK_CANDLE then return end

    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if CardEffect(player) then
            return game:GetItemPool():GetCollectible(poolType, decrease, seed)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, ARAOI._OnInvertedCardSunGetCollectible)

ARAOI.EIDWrapper(function ()
    local damocles = CollectibleType.COLLECTIBLE_DAMOCLES
    EID:addCard(card.ID,
        "#{{Collectible"..damocles.."}} Gives Isaac all curses, Damocles and Sacred Orb for the floor"..
        "#!!! Only works at the start of a new floor, otherwise it will act like {{Card"..card.Replace.."}} The Sun?"
    )
end)

return card