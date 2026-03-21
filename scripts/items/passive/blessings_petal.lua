-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Blessings_Petal = {}

local TEARS_EFFECT = Isaac.GetNullItemIdByName("Blessing's Petal Tears")

---------------
-- FUNCTIONS --
---------------

---@param add? integer -- How many pickups to add. Set to `0` to reset, `nil` to get the current value
---@return boolean
function ARAOI.Blessings_Petal.PickupCount(add)
    if add and add == 0 then
        return ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.PERSISTENT, "blessingsPetalPickupCount", 0, 0)
    elseif add then
        local count = ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.PERSISTENT, "blessingsPetalPickupCount", 0)
        return ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.PERSISTENT, "blessingsPetalPickupCount", 0, math.min(2, count + add))
    else
        return ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.PERSISTENT, "blessingsPetalPickupCount", 0)
    end
end


-- Save the fact that the item has been picked up
---@param player EntityPlayer
---@param firstTime boolean
function ARAOI:_OnBlessingsPetalAddCollectible(player, _, firstTime)
    if firstTime then
        ARAOI.Blessings_Petal.PickupCount(1)
        player:GetEffects():AddNullEffect(TEARS_EFFECT, false, 1)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, ARAOI._OnBlessingsPetalAddCollectible, ARAOI.CollectibleType.BLESSINGS_PETAL)


-- Remove stats from the player
---@param player EntityPlayer
function ARAOI:_OnBlessingsPetalRemoveCollectible(player)
    player:GetEffects():RemoveNullEffect(TEARS_EFFECT)
end
ARAOI:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, ARAOI._OnBlessingsPetalAddCollectible, ARAOI.CollectibleType.BLESSINGS_PETAL)


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

---@param isContinued boolean
function ARAOI:_OnBlessingsPetalGameStarted(isContinued)
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
end
ARAOI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, ARAOI._OnBlessingsPetalGameStarted)


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
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.BLESSINGS_PETAL, "1 locust (0.5x Isaac's damage)")
end)