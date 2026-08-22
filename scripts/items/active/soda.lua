-----------------------------
-- NO CONFIG FOR THIS ITEM --
-----------------------------


------------------------
-- CONSTANTS AND INIT --
------------------------

ARAOI.Soda = {}

local SFX = SFXManager()

local DamageMultiplayerCache = {}


---------------
-- FUNCTIONS --
---------------

---@param player EntityPlayer
---@param set? number
local function DamageMultiplier(player, set)
    if set then
        DamageMultiplayerCache[ARAOI.PlayerUtils.GetId(player)] = set
    end
    return DamageMultiplayerCache[ARAOI.PlayerUtils.GetId(player)] or 1
end


------------------------
-- ITEM FUNCTIONALITY --
------------------------

-- Updates the player's stats
---@param player EntityPlayer
---@param flag CacheFlag
function ARAOI:_OnSodaEvaluateCache(player, flag)
    if not player:HasCollectible(ARAOI.CollectibleType.SODA) then return end

    if (flag == CacheFlag.CACHE_SPEED) and (player.MoveSpeed >= 2) then
        DamageMultiplier(player, player.MoveSpeed - 1)
        player.MoveSpeed = ARAOI.Soda.GetSpeed(player) or player.MoveSpeed
    end

    if (flag == CacheFlag.CACHE_DAMAGE) and (player.MoveSpeed >= 2) then
        player.Damage = player.Damage * DamageMultiplier(player)
    end
end
ARAOI:AddPriorityCallback(ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.LATE, ARAOI._OnSodaEvaluateCache)

ARAOI.EIDWrapper(function ()
    EID:addCollectible(ARAOI.CollectibleType.SODA, "#{{ArrowUp}} Converts speed past the cap into damage multiplier")
end)

