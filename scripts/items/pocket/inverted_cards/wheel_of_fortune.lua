---@class Helper
local Helper = include("scripts.Helper")

local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Wheel of Fortune")
card.Replace = Card.CARD_REVERSE_WHEEL_OF_FORTUNE

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()
    local HUD = game:GetHUD()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local ItemPool = game:GetItemPool()

        local rng = player:GetCardRNG(card.ID)

        local use_card = ItemPool:GetCard(rng:RandomInt(1, 99999999), false, false, false)

        local config = ItemConfig:GetCard(use_card)
        player:UseCard(use_card, UseFlag.USE_NOANNOUNCER)

        local name = Helper.Split(config.Name, "_")
        name[1] = string.sub(name[1], 2)
        table.remove(name, #name)
        name = Helper.Join(name, " ")

        HUD:ShowItemText(name)

        if rng:RandomFloat() > 0.1 then
            player:AddCard(card.ID)
        end
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{Card}} Mimics a random card on use"..
            "# Has a 10% chance to destroy itself with each use"
        )
    end
end

return card