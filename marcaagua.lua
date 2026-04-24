--- source / zl watermark
--- 
local G2L = {};

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function setupGUI()
    if player.PlayerGui:FindFirstChild("ZLGui") then
        player.PlayerGui.ZLGui:Destroy()
    end

    G2L["1"] = Instance.new("ScreenGui")
    G2L["1"]["ResetOnSpawn"] = false
    G2L["1"]["Name"] = "ZLGui"
    G2L["1"]["ClipToDeviceSafeArea"] = false
    G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
    G2L["1"].Parent = player:WaitForChild("PlayerGui")

    G2L["2"] = Instance.new("TextLabel", G2L["1"])
    G2L["2"]["TextWrapped"] = true
    G2L["2"]["BorderSizePixel"] = 0
    G2L["2"]["TextSize"] = 14
    G2L["2"]["TextScaled"] = true
    G2L["2"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
    G2L["2"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    G2L["2"]["TextColor3"] = Color3.fromRGB(94, 255, 245)
    G2L["2"]["BorderMode"] = Enum.BorderMode.Inset
    G2L["2"]["BackgroundTransparency"] = 1
    G2L["2"]["Size"] = UDim2.new(0, 135, 0, 34)
    G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
    G2L["2"]["Text"] = [[ZLHUB  神々]]
    G2L["2"]["Position"] = UDim2.new(0.635, 105, -0.5, 125)

    G2L["3"] = Instance.new("UIGradient", G2L["2"])
    G2L["3"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),ColorSequenceKeypoint.new(0.149, Color3.fromRGB(253, 253, 253)),ColorSequenceKeypoint.new(0.618, Color3.fromRGB(254, 31, 32)),ColorSequenceKeypoint.new(0.670, Color3.fromRGB(240, 249, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))}

    G2L["4"] = Instance.new("LocalScript", G2L["2"])
    
    local function C_4()
        local gradient = G2L["4"].Parent:WaitForChild("UIGradient")
        local speed = 0.01
        local offsetX = -1
        while true do
            offsetX = offsetX + speed
            if offsetX > 1 then
                offsetX = -1
            end
            gradient.Offset = Vector2.new(offsetX, 0)
            task.wait(0.05)
        end
    end
    task.spawn(C_4)

    G2L["5"] = Instance.new("UIStroke", G2L["2"])
    G2L["5"]["Thickness"] = 0.3

    G2L["6"] = Instance.new("UIStroke", G2L["2"])
    G2L["6"]["Thickness"] = 0.8
    G2L["6"]["Color"] = Color3.fromRGB(255, 255, 255)
    G2L["6"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border
    G2L["6"]["Name"] = [[borde]]

    G2L["7"] = Instance.new("UIGradient", G2L["6"])
    G2L["7"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),ColorSequenceKeypoint.new(0.157, Color3.fromRGB(0, 201, 232)),ColorSequenceKeypoint.new(0.327, Color3.fromRGB(165, 247, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))}

    G2L["8"] = Instance.new("LocalScript", G2L["6"])
    
    local function C_8()
        local gradient = G2L["8"].Parent:WaitForChild("UIGradient")
        local speed = 0.01
        local offsetX = -1
        while true do
            offsetX = offsetX + speed
            if offsetX > 1 then
                offsetX = -1
            end
            gradient.Offset = Vector2.new(offsetX, 0)
            task.wait(0.05)
        end
    end
    task.spawn(C_8)
end

setupGUI()
player.CharacterAdded:Connect(setupGUI)

return G2L["1"], require
