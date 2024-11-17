---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Sun")
card.Replace = Card.CARD_REVERSE_SUN

---@param player EntityPlayer
---@param set? boolean
local function CardEffect(player, set)
    return SaveData:Data(SaveData.RUN, "CardEffectInvertedSun", {}, helper.player.GetID(player), false, set)
end

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
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

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if CardEffect(player) then
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_SACRED_ORB)
                CardEffect(player, false)
            end
        end
    end)

    Mod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, function (_, selectedCollectible, poolType, decrease, seed)
        if selectedCollectible ~= CollectibleType.COLLECTIBLE_BLACK_CANDLE then return end

        for _, player in ipairs(PlayerManager.GetPlayers()) do
            if CardEffect(player) then
                return game:GetItemPool():GetCollectible(poolType, decrease, seed)
            end
        end
    end)

    ---@class EID
    if EID then
        local damocles = CollectibleType.COLLECTIBLE_DAMOCLES
        EID:addCard(card.ID,
            "#{{Collectible"..damocles.."}} Gives Isaac all curses, Damocles and Sacred Orb for the floor"..
            "#!!! Only works at the start of a new floor, otherwise it will act like {{Card"..card.Replace.."}} The Sun?"
        )
    end
end

return card