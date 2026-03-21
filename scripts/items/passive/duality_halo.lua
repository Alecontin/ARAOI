-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Duality_Halo = {}

local game = Game()


---------------
-- VARIABLES --
---------------

local devil_chance, angel_chance = 0, 0


---------------
-- FUNCTIONS --
---------------

-- Spawns the collectibles according to the `Devil_Angel_Chances`
---@param ignoreChances? boolean -- Should we ignore the deal spawn chance?
function ARAOI.Duality_Halo.SpawnCollectibles(ignoreChances)
    local room = game:GetRoom()
    local level = game:GetLevel()

    -- Don't spawn items if we are on Basement 1, since that's how it works in the game
    if level:GetStage() == LevelStage.STAGE1_1 and not (level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0) then return end

    -- Check grid entities
    for _, entity in ipairs(ARAOI.RoomUtils.GetGridEntities()) do
        -- Looking for doors
        local door = entity:ToDoor()
        if door then
            -- If the deal spawned, we don't need to continue
            if door.TargetRoomType == RoomType.ROOM_ANGEL
            or door.TargetRoomType == RoomType.ROOM_DEVIL
            then return end
        end
    end

    -- PickupOptionIndex to set the second item spawned to
    local option = nil

    -- Get the RNG and chance to spawn the items
    local rng = level:GetDevilAngelRoomRNG()
    local chance = rng:RandomFloat()
    if ignoreChances == true then chance = -1 end

    -- We hit the chance to spawn the items
    if chance <= (devil_chance + angel_chance) then

        -- This for loop basically spawns 2 items
        for i = 1, 2 do
            -- Check if the current item to be spawned should be from the angel pool
            local is_angel = i == 2

            -- We don't need to spawn a second item since our angel chance is 0
            if is_angel and (angel_chance == 0 and not PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_DUALITY)) then return end

            -- Get the item pool and offset for the spawn
            local item_pool = ItemPoolType.POOL_DEVIL
            local offset = Vector(80, 0)

            -- Change item pools and offset according to what deal item to spawn
            if is_angel then
                item_pool = ItemPoolType.POOL_ANGEL
                offset = offset * -1
            end

            -- Offset the item upwards since the items don't actually spawn in
            -- the center of the room for some reason
            offset = offset + Vector(0, 50)

            -- Get the position to spawn the item
            local position = room:GetCenterPos() - offset

            -- Spawn the item from the pool, respecting Glitched Crown, T. Isaac, Isaac's Birthright and Binge Eater
            local item = ARAOI.ItemUtils.SpawnCollectibleFromPool(item_pool, Isaac.GetCollectibleSpawnPosition(position), Vector.Zero, nil, true,
                PlayerManager.FirstCollectibleOwner(ARAOI.CollectibleType.DUALITY_HALO):GetCollectibleRNG(ARAOI.CollectibleType.DUALITY_HALO)
            )

            -- Make the devil deal item cost hearts
            if not is_angel then
                item:MakeShopItem(-2)
            end

            -- Remember to make the collectible cost money for T. Keeper
            if ARAOI.PlayerUtils.AnyPlayerIs(PlayerType.PLAYER_KEEPER, PlayerType.PLAYER_KEEPER_B) then
                item:MakeShopItem(-1)
            end

            -- Finally we use the option variable
            if not option then
                -- Set it to a new index if it doesn't exist
                option = item:SetNewOptionsPickupIndex()
            else
                -- Set it to the other item's option if it does exist
                item.OptionsPickupIndex = option
            end
        end
    end
end


----------------------
-- FUNCTION TRIGGER --
----------------------

function ARAOI:_OnDualityHaloPreRoomTriggerClear()
    -- No point in triggering the functionality when we don't even have the item
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.DUALITY_HALO) then return end

    -- Get the current room
    local room = game:GetRoom()

    -- Check if the room is the last boss room
    if room:IsCurrentRoomLastBoss() then
        -- Store the current deal chance before it gets possibly overwritten
        devil_chance, angel_chance = ARAOI.MiscUtils.getDevilAngelRoomChance()

        -- Create a timer to trigger the item's functionality
        Isaac.CreateTimer(ARAOI.Duality_Halo.SpawnCollectibles, 3, 1, false)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_ROOM_TRIGGER_CLEAR, ARAOI._OnDualityHaloPreRoomTriggerClear)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.DUALITY_HALO,
        "#{{AngelDevilChance}} If a Deal doesn't spawn, has the same deal probability to spawn an item from the deal"..
        "# Having multiple deal chances combines them and spawns a choice between deals"..
        "#{{Collectible}} Taking an item spawned this way will not future deals"
    )
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.DUALITY_HALO, "2 locusts (0.5x Isaac's damage)")
end)