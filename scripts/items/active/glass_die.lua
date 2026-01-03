-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Glass_Die = {}

local GLASS_DIE_SPRITE = Sprite("gfx/ui/hud_glass_die.anm2", true)
GLASS_DIE_SPRITE:SetAnimation(GLASS_DIE_SPRITE:GetDefaultAnimation())

local game = Game()

-- Variable containing sprite data for modded pools: [PoolID] = {ANM2, Frame, Offset, Scale}
local Modded_Sprite_Data = {}

---------------
-- FUNCTIONS --
---------------

---@param sprite Sprite
---@param pool_id ItemPoolType
---@param sprite_frame integer
---@param sprite_offset? Vector
---@param sprite_scale? integer
---@param do_initial_setup? boolean -- Default: `true` — Sets some initial sprite variables just in case. Set this to `false` if it's giving errors
function ARAOI.Glass_Die.RegisterPoolSprite(sprite, pool_id, sprite_frame, sprite_offset, sprite_scale, do_initial_setup)
    if Modded_Sprite_Data[pool_id] ~= nil then
        Isaac.ConsoleOutput("ARAOI - The pool \""..pool_id.."\" is already registered. This might cause problems.")
    end
    if do_initial_setup ~= false then
        sprite:LoadGraphics()
        sprite:SetAnimation(sprite:GetDefaultAnimation())
    end
    Modded_Sprite_Data[pool_id] = {
        sprite,
        sprite_frame,
        sprite_offset or Vector.Zero,
        sprite_scale or 1,
    }
end

---------------
-- ON PICKUP --
---------------

---@param firstTime boolean
---@param slot ActiveSlot
---@param player EntityPlayer
function ARAOI:_OnGlassDieAddCollectible(_, _, firstTime, slot, _, player)
    if firstTime then
        player:GetActiveItemDesc(slot).VarData = -1 -- game:GetRoom():GetItemPool(1)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, ARAOI._OnGlassDieAddCollectible, ARAOI.CollectibleType.GLASS_DIE)


--------------
-- ITEM USE --
--------------

---@param player EntityPlayer
function ARAOI:_OnGlassDieUse(_, _, player, useFlag, slot)
    if useFlag & UseFlag.USE_CARBATTERY > 0 then return end

    -- Getting our item's ItemDesc
    local desc = player:GetActiveItemDesc(slot)

    -- Getting the current room
    local room = game:GetRoom()

    -- Is the item empty?
    if desc.VarData == -1 then
        -- Set the item's var data to the room's pool
        desc.VarData = ARAOI.RoomUtils.GetItemPool()


    -- The item has a pool stored
    else
        -- Check all room entities
        for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do

            -- Try to convert the entity into a pickup
            local pickup = entity:ToPickup()

            -- The entity was converted, the pickup is a collectible and it can be rerolled?
            if pickup and ARAOI.ItemUtils.IsCollectible(pickup) and pickup:CanReroll() then

                -- Get a list of collectibles from the stored pool
                local collectibles = ARAOI.ItemUtils.GetCollectibleCycle(desc.VarData, player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) and 2 or 1)

                -- For every item in the list
                for i, collectible in ipairs(collectibles) do
                    -- If it's the first item
                    if i == 1 then
                        -- We morph the pickup, this makes it have only the first item
                        pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectible, true, false, true)
                    else
                        -- Else, we add the item to the cycle
                        pickup:AddCollectibleCycle(collectible)
                    end
                end

                -- The above workaround was made because if we were to just morph the item with ignoremodifiers set to false
                -- we would have 1 item from the selected pool and the rest, if we have items such as glitched crown, would
                -- be from the room's item pool, which is not how I wanted the item to work
            end
        end

        -- Reset the VarData
        desc.VarData = -1
    end

    -- Play some sounds
    ---@diagnostic disable-next-line: param-type-mismatch
    SFXManager():Play(910, 0.6, nil, nil, 1.3) -- D6
    SFXManager():Play(SoundEffect.SOUND_GLASS_BREAK, 0.6, nil, nil, 2)

    -- Play the item animation
    return true
end
ARAOI:AddCallback(ModCallbacks.MC_USE_ITEM, ARAOI._OnGlassDieUse, ARAOI.CollectibleType.GLASS_DIE)


---------------------------
-- RENDERING OF THE ITEM --
---------------------------

---@param player EntityPlayer
---@param slot ActiveSlot
---@param offset Vector
---@param alpha number
---@param scale number
function ARAOI:_OnGlassDiePreRenderActiveItem(player, slot, offset, alpha, scale)-- Do not render if the game JUST started
    -- Don't render if the item is not ours
    local collectible_id = player:GetActiveItem(slot)
    if collectible_id ~= ARAOI.CollectibleType.GLASS_DIE then return end

    -- Get the currently selected pool
    local selected_pool = player:GetActiveItemDesc(slot).VarData

    -- The selected pool is -1, which means we don't need to do anything
    -- We do, however, hide the outline because it's quite ugly
    if selected_pool == -1 then return {["HideOutline"] = true} end

    -- Setting some render options to be the same as what the game wants
    GLASS_DIE_SPRITE.Scale = Vector(scale, scale)
    GLASS_DIE_SPRITE.Color.A = alpha

    -- Check if the selected pool is a registered modded one
    if ARAOI.TableUtils.IsValueInTable(selected_pool, ARAOI.TableUtils.Keys(Modded_Sprite_Data)) then
        -- Set the glass die frame to an empty one (which is a pool that you can not encounter in a room)
        GLASS_DIE_SPRITE:SetFrame(7)

        -- Get the modded sprite's data
        local data = Modded_Sprite_Data[selected_pool]

        -- Getting the modded sprite
        ---@type Sprite
        local modded_sprite = data[1]

        -- Setting the frame to the provided one
        modded_sprite:SetFrame(data[2])

        -- Setting some render options to be the same as what the game wants
        modded_sprite.Scale = Vector(scale, scale) * data[4]
        modded_sprite.Color.A = alpha

        -- Rendering it to the screen
        modded_sprite:Render(offset + (Vector(16, 16) + data[3]) * scale)
    else
        -- Set the frame to the pool frame
        GLASS_DIE_SPRITE:SetFrame(selected_pool)
    end

    -- Render the sprite to the screen
    GLASS_DIE_SPRITE:Render(offset)

    -- Hide the default sprite
    return {["HideItem"] = true, ["HideOutline"] = true}
end
ARAOI:AddCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_ACTIVE_ITEM, ARAOI._OnGlassDiePreRenderActiveItem)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.GLASS_DIE,
        "#{{Mirror}} Copies the current room's item pool on use"..
        "# If there is an item pool copied, it will reroll items into the copied pool and will empty the die"
    )
    ARAOI.EIDUtils.CarBatterySynergy(
        "Glass Die Car Battery Synergy",
        ARAOI.CollectibleType.GLASS_DIE,
        "Adds an extra item to the pedestals item cycle"
    )
end)