local card = {}

card.ID = ARAOI.CardSubType.INVERTED_DEATH
card.Replace = Card.CARD_REVERSE_DEATH

ARAOI.Inverted_Cards.Death = card

local game = Game()

---@type table<integer, EntityData>
local dead_entities = {}

---@param entity EntityNPC
local function new_entity_data(entity)
    ---@class EntityData
    local instance = {}
    instance.Type = entity.Type
    instance.Variant = entity.Variant
    instance.SubType = entity.SubType
    instance.Position = entity.Position
    instance.Champion = entity:GetChampionColorIdx()

    return instance
end

---@param entity Entity
function ARAOI:_OnInvertedCardDeathRoomEntityDeath(entity)
    if entity:IsActiveEnemy(true) then
        local npc = entity:ToNPC(); if not npc then return end
        dead_entities[entity.InitSeed] = new_entity_data(npc)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, ARAOI._OnInvertedCardDeathRoomEntityDeath)

function ARAOI:_OnInvertedCardDeathPreNewRoom()
    dead_entities = {}
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_NEW_ROOM, ARAOI._OnInvertedCardDeathPreNewRoom)

---@param player EntityPlayer
function ARAOI:_OnInvertedCardDeathUse(_, player, useFlags)
    for i = 1, (useFlags & UseFlag.USE_CARBATTERY == 0) and 1 or 2 do
        for _, data in pairs(dead_entities) do
            local entity = Isaac.Spawn(data.Type, data.Variant, data.SubType, data.Position, Vector.Zero, player)
            entity:AddCharmed(EntityRef(player), -1)

            local npc = entity:ToNPC()
            if not npc then goto continue end
            if data.Champion ~= -1 then
                npc:MakeChampion(entity.InitSeed, data.Champion)
            end

            ::continue::
        end
    end
    dead_entities = {}
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardDeathUse, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "# Revives killed enemies in the room as allies"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, "Double trouble!")
end)

return card