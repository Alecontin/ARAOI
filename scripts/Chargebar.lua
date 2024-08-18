--[[

    It seems like the game doesn't have an built-in chargebar function so I made my own
    I know it's a bit messy but it's the only thing I could come up with

--]]


---@class Chargebar
local chargebar = {}
chargebar.__index = chargebar

---@param angle? number -- *Default: `19` — The angle relative to the player, upwards.*
---@param distance? number -- *Default: `57.245086669922` — The distance from the player's position, towards the provided angle.*
function chargebar:Render(angle, distance)
    angle = angle or 19
    distance = 57.245086669922

    local player = self.ActivePlayer or Isaac.GetPlayer()
    self.Sprite:Render(Isaac.WorldToScreen(player.Position - (Vector(0,1):Normalized():Rotated(angle) * distance) ))

    local animation = self.Sprite:GetAnimation()
    local frame = self.Sprite:GetFrame()

    if animation == "Charging" then
        if frame >= 100 then
            self.Sprite:Play("StartCharged")
        end

    elseif animation == "StartCharged" and frame == 11 then
        self.Sprite:Play("Charged")

    elseif animation == "Charged" and frame == 5 then
        self.Sprite:SetFrame(0)
    end
end

function chargebar:GetCharge()
    if self.Sprite:GetAnimation() == "Charging" then
        return self.Sprite:GetFrame()
    elseif self.Sprite:GetAnimation() == "StartCharged" or self.Sprite:GetAnimation() == "Charged" then
        return 100
    else
        return 0
    end
end

---@param charge? integer
function chargebar:Advance(charge)
    if self.Sprite:GetAnimation() == "Disappear" then
        self.Sprite:SetAnimation("Charging")
        self:SetCharge(0)
    end

    if self.Sprite:GetAnimation() == "Charging" then
        self.Sprite:SetFrame(self.Sprite:GetFrame() + (charge or 1))
    end
end

---@param charge integer
function chargebar:SetCharge(charge)
    self.Sprite:Play("Charging")
    self.Sprite:SetFrame(charge)
end

function chargebar:Update()
    if self.Sprite:GetAnimation() ~= "Charging" then
        self.Sprite:SetFrame(self.Sprite:GetFrame() + 1)
    end
end

function chargebar:Release()
    self.Sprite:Play("Disappear")
end

---@param player EntityPlayer
---@param createIfNeeded? boolean
---@return Chargebar | nil
function chargebar:GetPlayerChargebar(player, createIfNeeded)
    local data = player:GetData()
    if data[self.ID] == nil and createIfNeeded == true then
        local new = chargebar:Create(self.ID)
        new:SetActivePlayer(player)
        data[self.ID] = new
    end

    return data[self.ID]
end

---@param player EntityPlayer
function chargebar:SetActivePlayer(player)
    self.ActivePlayer = player
end

---@param path string -- Path relative to the resources directory
function chargebar:SetCustomSpritesheet(path)
    self.Sprite:ReplaceSpritesheet(0, path)
    self.Sprite:LoadGraphics()
end

function chargebar:Create(id)
    ---@class Chargebar
    local instance = setmetatable({}, chargebar)
    instance.ID = id

    instance.ActivePlayer = nil

    instance.Sprite = Sprite()
    instance.Sprite:Load("gfx/chargebar.anm2", true)
    instance.Sprite:SetAnimation("Disappear")
    instance.Sprite:SetFrame(30)

    return instance
end

return chargebar