--[[
       Leak Tag by Zleyend    |.    zlxch.com   website official
]]


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local TEXT = "garama cyber giveaway\nzlxch.com"

local function createFootTag(character)
    local hrp = character:WaitForChild("HumanoidRootPart")

    local old = workspace:FindFirstChild(player.Name .. "_FootTag")
    if old then
        old:Destroy()
    end

    local anchor = Instance.new("Part")
    anchor.Name = player.Name .. "_FootTag"
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Parent = workspace

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 300, 0, 80)
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = anchor

    local blackLabel = Instance.new("TextLabel")
    blackLabel.Size = UDim2.new(1, 0, 1, 0)
    blackLabel.BackgroundTransparency = 1
    blackLabel.Text = TEXT
    blackLabel.Font = Enum.Font.GothamBlack
    blackLabel.TextSize = 15 --18
    blackLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    blackLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    blackLabel.TextStrokeTransparency = 0
    blackLabel.Parent = gui

    local whiteLabel = blackLabel:Clone()
    whiteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    whiteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    whiteLabel.ZIndex = 2
    whiteLabel.Parent = gui

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90

    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    }

    gradient.Parent = whiteLabel

    local cycleTime = 6

    RunService.RenderStepped:Connect(function()
        if not hrp.Parent then
            return
        end

        local forward = hrp.CFrame.LookVector * 4
        local left = -hrp.CFrame.RightVector * 4
        anchor.Position = hrp.Position + forward + left

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
end

if player.Character then
    createFootTag(player.Character)
end

player.CharacterAdded:Connect(createFootTag)
