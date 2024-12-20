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

---@type number[] -- List containing the Devil Chance and Angel Chance: `{DevilChance: number, AngelChance: number}`
ARAOI.Duality_Halo.Devil_Angel_Chances = {0, 0}


---------------
-- FUNCTIONS --
---------------

-- Sets the Devil and Angel Chances of spawning an item to the provided values
--
-- This will be updated immediately after defeating the floor's boss, so this function should only be used for testing purposes
---@param devilChance number -- Between 0 and 1
---@param angelChance number -- Between 0 and 1
function ARAOI.Duality_Halo.SetDevilAngelChances(devilChance, angelChance)
    ARAOI.Duality_Halo.Devil_Angel_Chances = {devilChance, angelChance}
end

-- Updates the Devil and Angel Chances according to the current Devil and Angel room chances
function ARAOI.Duality_Halo.UpdateDevilAngelChances()
    ARAOI.Duality_Halo.Devil_Angel_Chances = ARAOI.MiscUtils.getDevilAngelRoomChance()
end

-- Spawns the collectibles according to the `Devil_Angel_Chances`
function ARAOI.Duality_Halo.SpawnCollectibles()
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

    -- This for loop basically spawns 2 items
    for i, v in ipairs(ARAOI.Duality_Halo.Devil_Angel_Chances) do
        -- If the chance is more than 0 and the new chance is within spawning bounds
        if v > 0 and chance <= v then
            -- Check if the current item to be spawned should be from the angel pool
            local is_angel = i == 2

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

            -- Make the devil deal item to cost hearts
            if not is_angel then
                item:MakeShopItem(-2)
            end

            -- Remember to make the collectible cost money for T. Keeper
            if ARAOI.PlayerUtils.AnyPlayerIs(PlayerType.PLAYER_KEEPER, PlayerType.PLAYER_KEEPER_B) then
                item:MakeShopItem(-1)
                item.Price = 1
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

ARAOI.Mod:AddCallback(ModCallbacks.MC_PRE_ROOM_TRIGGER_CLEAR, function ()
    -- No point in triggering the functionality when we don't even have the item
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.DUALITY_HALO) then return end

    -- Get the current room
    local room = game:GetRoom()

    -- Check if the room is the last boss room
    if room:IsCurrentRoomLastBoss() then
        -- Store the current Devil/Angel chance because we can't check if a door will spawn or not
        -- we need to check if the door spawned after it spawns
        

        -- Create a timer to trigger the item's functionality
        Isaac.CreateTimer(ARAOI.Duality_Halo.SpawnCollectibles, 3, 1, false)
    end
end)


-------------
-- LOCUSTS --
-------------

---@param locust EntityFamiliar
ARAOI.Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, locust)
    if locust.SubType == ARAOI.CollectibleType.DUALITY_HALO then
        local locusts = ARAOI.PlayerUtils.GetLocusts(locust.SpawnerEntity:ToPlayer(), ARAOI.CollectibleType.DUALITY_HALO)
        if locusts then
            if #locusts%2 == 1 then
                locust:GetSprite().Color:SetTint(1, 1, 1, 1)
            end
            if #locusts%2 == 0 then
                locust:GetSprite().Color:SetTint(0, 0, 0, 1)
            end
        end
    end
end, FamiliarVariant.ABYSS_LOCUST)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.DUALITY_HALO,
        "#{{AngelDevilChance}} If a Deal doesn't spawn, it will try to spawn a deal item in the boss room using the deal spawn chance"..
        "#{{Collectible}} Taking an item spawned this way will not affect deal chance"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Duality Halo Abyss Synergy",
        ARAOI.CollectibleType.DUALITY_HALO,
        "Small black and white locusts that deal 0.5x Isaac's damage"
    )
end)