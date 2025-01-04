-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------



------------------------
-- CONSTANTS AND INIT --
------------------------

local game = Game()
local ItemConfig = Isaac.GetItemConfig()

local collectible = Sprite("gfx/005.100_collectible.anm2", true)
collectible:SetAnimation("ShopIdle")
collectible:SetFrame(1)


-----------------------------
-- VARIABLES AND FUNCTIONS --
-----------------------------

local players_recycling = {}

---@param player EntityPlayer
local function IsRecycling(player)
    local player_id = ARAOI.PlayerUtils.GetID(player)
    return players_recycling[player_id] or false
end

---@param player EntityPlayer
local function ToggleRecycling(player)
    local player_id = ARAOI.PlayerUtils.GetID(player)
    players_recycling[player_id] = not IsRecycling(player)
end

local currently_selected_item = {}

---@param player EntityPlayer
---@param set? integer
local function CurrentSelection(player, set)
    local player_id = ARAOI.PlayerUtils.GetID(player)
    return ARAOI.SaveData:Key(currently_selected_item, player_id, 1, set)
end

---@param player EntityPlayer
---@param offset? integer
local function GetSelectedItemConfig(player, offset)
    local players_items = ARAOI.TableUtils.Keys(ARAOI.PlayerUtils.GetCollectibleListCurated(player, {ItemType.ITEM_TRINKET}, ItemTag.TAG_QUEST))
    return ItemConfig:GetCollectible(players_items[((CurrentSelection(player) + offset) % #players_items) + 1])
end


-----------------
-- ON ITEM USE --
-----------------

---@param rng RNG
---@param player EntityPlayer
---@param useFlags UseFlag
---@param slot ActiveSlot
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player, useFlags, slot)
    -- Car battery would mess things up!
    if useFlags & UseFlag.USE_CARBATTERY > 0 then return end

    -- This prevents us from entering the writing state from items such as Void
    -- If that were to happen, it would be a soft-lock
    if not player:HasCollectible(ARAOI.CollectibleType.RECYCLE) then return end

    -- If the player is not recycling
    if not IsRecycling(player) then
        -- The player is recycling now
        ToggleRecycling(player)

        -- Freeze the charges so the item can be used again
        ARAOI.PlayerUtils.FreezeActiveCharge(player, slot)

        -- Play the item's animation
        return true

    -- If the player is recycling
    else
        -- The player is no longer recycling
        ToggleRecycling(player)

        -- Get the selected collectible id
        local selected_collectible = GetSelectedItemConfig(player, 0).ID

        -- Remove the collectible from the player's inventory
        player:RemoveCollectible(selected_collectible)

        -- If the player tried to get rid of the item itself
        if selected_collectible == ARAOI.CollectibleType.RECYCLE then
            -- Get sad and stop execution :(
            return player:AnimateSad()
        end

        -- The player recycled! Yay!
        player:AnimateHappy()

        -- Did we hit the 1 in 5 chance?
        if rng:RandomInt(5) == 1 then
            -- Spawn an item
            Isaac.Spawn(5, 100, game:GetRoom():GetSeededCollectible(rng:Next()), game:GetRoom():FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)

        -- We didn't get lucky, act normally
        else
            -- Spawning 1 of every pickup!
            for _, pickup in ipairs({PickupVariant.PICKUP_BOMB, PickupVariant.PICKUP_KEY, PickupVariant.PICKUP_COIN}) do
                Isaac.Spawn(5, pickup, 0, player.Position, EntityPickup.GetRandomPickupVelocity(player.Position, rng) / 2, player)
            end
        end

        -- Book of Virtues
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            -- Spawn an item wisp of the removed collectible
            player:AddItemWisp(selected_collectible, player.Position)
        end

        -- Car battery
        if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then
            Isaac.Spawn(5, ARAOI.TableUtils.Choice({PickupVariant.PICKUP_BOMB, PickupVariant.PICKUP_KEY, PickupVariant.PICKUP_COIN}),
            0, player.Position, EntityPickup.GetRandomPickupVelocity(player.Position, rng) / 2, player)
        end
    end
end, ARAOI.CollectibleType.RECYCLE)


--------------------------------
-- RENDERING OF THE SELECTION --
--------------------------------

-- Using ModCallbacks.MC_POST_PLAYER_RENDER so that this gets hidden on splash screens
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function ()
    -- For every player
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        -- Check if the player is recycling
        if IsRecycling(player) then
            -- We somehow don't have our item
            if not player:HasCollectible(ARAOI.CollectibleType.RECYCLE) then
                -- Fix the mistake
                ToggleRecycling(player)
                -- Skip this player
                goto next_player
            end

            -- Function to avoid copy-pasting!
            local function RenderSelectedItem(offset)
                -- Getting the selected item
                local item_image = GetSelectedItemConfig(player, offset).GfxFileName

                -- Replacing the spritesheet of the collectible sprite
                collectible:ReplaceSpritesheet(1, item_image, true)

                -- Declaring the position at which to render the sprite later
                local x = player.Position.X + 25 * (offset * 0.9)
                local y = player.Position.Y - 50

                -- Declaring the scale and alpha values
                local scale = 1 - math.abs(offset)/5
                local alpha = 1 - math.abs(offset)/4

                -- Setting the scale and alpha
                collectible.Scale = Vector(scale, scale)
                collectible.Color.A = alpha

                -- Finally rendering the item
                collectible:Render(Isaac.WorldToScreen(Vector(x, y)))
            end

            -- This renders the items for offsets -2, 2, -1, 1
            for i = 3, 1, -1 do
                RenderSelectedItem(-i)
                RenderSelectedItem(i)
            end
            -- And then this for offset 0, this way the item in the middle always appears on top
            RenderSelectedItem(0)

            -- If we just shot right on this render frame
            if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
                -- Shift the current selection to the right
                CurrentSelection(player, CurrentSelection(player) + 1)
            end
            -- If we just shot left on this render frame
            if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
                -- Shift the current selection to the left
                CurrentSelection(player, CurrentSelection(player) - 1)
            end
            -- If we just switched items
            if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then
                -- Cancel the interaction
                ToggleRecycling(player)
            end
        end
        ::next_player::
    end
end)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(
        ARAOI.CollectibleType.RECYCLE,
        "#{{GrabBag}} Turns a selected collectible into random {{Bomb}}{{Key}}{{Coin}} pickups"..
        "#{{Luck}} 1 in 5 chance of spawning a collectible instead"..
        "#{{Collectible"..ARAOI.CollectibleType.RECYCLE.."}} Recycling this item will yield no rewards !!!"
    )
    ARAOI.EIDUtils.BookOfVirtuesSynergy(
        "Recycle Book of Virtues synergy",
        ARAOI.CollectibleType.RECYCLE,
        "Spawns a {{Collectible"..CollectibleType.COLLECTIBLE_LEMEGETON.."}} Lemegeton Wisp of the removed item"
    )
    ARAOI.EIDUtils.AbyssSynergy(
        "Recycle Abyss Synergy",
        ARAOI.CollectibleType.RECYCLE,
        "Green locust that poisons enemies"
    )
end)