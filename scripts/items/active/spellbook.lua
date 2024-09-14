----------------------------
-- START OF CONFIGURATION --
----------------------------




-- If we get these items, we roll again.
-- This can be because the game just crashes, or the item just doesn't work.
local RerollItems = {
    CollectibleType.COLLECTIBLE_DELIRIOUS
}

-- If you feel like an item should have a default spell that never changes, you can add it here
-- 1 = LEFT
-- 2 = UP
-- 3 = RIGHT
-- 4 = DOWN
local ManualSpellOverwrites = {
    -- ["22441313"] = CollectibleType.COLLECTIBLE_DEATH_CERTIFICATE
}



--------------------------
-- END OF CONFIGURATION --
--------------------------





---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local spellbook = Isaac.GetItemIdByName("Spellbook")

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

local book_hud_sprite = CreateBookSprite()

local arrows = {
    CreateArrowSprite(0),
    CreateArrowSprite(1),
    CreateArrowSprite(2),
    CreateArrowSprite(3)
}

local WritingSpellData = {}

---@param player EntityPlayer
---@param is_writing? boolean
local function IsWritingSpell(player, is_writing)
    return SaveData:Key(WritingSpellData, Helper.GetPlayerId(player), false, is_writing)
end

local WrittenSpells = {}

---@param player EntityPlayer
---@param spell? string
local function WrittenSpell(player, spell)
    return SaveData:Key(WrittenSpells, Helper.GetPlayerId(player), "", spell)
end

---@param player EntityPlayer
---@param item CollectibleType
local function AddTemporaryItem(player, item)
    local temporaryItems = SaveData:Data(SaveData.RUN, "SpellBookTemporaryItems", {}, Helper.GetPlayerId(player), {})

    player:AddCollectible(item)
    table.insert(temporaryItems, item)

    return SaveData:Data(SaveData.RUN, "SpellBookTemporaryItems", {}, Helper.GetPlayerId(player), {}, temporaryItems)
end

---@param player EntityPlayer
local function WipeTemporaryItems(player)
    local temporaryItems = SaveData:Data(SaveData.RUN, "SpellBookTemporaryItems", {}, Helper.GetPlayerId(player), {})

    for _, item in ipairs(temporaryItems) do
        player:RemoveCollectible(item)
    end

    SaveData:Data(SaveData.RUN, "SpellBookTemporaryItems", {}, Helper.GetPlayerId(player), {})
end



local modded_item = {}

local RENDERING_ENABLED = false

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local sfx = SFXManager()
    local ItemConfig = Isaac.GetItemConfig()

    -------------------
    -- INPUT BLOCKER --
    -------------------

    ---@param _ any
    ---@param entity Entity
    ---@param inputHook InputHook
    ---@param buttonAction ButtonAction
    Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, inputHook, buttonAction)
        if not entity then return end

        local player = entity:ToPlayer()
        if not player then return end

        -- Check if this input call is checking if the player wants to shoot
        if inputHook == InputHook.IS_ACTION_PRESSED
        and Helper.IsValueInTable(
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
            if IsWritingSpell(player) then
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

    ---@param slot ActiveSlot
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MIN_USABLE_CHARGE, function (_, slot, player)
        -- Get the collectible from the checked slot
        local collectible = player:GetActiveItem(slot)

        -- If we are checking the charges for our item and we are writing a spell
        if collectible == spellbook and IsWritingSpell(player) then
            -- Make the item's min charges be 0 which essentially means it's a free use
            -- Do note that the item still gets discharged as normal. This just allows us to mark it as "usable"
            return 0
        end
    end)

    Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function ()
        for _, player in pairs(PlayerManager.GetPlayers()) do
            WipeTemporaryItems(player)
        end
    end)



    ----------------------------
    -- ITEM USE FUNCTIONALITY --
    ----------------------------

    ---@param player EntityPlayer
    ---@param slot ActiveSlot
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, useFlag, slot)
        -- This prevents us from entering the writing state from items such as Void
        -- If that were to happed, it would be a soft-lock
        if not player:HasCollectible(spellbook) then return end

        -- Prevent the item from being used twice with car battery
        -- The second use casts the spell, but there is no time to write one
        -- so Car Battery makes the item useless
        if useFlag & UseFlag.USE_CARBATTERY > 0 then return end

        -- Toggle the player's writing ability, which locks and unlocks shooting
        local writing = IsWritingSpell(player, not IsWritingSpell(player))

        -- Check what spell we've written, this is used on the item's second use, after something was written
        local spell = WrittenSpell(player)

        -- Function that adds a free charge to the item
        -- Used when casting a spell, since otherwise it would drain the remaining charges, making
        -- items such as The Battery completely useless
        local function recharge()
            local charges = player:GetActiveCharge(slot) + player:GetActiveMaxCharge(slot)
            player:SetActiveCharge(charges)
        end

        -- We just stopped writing and there's something written
        if writing == false and spell ~= "" then
            -- Get the RNG based on what's written and the current seed
            local rng = RNG(tonumber(spell) + game:GetSeeds():GetStartSeed())

            -- Setting some default values so we can keep rerolling the items until an item
            -- which can be used is selected, basically skiping over the items defined
            -- on the RerollItems list
            local spell_item = nil
            local config = nil

            -- While we don't have an item selected, the item selected is in the RerollItems list or the config doesn't exist
            while spell_item == nil
            or Helper.IsValueInTable(spell_item, RerollItems)
            or config == nil
            do
                -- Get a random item and it's configuration, then check again
                -- The line below is here because my code editor screams at me otherwise
                ---@diagnostic disable-next-line: undefined-field
                spell_item = ManualSpellOverwrites[spell] or rng:RandomInt(ItemConfig:GetCollectibles().Size - 1)
                config = ItemConfig:GetCollectible(spell_item)
            end

            -- If the item is a passive item or a familiar
            if config.Type == ItemType.ITEM_PASSIVE or config.Type == ItemType.ITEM_FAMILIAR then
                -- We add the item to the list of temporary items for them to get deleted later
                AddTemporaryItem(player, spell_item)

            else -- If the item is not a passive item
                -- Use it as normal
                player:UseActiveItem(spell_item, UseFlag.USE_CUSTOMVARDATA, nil, 1)

                -- If we have book of virtues, we artificially spawn wisps
                if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                    -- Spawn a wisp
                    player:AddWisp(spell_item, player.Position)
                    sfx:Play(SoundEffect.SOUND_CANDLE_LIGHT)
                end
            end

            -- Show the player what item was used by the spell and play a sound
            game:GetHUD():ShowItemText(player, config)
            player:AnimateCollectible(spell_item)
            sfx:Play(SoundEffect.SOUND_POWERUP1, 0.3, nil, nil, 2)

            -- Clear the spell
            WrittenSpell(player, "")


        -- We just stopped writing but there was no spell written
        elseif writing == false and spell == "" then
            -- Play an error sound and recharge the item
            SFXManager():Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
            recharge()


        -- We used the item to start writing a spell, show the item's use animation and play a sound
        else
            sfx:Play(SoundEffect.SOUND_MENU_RIP, 3)
            return true

        end
    end, spellbook)



    ------------------------------
    -- BOOK AND ARROWS RENDERER --
    ------------------------------

    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
        if not RENDERING_ENABLED then
            RENDERING_ENABLED = true
        end
    end)

    Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
        -- Getting the data also sets it, so we make sure we loaded it first
        if not RENDERING_ENABLED then return end

        -- Do a render pass for each player
        for _, player in ipairs(PlayerManager.GetPlayers()) do

            -- Get the written spell
            local spell = WrittenSpell(player)

            -- Check if the player is writing
            if IsWritingSpell(player) then

                -- If we are writing and we don't have the book, that means
                -- it's either a soft-lock or we put the book down while writing
                -- So, we set everything to the default values
                if not player:HasCollectible(spellbook) then
                    IsWritingSpell(player, false)
                    WrittenSpell(player, "")
                end

                -- Get the player's position relative to the screen
                local pos = Isaac.WorldToScreen(player.Position)

                -- Offset the position so the book get's rendered on top of the player
                pos.Y = pos.Y - 50

                -- Render the book at the offset position
                book_hud_sprite:Render(pos)

                -- Defining a function to not have to copy-paste this 4 times
                local function playInputSoundEffect()
                    sfx:Play(SoundEffect.SOUND_POT_BREAK_2, 0.3, nil, nil, 3)
                end

                -- If the spell is less than 10 characters long, we can write to it
                -- This is an arbitrary value good enough to generate a spell for every item
                -- in the game while not going over the integer limit
                if #spell < 10 then
                    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
                        WrittenSpell(player, WrittenSpell(player).."1")
                        playInputSoundEffect()
                    end
                    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) then
                        WrittenSpell(player, WrittenSpell(player).."2")
                        playInputSoundEffect()
                    end
                    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
                        WrittenSpell(player, WrittenSpell(player).."3")
                        playInputSoundEffect()
                    end
                    if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) then
                        WrittenSpell(player, WrittenSpell(player).."4")
                        playInputSoundEffect()
                    end
                end
            end

            -- For every character in the written spell
            for i = 1, #spell do
                -- Get the character
                local char = spell:sub(i,i)

                -- Get the player's position relative to the screen
                local pos = Isaac.WorldToScreen(player.Position)

                -- Offset the arrows so they end up centered
                -- I honestly have no idea how I ended up with this formula, it was a lot of trial and error
                pos.X = pos.X - 5 - (string.len(spell)/2-i) * 10
                pos.Y = pos.Y - 50

                -- Get the arrow for that character and render it to the offset position
                arrows[tonumber(char)]:Render(pos)
            end

            -- This is some left-over debug code which shows what the actual spell is
            -- local pos = Isaac.WorldToScreen(player.Position)
            -- Isaac.RenderText(spell, pos.X - string.len(spell) * 3, pos.Y - 50, 1, 1, 1, 1)
        end
    end)

    ---@class EID
    if EID then
        EID:addCollectible(spellbook,
            "#{{Collectible"..spellbook.."}} On use, spawns an open Spellbook above Isaac "..
            "#{{Tearsize}} Shooting in any direction will write to the Spellbook"..
            "#{{Collectible}} Casting the spell will mimic the use of a random item"..
            "#{{Collectible"..(CollectibleType.COLLECTIBLE_RESTOCK).."}} Writing the same spell will use the same item"..
            "#{{TreasureRoom}} If the used item was a passive item, it will instead give it to Isaac for the rest of the floor"
        )
    end
end

return modded_item