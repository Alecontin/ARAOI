---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted World")
card.Replace = Card.CARD_REVERSE_WORLD

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local rng = player:GetCardRNG(card.ID)
        rng:RandomFloat()

        local room = RoomConfigHolder.GetRandomRoom(rng:GetSeed(), true, StbType.SPECIAL_ROOMS, RoomType.ROOM_BLACK_MARKET)

        Isaac.ExecuteCommand("goto s.blackmarket."..room.Variant)

        SaveData:CreateTimerInFrames("Schedule Spawn Inverted World Ladder", 1)
    end, card.ID)

    Mod:AddCallback("Schedule Spawn Inverted World Ladder", function ()
        local player = Isaac.GetPlayer()
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TALL_LADDER, 0, player.Position, Vector.Zero, player)
    end)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{BlackSack}} Teleports Isaac to a random Black Market"
        )
    end
end

return card