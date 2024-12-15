--[[

    This is the script that holds everything together and allows for other scripts
    to communicate with each other, including scripts from other mods!

--]]

---@class CollectibleType
ARAOI.CollectibleType = {
    ---@type integer
    THREED_GLASSES = Isaac.GetItemIdByName("3D Glasses"),

    ---@type integer
    BAG_OF_HOLDING = Isaac.GetItemIdByName("Bag of Holding"),

    ---@type integer
    ETERNAL_DPLOPIA = Isaac.GetItemIdByName("Eternal Dplopia"),

    ---@type integer
    GLASS_DIE = Isaac.GetItemIdByName("Glass Die"),

    ---@type integer
    RUBIKS_CUBE = Isaac.GetItemIdByName("Rubik's Cube"),

    ---@type integer
    SPELLBOOK = Isaac.GetItemIdByName("Spellbook"),

    ---@type integer
    WIRE_CUTTER = Isaac.GetItemIdByName("Wire Cutter"),

    ---@type integer
    BLESSINGS_PETAL = Isaac.GetItemIdByName("Blessing's Petal"),

    ---@type integer
    DUALITY_HALO = Isaac.GetItemIdByName("Duality Halo"),

    ---@type integer
    GAMBLING_CHIPS = Isaac.GetItemIdByName("Gambling Chips"),

    ---@type integer
    LUCKY_COIN = Isaac.GetItemIdByName("Lucky Coin"),

    ---@type integer
    RAINBOW_HEADBAND = Isaac.GetItemIdByName("Rainbow Headband"),

    ---@type integer
    SACRIFICIAL_HEART = Isaac.GetItemIdByName("Sacrificial Heart"),

    ---@type integer
    VAMPIRE_CLOAK = Isaac.GetItemIdByName("Vampire Cloak"),

    ---@type integer
    VOODOO_BODY = Isaac.GetItemIdByName("Voodoo Body"),

    ---@type integer
    NUM_COLLECTIBLES = 15
}

---@class TrinketType
ARAOI.TrinketType = {
    ---@type integer
    SPARE_BATTERY = Isaac.GetTrinketIdByName("Spare Battery"),

    ---@type integer
    SOLVED_RUBIKS_CUBE = Isaac.GetTrinketIdByName("Solved Rubik's Cube"),

    ---@type integer
    INVERTED_SPADES = Isaac.GetTrinketIdByName("Inverted Spades"),

    ---@type integer
    NUM_TRINKETS = 3
}

---@class CardSubType
ARAOI.CardSubType = {
    ---@type integer
    INVERTED_FOOL = Isaac.GetCardIdByName("Inverted Fool"),

    ---@type integer
    INVERTED_MAGICIAN = Isaac.GetCardIdByName("Inverted Magician"),

    ---@type integer
    INVERTED_HIGH_PRIESTESS = Isaac.GetCardIdByName("Inverted High Priestess"),

    ---@type integer
    INVERTED_EMPRESS = Isaac.GetCardIdByName("Inverted Empress"),

    ---@type integer
    INVERTED_EMPEROR = Isaac.GetCardIdByName("Inverted Emperor"),

    ---@type integer
    INVERTED_HERMIT = Isaac.GetCardIdByName("Inverted Hermit"),

    ---@type integer
    INVERTED_HIEROPHANT = Isaac.GetCardIdByName("Inverted Hierophant"),

    ---@type integer
    INVERTED_LOVERS = Isaac.GetCardIdByName("Inverted Lovers"),

    ---@type integer
    INVERTED_CHARIOT = Isaac.GetCardIdByName("Inverted Chariot"),

    ---@type integer
    INVERTED_JUSTICE = Isaac.GetCardIdByName("Inverted Justice"),

    ---@type integer
    INVERTED_WHEEL_OF_FORTUNE = Isaac.GetCardIdByName("Inverted Wheel of Fortune"),

    ---@type integer
    INVERTED_STRENGTH = Isaac.GetCardIdByName("Inverted Strength"),

    ---@type integer
    INVERTED_HANGED_MAN = Isaac.GetCardIdByName("Inverted Hanged Man"),

    ---@type integer
    INVERTED_DEATH = Isaac.GetCardIdByName("Inverted Death"),

    ---@type integer
    INVERTED_TEMPERANCE = Isaac.GetCardIdByName("Inverted Temperance"),

    ---@type integer
    INVERTED_DEVIL = Isaac.GetCardIdByName("Inverted Devil"),

    ---@type integer
    INVERTED_TOWER = Isaac.GetCardIdByName("Inverted Tower"),

    ---@type integer
    INVERTED_STARS = Isaac.GetCardIdByName("Inverted Stars"),

    ---@type integer
    INVERTED_MOON = Isaac.GetCardIdByName("Inverted Moon"),

    ---@type integer
    INVERTED_SUN = Isaac.GetCardIdByName("Inverted Sun"),

    ---@type integer
    INVERTED_JUDGEMENT = Isaac.GetCardIdByName("Inverted Judgement"),

    ---@type integer
    INVERTED_WORLD = Isaac.GetCardIdByName("Inverted World"),

    ---@type integer
    NUM_CARDS = 22
}

---@class SaveDataManager
ARAOI.SaveData = include("scripts.SaveDataManager"):init(ARAOI.Mod)

---@class EIDUtils
ARAOI.EIDUtils = include("scripts.utils.eidutils")

---@class ItemUtils
ARAOI.ItemUtils = include("scripts.utils.item")

---@class MiscUtils
ARAOI.MiscUtils = include("scripts.utils.misc")

---@class PlayerUtils
ARAOI.PlayerUtils = include("scripts.utils.player")

---@class RoomUtils
ARAOI.RoomUtils = include("scripts.utils.room")

---@class TableUtils
ARAOI.TableUtils = include("scripts.utils.table")

-- Wrapper for the description reloaded callback
function ARAOI.ReloadableDescription(func)
    if EID then
        ARAOI.Mod:AddCallback("Reload ARAOI EID Descriptions", func)
    end
end

-- Calls the callback responsible for reloading the EID descriptions
function ARAOI.ReloadDescriptions()
    if EID then
        Isaac.RunCallback("Reload ARAOI EID Descriptions")
    end
end