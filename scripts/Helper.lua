
---@class helper
local helper = {}

---@type EIDUtils
helper.eid = include("scripts.utils.eid")

---@type ItemUtils
helper.item = include("scripts.utils.item")

---@type MiscUtils
helper.misc = include("scripts.utils.misc")

---@type PlayerUtils
helper.player = include("scripts.utils.player")

---@type RoomUtils
helper.room = include("scripts.utils.room")

---@type TableUtils
helper.table = include("scripts.utils.table")

return helper