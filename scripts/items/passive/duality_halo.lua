
---@class Helper
local Helper = include("scripts.Helper")

local DUALITY_HALO = Isaac.GetItemIdByName("Duality Halo")

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()

    -- Store the chances for later use, initialized to avoid errors
    self.devil_angel_room_chance = {0, 0}


    ------------------------
    -- MAIN FUNCTIONALITY --
    ------------------------

    local function spawnConsolation()
        local room = game:GetRoom()
        local level = game:GetLevel()

        -- Don't spawn items if we are on Basement 1, since that's how it works in the game
        if level:GetStage() == LevelStage.STAGE1_1 and not (level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH > 0) then return end

        -- Check grid entities
        for _, entity in ipairs(Helper.GetRoomGridEntities()) do
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
        for i, v in ipairs(self.devil_angel_room_chance) do
            -- If the chance is more than 0 and the new chance is within spawning bounds
            if v > 0 and chance <= v then
                -- Check if the current item to be spawned should be from the angel pool
                local isAngel = i == 2

                -- Get the item pool and offset for the spawn
                local item_pool = ItemPoolType.POOL_DEVIL
                local offset = Vector(80, 0)

                -- Change item pools and offset according to what deal item to spawn
                if isAngel then
                    item_pool = ItemPoolType.POOL_ANGEL
                    offset = offset * -1
                end

                -- Offset the item upwards since the items don't actually spawn in
                -- the center of the room for some reason
                offset = offset + Vector(0, 50)

                -- Get the position to spawn the item
                local position = room:GetCenterPos() - offset

                -- Spawn the item from the pool, respecting Glitched Crown, T. Isaac, Isaac's Birthright and Binge Eater
                local item = Helper.SpawnCollectiblePool(item_pool, Isaac.GetCollectibleSpawnPosition(position), Vector.Zero, nil, true,
                    PlayerManager.FirstCollectibleOwner(DUALITY_HALO):GetCollectibleRNG(DUALITY_HALO)
                )

                -- Make the devil deal item to cost hearts
                if not isAngel then
                    item:MakeShopItem(-2)
                end

                -- Remember to make the collectible cost money for T. Keeper
                if Helper.AnyPlayerIs(PlayerType.PLAYER_KEEPER, PlayerType.PLAYER_KEEPER_B) then
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

    local function bossDefeated()
        -- No point in triggering the functionality when we don't even have the item
        if not PlayerManager.AnyoneHasCollectible(DUALITY_HALO) then return end

        -- Get the current room
        local room = game:GetRoom()

        -- Check if the room is the last boss room
        if room:IsCurrentRoomLastBoss() then
            -- Store the current Devil/Angel chance because we can't check if a door will spawn or not
            -- we need to check if the door spawned after it spawns
            self.devil_angel_room_chance = Helper.getDevilAngelRoomChance()

            -- Create a timer to trigger the item's functionality
            Isaac.CreateTimer(spawnConsolation, 3, 1, false)
        end
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_ROOM_TRIGGER_CLEAR, bossDefeated)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then
        EID:addCollectible(DUALITY_HALO,
            "#{{AngelDevilChance}} If a Deal doesn't spawn, it will try to spawn a deal item in the boss room using the deal spawn chance"..
            "#{{Collectible}} Taking an item spawned this way will not affect deal chance"
        )
    end
end

return modded_item