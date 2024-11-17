---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Hanged Man")
card.Replace = Card.CARD_REVERSE_HANGED_MAN

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local sfx = SFXManager()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(Card.CARD_HANGED_MAN)
        local room = game:GetRoom()

        local function BarricadeDoors()
            for _, entity in ipairs(helper.room.GetGridEntities()) do
                local door = entity:ToDoor()
                if door then
                    door:Close(true)
                    door:Bar()
                end
            end
        end

        if game:GetStateFlag(GameStateFlag.STATE_GREED_SPAWNED) == false then
            Isaac.Spawn(EntityType.ENTITY_GREED, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
            game:SetStateFlag(GameStateFlag.STATE_GREED_SPAWNED, true)
            BarricadeDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        elseif game:GetStateFlag(GameStateFlag.STATE_SUPERGREED_SPAWNED) == false then
            Isaac.Spawn(EntityType.ENTITY_GREED, 1, 0, room:GetRandomPosition(0), Vector.Zero, player)
            game:SetStateFlag(GameStateFlag.STATE_SUPERGREED_SPAWNED, true)
            BarricadeDoors()
            sfx:Play(SoundEffect.SOUND_SUMMONSOUND)
        else
            for _ = 1, rng:RandomInt(2, 10) do
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