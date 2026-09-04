--[[
       Leak Tag by Zleyend    |.    zlhub.net   website official
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local TEXT = "ZLHUB.NET"

local oldGui = player.PlayerGui:FindFirstChild("FootTagGui")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FootTagGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local blackLabel = Instance.new("TextLabel")
blackLabel.Size = UDim2.new(0, 300, 0, 80)
blackLabel.Position = UDim2.new(0.5, 0, 0.8, 0.5)
blackLabel.AnchorPoint = Vector2.new(0.5, 0.5)
blackLabel.BackgroundTransparency = 1
blackLabel.Text = TEXT
blackLabel.Font = Enum.Font.GothamBlack
blackLabel.TextSize = 20
blackLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
blackLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
blackLabel.TextStrokeTransparency = 0
blackLabel.Parent = screenGui

local whiteLabel = blackLabel:Clone()
whiteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
whiteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
whiteLabel.ZIndex = 2
whiteLabel.Parent = screenGui

local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
}
gradient.Parent = whiteLabel

local cycleTime = 4

RunService.RenderStepped:Connect(function()
    local progress = (tick() % cycleTime) / cycleTime

    if progress < 0.5 then
        local p = progress * 2
        local y = p * 2 - 1

        gradient.Offset = Vector2.new(0, y)

        gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0.00, 0),
            NumberSequenceKeypoint.new(0.47, 0),
            NumberSequenceKeypoint.new(0.49, 0),
            NumberSequenceKeypoint.new(0.50, 0),
            NumberSequenceKeypoint.new(0.51, 0),
            NumberSequenceKeypoint.new(0.53, 1),
            NumberSequenceKeypoint.new(1.00, 1)
        }

    else
        local p = (progress - 0.5) * 2
        local y = p * 2 - 1

        gradient.Offset = Vector2.new(0, y)

        gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.47, 1),
            NumberSequenceKeypoint.new(0.49, 0),
            NumberSequenceKeypoint.new(0.50, 0),
            NumberSequenceKeypoint.new(0.51, 0),
            NumberSequenceKeypoint.new(0.53, 0),
            NumberSequenceKeypoint.new(1.00, 0)
        }
    end
end)
