----------------------------
-- START OF CONFIGURATION --
----------------------------



local MAX_CHANCE  = 30 -- *Default: `30` — The maximum chance for a slot to spawn.*
local BASE_CHANCE = 15 -- *Default: `15` — The base chance for a slot to spawn, scales with luck using the `LUCK_MODIFIER` up uo `MAX_CHANCE`.*

local LUCK_MODIFIER = 0.75 -- *Default: `0.75` — Player's luck will be multiplied by this and added to the `BASE_CHANCE`.*

local COIN_CHANCE        = 10 -- *Default: `10` — Chance to spawn a coin on enemy kill.*



--------------------------
-- END OF CONFIGURATION --
--------------------------



---@class helper
local helper = include("scripts.helper")


---------------
-- CONSTANTS --
---------------

local GAMBLING_CHIPS = Isaac.GetItemIdByName("Gambling Chips")


---------------
-- FUNCTIONS --
---------------

-- Some slots should not be available because it's not really a gamble if they reward you every time.
-- Blood Donation Machines always reward you with coins, and the fortune from Fortune Teller Machines
-- should count as a reward since that's literally what they're meant to give you anyways.
---@param player EntityPlayer?
---@return SlotVariant[]
local function getAvailableSlots(player)
    local PersistentGameData = Isaac.GetPersistentGameData()

    local AVAILABLE_SLOTS = {
        SlotVariant.BEGGAR,
        SlotVariant.BOMB_BUM,
        SlotVariant.KEY_MASTER,
        SlotVariant.SHELL_GAME,
        SlotVariant.SHOP_RESTOCK_MACHINE,
        SlotVariant.SLOT_MACHINE,
    }

    if player == nil or not helper.player.IsLost(player) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.DEVIL_BEGGAR)

        if PersistentGameData:Unlocked(Achievement.HELL_GAME) then
            table.insert(AVAILABLE_SLOTS, SlotVariant.HELL_GAME)
        end
    end

    if PersistentGameData:Unlocked(Achievement.CRANE_GAME) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.CRANE_GAME)
    end

    if PersistentGameData:Unlocked(Achievement.ROTTEN_BEGGAR) then
        table.insert(AVAILABLE_SLOTS, SlotVariant.ROTTEN_BEGGAR)
    end

    return AVAILABLE_SLOTS
end

---@return boolean
local function anyPlayerHasGamblingChip()
    return PlayerManager.AnyoneHasCollectible(GAMBLING_CHIPS)
end

---@param slot EntitySlot
local function isSlotAvailable(slot)
    return helper.table.IsValueInTable(slot.Variant, getAvailableSlots())
end


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)

    local game = Game()
    local SFX = SFXManager()


    -----------------------------
    -- MAIN ITEM FUNCTIONALITY --
    -----------------------------

    -- This needs to be called from 2 separate callbacks and the
    -- 2 callbacks have some separate checks before calling this function
    ---@param room Room
    local function spawnGambling(room)
        -- We should run this function for every player that has the item
        -- This also makes it unnecessary to check if anyPlayerHasCollectible
        local players_with_collectible = helper.player.GetPlayersWithCollectible(GAMBLING_CHIPS)
        for _, player in pairs(players_with_collectible) do
            -- Get rng for this to happen the same way if we use the same seed
            local rng = player:GetCollectibleRNG(GAMBLING_CHIPS)

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
            local slot = helper.table.Choice(slot_list, nil, rng) -- RandomInt starts at 0, arrays are 1-indexed

            -- Spawn the slot
            game:Spawn(EntityType.ENTITY_SLOT, slot, free_position,
                Vector.Zero, nil, 0, rng:GetSeed())

            -- Show the player that the item got triggered
            player:AnimateCollectible(GAMBLING_CHIPS)
            SFX:Play(SoundEffect.SOUND_SLOTSPAWN)

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
    Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function (_, pickup)
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
                local spawn_offset = pickup.Position + Vector.One
                Isaac.Spawn(pickup.Type, pickup.Variant, pickup.SubType,
                    spawn_offset, pickup.Velocity, nil)
            end

            ::continue::
        end
    end)




    ---------------------------------
    -- COIN SPAWNING FUNCTIONALITY --
    ---------------------------------

    ---@param entity Entity
    ---@param amount number
    ---@param flags DamageFlag
    ---@param source EntityRef
    Mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source)
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
        if not player:HasCollectible(GAMBLING_CHIPS) then return end

        -- Get rng so it behaves the same per seed
        local rng = player:GetCollectibleRNG(GAMBLING_CHIPS)

        -- Setting the chance
        local chance = COIN_CHANCE
        chance = chance / 100 -- Converting to %

        -- Check if the spawn should happen
        if rng:RandomFloat() > chance then return end

        -- Which position should the pickup spawn in
        local spawn_position = entity.Position

        -- Spawning the entity
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, spawn_position,
            EntityPickup.GetRandomPickupVelocity(spawn_position)/3, player)
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        local shell_game_icons = Sprite("gfx/ui/eid_shell_game_icons.anm2", true)
        EID:addIcon("ShellGame", "idle", 0, 12, 12, -1, -1.5, shell_game_icons)
        EID:addIcon("HellGame", "idle", 1, 12, 12, 1, -1.5, shell_game_icons)

        local slots = "{{Slotmachine}}{{RestockMachine}}{{CraneGame}}{{Beggar}}{{DemonBeggar}}{{KeyBeggar}}{{BombBeggar}}{{RottenBeggar}}{{ShellGame}}{{HellGame}}"

        local max_luck = math.ceil((MAX_CHANCE - BASE_CHANCE) / LUCK_MODIFIER)

        EID:addCollectible(GAMBLING_CHIPS,
            "#{{Coin}} +10 Coins"..
            "# "..BASE_CHANCE.."% chance to spawn on every room one of: "..slots..
            "#{{Luck}} "..MAX_CHANCE.."% at "..max_luck.." luck"..
            "# Duplicates rewards from "..slots..
            "#{{DeathMark}} "..COIN_CHANCE.."% chance for enemies to spawn a coin on death"
        )

        helper.eid.PlayerBasedModifier(
            "Gambling Chips Lost",
            GAMBLING_CHIPS,
            {PlayerType.PLAYER_THELOST, PlayerType.PLAYER_THELOST_B},
            PlayerType.PLAYER_THELOST,
            "The Lost will not spawn slots that require health"
        )

    end
end

return modded_item