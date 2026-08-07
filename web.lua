--[[
       Leak Tag by Zleyend    |.    zlhub.net   website official
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

local TEXT_SIZE = UserInputService.TouchEnabled and 18 or 22

local TEXT = "ZLHUB.NET"

local RENDER_NAME = "ZLFootTagUpdate"

local function createText(parent)
    local blackLabel = Instance.new("TextLabel")
    blackLabel.Size = UDim2.fromScale(1, 1)
    blackLabel.BackgroundTransparency = 1
    blackLabel.Text = TEXT
    blackLabel.Font = Enum.Font.GothamBlack
    blackLabel.TextSize = TEXT_SIZE
    blackLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    blackLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    blackLabel.TextStrokeTransparency = 0
    blackLabel.ZIndex = 1
    blackLabel.Parent = parent

    local whiteLabel = blackLabel:Clone()
    whiteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    whiteLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    whiteLabel.ZIndex = 2
    whiteLabel.Parent = parent

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Parent = whiteLabel

    return gradient
end

local function createFootTag(character)
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_NAME)
    end)

    local oldScreen = playerGui:FindFirstChild("ZLFirstPersonTag")
    if oldScreen then
        oldScreen:Destroy()
    end

    local hrp = character:WaitForChild("HumanoidRootPart")
    local head = character:WaitForChild("Head")

    local oldAttachment = hrp:FindFirstChild("ZLFootTagAttachment")
    if oldAttachment then
        oldAttachment:Destroy()
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "ZLFootTagAttachment"
    attachment.Position = Vector3.new(0, -3, 0)
    attachment.Parent = hrp

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ZLFootTag"
    billboard.Adornee = attachment
    billboard.Size = UDim2.fromOffset(300, 80)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Enabled = true
    billboard.Parent = attachment

    local worldGradient = createText(billboard)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZLFirstPersonTag"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999999
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(300, 80)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.68)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local screenGradient = createText(frame)

    local cycleTime = 6

    local isFirstPerson = false

    local ENTER_DISTANCE = 1.2
    local EXIT_DISTANCE = 4

    local exitTimer = 0
    local EXIT_DELAY = 0.15

    RunService:BindToRenderStep(
        RENDER_NAME,
        Enum.RenderPriority.Camera.Value + 10,
        function(dt)
            if not character.Parent then
                return
            end

            if not head.Parent or not hrp.Parent then
                return
            end

            local camera = workspace.CurrentCamera
            if not camera then
                return
            end

            local distance =
                (camera.CFrame.Position - head.Position).Magnitude

            if not isFirstPerson then
                if distance <= ENTER_DISTANCE then
                    isFirstPerson = true
                    exitTimer = 0
                end
            else
                if distance >= EXIT_DISTANCE then
                    exitTimer += dt

                    if exitTimer >= EXIT_DELAY then
                        isFirstPerson = false
                        exitTimer = 0
                    end
                else
                    exitTimer = 0
                end
            end

            screenGui.Enabled = isFirstPerson
            billboard.Enabled = not isFirstPerson

            local progress = (time() % cycleTime) / cycleTime

            local offset
            local transparency

            if progress < 0.5 then
                local p = progress * 2
                offset = p * 2 - 1

                transparency = NumberSequence.new({
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
                offset = p * 2 - 1

                transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0.00, 1),
                    NumberSequenceKeypoint.new(0.47, 1),
                    NumberSequenceKeypoint.new(0.49, 0),
                    NumberSequenceKeypoint.new(0.50, 0),
                    NumberSequenceKeypoint.new(0.51, 0),
                    NumberSequenceKeypoint.new(0.53, 0),
                    NumberSequenceKeypoint.new(1.00, 0)
                })
            end

            worldGradient.Offset = Vector2.new(0, offset)
            screenGradient.Offset = Vector2.new(0, offset)

            worldGradient.Transparency = transparency
            screenGradient.Transparency = transparency
        end
    )
end

if player.Character then
    task.spawn(createFootTag, player.Character)
end

player.CharacterAdded:Connect(function(character)
    createFootTag(character)
end)
