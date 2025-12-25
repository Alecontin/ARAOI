
--------------------------------
-- MAIN TRINKET FUNCTIONALITY --
--------------------------------

function ARAOI:_OnBountifulSackNewRoom()
    -- Getting the room we just entered
    local room = Game():GetRoom()

    -- If anyone has our trinket, the room we just entered is already clear, and it's the first time we visited it
    if PlayerManager.AnyoneHasTrinket(ARAOI.TrinketType.BOUNTIFUL_SACK) and room:IsClear() and room:IsFirstVisit() then
        -- Try to spawn a clear award
        room:SpawnClearAward()
    end
end
ARAOI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ARAOI._OnBountifulSackNewRoom)


----------------------
-- ITEM DESCRIPTION --
----------------------

ARAOI.EIDWrapper(function ()
    EID:addTrinket(
        ARAOI.TrinketType.BOUNTIFUL_SACK,
        "#{{GrabBag}} Rooms with no enemies in them also spawn room clear rewards"
    )
end)