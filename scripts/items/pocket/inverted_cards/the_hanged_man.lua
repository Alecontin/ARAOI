---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Hanged Man")
card.Replace = Card.CARD_REVERSE_HANGED_MAN

local function greedSpawns(set)
    return SaveData:Key(SaveData.RUN, "InvertedHangedManGreedSpawns", 0, set)
end

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local sfx = SFXManager()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(Card.CARD_HANGED_MAN)
        local room = game:GetRoom()

        local function CloseDoors()
            for _, entity in ipairs(helper.room.GetGridEntities()) do
                local door = entity:ToDoor()
                if door then
                    door:Close(true)
                    door:Bar()
                end
            end
        end

        local can_spawn_keeper = greedSpawns() == 0
        local can_spawn_keeper_super_keeper = greedSpawns() == 1

        if can_spawn_keeper then
            Isaac.Spawn(EntityType.ENTITY_GREED, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
            greedSpawns(1)
            CloseDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        elseif can_spawn_keeper_super_keeper then
            Isaac.Spawn(EntityType.ENTITY_GREED, 1, 0, room:GetRandomPosition(0), Vector.Zero, player)
            greedSpawns(2)
            CloseDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        else
            for _ = 2, rng:RandomInt(2, 10) do
                Isaac.Spawn(EntityType.ENTITY_SHOPKEEPER, 1, 0, room:GetRandomPosition(0), Vector.Zero, player)
            end
        end
    end, card.ID)

    ---@type EID
    if EID then
        EID:addCard(card.ID,
            "#{{Player14}} Spawns the Greed boss"..
            "#{{Player33}} Spawns Super Greed if Greed was already spawned"..
            "#{{SecretRoom}} Spawns 2-10 secret room shopkeepers if Super Greed was already spawned"
        )
    end
end

return card