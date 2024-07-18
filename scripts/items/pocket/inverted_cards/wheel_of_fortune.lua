local wheel_of_fortune = Isaac.GetCardIdByName("Inverted Wheel of Fortune")
local reverse = Card.CARD_REVERSE_WHEEL_OF_FORTUNE

local card_config = include("scripts.items.pocket.inverted_cards")

---@class Helper
local Helper = include("scripts.Helper")

local card = {}

---@param Mod ModReference
function card:init(Mod)
    local game = Game()
    local ItemConfig = Isaac.GetItemConfig()
    local HUD = game:GetHUD()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local ItemPool = game:GetItemPool()

        local rng = player:GetCardRNG(wheel_of_fortune)

        local use_card = ItemPool:GetCard(rng:RandomInt(1, 99999999), false, false, false)

        local config = ItemConfig:GetCard(use_card)
        player:UseCard(use_card, UseFlag.USE_NOANNOUNCER)

        local name = Helper.Split(config.Name, "_")
        name[1] = string.sub(name[1], 2)
        table.remove(name, #name)
        name = Helper.Join(name, " ")

        HUD:ShowItemText(name)

        if rng:RandomFloat() > 0.1 then
            player:AddCard(wheel_of_fortune)
        end
    end, wheel_of_fortune)

    ---@param rng RNG
    ---@param currentCard Card
    Mod:AddCallback(ModCallbacks.MC_GET_CARD, function (_, rng, currentCard)
        if currentCard == reverse and rng:RandomFloat() <= card_config.ReplaceChance then
            return wheel_of_fortune
        end
    end)

    ---@class EID
    if EID then
        EID:addCard(wheel_of_fortune,
            "#{{Card}} Mimics a random card on use"..
            "# Has a 10% chance to destroy itself with each use"
        )
    end
end

return card