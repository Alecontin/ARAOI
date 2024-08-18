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
    [13] = "Curse",
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


    ---@param player EntityPlayer
    ---@param rng RNG
    Mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, rng, player)
        local room = game:GetRoom()

        local desc = player:GetActiveItemDesc()
        local offset = 1

        if desc.VarData == 0 then
            local pool_id = room:GetItemPool(1)
            local offset_id = pool_id + offset
            desc.VarData = offset_id
        else
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                local pickup = entity:ToPickup()
                if pickup and Helper.IsCollectible(pickup) and pickup:CanReroll() then

                    local collectibles = Helper.GetCollectibleCycle(desc.VarData - offset)
                    for i, collectible in ipairs(collectibles) do
                        if i == 1 then
                            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectible, true, false, true)
                        else
                            pickup:AddCollectibleCycle(collectible)
                        end
                    end
                end
            end
            desc.VarData = 0
        end
        return true
    end, glass_die)



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
        local selected_pool = player:GetActiveItemDesc().VarData

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
            hud_boh:Play(PoolName[selected_pool], true)

            -- Store the selection
            player:GetData()[KEY_GLASS_DIE_LAST_SELECTION] = selected_pool
        end

        -- Render the sprite to the screen
        hud_boh:Render(offset)
    end)

    ---@class EID
    if EID then
        local d6 = CollectibleType.COLLECTIBLE_D6

        EID:addCollectible(glass_die,
            "#{{MirrorRoom}} Copies the current room's item pool on use"..
            "# If there is an item pool copied, it will reroll items into the copied pool and will empty the die"
        )
    end
end


return modded_item