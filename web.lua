--[[
    Leak Tag by Zleyend | zlhub.net
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local TEXT = "discord.gg/ZLHUB"

-- Detección de dispositivo
local isMobile = UserInputService.TouchEnabled
    and not UserInputService.KeyboardEnabled

local TEXT_SIZE = isMobile and 30 or 54

-- Eliminar GUI anterior
local oldGui = player.PlayerGui:FindFirstChild("FootTagGui")
if oldGui then
    oldGui:Destroy()
end

-- Crear GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FootTagGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = player.PlayerGui

-- Texto elegante
local label = Instance.new("TextLabel")
label.Name = "TextLabel"
label.Size = UDim2.new(0, 300, 0, 80)
label.Position = UDim2.new(0.5, 0, 0.8, 0.5)
label.AnchorPoint = Vector2.new(0.5, 0.5)

label.BackgroundTransparency = 1
label.Text = TEXT
label.Font = Enum.Font.Garamond
label.TextSize = TEXT_SIZE
label.TextColor3 = Color3.fromRGB(255,255,255)

-- Sin efectos
label.TextStrokeTransparency = 1
label.TextTransparency = 0

label.ZIndex = 1
label.Parent = screenGui
