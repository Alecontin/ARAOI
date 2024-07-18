----------------------------
-- START OF CONFIGURATION --
----------------------------



local MAX_CHANCE  = 30 -- *Default: `30` — The maximum chance for a slot to spawn.*
local BASE_CHANCE = 15 -- *Default: `15` — The base chance for a slot to spawn, scales with luck using the `LUCK_MODIFIER` up uo `MAX_CHANCE`.*

local LUCK_MODIFIER = 0.75 -- *Default: `0.75` — Player's luck will be multiplied by this and added to the `BASE_CHANCE`.*

local COIN_CHANCE        = 10 -- *Default: `10` — Chance to spawn a coin on enemy kill.*
local COIN_CHANCE_KEEPER = 5  -- *Default: `5` — Chance to spawn a coin on enemy kill for Keeper.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



---@class Helper
local Helper = include("scripts.Helper")

local GAMBLING_CHIP = Isaac.GetItemIdByName("Gambling Chips")
CollectibleType.COLLECTIBLE_GAMBLING_CHIP = GAMBLING_CHIP

-- Some slots should not be available because it's not really a gamble if they reward you every time.
-- Blood Donation Machines always reward you with coins, and the fortune from Fortune Teller Machines
-- should count as a reward since that's literally what they're meant to give you anyways.
---@param player EntityPlayer?
---@return SlotVariant[]
local function getAvailableSlots(player)
    local PGD = Isaac.GetPersistentGameData()

    local AVAILABLE_SLOTS = {
        SlotVariant.BEGGAR,
        SlotVariant.BOMB_BUM,
        SlotVariant.KEY_MASTER,
        SlotVariant.SHELL_GAME,
        SlotVariant.SHOP_RESTOCK_MACHINE,
        SlotVariant.SLOT_MACHINE,
    }

    if player == nil or not Helper.IsLost(player) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.DEVIL_BEGGAR)

        if PGD:Unlocked(Achievement.HELL_GAME) then
            table.insert(AVAILABLE_SLOTS, SlotVariant.HELL_GAME)
        end
    end

    if PGD:Unlocked(Achievement.CRANE_GAME) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.CRANE_GAME)
    end

    if PGD:Unlocked(Achievement.ROTTEN_BEGGAR) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.ROTTEN_BEGGAR)
    end

    return AVAILABLE_SLOTS
end

---@return boolean
local function anyPlayerHasGamblingChip()
    return PlayerManager.AnyoneHasCollectible(GAMBLING_CHIP)
end

---@param slot EntitySlot
local function isSlotAvailable(slot)
    return Helper.IsValueInTable(slot.Variant, getAvailableSlots())
end


local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)

    local game = Game()
    local sfx = SFXManager()


    ----------------------------
    -- MAIN MOD FUNCTIONALITY --
    ----------------------------

    -- This needs to be called from 2 separate callbacks and the
    -- 2 callbacks have some separate checks before calling this function
    ---@param room Room
    local function spawnGambling(room)
        -- We should run this function for every player that has the item
        -- This also makes it unnecessary to check if anyPlayerHasCollectible
        local players_with_collectible = Helper.GetPlayersWithCollectible(GAMBLING_CHIP)
        for _, player in pairs(players_with_collectible) do
            -- Get rng for this to happen the same way if we use the same seed
            local rng = player:GetCollectibleRNG(GAMBLING_CHIP)

            -- Get the chance of spawning a slot
            local chance = math.min(BASE_CHANCE + (player.Luck * LUCK_MODIFIER), MAX_CHANCE)
            chance = chance / 100 -- Converting to a percent

            -- Check if the spawn should happen
            local random_rumber = rng:RandomFloat()
            if random_rumber > chance then goto next_player end

            -- Get a free position, this avoids rocks and pits, and should avoid the player
            local top_left = room:GetTopLeftPos()
            local offset = Vector(100, 100)
            local free_position = room:FindFreePickupSpawnPosition(top_left + offset, 0, true)

            -- Get the available slots to be spawned according to player type
            local slot_list = getAvailableSlots(player)

            -- Get the slot to be spawned
            local slot = Helper.Choice(slot_list, nil, rng) -- RandomInt starts at 0, arrays are 1-indexed

            -- Spawn the slot
            game:Spawn(EntityType.ENTITY_SLOT, slot, free_position,
                Vector.Zero, nil, 0, rng:GetSeed())

            -- Show the player that the item got triggered
            player:AnimateCollectible(GAMBLING_CHIP)
            sfx:Play(SoundEffect.SOUND_SLOTSPAWN)

            ::next_player::
        end
    end

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function (_)
        local room = game:GetRoom()

        -- Check if it's the first time the player loads this room
        -- We shouldn't spawn slots in already visited rooms
        if not room:IsFirstVisit() then return end

        if room:IsClear() then
            spawnGambling(room)
        end
    end)

    Mod:AddCallback(ModCallbacks.MC_PRE_ROOM_TRIGGER_CLEAR, function (_)
        local room = game:GetRoom()
        spawnGambling(room)
    end)



    -------------------------------
    -- BEGGAR PICKUP DUPLICATION --
    -------------------------------

    ---@param pickup EntityPickup
    local function onPickupSpawned(_, pickup)
        -- This should only run when any player has the gambling chip
        if not anyPlayerHasGamblingChip() then return end

        -- Should not work for collectibles
        if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then return end

        -- Check all slots to determine if one of them spawned the pickup
        for _, entity in pairs(Isaac.GetRoomEntities()) do
            -- Convert the entity to a slot, if it's not a slot then skip this entity
            local slot = entity:ToSlot()
            if not slot then goto continue end
            
            -- Check if the slot is in the available slots
            if not isSlotAvailable(slot) then goto continue end

            -- Get the distance to the pickup, if it's 0 it spawned from this slot
            local distance = slot.Position:Distance(pickup.Position)

            -- Shell games spawn items with an offset since they spawn from the skull
            -- instead of the slot position itself, we check if the distance is
            -- one of these skull offsets
            if (slot.Variant == SlotVariant.HELL_GAME
            or slot.Variant == SlotVariant.SHELL_GAME)
            -- We convert the distance to a string to "get rid" of float imprecisions
            and (tostring(distance) == tostring(37.336307525635) or distance == 5.0) then
                distance = 0
            end

            -- This should mean that the pickup was spawned from this slot
            if distance == 0 then
                -- We need an offset so it doesn't get treated as spawned from the slot
                local spawnOffset = pickup.Position + Vector.One
                Isaac.Spawn(pickup.Type, pickup.Variant, pickup.SubType,
                    spawnOffset, pickup.Velocity, nil)
            end

            ::continue::
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, onPickupSpawned)




    ---------------------------------
    -- COIN SPAWNING FUNCTIONALITY --
    ---------------------------------

    ---@param entity Entity
    ---@param amount number
    ---@param flags DamageFlag
    ---@param source EntityRef
    local function onEntityKill(_, entity, amount, flags, source)
        -- Checking for unlethal damage, this means the enemy didn't die
        if entity.HitPoints - amount > 0
        or flags == DamageFlag.DAMAGE_NOKILL
        or flags == DamageFlag.DAMAGE_FAKE or
        not entity:IsActiveEnemy()
        then return end

        -- Checking if source and its parent is nil
        if source.Entity == nil then return end
        if source.Entity.Parent == nil then return end

        -- Getting the player
        local player = source.Entity.Parent:ToPlayer()
        if not player then return end

        -- Checking for collectible
        if not player:HasCollectible(GAMBLING_CHIP) then return end

        -- Getting player type for later use

        -- Get rng so it behaves the same per seed
        local rng = player:GetCollectibleRNG(GAMBLING_CHIP)

        -- Setting the chance according to player type
        local chance = COIN_CHANCE
        if Helper.IsKeeper(player) then chance = COIN_CHANCE_KEEPER end
        chance = chance / 100 -- Converting to %

        -- Check if the spawn should happen
        if rng:RandomFloat() > chance then return end

        -- Which position should the pickup spawn in
        local spawn_position = entity.Position

        -- Spwaning the entity
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, spawn_position,
            EntityPickup.GetRandomPickupVelocity(spawn_position)/3, player)
    end
    Mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, onEntityKill)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@class EID
    if EID then

        ---@param pickup EntityPickup
        local function addDescription(_, pickup)
            if pickup.SubType ~= GAMBLING_CHIP then return end

            local data = pickup:GetData()

            local slots = "{{Slotmachine}}{{RestockMachine}}{{CraneGame}}{{Beggar}}{{DemonBeggar}}{{KeyBeggar}}{{BombBeggar}}{{RottenBeggar}}{{MiniBoss}}"
            
            local max_luck = math.ceil((MAX_CHANCE - BASE_CHANCE) / LUCK_MODIFIER)

            local areKeepers = #Helper.GetPlayersOfType(PlayerType.PLAYER_KEEPER, PlayerType.PLAYER_KEEPER_B) > 0
            local areLosts = #Helper.GetPlayersOfType(PlayerType.PLAYER_THELOST, PlayerType.PLAYER_THELOST_B) > 0
            local areEdens = #Helper.GetPlayersOfType(PlayerType.PLAYER_EDEN, PlayerType.PLAYER_EDEN_B) > 0

            local keeper_desc = "("..COIN_CHANCE_KEEPER.."% {{Player14}}) "
            if not areKeepers then keeper_desc = '' end

            local lost_desc = "#{{Player10}} The lost will not spawn devil slot variants"
            if not areLosts then lost_desc = '' end

            local eden_desc = "(pickup {{Player9}}) "
            if not areEdens then eden_desc = '' end

            local description = "#{{Coin}} +10 Coins"..
                                "# "..BASE_CHANCE.."% chance to spawn on every room one of: "..slots..
                                "#{{Luck}} "..MAX_CHANCE.."% at "..max_luck.." luck"..
                                "# Duplicates rewards from "..slots..
                                "#{{DeathMark}} "..COIN_CHANCE.."% "..keeper_desc.."chance for enemies to spawn a coin "..eden_desc.."on death"..
                                lost_desc..
                                "#{{MiniBoss}} {{ColorGray}}This icon refers to shell games as there is no icon for them"
                                
            data["EID_Description"] = description
        end
        Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, addDescription, PickupVariant.PICKUP_COLLECTIBLE)
        
    end
end

return modded_item