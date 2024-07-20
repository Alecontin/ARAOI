---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@param player EntityPlayer
---@param set? boolean
local function CardEffect(player, set)
    return SaveData:Data(SaveData.RUN, "CardEffectInvertedSun", {}, Helper.GetPlayerId(player), false, set)
end

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Sun")
card.Replace = Card.CARD_REVERSE_SUN

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local level = game:GetLevel()

        local function NumRoomsVisited()
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

        if NumRoomsVisited() ~= 1 then
            player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            return
        end

        local rng = player:GetCardRNG(card.ID)

        for _, any_player in ipairs(Helper.GetPlayersWithCollectible(CollectibleType.COLLECTIBLE_BLACK_CANDLE)) do
            for _ = 1, any_player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BLACK_CANDLE) do
                any_player:RemoveCollectible(CollectibleType.COLLECTIBLE_BLACK_CANDLE)
                Helper.SpawnCollectiblePool(ItemPoolType.POOL_SHOP, room:FindFreePickupSpawnPosition(any_player.Position, 50), Vector.Zero, any_player, true, true, rng)
            end
        end

        player:AddCollectible(CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE)

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
        local candle = CollectibleType.COLLECTIBLE_BLACK_CANDLE
        local damocles = CollectibleType.COLLECTIBLE_DAMOCLES
        EID:addCard(card.ID,
            "#{{Collectible"..damocles.."}} Gives you all curses and Damocles for the floor"..
            "#{{Collectible"..candle.."}} Removes Black Candle and spawns an item from the {{Shop}} Shop item pool"..
            "#!!! Only works at the start of a new floor, otherwise it will act like {{Card"..card.Replace.."}} The Sun?"
        )
    end
end

return card