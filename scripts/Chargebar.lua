--[[

    It seems like the game doesn't have an built-in chargebar function so I made my own
    I know it's a bit messy but it's the only thing I could come up with

--]]


---@class Chargebar
local chargebar = {}
chargebar.__index = chargebar

-- Always render this using `ModCallbacks.MC_POST_PLAYER_RENDER`
---@param offset Vector
function chargebar:Render(offset)
    local player = self.ActivePlayer or Isaac.GetPlayer()

    local animation = self.Sprite:GetAnimation()
    local frame = self.Sprite:GetFrame()

    if animation == "Charging" then
        self.Sprite:SetFrame(math.floor(self.Charge))
        if self.Charge >= 100 then
            self.Sprite:Play("StartCharged")
        elseif self.Charge == 0 then
            self.Sprite:Play("Disappear")
        end

    elseif animation == "StartCharged" and frame == 11 then
        self.Sprite:Play("Charged")

    elseif animation == "Charged" and frame == 5 then
        self.Sprite:SetFrame(0)

    elseif animation == "Disappear" then
        if self.Charge > 0 then
            self.Sprite:Play("Charging")
        end

    end
    self.Sprite:Render(Isaac.WorldToScreen(player.Position + offset))
end

-- Always update this using `ModCallbacks.MC_POST_UPDATE`
---@param charge? integer
function chargebar:Update(charge)
    self.Charge = charge or self.Charge
    if (self.Charge > 0 and self.Charge < 100) or ((self.LastCharge ~= self.Charge) and self.Charge < 100) then
        self.Sprite:Play("Charging")
    end
    self.LastCharge = self.Charge
    self.Sprite:SetFrame(self.Sprite:GetFrame() + 1)
end

-- Get the chargebar of the provided player
---@param player EntityPlayer
---@return Chargebar
function chargebar:GetPlayerChargebar(player)
    local data = player:GetData()
    if data[self.ID] == nil then
        local new = chargebar:Create(self.ID)
        new:SetActivePlayer(player)
        data[self.ID] = new
    end

    return data[self.ID]
end

-- Change the chargebars player
---@param player EntityPlayer
function chargebar:SetActivePlayer(player)
    self.ActivePlayer = player
end

-- Function used to change the chargebars sprite to a custom one
---@param PNG_path string -- Path relative to the resources directory
function chargebar:SetCustomSpritesheet(PNG_path)
    self.Sprite:ReplaceSpritesheet(0, PNG_path)
    self.Sprite:LoadGraphics()
end

-- Create a chargebar instance
function chargebar:Create(id)
    ---@class Chargebar
    local instance = setmetatable({}, chargebar)
    instance.ID = id

    instance.ActivePlayer = nil

    instance.Charge = 0
    instance.LastCharge = 0

    instance.Sprite = Sprite()
    instance.Sprite:Load("gfx/chargebar.anm2", true)
    instance.Sprite:SetAnimation("Disappear")
    instance.Sprite:SetFrame(30)

    return instance
end

return chargebar
