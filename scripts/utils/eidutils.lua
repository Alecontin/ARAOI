
---@class EIDUtils
local EIDUtils = {}

---@class PlayerUtils
local PlayerUtils = include("scripts.utils.player")

---@class EIDDescriptionObject
-- Helper table to type the DescriptionObject so I don't have to check the wiki every time.
EIDDescriptionObject = {
    -- Type of the described entity. Example: `5`
    ---@type integer
    ObjType = 0,

    -- Variant of the described entity. Example: `100`
    ---@type integer
    ObjVariant = 0,

    -- SubType of the described entity. Example for Sad Onion: `1`
    ---@type integer
    ObjSubType = 0,

    -- Combined string that describes the entity. Example for Sad Onion: `"5.100.1"`
    ---@type string
    fullItemString = "",

    -- Translated EID object name. Example for Sad Onion: `"Sad Onion"` or `"悲伤洋葱"` when chinese language is active
    ---@type string
    Name = "",

    -- Unformatted but translated EID description. Example for Sad Onion: "↑ +0.7 Tears up" or ↑ +0.7射速" when chinese language is active
    ---@type string
    Description = "",

    -- EID Transformation information object.
    ---@type unknown
    Transformation = nil,

    -- Name of the mod this item comes from. Can be nil!
    ---@type string
    ModName = nil,

    -- Quality of the displayed object. Number between 0 and 4. Set to nil to remove it.
    ---@type number
    Quality = 0,

    -- Object icon displayed in the top left of the description. Set to nil to not display it. Format like any EID icon: `{Animationname, Frame, Width, Height, LeftOffset [Default: -1], TopOffset [Default: 0], SpriteObject [Default: EID.InlineIconSprite]}`
    ---@type table
    Icon = table,

    -- Entity Object which currently is described.
    ---@type Entity
    Entity = nil,

    -- Allows description modifiers to be shown when the pill is still unidentified
    ---@type boolean
    ShowWhenUnidentified = false
}

---@param descObj EIDDescriptionObject
---@param entityType? integer
---@param entityVariant? integer
---@param entitySubtype? integer
function EIDUtils.DescObjIs(descObj, entityType, entityVariant, entitySubtype)
    return (descObj.ObjType == entityType    or entityType == nil)
    and (descObj.ObjVariant == entityVariant or entityVariant == nil)
    and (descObj.ObjSubType == entitySubtype or entitySubtype == nil)
end

-- Function that makes it easier to append Book Of Virtues synergies to items
--
-- The `Book Of Virtues` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
function EIDUtils.BookOfVirtuesSynergy(modifier_id, to_this_item, description)
    local Book_Of_Virtues = CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES
    local function condition(descObject)
        if EIDUtils.DescObjIs(descObject, 5, 100, to_this_item)
        and PlayerManager.AnyoneHasCollectible(Book_Of_Virtues)
        then return true end
    end
    local function modifier(descObject)
        EID:appendToDescription(descObject, "#{{Collectible"..Book_Of_Virtues.."}} {{ColorPastelBlue}}"..description.."{{CR}}")
        return descObject
    end
    EID:addDescriptionModifier(modifier_id, condition, modifier)
end

-- Function that makes it easier to append Abyss synergies to items
--
-- The `Abyss` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
---@deprecated Use `EID:addAbyssSynergiesCondition()` instead
function EIDUtils.AbyssSynergy(modifier_id, to_this_item, description)
    local Abyss = CollectibleType.COLLECTIBLE_ABYSS
    EID:addAbyssSynergiesCondition(to_this_item, description, nil, nil, nil)
    -- local function condition(descObject)
    --     if EIDUtils.DescObjIs(descObject, 5, 100, to_this_item)
    --     and PlayerManager.AnyoneHasCollectible(Abyss)
    --     then return true end
    -- end
    -- local function modifier(descObject)
    --     EID:appendToDescription(descObject, "#{{Collectible"..Abyss.."}} {{ColorRed}}"..description.."{{CR}}")
    --     return descObject
    -- end
    -- EID:addDescriptionModifier(modifier_id, condition, modifier)
end

-- Function that makes it easier to append Car Battery synergies to items
--
-- The `Car Battery` icon will be automatically appended to the description string
---@param modifier_id string
---@param to_this_item CollectibleType
---@param description string
function EIDUtils.CarBatterySynergy(modifier_id, to_this_item, description)
    local Car_Battery = CollectibleType.COLLECTIBLE_CAR_BATTERY
    local function condition(descObject)
        if EIDUtils.DescObjIs(descObject, 5, 100, to_this_item)
        and PlayerManager.AnyoneHasCollectible(Car_Battery)
        then return true end
    end
    local function modifier(descObject)
        EID:appendToDescription(descObject, "#{{Collectible"..Car_Battery.."}} "..description)
        return descObject
    end
    EID:addDescriptionModifier(modifier_id, condition, modifier)
end

-- Function that makes it easier to append a synergy description to items
---@param modifier_id string
---@param to_this_item CollectibleType
---@param if_player_has_this_item CollectibleType
---@param append_to_description string
function EIDUtils.SimpleSynergyModifier(modifier_id, to_this_item, if_player_has_this_item, append_to_description)
    local function condition(descObject)
        if EIDUtils.DescObjIs(descObject, 5, 100, to_this_item)
        and PlayerManager.AnyoneHasCollectible(if_player_has_this_item)
        then return true end
    end
    local function modifier(descObject)
        EID:appendToDescription(descObject, "#{{Collectible"..if_player_has_this_item.."}} "..append_to_description)
        return descObject
    end
    EID:addDescriptionModifier(modifier_id, condition, modifier)
end

-- Function that makes it easier to append some player-based information to items
---@param modifier_id string
---@param to_this_item CollectibleType
---@param if_player_is PlayerType[]
---@param player_icon PlayerType
---@param append_to_description string
function EIDUtils.PlayerBasedModifier(modifier_id, to_this_item, if_player_is, player_icon, append_to_description)
    local function condition(descObject)
        if EIDUtils.DescObjIs(descObject, 5, 100, to_this_item)
        and PlayerUtils.AnyPlayerIs(table.unpack(if_player_is))
        then return true end
    end
    local function modifier(descObject)
        EID:appendToDescription(descObject, "#{{Player"..player_icon.."}} "..append_to_description)
        return descObject
    end
    EID:addDescriptionModifier(modifier_id, condition, modifier)
end


-- @_param_ `changes`
--
-- _type_ `string` — Text will be appended to the description
--
-- _type_ `table<string | number>` — Replaces index 1 with 2, 3 with 4, etc. So passing in `{" 1 ", " a lot ", 2, "three"}` will replace `" 1 "` with `" a lot "` and `2` with `"three"`
--
-- _type_ `table<string | number>` — As an added bonus, passing in a string at the end will append it to the description, so passing in `{1, 2, "All downsides are removed!"}` will replace `1` with `2` and add "All downsides are removed!" to the description
---@param id Card
---@param changes string | table<string | number>
---@param language any?
function EIDUtils.TarotClothMetadata(id, changes, language)
	language = language or "en_us"

    EID:CreateDescriptionTableIfMissing("tarotClothBuffs", language)

    local function SetCardDesc(data)
        EID.descriptions[language].tarotClothBuffs[id] = data
    end

    if type(changes) == "string" then
        SetCardDesc("{{ColorShinyPurple}}"..changes.."{{CR}}")
    else
        if #changes % 2 == 1 then
            changes[#changes] = "{{ColorShinyPurple}}"..changes[#changes].."{{CR}}"
        end
        SetCardDesc(changes)
    end
end

return EIDUtils