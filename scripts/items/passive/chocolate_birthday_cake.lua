-----------------------------
-- CONSTANTS AND VARIABLES --
-----------------------------

local game = Game()


-----------------------
-- ITEM AVAILABILITY --
-----------------------

-- Function that rerolls the item if the game is not played withing a time period
function ARAOI:_OnChocolateBirthdayCakeGetCollectible(collectible, pool, decrease, seed)
    -- If the collectible is our item
    if collectible == ARAOI.CollectibleType.CHOCOLATE_BIRTHDAY_CAKE then
        -- Get the current date
        local date = os.date("*t")
        -- If the month is March and the day is between 7 and 14
        if date.month == 3 and date.day >= 7 and date.day <= 14 then
            -- We can allow the item to spawn
            return collectible

        -- Otherwise
        else
            -- Try to get another item
            return game:GetItemPool():GetCollectible(pool, decrease, seed)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, ARAOI._OnChocolateBirthdayCakeGetCollectible)


-------------------------
--- MAIN FUNCTIONALITY --
-------------------------

-- Function that adds a Mystery Gift on the pedestals item cycle
---@param pickup EntityPickup
---@param ignoreModifiers any
function ARAOI:_OnChocolateBirthdayCakeAddPresentToItemCycle(pickup, _, _, _, _, _, ignoreModifiers)
    -- If no-one has our item, we end early
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.CHOCOLATE_BIRTHDAY_CAKE) then return end

    -- If the pickup is not a collectible, we end early
    if not ARAOI.ItemUtils.IsCollectible(pickup) then return end

    -- If the spawned collectible is meant to spawn without modifiers, we end early
    if ignoreModifiers == true then return end

    -- Get the rng
    local rng = PlayerManager.FirstCollectibleOwner(ARAOI.CollectibleType.CHOCOLATE_BIRTHDAY_CAKE)
    :GetCollectibleRNG(ARAOI.CollectibleType.CHOCOLATE_BIRTHDAY_CAKE)

    -- Get the chance
    local chance = rng:RandomFloat()

    -- If the chance is 10 or lower
    if chance <= 0.10 then
        -- Add a Mystery Gift to the collectible cycle 
        pickup:AddCollectibleCycle(CollectibleType.COLLECTIBLE_MYSTERY_GIFT)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_PICKUP_MORPH, ARAOI._OnChocolateBirthdayCakeAddPresentToItemCycle)
ARAOI:AddCallback(ModCallbacks.MC_POST_PICKUP_SELECTION, ARAOI._OnChocolateBirthdayCakeAddPresentToItemCycle)

-- Function that tries to spawn a Mystery Gift to collectibles in a new unexplored room
function ARAOI:_OnChocolateBirthdayCakeNewRoom()
    -- If it's not the first visit to this room, we end early
    if not game:GetRoom():IsFirstVisit() then return end

    -- Check every entity
    for _,entity in ipairs(Isaac.GetRoomEntities()) do
        -- Try to turn the entity into a pickup
        local pickup = entity:ToPickup()
        -- If we succeeded and the pickup is a collectible
        if pickup and ARAOI.ItemUtils.IsCollectible(pickup) then
            -- Call the function to add the Mystery Gift to the cycle
			---@diagnostic disable-next-line: missing-parameter
            ARAOI:_OnChocolateBirthdayCakeAddPresentToItemCycle(pickup)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnChocolateBirthdayCakeNewRoom)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.CHOCOLATE_BIRTHDAY_CAKE,
        "#{{Collectible"..CollectibleType.COLLECTIBLE_MYSTERY_GIFT.."}} 10% chance to add a Mystery Gift to a pedestals item cycle"..
        "# My birthday is on March 7th!"
    )
end)