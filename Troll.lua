local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    ITEMS_TO_INJECT = {
        {name = "Skibidi Toilet", mutation = "None", traits = {}},
    },
    TARGET_OPPONENT = "N4rczis0",
    AUTO_INJECT = true,
    INJECT_DELAY = 1.4,
}

local function safe(fn)
    local ok, res = pcall(fn)
    if ok then return res end
    return nil
end

local AnimalsData, BrainrotAssets, AnimalAnims, animalsModule = nil, nil, nil, nil

local function loadGameModules()
    pcall(function()
        local Shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 15)
        if Shared then
            local m = Shared:FindFirstChild("Animals")
            if m then 
                animalsModule = require(m)
                AnimalsData = animalsModule
            end
            local ba = Shared:FindFirstChild("BrainrotAssets")
            if ba then BrainrotAssets = require(ba) end
        end
    end)
    
    pcall(function()
        local a = ReplicatedStorage:FindFirstChild("Animations") or ReplicatedStorage:WaitForChild("Animations", 15)
        AnimalAnims = a and (a:FindFirstChild("Animals") or a:WaitForChild("Animals", 15))
    end)
end

loadGameModules()

local function ApplyMutation(model, animalName, mutName)
    if not mutName or mutName == "None" then return end
    
    if animalsModule and animalsModule.ApplyMutation then
        pcall(function() animalsModule:ApplyMutation(model, animalName, mutName) end)
        return
    end
    
    local palette = {
        Gold = {Color3.fromRGB(237,178,0), Color3.fromRGB(237,194,86), Color3.fromRGB(215,111,1)},
        Diamond = {Color3.fromRGB(37,196,254), Color3.fromRGB(116,212,254), Color3.fromRGB(28,137,254)},
        Bloodrot = {Color3.fromRGB(145,0,27), Color3.fromRGB(154,94,100), Color3.fromRGB(75,0,7)},
        Rainbow = {Color3.fromRGB(255,0,0), Color3.fromRGB(255,100,0), Color3.fromRGB(255,200,0)},
        Candy = {Color3.fromRGB(255,105,180), Color3.fromRGB(255,182,193), Color3.fromRGB(200,50,150)},
        Lava = {Color3.fromRGB(200,50,0), Color3.fromRGB(255,100,0), Color3.fromRGB(150,20,0)},
        Galaxy = {Color3.fromRGB(60,0,120), Color3.fromRGB(100,0,180), Color3.fromRGB(30,0,80)},
        YinYang = {Color3.fromRGB(18,18,22), Color3.fromRGB(20,20,28), Color3.fromRGB(230,230,240)},
        Radioactive = {Color3.fromRGB(100,255,0), Color3.fromRGB(150,255,50), Color3.fromRGB(50,200,0)},
        Cursed = {Color3.fromRGB(255,23,23), Color3.fromRGB(180,0,0), Color3.fromRGB(120,0,0)},
        Divine = {Color3.fromRGB(255,215,0), Color3.fromRGB(255,255,200), Color3.fromRGB(200,160,0)},
        Cyber = {Color3.fromRGB(62,155,255), Color3.fromRGB(80,200,255), Color3.fromRGB(30,80,180)},
    }
    
    local mutPalette = palette[mutName]
    if not mutPalette then return end
    
    local idx = 0
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and not part:GetAttribute("IgnoreColor") then
            idx = idx + 1
            local colorIdx = ((idx - 1) % #mutPalette) + 1
            part.Color = mutPalette[colorIdx]
            
            if mutName == "Galaxy" or mutName == "Lava" or mutName == "Cyber" then
                part.Material = Enum.Material.Neon
            end
        end
    end
end

local function ApplyTraits(model, traitList)
    if not traitList or #traitList == 0 then return end
    
    for _, traitName in ipairs(traitList) do
        pcall(function()
            local traitFolder = ReplicatedStorage:FindFirstChild("Models") 
                and ReplicatedStorage.Models:FindFirstChild("Traits")
            if not traitFolder then return end
            
            local traitModel = traitFolder:FindFirstChild(traitName)
            if not traitModel then return end
            
            local clone = traitModel:Clone()
            clone.Name = "_Trait." .. traitName
            clone.Parent = model
            
            for _, part in clone:GetChildren() do
                if part:IsA("BasePart") then
                    for _, att in part:GetDescendants() do
                        if att:IsA("Attachment") then
                            local target = model:FindFirstChild(att.Name, true)
                            if target and target:IsA("Attachment") then
                                local rc = Instance.new("RigidConstraint")
                                rc.Attachment0 = att
                                rc.Attachment1 = target
                                rc.Parent = part
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function tryGetModel(animalName)
    local modelTemplate = nil
    
    if BrainrotAssets and BrainrotAssets.getModel then
        modelTemplate = safe(function() return BrainrotAssets.getModel(animalName) end)
    end
    
    if not modelTemplate then
        local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
        local animalsFolder = modelsFolder and modelsFolder:FindFirstChild("Animals")
        if animalsFolder then
            modelTemplate = animalsFolder:FindFirstChild(animalName)
        end
    end
    
    if not modelTemplate then
        local data = ReplicatedStorage:FindFirstChild("Datas")
        if data then
            local animalData = data:FindFirstChild("Animals")
            if animalData then
                local info = safe(function() return require(animalData)[animalName] end)
                if info and info.Model then
                    modelTemplate = info.Model
                end
            end
        end
    end
    
    return modelTemplate
end

local function createModelInViewport(viewportFrame, animalName, mutation, traits)
    for _, child in viewportFrame:GetChildren() do
        if child:IsA("WorldModel") or child:IsA("Camera") then
            child:Destroy()
        end
    end
    
    local modelTemplate = tryGetModel(animalName)
    
    if not modelTemplate then
        local fallback = Instance.new("Model")
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 2)
        part.Shape = Enum.PartType.Ball
        part.Color = Color3.fromRGB(255, 50, 50)
        part.Anchored = true
        part.Parent = fallback
        fallback.PrimaryPart = part
        modelTemplate = fallback
    end
    
    local cam = Instance.new("Camera")
    cam.FieldOfView = 50
    cam.Parent = viewportFrame
    viewportFrame.CurrentCamera = cam
    
    local wm = Instance.new("WorldModel")
    wm.Parent = viewportFrame
    
    local model = modelTemplate:Clone()
    
    if mutation and mutation ~= "None" then
        ApplyMutation(model, animalName, mutation)
    end
    
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Anchored = true
            part.CastShadow = false
        end
    end
    
    if traits and #traits > 0 then
        ApplyTraits(model, traits)
    end
    
    local primaryPart = model.PrimaryPart or model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        model:PivotTo(CFrame.new(0, 0, 0))
    else
        local anyPart = model:FindFirstChildWhichIsA("BasePart")
        if anyPart then
            model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
        end
    end
    model.Parent = wm
    
    local minY, maxY, maxX, maxZ = math.huge, -math.huge, 0, 0
    local foundPart = false
    
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local pos = part.Position
            local size = part.Size
            minY = math.min(minY, pos.Y - size.Y * 0.5)
            maxY = math.max(maxY, pos.Y + size.Y * 0.5)
            maxX = math.max(maxX, size.X)
            maxZ = math.max(maxZ, size.Z)
            foundPart = true
        end
    end
    
    if not foundPart then
        minY, maxY, maxX, maxZ = -1, 1, 2, 2
    end
    
    local maxDim = math.max(maxX, maxY - minY, maxZ)
    local DIR = Vector3.new(-1, 0.25, -1).Unit
    local dist = (maxDim * 0.5 / math.tan(math.rad(25))) * 0.75
    local lookAt = primaryPart and primaryPart.CFrame or CFrame.new(0, (maxY + minY) * 0.5, 0)
    
    cam.CFrame = CFrame.new(
        (lookAt * CFrame.new(DIR * (dist + maxDim * 0.5))).Position,
        lookAt.Position
    )
    
    pcall(function()
        local animFolder = AnimalAnims and AnimalAnims:FindFirstChild(animalName)
        local idleAnim = animFolder and animFolder:FindFirstChild("Idle")
        if idleAnim then
            local ac = model:FindFirstChildOfClass("AnimationController") 
                or model:FindFirstChildWhichIsA("AnimationController", true)
            if not ac then
                ac = Instance.new("AnimationController")
                ac.Parent = model
            end
            local animator = ac:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator", ac)
            end
            local track = animator:LoadAnimation(idleAnim)
            track.Looped = true
            track:Play(0)
        end
    end)
    
    return true
end

local function getTradeGui()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    
    local tradeGui = pg:FindFirstChild("TradeLiveTrade")
    if not tradeGui then return nil end
    
    local inner = tradeGui:FindFirstChild("TradeLiveTrade")
    if not inner then return nil end
    
    return inner
end

local function getOtherScroll(inner)
    if not inner then return nil end
    local other = inner:FindFirstChild("Other")
    if not other then return nil end
    return other:FindFirstChild("ScrollingFrame")
end

local function getOpponentName()
    local inner = getTradeGui()
    if not inner then return nil end
    
    local other = inner:FindFirstChild("Other")
    if not other then return nil end
    
    local username = other:FindFirstChild("Username")
    if not username then return nil end
    
    local text = username.Text or ""
    local name = text:match("^@?(.-)'s Offer$") or text:match("^@(.-)$") or text
    return name
end

local injectedItems = {}
local isInjected = false
local pendingInjection = false

local function injectIntoOtherSide(items, opponentName)
    local inner = getTradeGui()
    if not inner then
        return false
    end
    
    local scroll = getOtherScroll(inner)
    if not scroll then
        return false
    end
    
    for _, v in scroll:GetChildren() do
        if v:IsA("Frame") and v.Name:sub(1, 3) == "KV_" then
            v:Destroy()
        end
    end
    injectedItems = {}
    
    local template = scroll:FindFirstChild("Template")
    if not template then
        return false
    end
    
    pcall(function()
        local other = inner:FindFirstChild("Other")
        if other then
            local username = other:FindFirstChild("Username")
            if username then
                username.Text = "@" .. (opponentName or CONFIG.TARGET_OPPONENT) .. "'s Offer"
            end
        end
    end)
    
    for i, item in ipairs(items) do
        local frame = template:Clone()
        frame.Name = "KV_" .. i
        frame.Visible = true
        frame.LayoutOrder = i + 1000
        frame:SetAttribute("KVInjected", true)
        
        local spacer = frame:FindFirstChild("Spacer")
        if spacer then
            local titleLbl = spacer:FindFirstChild("Title")
            if titleLbl then
                titleLbl.Text = item.name
            end
            
            local cashLbl = spacer:FindFirstChild("Cash")
            if cashLbl then
                local gen = 0
                pcall(function()
                    local data = ReplicatedStorage:FindFirstChild("Datas") 
                        and ReplicatedStorage.Datas:FindFirstChild("Animals")
                    if data then
                        local animalData = require(data)[item.name]
                        if animalData then
                            gen = animalData.Generation or 0
                        end
                    end
                end)
                if gen > 0 then
                    local function fmt(n)
                        if n >= 1e12 then return string.format("%.1fT", n/1e12)
                        elseif n >= 1e9 then return string.format("%.1fB", n/1e9)
                        elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
                        elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
                        else return tostring(math.floor(n)) end
                    end
                    cashLbl.Text = "$" .. fmt(gen) .. "/s"
                end
            end
            
            local vp = spacer:FindFirstChild("ViewportFrame")
            if vp then
                createModelInViewport(vp, item.name, item.mutation, item.traits or {})
            end
            
            pcall(function()
                if not item.traits or #item.traits == 0 then return end
                local traitsFrame = spacer:FindFirstChild("Traits") or frame:FindFirstChild("Traits", true)
                if not traitsFrame then return end
                
                traitsFrame.ClipsDescendants = false
                local tmplT = traitsFrame:FindFirstChild("Template")
                if not tmplT then return end
                tmplT.Visible = false
                
                for _, child in traitsFrame:GetChildren() do
                    if child ~= tmplT and child:IsA("ImageLabel") then
                        child:Destroy()
                    end
                end
                
                local TRAIT_ICONS = {
                    ["Taco"] = "rbxassetid://89041930759464",
                    ["Nyan"] = "rbxassetid://104229924295526",
                    ["Galactic"] = "rbxassetid://99181785766598",
                    ["Fireworks"] = "rbxassetid://121100427764858",
                    ["Zombie"] = "rbxassetid://110723387483939",
                    ["Claws"] = "rbxassetid://104964195846833",
                    ["Glitched"] = "rbxassetid://121332433272976",
                    ["Bubblegum"] = "rbxassetid://100601425541874",
                    ["Fire"] = "rbxassetid://118283346037788",
                    ["Wet"] = "rbxassetid://78474194088770",
                    ["Snowy"] = "rbxassetid://83627475909869",
                }
                
                for _, traitName in ipairs(item.traits) do
                    local icon = TRAIT_ICONS[traitName]
                    if icon then
                        local img = tmplT:Clone()
                        img.Image = icon
                        img.Visible = true
                        img.Parent = traitsFrame
                    end
                end
            end)
        end
        
        frame.Parent = scroll
        table.insert(injectedItems, frame)
    end
    
    pcall(function()
        local other = inner:FindFirstChild("Other")
        if other then
            local baseSlots = other:FindFirstChild("BaseSlots")
            if baseSlots then
                local current = #items
                local max = 15
                baseSlots.Text = current .. "/" .. max
            end
        end
    end)
    
    isInjected = true
    pendingInjection = false
    
    return true
end

local function restoreOriginal()
    local inner = getTradeGui()
    if not inner then return end
    
    local scroll = getOtherScroll(inner)
    if not scroll then return end
    
    for _, v in scroll:GetChildren() do
        if v:IsA("Frame") and v.Name:sub(1, 3) == "KV_" then
            v:Destroy()
        end
    end
    
    pcall(function()
        local other = inner:FindFirstChild("Other")
        if other then
            local baseSlots = other:FindFirstChild("BaseSlots")
            if baseSlots then
                baseSlots.Text = "0/15"
            end
        end
    end)
    
    isInjected = false
    pendingInjection = false
    injectedItems = {}
end

local tradeOpen = false

local function checkTradeGui()
    local inner = getTradeGui()
    local isOpen = inner ~= nil and inner.Visible == true
    
    if isOpen and not tradeOpen then
        tradeOpen = true
        
        task.wait(CONFIG.INJECT_DELAY)
        
        if not getTradeGui() then
            tradeOpen = false
            return
        end
        
        local opponentName = getOpponentName()
        
        if opponentName and opponentName == CONFIG.TARGET_OPPONENT then
            if CONFIG.AUTO_INJECT then
                injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
            end
        end
        
    elseif not isOpen and tradeOpen then
        tradeOpen = false
        restoreOriginal()
    end
end

local ViewportInjector = {}

function ViewportInjector.setItems(items)
    CONFIG.ITEMS_TO_INJECT = items
    if tradeOpen then
        local opponentName = getOpponentName()
        if opponentName and opponentName == CONFIG.TARGET_OPPONENT then
            injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
        end
    end
end

function ViewportInjector.setTargetOpponent(name)
    CONFIG.TARGET_OPPONENT = name
    if tradeOpen then
        local opponentName = getOpponentName()
        if opponentName and opponentName == name then
            injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
        end
    end
end

function ViewportInjector.inject()
    local opponentName = getOpponentName()
    if not opponentName then
        return false
    end
    
    if opponentName == CONFIG.TARGET_OPPONENT then
        return injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
    else
        return false
    end
end

function ViewportInjector.restore()
    restoreOriginal()
end

function ViewportInjector.toggleAuto()
    CONFIG.AUTO_INJECT = not CONFIG.AUTO_INJECT
end

function ViewportInjector.addItem(name, mutation, traits)
    table.insert(CONFIG.ITEMS_TO_INJECT, {
        name = name,
        mutation = mutation or "None",
        traits = traits or {},
    })
    if tradeOpen then
        local opponentName = getOpponentName()
        if opponentName and opponentName == CONFIG.TARGET_OPPONENT then
            injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
        end
    end
end

function ViewportInjector.clearItems()
    CONFIG.ITEMS_TO_INJECT = {}
    if tradeOpen then
        local opponentName = getOpponentName()
        if opponentName and opponentName == CONFIG.TARGET_OPPONENT then
            injectIntoOtherSide(CONFIG.ITEMS_TO_INJECT, opponentName)
        end
    end
end

function ViewportInjector.setDelay(seconds)
    CONFIG.INJECT_DELAY = math.max(0.5, seconds or 1.5)
end

_G.ViewportInjector = ViewportInjector

task.spawn(function()
    while true do
        pcall(checkTradeGui)
        task.wait(0.5)
    end
end)

task.spawn(function()
    loadGameModules()
end)
