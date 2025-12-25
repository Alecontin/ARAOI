local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.BROKEN_HEARTS = 2 -- *Default: `2` — The amount of broken hearts the player will get. T. Magdalene will multiply this by 2.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Sacrificial_Heart = {}
ARAOI.Sacrificial_Heart.Config = Config

local game = Game()


---------------------
-- HEALTH DECREASE --
---------------------

---@param player EntityPlayer
function ARAOI:_OnSacrificialHeartPreAddCollectible(_, _, firstTime, _, _, player)
    -- Check if the health was already applied, we shouldn't re-apply the broken hearts if T. Isaac juggles the item around
    if firstTime then

        -- T. Magdalene nerf since it's the character that will benefit from this item the most
        if player:GetPlayerType() == PlayerType.PLAYER_MAGDALENE_B then
            player:AddBrokenHearts(Config.BROKEN_HEARTS * 2)
        else
            player:AddBrokenHearts(Config.BROKEN_HEARTS)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, ARAOI._OnSacrificialHeartPreAddCollectible, ARAOI.CollectibleType.SACRIFICIAL_HEART)


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

function ARAOI:_OnSacrificialHeartNewLevel()
    -- Shouldn't change curse rooms if we don't have the item
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.SACRIFICIAL_HEART) then return end

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
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ARAOI._OnSacrificialHeartNewLevel)



-----------------------------
-- VOODOO HEAD INTERACTION --
-----------------------------

function ARAOI:_OnSacrificialHeartNewRoom()
    -- Check if we have the synergy
    if not (PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.SACRIFICIAL_HEART) and
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
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnSacrificialHeartNewRoom)

----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.SACRIFICIAL_HEART,
        "#{{BrokenHeart}} +"..Config.BROKEN_HEARTS.." Broken Hearts"..
        "# Turns {{CursedRoom}} Curse rooms into {{SacrificeRoom}} Sacrifice rooms"..
        "# Triggers on new floor"
    )

    ARAOI.EIDUtils.PlayerBasedModifier(
        "Sacrificial Heart Tainted Magdalene",
        ARAOI.CollectibleType.SACRIFICIAL_HEART,
        {PlayerType.PLAYER_MAGDALENE_B},
        PlayerType.PLAYER_MAGDALENE_B,
        "{{BrokenHeart}} +"..(Config.BROKEN_HEARTS*2).." broken hearts instead of "..Config.BROKEN_HEARTS
    )


    local function condition(descObj)
        return (descObj.ObjSubType == ARAOI.CollectibleType.SACRIFICIAL_HEART and PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD)) or
                (descObj.ObjSubType == CollectibleType.COLLECTIBLE_VOODOO_HEAD and PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.SACRIFICIAL_HEART))
    end
    local function modifier(descObj)
        local id
        if descObj.ObjSubType == ARAOI.CollectibleType.SACRIFICIAL_HEART then
            id = CollectibleType.COLLECTIBLE_VOODOO_HEAD
        else
            id = ARAOI.CollectibleType.SACRIFICIAL_HEART
        end
        EID:appendToDescription(descObj, "#{{Collectible"..id.."}} {{RedChest}} Red Chests and a {{Coin}} Coin will now spawn inside Sacrifice rooms")
        return descObj
    end
    EID:addDescriptionModifier("Sacrificial Heart Voodoo Head Synergy", condition, modifier)
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Passives", "Sacrificial Heart")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Sacrificial Heart", Config, "BROKEN_HEARTS", ConfigDefaults, ConfigDefaults.BROKEN_HEARTS, 0, 18, 5, function ()
        return "Broken Hearts: " .. Config.BROKEN_HEARTS
    end, "The base chance for a slot to spawn", "T. Magdalene will multiply this by 2")

    ARAOI.MCMUtils.AddReset("Passives", "Sacrificial Heart")
end