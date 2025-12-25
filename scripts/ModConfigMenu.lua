local reset_selection = 1


ModConfigMenu.AddText("ARAOI", "General", "Hold the DROP BUTTON")
ModConfigMenu.AddText("ARAOI", "General", "to change values FASTER")

ModConfigMenu.AddSpace("ARAOI", "General")

ModConfigMenu.AddSetting(
    "ARAOI",
    "General",
    {
        Type = ModConfigMenu.OptionType.NUMBER,
        Minimum = 0,
        Maximum = 4,
        CurrentSetting = function()
            return reset_selection
        end,
        Display = function()
            local text = {"Reset All Configs", "Are You Sure?", "Are You Really Sure?"}
            return text[reset_selection]
        end,
        OnChange = function(n)
            if n == 4 then
                reset_selection = 1
                ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager, "MOD_CONFIG_MENU", {}, {})
                ARAOI.MCMReload()
                ARAOI.EIDReload()
            elseif n ~= 0 then
                reset_selection = n
            end
        end
    }
)