----------------------------
-- START OF CONFIGURATION --
----------------------------


-- Setting these values above 12 will cause the EID description to bug out, however, the item will still work as expected.
local GLASS_DIE_CHARGE_EMPTY = 2 -- *Default: `2` — How many charges does it take to recharge an empty Glass Die.*
local GLASS_DIE_CHARGE_POOL  = 6 -- *Default: `6` — How many charges does it take to recharge a Glass Die with a copied item pool.*



--------------------------
-- END OF CONFIGURATION --
--------------------------


---@class Helper
local Helper = include("scripts.Helper")

---@class SaveDataManager
local SaveData = require("scripts.SaveDataManager")

local RENDERING_ENABLED = true

local glass_die = Isaac.GetItemIdByName("Glass Die")

local KEY_GLASS_DIE_RENDER_SPRITE = "GlassDieSpriteHUD"
local KEY_GLASS_DIE_LAST_SELECTION = "GlassDieLastSelection"

local PoolName = {
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


local modded_item = {}

---@param Mod ModReference
function modded_item:init(Mod)
    local game = Game()
    local sfx = SFXManager()



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

            print("Item Pool is "..offset_id.." ("..pool_id.."), aka: "..tostring(PoolName[offset_id]))

            -- Set the item's var data to the room's pool
            desc.VarData = offset_id


        -- The item has a pool stored
        else
            -- Check all room entities
            for _, entity in ipairs(Isaac.GetRoomEntities()) do

                -- Try to convert the entity into a pickup
                local pickup = entity:ToPickup()

                -- The entity was converted, the pickup is a collectible and it can be rerolled?
                if pickup and Helper.IsCollectible(pickup) and pickup:CanReroll() then

                    -- Get a list of collectibles from the stored pool
                    local collectibles = Helper.GetCollectibleCycle(desc.VarData - offset)

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
    end, glass_die)



    -------------------------
    -- SETTING THE CHARGES --
    -------------------------


    ---@param collectibleType CollectibleType
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function (_, collectibleType, player, _)
        if collectibleType ~= glass_die then return end

        local desc = player:GetActiveItemDesc(player:GetActiveItemSlot(glass_die))

        if desc.VarData == 0 then
            return GLASS_DIE_CHARGE_EMPTY
        else
            return GLASS_DIE_CHARGE_POOL
        end
    end)



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
        -- Getting the data also sets it, so we make sure we loaded it first
        if not RENDERING_ENABLED then return end

        -- Don't render if the item is not ours
        local collectible_id = player:GetActiveItem(slot)
        if collectible_id ~= glass_die then return end

        -- Get the currently selected pool
        local selected_pool = player:GetActiveItemDesc(slot).VarData

        -- The selected item is 0, which means we don't need to do anything
        if selected_pool == 0 then return end

        -- Get a reference to the data
        local data = player:GetData()

        -- Keeping track of the render and the selected item
        -- That way we don't have to reload the sprite every render
        local hud_boh = data[KEY_GLASS_DIE_RENDER_SPRITE]
        local last_boh_selection = data[KEY_GLASS_DIE_LAST_SELECTION]

        -- First time rendering so we create the sprite
        if hud_boh == nil then
            hud_boh = Sprite("gfx/ui/hud_glass_die.anm2", true)

            -- Make a reference to the sprite
            data[KEY_GLASS_DIE_RENDER_SPRITE] = hud_boh

            -- Set some stuff to the defaults because for some reason the game doesn't do that
            hud_boh:SetOverlayRenderPriority(true)
            hud_boh:SetAnimation(hud_boh:GetDefaultAnimationName())
            hud_boh:SetFrame(1)
        end

        -- Setting some render options to be the same as what the game wants
        hud_boh.Scale = Vector(scale, scale)
        hud_boh.Color.A = alpha

        -- New pool was selected
        if last_boh_selection ~= selected_pool then
            local pool_name = PoolName[selected_pool]
            if pool_name == nil then
                pool_name = "Modded"
            end

            -- Change the animation to the new pool
            hud_boh:Play(pool_name, true)

            -- Store the selection
            player:GetData()[KEY_GLASS_DIE_LAST_SELECTION] = selected_pool
        end

        -- Render the sprite to the screen
        hud_boh:Render(offset)
    end)

    ---@class EID
    if EID then
        EID:addCollectible(glass_die,
            "#{{Mirror}} Copies the current room's item pool on use"..
            "# If there is an item pool copied, it will reroll items into the copied pool and will empty the die"..
            "#{{Battery}} Charge depends on item state:"..
            "#{{Blank}} {{Battery}}{{"..GLASS_DIE_CHARGE_EMPTY.."}} charges empty"..
            "#{{Blank}} {{Battery}}{{"..GLASS_DIE_CHARGE_POOL.."}} charges with a pool"
        )
    end
end


return modded_item