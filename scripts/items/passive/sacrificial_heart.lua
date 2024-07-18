----------------------------
-- START OF CONFIGURATION --
----------------------------



local BROKEN_HEARTS = 2 -- *Default: `2` — The ammount of broken hearts the player will get. T. Magdalene will multiply this by 2.*



--------------------------
-- END OF CONFIGURATION --
--------------------------

local SACRIFICIAL_HEART = Isaac.GetItemIdByName("Sacrificial Heart")

---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()


    ---------------------
    -- HEALTH DECREASE --
    ---------------------

    ---@param player EntityPlayer
    local function giveBrokenHearts(_, _, _, firstTime, _, _, player)
        -- Check if the health was already applied, we shouldn't re-apply the broken hearts if T. Isaac juggles the item around
        if firstTime then

            -- T. Magdalene nerf since she's the character that will benefit from this item the most
            if player:GetPlayerType() == PlayerType.PLAYER_MAGDALENE_B then
                player:AddBrokenHearts(BROKEN_HEARTS * 2)
            else
                player:AddBrokenHearts(BROKEN_HEARTS)
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, giveBrokenHearts, SACRIFICIAL_HEART)


    -----------------------------
    -- MAIN ITEM FUNCTIONALITY --
    -----------------------------

    local function changeCurseIntoSacrifice(_)
        -- Shouldn't change curse rooms if we don't have the item
        if not PlayerManager.AnyoneHasCollectible(SACRIFICIAL_HEART) then return end

        -- Shouldn't do anything in greed mode, this is also how Voodoo Head works
        if game:IsGreedMode() then return end

        -- Define level and rooms
        local level = game:GetLevel()
        local rooms = level:GetRooms()

        -- Check every room
        for i = 0, #rooms-1 do
            -- Which room are we checking?
            local room = rooms:Get(i)

            -- Get the room data
            local data = room.Data

            -- Check if the data matches a curse room
            if data and data.Type == RoomType.ROOM_CURSE then

                -- Define the room overwrite
                local override = RoomConfigHolder.GetRandomRoom(
                    room.SpawnSeed,
                    true,
                    StbType.SPECIAL_ROOMS,
                    RoomType.ROOM_SACRIFICE,
                    data.Shape
                )

                -- Set the room's data to the new overwrite
                room.Data = override

            end
        end

        -- Get the spawn room, we do this because the door doesn't update
        -- when we overwrite the data, so we need to update it manually
        local spawn_room = game:GetRoom()

        -- Check all possible door spots in the room
        for i = 1,4 do
            -- Try to get the door
            local door = spawn_room:GetDoor(i)

            -- Check if the door exists and it was supposed to lead to a curse room
            if door and door.TargetRoomType == RoomType.ROOM_CURSE then
                -- Set the new destination
                door:SetRoomTypes(spawn_room:GetType(), RoomType.ROOM_SACRIFICE)
            end
        end
        
        -- Lastly update the map visibility, otherwise sacrifice rooms would appear
        -- as curse rooms on the map if you used The World or had The Mind
        ---@class MinimapAPI
        if MinimapAPI then
            for _,room in ipairs(MinimapAPI:GetLevel()) do
                if room.Type == RoomType.ROOM_CURSE then
                    room.Type = RoomType.ROOM_SACRIFICE
                    room.PermanentIcons = {"SacrificeRoom"}
                end
            end
        else
            level:UpdateVisibility()
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, changeCurseIntoSacrifice)



    -----------------------------
    -- VOODOO HEAD INTERACTION --
    -----------------------------

    local function onSacrificeRoomEnter(_)
        -- Check if we have the synergy
        if not (PlayerManager.AnyoneHasCollectible(SACRIFICIAL_HEART) and
                PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD))
        then return end

        -- Get the room that the player entered
        local room = game:GetRoom()

        -- We should only spawn chests once
        if not room:IsFirstVisit() then return end

        -- Is the room a sacrifice room?
        if room:GetType() ~= RoomType.ROOM_SACRIFICE then return end

        -- Get some positions
        local center = room:GetCenterPos()
        local offset = 34*3
        local left = center + Vector(-offset, 0)
        local right = center + Vector(offset, 0)
        local down = center + Vector(0, 50)

        -- Spawn the chests, we do it in a for loop to avoid repeating ourselves
        for _, pos in pairs({left, right}) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_REDCHEST,
                ChestSubType.CHEST_CLOSED,
                room:FindFreePickupSpawnPosition(pos, 0, true, false),
                Vector.Zero,
                nil
            )
        end

        -- That being said...
        -- But it's a coin instead of a chest!!
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COIN,
            CoinSubType.COIN_PENNY,
            down,
            Vector.Zero,
            nil
        )
    end
    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, onSacrificeRoomEnter)

    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then
        EID:addCollectible(
            SACRIFICIAL_HEART, 
            "#{{BrokenHeart}} +"..BROKEN_HEARTS.." Broken Hearts"..
            "# Changes all curse rooms {{CursedRoom}} into sacrifice rooms {{SacrificeRoom}}"..
            "# Change triggers on new floor"
        )

        local function condition(descObj)
            return descObj.ObjSubType == SACRIFICIAL_HEART and Helper.AnyPlayerIs(PlayerType.PLAYER_MAGDALENE_B)
        end
        local function modifier(descObj)
            EID:appendToDescription(descObj, "#{{Player22}} {{BrokenHeart}} +"..(BROKEN_HEARTS*2).." broken hearts instead of "..BROKEN_HEARTS)
            return descObj
        end
        EID:addDescriptionModifier("Sac Heart T. Magdalene", condition, modifier)


        local function condition(descObj)
            return (descObj.ObjSubType == SACRIFICIAL_HEART and PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD)) or
                   (descObj.ObjSubType == CollectibleType.COLLECTIBLE_VOODOO_HEAD and PlayerManager.AnyoneHasCollectible(SACRIFICIAL_HEART))
        end
        local function modifier(descObj)
            local id
            if descObj.ObjSubType == SACRIFICIAL_HEART then
                id = CollectibleType.COLLECTIBLE_VOODOO_HEAD
            else
                id = SACRIFICIAL_HEART
            end
            EID:appendToDescription(descObj, "#{{Collectible"..id.."}} Will turn both cursed rooms {{CursedRoom}} into sacrifice rooms {{SacrificeRoom}}"..
                                             "#2 red chests {{RedChest}} and a coin {{Coin}} will now spawn inside sacrifice rooms {{SacrificeRoom}}")
            return descObj
        end
        EID:addDescriptionModifier("Sac Heart Voodoo Head Synergy", condition, modifier)
    end
end

return modded_item