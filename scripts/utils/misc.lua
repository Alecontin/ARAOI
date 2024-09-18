
---@class MiscUtils
local MiscUtils = {}

local game = Game()

---@param H any -- *Number between 0 and 360*
---@param S? any -- *Default: `1` — Number between 0 and 1*
---@param L? any -- *Default: `0.5` — Number between 0 and 1*
function MiscUtils.HSLtoRGB(H, S, L)
    H = H % 360
    S = S or 1
    L = L or 0.5

    -- C = (1 - |2L - 1|) × S
    local C = (1 - math.abs(2 * L - 1)) * S

    -- X = C × (1 - |(H / 60°) mod 2 - 1|)
    local X = C * (1 - math.abs((H / 60) % 2 - 1))

    -- m = L - C/2
    local m = L - C / 2

    local Rp, Gp, Bp

    if H >= 0 and H < 60 then
        Rp, Gp, Bp = C, X, 0
    elseif H >= 60 and H < 120 then
        Rp, Gp, Bp = X, C, 0
    elseif H >= 120 and H < 180 then
        Rp, Gp, Bp = 0, C, X
    elseif H >= 180 and H < 240 then
        Rp, Gp, Bp = 0, X, C
    elseif H >= 240 and H < 300 then
        Rp, Gp, Bp = X, 0, C
    elseif H >= 300 and H < 360 then
        Rp, Gp, Bp = C, 0, X
    else
        Rp, Gp, Bp = 0, 0, 0
    end

    return (Rp + m) * 255, (Gp + m) * 255, (Bp + m) * 255
end

function MiscUtils.Lerp(A, B, t)
    return A + (B - A) * t
end

-- This function was directly copied from [The Official API](https://wofsauge.github.io/IsaacDocs/rep/Room.html#getdevilroomchance),
-- I changed the anyPlayerHasCollectible and anyPlayerHasTrinket functions with the Repentagon functions
---@return number[] -- List where the first item is the devil chance and the second the angel chance
function MiscUtils.getDevilAngelRoomChance()
    local level = game:GetLevel()
    local room = level:GetCurrentRoom()
    local totalChance = math.min(room:GetDevilRoomChance(), 1.0)

    local angelRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_FAMINE_SPAWNED) -- repurposed
    local devilRoomSpawned = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_SPAWNED)
    local devilRoomVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED)

    local devilRoomChance = 1.0
    if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_EUCHARIST) then
        devilRoomChance = 0.0
    elseif devilRoomSpawned and devilRoomVisited and game:GetDevilRoomDeals() > 0 then -- devil deals locked in
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or
        PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION) or
            level:GetAngelRoomChance() > 0.0 -- confessional, sac room
        then
            devilRoomChance = 0.5
        end
    elseif devilRoomSpawned or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or level:GetAngelRoomChance() > 0.0 then
        if not (devilRoomVisited or angelRoomSpawned) then
            devilRoomChance = 0.0
        else
            devilRoomChance = 0.5
        end
    end

    -- https://bindingofisaacrebirth.fandom.com/wiki/Angel_Room#Angel_Room_Generation_Chance
    if devilRoomChance == 0.5 then
        if PlayerManager.AnyoneHasTrinket(TrinketType.TRINKET_ROSARY_BEAD) then
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if game:GetDonationModAngel() >= 10 then -- donate 10 coins
            devilRoomChance = devilRoomChance * (1.0 - 0.5)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 - 0.1)
        end
        if level:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) and not level:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT) then
            devilRoomChance = devilRoomChance * (1.0 + 0.1)
        end
        if level:GetAngelRoomChance() > 0.0 or
            (level:GetAngelRoomChance() < 0.0 and (PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) or PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION)))
        then
            devilRoomChance = devilRoomChance * (1.0 - level:GetAngelRoomChance())
        end
        if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            devilRoomChance = devilRoomChance * (1.0 - 0.25)
        end
        devilRoomChance = math.max(0.0, math.min(devilRoomChance, 1.0))
    end

    local angelRoomChance = 1.0 - devilRoomChance
    if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_DUALITY) then
        angelRoomChance = devilRoomChance
    end
    return {totalChance * devilRoomChance, totalChance * angelRoomChance}
end

return MiscUtils