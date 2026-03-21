local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------



Config.MAX_CHANCE  = 30 -- *Default: `30` — The maximum chance for a slot to spawn.*
Config.BASE_CHANCE = 15 -- *Default: `15` — The base chance for a slot to spawn, scales with luck using the `LUCK_MODIFIER` up uo `MAX_CHANCE`.*

Config.LUCK_MODIFIER = 75 -- *Default: `75` — Player's luck will be multiplied by this percentage and added to the `BASE_CHANCE`.*

Config.COIN_CHANCE   = 10 -- *Default: `10` — Chance to spawn a coin on enemy kill.*



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)



------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Gambling_Chips = {}
ARAOI.Gambling_Chips.Config = Config

local game = Game()


---------------
-- FUNCTIONS --
---------------


-- Gets a random slot machine that is considered "gambling"
---@param rng? RNG
---@param allowSelfDamage? boolean
---@return SlotVariant
function ARAOI.Gambling_Chips.GetRandomGamblingSlot(rng, allowSelfDamage)
    if rng == nil then
        rng = RNG()
    end

    local PersistentGameData = Isaac.GetPersistentGameData()

    local AVAILABLE_SLOTS = {
        SlotVariant.BEGGAR,
        SlotVariant.BOMB_BUM,
        SlotVariant.KEY_MASTER,
        SlotVariant.SHELL_GAME,
        SlotVariant.SHOP_RESTOCK_MACHINE,
        SlotVariant.SLOT_MACHINE,
    }

    if allowSelfDamage then
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

    return ARAOI.TableUtils.Choice(AVAILABLE_SLOTS)
end

---@param slot EntitySlot
local function ShouldSlotRewardBeDoubled(slot)
    local slots = {
        SlotVariant.BEGGAR,
        SlotVariant.BOMB_BUM,
        SlotVariant.KEY_MASTER,
        SlotVariant.SHELL_GAME,
        SlotVariant.SHOP_RESTOCK_MACHINE,
        SlotVariant.SLOT_MACHINE,
        SlotVariant.DEVIL_BEGGAR,
        SlotVariant.HELL_GAME,
        SlotVariant.CRANE_GAME,
        SlotVariant.CONFESSIONAL
    }

    return ARAOI.TableUtils.IsValueInTable(slot.Variant, slots)
end


-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

-- Triggers the item's slot spawning mechanic
function ARAOI.Gambling_Chips.TriggerSpawnSlot()
    local SFX = SFXManager()
    local room = game:GetRoom()

    -- We should run this function for every player that has the item
    -- This also makes it unnecessary to check if anyPlayerHasCollectible
    local players_with_collectible = ARAOI.PlayerUtils.GetPlayersWithCollectible(ARAOI.CollectibleType.GAMBLING_CHIPS)
    for _, player in pairs(players_with_collectible) do
        -- Get rng for this to happen the same way if we use the same seed
        local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLING_CHIPS)

        -- Get the chance of spawning a slot
        local chance = math.min(Config.BASE_CHANCE + (player.Luck * Config.LUCK_MODIFIER), Config.MAX_CHANCE)
        chance = chance / 100 -- Converting to a percent

        -- Check if the spawn should happen
        local random_rumber = rng:RandomFloat()
        if random_rumber > chance then goto next_player end

        -- Get a free position, this avoids rocks and pits, and should avoid the player
        local top_left = room:GetTopLeftPos()
        local offset = Vector(100, 100)
        local free_position = room:FindFreePickupSpawnPosition(top_left + offset, 0, true)

        -- Get the slot to be spawned according to player type
        local slot = ARAOI.Gambling_Chips.GetRandomGamblingSlot(rng, not ARAOI.PlayerUtils.IsLost(player))

        -- Spawn the slot
        game:Spawn(EntityType.ENTITY_SLOT, slot, free_position,
            Vector.Zero, nil, 0, rng:GetSeed())

        -- Show the player that the item got triggered
        player:AnimateCollectible(ARAOI.CollectibleType.GAMBLING_CHIPS)
        SFX:Play(SoundEffect.SOUND_SLOTSPAWN)

        ::next_player::
    end
end

function ARAOI:_OnGamblingChipsNewRoom()
    local room = game:GetRoom()

    -- Check if it's the first time the player loads this room
    -- We shouldn't spawn slots in already visited rooms
    if not room:IsFirstVisit() then return end

    if room:IsClear() then
        ARAOI.Gambling_Chips.TriggerSpawnSlot()
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnGamblingChipsNewRoom)

function ARAOI:_OnGamblingChipsPreRoomTriggerClear()
    -- local room = game:GetRoom()
    ARAOI.Gambling_Chips.TriggerSpawnSlot()
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_ROOM_TRIGGER_CLEAR, ARAOI._OnGamblingChipsPreRoomTriggerClear)



-------------------------------
-- BEGGAR PICKUP DUPLICATION --
-------------------------------

---@param pickup EntityPickup
function ARAOI:_OnGamblingChipsPickupInit(pickup)
    -- This should only run when any player has the gambling chip
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.GAMBLING_CHIPS) then return end

    -- Should not work for collectibles
    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then return end

    -- Check all slots to determine if one of them spawned the pickup
    for _, entity in pairs(Isaac.GetRoomEntities()) do
        -- Convert the entity to a slot, if it's not a slot then skip this entity
        local slot = entity:ToSlot()
        if not slot then goto continue end

        -- Check if the slot is in the available slots
        if not ShouldSlotRewardBeDoubled(slot) then goto continue end

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
end
ARAOI:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, ARAOI._OnGamblingChipsPickupInit)




---------------------------------
-- COIN SPAWNING FUNCTIONALITY --
---------------------------------

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function ARAOI:_OnGamblingChipsEntityTakeDamage(entity, amount, flags, source)
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
    if not player:HasCollectible(ARAOI.CollectibleType.GAMBLING_CHIPS) then return end

    -- Get rng so it behaves the same per seed
    local rng = player:GetCollectibleRNG(ARAOI.CollectibleType.GAMBLING_CHIPS)

    -- Setting the chance
    local chance = Config.COIN_CHANCE
    chance = chance / 100 -- Converting to %

    -- Check if the spawn should happen
    if rng:RandomFloat() > chance then return end

    -- Which position should the pickup spawn in
    local spawn_position = entity.Position

    -- Spawning the entity
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, spawn_position,
        EntityPickup.GetRandomPickupVelocity(spawn_position)/3, player)
end
ARAOI:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ARAOI._OnGamblingChipsEntityTakeDamage)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    local shell_game_icons = Sprite("gfx/ui/eid_shell_game_icons.anm2", true)
    EID:addIcon("ShellGame", "idle", 0, 12, 12, -1, -1.5, shell_game_icons)
    EID:addIcon("HellGame", "idle", 1, 12, 12, 1, -1.5, shell_game_icons)

    local slots = "{{Slotmachine}}{{RestockMachine}}{{CraneGame}}{{Beggar}}{{DemonBeggar}}{{KeyBeggar}}{{BombBeggar}}{{RottenBeggar}}{{ShellGame}}{{HellGame}}"

    local max_luck = math.ceil((Config.MAX_CHANCE - Config.BASE_CHANCE) / (Config.LUCK_MODIFIER / 100))

    EID:addCollectible(ARAOI.CollectibleType.GAMBLING_CHIPS,
        "#{{Coin}} +10 Coins"..
        "# "..Config.BASE_CHANCE.."% chance to spawn on every room one of: "..slots..
        "#{{Luck}} "..Config.MAX_CHANCE.."% at "..max_luck.." luck"..
        "# Duplicates pickups from "..slots..
        "#{{DeathMark}} "..Config.COIN_CHANCE.."% chance for enemies to spawn a coin on death"
    )

    ARAOI.EIDUtils.PlayerBasedModifier(
        "Gambling Chips Lost",
        ARAOI.CollectibleType.GAMBLING_CHIPS,
        {PlayerType.PLAYER_THELOST, PlayerType.PLAYER_THELOST_B},
        PlayerType.PLAYER_THELOST,
        "The Lost will not spawn slots that require health"
    )
    EID:addAbyssSynergiesCondition(ARAOI.CollectibleType.GAMBLING_CHIPS, "1 locust, 5% chance of coin on hit (1x Isaac's damage)")
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Passives", "Gambling Chips")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Gambling Chips", Config, "BASE_CHANCE", ConfigDefaults, ConfigDefaults.BASE_CHANCE .. "%", 0, 100, 10, function ()
        return "Base Chance: " .. Config.BASE_CHANCE .. "%"
    end, "The base chance for a slot to spawn")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Gambling Chips", Config, "MAX_CHANCE", ConfigDefaults, ConfigDefaults.MAX_CHANCE .. "%", 0, 100, 10, function ()
        return "Max Chance: " .. Config.MAX_CHANCE .. "%"
    end, "The maximum chance for a slot to spawn")

    ARAOI.MCMUtils.AddNumberSetting("Passives", "Gambling Chips", Config, "LUCK_MODIFIER", ConfigDefaults, ConfigDefaults.LUCK_MODIFIER/100 .. "x", 0, 1000000, 20, function ()
        return "Luck Modifier: " .. Config.LUCK_MODIFIER/100 .. "x"
    end, "Isaac's luck will be multiplied by this number and added to the Base Chance")

    ARAOI.MCMUtils.AddReset("Passives", "Gambling Chips")
end