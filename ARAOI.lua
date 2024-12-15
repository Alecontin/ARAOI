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
    VOODOO_BODY = Isaac.GetItemIdByName("Voodoo Body")
}
ARAOI.CollectibleType.NUM_COLLECTIBLES = #ARAOI.CollectibleType

---@class TrinketType
ARAOI.TrinketType = {
    ---@type integer
    SPARE_BATTERY = Isaac.GetTrinketIdByName("Spare Battery"),

    ---@type integer
    SOLVED_RUBIKS_CUBE = Isaac.GetTrinketIdByName("Solved Rubik's Cube"),

    ---@type integer
    INVERTED_SPADES = Isaac.GetTrinketIdByName("Inverted Spades")
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