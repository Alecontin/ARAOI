local hanged_man = Isaac.GetCardIdByName("Inverted Hanged Man")
local reverse = Card.CARD_REVERSE_HANGED_MAN

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local function GreedSpawns(set)
    return SaveData:Key(SaveData.RUN, "InvertedHangedManGreedSpawns", 0, set)
end

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local sfx = SFXManager()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(Card.CARD_HANGED_MAN)
        local room = game:GetRoom()

        local function CloseDoors()
            for _, entity in ipairs(Helper.GetRoomGridEntities()) do
                local door = entity:ToDoor()
                if door then
                    door:Close(true)
                    door:Bar()
                end
            end
        end

        local can_spawn_keeper = GreedSpawns() == 0
        local can_spawn_keeper_super_keeper = GreedSpawns() == 1

        if can_spawn_keeper then
            Isaac.Spawn(EntityType.ENTITY_GREED, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
            GreedSpawns(1)
            CloseDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        elseif can_spawn_keeper_super_keeper then
            Isaac.Spawn(EntityType.ENTITY_GREED, 1, 0, room:GetRandomPosition(0), Vector.Zero, player)
            GreedSpawns(2)
            CloseDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        elseif rng:RandomFloat() > 0.01 then
            local room = game:GetRoom()
            for _ = 2, rng:RandomInt(2, 10) do
                Isaac.Spawn(EntityType.ENTITY_SHOPKEEPER, 1, 0, room:GetRandomPosition(0), Vector.Zero, player)
            end
        else
            Isaac.Spawn(EntityType.ENTITY_ULTRA_GREED, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
            CloseDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        end
    end, hanged_man)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return hanged_man
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(hanged_man,
            "#{{Player14}} Spawns the Greed boss"..
            "#{{Player33}} Spawns Super Greed if Greed was already spawned"..
            "#{{SecretRoom}} Spawns 2-10 secret room shopkeepers if Super Greed was already spawned"..
            "#{{GreedMode}} 1% chance to spawn Ultra Greed instead"
        )
    end
end

return card