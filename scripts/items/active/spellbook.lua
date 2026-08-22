local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------




Config.ENABLE_EID_HISTORY = true -- *Default: `true` — Enables the External Item Descriptions history.*
Config.MAX_EID_HISTORY = 10 -- *Default: `10` — Maximum number of items displayed on the External Item Descriptions history.*

Config.KEEP_ITEMS = false -- *Default: `false` — Remove items on new floor?*

Config.ENABLE_ACTIVES  = true -- *Default: `true` — Should we be able to roll for active items?*
Config.ENABLE_PASSIVES = true -- *Default: `true` — Should we be able to roll for passive items?*
Config.ENABLE_FAMILIAR = true -- *Default: `true` — Should we be able to roll for familiars?*

-- If we get these items, we roll again.
-- This can be because the game crashes, or the item just doesn't work.
Config.REROLL_ITEMS = {
    CollectibleType.COLLECTIBLE_DELIRIOUS
}

-- If you feel like an item should have a default spell that never changes, you can add it here
--
-- 1 = LEFT
--
-- 2 = UP
--
-- 3 = RIGHT
--
-- 4 = DOWN
Config.SPELL_OVERWRITE = {
    -- ["22441313"] = CollectibleType.COLLECTIBLE_DEATH_CERTIFICATE
}



--------------------------
-- END OF CONFIGURATION --
--------------------------
local ConfigDefaults = ARAOI.TableUtils.ShallowCopy(Config)


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Spellbook = {}
ARAOI.Spellbook.Config = Config

local SFX = SFXManager()
local ItemConfig = Isaac.GetItemConfig()

local collectible = Sprite("gfx/005.100_collectible.anm2", true)
collectible:SetAnimation("ShopIdle")
collectible:SetFrame(1)
collectible.Color.A = 0.7

---------------
-- FUNCTIONS --
---------------

---@param frame integer
local function CreateArrowSprite(frame)
    local arrow = Sprite("gfx/ui/hud_arrow.anm2")
    arrow:SetOverlayRenderPriority(true)
    arrow:SetAnimation(arrow:GetDefaultAnimationName())
    arrow:SetFrame(frame)

    return arrow
end

---@return Sprite
local function CreateBookSprite()
    local book = Sprite("gfx/ui/hud_spellbook.anm2", true)
    book:SetOverlayRenderPriority(true)
    book:SetAnimation(book:GetDefaultAnimationName())
    book:SetFrame(1)
    return book
end

local SPELLBOOK_SPRITE = CreateBookSprite()

local arrows = {
    CreateArrowSprite(0),
    CreateArrowSprite(1),
    CreateArrowSprite(2),
    CreateArrowSprite(3)
}

-- Note that I am not storing some data in the SaveDataManager, but in this script itself
-- This means that this data will not be saved across fully closing and reopening the game
-- I am hoping to prevent a hardlock, this way if you get stuck writing a spell, you can always just close and reopen the game

local Writing_Spell_Data = {}

-- Checks if the player is writing a spell
--
-- If `is_writing` is passed, sets the current state to the provided boolean
---@param player EntityPlayer
---@param is_writing? boolean
---@return boolean
function ARAOI.Spellbook.IsPlayerWritingSpell(player, is_writing)
    if is_writing ~= nil then
        Writing_Spell_Data[ARAOI.PlayerUtils.GetId(player)] = is_writing
    end
    return Writing_Spell_Data[ARAOI.PlayerUtils.GetId(player)] or false
    -- return ARAOI.SaveDataManager:Key(Writing_Spell_Data, ARAOI.PlayerUtils.GetID(player), false, is_writing)
end

local Written_Spells = {}


-- Gets the player's currently written spell
--
-- If `spell` is passed, sets the currently written spell to the provided string
---@param player EntityPlayer
---@param spell? string
---@return string
function ARAOI.Spellbook.PlayerWrittenSpell(player, spell)
    if spell then
        Written_Spells[ARAOI.PlayerUtils.GetId(player)] = spell
    end
    return Written_Spells[ARAOI.PlayerUtils.GetId(player)] or ""
    -- return ARAOI.SaveDataManager:Key(Written_Spells, ARAOI.PlayerUtils.GetID(player), "", spell)
end


-- Adds a temporary item to the player, which will be deleted on the next floor
---@param player EntityPlayer
---@param item CollectibleType
---@return nil
function ARAOI.Spellbook.AddTemporaryItemToPlayer(player, item)
    local temporary_items = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetId(player), {})

    player:AddCollectible(item)
    local history = player:GetHistory():GetCollectiblesHistory()
    table.insert(temporary_items, history[#history]:GetTime())

    ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetId(player), {}, temporary_items)
end

-- Removes the temporary items from the player
---@param player EntityPlayer
---@return nil
function ARAOI.Spellbook.RemoveTemporaryItemsFromPlayer(player)
    local temporary_items = ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetId(player), {})

    for _, item in ipairs(player:GetHistory():GetCollectiblesHistory()) do
        if ARAOI.TableUtils.IsValueInTable(item:GetTime(), temporary_items) then
            player:RemoveCollectible(item:GetItemID())
        end
    end

    ARAOI.SaveDataManager:Data(ARAOI.SaveDataManager.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetId(player), {}, {})
end

-- Returns the known spells for use with EID
--
-- If `spell` and `item` are passed, adds them to the known spells
---@param spell string?
---@param item CollectibleType?
---@return table table -- `{{spell: str, item: CollectibleType}, ...}`
function ARAOI.Spellbook.EIDRegisteredSpells(spell, item)
    local data = ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.RUN, "SpellbookRegisteredSpells", {})
    if spell and item then
        for i, v in ipairs(data) do
            local stored_spell = v[1]
            if spell == stored_spell then
                table.remove(data, i)
            end
        end

        table.insert(data, {spell, item})
    end

    ARAOI.SaveDataManager:Key(ARAOI.SaveDataManager.RUN, "SpellbookRegisteredSpells", {}, data)

    return ARAOI.TableUtils.ReverseList(data)
end

-- Converts the passed spell into a string of EID Inline Icons
---@param spell string
---@return string
function ARAOI.Spellbook.SpellToEIDInlineArrows(spell)
    local result = ""
    for i = 1, #spell do
        local char = string.sub(spell, i, i)
        result = result.."{{SBArrow"..char.."}}"
    end
    return result
end

-- Function to add overwrites from other scripts or mods more easily
---@param spell string -- The spell which, when entered, will give the specified item. `1 = LEFT`, `2 = UP`, `3 = RIGHT`, `4 = DOWN`
---@param item CollectibleType
function ARAOI.Spellbook.AddSpellOverwrite(spell, item)
    spell = tostring(spell)

    if Config.SPELL_OVERWRITE[spell] ~= nil then
        Isaac.ConsoleOutput("ARAOI - The spell: "..spell..", is already defined. Consider using another spell.")
    end

    Config.SPELL_OVERWRITE[spell] = item
end

-- Function to add an item to the blacklist from other scripts or mods more easily
---@param item CollectibleType
function ARAOI.Spellbook.AddItemToBlacklist(item)
    table.insert(Config.REROLL_ITEMS, item)
end


-------------------
-- INPUT BLOCKER --
-------------------

---@param entity Entity
---@param inputHook InputHook
---@param buttonAction ButtonAction
function ARAOI:_OnSpellbookInputAction(entity, inputHook, buttonAction)
    if not entity then return end
    if not PlayerManager.AnyoneHasCollectible(ARAOI.CollectibleType.SPELLBOOK) then return end

    local player = entity:ToPlayer()
    if not player or not ARAOI.Spellbook.IsPlayerWritingSpell(player) then return end

    -- Check if this input call is checking if the player wants to shoot
    if inputHook == InputHook.IS_ACTION_PRESSED
    and ARAOI.TableUtils.IsValueInTable(
        buttonAction,
        {
            ButtonAction.ACTION_SHOOTLEFT,
            ButtonAction.ACTION_SHOOTUP,
            ButtonAction.ACTION_SHOOTRIGHT,
            ButtonAction.ACTION_SHOOTDOWN
        }
    )
    then
        -- If we are writing a spell, we block the shooting input
        if inputHook == InputHook.GET_ACTION_VALUE then
            return 0
        else
            return false
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_INPUT_ACTION, ARAOI._OnSpellbookInputAction)


--------------------
-- MISC FUNCTIONS --
--------------------

function ARAOI:_OnSpellbookNewLevel()
    if not Config.KEEP_ITEMS then
        for _, player in pairs(PlayerManager.GetPlayers()) do
            ARAOI.Spellbook.RemoveTemporaryItemsFromPlayer(player)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ARAOI._OnSpellbookNewLevel)


----------------------------
-- ITEM USE FUNCTIONALITY --
----------------------------

---@param player EntityPlayer
---@param slot ActiveSlot
function ARAOI:_OnSpellbookUse(_, _, player, useFlag, slot)
    local game = Game()

    -- This prevents us from entering the writing state from items such as Void
    -- If that were to happen, it would be a soft-lock
    if not player:HasCollectible(ARAOI.CollectibleType.SPELLBOOK) then return end

    -- Prevent the item from being used twice with car battery
    -- The second use casts the spell, but there is no time to write one
    -- so Car Battery makes the item useless
    if useFlag & UseFlag.USE_CARBATTERY > 0 then return end

    -- If every item type is disabled
    if not Config.ENABLE_PASSIVES and not Config.ENABLE_ACTIVES and not Config.ENABLE_FAMILIAR then
        -- Special interaction where we remove the book and simultaneously spawn a mama mega explosion and a dogma black hole
        player:RemoveCollectible(ARAOI.CollectibleType.SPELLBOOK)
        game:GetRoom():MamaMegaExplosion(player.Position)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DOGMA_BLACKHOLE, 0, player.Position, Vector.Zero, nil)
        return
    end

    -- Toggle the player's writing ability, which locks and unlocks shooting
    local writing = ARAOI.Spellbook.IsPlayerWritingSpell(player, not ARAOI.Spellbook.IsPlayerWritingSpell(player))

    -- Check what spell we've written, this is used on the item's second use, after something was written
    local spell = ARAOI.Spellbook.PlayerWrittenSpell(player)

    -- We just stopped writing and there's something written
    if writing == false and spell ~= "" then
        -- Get the RNG based on what's written and the current seed
        local rng = RNG(tonumber(spell) + game:GetSeeds():GetStartSeed())

        -- Setting some default values so we can keep rerolling the items until an item
        -- which can be used is selected, basically skipping over the items defined
        -- on the RerollItems list
        local spell_item = nil
        local config = nil

        -- While we don't have an item selected, the item selected is in the RerollItems list or the config doesn't exist
        while spell_item == nil
        or ARAOI.TableUtils.IsValueInTable(spell_item, Config.REROLL_ITEMS)
        or config == nil
        do
            -- Get a random item and it's configuration, then check again
            -- The line below is here because my code editor screams at me otherwise
            ---@diagnostic disable-next-line: undefined-field
            spell_item = Config.SPELL_OVERWRITE[spell] or rng:RandomInt(ItemConfig:GetCollectibles().Size - 1)
            config = ItemConfig:GetCollectible(spell_item)

            -- If we got a disabled item type, we get rid of the config to roll again
            if (config.Type == ItemType.ITEM_PASSIVE and not Config.ENABLE_PASSIVES)
            or (config.Type == ItemType.ITEM_ACTIVE and not Config.ENABLE_ACTIVES)
            or (config.Type == ItemType.ITEM_FAMILIAR and not Config.ENABLE_FAMILIAR)
            then
                config = nil
            end
        end

        -- If the item is a passive item or a familiar
        if config.Type == ItemType.ITEM_PASSIVE or config.Type == ItemType.ITEM_FAMILIAR then
            -- We add the item to the list of temporary items for them to get deleted later, keeping in mind Car Battery
            ARAOI.PlayerUtils.CarBatteryWrapper(player, function ()
                ARAOI.Spellbook.AddTemporaryItemToPlayer(player, spell_item)
            end)

        else -- If the item is not a passive item
            -- Use the active item, and twice if we have Car Battery
            ARAOI.PlayerUtils.CarBatteryWrapper(player, function (car_battery_flag)
                -- Use the active item, adding the necessary UseFlags
                player:UseActiveItem(spell_item, car_battery_flag, slot)

                -- If we have book of virtues, we artificially spawn wisps
                if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                    -- Spawn a wisp
                    player:AddWisp(spell_item, player.Position)
                    SFX:Play(SoundEffect.SOUND_CANDLE_LIGHT)
                end
            end)
        end

        -- Show the player what item was used by the spell and play a sound
        game:GetHUD():ShowItemText(player, config)
        player:AnimateCollectible(spell_item)
        SFX:Play(SoundEffect.SOUND_POWERUP1, 0.3, nil, nil, 2)

        -- Register this spell
        ARAOI.Spellbook.EIDRegisteredSpells(spell, spell_item)

        -- Clear the spell
        ARAOI.Spellbook.PlayerWrittenSpell(player, "")

    -- We just stopped writing but there was no spell written
    elseif writing == false and spell == "" then
        -- Play an error sound
        SFXManager():Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
        ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)


    -- We used the item to start writing a spell, show the item's use animation and play a sound
    else
        ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)
        SFX:Play(SoundEffect.SOUND_MENU_RIP, 3)
        return true
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnSpellbookUse, ARAOI.CollectibleType.SPELLBOOK)


------------------------------
-- BOOK AND ARROWS RENDERER --
------------------------------

function ARAOI:_OnSpellbookRender()
    -- If anyone is writing a spell, keep track of it
    local anyone_is_writing_spell = false

    -- Do a render pass for each player
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        -- Check if the player is writing
        if ARAOI.Spellbook.IsPlayerWritingSpell(player) then
            -- Don't render if the player is not visible
            if not player:IsVisible() then goto next_player end

            -- Get the written spell
            local spell = ARAOI.Spellbook.PlayerWrittenSpell(player)
            -- We are writing a spell!
            anyone_is_writing_spell = true

            -- If we are writing and we don't have the book, that means
            -- it's either a soft-lock or we put the book down while writing
            -- So, we set everything to the default values
            if not player:HasCollectible(ARAOI.CollectibleType.SPELLBOOK) then
                ARAOI.Spellbook.IsPlayerWritingSpell(player, false)
                ARAOI.Spellbook.PlayerWrittenSpell(player, "")
            end

            -- Get the player's position relative to the screen
            local position = Isaac.WorldToScreen(player.Position)

            -- Offset the position so the book get's rendered on top of the player
            position.Y = position.Y - 50
            position.X = position.X + 0.5

            -- Render the book at the offset position
            SPELLBOOK_SPRITE:Render(position)

            -- Defining a function to not have to copy-paste this 4 times
            local function playInputSoundEffect()
                SFX:Play(SoundEffect.SOUND_POT_BREAK_2, 0.3, nil, nil, 3)
            end

            -- If the spell is less than 8 characters long, we can write to it
            -- This is an arbitrary value good enough to generate a spell for every item
            -- in the game while not going over the integer limit
            if #spell < 8 then
                local s = ARAOI.Spellbook.PlayerWrittenSpell(player)
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, s.."1")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, s.."2")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, s.."3")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, s.."4")
                    playInputSoundEffect()
                end
                if Input.IsButtonTriggered(Keyboard.KEY_BACKSPACE, player.ControllerIndex)
                or Input.IsButtonTriggered(Keyboard.KEY_DELETE, player.ControllerIndex)
                then
                    if #spell > 0 then
                        ARAOI.Spellbook.PlayerWrittenSpell(player, string.sub(s, 1, #s - 1))
                        SFX:Play(SoundEffect.SOUND_PLOP, 0.6)
                    end
                end

            -- If we wrote past the spell cap then we erase the spell and play a sound
            else
                if ARAOI.PlayerUtils.TriggeredShooting(player) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, "")
                    SFX:Play(SoundEffect.SOUND_PLOP, 0.6)
                end
            end

            -- If we switched items we cancel the interaction
            if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
                ARAOI.Spellbook.PlayerWrittenSpell(player, "")
                ARAOI.Spellbook.IsPlayerWritingSpell(player, false)
            end

            -- For every character in the written spell
            for i = 1, #spell do
                -- Get the character
                local character = spell:sub(i,i)

                -- Get the player's position relative to the screen
                local arrow_position = Isaac.WorldToScreen(player.Position)

                -- Offset the arrows so they end up centered
                -- I honestly have no idea how I ended up with this formula, it was a lot of trial and error
                arrow_position.X = arrow_position.X - 6.3 - (string.len(spell)/2-i) * 14
                arrow_position.Y = arrow_position.Y - 51

                -- Get the arrow for that character and render it to the offset position
                arrows[tonumber(character)]:Render(arrow_position)
            end

            -- Getting all the known spells
            local known_spells = ARAOI.Spellbook.EIDRegisteredSpells()
            -- Looping through every known spell
            for i = 1,#known_spells do
                -- Getting the spell and the item
                local registered_spell, spell_item = known_spells[i][1], known_spells[i][2]
                -- If the registered spell is the same as the spell we are currently writing
                if registered_spell == spell then
                    -- Get the item image
                    local item_image = ItemConfig:GetCollectible(spell_item).GfxFileName

                    -- Replace the spritesheet of the collectible sprite
                    collectible:ReplaceSpritesheet(1, item_image, true)

                    -- Setting the position for the item to be rendered
                    local position = Isaac.WorldToScreen(player.Position)
                    position.Y = position.Y - 57

                    -- Render the item
                    collectible:Render(position)

                    -- We don't need to keep checking spells, so we break out of the loop
                    break
                end
            end
        end

        ::next_player::
    end

    if anyone_is_writing_spell and Config.ENABLE_EID_HISTORY and EID and not EID.isHidden then
        local alpha = EID.Config["Transparency"]
        EID:renderString(
            "{{Collectible"..ARAOI.CollectibleType.SPELLBOOK.."}} Spellbook History",
            Vector(300, 35), Vector(1,1), KColor(175/255, 77/255, 168/255, alpha), false
        )
        local known_spells = ARAOI.Spellbook.EIDRegisteredSpells()
        if #known_spells > 0 then
            for i = 1,math.min(#known_spells, Config.MAX_EID_HISTORY) do
                local spell, item = known_spells[i][1], known_spells[i][2]
                EID:renderString(
                    "{{Collectible"..item.."}} "..ARAOI.Spellbook.SpellToEIDInlineArrows(spell),
                    Vector(300, 35 + 15 * i), Vector(1,1), KColor(1, 1, 1, alpha), false
                )
            end
        else
            EID:renderString(
                "Write something!",
                Vector(300, 35 + 15), Vector(1,1), KColor(1, 1, 1, alpha), false
            )
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_RENDER, ARAOI._OnSpellbookRender)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    local arrow_sprite = Sprite("gfx/ui/eid_inline_arrow.anm2")
    EID:addIcon("SBArrow1", "idle", 0, 14, 11, 7, 6, arrow_sprite)
    EID:addIcon("SBArrow2", "idle", 1, 11, 14, 6, 5, arrow_sprite)
    EID:addIcon("SBArrow3", "idle", 2, 14, 11, 7, 6, arrow_sprite)
    EID:addIcon("SBArrow4", "idle", 3, 11, 14, 6, 5, arrow_sprite)

    EID:addCollectible(ARAOI.CollectibleType.SPELLBOOK,
        "#{{Collectible"..ARAOI.CollectibleType.SPELLBOOK.."}} On use, spawns an open Spellbook above Isaac"..
        "#{{Tearsize}} Shooting in any direction will write to the Spellbook"..
        "#{{Collectible}} Casting the spell will mimic the use of a random item"..
        "#{{Collectible"..(CollectibleType.COLLECTIBLE_RESTOCK).."}} Writing the same spell will mimic the same item"..
        "#{{TreasureRoom}} If the used item was a passive item, it will instead be given to Isaac for the rest of the floor"
    )

    EID:addCarBatteryCondition(ARAOI.CollectibleType.SPELLBOOK, "Will cast the spells twice")
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "Spellbook Book Of Virtues",
        ARAOI.CollectibleType.SPELLBOOK,
        "Casting an active item spell will also spawn its wisp"
    )
end)


---------------------
-- MOD CONFIG MENU --
---------------------

if ModConfigMenu then
    ARAOI.MCMUtils.AddItemTitle("Actives", "Spellbook")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Spellbook", Config, "ENABLE_EID_HISTORY", ConfigDefaults, function ()
        return "Enable EID History: "
    end, "Enables the EID history for the Spellbook")

    ARAOI.MCMUtils.AddNumberSetting("Actives", "Spellbook", Config, "MAX_EID_HISTORY", ConfigDefaults, ConfigDefaults.MAX_EID_HISTORY, 1, 20, 5, function ()
        return "Max EID History: " .. Config.MAX_EID_HISTORY
    end, "Maximum number of spells displayed on the EID history")

    ModConfigMenu.AddSpace("ARAOI", "Actives")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Spellbook", Config, "KEEP_ITEMS", ConfigDefaults, function ()
        return "Keep Items: "
    end, "Keep items on new floor?")

    ModConfigMenu.AddSpace("ARAOI", "Actives")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Spellbook", Config, "ENABLE_ACTIVES", ConfigDefaults, function ()
        return "Enable Active Items: "
    end, "Should we be able to roll for active items?")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Spellbook", Config, "ENABLE_PASSIVES", ConfigDefaults, function ()
        return "Enable Passive Items: "
    end, "Should we be able to roll for passive items?")

    ARAOI.MCMUtils.AddBooleanSetting("Actives", "Spellbook", Config, "ENABLE_FAMILIAR", ConfigDefaults, function ()
        return "Enable Familiars: "
    end, "Should we be able to roll for familiars?")

    ARAOI.MCMUtils.AddReset("Actives", "Spellbook")
end