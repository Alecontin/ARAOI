
---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

---@class Helper
local Helper = include("scripts.Helper")

local BLESSINGS_PETAL = Isaac.GetItemIdByName("Blessing's Petal")

---@param set? boolean
---@return boolean
local function hasPickedUpEdensPetal(set)
    return SaveData:Key(SaveData.PERSISTANT, "hasPickedUpBlessingsPetal", false, set)
end

---@param rng RNG
local function randomChest(rng)
    local chests = {
        [PickupVariant.PICKUP_CHEST] = 1,
        [PickupVariant.PICKUP_LOCKEDCHEST] = 1,
        [PickupVariant.PICKUP_REDCHEST] = 1,
        [PickupVariant.PICKUP_BOMBCHEST] = 1,
        [PickupVariant.PICKUP_ETERNALCHEST] = 1,
        [PickupVariant.PICKUP_SPIKEDCHEST] = 1,
        [PickupVariant.PICKUP_MIMICCHEST] = 1,
        [PickupVariant.PICKUP_OLDCHEST] = 0.5,
        [PickupVariant.PICKUP_MOMSCHEST] = 0.01
    }
    if Isaac.GetCompletionMark(PlayerType.PLAYER_LAZARUS_B, CompletionType.MEGA_SATAN) then
        chests[PickupVariant.PICKUP_WOODENCHEST] = 1
    end
    if Isaac.GetCompletionMark(PlayerType.PLAYER_ISAAC_B, CompletionType.MEGA_SATAN) then
        chests[PickupVariant.PICKUP_MEGACHEST] = 0.1
    end
    if Isaac.GetCompletionMark(PlayerType.PLAYER_THELOST_B, CompletionType.MEGA_SATAN) then
        chests[PickupVariant.PICKUP_HAUNTEDCHEST] = 1
    end

    local keys, values = Helper.KeysAndValues(chests)
    return Helper.Choice(keys, values, rng)
end

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()

    -- Save the fact that the item has been picked up
    Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function ()
        hasPickedUpEdensPetal(true)
    end, BLESSINGS_PETAL)


    -----------------------------
    -- MAIN ITEM FUNCTIONALITY --
    -----------------------------

    ---@param isContinued boolean
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function (_, isContinued)
        -- Only spawn a pickup if it's a new run and you previously picked up the item
        if hasPickedUpEdensPetal() and not isContinued then
            -- Reset the data
            hasPickedUpEdensPetal(false)

            -- Get some necessary data
            local player = Isaac.GetPlayer()
            local room = game:GetRoom()

            -- Set the rng and seed
            local rng = RNG()
            rng:SetSeed(game:GetSeeds():GetStartSeed())

            -- Set a list of pickups and weights
            local pickups = {
                [PickupVariant.PICKUP_COIN] = 1,
                [PickupVariant.PICKUP_KEY] = 1,
                [PickupVariant.PICKUP_BOMB] = 1,
                [PickupVariant.PICKUP_HEART] = 0.7,
                [PickupVariant.PICKUP_LIL_BATTERY] = 0.5,
                [randomChest(rng)] = 0.2
            }

            -- Separate the pickups and weights
            local keys, values = Helper.KeysAndValues(pickups)

            -- Spawn a pickup according to the weights
            Isaac.Spawn(EntityType.ENTITY_PICKUP, Helper.Choice(keys, values, rng), 0, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, nil)
        end
    end)

    ---@param player EntityPlayer
    ---@param cacheFlag CacheFlag
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, cacheFlag)
        if not player:HasCollectible(BLESSINGS_PETAL) then return end

        if cacheFlag == CacheFlag.CACHE_FIREDELAY and not player:HasCollectible(CollectibleType.COLLECTIBLE_EDENS_BLESSING) then
            Helper.ModifyFireDelay(player, -0.35 * Helper.GetAproxTearRateMultiplier(player), true)
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 1
        end
    end)


    ---@class EID
    if EID then
        EID:addCollectible(BLESSINGS_PETAL,
            "#{{ArrowUp}} +0.35 Tears"..
            "#{{ArrowUp}} +1 Luck"..
            "# Spawns a random pickup at the start of the next run"..
            "# Pickups can be any variant of: #{{Blank}} {{Coin}} {{Key}} {{Bomb}} {{Heart}} {{Battery}} {{Chest}}"
        )
    end
end

return modded_item