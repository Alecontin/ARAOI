local Config = {}
----------------------------
-- START OF CONFIGURATION --
----------------------------




Config.ENABLE_EID_HISTORY = true -- *Default: `true` — Enables the External Item Descriptions history.*

-- If we get these items, we roll again.
-- This can be because the game just crashes, or the item just doesn't work.
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


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Spellbook = {}
ARAOI.Spellbook.Config = Config

local SFX = SFXManager()

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
    return ARAOI.SaveData:Key(Writing_Spell_Data, ARAOI.PlayerUtils.GetID(player), false, is_writing)
end

local Written_Spells = {}


-- Gets the player's currently written spell
--
-- If `spell` is passed, sets the currently written spell to the provided string
---@param player EntityPlayer
---@param spell? string
---@return string
function ARAOI.Spellbook.PlayerWrittenSpell(player, spell)
    return ARAOI.SaveData:Key(Written_Spells, ARAOI.PlayerUtils.GetID(player), "", spell)
end


-- Adds a temporary item to the player, which will be deleted on the next floor
---@param player EntityPlayer
---@param item CollectibleType
---@return nil
function ARAOI.Spellbook.AddTemporaryItemToPlayer(player, item)
    local temporary_items = ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetID(player), {})

    player:AddCollectible(item)
    local history = player:GetHistory():GetCollectiblesHistory()
    table.insert(temporary_items, history[#history]:GetTime())

    ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetID(player), {}, temporary_items)
end

-- Removes the temporary items from the player
---@param player EntityPlayer
---@return nil
function ARAOI.Spellbook.RemoveTemporaryItemsFromPlayer(player)
    local temporary_items = ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetID(player), {})

    for _, item in ipairs(player:GetHistory():GetCollectiblesHistory()) do
        if ARAOI.TableUtils.IsValueInTable(item:GetTime(), temporary_items) then
            player:RemoveCollectible(item:GetItemID())
        end
    end

    ARAOI.SaveData:Data(ARAOI.SaveData.RUN, "SpellbookTemporaryItems", {}, ARAOI.PlayerUtils.GetID(player), {}, {})
end

-- Returns the known spells for use with EID
--
-- If `spell` and `item` are passed, adds them to the known spells
---@param spell string?
---@param item CollectibleType?
---@return table table -- `{{spell: str, item: CollectibleType}, ...}`
function ARAOI.Spellbook.EIDRegisteredSpells(spell, item)
    local data = ARAOI.SaveData:Key(ARAOI.SaveData.RUN, "SpellbookRegisteredSpells", {})
    if spell and item then
        for i, v in ipairs(data) do
            local stored_spell = v[1]
            if spell == stored_spell then
                table.remove(data, i)
            end
        end

        table.insert(data, {spell, item})

        if #data > 10 then
            table.remove(data, 1)
        end
    end

    ARAOI.SaveData:Key(ARAOI.SaveData.RUN, "SpellbookRegisteredSpells", {}, data)

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

---@param _ any
---@param entity Entity
---@param inputHook InputHook
---@param buttonAction ButtonAction
ARAOI.Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, inputHook, buttonAction)
    if not entity then return end

    local player = entity:ToPlayer()
    if not player then return end

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

        -- Check if the player is currently writing a spell
        if ARAOI.Spellbook.IsPlayerWritingSpell(player) then
            -- If we are writing a spell, we block the shooting input
            if inputHook == InputHook.GET_ACTION_VALUE then
                return 0
            else
                return false
            end
        end

    end
end)


--------------------
-- MISC FUNCTIONS --
--------------------

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
    for _, player in pairs(PlayerManager.GetPlayers()) do
        ARAOI.Spellbook.RemoveTemporaryItemsFromPlayer(player)
    end
end)


----------------------------
-- ITEM USE FUNCTIONALITY --
----------------------------

---@param player EntityPlayer
---@param slot ActiveSlot
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, useFlag, slot)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()

    -- This prevents us from entering the writing state from items such as Void
    -- If that were to happen, it would be a soft-lock
    if not player:HasCollectible(ARAOI.CollectibleType.SPELLBOOK) then return end

    -- Prevent the item from being used twice with car battery
    -- The second use casts the spell, but there is no time to write one
    -- so Car Battery makes the item useless
    if useFlag & UseFlag.USE_CARBATTERY > 0 then return end

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
        end

        -- If the item is a passive item or a familiar
        if config.Type == ItemType.ITEM_PASSIVE or config.Type == ItemType.ITEM_FAMILIAR then
            -- We add the item to the list of temporary items for them to get deleted later
            ARAOI.Spellbook.AddTemporaryItemToPlayer(player, spell_item)

        else -- If the item is not a passive item
            -- Use it as normal
            player:UseActiveItem(spell_item)

            -- If we have book of virtues, we artificially spawn wisps
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                -- Spawn a wisp
                player:AddWisp(spell_item, player.Position)
                SFX:Play(SoundEffect.SOUND_CANDLE_LIGHT)
            end
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
end, ARAOI.CollectibleType.SPELLBOOK)


------------------------------
-- BOOK AND ARROWS RENDERER --
------------------------------

ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
    -- If anyone is writing a spell, keep track of it
    local anyone_is_writing_spell = false

    -- Do a render pass for each player
    for _, player in ipairs(PlayerManager.GetPlayers()) do

        -- Get the written spell
        local spell = ARAOI.Spellbook.PlayerWrittenSpell(player)

        -- Check if the player is writing
        if ARAOI.Spellbook.IsPlayerWritingSpell(player) then
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
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, ARAOI.Spellbook.PlayerWrittenSpell(player).."1")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, ARAOI.Spellbook.PlayerWrittenSpell(player).."2")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, ARAOI.Spellbook.PlayerWrittenSpell(player).."3")
                    playInputSoundEffect()
                end
                if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) then
                    ARAOI.Spellbook.PlayerWrittenSpell(player, ARAOI.Spellbook.PlayerWrittenSpell(player).."4")
                    playInputSoundEffect()
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
        end

        -- For every character in the written spell
        for i = 1, #spell do
            -- Get the character
            local character = spell:sub(i,i)

            -- Get the player's position relative to the screen
            local position = Isaac.WorldToScreen(player.Position)

            -- Offset the arrows so they end up centered
            -- I honestly have no idea how I ended up with this formula, it was a lot of trial and error
            position.X = position.X - 6.3 - (string.len(spell)/2-i) * 14
            position.Y = position.Y - 51

            -- Get the arrow for that character and render it to the offset position
            arrows[tonumber(character)]:Render(position)
        end

        -- This is some left-over debug code which shows what the actual spell is
        -- local pos = Isaac.WorldToScreen(player.Position)
        -- Isaac.RenderText(spell, pos.X - string.len(spell) * 3, pos.Y - 50, 1, 1, 1, 1)
    end

    if anyone_is_writing_spell and Config.ENABLE_EID_HISTORY and EID and not EID.isHidden then
        local alpha = EID.Config["Transparency"]
        EID:renderString(
            "{{Collectible"..ARAOI.CollectibleType.SPELLBOOK.."}} Spellbook History",
            Vector(300, 35), Vector(1,1), KColor(175/255, 77/255, 168/255, alpha), false
        )
        local known_spells = ARAOI.Spellbook.EIDRegisteredSpells()
        if #known_spells > 0 then
            for i = 1,#known_spells do
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
end)


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
        "#{{Collectible"..(CollectibleType.COLLECTIBLE_RESTOCK).."}} Writing the same spell will use the same item"..
        "#{{TreasureRoom}} If the used item was a passive item, it will instead give it to Isaac for the rest of the floor"
    )

    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "Spellbook Book Of Virtues",
        ARAOI.CollectibleType.SPELLBOOK,
        "Casting an active item spell will also spawn its wisp"
    )
end)