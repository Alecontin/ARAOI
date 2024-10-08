--[[

    Welcome to this mess of a save data manager.
    Since this is one of my first mods ever made, the code here is not really great.

    Feel free to use this if you want.

    When importing this module, always use the 'require' method.

    Why? Because 'require' caches the file, so if you require it
    somewhere else the data will be the same across files.

    If you instead were to 'include' it, it would create a separate
    copy of the module for each file you include it in, which would
    make data different per file, which is not what you'd want.

    Please avoid setting the whole context table, you should use a
    different key for everything that you need.

    Lets say that I have a function that gets all the context data,
    does something, and then sets it again.

    Then lets say I have an item that writes something to the context.

    What could happen is as follows:

    function gets the context: {"Hello World!"}
    item then adds stuff to the context: {"Hello World!", "Foo Bar"}
    the other function finished executing and set the context again: {"Hello World"}

    Even though the item added stuff to the context, the function reverted that.
    That's why you should avoid setting the whole context to anything. Just leave
    that to the manager itself.

    Also, DO NOT, EVER, USE NUMBERS AS KEYS!
    If you have, for example, {[268723463] = "Hello World"}

    What will happen when you save that is:
    IT WILL CREATE ALL INDEXES UP UNTIL THE NUMBER THAT YOU SET!

    The file WILL run out of memory to use, and nothing will be saved.
    I learned that the hard way.

--]]







local json = require("json")

---@class SaveDataManager
local save = {}

---@class Timer
local Timer = {}

---@type string
Timer.CALLBACK = ""

---@type integer
Timer.FRAMES = 0

---@type table?
Timer.PARAMS = {}

---@type function
local ShallowCopy = include("scripts.utils.table").ShallowCopy



------------------------------------
-- SaveDataManager Initialization --
------------------------------------

---@param Mod ModReference
function save:init(Mod)
    -- Get the game object
    local game = Game()

    -- Data can be stored in any of these tables
    -- Context will automatically clear

    save.PERSISTANT = {}
    save.RUN = {}
    save.LEVEL = {}
    save.ROOM = {}
    save.TIMERS = {}

    save.LAST_ROOM_RUN = {}
    save.LAST_ROOM_LEVEL = {}
    save.LAST_ROOM_ROOM = {}
    save.LAST_ROOM_TIMERS = {}

    -- Gets the data to save
    local function saveData()
        local data = json.encode({
            save.PERSISTANT, save.RUN, save.LEVEL, save.ROOM, save.TIMERS
        })
        return data
    end

    -------------
    -- LOADING --
    -------------

    -- Load the save file data when a game is continued,
    -- otherwise wipe everything except the PERSISTANT context

    local function loadSaveData(isContinued)
        if not isContinued then
            -- Clearing all the contexts

            save.RUN    = {}
            save.LEVEL  = {}
            save.ROOM   = {}
            save.TIMERS = {}
        else
            -- The run is continued, try to load data

            -- Get the mod's data
            local mod_data = Mod:LoadData()

            -- If the mod's data is not an empty string
            if mod_data ~= "" then
                -- Decode the data
                local data = json.decode(mod_data)

                save.PERSISTANT = data[1] or {}
                save.RUN        = data[2] or {}
                save.LEVEL      = data[3] or {}
                save.ROOM       = data[4] or {}
                save.TIMERS     = data[5] or {}
            end
        end
    end

    ---@param isContinued boolean
    local function onGameStarted(_, isContinued)
        loadSaveData(isContinued)
    end
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onGameStarted)

    --------------
    -- CLEARERS --
    --------------

    -- LEVEL context clearer
    local function onLevelChanged(_)
        if game:GetFrameCount() <= 1 then return end
        save.LEVEL = {}
        Mod:SaveData(saveData())
    end
    Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, onLevelChanged)

    -- ROOM context clearer
    local function onRoomChanged(_)
        if game:GetFrameCount() <= 1 then return end
        save.ROOM = {}
        Mod:SaveData(saveData())
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_NEW_ROOM, onRoomChanged)

    -----------------
    -- SAVING DATA --
    -----------------

    -- Saves the data to the save file on game exit
    ---@param shouldSave boolean
    local function onGameExit(_, shouldSave)
        if shouldSave then
            Mod:SaveData(saveData())
        end
    end
    Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, onGameExit)
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_END, onGameExit)

    -------------------------------
    -- GLOWING HOURGLASS SUPPORT --
    -------------------------------

    -- I wanted to also support the use of the `rewind` command but I can't check for default console commands ☹️

    local function onRewind(_, COMMAND)
        -- if COMMAND == "rewind" or COMMAND == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
        if save.LAST_ROOM_RUN or save.LAST_ROOM_LEVEL or save.LAST_ROOM_ROOM or save.LAST_ROOM_TIMERS then
            save.RUN    = ShallowCopy(save.LAST_ROOM_RUN)
            save.LEVEL  = ShallowCopy(save.LAST_ROOM_LEVEL)
            save.ROOM   = ShallowCopy(save.LAST_ROOM_ROOM)
            save.TIMERS = ShallowCopy(save.LAST_ROOM_TIMERS)
        end
            -- if COMMAND == "rewind" then return "" end
            -- if COMMAND == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then return true end
        -- end
    end
    -- Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, onRewind) -- This does NOT trigger for default game commands apparently
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, onRewind, CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS)

    local function roomChangedStore(_)
        if game:GetFrameCount() <= 1 then return end

        save.LAST_ROOM_RUN    = ShallowCopy(save.RUN)
        save.LAST_ROOM_LEVEL  = ShallowCopy(save.LEVEL)
        save.LAST_ROOM_ROOM   = ShallowCopy(save.ROOM)
        save.LAST_ROOM_TIMERS = ShallowCopy(save.TIMERS)
    end
    Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, roomChangedStore)

    ------------
    -- TIMERS --
    ------------

    -- Updates the timers, subtracting 1 from the update frames and calling the callback when the frames are 0
    local function timerUpdate()
        for i, t in ipairs(save.TIMERS) do
            if t.FRAMES <= 0 then
                if t.PARAMS then
                    Isaac.RunCallback(t.CALLBACK, table.unpack(t.PARAMS))
                else
                    Isaac.RunCallback(t.CALLBACK)
                end
                table.remove(save.TIMERS, i)
            else
                t.FRAMES = t.FRAMES - 1
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, timerUpdate)

    -- Creates a timer that will run the callback in the amount of defined seconds
    ---- "But couldn't I just use Isaac.CreateTimer() instead?"
    --
    -- Well, yes, but this persists across saving and loading.
    ---@param callbackID string -- The ID of the callback to be ran
    ---@param time number -- Time, in seconds, after which the callback will run
    ---@param args? table -- List of parameters to pass to the callback
    function save:CreateTimer(callbackID, time, args)
        self:CreateTimerInFrames(callbackID, time * 30, args)
    end

    -- Creates a timer that will run the callback in the amount of defined update frames
    ---- "But couldn't I just use Isaac.CreateTimer() instead?"
    --
    -- Well, yes, but this persists across saving and loading.
    ---@param callbackID string -- The ID of the callback to be ran
    ---@param time number -- Time, in seconds, after which the callback will run
    ---@param args? table -- List of parameters to pass to the callback
    function save:CreateTimerInFrames(callbackID, time, args)
        local timer = Timer

        timer.CALLBACK = callbackID

        timer.FRAMES = time

        timer.PARAMS = args

        table.insert(save.TIMERS, timer)
    end

    -- Get/Set data from/to an access point
    ---@param access any -- Can be anywhere, as long as it's a table, like `save.RUN`
    ---@param point any -- What point to access from the table, for example: `"CursedObjects"`
    ---@param default any -- What should the default value of the access point (`save.RUN["CursedObjects"]`) be, for example: `{}`
    ---@param default_value any -- What should the default returned value be?
    ---@param key any -- Should be a string, it will be automatically converted to one
    ---@param value? any -- The value to set the key to, leave blank to not set the value
    ---@return any
    function save:Data(access, point, default, key, default_value, value)
        local data = access[tostring(point)] or default
        if value ~= nil then
            data[tostring(key)] = value
            access[tostring(point)] = data
            Mod:SaveData(saveData())
        end
        if data[tostring(key)] ~= nil then
            return data[tostring(key)]
        else
            return default_value
        end
    end

    -- Get/Set data from/to an access point
    ---@param access any -- Can be anywhere, as long as it's a table, like `save.RUN`
    ---@param default any -- What should the default value of the access point (`save.RUN["CursedObjects"]`) be, for example: `{}`
    ---@param key any -- Should be a string, it will be automatically converted to one
    ---@param value? any -- The value to set the key to, leave blank to not set the value
    ---@return any
    function save:Key(access, key, default, value)
        if value ~= nil then
            access[tostring(key)] = value
            Mod:SaveData(saveData())
        end
        if access[tostring(key)] ~= nil then
            return access[tostring(key)]
        else
            return default
        end
    end

    loadSaveData(true)
end

return save