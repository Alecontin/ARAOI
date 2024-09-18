-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------





---@class helper
local helper = include("scripts.helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")


---------------
-- CONSTANTS --
---------------

local GLASS_DIE = Isaac.GetItemIdByName("Glass Die")
local GLASS_DIE_SPRITE = Sprite("gfx/ui/hud_glass_die.anm2")

local POOL_ID_TO_NAME = {
    [0] = "Empty",
    [1] = "Treasure",
    [2] = "Shop",
    [3] = "Boss",
    [4] = "Devil",
    [5] = "Angel",
    [6] = "Secret",
    [7] = "Library",
    [9] = "GoldenChest",
    [13] = "Curse",
    [16] = "MomsChest",
    [17] = "Treasure",
    [18] = "Boss",
    [19] = "Shop",
    [20] = "Curse",
    [21] = "Devil",
    [22] = "Angel",
    [23] = "Secret",
    [25] = "UltraSecret",
    [27] = "Planetarium",
}


-------------------------
-- ITEM INITIALIZATION --
-------------------------

local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()


    --------------
    -- ITEM USE --
    --------------

    ---@param player EntityPlayer
    ---@param rng RNG
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player)
        local room = game:GetRoom()

        local desc = player:GetActiveItemDesc()
        local offset = 1

        -- Is the item empty?
        if desc.VarData == 0 then
            -- Get the room's pool and offset it
            local pool_id = room:GetItemPool(1)
            local offset_id = pool_id + offset

            -- Set the item's var data to the room's pool
            desc.VarData = offset_id


        -- The item has a pool stored
        else
            -- Check all room entities
            for _, entity in ipairs(Isaac.GetRoomEntities()) do

                -- Try to convert the entity into a pickup
                local pickup = entity:ToPickup()

                -- The entity was converted, the pickup is a collectible and it can be rerolled?
                if pickup and helper.item.IsCollectible(pickup) and pickup:CanReroll() then

                    -- Get a list of collectibles from the stored pool
                    local collectibles = helper.item.GetCollectibleCycle(desc.VarData - offset)

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
                    -- we would have 1 item from the selected pool and the rest, if we have items such as glitched croun, would
                    -- be from the room's item pool, which is not how I wanted the item to work
                end
            end

            desc.VarData = 0
        end

        -- Play the item animation
        return true
    end, GLASS_DIE)


    ---------------------------
    -- RENDERING OF THE ITEM --
    ---------------------------


    Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
        if not RENDERING_ENABLED then
            RENDERING_ENABLED = true
        end
    end)

    ---@param player EntityPlayer
    ---@param slot ActiveSlot
    ---@param offset Vector
    ---@param alpha number
    ---@param scale number
    Mod:AddCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_ACTIVE_ITEM, function (_, player, slot, offset, alpha, scale)-- Do not render if the game JUST started
        -- Don't render if the item is not ours
        local collectible_id = player:GetActiveItem(slot)
        if collectible_id ~= GLASS_DIE then return end

        -- Get the currently selected pool
        local selected_pool = player:GetActiveItemDesc(slot).VarData

        -- The selected item is 0, which means we don't need to do anything
        if selected_pool == 0 then return end

        -- Setting some render options to be the same as what the game wants
        GLASS_DIE_SPRITE.Scale = Vector(scale, scale)
        GLASS_DIE_SPRITE.Color.A = alpha

        -- Translate the pool id into the name
        local pool_name = POOL_ID_TO_NAME[selected_pool]

        -- If the id is not in the pool names
        if pool_name == nil then
            -- The pool must be modded, so we set the pool name to "Modded"
            pool_name = "Modded"
        end

        -- Change the animation to the new pool
        GLASS_DIE_SPRITE:Play(pool_name, true)

        -- Render the sprite to the screen
        GLASS_DIE_SPRITE:Render(offset)
    end)


    ----------------------
    -- ITEM DESCRIPTION --
    ----------------------

    ---@type EID
    if EID then
        EID:addCollectible(GLASS_DIE,
            "#{{Mirror}} Copies the current room's item pool on use"..
            "# If there is an item pool copied, it will reroll items into the copied pool and will empty the die"
        )
    end
end


return modded_item