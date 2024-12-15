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

---@param set? boolean
---@return boolean
function ARAOI.Blessings_Petal.HasPickedUpBlessingsPetal(set)
    return ARAOI.SaveData:Key(ARAOI.SaveData.PERSISTENT, "hasPickedUpBlessingsPetal", false, set)
end


-- Save the fact that the item has been picked up
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function ()
    ARAOI.Blessings_Petal.HasPickedUpBlessingsPetal(true)
end, ARAOI.CollectibleType.BLESSINGS_PETAL)


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

---@param isContinued boolean
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function (_, isContinued)
    local game = Game()

    -- Only spawn a pickup if it's a new run and you previously picked up the item
    if ARAOI.Blessings_Petal.HasPickedUpBlessingsPetal() and not isContinued then
        -- Reset the data
        ARAOI.Blessings_Petal.HasPickedUpBlessingsPetal(false)

        -- Get some necessary data
        local player = Isaac.GetPlayer()
        local room = game:GetRoom()

        -- Spawn a pickup according to the weights
        Isaac.Spawn(EntityType.ENTITY_PICKUP, ARAOI.ItemUtils.GetRandomPickup(nil, nil, nil, nil, nil, nil, nil, true), 0,
        room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, nil)
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
        ARAOI.PlayerUtils.ModifyFireDelay(player, -0.35 * ARAOI.PlayerUtils.GetAproxTearRateMultiplier(player), true)
    end
    if cacheFlag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + 1
    end
end)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.ReloadableDescription(function ()
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