-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Blessings_Petal = {}


---------------
-- FUNCTIONS --
---------------

---@param add? integer -- How many pickups to add. Set to `0` to reset, `nil` to get the current value
---@return boolean
function ARAOI.Blessings_Petal.PickupCount(add)
    if add and add == 0 then
        return ARAOI.SaveData:Key(ARAOI.SaveData.PERSISTENT, "blessingsPetalPickupCount", 0, 0)
    elseif add then
        local count = ARAOI.SaveData:Key(ARAOI.SaveData.PERSISTENT, "blessingsPetalPickupCount", 0)
        return ARAOI.SaveData:Key(ARAOI.SaveData.PERSISTENT, "blessingsPetalPickupCount", 0, math.min(2, count + add))
    else
        return ARAOI.SaveData:Key(ARAOI.SaveData.PERSISTENT, "blessingsPetalPickupCount", 0)
    end
end


-- Save the fact that the item has been picked up
---@param firstTime boolean
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, _, _, firstTime)
    if firstTime then
        ARAOI.Blessings_Petal.PickupCount(1)
    end
end, ARAOI.CollectibleType.BLESSINGS_PETAL)


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

---@param isContinued boolean
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function (_, isContinued)
    local game = Game()

    -- Get how many times we picked up our item
    local pickupCount = ARAOI.Blessings_Petal.PickupCount()

    -- If the run is not continued (A.K.A. we started a new run)
    -- and we picked up at least 1 of our item
    if not isContinued and pickupCount > 0 then
        -- Get some necessary data
        local player = Isaac.GetPlayer()
        local room = game:GetRoom()

        -- Repeat this as many times as we picked up our item
        for _ = 1, pickupCount do
            -- Spawn a pickup according to the weights
            Isaac.Spawn(EntityType.ENTITY_PICKUP, ARAOI.ItemUtils.GetRandomPickup(nil, nil, nil, nil, nil, nil, nil, true), 0,
            room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, nil)
        end

        -- Reset the pickup count
        ARAOI.Blessings_Petal.PickupCount(0)
    end
end)


----------------
-- ITEM STATS --
----------------

---@param player EntityPlayer
---@param cacheFlag CacheFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, cacheFlag)
    if not player:HasCollectible(ARAOI.CollectibleType.BLESSINGS_PETAL) then return end

    if cacheFlag == CacheFlag.CACHE_FIREDELAY and not player:HasCollectible(CollectibleType.COLLECTIBLE_EDENS_BLESSING) then
        ARAOI.PlayerUtils.AddFireDelay(player, -0.35 * ARAOI.PlayerUtils.GetAproxTearRateMultiplier(player), true)
    end
    if cacheFlag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + 1
    end
end)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.BLESSINGS_PETAL,
        "#{{ArrowUp}} +0.35 Tears"..
        "#{{ArrowUp}} +1 Luck"..
        "# Spawns a random pickup at the start of the next run"..
        "# Pickups can be any variant of: #{{Blank}} {{Coin}} {{Key}} {{Bomb}} {{Heart}} {{Battery}} {{Chest}}"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Blessing's Petal Abyss Synergy",
        ARAOI.CollectibleType.BLESSINGS_PETAL,
        "Small white locust that deals 0.5x Isaac's damage"
    )
end)