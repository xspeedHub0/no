--[[
       Leak Tag by Zleyend    |.    zlhub.net   website official
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local TEXT = "ZLHUB.NET"

local currentConnection

local function createFootTag(character)
    local hrp = character:WaitForChild("HumanoidRootPart")

    if currentConnection then
        currentConnection:Disconnect()
        currentConnection = nil
    end

    local old = hrp:FindFirstChild("ZLFootTagAttachment")
    if old then
        old:Destroy()
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "ZLFootTagAttachment"
    attachment.Position = Vector3.new(0, -3, 0)
    attachment.Parent = hrp

    local gui = Instance.new("BillboardGui")
    gui.Name = "ZLFootTag"
    gui.Adornee = attachment
    gui.Size = UDim2.fromOffset(300, 80)

    gui.StudsOffset = Vector3.new(0, 0, 0)

    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Parent = attachment

    local blackLabel = Instance.new("TextLabel")
    blackLabel.Size = UDim2.fromScale(1, 1)
    blackLabel.BackgroundTransparency = 1
    blackLabel.Text = TEXT
    blackLabel.Font = Enum.Font.GothamBlack
    blackLabel.TextSize = 18
    blackLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    blackLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    blackLabel.TextStrokeTransparency = 0
    blackLabel.ZIndex = 1
    blackLabel.Parent = gui

    local whiteLabel = blackLabel:Clone()
    whiteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    whiteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    whiteLabel.ZIndex = 2
    whiteLabel.Parent = gui

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90

    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(255, 255, 255)
        ),

        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(255, 255, 255)
        )
    })

    gradient.Parent = whiteLabel

    local cycleTime = 6

    currentConnection = RunService.RenderStepped:Connect(function()
        if not character.Parent then
            return
        end

        local progress = (time() % cycleTime) / cycleTime

        if progress < 0.5 then
            local p = progress * 2
            local y = p * 2 - 1

            gradient.Offset = Vector2.new(0, y)

            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 0),
                NumberSequenceKeypoint.new(0.47, 0),
                NumberSequenceKeypoint.new(0.49, 0),
                NumberSequenceKeypoint.new(0.50, 0),
                NumberSequenceKeypoint.new(0.51, 0),
                NumberSequenceKeypoint.new(0.53, 1),
                NumberSequenceKeypoint.new(1.00, 1)
            })
        else
            local p = (progress - 0.5) * 2
            local y = p * 2 - 1

            gradient.Offset = Vector2.new(0, y)

            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 1),
                NumberSequenceKeypoint.new(0.47, 1),
                NumberSequenceKeypoint.new(0.49, 0),
                NumberSequenceKeypoint.new(0.50, 0),
                NumberSequenceKeypoint.new(0.51, 0),
                NumberSequenceKeypoint.new(0.53, 0),
                NumberSequenceKeypoint.new(1.00, 0)
            })
        end
    end)
end

if player.Character then
    createFootTag(player.Character)
end

player.CharacterAdded:Connect(createFootTag)
