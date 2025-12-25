---@class MCMUtils
local MCMUtils = {}


---@param Category string -- "The name of the MCM SubCategory"
---@param Name string -- Name of the item
---@param SettingsTable table -- The `Config` table of the item
---@param Key string -- The `Key` of the `Config`
---@param DefaultSettings table -- The `ConfigDefaults` table of the item
---@param Default string -- The string that will show in the `info`
---@param Minimum integer
---@param Maximum integer
---@param SpecialStep integer -- The the step number when holding down the `Drop Button`
---@param Display function -- Function that returns a string to display when the value changes
---@param Description string -- The description that will show in the `info`
---@param Description2? string -- The description that will show in the `info`, second line
function MCMUtils.AddNumberSetting(Category, Name, SettingsTable, Key, DefaultSettings, Default, Minimum, Maximum, SpecialStep, Display, Description, Description2)
    ModConfigMenu.AddSetting(
        "ARAOI",
        Category,
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function ()
                return SettingsTable[Key]
            end,
            Minimum = Minimum,
            Maximum = Maximum,
            Display = function ()
                return ((SettingsTable[Key] ~= DefaultSettings[Key]) and "* " or "") .. Display()
            end,
            OnChange = function (n)
                if Input.IsActionPressed(ButtonAction.ACTION_DROP, Isaac.GetPlayer().ControllerIndex) then
                    SettingsTable[Key] = math.min(Maximum, math.max(Minimum, n + (SpecialStep * ((SettingsTable[Key] < n) and 1 or -1)) -((SettingsTable[Key] < n) and 1 or -1)))
                else
                    SettingsTable[Key] = n
                end
                -- SettingsTable[Key] = (Input.IsButtonPressed(Keyboard.KEY_LEFT_CONTROL, Isaac.GetPlayer().ControllerIndex) and n+SpecialStep or n)
                ARAOI.EIDReload()
                ARAOI.SaveDataManager:MCM(Name, Key, SettingsTable[Key], SettingsTable[Key])
            end,
            Info = {
                "Default: " .. Default,
                Description,
                Description2
            }
        }
    )

    ARAOI.MCMWrapper(function ()
        SettingsTable[Key] = ARAOI.SaveDataManager:MCM(Name, Key, DefaultSettings[Key])
    end)
end

---@param Category string -- "The name of the MCM SubCategory"
---@param Name string -- Name of the item
---@param SettingsTable table -- The `Config` table of the item
---@param Key string -- The `Key` of the `Config`
---@param DefaultSettings table -- The `ConfigDefaults` table of the item
---@param Display function -- Function that returns a string to display when the value changes
---@param Description string -- The description that will show in the `info`
---@param Description2? string -- The description that will show in the `info`, second line
function MCMUtils.AddBooleanSetting(Category, Name, SettingsTable, Key, DefaultSettings, Display, Description, Description2)
    ModConfigMenu.AddSetting(
        "ARAOI",
        Category,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function ()
                return SettingsTable[Key]
            end,
            Display = function ()
                return ((SettingsTable[Key] ~= DefaultSettings[Key]) and "* " or "") .. Display() .. (SettingsTable[Key] and "YES" or "NO")
            end,
            OnChange = function (n)
                SettingsTable[Key] = n
                ARAOI.EIDReload()
                ARAOI.SaveDataManager:MCM(Name, Key, SettingsTable[Key], n)
            end,
            Info = {
                "Default: " .. (DefaultSettings[Key] and "YES" or "NO"),
                Description,
                Description2
            }
        }
    )

    ARAOI.MCMWrapper(function ()
        SettingsTable[Key] = ARAOI.SaveDataManager:MCM(Name, Key, DefaultSettings[Key])
    end)
end

function MCMUtils.AddItemTitle(Category, Name)
    ModConfigMenu.AddSpace(
        "ARAOI",
        Category
    )

    ModConfigMenu.AddTitle(
        "ARAOI",
        Category,
        Name
    )
end

function MCMUtils.AddReset(Category, Name)
    local reset_selection = 1
    ModConfigMenu.AddSetting(
        "ARAOI",
        Category,
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            Minimum = 0,
            Maximum = 3,
            CurrentSetting = function()
                return reset_selection
            end,
            Display = function()
                local text = {"Reset Config", "Are You Sure?"}
                return text[reset_selection]
            end,
            OnChange = function(n)
                if n == 3 then
                    reset_selection = 1
                    ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.MOD_CONFIG_MENU, Name, {}, {})
                    ARAOI.MCMReload()
                    ARAOI.EIDReload()
                elseif n ~= 0 then
                    reset_selection = n
                end
            end
        }
    )
end



return MCMUtils