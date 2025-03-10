
-----------------------------
-- MAIN ITEM FUNCTIONALITY --
-----------------------------

---@param collectible CollectibleType
---@param firstTime boolean
---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, collectible, _, firstTime, _, _, player)
    local ItemConfig = Isaac.GetItemConfig()
    local item = ItemConfig:GetCollectible(collectible)
    if item:HasTags(ItemTag.TAG_FOOD) and firstTime and player:HasCollectible(ARAOI.CollectibleType.LUNCHBOX) then
        if player:GetTrinket(0) ~= 0 then
            SFXManager():Play(SoundEffect.SOUND_VAMP_GULP)
        end
        player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, UseFlag.USE_NOANIM | UseFlag.USE_MIMIC)
    end
end)


---------------------
-- EID DESCRIPTION --
---------------------

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.LUNCHBOX,
        "#{{Collectible"..CollectibleType.COLLECTIBLE_SMELTER.."}} Picking up any food item will gulp your held trinkets"
    )
end)