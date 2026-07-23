local allowedPlaces = {
    [109983668079237] = true,
    [96342491571673] = true,
}

if not allowedPlaces[game.PlaceId] then
    return
end

local Synchronizer = require(game.ReplicatedStorage.Packages.Synchronizer)
local guid = getupvalue(Synchronizer.Get, 2)
setupvalue(Synchronizer.Get, 1, function() return guid end)


-- -- ──────────────────────────────────

local WS_URL = "wss://zlhub.net/ws"  
-- -- ──────────────────────────────────

local MAX_DUELS_CARDS = 24
local MAX_TRADES_CARDS = 24
local MAX_TOP_RICH_CARDS = 24
local MAX_CHARACTERS = 120
local MAX_MESSAGES = 40

-- -- ──────────────────────────────────

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Datas = ReplicatedStorage:WaitForChild("Datas")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = ReplicatedStorage:WaitForChild("Utils")

local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
local AnimalsData = require(Datas:WaitForChild("Animals"))
local AnimalsShared = require(Shared:WaitForChild("Animals"))
local NumberUtils = require(Utils:WaitForChild("NumberUtils"))
local BaseSkins = require(ReplicatedStorage.Shared.BaseSkins)

setupvalue(AnimalsShared.GetGeneration, 1, function() end)

    local guid = getupvalue(Synchronizer.Get, 2)
    setupvalue(Synchronizer.Get, 1, function() return guid end)
    
    
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotAssets = require(ReplicatedStorage.Shared.BrainrotAssets)
local BrainrotSizes = ReplicatedStorage:FindFirstChild("BrainrotSizes") or {}

-- ──────────────────────────────────

local globalCooldown = nil

if not request then
    if syn and syn.request then
        request = syn.request
    elseif http_request then
        request = http_request
    else
        warn("⚠️ 'request' function not available!")
        return
    end
end

-- ──────────────────────────────────

local useWebSocket = true

if WebSocket and type(WebSocket.connect) == "function" then
    useWebSocket = true
    
else
    useWebSocket = false
    print("⚠️ WebSocket NO disponible, usando polling cada 10 segundos")
end

-- ──────────────────────────────────

local cachedDuelsData = {}
local cachedTradesData = {}
local cachedTopRichData = {}
local wsConnection = nil  -- Una sola conexión
local wsReconnectTimer = nil
local wsConnected = false

-- ────────────────────────────────────────────────────────────
-- CONTROL DE RECONEXIÓN (DEFINIR PRIMERO)
-- ────────────────────────────────────────────────────────────
local reconnectAttempts = 0
local MAX_RECONNECT_ATTEMPTS = 2
local reconnectInProgress = false
local reconnectBtn = nil
local connectionStatusLabel = nil

-- ──────────────────────────────────

local isChatVisible = false
local isPvPFinderVisible = false
local isTradeFinderVisible = false
local isFilterWindowVisible = false
local isTopRichVisible = false
local isVIPWindowVisible = false
local shownMessages = {}
local pendingMessages = {}
local lastMessageId = ""
local isPolling = false
local messageCounter = 0
local pvpGuiInstance = nil
local tradeGuiInstance = nil
local filterGuiInstance = nil
local topRichGuiInstance = nil
local vipGuiInstance = nil
local lastProcessedMessage = ""
local lastProcessedTime = 0
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotAssets = require(ReplicatedStorage.Shared.BrainrotAssets)
-- ──────────────────────────────────

local pendingOwnSubmissions = {}

SECRET_KEY = "ZLtrade2026OnToP"
VALIDATION_MESSAGES = {"Hola", "ZL", "OnTop", "Prueba"}

-- ────────────────────────────────────────────────────────────
-- OFUSCACIÓN CORREGIDA
-- ────────────────────────────────────────────────────────────

local function xorBytes(str)
    local out = {}
    for i = 1, #str do
        local k = string.byte(SECRET_KEY, ((i - 1) % #SECRET_KEY) + 1)
        local b = string.byte(str, i)
        -- Usar bit32.bxor (disponible en Roblox)
        local xor_result = bit32.bxor(b, k)
        out[i] = xor_result
    end
    return out
end

local function toHex(bytes)
    local hex = ""
    for i = 1, #bytes do
        hex = hex .. string.format("%02x", bytes[i])
    end
    return hex
end

local function generateJunk(len)
    -- Remover '~' y otros caracteres problemáticos
    local nonHexChars = "!@#$%^&*()_+=-[]{};:'\",.<>/?\\|`"
    -- '~' removido de esta lista
    local t = {}
    for i = 1, len do
        local pos = math.random(1, #nonHexChars)
        t[i] = string.sub(nonHexChars, pos, pos)
    end
    return table.concat(t)
end

local function generateHandshakeKey()
    local timestamp = os.time()
    local randomMsg = VALIDATION_MESSAGES[math.random(1, #VALIDATION_MESSAGES)]
    
    -- Formato: "mensaje|timestamp"
    local dataToEncode = randomMsg .. "|" .. timestamp
    
    local xorResult = xorBytes(dataToEncode)
    local encoded = toHex(xorResult)
    
    -- IMPORTANTE: Asegurar que el hex sea fácilmente identificable
    -- Agregar marcadores para que el servidor encuentre el hex fácilmente
    local hexMarker = "##HEX##"
    local junk1 = generateJunk(math.random(5, 10))
    local junk2 = generateJunk(math.random(5, 10))
    
    local mode = math.random(1, 3)
    
    local obfuscated
    if mode == 1 then
        -- Modo: basura + HEX + marcador + basura
        obfuscated = junk1 .. hexMarker .. encoded .. junk2
    elseif mode == 2 then
        -- Modo: HEX + marcador + basura
        obfuscated = encoded .. hexMarker .. junk1 .. junk2
    else
        -- Modo: basura + marcador + HEX
        obfuscated = junk1 .. junk2 .. hexMarker .. encoded
    end
    
    return obfuscated
end
-- ────────────────────────────────────────────────────────────
-- HANDSHAKE CON EL SERVIDOR
-- ────────────────────────────────────────────────────────────

local wsAuthenticated = false

local function sendHandshakeAndWait()
    if not wsConnection or not wsConnected then
        print("❌ [z] Falla: WebSocket no conectado")
        return false
    end
    
    -- Generar key de handshake
    local handshakeKey = generateHandshakeKey()
    
    -- Debug: verificar que la key no esté vacía
    if not handshakeKey or handshakeKey == "" then
        print("❌ Error: Key de  vacía")
        return false
    end
    
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        print("❌ Error: WebSocket no tiene método Send/send")
        return false
    end
    
    -- Variable para esperar respuesta
    local handshakeCompleted = false
    local handshakeSuccess = false
    local errorReason = nil
    local responseReceived = nil
    
    -- Conectar evento temporal para handshake
    local connection
    connection = wsConnection.OnMessage:Connect(function(message)
        -- Limpiar mensaje
        local cleaned = message:gsub("[%z\1-\31]", "")
        cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
        
        responseReceived = cleaned
        
        local success, data = pcall(function()
            return HttpService:JSONDecode(cleaned)
        end)
        
        if not success then
            errorReason = "JSON inválido: " .. tostring(cleaned):sub(1, 100)
            print("❌ Error decodificando:", errorReason)
            handshakeCompleted = true
            handshakeSuccess = false
            if connection then connection:Disconnect() end
            return
        end
        
        if data and data.type == "handshake_response" then
            if data.success then
                print("✅ Éxito -autenticado")
                handshakeSuccess = true
                wsAuthenticated = true
            else
                errorReason = data.error or "Error desconocido del servidor"
                print("❌ Servidor rechazó:", errorReason)
                handshakeSuccess = false
                wsAuthenticated = false
            end
            handshakeCompleted = true
            if connection then connection:Disconnect() end
        elseif data and data.type == "error" then
            errorReason = "Servidor envió error: " .. (data.error or "unknown")
            print("❌ Error del servidor:", errorReason)
            handshakeCompleted = true
            handshakeSuccess = false
            if connection then connection:Disconnect() end
        else
            -- Respuesta inesperada pero no es handshake_response
            if data and data.type then
                print("⚠️ Respuesta inesperada tipo: " .. tostring(data.type) .. ", esperando handshake_response")
            else
                print("⚠️ Respuesta sin tipo: " .. tostring(cleaned):sub(1, 80))
            end
        end
    end)
    
    -- Enviar handshake
    local handshakeMsg = HttpService:JSONEncode({
        type = "handshake",
        key = handshakeKey
    })
    
    print("Enviando...")
    
    local success, err = pcall(function()
        sendMethod(wsConnection, handshakeMsg)
    end)
    
    if not success then
        print("❌  Error enviando mensaje:", err)
        if connection then connection:Disconnect() end
        return false
    end
    
    print("Mensaje enviado, esperando respuesta...")
    
    -- Esperar respuesta (máximo 5 segundos)
    local timeout = 0
    local maxTimeout = 50  -- 5 segundos (50 * 0.1s)
    while not handshakeCompleted and timeout < maxTimeout do
        task.wait(0.1)
        timeout = timeout + 1
        
        -- Debug cada segundo
        if timeout % 10 == 0 then
            print("Esperando... " .. (timeout/10) .. "s")
        end
    end
    
    if not handshakeCompleted then
        errorReason = "Timeout - Sin respuesta del servidor después de 5 segundos"
        print("❌ [HANDSHAKE] " .. errorReason)
        if responseReceived then
            print("   Última respuesta recibida: " .. tostring(responseReceived):sub(1, 200))
        else
            print("   No se recibió ninguna respuesta del servidor")
        end
        if connection then connection:Disconnect() end
        return false
    end
    
    return handshakeSuccess
end

-- ──────────────────────────────────

local function censorUsername(username)
    if not username or #username <= 4 then
        return username or "???"
    end
    local censored = string.sub(username, 1, #username - 3)
    if #censored > 12 then
        censored = string.sub(censored, 1, 10) .. "..."
    end
    return censored
end

-- ──────────────────────────────────

local topRichRankCache = {}
local lastRankCacheTime = 0
local RANK_CACHE_DURATION = 60

local function getUserTopRichRank(userId)
    if topRichRankCache[userId] and (tick() - lastRankCacheTime) < RANK_CACHE_DURATION then
        return topRichRankCache[userId]
    end
    topRichRankCache = {}
    local rank = nil
    for i, entry in ipairs(topRichList) do
        if entry.userId == userId then
            rank = i
            break
        end
        topRichRankCache[entry.userId] = i
    end
    lastRankCacheTime = tick()
    return rank
end

local function getRankTextWithEmoji(rank)
    if not rank or rank <= 0 then return "", nil end
    local text = ""
    local color = nil
    if rank == 1 then
        text = " 🥇 #1"
        color = Color3.fromRGB(255, 255, 255)
    elseif rank == 2 then
        text = " 🥈 #2"
        color = Color3.fromRGB(192, 192, 192)
    elseif rank == 3 then
        text = " 🥉 #3"
        color = Color3.fromRGB(205, 127, 50)
    else
        text = " #" .. rank
        color = Color3.fromRGB(255, 215, 0)
    end
    return text, color
end

local function applyRankToNameLabel(nameLabel, username, userId)
    if not nameLabel or not username then return end
    task.spawn(function()
        local rank = getUserTopRichRank(userId)
        local rankText, color = getRankTextWithEmoji(rank)
        if rankText and rankText ~= "" then
            nameLabel.Text = username .. rankText
            if color then
                nameLabel.TextColor3 = color
            end
        else
            nameLabel.Text = username
            nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        end
    end)
end

-- ──────────────────────────────────

local PREMIUM_URL = "https://raw.githubusercontent.com/xspeedHub0/AutoJoinerAccess/refs/heads/main/users.txt"
local isUserPremium = false
local premiumExpiryTime = 0
local premiumUsername = nil

local function getCooldownTime()
    if isUserPremium then
        return 30
    else
        return 120
    end
end

local function parseRemainingTime(timeStr)
    if not timeStr or timeStr == "" then return 0 end
    timeStr = string.lower(string.gsub(timeStr, "%s+", ""))
    local days = string.match(timeStr, "(%d+)d")
    local hours = string.match(timeStr, "(%d+)h")
    local minutes = string.match(timeStr, "(%d+)m")
    local totalSeconds = 0
    if days then totalSeconds = totalSeconds + (tonumber(days) * 86400) end
    if hours then totalSeconds = totalSeconds + (tonumber(hours) * 3600) end
    if minutes then totalSeconds = totalSeconds + (tonumber(minutes) * 60) end
    if totalSeconds == 0 and string.find(timeStr, "expired") then return 0 end
    return totalSeconds
end

local function checkPremiumStatus()
    local success, response = pcall(function()
        return request({
            Url = PREMIUM_URL,
            Method = "GET",
            Headers = {["Cache-Control"] = "no-cache"}
        })
    end)
    if not success or not response or response.StatusCode ~= 200 then
        return false
    end
    local content = response.Body
    if not content or content == "" then return false end
    local currentPlayerName = string.lower(player.Name)
    for line in string.gmatch(content, "[^\r\n]+") do
        line = string.gsub(line, "^%s*(.-)%s*$", "%1")
        local username, remainingTime, timestamp = string.match(line, "^([^=]+)=([^#]+)#(%d+)$")
        if not username then
            username, remainingTime = string.match(line, "^([^=]+)=([^#]+)$")
        end
        if username and remainingTime then
            username = string.lower(string.gsub(username, "^%s*(.-)%s*$", "%1"))
            remainingTime = string.gsub(remainingTime, "^%s*(.-)%s*$", "%1")
            if username == currentPlayerName then
                if timestamp and tonumber(timestamp) then
                    local expiryTimestamp = tonumber(timestamp)
                    if os.time() <= expiryTimestamp then
                        isUserPremium = true
                        premiumExpiryTime = expiryTimestamp
                        premiumUsername = player.Name
                        local secondsRemaining = expiryTimestamp - os.time()
                        local timeStr = ""
                        if secondsRemaining >= 86400 then
                            timeStr = string.format("%dd", math.floor(secondsRemaining / 86400))
                        elseif secondsRemaining >= 3600 then
                            timeStr = string.format("%dh", math.floor(secondsRemaining / 3600))
                        else
                            timeStr = string.format("%dm", math.floor(secondsRemaining / 60))
                        end
                        showNotification("👑 Premium Activo", string.format("Bienvenido %s! Premium por %s", player.Name, timeStr), 5)
                        return true
                    else
                        local secondsFromText = parseRemainingTime(remainingTime)
                        if secondsFromText > 0 then
                            isUserPremium = true
                            premiumExpiryTime = os.time() + secondsFromText
                            premiumUsername = player.Name
                            local timeStr = ""
                            if secondsFromText >= 86400 then
                                timeStr = string.format("%dd", math.floor(secondsFromText / 86400))
                            elseif secondsFromText >= 3600 then
                                timeStr = string.format("%dh", math.floor(secondsFromText / 3600))
                            else
                                timeStr = string.format("%dm", math.floor(secondsFromText / 60))
                            end
                            showNotification("👑 Premium Activo", string.format("Bienvenido %s! Premium por %s (renovado)", player.Name, timeStr), 5)
                            return true
                        end
                    end
                end
                local secondsRemaining = parseRemainingTime(remainingTime)
                if secondsRemaining > 0 then
                    isUserPremium = true
                    premiumExpiryTime = os.time() + secondsRemaining
                    premiumUsername = player.Name
                    local timeStr = ""
                    if secondsRemaining >= 86400 then
                        timeStr = string.format("%dd", math.floor(secondsRemaining / 86400))
                    elseif secondsRemaining >= 3600 then
                        timeStr = string.format("%dh", math.floor(secondsRemaining / 3600))
                    else
                        timeStr = string.format("%dm", math.floor(secondsRemaining / 60))
                    end
                    showNotification("👑 Premium Activo", string.format("Bienvenido %s! Premium por %s", player.Name, timeStr), 5)
                    return true
                else
                    isUserPremium = false
                    premiumExpiryTime = 0
                    showNotification("⚠️ Premium Expirado", "Tu premium ha expirado. Renueva para seguir usando todas las funciones.", 5, true)
                    return false
                end
            end
        end
    end
    isUserPremium = false
    premiumExpiryTime = 0
    return false
end

local function getPremiumTimeRemaining()
    if not isUserPremium then return "Sin premium" end
    local remaining = premiumExpiryTime - os.time()
    if remaining <= 0 then
        isUserPremium = false
        return "Expirado"
    end
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

task.spawn(function()
    task.wait(2)
    checkPremiumStatus()
    while true do
        task.wait(300)
        if isUserPremium and premiumExpiryTime > 0 and premiumExpiryTime <= os.time() then
            isUserPremium = false
            showNotification("⚠️ Premium Expirado", "Tu premium ha expirado durante la sesión.", 5, true)
        elseif not isUserPremium then
            checkPremiumStatus()
        end
    end
end)

-- ──────────────────────────────────

local VIP_HIGHLIGHT_DURATION = 16
local vipHighlightQueue = {}
local vipUsersCache = {}

local function loadVIPsToCache()
    local success, response = pcall(function()
        return request({
            Url = PREMIUM_URL,
            Method = "GET",
            Headers = {["Cache-Control"] = "no-cache"}
        })
    end)
    if success and response and response.StatusCode == 200 then
        local content = response.Body
        if content then
            vipUsersCache = {}
            for line in string.gmatch(content, "[^\r\n]+") do
                line = string.gsub(line, "^%s*(.-)%s*$", "%1")
                local username = string.match(line, "^([^=]+)=")
                if username then
                    username = string.lower(string.gsub(username, "^%s*(.-)%s*$", "%1"))
                    vipUsersCache[username] = true
                end
            end
        end
    end
end

local function isUserVIP(username)
    if not username or username == "" then 
        return false 
    end
    -- Asegurar que vipUsersCache existe
    if not vipUsersCache then
        vipUsersCache = {}
    end
    return vipUsersCache[string.lower(username)] == true
end

-- Reemplazar la función addToVIPHighlight con esta versión que limpia expirados primero
local function addToVIPHighlight(username)
    if not username or username == "" then 
        return 
    end
    
    if not isUserVIP(username) then 
        return 
    end
    
    -- Asegurar que vipHighlightQueue existe
    if not vipHighlightQueue then
        vipHighlightQueue = {}
    end
    
    -- 🔥 LIMPIAR EXPIRADOS ANTES DE AGREGAR NUEVO
    local currentTime = tick()
    for i = #vipHighlightQueue, 1, -1 do
        if vipHighlightQueue[i].expires < currentTime then
            table.remove(vipHighlightQueue, i)
        end
    end
    
    -- Eliminar entrada duplicada si existe
    for i, entry in ipairs(vipHighlightQueue) do
        if entry.username == username then
            table.remove(vipHighlightQueue, i)
            break
        end
    end
    
    -- Agregar nueva entrada
    table.insert(vipHighlightQueue, 1, {
        username = username,
        expires = currentTime + VIP_HIGHLIGHT_DURATION
    })
end

-- Reemplazar la función sortPlayersWithVIPHighlight
local function sortPlayersWithVIPHighlight(players)
    if not players or type(players) ~= "table" then
        return {}
    end
    
    -- 🔥 LIMPIAR EXPIRADOS CADA VEZ QUE SE ORDENA
    local currentTime = tick()
    if vipHighlightQueue then
        for i = #vipHighlightQueue, 1, -1 do
            if vipHighlightQueue[i].expires < currentTime then
                table.remove(vipHighlightQueue, i)
            end
        end
    end
    
    -- Crear listas separadas
    local highlighted = {}  -- VIPs activos
    local normal = {}       -- No VIPs
    
    for _, player in ipairs(players) do
        if player and player.username then
            -- Verificar si es VIP Y si está activo en la cola
            local isActiveVIP = false
            if isUserVIP(player.username) and vipHighlightQueue then
                for _, vip in ipairs(vipHighlightQueue) do
                    if vip.username == player.username then
                        isActiveVIP = true
                        break
                    end
                end
            end
            -- O si es VIP y no tiene entrada en queue, igual lo tratamos como VIP pero con prioridad normal
            local isVIP = isUserVIP(player.username)
            
            if isActiveVIP then
                table.insert(highlighted, player)
            else
                table.insert(normal, player)
            end
        end
    end
    
    -- Ordenar por timestamp dentro de cada grupo (más reciente primero)
    table.sort(highlighted, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)
    table.sort(normal, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)
    
    -- Combinar: VIPs activos primero, luego normales
    local result = {}
    for _, p in ipairs(highlighted) do table.insert(result, p) end
    for _, p in ipairs(normal) do table.insert(result, p) end
    
    return result
end

-- 🔥 NUEVA FUNCIÓN: Limpiador periódico de expirados
local function startVIPCleanupLoop()
    task.spawn(function()
        while true do
            task.wait(5) -- Limpiar cada 5 segundos
            if vipHighlightQueue then
                local currentTime = tick()
                local changed = false
                for i = #vipHighlightQueue, 1, -1 do
                    if vipHighlightQueue[i].expires < currentTime then
                        table.remove(vipHighlightQueue, i)
                        changed = true
                    end
                end
                -- Si hubo cambios y alguna ventana está abierta, refrescar
                if changed then
                    if isPvPFinderVisible and pvpGuiInstance then
                        cachedDuelsData = sortPlayersWithVIPHighlight(cachedDuelsData)
                        updatePlayersListIncremental()
                    end
                    if isTradeFinderVisible and tradeGuiInstance then
                        cachedTradesData = sortPlayersWithVIPHighlight(cachedTradesData)
                        updateTradePlayersListIncremental()
                    end
                end
            end
        end
    end)
end

-- Iniciar el limpiador al cargar el script
startVIPCleanupLoop()

task.spawn(function()
    loadVIPsToCache()
    while true do
        task.wait(300)
        loadVIPsToCache()
    end
end)

-- ──────────────────────────────────

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZLChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- ──────────────────────────────────

local pvpBtn = Instance.new("TextButton")
pvpBtn.Size = UDim2.new(0, 100, 0, 39)
pvpBtn.Position = UDim2.new(0.5, -5, 0, 10)
pvpBtn.Text = "PvP Finder"
pvpBtn.TextSize = 14
pvpBtn.Font = Enum.Font.GothamBold
pvpBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
pvpBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pvpBtn.BackgroundTransparency = 0.25
pvpBtn.BorderSizePixel = 1
pvpBtn.Parent = gui
local pvpCorner = Instance.new("UICorner")
pvpCorner.CornerRadius = UDim.new(0, 30)
pvpCorner.Parent = pvpBtn

local tradeBtn = Instance.new("TextButton")
tradeBtn.Size = UDim2.new(0, 100, 0, 39)
tradeBtn.Position = UDim2.new(0.5, 105, 0, 10)
tradeBtn.Text = "Trade Finder"
tradeBtn.TextSize = 14
tradeBtn.Font = Enum.Font.GothamBold
tradeBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
tradeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tradeBtn.BackgroundTransparency = 0.25
tradeBtn.BorderSizePixel = 1
tradeBtn.Parent = gui
local tradeCorner = Instance.new("UICorner")
tradeCorner.CornerRadius = UDim.new(0, 30)
tradeCorner.Parent = tradeBtn

-- ──────────────────────────────────

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 200)
main.Position = UDim2.new(0.5, -170, 0, 54)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BackgroundTransparency = 0.25
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

local scrolling = Instance.new("ScrollingFrame")
scrolling.Size = UDim2.new(1,-10,1,-45)
scrolling.Position = UDim2.new(0,5,0,5)
scrolling.CanvasSize = UDim2.new(0,0,0,0)
scrolling.ScrollBarThickness = 3
scrolling.BackgroundTransparency = 1
scrolling.BorderSizePixel = 0
scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
scrolling.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,3)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrolling

local input = Instance.new("TextBox")
input.Size = UDim2.new(1,-65,0,35)
input.Position = UDim2.new(0,5,1,-40)
input.PlaceholderText = "Message..."
input.Text = ""
input.TextSize = 12
input.TextColor3 = Color3.new(1,1,1)
input.BackgroundColor3 = Color3.fromRGB(35,35,35)
input.BorderSizePixel = 0
input.ClearTextOnFocus = false
input.Parent = main

local send = Instance.new("TextButton")
send.Size = UDim2.new(0,55,0,35)
send.Position = UDim2.new(1,-60,1,-40)
send.Text = "Send"
send.TextSize = 12
send.TextColor3 = Color3.new(1,1,1)
send.BackgroundColor3 = Color3.fromRGB(45,45,45)
send.BorderSizePixel = 0
send.Parent = main

-- ──────────────────────────────────

showNotification = function(title, text, duration, isError)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end



-- ──────────────────────────────────
-- Botón de pausa simple
local isPaused = false

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(0, 40, 0, 39)
pauseBtn.Position = UDim2.new(0.5, 215, 0, 10)
pauseBtn.Text = "⏸"
pauseBtn.TextSize = 16
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
pauseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
pauseBtn.BackgroundTransparency = 0.25
pauseBtn.BorderSizePixel = 1
pauseBtn.Parent = gui

local pauseCorner = Instance.new("UICorner")
pauseCorner.CornerRadius = UDim.new(0, 30)
pauseCorner.Parent = pauseBtn

-- FUNCIONES DE PAUSA (definir ANTES de ser usadas)
local function shouldSkipUpdate()
    return isPaused
end

pauseBtn.MouseButton1Click:Connect(function()
    isPaused = not isPaused
    pauseBtn.Text = isPaused and "▶" or "⏸"
    pauseBtn.TextColor3 = isPaused and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 215, 0)
    
    -- Al reanudar, actualizar todo
    if not isPaused then
        task.spawn(function()
            if isPvPFinderVisible then 
                if updatePlayersListIncremental then updatePlayersListIncremental() end
            end
            if isTradeFinderVisible then 
                if updateTradePlayersListIncremental then updateTradePlayersListIncremental() end
            end
        end)
    end
end)

-- ──────────────────────────────────

local function getPlayerGears()
    local playerGears = {}
    
    local success, playerData = pcall(function()
      --  return Synchronizer:Get(player)
    end)
    
    if not success or not playerData then
        print("❌ No se pudo obtener datos del jugador para gears")
        return playerGears
    end
    
    local inventory = nil
    pcall(function()
        inventory = playerData:Get("GearInventory")
    end)
    
    if not inventory or type(inventory) ~= "table" then
        print("❌ No se encontró GearInventory o está vacío")
        return playerGears
    end
    
    -- Tabla de imágenes de gears
    local gearImages = {
        ["Santa's Sleigh"] = "rbxassetid://106575011463424",
        ["Cupid's Wings"] = "rbxassetid://125592127726740",
        ["Witch's Broom"] = "rbxassetid://118466141203194",
        ["Waverider"] = "rbxassetid://125399512921257",
        ["Radioactive Airstrike"] = "rbxassetid://73753077277254",
        ["Yin Yang Lamp"] = "rbxassetid://106398585307279",
        ["Demon's Head"] = "rbxassetid://98312790037177",
        ["Lava Blaster"] = "rbxassetid://204508521",
        ["Blackhole Bomb"] = "rbxassetid://27295735"
    }
    
    local printed = {}
    
    for _, gear in pairs(inventory) do
        if typeof(gear) == "table" and typeof(gear.GearName) == "string" then
            local gearName = gear.GearName
            -- Evitar duplicados
            if not printed[gearName] and gearImages[gearName] then
                printed[gearName] = true
                table.insert(playerGears, {
                    name = gearName,
                    image = gearImages[gearName],
                    type = "gear"
                })
                print("✅ Gear encontrado:", gearName)
            end
        end
    end
    
    print("📊 Gears poseídos:", #playerGears)
    return playerGears
end

-- ──────────────────────────────────

local function checkGlobalCooldown()
    if not globalCooldown then
        return true, 0, 0
    end
    local currentTime = os.time()
    local timePassed = currentTime - globalCooldown
    local cooldownTime = getCooldownTime()
    if timePassed < cooldownTime then
        local remainingMinutes = math.floor((cooldownTime - timePassed) / 60)
        local remainingSeconds = (cooldownTime - timePassed) % 60
        return false, remainingMinutes, remainingSeconds
    else
        globalCooldown = nil
        return true, 0, 0
    end
end

local function applyGlobalCooldown()
    globalCooldown = os.time()
    local cooldownTime = getCooldownTime()
    task.delay(cooldownTime, function()
        if globalCooldown and os.time() - globalCooldown >= cooldownTime then
            globalCooldown = nil
        end
    end)
end

-- ──────────────────────────────────

local TraitsData = {
	["Taco"] = { Display = "Taco", Icon = "rbxassetid://89041930759464", Color = Color3.fromRGB(255, 222, 89) },
	["Nyan"] = { Display = "Nyan", Icon = "rbxassetid://104229924295526", Color = Color3.fromRGB(238, 89, 255) },
	["Galactic"] = { Display = "Galactic", Icon = "rbxassetid://99181785766598", Color = Color3.fromRGB(125, 89, 255) },
	["Fireworks"] = { Display = "Fireworks", Icon = "rbxassetid://121100427764858", Color = Color3.fromRGB(255, 40, 40) },
	["Zombie"] = { Display = "Zombie", Icon = "rbxassetid://110723387483939", Color = Color3.fromRGB(74, 255, 71) },
	["Claws"] = { Display = "Claws", Icon = "rbxassetid://104964195846833", Color = Color3.fromRGB(235, 57, 26) },
	["Glitched"] = { Display = "Glitched", Icon = "rbxassetid://121332433272976", Color = Color3.fromRGB(167, 94, 223) },
	["Bubblegum"] = { Display = "Bubblegum", Icon = "rbxassetid://100601425541874", Color = Color3.fromRGB(240, 88, 254) },
	["Fire"] = { Display = "Fire", Icon = "rbxassetid://118283346037788", Color = Color3.fromRGB(255, 170, 0) },
	["Wet"] = { Display = "Wet", Icon = "rbxassetid://78474194088770", Color = Color3.fromRGB(30, 130, 220) },
	["Snowy"] = { Display = "Snowy", Icon = "rbxassetid://83627475909869", Color = Color3.fromRGB(255, 255, 255) },
	["Cometstruck"] = { Display = "Comet-struck", Icon = "rbxassetid://127455440418221", Color = Color3.fromRGB(175, 30, 220) },
	["Explosive"] = { Display = "Explosive", Icon = "rbxassetid://97725744252608", Color = Color3.fromRGB(255, 170, 0) },
	["Disco"] = { Display = "Disco", Icon = "rbxassetid://82620342632406", Color = Color3.fromRGB(232, 99, 255) },
	["10B"] = { Display = "10B", Icon = "rbxassetid://134655415681926", Color = Color3.fromRGB(255, 40, 40) },
	["Shark Fin"] = { Display = "Shark Fin", Icon = "rbxassetid://104985313532149", Color = Color3.fromRGB(30, 130, 220) },
	["Matteo Hat"] = { Display = "Matteo Hat", Icon = "rbxassetid://115664804212096", Color = Color3.fromRGB(255, 150, 29) },
	["Brazil"] = { Display = "Brazil", Icon = "rbxassetid://75650816341229", Color = Color3.fromRGB(0, 255, 0) },
	["Sleepy"] = { Display = "Sleepy", Icon = "rbxassetid://115001117876534", Color = Color3.fromRGB(39, 71, 255) },
	["Lightning"] = { Display = "Lightning", Icon = "rbxassetid://139729696247144", Color = Color3.fromRGB(0, 229, 255) },
	["UFO"] = { Display = "UFO", Icon = "rbxassetid://110910518481052", Color = Color3.fromRGB(0, 255, 0) },
	["Spider"] = { Display = "Spider", Icon = "rbxassetid://117478971325696", Color = Color3.fromRGB(255, 255, 255) },
	["Strawberry"] = { Display = "Strawberry", Icon = "rbxassetid://84731118566493", Color = Color3.fromRGB(232, 38, 56) },
	["Paint"] = { Display = "Paint", Icon = "rbxassetid://119591742504251", Color = Color3.fromRGB(255, 200, 0) },
	["Skeleton"] = { Display = "Skeleton", Icon = "rbxassetid://89591838221335", Color = Color3.fromRGB(255, 255, 255) },
	["Sombrero"] = { Display = "Sombrero", Icon = "rbxassetid://95128039793845", Color = Color3.fromRGB(250, 199, 17) },
	["Tie"] = { Display = "Tie", Icon = "rbxassetid://103610037004911", Color = Color3.fromRGB(255, 0, 0) },
	["Witch Hat"] = { Display = "Witch Hat", Icon = "rbxassetid://123964048606874", Color = Color3.fromRGB(127, 81, 207) },
	["Indonesia"] = { Display = "Indonesia", Icon = "rbxassetid://93350414974589", Color = Color3.fromRGB(251, 61, 41) },
	["Meowl"] = { Display = "Meowl", Icon = "rbxassetid://114748221761549", Color = Color3.fromRGB(255, 255, 255) },
	["RIP Gravestone"] = { Display = "RIP Gravestone", Icon = "rbxassetid://123115843719383", Color = Color3.fromRGB(255, 255, 255) },
	["Jackolantern Pet"] = { Display = "Jackolantern Pet", Icon = "rbxassetid://97054765273857", Color = Color3.fromRGB(255, 170, 0) },
	["Santa Hat"] = { Display = "Santa Hat", Icon = "rbxassetid://88375043733582", Color = Color3.fromRGB(206, 77, 76) },
	["Reindeer Pet"] = { Display = "Reindeer Pet", Icon = "rbxassetid://70894779883038", Color = Color3.fromRGB(255, 255, 255) },
	["Skibidi"] = { Display = "Skibidi", Icon = "rbxassetid://83384385019272", Color = Color3.fromRGB(255, 255, 255) },
	["26"] = { Display = "26", Icon = "rbxassetid://80468035315420", Color = Color3.fromRGB(255, 237, 44) },
	["Rose"] = { Display = "Rose", Icon = "rbxassetid://135489065859287", Color = Color3.fromRGB(217, 80, 80) },
	[" :3"] = { Display = ":3", Icon = "rbxassetid://108293878529172", Color = Color3.fromRGB(255, 255, 255) },
	["Chocolate"] = { Display = "Chocolate", Icon = "rbxassetid://81641382604997", Color = Color3.fromRGB(113, 54, 0) },
	["Halo"] = { Display = "Halo", Icon = "rbxassetid://98316436141359", Color = Color3.fromRGB(255, 209, 59) },
	["Lucky"] = { Display = "Lucky", Icon = "rbxassetid://124098467754457", Color = Color3.fromRGB(142, 227, 63) },
	["Orange Balloon"] = { Display = "Orange Balloon", Icon = "rbxassetid://83111173051279", Color = Color3.fromRGB(252, 120, 28) },
	["Green Balloon"] = { Display = "Green Balloon", Icon = "rbxassetid://75222826429094", Color = Color3.fromRGB(56, 233, 83) },
	["Blue Balloon"] = { Display = "Blue Balloon", Icon = "rbxassetid://128841931686463", Color = Color3.fromRGB(59, 128, 239) },
	["Red Balloon"] = { Display = "Red Balloon", Icon = "rbxassetid://119661964026012", Color = Color3.fromRGB(226, 42, 42) },
	["Pink Balloon"] = { Display = "Pink Balloon", Icon = "rbxassetid://114128099162490", Color = Color3.fromRGB(248, 61, 146) },
	["Rainbow Balloon"] = { Display = "Rainbow Balloon", Icon = "rbxassetid://112821854659961", Color = Color3.fromRGB(255, 255, 255) },
	["Granny"] = { Display = "Granny", Icon = "rbxassetid://73467619616299", Color = Color3.fromRGB(255, 255, 255) },
	["Bunny Ears"] = { Display = "Bunny Ears", Icon = "rbxassetid://118516289496954", Color = Color3.fromRGB(244, 92, 129) },
	["Orange Egg"] = { Display = "Orange Egg", Icon = "rbxassetid://76307362192037", Color = Color3.fromRGB(252, 120, 28) },
	["Green Egg"] = { Display = "Green Egg", Icon = "rbxassetid://94602857440295", Color = Color3.fromRGB(56, 233, 83) },
	["Blue Egg"] = { Display = "Blue Egg", Icon = "rbxassetid://109212886335786", Color = Color3.fromRGB(59, 128, 239) },
	["Pink Egg"] = { Display = "Pink Egg", Icon = "rbxassetid://133939661230277", Color = Color3.fromRGB(248, 61, 146) },
	["John Pork"] = { Display = "John Pork", Icon = "rbxassetid://117176397136731", Color = Color3.fromRGB(234, 138, 131) },
	["1 Year"] = { Display = "1 Year",  Icon = "rbxassetid://139663830647832", Color = Color3.fromRGB(255, 215, 0) },
	["Aura Shades"] = { Display = "Aura Shades", Icon = "rbxassetid://89908570233459", Color = Color3.fromRGB(255, 255, 255) } 
}

local MutationsData = {
    Gold = { DisplayText = "Gold", Color = Color3.fromRGB(255, 222, 89), RichText = '<font color="#FFDE59">' },
    Diamond = { DisplayText = "Diamond", Color = Color3.fromRGB(37, 196, 254), RichText = '<font color="#25C4FE">' },
    Bloodrot = { DisplayText = "Bloodrot", Color = Color3.fromRGB(145, 0, 27), RichText = '<font color="#8A3B3C">' },
    Rainbow = { DisplayText = "Rainbow", Color = Color3.fromRGB(255, 0, 251), RichText = '<font color="#ff00fb">' },
    Candy = { DisplayText = "Candy", Color = Color3.fromRGB(255, 70, 246), RichText = '<font color="#ff46f6">' },
    Lava = { DisplayText = "Lava", Color = Color3.fromRGB(255, 149, 0), RichText = '<font color="#ff7700">' },
    Galaxy = { DisplayText = "Galaxy", Color = Color3.fromRGB(170, 60, 255), RichText = '<font color="#aa3cff">' },
    YinYang = { DisplayText = "Yin Yang", Color = Color3.fromRGB(255, 255, 255), RichText = '<font color="#ffffff">' },
    Radioactive = { DisplayText = "Radioactive", Color = Color3.fromRGB(104, 245, 0), RichText = '<font color="#68f500">' },
    Cursed = { DisplayText = "Cursed", Color = Color3.fromRGB(245, 56, 56), RichText = '<font color="#f53838">' },
    Divine = { DisplayText = "Divine", Color = Color3.fromRGB(255, 209, 59), RichText = '<font color="#ffd13b">' },
    Cyber = { DisplayText = "Cyber", Color = Color3.fromRGB(128, 191, 255), RichText = '<fon color ="#80BFFF">' },
}

local function getMutationColor(mutationName)
    if mutationName and MutationsData[mutationName] then
        return MutationsData[mutationName].Color
    end
    return nilend
end


-- =====================================================
-- MUTATION SYSTEM (Migrado desde KingVisuals)
-- =====================================================

-- Mutations that have a MaterialVariant stud in MaterialService
local MUTATION_STUDS = {
    Galaxy      = "Galaxy Stud",
    Cursed      = "Cursed Stud",
    Divine      = "Divine Stud",
    Radioactive = "Radioactive Stud",
    Gold        = "Gold Stud",
    Diamond     = "Diamond",
    Bloodrot    = "Bloodrot",
    Candy       = "Candy",
    Lava        = "Lava",
    YinYang     = "YinYang",
    Cyber       = "Tech Stud",
}

-- Mutation palettes (Color attribute index 1..6)
local MUTATION_PALETTES = {
    Gold        = {Color3.fromRGB(237,178,0),   Color3.fromRGB(237,194,86), Color3.fromRGB(215,111,1), Color3.fromRGB(139,74,0),   Color3.fromRGB(255,164,164),Color3.fromRGB(255,244,190)},
    Diamond     = {Color3.fromRGB(37,196,254),  Color3.fromRGB(116,212,254),Color3.fromRGB(28,137,254),Color3.fromRGB(21,64,254),  Color3.fromRGB(160,162,254),Color3.fromRGB(176,255,252)},
    Bloodrot    = {Color3.fromRGB(145,0,27),    Color3.fromRGB(154,94,100), Color3.fromRGB(75,0,7),    Color3.fromRGB(72,0,2),     Color3.fromRGB(121,112,112),Color3.fromRGB(255,152,154)},
    Candy       = {Color3.fromRGB(255,105,180), Color3.fromRGB(255,182,193),Color3.fromRGB(200,50,150),Color3.fromRGB(255,20,147), Color3.fromRGB(255,200,220),Color3.fromRGB(255,240,245)},
    Lava        = {Color3.fromRGB(200,50,0),    Color3.fromRGB(255,100,0),  Color3.fromRGB(150,20,0),  Color3.fromRGB(100,10,0),   Color3.fromRGB(255,160,0),  Color3.fromRGB(255,220,100)},
    Galaxy      = {Color3.fromRGB(60,0,120),    Color3.fromRGB(100,0,180),  Color3.fromRGB(30,0,80),   Color3.fromRGB(180,0,255),  Color3.fromRGB(80,0,160),   Color3.fromRGB(200,150,255)},
    YinYang     = {Color3.fromRGB(18,18,22),    Color3.fromRGB(20,20,28),   Color3.fromRGB(230,230,240), Color3.fromRGB(230,230,240),Color3.fromRGB(128,128,128),Color3.fromRGB(24,24,30)},
    Radioactive = {Color3.fromRGB(100,255,0),   Color3.fromRGB(150,255,50), Color3.fromRGB(50,200,0),  Color3.fromRGB(0,150,0),    Color3.fromRGB(200,255,100),Color3.fromRGB(230,255,180)},
    Cursed      = {Color3.fromRGB(255,23,23),   Color3.fromRGB(180,0,0),    Color3.fromRGB(120,0,0),   Color3.fromRGB(80,0,0),     Color3.fromRGB(255,100,100),Color3.fromRGB(255,180,180)},
    Divine      = {Color3.fromRGB(255,215,0),   Color3.fromRGB(255,255,200),Color3.fromRGB(200,160,0), Color3.fromRGB(255,240,150),Color3.fromRGB(18,18,22),Color3.fromRGB(255,250,220)},
    Cyber       = {Color3.fromRGB(62,155,255),  Color3.fromRGB(0,100,200),  Color3.fromRGB(0,50,150),  Color3.fromRGB(0,150,255),  Color3.fromRGB(100,200,255),Color3.fromRGB(150,230,255)},
}

-- Get shared animals module (for proper mutation application)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = ReplicatedStorage
local _sharedAnimals = nil

local function GetSharedAnimals()
    if not _sharedAnimals then
        local ok, result = pcall(function() 
            return require(RS.Shared.Animals) 
        end)
        if ok then 
            _sharedAnimals = result 
        else
            -- NO mostrar el error, solo asignar nil silenciosamente
            _sharedAnimals = nil
        end
    end
    return _sharedAnimals
end

-- =====================================================
-- FULL MUTATION APPLICATION (KingVisuals version)
-- =====================================================
local function ApplyMutationFull(model, animalName, mutName)
    if not mutName or mutName == "None" then return end

    --[[ Try to use game's SharedAnimals first (most accurate)
    local sa = GetSharedAnimals()
    if sa then
        local ok, err = pcall(function() sa:ApplyMutation(model, animalName, mutName) end)
        if ok then return end
    end
    
    ]]

    -- Fallback: manual implementation
    local mutData = nil
    pcall(function() mutData = require(RS.Datas.Mutations) end)
    
    local palettes = MUTATION_PALETTES
    local mutSurface = RS.MutationSurfaces and RS.MutationSurfaces:FindFirstChild(animalName)
    local vfxFolder = RS.Vfx and RS.Vfx:FindFirstChild(mutName)

    -- Rainbow: tag-based
    if mutName == "Rainbow" then
        model:AddTag("RainbowModel")
    else
        -- Apply palette colors
        local palette = MUTATION_PALETTES[mutName]
        if palette then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local mv = v.MaterialVariant
                        if mv == "Strawberry Stud Light" or mv == "Strawberry Stud Dark" then
                            v.MaterialVariant = mutName.." Strawberry Stud Light"
                            return
                        end
                        local colorIdx = tonumber(
                            v:GetAttribute(("%*Color"):format(mutName)) or
                            v:GetAttribute("Color") or 1) or 1
                        colorIdx = math.clamp(colorIdx, 1, #palette)
                        local col = palette[colorIdx] or palette[1]
                        if not col then return end
                        local surfApp = v:FindFirstChildOfClass("SurfaceAppearance")
                        if surfApp then
                            surfApp:Destroy()
                            if mutSurface then
                                local newSurf = mutSurface:Clone()
                                if mutName == "Divine" then
                                    newSurf.Color = palette[1] or col
                                else
                                    newSurf.Color = col
                                end
                                newSurf.Parent = v
                            end
                        else
                            v.Color = col
                        end
                        if v:GetAttribute("Neon") then
                            v.Material = Enum.Material.Neon
                        end
                    end)
                end
            end
        end

        -- Special post-processing per mutation
        if mutName == "Galaxy" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        if (v:GetAttribute("GalaxyColor") or v:GetAttribute("Color") or 1) == 1 then
                            v.Material = Enum.Material.Neon
                        end
                        v.MaterialVariant = "Galaxy Stud"
                    end)
                end
            end

        elseif mutName == "Lava" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        if (v:GetAttribute("LavaColor") or v:GetAttribute("Color") or 1) == 1 then
                            v.Material = Enum.Material.Neon
                        end
                    end)
                end
            end

        elseif mutName == "YinYang" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local c = v:GetAttribute("YinYangColor") or v:GetAttribute("Color") or 1
                        if c == 3 or c == 4 then
                            v.Material = Enum.Material.Neon
                        end
                    end)
                end
            end

        elseif mutName == "Divine" then
            local emissive = model:GetAttribute("EmissiveStrength") or 2
            for _, v in model:GetDescendants() do
                if v:IsA("SurfaceAppearance") then
                    pcall(function() v.EmissiveStrength = emissive end)
                end
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local c = v:GetAttribute("DivineColor") or v:GetAttribute("Color") or 1
                        if c == 2 then v.Material = Enum.Material.Neon end
                        local mode = v:GetAttribute("Divine*MaterialMode") or model:GetAttribute("Divine*MaterialMode")
                        if v:GetAttribute("Divine*Stud") == false then
                            v.MaterialVariant = ""
                        elseif v.MaterialVariant == "Custom Stud" or v:GetAttribute("Divine*Stud") == true then
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Divine Stud"
                        elseif c ~= 2 and c ~= 6 then
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Divine Stud"
                        end
                    end)
                end
            end

        elseif mutName == "Radioactive" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local c = v:GetAttribute("RadioactiveColor") or v:GetAttribute("Color") or 1
                        if c == 2 then v.Material = Enum.Material.Neon end
                        if v:GetAttribute("Radioactive*Stud") == false then
                            v.MaterialVariant = ""
                        elseif v.MaterialVariant == "Custom Stud" or v:GetAttribute("Radioactive*Stud") == true then
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Radioactive Stud"
                        elseif c ~= 2 and c ~= 6 then
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Radioactive Stud"
                        end
                    end)
                end
            end

        elseif mutName == "Cursed" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local c = v:GetAttribute("CursedColor") or v:GetAttribute("Color") or 1
                        if c == 2 then v.Material = Enum.Material.Neon end
                        if v:GetAttribute("Cursed*Stud") == false then
                            v.MaterialVariant = ""
                        elseif v.MaterialVariant == "Custom Stud" or v:GetAttribute("Cursed*Stud") == true or
                               (c ~= 2 and c ~= 6) then
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Cursed Stud"
                            v.Color = Color3.fromRGB(255, 23, 23)
                        end
                        local sa2 = v:FindFirstChildOfClass("SurfaceAppearance")
                        if sa2 then
                            if not v:GetAttribute("Cursed*IgnoreSurfaceColor") then
                                sa2.Color = Color3.fromRGB(255, 23, 23)
                            end
                            if v:GetAttribute("IgnoreSurface") then sa2:Destroy() end
                        end
                    end)
                end
            end

        elseif mutName == "Cyber" then
            for _, v in model:GetDescendants() do
                if v:IsA("BasePart") and v.Transparency ~= 1 and not v:GetAttribute("IgnoreColor") then
                    pcall(function()
                        local c = tonumber(v:GetAttribute("Cyber*Color") or v:GetAttribute("Color") or 1) or 1
                        local surfApp = v:FindFirstChildOfClass("SurfaceAppearance")
                        if v:GetAttribute("Eyes") then
                            v.Color = Color3.fromRGB(62, 155, 255)
                            v.Transparency = 0.25
                            v.Material = Enum.Material.Neon
                            return
                        end
                        if c == 7 then
                            v.Material = Enum.Material.Neon
                        elseif c == 4 then
                            v.Transparency = 0.5
                            v.Material = Enum.Material.SmoothPlastic
                            v.MaterialVariant = "Tech Stud"
                            v.Color = Color3.fromRGB(62, 155, 255)
                        elseif c == 3 then
                            v.Material = Enum.Material.Glass
                            v.Transparency = 0.5
                            if not surfApp and v.ClassName == "MeshPart" then
                                Instance.new("SurfaceAppearance").Parent = v
                            end
                        elseif c == 1 then
                            v.Material = Enum.Material.Glass
                            v.Transparency = 0.25
                            if not surfApp and v.ClassName == "MeshPart" then
                                Instance.new("SurfaceAppearance").Parent = v
                            end
                        end
                        surfApp = v:FindFirstChildOfClass("SurfaceAppearance")
                        if surfApp then
                            local vol = v.Size.X * v.Size.Y * v.Size.Z
                            v.Transparency = 0
                            v.Material = Enum.Material.Neon
                            surfApp.AlphaMode = Enum.AlphaMode.Overlay
                            surfApp.EmissiveTint = Color3.fromRGB(255, 255, 255)
                            if vol > 3 then
                                surfApp.Color = Color3.fromRGB(35, 75, 115)
                                surfApp.EmissiveStrength = 50
                            else
                                surfApp.Color = Color3.fromRGB(0, 25, 30)
                                surfApp.EmissiveStrength = 25
                            end
                        end
                    end)
                end
            end
        end
    end

    -- Apply VFX
    if vfxFolder then
        local vfxInst = model:FindFirstChild("VfxInstance")
        if vfxInst then
            for _, vfx in vfxFolder:GetChildren() do
                pcall(function() vfx:Clone().Parent = vfxInst end)
            end
        end
    end
end

-- =====================================================
-- REPLACE YOUR OLD applyMutationEffects WITH THIS
-- =====================================================
-- Comenta o elimina tu vieja función applyMutationEffects
-- y usa esta en su lugar:

local function applyMutationEffects(model, mutationName, animalName)
    if not mutationName or mutationName == "None" then return end
    ApplyMutationFull(model, animalName or model.Name, mutationName)
end


-- ──────────────────────────────────

local function createTraitIcons(traitsList, parentFrame)
	if not traitsList or type(traitsList) ~= "table" or #traitsList == 0 then
		return
	end
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(0, 0, 0, 22)
	iconContainer.BackgroundTransparency = 1
	iconContainer.AutomaticSize = Enum.AutomaticSize.X
	iconContainer.ZIndex = 2000
	iconContainer.Parent = parentFrame
	local iconLayout = Instance.new("UIListLayout")
	iconLayout.FillDirection = Enum.FillDirection.Horizontal
	iconLayout.Padding = UDim.new(0, 3)
	iconLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	iconLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	iconLayout.Parent = iconContainer
	for _, traitName in ipairs(traitsList) do
		local traitData = TraitsData[traitName]
		if traitData and traitData.Icon then
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.new(0, 18, 0, 18)
			icon.Image = traitData.Icon
			icon.BackgroundTransparency = 1
			icon.ZIndex = 2000
			icon.Parent = iconContainer
			local tooltip = Instance.new("TextLabel")
			tooltip.Size = UDim2.new(0, 90, 0, 22)
			tooltip.Position = UDim2.new(0, -40, 1, 2)
			tooltip.Text = traitData.Display
			tooltip.TextSize = 10
			tooltip.TextColor3 = Color3.new(1, 1, 1)
			tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			tooltip.BackgroundTransparency = 0.2
			tooltip.BorderSizePixel = 0
			tooltip.Visible = false
			tooltip.ZIndex = 3000
			tooltip.Parent = icon
			local tooltipCorner = Instance.new("UICorner")
			tooltipCorner.CornerRadius = UDim.new(0, 4)
			tooltipCorner.Parent = tooltip
			icon.MouseEnter:Connect(function()
				tooltip.Visible = true
				tooltip.ZIndex = 3000
				if tooltip.Parent then
					tooltip.Parent.ZIndex = 3000
				end
			end)
			icon.MouseLeave:Connect(function()
				tooltip.Visible = false
			end)
		end
	end
end

-- ──────────────────────────────────

-- ────────────────────────────────────────────────────────────
-- SISTEMA DE REMOTES CON LarpNet (Solo Duel y Trade con GUID)
-- ────────────────────────────────────────────────────────────

local Netty = game.ReplicatedStorage.Packages.Net

local remoteCache = {
    scanned = false,
    duelRemote = nil,
    tradeRemote = nil
}

-- Función para identificar si un nombre es un hash (32+ caracteres sin "/")
local function isHashedName(name)
    if not name or type(name) ~= "string" then return false end
    local withoutPrefix = name:match("^RF/(.+)$") or name
    return #withoutPrefix >= 32 and not withoutPrefix:find("/")
end

-- Función principal para encontrar remotes por su path
local function LarpNet(path)
    local children = Netty:GetChildren()
    local labelIndex = nil

    -- Encontrar el label (carpeta con el nombre legible)
    for i, v in ipairs(children) do
        if v.Name == "RF/" .. path then
            labelIndex = i
            break
        end
    end

    if not labelIndex then 
        return nil 
    end

    -- Buscar el RemoteFunction hasheado más cercano al label
    for offset = 1, 5 do
        -- Buscar hacia atrás primero (donde normalmente está el remote)
        local backIdx = labelIndex - offset
        if backIdx >= 1 then
            local v = children[backIdx]
            if v and v:IsA("RemoteFunction") and isHashedName(v.Name) then
                return v
            end
        end
        -- Buscar hacia adelante como fallback
        local fwdIdx = labelIndex + offset
        if fwdIdx <= #children then
            local v = children[fwdIdx]
            if v and v:IsA("RemoteFunction") and isHashedName(v.Name) then
                return v
            end
        end
    end

    return nil
end

-- Escanear y cachear los remotes
local function scanAndCacheRemotes()
    if remoteCache.scanned then
        return true
    end
    
    
    
    -- Buscar solo Duel y Trade
    remoteCache.duelRemote = LarpNet("DuelsMachineService/Invite")
    remoteCache.tradeRemote = LarpNet("TradeService/Invite")
    
    remoteCache.scanned = true
    
    -- Mostrar resultados
    if remoteCache.duelRemote then
        print("✅ Duel Remote guardado:", remoteCache.duelRemote.Name)
    else
        print("❌ Duel Remote NO encontrado")
    end
    
    if remoteCache.tradeRemote then
        print("✅ Trade Remote guardado:", remoteCache.tradeRemote.Name)
    else
        print("❌ Trade Remote NO encontrado")
    end
    
    return remoteCache.duelRemote ~= nil or remoteCache.tradeRemote ~= nil
end

-- ────────────────────────────────────────────────────────────
-- FUNCIONES DE ENVÍO
-- ────────────────────────────────────────────────────────────

-- Enviar invitación de duelo
local function sendDuelInvitationOptimized(targetUserId, targetUsername)
    if not remoteCache.scanned then
        scanAndCacheRemotes()
    end
    
    if not remoteCache.duelRemote then
        showNotification("❌ Duel Failed", "Remote de duelo no encontrado", 4, true)
        return false
    end
    
    local success, result = pcall(function()
        return remoteCache.duelRemote:InvokeServer(targetUserId)
    end)
    
    if success then
        showNotification("⚔️ Duel Invitation", string.format("Enviada a %s", targetUsername), 4, false)
        return true
    else
        showNotification("❌ Duel Failed", "Error: " .. tostring(result), 4, true)
        return false
    end
end

-- Enviar solicitud de trade (CON GUID + userId)
local function sendTradeRequestOptimized(targetUserId, targetUsername, animalName) -- animalName
    if not remoteCache.scanned then
        scanAndCacheRemotes()
    end
    
    if not remoteCache.tradeRemote then
        showNotification("❌ Trade Failed", "Remote de trade no encontrado", 4, true)
        return false
    end
    
    -- GUID específico para trades
    local TRADE_GUID = "afb005f9-6e81-4e0a-8bb0-3555938a9658"
    
    -- Enviar con GUID + userId
    local success, result = pcall(function()
        return remoteCache.tradeRemote:InvokeServer(TRADE_GUID, targetUserId)
    end)
    
    if success then
        showNotification("📦 Trade Request", string.format("Enviada a %s", targetUsername), 4, false)
        return true
    else
        showNotification("❌ Trade Failed", "Error: " .. tostring(result), 4, true)
        return false
    end
end

-- ────────────────────────────────────────────────────────────
-- INICIALIZACIÓN AUTOMÁTICA
-- ────────────────────────────────────────────────────────────

task.spawn(function()
    task.wait(2)
    scanAndCacheRemotes()
end)

-- ──────────────────────────────────

local _lockedPlot = nil

local function getMyPlot()
    if _lockedPlot and _lockedPlot.Parent then
        return _lockedPlot
    end

    _lockedPlot = nil

    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        warn("[getMyPlot] No existe workspace.Plots")
        return nil
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if not hrp then
        warn("[getMyPlot] No se encontró HumanoidRootPart")
        return nil
    end

    local closestPlot = nil
    local closestDistance = math.huge

    for _, plot in ipairs(plots:GetChildren()) do
        local spawn = plot:FindFirstChild("Spawn")

        if spawn and spawn:IsA("BasePart") then
            local distance = (spawn.Position - hrp.Position).Magnitude

            if distance < closestDistance then
                closestDistance = distance
                closestPlot = plot
            end
        end
    end

    if closestPlot then
        _lockedPlot = closestPlot

        print(
            "[getMyPlot] Plot detectado:",
            closestPlot.Name,
            "distancia:",
            math.floor(closestDistance)
        )
    end

    return closestPlot
end


local function getAnimalFullData(animalModelName)
    local myPlot = getMyPlot()
    if not myPlot then
        warn("[getAnimalFullData] No se encontró el plot")
        return nil
    end

    local sync = require(RS.Packages.Synchronizer)

    local result = nil
    local finished = false

    sync:WaitAndCall(myPlot.Name, function(channel)
        if not channel then
            finished = true
            return
        end

        local animalList = channel:Get("AnimalList")

        if type(animalList) ~= "table" then
            warn("[getAnimalFullData] AnimalList no disponible en:", myPlot.Name)
            finished = true
            return
        end

        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table"
                and animalData.Index == animalModelName then

                local animalInfo = AnimalsData[animalModelName]

                if animalInfo then
                    local mutation =
                        animalData.Mutation or "None"

                    local traitsData =
                        animalData.Traits

                    local genValue =
                        AnimalsShared:GetGeneration(
                            animalModelName,
                            animalData.Mutation,
                            traitsData,
                            nil
                        )

                    local genText =
                        "$"
                        .. NumberUtils:ToString(genValue)
                        .. "/s"

                    local traits = "None"

                    if type(traitsData) == "table"
                        and #traitsData > 0 then

                        traits = table.concat(
                            traitsData,
                            ", "
                        )
                    end

                    result = {
                        name =
                            animalInfo.DisplayName
                            or animalModelName,

                        modelName = animalModelName,

                        rarity = animalInfo.Rarity,

                        genValue = genValue,

                        genText = genText,

                        mutation = mutation,

                        traits = traits,

                        slot = tostring(slot)
                    }

                    break
                end
            end
        end

        finished = true
    end)

    -- Si el canal ya existía, WaitAndCall ejecuta el callback inmediatamente.
    if finished then
        return result
    end

    return nil
end

-- ──────────────────────────────────
sendAnimalToPvPAPI = function(animalName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    local animalData = getAnimalFullData(animalName)
    
    -- Solo verificar conexión, no autenticación
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = animalName,
        animalDisplayName = animalData and animalData.name or animalName,
        rarity = animalData and animalData.rarity or "Unknown",
        genValue = animalData and animalData.genValue or 0,
        genText = animalData and animalData.genText or "$0/s",
        mutation = animalData and animalData.mutation or "None",
        traits = animalData and animalData.traits or "None",
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = "pending_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999)),
        userId = player.UserId,
        username = player.Name,
        animal = animalName,
        animalDisplayName = animalData and animalData.name or animalName,
        rarity = animalData and animalData.rarity or "Unknown",
        genText = animalData and animalData.genText or "$0/s",
        mutation = animalData and animalData.mutation or "None",
        traits = animalData and animalData.traits or "None",
        timestamp = os.time()
    }
    
    table.insert(cachedDuelsData, 1, newEntry)
    if #cachedDuelsData > MAX_DUELS_CARDS then
        table.remove(cachedDuelsData)
    end
    
    if not isPaused and isPvPFinderVisible and pvpGuiInstance then
        updatePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_duel",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        showNotification("✅ Duelo Publicado", string.format("%s añadido a la lista", animalName), 2)
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        return false
    end
end

-- ──────────────────────────────────


sendAnimalToTradeAPI = function(animalName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    local animalData = getAnimalFullData(animalName)
    
    -- Solo verificar conexión, no autenticación
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local localId = "local_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    pendingOwnSubmissions[localId] = true
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = animalName,
        status = "looking",
        animalDisplayName = animalData and animalData.name or animalName,
        rarity = animalData and animalData.rarity or "Unknown",
        genValue = animalData and animalData.genValue or 0,
        genText = animalData and animalData.genText or "$0/s",
        mutation = animalData and animalData.mutation or "None",
        traits = animalData and animalData.traits or "None",
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = localId,
        userId = player.UserId,
        username = player.Name,
        animal = animalName,
        status = "looking",
        animalDisplayName = animalData and animalData.name or animalName,
        rarity = animalData and animalData.rarity or "Unknown",
        genText = animalData and animalData.genText or "$0/s",
        mutation = animalData and animalData.mutation or "None",
        traits = animalData and animalData.traits or "None",
        timestamp = os.time()
    }
    
    table.insert(cachedTradesData, 1, newEntry)
    if #cachedTradesData > MAX_TRADES_CARDS then
        table.remove(cachedTradesData)
    end
    
    if not isPaused and isTradeFinderVisible and tradeGuiInstance then
        updateTradePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_trade",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        pendingOwnSubmissions[localId] = nil
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
end


-- ──────────────────────────────────

-- ========== FUNCIONES PARA ENVIAR SKINS ==========

sendSkinToPvPAPI = function(skinName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = skinName,  -- Usamos el mismo campo 'animal' para compatibilidad
        animalDisplayName = "✨ " .. skinName .. " (Skin)",
        rarity = "Skin",
        genText = "🌟 Skin",
        mutation = "None",
        traits = "None",
        type = "skin",  -- Campo adicional para identificar que es skin
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = "pending_skin_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999)),
        userId = player.UserId,
        username = player.Name,
        animal = skinName,
        animalDisplayName = "✨ " .. skinName .. " (Skin)",
        rarity = "Skin",
        genText = "🌟 Skin",
        mutation = "None",
        traits = "None",
        timestamp = os.time()
    }
    
    table.insert(cachedDuelsData, 1, newEntry)
    if #cachedDuelsData > MAX_DUELS_CARDS then
        table.remove(cachedDuelsData)
    end
    
    if not isPaused and isPvPFinderVisible and pvpGuiInstance then
        updatePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_duel",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        showNotification("✅ Skin Publicada", string.format("%s añadida a la lista PvP", skinName), 2)
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        return false
    end
end

-- ──────────────────────────────────


sendSkinToTradeAPI = function(skinName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local localId = "local_skin_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    pendingOwnSubmissions[localId] = true
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = skinName,
        status = "looking",
        animalDisplayName = "✨ " .. skinName .. " (Skin)",
        rarity = "Skin",
        genText = "🌟 Skin",
        mutation = "None",
        traits = "None",
        type = "skin",
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = localId,
        userId = player.UserId,
        username = player.Name,
        animal = skinName,
        status = "looking",
        animalDisplayName = "✨ " .. skinName .. " (Skin)",
        rarity = "Skin",
        genText = "🌟 Skin",
        mutation = "None",
        traits = "None",
        timestamp = os.time()
    }
    
    table.insert(cachedTradesData, 1, newEntry)
    if #cachedTradesData > MAX_TRADES_CARDS then
        table.remove(cachedTradesData)
    end
    
    if not isPaused and isTradeFinderVisible and tradeGuiInstance then
        updateTradePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_trade",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        pendingOwnSubmissions[localId] = nil
        showNotification("✅ Skin Publicada", string.format("%s añadida a la lista de Trades", skinName), 2)
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
end


-- ──────────────────────────────────


sendGearToPvPAPI = function(gearName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = gearName,
        animalDisplayName = "⚙️ " .. gearName .. " ",
        rarity = "Gear",
        genText = "⚙️ Gear",
        mutation = "None",
        traits = "None",
        type = "gear",
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = "pending_gear_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999)),
        userId = player.UserId,
        username = player.Name,
        animal = gearName,
        animalDisplayName = " " .. gearName .. " (Gear)",
        rarity = "Gear",
        genText = "⚙️ Gear",
        mutation = "None",
        traits = "None",
        type = "gear",
        timestamp = os.time()
    }
    
    table.insert(cachedDuelsData, 1, newEntry)
    if #cachedDuelsData > MAX_DUELS_CARDS then
        table.remove(cachedDuelsData)
    end
    
    if not isPaused and isPvPFinderVisible and pvpGuiInstance then
        updatePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_duel",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        showNotification("✅ Gear Publicado", string.format("%s añadido a la lista PvP", gearName), 2)
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        return false
    end
end

sendGearToTradeAPI = function(gearName)
    if isUserVIP(player.Name) then
        addToVIPHighlight(player.Name)
    end
    
    if not wsConnected then
        showNotification("❌ WebSocket Error", "Sin conexión al servidor", 3, true)
        return false
    end
    
    local localId = "local_gear_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    pendingOwnSubmissions[localId] = true
    
    local data = {
        userId = player.UserId,
        username = player.Name,
        animal = gearName,
        status = "looking",
        animalDisplayName = "🔧 " .. gearName .. " (Gear)",
        rarity = "Gear",
        genText = "⚙️ Gear",
        mutation = "None",
        traits = "None",
        type = "gear",
        timestamp = os.time()
    }
    
    -- Caché local
    local newEntry = {
        id = localId,
        userId = player.UserId,
        username = player.Name,
        animal = gearName,
        status = "looking",
        animalDisplayName = " " .. gearName .. " (Gear)",
        rarity = "Gear",
        genText = "⚙️ Gear",
        mutation = "None",
        traits = "None",
        type = "gear",
        timestamp = os.time()
    }
    
    table.insert(cachedTradesData, 1, newEntry)
    if #cachedTradesData > MAX_TRADES_CARDS then
        table.remove(cachedTradesData)
    end
    
    if not isPaused and isTradeFinderVisible and tradeGuiInstance then
        updateTradePlayersListIncremental()
    end
    
    -- Enviar por WebSocket
    local sendMethod = wsConnection.Send or wsConnection.send
    if not sendMethod then
        showNotification("❌ Error", "WebSocket no soporta envío", 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
    
    local message = HttpService:JSONEncode({
        type = "new_trade",
        data = data
    })
    
    local success, err = pcall(function()
        sendMethod(wsConnection, message)
    end)
    
    if success then
        pendingOwnSubmissions[localId] = nil
        showNotification("✅ Gear Publicado", string.format("%s añadido a la lista de Trades", gearName), 2)
        return true
    else
        showNotification("❌ Error", "Falló al enviar: " .. tostring(err), 3, true)
        pendingOwnSubmissions[localId] = nil
        return false
    end
end

-- ──────────────────────────────────

local function findAllAnimalsInDebris(animalName)
    local debris = workspace:FindFirstChild("Debris")
    if not debris then return {} end
    local foundAnimals = {}
    for _, fastOverhead in pairs(debris:GetChildren()) do
        if fastOverhead.Name == "FastOverheadTemplate" then
            local animalOverhead = fastOverhead:FindFirstChild("AnimalOverhead")
            if animalOverhead then
                local generation = animalOverhead:FindFirstChild("Generation")
                local displayName = animalOverhead:FindFirstChild("DisplayName")
                if displayName and displayName:IsA("TextLabel") then
                    local displayText = displayName.Text or ""
                    local cleanDisplay = string.gsub(string.lower(displayText), "%s+", "")
                    local cleanAnimal = string.gsub(string.lower(animalName), "%s+", "")
                    if string.find(cleanDisplay, cleanAnimal) or string.find(cleanAnimal, cleanDisplay) then
                        local genText = ""
                        if generation and generation:IsA("TextLabel") then
                            genText = generation.Text or ""
                        end
                        table.insert(foundAnimals, {
                            Generation = genText,
                            DisplayName = displayText,
                            OriginalName = animalName
                        })
                    end
                end
            end
        end
    end
    return foundAnimals
end

-- ──────────────────────────────────

local function showAnimalSelectionMenu(isTradeMode)
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    
    -- ========== DATOS DE SKINS ==========
    local skinImages = {
        ["Aquatic"] = "rbxassetid://100987404805977",
        ["Bunny Basket"] = "rbxassetid://103854752453800",
        ["Candy"] = "rbxassetid://95295980395057",
        ["Christmas"] = "rbxassetid://82581266228221",
        ["Cursed"] = "rbxassetid://103442397385310",
        ["Cyber"] = "rbxassetid://70704569365791",
        ["Diamond"] = "rbxassetid://129081602059395",
        ["Divine"] = "rbxassetid://123619895457714",
        ["Easter"] = "rbxassetid://101004973484528",
        ["Galaxy"] = "rbxassetid://106862562813227",
        ["Gingerbread"] = "rbxassetid://85315107374050",
        ["Gold"] = "rbxassetid://80252148814852",
        ["Halloween"] = "rbxassetid://78069578479722",
        ["Headless"] = "rbxassetid://127794717088326",
        ["John Pork"] = "rbxassetid://103526057900666",
        ["Lava"] = "rbxassetid://97577086368828",
        ["Lucky"] = "rbxassetid://99633507283702",
        ["Meowl"] = "rbxassetid://106055459107464",
        ["Pot of Gold"] = "rbxassetid://104285709377050",
        ["Radioactive"] = "rbxassetid://102411245785930",
        ["Rainbow"] = "rbxassetid://131742943178952",
        ["Octo"] = "rbxassetid://117203223532989",
        ["Rose"] = "rbxassetid://87697470314885",
        ["Skibidi"] = "rbxassetid://115813831981880",
        ["Spyder"] = "rbxassetid://119443420474301",
        ["Strawberry"] = "rbxassetid://121254385285365",
        ["Summer"] = "rbxassetid://121389162032475",
        ["Taco"] = "rbxassetid://109613830616820",
        ["Valentines"] = "rbxassetid://72064872429166",
        ["YinYang"] = "rbxassetid://123280721293513"
    }
    
    -- Obtener skins del jugador
    local playerOwnedSkins = {}
    local success, playerData = pcall(function()
      --  return Synchronizer:Get(player)
    end)
    
    if success and playerData then
        local IndexLoaded = false
        local Index = nil
        pcall(function()
            Index = require(ReplicatedStorage.Datas.Index)
            IndexLoaded = true
        end)
        
        if IndexLoaded and Index then
            for skinName in pairs(Index) do
                if skinImages[skinName] then
                    local owns = false
                    pcall(function()
                        owns = BaseSkins.Owns(playerData, skinName)
                    end)
                    if owns then
                        table.insert(playerOwnedSkins, {
                            name = skinName,
                            image = skinImages[skinName]
                        })
                        print("✅ Skin encontrada:", skinName)
                    end
                end
            end
        end
    end
    
    -- ========== CREAR GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlotInventoryGUI"
    screenGui.Parent = gui
    screenGui.ResetOnSpawn = false
    
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
    scrollingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    scrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    scrollingFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    scrollingFrame.BackgroundTransparency = 0.2
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = screenGui
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.23, 0, 0, 185)
    gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollingFrame
    
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, 10)
    uiPadding.Parent = scrollingFrame
    
    -- ========== FUNCIÓN PARA CREAR TARJETA DE SKIN (SOLO IMAGEN) ==========
    local function createSkinCard(skinName, skinImage, container, layoutOrder)
        local itemFrame = Instance.new("Frame")
        itemFrame.BackgroundTransparency = 1
        itemFrame.LayoutOrder = layoutOrder
        itemFrame.Parent = container
        
        -- Área de preview (solo imagen)
        local previewFrame = Instance.new("Frame")
        previewFrame.Size = UDim2.new(1, 0, 0.75, 0)
        previewFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        previewFrame.BackgroundTransparency = 0.3
        previewFrame.BorderSizePixel = 1
        previewFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
        previewFrame.Parent = itemFrame
        
        local previewCorner = Instance.new("UICorner")
        previewCorner.CornerRadius = UDim.new(0, 8)
        previewCorner.Parent = previewFrame
        
        -- Imagen de la skin
        local skinImageLabel = Instance.new("ImageLabel")
        skinImageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
        skinImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        skinImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        skinImageLabel.BackgroundTransparency = 1
        skinImageLabel.Image = skinImage
        skinImageLabel.ScaleType = Enum.ScaleType.Fit
        skinImageLabel.Parent = previewFrame
        
        -- Nombre de la skin
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 0, 0.78, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "✨ " .. skinName
        nameLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = itemFrame
        
        -- Botón de acción
        local actionButton = Instance.new("TextButton")
        actionButton.Size = UDim2.new(0.8, 0, 0.18, 0)
        actionButton.Position = UDim2.new(0.5, 0, 0.88, 0)
        actionButton.AnchorPoint = Vector2.new(0.5, 0.5)
        actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        
        local canAdd, minutes, seconds = checkGlobalCooldown()
        if canAdd then
            actionButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
        else
            actionButton.Text = string.format("⏳ %d:%02d", minutes, seconds)
        end
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextScaled = true
        actionButton.Parent = itemFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = actionButton
        
        -- Actualizar texto del botón según cooldown
        task.spawn(function()
            while actionButton and actionButton.Parent do
                local canAdd, mins, secs = checkGlobalCooldown()
                if not canAdd then
                    actionButton.Text = string.format("⏳ %d:%02d", mins, secs)
                    actionButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
                else
                    if actionButton.Text ~= (isTradeMode and "📦 OFFER" or "⚔️ ADD") then
                        actionButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
                        actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    end
                end
                task.wait(1)
            end
        end)
        
        -- Acción del botón
        actionButton.MouseButton1Click:Connect(function()
            local canAdd, remainingMinutes, remainingSeconds = checkGlobalCooldown()
            if not canAdd then
                showNotification("⏳ Cooldown Global", string.format("Espera %d:%02d antes de añadir otro ítem", remainingMinutes, remainingSeconds), 3)
                return
            end
            
            actionButton.Text = isTradeMode and "✅ OFFERED!" or "✅ ADDED!"
            actionButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            showNotification("✨ Skin Añadida", "Añadida: " .. skinName, 2)
            applyGlobalCooldown()
            
            task.spawn(function()
                if isTradeMode then
                    sendSkinToTradeAPI(skinName)
                else
                    sendSkinToPvPAPI(skinName)
                end
            end)
            
            task.wait(0.5)
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            task.wait(0.5)
            if isTradeMode then
                openTradeFinder()
            else
                openPvPFinder()
            end
        end)
        
        return itemFrame
    end
    
    -- ========== FUNCIÓN PARA CREAR TARJETA DE GEAR ==========
local function createGearCard(gearName, gearImage, container, layoutOrder)
    local itemFrame = Instance.new("Frame")
    itemFrame.BackgroundTransparency = 1
    itemFrame.LayoutOrder = layoutOrder
    itemFrame.Parent = container
    
    -- Área de preview (imagen del gear)
    local previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, 0, 0.75, 0)
    previewFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    previewFrame.BackgroundTransparency = 0.3
    previewFrame.BorderSizePixel = 1
    previewFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    previewFrame.Parent = itemFrame
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = previewFrame
    
    -- Imagen del gear
    local gearImageLabel = Instance.new("ImageLabel")
    gearImageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
    gearImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    gearImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    gearImageLabel.BackgroundTransparency = 1
    gearImageLabel.Image = gearImage
    gearImageLabel.ScaleType = Enum.ScaleType.Fit
    gearImageLabel.Parent = previewFrame
    
    -- Nombre del gear
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 0, 0.78, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = " " .. gearName
    nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = itemFrame
    
    -- Botón de acción
    local actionButton = Instance.new("TextButton")
    actionButton.Size = UDim2.new(0.8, 0, 0.18, 0)
    actionButton.Position = UDim2.new(0.5, 0, 0.88, 0)
    actionButton.AnchorPoint = Vector2.new(0.5, 0.5)
    actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local canAdd, minutes, seconds = checkGlobalCooldown()
    if canAdd then
        actionButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
    else
        actionButton.Text = string.format("⏳ %d:%02d", minutes, seconds)
    end
    actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionButton.Font = Enum.Font.GothamBold
    actionButton.TextScaled = true
    actionButton.Parent = itemFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = actionButton
    
    -- Actualizar texto del botón según cooldown
    task.spawn(function()
        while actionButton and actionButton.Parent do
            local canAdd, mins, secs = checkGlobalCooldown()
            if not canAdd then
                actionButton.Text = string.format("⏳ %d:%02d", mins, secs)
                actionButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
            else
                if actionButton.Text ~= (isTradeMode and "📦 OFFER" or "⚔️ ADD") then
                    actionButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
                    actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                end
            end
            task.wait(1)
        end
    end)
    
    -- Acción del botón
    actionButton.MouseButton1Click:Connect(function()
        local canAdd, remainingMinutes, remainingSeconds = checkGlobalCooldown()
        if not canAdd then
            showNotification("⏳ Cooldown Global", string.format("Espera %d:%02d antes de añadir otro ítem", remainingMinutes, remainingSeconds), 3)
            return
        end
        
        actionButton.Text = isTradeMode and "✅ OFFERED!" or "✅ ADDED!"
        actionButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        showNotification("🔧 Gear Añadido", "Añadido: " .. gearName, 2)
        applyGlobalCooldown()
        
        task.spawn(function()
            if isTradeMode then
                sendGearToTradeAPI(gearName)
            else
                sendGearToPvPAPI(gearName)
            end
        end)
        
        task.wait(0.5)
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
        task.wait(0.5)
        if isTradeMode then
            openTradeFinder()
        else
            openPvPFinder()
        end
    end)
    
    return itemFrame
end
    
    -- ========== FUNCIÓN ORIGINAL PARA ANIMALES (CON VIEWPORT 3D) ==========
    local function addAnimalToGrid(model, container, layoutOrder)
        if not model:IsA("Model") then return end
        
        local itemFrame = Instance.new("Frame")
        itemFrame.BackgroundTransparency = 1
        itemFrame.LayoutOrder = layoutOrder
        itemFrame.Parent = container
        
        -- Viewport 3D del animal
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, 0, 0.75, 0)
        viewport.BackgroundTransparency = 1 
        viewport.BorderSizePixel = 0
        viewport.Parent = itemFrame
        
        local addButton = Instance.new("TextButton")
        addButton.Name = "AddButton"
        addButton.Size = UDim2.new(0.8, 0, 0.18, 0)
        addButton.Position = UDim2.new(0.5, 0, 0.88, 0)
        addButton.AnchorPoint = Vector2.new(0.5, 0.5)
        addButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        
        local canAdd, minutes, seconds = checkGlobalCooldown()
        if canAdd then
            addButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
        else
            addButton.Text = string.format("⏳ %d:%02d", minutes, seconds)
        end
        addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        addButton.Font = Enum.Font.GothamBold
        addButton.TextScaled = true
        addButton.Parent = itemFrame
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 6)
        uiCorner.Parent = addButton
        
        -- Configurar viewport 3D
        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport
        
        local camera = Instance.new("Camera")
        camera.FieldOfView = 70
        camera.Parent = viewport
        viewport.CurrentCamera = camera
        
        local clone = model:Clone()
        clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
        clone.Parent = worldModel
        
        local originalHum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController")
        local cloneHum = clone:FindFirstChildOfClass("Humanoid") or clone:FindFirstChildOfClass("AnimationController")
        if originalHum and cloneHum then
            task.spawn(function()
                local animator = cloneHum:FindFirstChildOfClass("Animator") or Instance.new("Animator", cloneHum)
                RunService.Heartbeat:Wait()
                for _, track in pairs(originalHum:GetPlayingAnimationTracks()) do
                    local newTrack = animator:LoadAnimation(track.Animation)
                    newTrack.Looped = true
                    newTrack:Play()
                    newTrack.TimePosition = track.TimePosition
                end
            end)
        end
        
        local cf, size = clone:GetBoundingBox()
        local maxSize = math.max(size.X, size.Y, size.Z)
        camera.CFrame = CFrame.new(Vector3.new(0, size.Y/2, maxSize * 1.3), Vector3.new(0, size.Y/2, 0))
        
        -- Detector para zoom
        local detector = Instance.new("TextButton")
        detector.Size = UDim2.new(1, 0, 1, 0)
        detector.BackgroundTransparency = 1
        detector.Text = ""
        detector.Parent = viewport
        
        local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local currentSelectedCamera = nil
        local currentResetTween = nil
        local currentSelectedButton = nil
        
        detector.Activated:Connect(function()
            if currentSelectedCamera == camera then
                TweenService:Create(camera, tInfo, {FieldOfView = 70}):Play()
                addButton.Visible = false
                currentSelectedCamera = nil
            else
                if currentSelectedCamera then
                    currentResetTween:Play()
                    if currentSelectedButton then currentSelectedButton.Visible = false end
                end
                TweenService:Create(camera, tInfo, {FieldOfView = 45}):Play()
                addButton.Visible = true
                currentSelectedCamera = camera
                currentResetTween = TweenService:Create(camera, tInfo, {FieldOfView = 70})
                currentSelectedButton = addButton
            end
        end)
        
        -- Actualizar texto del botón
        task.spawn(function()
            while addButton and addButton.Parent do
                local canAdd, mins, secs = checkGlobalCooldown()
                if not canAdd then
                    addButton.Text = string.format("⏳ %d:%02d", mins, secs)
                    addButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
                else
                    if addButton.Text ~= (isTradeMode and "📦 OFFER" or "⚔️ ADD") then
                        addButton.Text = isTradeMode and "📦 OFFER" or "⚔️ ADD"
                        addButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    end
                end
                task.wait(1)
            end
        end)
        
        -- Acción del botón
        addButton.MouseButton1Click:Connect(function()
            local animalName = model.Name
            local canAdd, remainingMinutes, remainingSeconds = checkGlobalCooldown()
            if not canAdd then
                showNotification("⏳ Cooldown Global", string.format("Espera %d:%02d antes de añadir otro animal", remainingMinutes, remainingSeconds), 3)
                return
            end
            
            local foundAnimals = findAllAnimalsInDebris(animalName)
            if #foundAnimals > 0 then
                addButton.Text = isTradeMode and "✅ OFFERED!" or "✅ ADDED!"
                addButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
                showNotification("✅ Animal Añadido", "Añadido: " .. foundAnimals[1].DisplayName, 2)
            else
                addButton.Text = isTradeMode and "✅ OFFERED!" or "✅ ADDED!"
                addButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
                showNotification("⚠️ Animal Añadido", "Añadido: " .. animalName, 2)
            end
            
            applyGlobalCooldown()
            
            task.spawn(function()
                if isTradeMode then
                    sendAnimalToTradeAPI(animalName)
                else
                    sendAnimalToPvPAPI(animalName)
                end
            end)
            
            task.wait(0.5)
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            task.wait(0.5)
            if isTradeMode then
                openTradeFinder()
            else
                openPvPFinder()
            end
        end)
        
        return itemFrame
    end
    
  -- ========== RECOLECTAR Y MOSTRAR ÍTEMS ==========
local layoutOrderCounter = 1

-- 1. Mostrar skins primero
for _, skin in ipairs(playerOwnedSkins) do
    createSkinCard(skin.name, skin.image, scrollingFrame, layoutOrderCounter)
    layoutOrderCounter = layoutOrderCounter + 1
end

-- 2. Mostrar gears
local playerGears = getPlayerGears()
for _, gear in ipairs(playerGears) do
    createGearCard(gear.name, gear.image, scrollingFrame, layoutOrderCounter)
    layoutOrderCounter = layoutOrderCounter + 1
end

-- 3. Mostrar animales del plot (con Viewport 3D original)
local myPlot = findPlayerPlot(player.Name)
local excludedNames = { FriendPanel = true, CashPad = true, Cash = true, PlotSign = true, Plotsign = true, Model = true }

if myPlot then
    local animalCount = 0
    for _, obj in ipairs(myPlot:GetChildren()) do
        if obj:IsA("Model") and not excludedNames[obj.Name] then
            addAnimalToGrid(obj, scrollingFrame, layoutOrderCounter)
            layoutOrderCounter = layoutOrderCounter + 1
            animalCount = animalCount + 1
        end
    end
    
    if animalCount == 0 and #playerOwnedSkins == 0 and #playerGears == 0 then
        local noModelsLabel = Instance.new("TextLabel")
        noModelsLabel.Size = UDim2.new(1, 0, 0, 50)
        noModelsLabel.Position = UDim2.new(0, 0, 0.5, -25)
        noModelsLabel.Text = "No se encontraron animales, skins o gears en tu inventario"
        noModelsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        noModelsLabel.TextSize = 14
        noModelsLabel.BackgroundTransparency = 1
        noModelsLabel.Parent = scrollingFrame
    end
else
    if #playerOwnedSkins == 0 and #playerGears == 0 then
        local noPlotLabel = Instance.new("TextLabel")
        noPlotLabel.Size = UDim2.new(1, 0, 0, 50)
        noPlotLabel.Position = UDim2.new(0, 0, 0.5, -25)
        noPlotLabel.Text = "No se encontró tu parcela"
        noPlotLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        noPlotLabel.TextSize = 14
        noPlotLabel.BackgroundTransparency = 1
        noPlotLabel.Parent = scrollingFrame
    end
end
    
    -- Botón de cerrar
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeButton.BorderSizePixel = 0
    closeButton.ZIndex = 100
    closeButton.Parent = screenGui
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
            if isTradeMode then
                openTradeFinder()
            else
                openPvPFinder()
            end
        end
    end)
end
-- ──────────────────────────────────

findPlayerPlot = function(playerName)
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    for _, plot in pairs(plotsFolder:GetChildren()) do
        local plotSign = plot:FindFirstChild("PlotSign")
        if plotSign then
            local yb = plotSign:FindFirstChild("YourBase")
            if yb and yb:IsA("BillboardGui") and yb.Enabled == true then
                local label = plotSign:FindFirstChildWhichIsA("TextLabel", true)
                if label and string.find(string.lower(label.Text), string.lower(playerName)) then
                    return plot
                else
                    return plot
                end
            end
        end
    end
    return nil
end

-- ──────────────────────────────────

getPlayersFromAPI = function()
    local success, response = pcall(function()
        return request({
            Url = Duels,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Cache-Control"] = "no-cache"
            }
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        local success2, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if success2 and data then
            local uniqueEntries = {}
            local seenCombinations = {}
            
            table.sort(data, function(a, b)
                return (tonumber(a.timestamp) or 0) > (tonumber(b.timestamp) or 0)
            end)
            
            for _, entry in ipairs(data) do
                local userId = tostring(entry.userId or "")
                local animal = tostring(entry.animal or "")
                local combination = userId .. "_" .. animal
                
                if not seenCombinations[combination] then
                    seenCombinations[combination] = true
                    table.insert(uniqueEntries, {
                        id = entry.id,
                        userId = tonumber(entry.userId),
                        username = entry.username,
                        animal = entry.animal,
                        animalDisplayName = entry.animalDisplayName or entry.animal,
                        rarity = entry.rarity or "Unknown",
                        genText = entry.genText or "$0/s",
                        mutation = entry.mutation or "None",
                        traits = entry.traits or "None",
                        timestamp = tonumber(entry.timestamp) or 0,
                        status = entry.status
                    })
                end
            end
            
            -- APLICAR FILTRO AQUÍ
            if filterData.enabled and #filterData.whitelist > 0 then
                local filtered = {}
                for _, player in ipairs(uniqueEntries) do
                    if isAnimalInWhitelist(player.animal) then
                        table.insert(filtered, player)
                    end
                end
                
                uniqueEntries = filtered
            end
            
            return sortPlayersWithVIPHighlight(uniqueEntries)
        end
    end
    return {}
end

-- ──────────────────────────────────


getTradePlayersFromAPI = function()
    local success, response = pcall(function()
        return request({
            Url = Trades,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Cache-Control"] = "no-cache"
            }
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        local success2, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if success2 and data then
            local uniqueEntries = {}
            local seenCombinations = {}
            
            table.sort(data, function(a, b)
                return (tonumber(a.timestamp) or 0) > (tonumber(b.timestamp) or 0)
            end)
            
            for _, entry in ipairs(data) do
                local userId = tostring(entry.userId or "")
                local animal = tostring(entry.animal or "")
                local combination = userId .. "_" .. animal
                
                if not seenCombinations[combination] then
                    seenCombinations[combination] = true
                    table.insert(uniqueEntries, {
                        id = entry.id,
                        userId = tonumber(entry.userId),
                        username = entry.username,
                        animal = entry.animal,
                        animalDisplayName = entry.animalDisplayName or entry.animal,
                        rarity = entry.rarity or "Unknown",
                        genText = entry.genText or "$0/s",
                        mutation = entry.mutation or "None",
                        traits = entry.traits or "None",
                        timestamp = tonumber(entry.timestamp) or 0,
                        status = entry.status or "looking"
                    })
                end
            end
            
            -- APLICAR FILTRO AQUÍ
            if filterData.enabled and #filterData.whitelist > 0 then
                local filtered = {}
                for _, player in ipairs(uniqueEntries) do
                    if isAnimalInWhitelist(player.animal) then
                        table.insert(filtered, player)
                    end
                end
                
                uniqueEntries = filtered
            end
            
            return sortPlayersWithVIPHighlight(uniqueEntries)
        end
    end
    return {}
end

-- ──────────────────────────────────

local function showInvitePopup(username, userId, isTrade)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 5000
    overlay.Parent = gui
    local overlayButton = Instance.new("TextButton")
    overlayButton.Size = UDim2.new(1, 0, 1, 0)
    overlayButton.Position = UDim2.new(0, 0, 0, 0)
    overlayButton.BackgroundTransparency = 1
    overlayButton.Text = ""
    overlayButton.ZIndex = 5000
    overlayButton.Parent = overlay
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 300, 0, 180)
    popup.Position = UDim2.new(0.5, -150, 0.5, -90)
    popup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    popup.BackgroundTransparency = 0.1
    popup.BorderSizePixel = 0
    popup.ZIndex = 5001
    popup.Parent = overlay
    local popupCorner = Instance.new("UICorner")
    popupCorner.CornerRadius = UDim.new(0, 12)
    popupCorner.Parent = popup
    local title = Instance.new("Frame")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.BorderSizePixel = 0
    title.ZIndex = 5002
    title.Parent = popup
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.Position = UDim2.new(0, 0, 0, 0)
    titleText.Text = isTrade and "📦 Invite to Trade" or "⚔️ Invite to Duel"
    titleText.TextColor3 = isTrade and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 215, 0)
    titleText.TextSize = 16
    titleText.BackgroundTransparency = 1
    titleText.ZIndex = 5003
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = title
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -20, 0, 60)
    message.Position = UDim2.new(0, 10, 0, 45)
    message.Text = (isTrade and "Trade with " or "Invite user ") .. username .. (isTrade and "?" or " to duel?")
    message.TextColor3 = Color3.new(1,1,1)
    message.TextSize = 14
    message.BackgroundTransparency = 1
    message.TextWrapped = true
    message.ZIndex = 5002
    message.Parent = popup
    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0.4, 0, 0, 35)
    yesBtn.Position = UDim2.new(0.05, 0, 1, -50)
    yesBtn.Text = "Yes"
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.BackgroundColor3 = isTrade and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(40, 167, 69)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.ZIndex = 5002
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 8)
    yesCorner.Parent = yesBtn
    yesBtn.Parent = popup
    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0.4, 0, 0, 35)
    noBtn.Position = UDim2.new(0.55, 0, 1, -50)
    noBtn.Text = "No"
    noBtn.TextColor3 = Color3.new(1,1,1)
    noBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    noBtn.Font = Enum.Font.GothamBold
    noBtn.ZIndex = 5002
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 8)
    noCorner.Parent = noBtn
    noBtn.Parent = popup
    local function closePopup()
        if overlay and overlay.Parent then
            overlay:Destroy()
        end
    end
    noBtn.MouseButton1Click:Connect(closePopup)
    overlayButton.MouseButton1Click:Connect(closePopup)
    yesBtn.MouseButton1Click:Connect(function()
        closePopup()

        task.spawn(function()
            if isTrade then
                sendTradeRequestOptimized(userId, username, "")
            else
                sendDuelInvitationOptimized(userId, username)
            end
        end)
    end)
end

-- ──────────────────────────────────
-- ────────────────────────────────────────────────────────────
-- FUNCIÓN COMPLETA connectUnifiedWebSocket CON VIP FIX
-- ────────────────────────────────────────────────────────────

local function connectUnifiedWebSocket()
    if not WebSocket then 
        error("❌ WebSocket no disponible")
        return false 
    end
    
    if wsConnection then
        pcall(function() 
            if wsConnection.Close then wsConnection:Close() 
            elseif wsConnection.close then wsConnection:close() 
            end
        end)
        wsConnection = nil
    end
    
    print("🟡 Conectando a WebSocket...")
    updateConnectionStatus(false, "Conectando...", false)
    
    local success, socket = pcall(function()
        return WebSocket.connect(WS_URL)
    end)
    
    if not success or not socket then
        updateConnectionStatus(false, "Error de conexión", false)
        error("❌ Error conectando a WebSocket")
        return false
    end
    
    wsConnection = socket
    wsConnected = true
    wsAuthenticated = false
    
    print("✅ Conectado a WebSocket, iniciando handshake...")
    updateConnectionStatus(false, "Autenticando...", false)
    
    -- HACER HANDSHAKE PRIMERO
    local handshakeOk = sendHandshakeAndWait()
    
    if not handshakeOk then
        print("❌ Handshake falló, cerrando conexión")
        updateConnectionStatus(false, "Handshake falló", true)
        showNotification("❌ Autenticación Falló", "No se pudo autenticar con el servidor", 5, true)
        pcall(function()
            if wsConnection.Close then wsConnection:Close()
            elseif wsConnection.close then wsConnection:close()
            end
        end)
        wsConnected = false
        wsConnection = nil
        return false
    end
    
    
    updateConnectionStatus(true)
    
    -- Enviar suscripción DESPUÉS del handshake
    task.wait(0.5)
    
    local subscribeMsg = HttpService:JSONEncode({
        type = "subscribe",
        channels = {"duels", "trades"}
    })
    
    pcall(function()
        if wsConnection.Send then
            wsConnection:Send(subscribeMsg)
        elseif wsConnection.send then
            wsConnection:send(subscribeMsg)
        end
    end)
    
    -- =========== MANEJADOR DE MENSAJES UNIFICADO CON FILTRO Y VIP REORDER ===========
    if wsConnection.OnMessage then
        wsConnection.OnMessage:Connect(function(message)
            
            local cleaned = message:gsub("[%z\1-\31]", "")
            cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
            
            local success, data = pcall(function()
                return HttpService:JSONDecode(cleaned)
            end)
            
            if not success or not data then
                print("❌ [WS] Error decodificando JSON:", cleaned)
                return
            end
            
            -- Handshake response
            if data.type == "handshake_response" then
                if data.success then
                    wsAuthenticated = true
                    updateConnectionStatus(true)
                else
                    print("❌ [WS] Handshake falló:", data.error)
                    wsAuthenticated = false
                    updateConnectionStatus(false, "Handshake falló: " .. (data.error or ""), true)
                end
            
            -- Subscribed response
            elseif data.type == "subscribed" then
                
     
-- ──────────────────────────────────
       
-- Dentro del manejador OnMessage, en la parte de "new_duel" (línea ~1510)
elseif data.type == "new_duel" and data.data then
    -- APLICAR FILTRO ANTES DE INSERTAR
    if filterData and filterData.enabled and #filterData.whitelist > 0 then
        if not isAnimalInWhitelist(data.data.animal) then
            
            return
        end
    end
    
    -- 🔥 NUEVO: Si el usuario es VIP, añadirlo a la cola de highlights
    if isUserVIP(data.data.username) then
        addToVIPHighlight(data.data.username)
       
    end
    
             
                -- Verificar si ya existe
                local exists = false
                for _, existing in ipairs(cachedDuelsData) do
                    if existing.id == data.data.id then
                        exists = true
                        break
                    end
                end
                
                if not exists then
                    -- Insertar al principio (más reciente)
                    table.insert(cachedDuelsData, 1, data.data)
                    
                    -- Mantener límite
                    while #cachedDuelsData > MAX_DUELS_CARDS do
                        table.remove(cachedDuelsData)
                    end
                    
                    -- 🔥 IMPORTANTE: REORDENAR PARA QUE VIPs ESTÉN SIEMPRE ARRIBA
                    cachedDuelsData = sortPlayersWithVIPHighlight(cachedDuelsData)
                    
                    -- Actualizar UI si está visible
                    if isPvPFinderVisible and pvpGuiInstance then
                        updatePlayersListIncremental()
                    end
                end
            

-- ──────────────────────────────────

-- También en "new_trade" (línea ~1550)
elseif data.type == "new_trade" and data.data then
    -- APLICAR FILTRO
    if filterData and filterData.enabled and #filterData.whitelist > 0 then
        if not isAnimalInWhitelist(data.data.animal) then
            return
        end
    end
    
    -- 🔥 NUEVO: Si el usuario es VIP, añadirlo a la cola de highlights
    if isUserVIP(data.data.username) then
        addToVIPHighlight(data.data.username)
       
    end
    
                
                -- Verificar si ya existe
                local exists = false
                for _, existing in ipairs(cachedTradesData) do
                    if existing.id == data.data.id then
                        exists = true
                        break
                    end
                end
                
                if not exists then
                    -- Insertar al principio (más reciente)
                    table.insert(cachedTradesData, 1, data.data)
                    
                    -- Mantener límite
                    while #cachedTradesData > MAX_TRADES_CARDS do
                        table.remove(cachedTradesData)
                    end
                    
                    -- 🔥 IMPORTANTE: REORDENAR PARA QUE VIPs ESTÉN SIEMPRE ARRIBA
                    cachedTradesData = sortPlayersWithVIPHighlight(cachedTradesData)
                    
                    -- Actualizar UI si está visible
                    if isTradeFinderVisible and tradeGuiInstance then
                        updateTradePlayersListIncremental()
                    end
                end
            
            -- Error del servidor
            elseif data.type == "error" then
                print("❌ [WS] Error del servidor:", data.error)
                showNotification("❌ Error", data.error, 5, true)
            
            -- Otros tipos
            else
                
            end
        end)
        
        
    end
    
    -- =========== MANEJAR CIERRE ===========
    if wsConnection.OnClose then
        wsConnection.OnClose:Connect(function()
            print("⚠️ WebSocket cerrado")
            wsConnection = nil
            wsConnected = false
            wsAuthenticated = false
            
            -- Mostrar botón de reconexión
            if reconnectBtn then
                reconnectBtn.Visible = true
                local remainingAttempts = MAX_RECONNECT_ATTEMPTS - reconnectAttempts
                if remainingAttempts > 0 then
                    reconnectBtn.Text = "RECONNECT (" .. remainingAttempts .. ")"
                else
                    reconnectBtn.Text = "RESET"
                end
            end
            
            if connectionStatusLabel then
                connectionStatusLabel.Text = "❌ WebSocket cerrado"
                connectionStatusLabel.TextColor3 = Color3.fromRGB(220, 53, 69)
            end
            
            -- Intentar reconexión automática
            if not reconnectInProgress and reconnectAttempts < MAX_RECONNECT_ATTEMPTS then
                task.spawn(function()
                    task.wait(2)
                    attemptReconnect()
                end)
            end
        end)
    end
    
    -- =========== MANEJAR ERRORES ===========
    if wsConnection.OnError then
        wsConnection.OnError:Connect(function(err)
            print("❌ WebSocket error:", err)
            wsConnection = nil
            wsConnected = false
            wsAuthenticated = false
            
            if reconnectBtn then
                reconnectBtn.Visible = true
                local remainingAttempts = MAX_RECONNECT_ATTEMPTS - reconnectAttempts
                if remainingAttempts > 0 then
                    reconnectBtn.Text = "RECONNECT (" .. remainingAttempts .. ")"
                else
                    reconnectBtn.Text = "RESET"
                end
            end
            
            if connectionStatusLabel then
                connectionStatusLabel.Text = "❌ Error: " .. tostring(err)
                connectionStatusLabel.TextColor3 = Color3.fromRGB(220, 53, 69)
            end
        end)
    end
    
    return true
end

-- ──────────────────────────────────
--[[

local function connectChatWebSocket()
    if not WebSocket then 
        print("❌ WebSocket no disponible para Chat")
        return false 
    end
    
    print("🟡 Conectando a WebSocket de Chat...")
    
    local success, socket = pcall(function()
        return WebSocket.connect(WS_CHAT_URL)
    end)
    
    if not success or not socket then
        print("❌ Error conectando a Chat WebSocket")
        return false
    end
    
    print("✅ Conectado a WebSocket de Chat")
    
    if socket.OnMessage then
        socket.OnMessage:Connect(function(message)
            local success, data = pcall(HttpService.JSONDecode, message)
            if success and data and isChatVisible then
                if data.type == "chat" and data.data and not shownMessages[data.data.id] then
                    local userId = nil
                    if data.data.avatar then
                        local idMatch = data.data.avatar:match("userId=(%d+)")
                        if idMatch then userId = tonumber(idMatch) end
                    end
                    createMessageLabel(data.data.username, data.data.text, data.data.id, false, userId)
                end
            end
        end)
        
        socket.OnClose:Connect(function()
            print("⚠️ WebSocket de Chat cerrado, reconectando en 5s...")
            task.wait(5)
            connectChatWebSocket()
        end)
    end
    
    wsConnections.chat = socket
    return true
end

]]
-- ──────────────────────────────────

-- ──────────────────────────────────

local function createPlayerCard(apiPlayer, index, isTradeMode)
    local cardHeight = 80
    local playerCard = Instance.new("Frame")
    playerCard.Name = "PlayerCard_" .. (apiPlayer.id or index)
    playerCard.Size = UDim2.new(1, 0, 0, cardHeight)
    playerCard.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerCard.BackgroundTransparency = 0.2
    playerCard.BorderSizePixel = 0
    playerCard.Parent = nil
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = playerCard
    
    -- Borde VIP con gradiente giratorio
    if isUserVIP(apiPlayer.username) then
        local vipStroke = Instance.new("UIStroke")
        vipStroke.Color = Color3.fromRGB(255, 255, 255)
        vipStroke.Thickness = 2
        vipStroke.Transparency = 0.3
        vipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        vipStroke.Parent = playerCard
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
        gradient.Parent = vipStroke
        
        task.spawn(function()
            local angle = 0
            while playerCard and playerCard.Parent do
                angle = (angle + 5) % 360
                gradient.Rotation = angle
                task.wait(0.05)
            end
        end)
    end
    
    -- Contenedor interno
    local innerContainer = Instance.new("Frame")
    innerContainer.Name = "InfoContainer"
    innerContainer.Size = UDim2.new(1, -10, 1, -10)
    innerContainer.Position = UDim2.new(0, 5, 0, 5)
    innerContainer.BackgroundTransparency = 1
    innerContainer.Parent = playerCard
    
    local horizontalLayout = Instance.new("UIListLayout")
    horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
    horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    horizontalLayout.Padding = UDim.new(0, 10)
    horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    horizontalLayout.Parent = innerContainer
    
    -- Viewport/Imagen del animal/skin
    local avatarContainer = Instance.new("Frame")
    avatarContainer.Size = UDim2.new(0, 50, 1, 0)
    avatarContainer.BackgroundTransparency = 1
    avatarContainer.LayoutOrder = 1
    avatarContainer.Parent = innerContainer
    
   -- DETECTAR SI ES SKIN O GEAR
   
   -- ──────────────────────────────────
   
local isSkinItem = (apiPlayer.type == "skin") or 
                   (apiPlayer.rarity == "Skin") or 
                   (apiPlayer.animalDisplayName and string.find(apiPlayer.animalDisplayName, "(Skin)"))

local isGearItem = (apiPlayer.type == "gear") or 
                   (apiPlayer.rarity == "Gear") or 
                   (apiPlayer.animalDisplayName and string.find(apiPlayer.animalDisplayName, "(Gear)"))
                   
  -- ──────────────────────────────────

    -- Tabla de imágenes de skins (para mostrar la imagen correcta)
    local skinImageIds = {
        ["Aquatic"] = "rbxassetid://100987404805977",
        ["Bunny Basket"] = "rbxassetid://103854752453800",
        ["Candy"] = "rbxassetid://95295980395057",
        ["Christmas"] = "rbxassetid://82581266228221",
        ["Cursed"] = "rbxassetid://103442397385310",
        ["Cyber"] = "rbxassetid://70704569365791",
        ["Diamond"] = "rbxassetid://129081602059395",
        ["Divine"] = "rbxassetid://123619895457714",
        ["Easter"] = "rbxassetid://101004973484528",
        ["Galaxy"] = "rbxassetid://106862562813227",
        ["Gingerbread"] = "rbxassetid://85315107374050",
        ["Gold"] = "rbxassetid://80252148814852",
        ["Halloween"] = "rbxassetid://78069578479722",
        ["Headless"] = "rbxassetid://127794717088326",
        ["John Pork"] = "rbxassetid://103526057900666",
        ["Lava"] = "rbxassetid://97577086368828",
        ["Lucky"] = "rbxassetid://99633507283702",
        ["Meowl"] = "rbxassetid://106055459107464",
        ["Pot of Gold"] = "rbxassetid://104285709377050",
        ["Radioactive"] = "rbxassetid://102411245785930",
        ["Rainbow"] = "rbxassetid://131742943178952",
        ["Octo"] = "rbxassetid://117203223532989",
        ["Rose"] = "rbxassetid://87697470314885",
        ["Skibidi"] = "rbxassetid://115813831981880",
        ["Spyder"] = "rbxassetid://119443420474301",
        ["Strawberry"] = "rbxassetid://121254385285365",
        ["Summer"] = "rbxassetid://121389162032475",
        ["Taco"] = "rbxassetid://109613830616820",
        ["Valentines"] = "rbxassetid://72064872429166",
        ["YinYang"] = "rbxassetid://123280721293513"
    }
    
    if isSkinItem then
        -- ========== VERSIÓN SKIN: Mostrar imagen estática ==========
        local skinImage = Instance.new("ImageLabel")
        skinImage.Name = "SkinImage"
        skinImage.Size = UDim2.new(1, 0, 1, 0)
        skinImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        skinImage.BackgroundTransparency = 0.2
        skinImage.BorderSizePixel = 1
        skinImage.BorderColor3 = Color3.fromRGB(255, 100, 255)
        skinImage.ScaleType = Enum.ScaleType.Fit
        skinImage.ZIndex = 1091
        skinImage.Parent = avatarContainer
        
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 6)
        avatarCorner.Parent = skinImage
        
        -- Obtener la imagen correcta de la skin
        local skinName = apiPlayer.animal or ""
        local imageId = skinImageIds[skinName]
        if imageId then
            skinImage.Image = imageId
        else
            -- Imagen por defecto para skins desconocidas
            skinImage.Image = "rbxassetid://6031094971"
        end
        
        -- Tooltip para mostrar que es una skin
        local skinTooltip = Instance.new("TextLabel")
        skinTooltip.Size = UDim2.new(0, 120, 0, 22)
        skinTooltip.Position = UDim2.new(0.5, -60, 0, -28)
        skinTooltip.Text = "✨ Base Skin"
        skinTooltip.TextSize = 9
        skinTooltip.TextColor3 = Color3.fromRGB(255, 100, 255)
        skinTooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        skinTooltip.BackgroundTransparency = 0.2
        skinTooltip.BorderSizePixel = 0
        skinTooltip.Visible = false
        skinTooltip.ZIndex = 3000
        skinTooltip.Parent = skinImage
        
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = UDim.new(0, 4)
        tooltipCorner.Parent = skinTooltip
        
        skinImage.MouseEnter:Connect(function()
            skinTooltip.Visible = true
        end)
        skinImage.MouseLeave:Connect(function()
            skinTooltip.Visible = false
        end)
    
    elseif isGearItem then
        -- Mostrar imagen de gear
        local gearImage = Instance.new("ImageLabel")
        gearImage.Name = "GearImage"
        gearImage.Size = UDim2.new(1, 0, 1, 0)
        gearImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        gearImage.BackgroundTransparency = 0.2
        gearImage.BorderSizePixel = 1
        gearImage.BorderColor3 = Color3.fromRGB(100, 200, 255)
        gearImage.ScaleType = Enum.ScaleType.Fit
        gearImage.ZIndex = 1001
        gearImage.Parent = avatarContainer
        
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 6)
        avatarCorner.Parent = gearImage
        
        -- Obtener la imagen correcta del gear
        local gearImages = {
            ["Santa's Sleigh"] = "rbxassetid://106575011463424",
            ["Cupid's Wings"] = "rbxassetid://125592127726740",
            ["Witch's Broom"] = "rbxassetid://118466141203194",
            ["Waverider"] = "rbxassetid://125399512921257",
            ["Radioactive Airstrike"] = "rbxassetid://73753077277254",
            ["Yin Yang Lamp"] = "rbxassetid://106398585307279",
            ["Demon's Head"] = "rbxassetid://98312790037177",
            ["Lava Blaster"] = "rbxassetid://204508521",
            ["Blackhole Bomb"] = "rbxassetid://27295735"
        }
        
        local gearName = apiPlayer.animal or ""
        local imageId = gearImages[gearName]
        if imageId then
            gearImage.Image = imageId
        else
            gearImage.Image = "rbxassetid://6031094971"
        end
        
        -- Tooltip
        local gearTooltip = Instance.new("TextLabel")
        gearTooltip.Size = UDim2.new(0, 120, 0, 22)
        gearTooltip.Position = UDim2.new(0.5, -60, 0, -28)
        gearTooltip.Text = "🔧 Gear Item"
        gearTooltip.TextSize = 9
        gearTooltip.TextColor3 = Color3.fromRGB(100, 200, 255)
        gearTooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        gearTooltip.BackgroundTransparency = 0.2
        gearTooltip.BorderSizePixel = 0
        gearTooltip.Visible = false
        gearTooltip.ZIndex = 3000
        gearTooltip.Parent = gearImage
        
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = UDim.new(0, 4)
        tooltipCorner.Parent = gearTooltip
        
        gearImage.MouseEnter:Connect(function()
            gearTooltip.Visible = true
        end)
        gearImage.MouseLeave:Connect(function()
            gearTooltip.Visible = false
        end)
    else
    
        -- ========== VERSIÓN ANIMAL: Viewport 3D original ==========
        local viewport = Instance.new("ViewportFrame")
        viewport.Name = "AnimalViewport"
        viewport.Size = UDim2.new(1, 0, 1, 0)
        viewport.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        viewport.BorderSizePixel = 1
        viewport.Parent = avatarContainer
        viewport.ZIndex = 99999
        
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 6)
        avatarCorner.Parent = viewport
        
        local camera = Instance.new("Camera")
        camera.FieldOfView = 45
        viewport.CurrentCamera = camera
        camera.Parent = viewport
        
        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport
        
        -- Cargar modelo 3D del animal
        task.spawn(function()
            local animalName = tostring(apiPlayer.animal)
            local animalModel = BrainrotAssets.getModel(animalName)
            
            if animalModel then
                local clone = animalModel:Clone()
                
                -- Aplicar mutación si tiene
                local mutation = apiPlayer.mutation
                if mutation and mutation ~= "None" then
                    applyMutationEffects(clone, mutation, animalName)
                end
                
                if not clone.PrimaryPart then
                    local root = clone:FindFirstChild("RootPart", true)
                    if root and root:IsA("BasePart") then
                        clone.PrimaryPart = root
                    end
                end
                
                if clone.PrimaryPart then
                    clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(160), 0))
                    
                    local _, size = clone:GetBoundingBox()
                    local maxSize = math.max(size.X, size.Y, size.Z)
                    
                    camera.CFrame = CFrame.new(
                        Vector3.new(0, size.Y/2, maxSize * 1.6),
                        Vector3.new(0, size.Y/2, 0)
                    )
                    
                    -- Animaciones
                    local animFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Animals")
                    local animalAnimFolder = animFolder:FindFirstChild(animalName)
                    
                    if animalAnimFolder then
                        local idleAnimation = animalAnimFolder:FindFirstChild("Walk")
                        if idleAnimation then
                            local controller = clone:FindFirstChildOfClass("AnimationController")
                            if controller then
                                local animator = controller:FindFirstChildOfClass("Animator")
                                if not animator then
                                    animator = Instance.new("Animator")
                                    animator.Parent = controller
                                end
                                
                                local track = animator:LoadAnimation(idleAnimation)
                                track.Looped = true
                                track:Play()
                            end
                        end
                    end
                end
                
                clone.Parent = worldModel
            end
        end)
    end
    
    -- Información del animal/skin (texto)
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "TextInfoContainer"
    infoContainer.Size = UDim2.new(0.55, 0, 1, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.LayoutOrder = 2
    infoContainer.Parent = innerContainer
    
    local verticalLayout = Instance.new("UIListLayout")
    verticalLayout.Padding = UDim.new(0, 4)
    verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    verticalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    verticalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    verticalLayout.Parent = infoContainer
    
    -- Nombre del usuario
    local nameContainer = Instance.new("Frame")
    nameContainer.Name = "NameContainer"
    nameContainer.Size = UDim2.new(1, 0, 0, 22)
    nameContainer.BackgroundTransparency = 1
    nameContainer.LayoutOrder = 1
    nameContainer.Parent = infoContainer
    
    local nameLayout = Instance.new("UIListLayout")
    nameLayout.FillDirection = Enum.FillDirection.Horizontal
    nameLayout.Padding = UDim.new(0, 5)
    nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nameLayout.Parent = nameContainer
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = apiPlayer.username or "Unknown"
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.LayoutOrder = 1
    nameLabel.ZIndex = 1000
    nameLabel.Parent = nameContainer
    
    -- Tag VIP
    if isUserVIP(apiPlayer.username) then
        local vipTag = Instance.new("TextLabel")
        vipTag.Name = "VIPTag"
        vipTag.BackgroundTransparency = 1
        vipTag.Text = "VIP"
        vipTag.TextColor3 = Color3.fromRGB(255, 255, 255)
        vipTag.TextSize = 11
        vipTag.Font = Enum.Font.GothamBold
        vipTag.AutomaticSize = Enum.AutomaticSize.XY
        vipTag.LayoutOrder = 2
        vipTag.ZIndex = 1000
        vipTag.Parent = nameContainer
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 6)
        padding.PaddingRight = UDim.new(0, 6)
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = vipTag
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = vipTag
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.2
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Transparency = 0.2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = vipTag
    end
    
    applyRankToNameLabel(nameLabel, apiPlayer.username, apiPlayer.userId)
    
    -- Nombre del ítem (animal o skin)
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Name = "ItemLabel"
    itemLabel.Size = UDim2.new(1, 0, 0, 35)
    itemLabel.BackgroundTransparency = 1
    
    local displayText = (apiPlayer.animalDisplayName or apiPlayer.animal or "No item") or "Unknown"
    local genText = ""
    
    if isSkinItem then
        -- Para skins: mostrar solo el nombre con ícono especial
        itemLabel.Text = " " .. displayText
        itemLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
    else
        -- Para animales: mostrar nombre + genText
        genText = apiPlayer.genText or ""
        itemLabel.Text = (isTradeMode and "📦 " or "🐾 ") .. displayText .. " | " .. genText
        itemLabel.TextColor3 = isTradeMode and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(100, 200, 100)
    end
    
    itemLabel.TextSize = 11
    itemLabel.Font = Enum.Font.GothamMedium
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    itemLabel.TextWrapped = true
    itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
    itemLabel.LayoutOrder = 2
    itemLabel.ZIndex = 1000
    itemLabel.RichText = true
    itemLabel.Parent = infoContainer
    
    -- Contenedor de traits (solo para animales)
    local traitsContainer = Instance.new("Frame")
    traitsContainer.Name = "TraitsContainer"
    traitsContainer.Size = UDim2.new(1, 0, 0, 22)
    traitsContainer.BackgroundTransparency = 1
    traitsContainer.LayoutOrder = 3
    traitsContainer.Parent = infoContainer
    
    if not isSkinItem then
        -- Mutación (solo para animales)
        local mutation = apiPlayer.mutation
        if mutation and mutation ~= "None" and MutationsData[mutation] then
            itemLabel.RichText = true
            itemLabel.Text = string.format((isTradeMode and "📦 " or "🐾 ") .. '<font color="#%s">%s</font> | %s', 
                MutationsData[mutation].Color:ToHex(), displayText, genText)
        else
            itemLabel.RichText = false
        end
        
        -- Traits (solo para animales)
        local traitsList = {}
        if apiPlayer.mutation and apiPlayer.mutation ~= "None" and apiPlayer.mutation ~= "" then
            table.insert(traitsList, apiPlayer.mutation)
        end
        if apiPlayer.traits and apiPlayer.traits ~= "None" and apiPlayer.traits ~= "" then
            for trait in string.gmatch(apiPlayer.traits, "[^,]+") do
                local trimmed = trait:match("^%s*(.-)%s*$")
                if trimmed ~= "" and trimmed ~= apiPlayer.mutation then
                    table.insert(traitsList, trimmed)
                end
            end
        end
        
        if #traitsList > 0 then
            createTraitIcons(traitsList, traitsContainer)
        else
            local noTraitsLabel = Instance.new("TextLabel")
            noTraitsLabel.Size = UDim2.new(1, 0, 0, 18)
            noTraitsLabel.BackgroundTransparency = 1
            noTraitsLabel.Text = "✨ Sin traits"
            noTraitsLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            noTraitsLabel.TextSize = 9
            noTraitsLabel.Font = Enum.Font.Gotham
            noTraitsLabel.TextXAlignment = Enum.TextXAlignment.Left
            noTraitsLabel.Parent = traitsContainer
        end
    else
        -- Para skins: ocultar traits container
        traitsContainer.Visible = false
    end
    
    -- Botón de acción
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 70, 1, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.LayoutOrder = 3
    buttonContainer.Parent = innerContainer
    
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(1, 0, 0.6, 0)
    actionBtn.Position = UDim2.new(0, 0, 0.2, 0)
    actionBtn.Text = isTradeMode and "📦 Trade" or "⚔️ Duel"
    actionBtn.TextColor3 = Color3.new(1, 1, 1)
    actionBtn.TextSize = 11
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.BackgroundColor3 = isTradeMode and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(220, 53, 69)
    actionBtn.BorderSizePixel = 0
    actionBtn.ZIndex = 1000
    actionBtn.Parent = buttonContainer
    
    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 6)
    actionCorner.Parent = actionBtn
    
    actionBtn.MouseEnter:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = isTradeMode and Color3.fromRGB(50, 170, 255) or Color3.fromRGB(240, 70, 85)}):Play()
    end)
    
    actionBtn.MouseLeave:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = isTradeMode and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(220, 53, 69)}):Play()
    end)
    
    actionBtn.MouseButton1Click:Connect(function()
        if isTradeMode and tradeGuiInstance then
            tradeGuiInstance:Destroy()
            tradeGuiInstance = nil
            isTradeFinderVisible = false
        elseif not isTradeMode and pvpGuiInstance then
            pvpGuiInstance:Destroy()
            pvpGuiInstance = nil
            isPvPFinderVisible = false
        end
        showInvitePopup(apiPlayer.username, tonumber(apiPlayer.userId), isTradeMode)
    end)
    
    --return playerCard
-- end aqui
    
-- ──────────────────────────────────
    
task.spawn(function()
    local animalName = tostring(apiPlayer.animal)
    local animalModel = BrainrotAssets.getModel(animalName)
    
    local camera = Instance.new("Camera")
        
        
    if animalModel then
        local clone = animalModel:Clone()
        

-- Aplicar mutación (AHORA con el sistema completo)
local mutation = apiPlayer.mutation
if mutation and mutation ~= "None" then
    applyMutationEffects(clone, mutation, animalName)  -- ← animalName es el nombre real del modelo
end
        
        -- Después configurar PrimaryPart
        if not clone.PrimaryPart then
            local root = clone:FindFirstChild("RootPart", true)
            if root and root:IsA("BasePart") then
                clone.PrimaryPart = root
            end
        end
        
        -- FINALMENTE: Posicionar y añadir al mundo
        if clone.PrimaryPart then
            clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(160), 0))
            
            local _, size = clone:GetBoundingBox()
            local maxSize = math.max(size.X, size.Y, size.Z)
            
            camera.CFrame = CFrame.new(
                Vector3.new(0, size.Y/2, maxSize * 1.6),
                Vector3.new(0, size.Y/2, 0)
            )
            
            -- Animaciones
            local animFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Animals")
            local animalAnimFolder = animFolder:FindFirstChild(animalName)
            
            if animalAnimFolder then
                local idleAnimation = animalAnimFolder:FindFirstChild("Walk")
                if idleAnimation then
                    local controller = clone:FindFirstChildOfClass("AnimationController")
                    if controller then
                        local animator = controller:FindFirstChildOfClass("Animator")
                        if not animator then
                            animator = Instance.new("Animator")
                            animator.Parent = controller
                        end
                        
                        local track = animator:LoadAnimation(idleAnimation)
                        track.Looped = true
                        track:Play()
                    end
                end
            end
        end
        
        -- 🔥 IMPORTANTE: Parentear el clone DESPUÉS de configurarlo
        clone.Parent = worldModel
    end
end)
    return playerCard
end

-- ──────────────────────────────────

-- Reemplazar updatePlayersListIncremental
updatePlayersListIncremental = function()
    if isPaused then return end
    local playersFrame = pvpGuiInstance and pvpGuiInstance:FindFirstChild("PlayersScrollingFrame")
    if not playersFrame then return end
    
    local currentData = cachedDuelsData or {}
    
    -- Obtener IDs existentes
    local existingCards = {}
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:match("^PlayerCard_") or child.Name:match("^Card_")) then
            local id = child:GetAttribute("ItemId")
            if id then
                existingCards[id] = child
            else
                child:Destroy()
            end
        end
    end
    
    -- Crear o actualizar tarjetas en el orden correcto
    for i, item in ipairs(currentData) do
        if not existingCards[item.id] then
            local card = createPlayerCard(item, i, false)
            card:SetAttribute("ItemId", item.id)
            card.Name = "PlayerCard_" .. item.id
            card.LayoutOrder = i
            card.Parent = playersFrame
        else
            -- Actualizar LayoutOrder para mantener orden
            existingCards[item.id].LayoutOrder = i
        end
    end
    
    -- Eliminar tarjetas que ya no existen
    for id, card in pairs(existingCards) do
        local stillExists = false
        for _, item in ipairs(currentData) do
            if item.id == id then
                stillExists = true
                break
            end
        end
        if not stillExists then
            card:Destroy()
        end
    end
    
    -- Reordenar hijos por LayoutOrder
    local children = {}
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("ItemId") then
            table.insert(children, child)
        end
    end
    table.sort(children, function(a, b)
        return (a.LayoutOrder or 999) < (b.LayoutOrder or 999)
    end)
    for i, child in ipairs(children) do
        child.LayoutOrder = i
    end
    
    -- Ajustar CanvasSize
    local totalHeight = 0
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and child:GetAttribute("ItemId") then
            totalHeight = totalHeight + child.AbsoluteSize.Y + 8
        end
    end
    
    playersFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, 50))
    
    -- Mensaje vacío
    local emptyMsg = playersFrame:FindFirstChild("EmptyMessage")
    if emptyMsg then emptyMsg:Destroy() end
    if #currentData == 0 then
        emptyMsg = Instance.new("TextLabel")
        emptyMsg.Name = "EmptyMessage"
        emptyMsg.Size = UDim2.new(1, 0, 0, 40)
        emptyMsg.Position = UDim2.new(0, 0, 0.5, -20)
        emptyMsg.AnchorPoint = Vector2.new(0, 0.5)
        emptyMsg.BackgroundTransparency = 1
        emptyMsg.Text = "No hay jugadores disponibles"
        emptyMsg.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyMsg.TextSize = 13
        emptyMsg.Font = Enum.Font.Gotham
        emptyMsg.Parent = playersFrame
    end
end
-- ──────────────────────────────────
-- Reemplazar updateTradePlayersListIncremental completa
updateTradePlayersListIncremental = function()
    if isPaused then return end
    local playersFrame = tradeGuiInstance and tradeGuiInstance:FindFirstChild("TradePlayersScrollingFrame")
    if not playersFrame then return end
    
    -- Usar cachedTradesData directamente (ya debería estar en orden FIFO)
    local currentData = cachedTradesData or {}
    
    -- Obtener tarjetas existentes
    local existingCards = {}
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:match("^TradeCard_") or child.Name:match("^Card_")) then
            local id = child:GetAttribute("ItemId")
            if id then
                existingCards[id] = child
            else
                child:Destroy()
            end
        end
    end
    
    -- Crear o actualizar tarjetas en el orden correcto (FIFO: las más nuevas primero)
    for i, item in ipairs(currentData) do
        if i <= MAX_TRADES_CARDS then
            if not existingCards[item.id] then
                local card = createPlayerCard(item, i, true)
                card:SetAttribute("ItemId", item.id)
                card.Name = "TradeCard_" .. item.id
                card.LayoutOrder = i  -- LayoutOrder = posición en la lista (1 = más nuevo)
                card.Parent = playersFrame
            else
                -- Actualizar LayoutOrder si la posición cambió
                existingCards[item.id].LayoutOrder = i
            end
        end
    end
    
    -- Eliminar tarjetas que ya no existen o exceden el límite
    local allCards = {}
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:match("^TradeCard_") or child.Name:match("^Card_")) then
            local id = child:GetAttribute("ItemId")
            if id then
                -- Verificar si el item todavía existe en currentData
                local stillExists = false
                for _, item in ipairs(currentData) do
                    if item.id == id then
                        stillExists = true
                        break
                    end
                end
                if stillExists then
                    table.insert(allCards, child)
                else
                    child:Destroy()
                end
            else
                child:Destroy()
            end
        end
    end
    
    -- Ordenar tarjetas por LayoutOrder (menor número = más nuevo, va arriba)
    table.sort(allCards, function(a, b)
        local aOrder = a.LayoutOrder or 999
        local bOrder = b.LayoutOrder or 999
        return aOrder < bOrder
    end)
    
    -- Reasignar LayoutOrder secuencialmente
    for i, card in ipairs(allCards) do
        card.LayoutOrder = i
    end
    
    -- Limitar a MAX_TRADES_CARDS (eliminar las más viejas si hay muchas)
    if #allCards > MAX_TRADES_CARDS then
        for i = MAX_TRADES_CARDS + 1, #allCards do
            allCards[i]:Destroy()
        end
    end
    
    -- Calcular altura total del canvas
    local totalHeight = 0
    for _, child in ipairs(playersFrame:GetChildren()) do
        if child:IsA("Frame") and (child.Name:match("^TradeCard_") or child.Name:match("^Card_")) then
            totalHeight = totalHeight + child.AbsoluteSize.Y + 8
        end
    end
    
    playersFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, 50))
    
    -- Mostrar mensaje si no hay datos
    local emptyMsg = playersFrame:FindFirstChild("EmptyMessage")
    if emptyMsg then emptyMsg:Destroy() end
    
    if #allCards == 0 then
        emptyMsg = Instance.new("TextLabel")
        emptyMsg.Name = "EmptyMessage"
        emptyMsg.Size = UDim2.new(1, 0, 0, 40)
        emptyMsg.Position = UDim2.new(0, 0, 0.5, -20)
        emptyMsg.AnchorPoint = Vector2.new(0, 0.5)
        emptyMsg.BackgroundTransparency = 1
        emptyMsg.Text = "📦 No hay ofertas de trade"
        emptyMsg.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyMsg.TextSize = 13
        emptyMsg.Font = Enum.Font.Gotham
        emptyMsg.Parent = playersFrame
    end
end

-- ──────────────────────────────────

openPvPFinder = function()
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
    end
    if isChatVisible then
        isChatVisible = false
        main.Visible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    if isNotesWindowVisible and notesGuiInstance then
        notesGuiInstance:Destroy()
        notesGuiInstance = nil
        isNotesWindowVisible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
        return
    end
    isPvPFinderVisible = true
    pvpGuiInstance = Instance.new("Frame")
    pvpGuiInstance.Size = UDim2.new(0, 280, 0, 320)
    pvpGuiInstance.Position = UDim2.new(0.5, -140, 0.5, -160)
    pvpGuiInstance.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    pvpGuiInstance.BackgroundTransparency = 0.15
    pvpGuiInstance.BorderSizePixel = 0
    pvpGuiInstance.ZIndex = 1000
    pvpGuiInstance.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = pvpGuiInstance
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚔️ PvP Finder"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.ZIndex = 1001
    title.Parent = pvpGuiInstance
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    local sideTab = createSideTab(pvpGuiInstance)
    local vipTab = createSideTabVIP(pvpGuiInstance)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 1002
    closeBtn.Parent = pvpGuiInstance
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if pvpGuiInstance then
            pvpGuiInstance:Destroy()
            pvpGuiInstance = nil
            isPvPFinderVisible = false
        end
    end)
    local toolbar = Instance.new("Frame")
    toolbar.Size = UDim2.new(1, -10, 0, 30)
    toolbar.Position = UDim2.new(0, 5, 0, 40)
    toolbar.BackgroundTransparency = 1
    toolbar.ZIndex = 1000
    toolbar.Parent = pvpGuiInstance
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0.45, -5, 1, 0)
    addBtn.Position = UDim2.new(0, 0, 0, 0)
    addBtn.Text = "[ Añadir ]"
    addBtn.TextColor3 = Color3.fromRGB(100, 200, 100)
    addBtn.TextSize = 12
    addBtn.Font = Enum.Font.GothamBold
    addBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    addBtn.BackgroundTransparency = 0.3
    addBtn.BorderSizePixel = 0
    addBtn.ZIndex = 1000
    addBtn.Parent = toolbar
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 5)
    addCorner.Parent = addBtn
    local filterBtn = Instance.new("TextButton")
    filterBtn.Size = UDim2.new(0.45, -5, 1, 0)
    filterBtn.Position = UDim2.new(0.55, 0, 0, 0)
    filterBtn.Text = "[ Filtro ]"
    filterBtn.TextColor3 = Color3.fromRGB(100, 150, 255)
    filterBtn.TextSize = 12
    filterBtn.Font = Enum.Font.GothamBold
    filterBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    filterBtn.BackgroundTransparency = 0.3
    filterBtn.BorderSizePixel = 0
    filterBtn.ZIndex = 1000
    filterBtn.Parent = toolbar
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, 5)
    filterCorner.Parent = filterBtn
    local function setupButtonHover(button)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
        end)
    end
    setupButtonHover(addBtn)
    setupButtonHover(filterBtn)
    local playersFrame = Instance.new("ScrollingFrame")
    playersFrame.Name = "PlayersScrollingFrame"
    playersFrame.Size = UDim2.new(1, -10, 1, -80)
    playersFrame.Position = UDim2.new(0, 5, 0, 75)
    playersFrame.BackgroundTransparency = 1
    playersFrame.BorderSizePixel = 0
    playersFrame.ScrollBarThickness = 3
    playersFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playersFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    playersFrame.ZIndex = 1000
    playersFrame.Parent = pvpGuiInstance
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Name = "MainLayout"
    mainLayout.Padding = UDim.new(0, 8)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = playersFrame
    local framePadding = Instance.new("UIPadding")
    framePadding.Name = "FramePadding"
    framePadding.PaddingTop = UDim.new(0, 5)
    framePadding.PaddingLeft = UDim.new(0, 2)
    framePadding.PaddingRight = UDim.new(0, 2)
    framePadding.Parent = playersFrame
    addBtn.MouseButton1Click:Connect(function()
        if pvpGuiInstance then
            pvpGuiInstance:Destroy()
            pvpGuiInstance = nil
            isPvPFinderVisible = false
        end
        showAnimalSelectionMenu(false)
    end)
    filterBtn.MouseButton1Click:Connect(function()
        openFilterWindow()
    end)
    updatePlayersListIncremental()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = pvpGuiInstance.Position
            local connection
            connection = UserInputService.InputChanged:Connect(function(inputChanged)
                if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inputChanged.Position - dragStart
                    pvpGuiInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            local releaseConnection
            releaseConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if not pvpGuiInstance or not pvpGuiInstance.Parent then
            if updateConnection then updateConnection:Disconnect() end
            return
        end
        if not useWebSocket or #cachedDuelsData == 0 then
            if tick() % 10 < 0.1 then
                updatePlayersListIncremental()
            end
        end
    end)
    pvpGuiInstance.Destroying:Connect(function()
        isPvPFinderVisible = false
        pvpGuiInstance = nil
        if updateConnection then updateConnection:Disconnect() end
    end)
end

-- ──────────────────────────────────

openTradeFinder = function()
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
    end
    if isChatVisible then
        isChatVisible = false
        main.Visible = false
    end
    if isNotesWindowVisible and notesGuiInstance then
        notesGuiInstance:Destroy()
        notesGuiInstance = nil
        isNotesWindowVisible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
        return
    end
    isTradeFinderVisible = true
    tradeGuiInstance = Instance.new("Frame")
    tradeGuiInstance.Size = UDim2.new(0, 280, 0, 320)
    tradeGuiInstance.Position = UDim2.new(0.5, -140, 0.5, -160)
    tradeGuiInstance.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tradeGuiInstance.BackgroundTransparency = 0.15
    tradeGuiInstance.BorderSizePixel = 0
    tradeGuiInstance.ZIndex = 1000
    tradeGuiInstance.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = tradeGuiInstance
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "📦 Trade Finder"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.ZIndex = 1001
    title.Parent = tradeGuiInstance
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    local sideTab = createSideTab(tradeGuiInstance)
    local vipTab = createSideTabVIP(tradeGuiInstance)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 1002
    closeBtn.Parent = tradeGuiInstance
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if tradeGuiInstance then
            tradeGuiInstance:Destroy()
            tradeGuiInstance = nil
            isTradeFinderVisible = false
        end
    end)
    local toolbar = Instance.new("Frame")
    toolbar.Size = UDim2.new(1, -10, 0, 30)
    toolbar.Position = UDim2.new(0, 5, 0, 40)
    toolbar.BackgroundTransparency = 1
    toolbar.ZIndex = 1000
    toolbar.Parent = tradeGuiInstance
    local offerBtn = Instance.new("TextButton")
    offerBtn.Size = UDim2.new(0.45, -5, 1, 0)
    offerBtn.Position = UDim2.new(0, 0, 0, 0)
    offerBtn.Text = "[ Ofrecer ]"
    offerBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
    offerBtn.TextSize = 12
    offerBtn.Font = Enum.Font.GothamBold
    offerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    offerBtn.BackgroundTransparency = 0.3
    offerBtn.BorderSizePixel = 0
    offerBtn.ZIndex = 1000
    offerBtn.Parent = toolbar
    local offerCorner = Instance.new("UICorner")
    offerCorner.CornerRadius = UDim.new(0, 5)
    offerCorner.Parent = offerBtn
    local filterBtn = Instance.new("TextButton")
    filterBtn.Size = UDim2.new(0.45, -5, 1, 0)
    filterBtn.Position = UDim2.new(0.55, 0, 0, 0)
    filterBtn.Text = "[ Filtro ]"
    filterBtn.TextColor3 = Color3.fromRGB(100, 150, 255)
    filterBtn.TextSize = 12
    filterBtn.Font = Enum.Font.GothamBold
    filterBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    filterBtn.BackgroundTransparency = 0.3
    filterBtn.BorderSizePixel = 0
    filterBtn.ZIndex = 1000
    filterBtn.Parent = toolbar
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, 5)
    filterCorner.Parent = filterBtn
    local function setupButtonHover(button)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
        end)
    end
    setupButtonHover(offerBtn)
    setupButtonHover(filterBtn)
    local playersFrame = Instance.new("ScrollingFrame")
    playersFrame.Name = "TradePlayersScrollingFrame"
    playersFrame.Size = UDim2.new(1, -10, 1, -80)
    playersFrame.Position = UDim2.new(0, 5, 0, 75)
    playersFrame.BackgroundTransparency = 1
    playersFrame.BorderSizePixel = 0
    playersFrame.ScrollBarThickness = 3
    playersFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playersFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    playersFrame.ZIndex = 1000
    playersFrame.Parent = tradeGuiInstance
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Name = "MainLayout"
    mainLayout.Padding = UDim.new(0, 8)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = playersFrame
    local framePadding = Instance.new("UIPadding")
    framePadding.Name = "FramePadding"
    framePadding.PaddingTop = UDim.new(0, 5)
    framePadding.PaddingLeft = UDim.new(0, 2)
    framePadding.PaddingRight = UDim.new(0, 2)
    framePadding.Parent = playersFrame
    offerBtn.MouseButton1Click:Connect(function()
        if tradeGuiInstance then
            tradeGuiInstance:Destroy()
            tradeGuiInstance = nil
            isTradeFinderVisible = false
        end
        showAnimalSelectionMenu(true)
    end)
    filterBtn.MouseButton1Click:Connect(function()
        openFilterWindow()
    end)
    updateTradePlayersListIncremental()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = tradeGuiInstance.Position
            local connection
            connection = UserInputService.InputChanged:Connect(function(inputChanged)
                if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inputChanged.Position - dragStart
                    tradeGuiInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            local releaseConnection
            releaseConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if not tradeGuiInstance or not tradeGuiInstance.Parent then
            if updateConnection then updateConnection:Disconnect() end
            return
        end
        if not useWebSocket or #cachedTradesData == 0 then
            if tick() % 10 < 0.1 then
                updateTradePlayersListIncremental()
            end
        end
    end)
    tradeGuiInstance.Destroying:Connect(function()
        isTradeFinderVisible = false
        tradeGuiInstance = nil
        if updateConnection then updateConnection:Disconnect() end
    end)
end

-- ──────────────────────────────────

--[[ 
local function toggleChat()
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    isChatVisible = not isChatVisible
    main.Visible = isChatVisible
    if isChatVisible then
        input:CaptureFocus()
        lastMessageId = ""
        task.spawn(function()
            task.wait(0.1)
            scrolling.CanvasPosition = Vector2.new(0, scrolling.CanvasSize.Y.Offset)
        end)
    end
end

local function cleanupOldMessages()
    local messageContainers = {}
    for _, child in ipairs(scrolling:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(messageContainers, child)
        end
    end
    if #messageContainers > MAX_MESSAGES then
        table.sort(messageContainers, function(a, b)
            return a.LayoutOrder < b.LayoutOrder
        end)
        local toRemove = #messageContainers - MAX_MESSAGES
        for i = 1, toRemove do
            local oldest = messageContainers[i]
            for messageId, data in pairs(shownMessages) do
                if data.container == oldest then
                    shownMessages[messageId] = nil
                    break
                end
            end
            oldest:Destroy()
        end
    end
end

local function createMessageLabel(username, text, messageId, isOwnMessage, userId)
    if shownMessages[messageId] then return nil end
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = scrolling
    local horizontalLayout = Instance.new("UIListLayout")
    horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
    horizontalLayout.Padding = UDim.new(0, 5)
    horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    horizontalLayout.Parent = container
    messageCounter = messageCounter + 1
    container.LayoutOrder = messageCounter
    local inviteButton = nil
    if userId and userId > 0 and not isOwnMessage then
        inviteButton = Instance.new("TextButton")
        inviteButton.Size = UDim2.new(0, 60, 0, 20)
        inviteButton.Text = "⚔️ Invite"
        inviteButton.TextSize = 10
        inviteButton.TextColor3 = Color3.new(1, 1, 1)
        inviteButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        inviteButton.BorderSizePixel = 0
        local inviteCorner = Instance.new("UICorner")
        inviteCorner.CornerRadius = UDim.new(0, 4)
        inviteCorner.Parent = inviteButton
        inviteButton.LayoutOrder = 1
        inviteButton.Parent = container
        inviteButton.MouseEnter:Connect(function()
            TweenService:Create(inviteButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 200, 80)}):Play()
        end)
        inviteButton.MouseLeave:Connect(function()
            TweenService:Create(inviteButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 167, 69)}):Play()
        end)
        inviteButton.MouseButton1Click:Connect(function()
            showInvitePopup(username, userId, false)
        end)
    end
    local textContainer = Instance.new("Frame")
    textContainer.Size = UDim2.new(1, (inviteButton and -65 or -10), 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.AutomaticSize = Enum.AutomaticSize.Y
    textContainer.LayoutOrder = 2
    textContainer.Parent = container
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextColor3 = isOwnMessage and Color3.fromRGB(100, 200, 255) or Color3.new(1, 1, 1)
    label.TextSize = 12
    label.RichText = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Parent = textContainer
    local usernameColor = isOwnMessage and "100,200,255" or "255,215,0"
    label.Text = string.format('<font color="rgb(%s)"><b>%s:</b></font> %s', usernameColor, username, text:sub(1, 200))
    shownMessages[messageId] = {
        username = username,
        text = text,
        time = os.time(),
        container = container,
        label = label,
        order = messageCounter,
        userId = userId,
        inviteButton = inviteButton
    }
    local currentTime = os.time()
    for id, data in pairs(shownMessages) do
        if currentTime - data.time > 300 then
            if data.container and data.container.Parent then
                data.container:Destroy()
            end
            shownMessages[id] = nil
        end
    end
    cleanupOldMessages()
    task.spawn(function()
        task.wait(0.05)
        scrolling.CanvasPosition = Vector2.new(0, scrolling.CanvasSize.Y.Offset)
    end)
    if pendingMessages[messageId] then
        pendingMessages[messageId] = nil
    end
    return container
end

local function sendMessage(text)
    if text == "" or #text > MAX_CHARACTERS then return end
    local messageId = HttpService:GenerateGUID(false)
    pendingMessages[messageId] = {
        username = player.Name,
        text = text,
        timestamp = os.time()
    }
    createMessageLabel(player.Name, text, messageId, true, player.UserId)
    task.spawn(function()
        local data = {
            id = messageId,
            username = player.Name,
            text = text,
            avatar = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=100&height=100&format=png"
        }
        local success, response = pcall(function()
            return request({
                Url = URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
        if not success or not response then
            showNotification("❌ Error", "Failed to send message", 3, true)
        end
    end)
    input.Text = ""
    input:CaptureFocus()
end


local function fetchMessages()
    if isPolling or not isChatVisible then return end
    isPolling = true
    local success, response = pcall(function()
        local url = URL .. "?limit=20"
        if lastMessageId ~= "" then
            url = URL .. "?limit=20&since=" .. lastMessageId
        end
        return request({
            Url = url,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache"
            }
        })
    end)
 
    isPolling = false

    if success and response and response.Body then
        local success2, messages = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if success2 and messages then
            table.sort(messages, function(a, b)
                return (a.timestamp or 0) < (b.timestamp or 0)
            end)
            for _, msg in ipairs(messages) do
                if not shownMessages[msg.id] then
                    local isOwnMessage = (msg.username == player.Name) and pendingMessages[msg.id] ~= nil
                    local userId = nil
                    if msg.avatar and type(msg.avatar) == "string" then
                        local idMatch = msg.avatar:match("userId=(%d+)")
                        if idMatch then userId = tonumber(idMatch) end
                    end
                    createMessageLabel(msg.username, msg.text, msg.id, isOwnMessage, userId)
                    lastMessageId = msg.id
                end
            end
        end
    end
end

]]

-- ──────────────────────────────────

pvpBtn.MouseButton1Click:Connect(openPvPFinder)
tradeBtn.MouseButton1Click:Connect(openTradeFinder)
send.MouseButton1Click:Connect(function()
    sendMessage(input.Text)
end)
input.FocusLost:Connect(function(enter)
    if enter then
        sendMessage(input.Text)
    end
end)

task.spawn(function()
    while true do
        if isChatVisible then
            fetchMessages()
            task.wait(0.8)
        else
            task.wait(5)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        toggleChat()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        openPvPFinder()
    elseif input.KeyCode == Enum.KeyCode.F10 then
        openTradeFinder()
    elseif input.KeyCode == Enum.KeyCode.Slash and isChatVisible then
        input:CaptureFocus()
    end
end)

--[[ 
task.spawn(function()
    task.wait(3)
    local success, response = pcall(function()
        return request({
            Url = URL .. "?limit=20",
            Method = "GET",
            Headers = {["Cache-Control"] = "no-cache"}
        })
    end)
    if success and response then
        local ok, messages = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if ok and messages then
            table.sort(messages, function(a, b)
                return (a.timestamp or 0) > (b.timestamp or 0)
            end)
            for i = 1, math.min(20, #messages) do
                local msg = messages[i]
                if not shownMessages[msg.id] then
                    local userId = nil
                    if msg.avatar and type(msg.avatar) == "string" then
                        local idMatch = msg.avatar:match("userId=(%d+)")
                        if idMatch then userId = tonumber(idMatch) end
                    end
                    createMessageLabel(msg.username, msg.text, msg.id, msg.username == player.Name, userId)
                end
            end
        end
    end
end)
]]

-- ──────────────────────────────────

filterData = {
    whitelist = {},
    enabled = false,
    searchText = ""
}

local FILTER_FILE = "ZLChat_Filter_Whitelist.txt"

local function saveWhitelist()
    local success, err = pcall(function()
        if not writefile then return end
        local data = HttpService:JSONEncode(filterData.whitelist)
        writefile(FILTER_FILE, data)
    end)
end

local function loadWhitelist()
    local success, err = pcall(function()
        if not readfile then return end
        if isfile(FILTER_FILE) then
            local data = readfile(FILTER_FILE)
            local loaded = HttpService:JSONDecode(data)
            if type(loaded) == "table" then
                filterData.whitelist = loaded
            end
        end
    end)
    if not success then filterData.whitelist = {} end
end

loadWhitelist()

isAnimalInWhitelist = function(animalName)
    if not filterData.enabled then return true end
    if #filterData.whitelist == 0 then return true end
    
    -- Convertir a minúsculas para comparación case-insensitive
    local animalLower = string.lower(animalName or "")
    
    for _, whitelisted in ipairs(filterData.whitelist) do
        local whitelistedLower = string.lower(whitelisted)
        -- Comparación exacta o parcial (por si hay nombres con espacios)
        if animalLower == whitelistedLower or 
           string.find(animalLower, whitelistedLower) or 
           string.find(whitelistedLower, animalLower) then
            return true
        end
    end
    return false
end


local function searchAnimalsFromModels(searchText)
    if not searchText or #searchText < 3 then return {} end
    
    local searchLower = string.lower(searchText)
    local results = {}
    local allNames = getAllAnimalNames()
    
    if #allNames == 0 then
        print("⚠️ No se encontraron nombres en Brainrot...")
        -- Debug: mostrar qué es BrainrotSizes
        
        if BrainrotSizes and BrainrotSizes:IsA("Folder") then
            
        end
        return results
    end
    
    
    -- Buscar coincidencias
    for _, name in ipairs(allNames) do
        local nameLower = string.lower(name)
        if string.find(nameLower, searchLower, 1, true) then
            local model = BrainrotAssets.getModel(name)
            if model then
                table.insert(results, {
                    name = name,
                    model = model,
                    matchScore = #searchLower / #nameLower
                })
                
            else
                
            end
        end
    end
    
    -- Ordenar por puntuación
    table.sort(results, function(a, b)
        return a.matchScore > b.matchScore
    end)
    
    
    return results
end


-- ──────────────────────────────────

openFilterWindow = function()
    if isChatVisible then
        isChatVisible = false
        main.Visible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
        return
    end
    isFilterWindowVisible = true
    filterGuiInstance = Instance.new("Frame")
    filterGuiInstance.Size = UDim2.new(0, 280, 0, 320)
    filterGuiInstance.Position = UDim2.new(0.5, -140, 0.5, -160)
    filterGuiInstance.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    filterGuiInstance.BackgroundTransparency = 0.15
    filterGuiInstance.BorderSizePixel = 0
    filterGuiInstance.ZIndex = 100
    filterGuiInstance.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = filterGuiInstance
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🐾 Whitelist Manager"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.ZIndex = 1001
    title.Parent = filterGuiInstance
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 1002
    closeBtn.Parent = filterGuiInstance
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if filterGuiInstance then
            filterGuiInstance:Destroy()
            filterGuiInstance = nil
            isFilterWindowVisible = false
        end
    end)
    local toolbar = Instance.new("Frame")
    toolbar.Size = UDim2.new(1, -10, 0, 30)
    toolbar.Position = UDim2.new(0, 5, 0, 40)
    toolbar.BackgroundTransparency = 1
    toolbar.ZIndex = 5000
    toolbar.Parent = filterGuiInstance
    local toggleFilterBtn = Instance.new("TextButton")
    toggleFilterBtn.Size = UDim2.new(0.45, -5, 1, 0)
    toggleFilterBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleFilterBtn.Text = filterData.enabled and "✓ Filter ON" or "✗ Filter OFF"
    toggleFilterBtn.TextColor3 = filterData.enabled and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
    toggleFilterBtn.TextSize = 11
    toggleFilterBtn.Font = Enum.Font.GothamBold
    toggleFilterBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleFilterBtn.BackgroundTransparency = 0.3
    toggleFilterBtn.BorderSizePixel = 0
    toggleFilterBtn.ZIndex = 1000
    toggleFilterBtn.Parent = toolbar
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggleFilterBtn
    local clearWhitelistBtn = Instance.new("TextButton")
    clearWhitelistBtn.Size = UDim2.new(0.45, -5, 1, 0)
    clearWhitelistBtn.Position = UDim2.new(0.55, 0, 0, 0)
    clearWhitelistBtn.Text = "[ Limpiar ]"
    clearWhitelistBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    clearWhitelistBtn.TextSize = 11
    clearWhitelistBtn.Font = Enum.Font.GothamBold
    clearWhitelistBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    clearWhitelistBtn.BackgroundTransparency = 0.3
    clearWhitelistBtn.BorderSizePixel = 0
    clearWhitelistBtn.ZIndex = 1000
    clearWhitelistBtn.Parent = toolbar
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 5)
    clearCorner.Parent = clearWhitelistBtn
    local function setupButtonHover(button)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
        end)
    end
    setupButtonHover(toggleFilterBtn)
    setupButtonHover(clearWhitelistBtn)
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -10, 0, 35)
    searchBox.Position = UDim2.new(0, 5, 0, 75)
    searchBox.PlaceholderText = "🔍 Search animal (min 3 letters)..."
    searchBox.Text = ""
    searchBox.TextSize = 12
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    searchBox.BackgroundTransparency = 0.3
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 1000
    searchBox.Parent = filterGuiInstance
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchBox
    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Name = "ResultsScrollingFrame"
    resultsFrame.Size = UDim2.new(1, -10, 1, -130)
    resultsFrame.Position = UDim2.new(0, 5, 0, 115)
    resultsFrame.BackgroundTransparency = 1
    resultsFrame.BorderSizePixel = 0
    resultsFrame.ScrollBarThickness = 3
    resultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    resultsFrame.ZIndex = 10
    resultsFrame.Parent = filterGuiInstance
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Padding = UDim.new(0, 6)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = resultsFrame
    local framePadding = Instance.new("UIPadding")
    framePadding.PaddingTop = UDim.new(0, 5)
    framePadding.PaddingLeft = UDim.new(0, 2)
    framePadding.PaddingRight = UDim.new(0, 2)
    framePadding.Parent = resultsFrame
    
    local function clearResults()
        for _, child in ipairs(resultsFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "MainLayout" and child.Name ~= "FramePadding" then
                child:Destroy()
            end
        end
    end
    
    local function createAnimalCard(animal, isInWhitelist, layoutOrder)
        local cardHeight = 75
        local card = Instance.new("Frame")
        card.Name = "AnimalCard_" .. animal.name
        card.Size = UDim2.new(1, 0, 0, cardHeight)
        card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.LayoutOrder = layoutOrder
        card.ZIndex = 2000
        card.Parent = resultsFrame
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card
        local innerContainer = Instance.new("Frame")
        innerContainer.Name = "InfoContainer"
        innerContainer.Size = UDim2.new(1, -10, 1, -10)
        innerContainer.Position = UDim2.new(0, 5, 0, 5)
        innerContainer.BackgroundTransparency = 1
        innerContainer.ZIndex = 5600
        innerContainer.Parent = card
        local horizontalLayout = Instance.new("UIListLayout")
        horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
        horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        horizontalLayout.Padding = UDim.new(0, 10)
        horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
        horizontalLayout.Parent = innerContainer
        local viewportContainer = Instance.new("Frame")
        viewportContainer.Size = UDim2.new(0, 60, 1, 0)
        viewportContainer.BackgroundTransparency = 1
        viewportContainer.LayoutOrder = 1
        viewportContainer.ZIndex = 5600
        viewportContainer.Parent = innerContainer
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, 0, 1, 0)
        viewport.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        viewport.BorderSizePixel = 1
        viewport.BorderColor3 = Color3.fromRGB(60, 60, 60)
        viewport.ZIndex = 5700
        viewport.Parent = viewportContainer
        local viewportCorner = Instance.new("UICorner")
        viewportCorner.CornerRadius = UDim.new(0, 6)
        viewportCorner.Parent = viewport
        local camera = Instance.new("Camera")
        camera.FieldOfView = 45
        viewport.CurrentCamera = camera
        camera.Parent = viewport
        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport
        task.spawn(function()
            if animal.model then
                local clone = animal.model:Clone()
                clone.Parent = worldModel
                if not clone.PrimaryPart then
                    local root = clone:FindFirstChild("RootPart", true)
                    if root and root:IsA("BasePart") then
                        clone.PrimaryPart = root
                    end
                end
                if clone.PrimaryPart then
                    clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(160), 0))
                    local _, size = clone:GetBoundingBox()
                    local maxSize = math.max(size.X, size.Y, size.Z)
                    camera.CFrame = CFrame.new(Vector3.new(0, size.Y/2, maxSize * 1.6), Vector3.new(0, size.Y/2, 0))
                end
            end
        end)
        local infoContainer = Instance.new("Frame")
        infoContainer.Name = "TextInfoContainer"
        infoContainer.Size = UDim2.new(0.5, 0, 1, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.LayoutOrder = 2
        infoContainer.ZIndex = 5600
        infoContainer.Parent = innerContainer
        local verticalLayout = Instance.new("UIListLayout")
        verticalLayout.Padding = UDim.new(0, 4)
        verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        verticalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        verticalLayout.SortOrder = Enum.SortOrder.LayoutOrder
        verticalLayout.Parent = infoContainer
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0, 25)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = animal.name
        nameLabel.TextColor3 = isInWhitelist and Color3.fromRGB(40, 200, 255) or Color3.fromRGB(255, 215, 0)
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.LayoutOrder = 1
        nameLabel.ZIndex = 2000
        nameLabel.Parent = infoContainer
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0, 18)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = isInWhitelist and "✅ In Whitelist" or "❌ Not in Whitelist"
        statusLabel.TextColor3 = isInWhitelist and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(150, 150, 150)
        statusLabel.TextSize = 10
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.LayoutOrder = 2
        statusLabel.ZIndex = 5600
        statusLabel.Parent = infoContainer
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Size = UDim2.new(0, 65, 1, 0)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.LayoutOrder = 3
        buttonContainer.ZIndex = 5600
        buttonContainer.Parent = innerContainer
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, 0, 0.5, 0)
        actionBtn.Position = UDim2.new(0, 0, 0.25, 0)
        actionBtn.Text = isInWhitelist and "Remove" or "Add"
        actionBtn.TextColor3 = Color3.new(1, 1, 1)
        actionBtn.TextSize = 11
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.BackgroundColor3 = isInWhitelist and Color3.fromRGB(220, 53, 69) or Color3.fromRGB(40, 167, 69)
        actionBtn.BorderSizePixel = 0
        actionBtn.ZIndex = 5700
        actionBtn.Parent = buttonContainer
        local actionCorner = Instance.new("UICorner")
        actionCorner.CornerRadius = UDim.new(0, 6)
        actionCorner.Parent = actionBtn
        actionBtn.MouseEnter:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = isInWhitelist and Color3.fromRGB(240, 70, 85) or Color3.fromRGB(50, 200, 80)}):Play()
        end)
        actionBtn.MouseLeave:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = isInWhitelist and Color3.fromRGB(220, 53, 69) or Color3.fromRGB(40, 167, 69)}):Play()
        end)
        actionBtn.MouseButton1Click:Connect(function()
            if isInWhitelist then
                local newWhitelist = {}
                for _, wlAnimal in ipairs(filterData.whitelist) do
                    if string.lower(wlAnimal) ~= string.lower(animal.name) then
                        table.insert(newWhitelist, wlAnimal)
                    end
                end
                filterData.whitelist = newWhitelist
                saveWhitelist()
                showNotification("🗑️ Removed", string.format("%s removed from whitelist", animal.name), 2)
                displaySearchResults(searchBox.Text)
            else
                table.insert(filterData.whitelist, animal.name)
                saveWhitelist()
                showNotification("➕ Added", string.format("%s added to whitelist", animal.name), 2)
                displaySearchResults(searchBox.Text)
            end
            if toggleFilterBtn then
                toggleFilterBtn.Text = filterData.enabled and "✓ Filter ON" or "✗ Filter OFF"
            end
        end)
        return card
    end
    
    getAllAnimalNames = function()
    local names = {}
    if not BrainrotSizes then
        warn("⚠️ BrainrotSizes no encontrado")
        return names
    end
    
    -- Obtener TODOS los hijos, sin importar el tipo
    for _, child in ipairs(BrainrotSizes:GetChildren()) do
        -- Solo obtener el nombre, sin filtrar por tipo
        table.insert(names, child.Name)
    end
    
    return names
end

local function getSuggestions(searchText)
    if not searchText or #searchText < 2 then return {} end
    local searchLower = string.lower(searchText)
    local suggestions = {}
    local allNames = getAllAnimalNames()
    
    for _, name in ipairs(allNames) do
        local nameLower = string.lower(name)
        if string.find(nameLower, searchLower, 1, true) then
            table.insert(suggestions, name)
        end
    end
    
    -- Limitar a 10 sugerencias
    if #suggestions > 10 then
        local temp = {}
        for i = 1, 10 do
            table.insert(temp, suggestions[i])
        end
        suggestions = temp
    end
    
    return suggestions
end
    
    displaySearchResults = function(searchText)
    local trimmedText = string.gsub(searchText, "^%s*(.-)%s*$", "%1")
    clearResults()
    local emptyMsg = resultsFrame:FindFirstChild("EmptyMessage")
    if emptyMsg then emptyMsg:Destroy() end
    
    if #trimmedText < 3 then
        -- Mostrar la whitelist completa
        if #filterData.whitelist == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Name = "EmptyMessage"
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.Position = UDim2.new(0, 0, 0.5, -20)
            emptyLabel.AnchorPoint = Vector2.new(0, 0.5)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "📋 No animals in whitelist yet.\n🔍 Type at least 3 letters to search..."
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.TextSize = 11
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextWrapped = true
            emptyLabel.ZIndex = 5000
            emptyLabel.Parent = resultsFrame
            resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 60)
            return
        end
        
        -- Mostrar animales en whitelist (usando BrainrotAssets.getModel)
        -- Mostrar animales en whitelist (usando BrainrotAssets.getModel)
local whitelistAnimals = {}
for _, animalName in ipairs(filterData.whitelist) do
    local model = BrainrotAssets.getModel(animalName)
    if model then
        table.insert(whitelistAnimals, {name = animalName, model = model})
    end
end
        table.sort(whitelistAnimals, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
        
        local totalHeight = 0
        local cardHeight = 75
        local spacing = 6
        local layoutOrderCounter = 1
        
        local titleFrame = Instance.new("Frame")
        titleFrame.Name = "WhitelistTitle"
        titleFrame.Size = UDim2.new(1, 0, 0, 30)
        titleFrame.BackgroundTransparency = 1
        titleFrame.LayoutOrder = layoutOrderCounter
        titleFrame.Parent = resultsFrame
        layoutOrderCounter = layoutOrderCounter + 1
        totalHeight = totalHeight + 30
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 1, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "📋 MY WHITELIST (" .. #whitelistAnimals .. " animals)"
        titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        titleLabel.TextSize = 12
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Center
        titleLabel.Parent = titleFrame
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -20, 0, 1)
        line.Position = UDim2.new(0, 10, 1, -5)
        line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        line.BorderSizePixel = 0
        line.Parent = titleFrame
        
        for _, animal in ipairs(whitelistAnimals) do
            createAnimalCard(animal, true, layoutOrderCounter)
            layoutOrderCounter = layoutOrderCounter + 1
            totalHeight = totalHeight + cardHeight + spacing
        end
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
        return
    end
    
    -- Buscar coincidencias con el texto ingresado
    local searchResults = searchAnimalsFromModels(trimmedText)
    
    if #searchResults == 0 then
        local noResults = Instance.new("TextLabel")
        noResults.Name = "EmptyMessage"
        noResults.Size = UDim2.new(1, 0, 0, 40)
        noResults.Position = UDim2.new(0, 0, 0.5, -20)
        noResults.AnchorPoint = Vector2.new(0, 0.5)
        noResults.BackgroundTransparency = 1
        noResults.Text = "❌ No animals found for: " .. trimmedText
        noResults.TextColor3 = Color3.fromRGB(255, 100, 100)
        noResults.TextSize = 12
        noResults.Font = Enum.Font.Gotham
        noResults.TextWrapped = true
        noResults.ZIndex = 5000
        noResults.Parent = resultsFrame
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 50)
        return
    end
    
    -- Separar en whitelist y no whitelist
    local whitelistResults = {}
    local otherResults = {}
    for _, animal in ipairs(searchResults) do
        local isInWhitelist = false
        for _, wlAnimal in ipairs(filterData.whitelist) do
            if string.lower(wlAnimal) == string.lower(animal.name) then
                isInWhitelist = true
                break
            end
        end
        if isInWhitelist then
            table.insert(whitelistResults, animal)
        else
            table.insert(otherResults, animal)
        end
    end
    
    -- Ordenar ambos resultados
    table.sort(whitelistResults, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    table.sort(otherResults, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    
    local totalHeight = 0
    local cardHeight = 75
    local spacing = 6
    local separatorHeight = 25
    local layoutOrderCounter = 1
    
    -- Función para crear separador
    local function createSeparator(title, layoutOrder)
        local separator = Instance.new("Frame")
        separator.Name = "Separator_" .. title
        separator.Size = UDim2.new(1, 0, 0, separatorHeight)
        separator.BackgroundTransparency = 1
        separator.LayoutOrder = layoutOrder
        separator.Parent = resultsFrame
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0.9, 0, 0, 1)
        line.Position = UDim2.new(0.05, 0, 0.5, 0)
        line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        line.BorderSizePixel = 0
        line.Parent = separator
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(0, 0, 1, 0)
        titleLabel.Position = UDim2.new(0.5, 0, 0, 0)
        titleLabel.AnchorPoint = Vector2.new(0.5, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        titleLabel.TextSize = 10
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Center
        titleLabel.AutomaticSize = Enum.AutomaticSize.X
        titleLabel.Parent = separator
        titleLabel.Position = UDim2.new(0.5, -titleLabel.TextBounds.X/2, 0, -8)
        return separator
    end
    
    -- Mostrar resultados en whitelist primero
    if #whitelistResults > 0 then
        createSeparator("📋 IN WHITELIST (" .. #whitelistResults .. ")", layoutOrderCounter)
        layoutOrderCounter = layoutOrderCounter + 1
        totalHeight = totalHeight + separatorHeight
        
        for _, animal in ipairs(whitelistResults) do
            createAnimalCard(animal, true, layoutOrderCounter)
            layoutOrderCounter = layoutOrderCounter + 1
            totalHeight = totalHeight + cardHeight + spacing
        end
        
        if #otherResults > 0 then
            local spacer = Instance.new("Frame")
            spacer.Name = "Spacer"
            spacer.Size = UDim2.new(1, 0, 0, 10)
            spacer.BackgroundTransparency = 1
            spacer.LayoutOrder = layoutOrderCounter
            spacer.Parent = resultsFrame
            layoutOrderCounter = layoutOrderCounter + 1
            totalHeight = totalHeight + 10
        end
    end
    
    -- Mostrar otros resultados
    if #otherResults > 0 then
        createSeparator("🔍 OTHER RESULTS (" .. #otherResults .. ")", layoutOrderCounter)
        layoutOrderCounter = layoutOrderCounter + 1
        totalHeight = totalHeight + separatorHeight
        
        for _, animal in ipairs(otherResults) do
            createAnimalCard(animal, false, layoutOrderCounter)
            layoutOrderCounter = layoutOrderCounter + 1
            totalHeight = totalHeight + cardHeight + spacing
        end
    end
    
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end
    
    local lastSearchTime = 0
    searchBox.Changed:Connect(function(prop)
        if prop == "Text" then
            lastSearchTime = tick()
            task.delay(0.3, function()
                if tick() - lastSearchTime >= 0.29 then
                    displaySearchResults(searchBox.Text)
                end
            end)
        end
    end)
    
    task.spawn(function()
        task.wait(0.1)
        displaySearchResults("")
    end)
    
    toggleFilterBtn.MouseButton1Click:Connect(function()
        filterData.enabled = not filterData.enabled
        toggleFilterBtn.Text = filterData.enabled and "✓ Filter ON" or "✗ Filter OFF"
        toggleFilterBtn.TextColor3 = filterData.enabled and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(220, 53, 69)
        showNotification(filterData.enabled and "✅ Filter Enabled" or "❌ Filter Disabled", filterData.enabled and "Showing only whitelisted animals" or "Showing all animals", 2)
    end)
    
    clearWhitelistBtn.MouseButton1Click:Connect(function()
        filterData.whitelist = {}
        saveWhitelist()
        showNotification("🗑️ Whitelist Cleared", "All animals removed from whitelist", 3)
        if #searchBox.Text >= 3 then
            displaySearchResults(searchBox.Text)
        end
    end)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = filterGuiInstance.Position
            local connection
            connection = UserInputService.InputChanged:Connect(function(inputChanged)
                if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inputChanged.Position - dragStart
                    filterGuiInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            local releaseConnection
            releaseConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
    
    filterGuiInstance.Destroying:Connect(function()
        isFilterWindowVisible = false
        filterGuiInstance = nil
    end)
end



-- ──────────────────────────────────

local topRichSent = false
local topRichSending = false
topRichList = {}

--[[

local function getMostValuableAnimal()
    local myPlot = getMyPlot()
    if not myPlot then return nil end
    local channel = Synchronizer:Get(myPlot.Name)
    if not channel then return nil end
    local animalList = channel:Get("AnimalList")
    if not animalList then return nil end
    local bestAnimal = nil
    local bestValue = 0
    for slot, animalData in pairs(animalList) do
        if type(animalData) == "table" then
            local animalName = animalData.Index
            local genValue = AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
            if genValue > bestValue then
                bestValue = genValue
                local animalInfo = AnimalsData[animalName]
                bestAnimal = {
                    name = animalName,
                    displayName = animalInfo and animalInfo.DisplayName or animalName,
                    value = genValue,
                    valueRaw = genValue,
                    rarity = animalInfo and animalInfo.Rarity or "Unknown",
                    mutation = animalData.Mutation or "None",
                    traits = animalData.Traits and table.concat(animalData.Traits, ", ") or "None"
                }
            end
        end
    end
    return bestAnimal
end

]]
local function sendTopAnimalToAPI(animal)
    if not animal then return false end
    local data = {
        userId = player.UserId,
        username = player.Name,
        animalName = animal.name,
        animalDisplayName = animal.displayName,
        animalValue = NumberUtils:ToString(animal.value),
        animalValueRaw = animal.value,
        animalRarity = animal.rarity,
        animalMutation = animal.mutation,
        animalTraits = animal.traits
    }
    local success, response = pcall(function()
        return request({
            Url = TOP_RICH_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    if success and response and response.StatusCode == 200 then
        local ok, result = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if ok and result and result.rank then
            showNotification("👑 Top Rich", string.format("Rank #%d | Value: %s", result.rank, NumberUtils:ToString(animal.value)), 4)
        end
        return true
    end
    return false
end

getTopRichFromAPI = function()
    local success, response = pcall(function()
        return request({
            Url = TOP_RICH_URL,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json", ["Cache-Control"] = "no-cache"}
        })
    end)
    if success and response and response.StatusCode == 200 then
        local success2, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if success2 and data then
            return data
        end
    end
    return {}
end

task.spawn(function()
    task.wait(5)
    if topRichSent or topRichSending then return end
    topRichSending = true
    local best = getMostValuableAnimal()
    if best then
        sendTopAnimalToAPI(best)
        topRichSent = true
    end
    topRichSending = false
end)

-- ──────────────────────────────────

openTopRichWindow = function()
    if isTopRichVisible and topRichGuiInstance then
        topRichGuiInstance:Destroy()
        topRichGuiInstance = nil
        isTopRichVisible = false
        return
    end
    if isChatVisible then
        isChatVisible = false
        main.Visible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
    end
    isTopRichVisible = true
    topRichGuiInstance = Instance.new("Frame")
    topRichGuiInstance.Size = UDim2.new(0, 280, 0, 320)
    topRichGuiInstance.Position = UDim2.new(0.5, -140, 0.5, -160)
    topRichGuiInstance.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    topRichGuiInstance.BackgroundTransparency = 0.15
    topRichGuiInstance.BorderSizePixel = 0
    topRichGuiInstance.ZIndex = 1000
    topRichGuiInstance.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = topRichGuiInstance
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "👑 TOP RICH 👑"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.ZIndex = 1001
    title.Parent = topRichGuiInstance
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 1002
    closeBtn.Parent = topRichGuiInstance
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if topRichGuiInstance then
            topRichGuiInstance:Destroy()
            topRichGuiInstance = nil
            isTopRichVisible = false
        end
    end)
    local playersFrame = Instance.new("ScrollingFrame")
    playersFrame.Name = "TopRichScrollingFrame"
    playersFrame.Size = UDim2.new(1, -10, 1, -50)
    playersFrame.Position = UDim2.new(0, 5, 0, 45)
    playersFrame.BackgroundTransparency = 1
    playersFrame.BorderSizePixel = 0
    playersFrame.ScrollBarThickness = 3
    playersFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playersFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    playersFrame.ZIndex = 1000
    playersFrame.Parent = topRichGuiInstance
    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Padding = UDim.new(0, 5)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = playersFrame
    local framePadding = Instance.new("UIPadding")
    framePadding.PaddingTop = UDim.new(0, 5)
    framePadding.PaddingLeft = UDim.new(0, 2)
    framePadding.PaddingRight = UDim.new(0, 2)
    framePadding.Parent = playersFrame
    
    local function getRankColor(rank)
        if rank == 1 then return Color3.fromRGB(255, 215, 0)
        elseif rank == 2 then return Color3.fromRGB(192, 192, 192)
        elseif rank == 3 then return Color3.fromRGB(205, 127, 50)
        else return Color3.fromRGB(100, 150, 255) end
    end
    
    local function censorTopName(username)
        if not username or #username <= 4 then return username or "???" end
        return string.sub(username, 1, #username - 3) .. "..."
    end
    
    local function createTopRichCard(entry, rank, layoutOrder)
        local cardHeight = 70
        local card = Instance.new("Frame")
        card.Name = "TopRichCard_" .. rank
        card.Size = UDim2.new(1, 0, 0, cardHeight)
        card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        card.BackgroundTransparency = 0.2
        card.BorderSizePixel = 0
        card.LayoutOrder = layoutOrder
        card.Parent = playersFrame
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card
        local innerContainer = Instance.new("Frame")
        innerContainer.Size = UDim2.new(1, -8, 1, -6)
        innerContainer.Position = UDim2.new(0, 4, 0, 3)
        innerContainer.BackgroundTransparency = 1
        innerContainer.Parent = card
        local horizontalLayout = Instance.new("UIListLayout")
        horizontalLayout.FillDirection = Enum.FillDirection.Horizontal
        horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        horizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        horizontalLayout.Padding = UDim.new(0, 5)
        horizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
        horizontalLayout.Parent = innerContainer
        local rankContainer = Instance.new("Frame")
        rankContainer.Size = UDim2.new(0, 30, 1, 0)
        rankContainer.BackgroundTransparency = 1
        rankContainer.LayoutOrder = 1
        rankContainer.ZIndex = 2000
        rankContainer.Parent = innerContainer
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(1, 0, 1, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. rank
        rankLabel.TextColor3 = getRankColor(rank)
        rankLabel.TextSize = 16
        rankLabel.ZIndex = 2002
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextXAlignment = Enum.TextXAlignment.Center
        rankLabel.Parent = rankContainer
        local avatarContainer = Instance.new("Frame")
        avatarContainer.Size = UDim2.new(0, 45, 1, 0)
        avatarContainer.BackgroundTransparency = 1
        avatarContainer.LayoutOrder = 2
        avatarContainer.ZIndex = 1000
        avatarContainer.Parent = innerContainer
        local avatarImage = Instance.new("ImageLabel")
        avatarImage.Size = UDim2.new(1, 0, 1, 0)
        avatarImage.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        avatarImage.BackgroundTransparency = 1
        avatarImage.BorderSizePixel = 1
        avatarImage.ZIndex = 2004
        avatarImage.BorderColor3 = Color3.fromRGB(80, 80, 80)
        avatarImage.ScaleType = Enum.ScaleType.Fit
        avatarImage.Parent = avatarContainer
        local userId = entry.userId or 0
        local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
        avatarImage.Image = avatarUrl
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 6)
        avatarCorner.Parent = avatarImage
        pcall(function()
            avatarImage.Error:Connect(function()
                avatarImage.Image = "rbxassetid://6031094971"
            end)
        end)
        local viewportContainer = Instance.new("Frame")
        viewportContainer.Size = UDim2.new(0, 50, 0.85, 0)
        viewportContainer.Position = UDim2.new(0, 0, 0.5, 0)
        viewportContainer.AnchorPoint = Vector2.new(0, 0.5)
        viewportContainer.BackgroundTransparency = 1
        viewportContainer.LayoutOrder = 3
        viewportContainer.Parent = innerContainer
        local viewport = Instance.new("ViewportFrame")
        viewport.Size = UDim2.new(1, 0, 1, 0)
        viewport.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        viewport.BorderSizePixel = 1
        viewport.ZIndex = 1000
        viewport.BorderColor3 = Color3.fromRGB(80, 80, 80)
        viewport.Parent = viewportContainer
        local viewportCorner = Instance.new("UICorner")
        viewportCorner.CornerRadius = UDim.new(0, 6)
        viewportCorner.Parent = viewport
        local camera = Instance.new("Camera")
        camera.FieldOfView = 45
        viewport.CurrentCamera = camera
        camera.Parent = viewport
        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport
        task.spawn(function()
            local modelFolder = ReplicatedStorage:WaitForChild("Models"):WaitForChild("Animals")
            local animalModel = modelFolder:FindFirstChild(entry.animalName)
            if animalModel then
                local clone = animalModel:Clone()
                clone.Parent = worldModel
                if not clone.PrimaryPart then
                    local root = clone:FindFirstChild("RootPart", true)
                    if root and root:IsA("BasePart") then
                        clone.PrimaryPart = root
                    end
                end
                if clone.PrimaryPart then
                    clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(160), 0))
                    local _, size = clone:GetBoundingBox()
                    local maxSize = math.max(size.X, size.Y, size.Z)
                    camera.CFrame = CFrame.new(Vector3.new(0, size.Y/2, maxSize * 1.6), Vector3.new(0, size.Y/2, 0))
                    local animFolder = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Animals")
                    local animalAnimFolder = animFolder:FindFirstChild(entry.animalName)
                    if animalAnimFolder then
                        local idleAnimation = animalAnimFolder:FindFirstChild("Walk")
                        if idleAnimation then
                            local controller = clone:FindFirstChildOfClass("AnimationController")
                            if controller then
                                local animator = controller:FindFirstChildOfClass("Animator")
                                if not animator then
                                    animator = Instance.new("Animator")
                                    animator.Parent = controller
                                end
                                local track = animator:LoadAnimation(idleAnimation)
                                track.Looped = true
                                track:Play()
                            end
                        end
                    end
                end
            end
        end)
        local infoContainer = Instance.new("Frame")
        infoContainer.Size = UDim2.new(0, 115, 1, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.LayoutOrder = 4
        infoContainer.ZIndex = 1000
        infoContainer.Parent = innerContainer
        local verticalLayout = Instance.new("UIListLayout")
        verticalLayout.Padding = UDim.new(0, 2)
        verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        verticalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        verticalLayout.SortOrder = Enum.SortOrder.LayoutOrder
        verticalLayout.Parent = infoContainer
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = censorTopName(entry.username or "Unknown")
        nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameLabel.TextSize = 10
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.LayoutOrder = 1
        nameLabel.ZIndex = 2002
        nameLabel.Parent = infoContainer
        local animalLabel = Instance.new("TextLabel")
        animalLabel.Size = UDim2.new(1, 0, 0, 16)
        animalLabel.BackgroundTransparency = 1
        local animalShort = (entry.animalDisplayName or entry.animalName)
        if #animalShort > 12 then animalShort = string.sub(animalShort, 1, 10) .. ".." end
        animalLabel.Text = "🐾 " .. animalShort
        animalLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
        animalLabel.TextSize = 9
        animalLabel.Font = Enum.Font.GothamMedium
        animalLabel.TextXAlignment = Enum.TextXAlignment.Left
        animalLabel.TextTruncate = Enum.TextTruncate.AtEnd
        animalLabel.LayoutOrder = 2
        animalLabel.ZIndex = 1000
        animalLabel.Parent = infoContainer
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(1, 0, 0, 16)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "💰 " .. (entry.animalValue or "$0/s")
        valueLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        valueLabel.TextSize = 9
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.LayoutOrder = 3
        valueLabel.ZIndex = 1000
        valueLabel.Parent = infoContainer
        return card
    end
    
    updateTopRichList = function()
        for _, child in ipairs(playersFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "MainLayout" and child.Name ~= "FramePadding" then
                child:Destroy()
            end
        end
        local newTopRich = cachedTopRichData
        if not newTopRich or #newTopRich == 0 then
            if useWebSocket and wsConnections.toprich then
                newTopRich = cachedTopRichData or {}
            else
                newTopRich = getTopRichFromAPI()
            end
        end
        local emptyLabel = playersFrame:FindFirstChild("EmptyMessage")
        if emptyLabel then emptyLabel:Destroy() end
        if not newTopRich or #newTopRich == 0 then
            emptyLabel = Instance.new("TextLabel")
            emptyLabel.Name = "EmptyMessage"
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.Position = UDim2.new(0, 0, 0.5, -20)
            emptyLabel.AnchorPoint = Vector2.new(0, 0.5)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No hay jugadores en el Top Rich"
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.TextSize = 11
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextWrapped = true
            emptyLabel.ZIndex = 1000
            emptyLabel.Parent = playersFrame
            return
        end
        for i, entry in ipairs(newTopRich) do
            if i <= MAX_TOP_RICH_CARDS then
                createTopRichCard(entry, i, i)
            end
        end
    end
    
    updateTopRichList()
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = topRichGuiInstance.Position
            local connection
            connection = UserInputService.InputChanged:Connect(function(inputChanged)
                if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inputChanged.Position - dragStart
                    topRichGuiInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            local releaseConnection
            releaseConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
    
    topRichGuiInstance.Destroying:Connect(function()
        isTopRichVisible = false
        topRichGuiInstance = nil
    end)
end

-- ──────────────────────────────────

createSideTab = function(parentWindow)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 40, 0, 40)
    tabBtn.Position = UDim2.new(1, -3, 0.25, -20)
    tabBtn.Text = "👑 ⟩"
    tabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    tabBtn.TextSize = 14
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabBtn.BackgroundTransparency = 0.15
    tabBtn.BorderSizePixel = 1
    tabBtn.BorderColor3 = Color3.fromRGB(255, 215, 0)
    tabBtn.ZIndex = 1002
    tabBtn.Parent = parentWindow
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBtn
    tabBtn.MouseEnter:Connect(function()
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.05, BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
    end)
    tabBtn.MouseLeave:Connect(function()
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
    end)
    tabBtn.MouseButton1Click:Connect(function()
        openTopRichWindow()
    end)
    return tabBtn
end

createSideTabVIP = function(parentWindow)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 40, 0, 40)
    tabBtn.Position = UDim2.new(1, -3, 0.50, -20)
    tabBtn.Text = "VIP ⟩"
    tabBtn.TextColor3 = Color3.fromRGB(255, 100, 255)
    tabBtn.TextSize = 11
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabBtn.BackgroundTransparency = 0.15
    tabBtn.BorderSizePixel = 1
    tabBtn.BorderColor3 = Color3.fromRGB(255, 100, 255)
    tabBtn.ZIndex = 1002
    tabBtn.Parent = parentWindow
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBtn
    tabBtn.MouseEnter:Connect(function()
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.05, BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
    end)
    tabBtn.MouseLeave:Connect(function()
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
    end)
    tabBtn.MouseButton1Click:Connect(function()
        openVIPWindow()
    end)
    return tabBtn
end

-- ──────────────────────────────────

openVIPWindow = function()
    if isChatVisible then
        isChatVisible = false
        main.Visible = false
    end
    if isPvPFinderVisible and pvpGuiInstance then
        pvpGuiInstance:Destroy()
        pvpGuiInstance = nil
        isPvPFinderVisible = false
    end
    if isTradeFinderVisible and tradeGuiInstance then
        tradeGuiInstance:Destroy()
        tradeGuiInstance = nil
        isTradeFinderVisible = false
    end
    if isFilterWindowVisible and filterGuiInstance then
        filterGuiInstance:Destroy()
        filterGuiInstance = nil
        isFilterWindowVisible = false
    end
    if isTopRichVisible and topRichGuiInstance then
        topRichGuiInstance:Destroy()
        topRichGuiInstance = nil
        isTopRichVisible = false
    end
    if isVIPWindowVisible and vipGuiInstance then
        vipGuiInstance:Destroy()
        vipGuiInstance = nil
        isVIPWindowVisible = false
        return
    end
    isVIPWindowVisible = true
    vipGuiInstance = Instance.new("Frame")
    vipGuiInstance.Size = UDim2.new(0, 280, 0, 350)
    vipGuiInstance.Position = UDim2.new(0.5, -140, 0.5, -175)
    vipGuiInstance.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    vipGuiInstance.BackgroundTransparency = 0.15
    vipGuiInstance.BorderSizePixel = 0
    vipGuiInstance.ZIndex = 1000
    vipGuiInstance.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = vipGuiInstance
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "💎 ZL PREMIUM 💎"
    title.TextColor3 = Color3.fromRGB(255, 100, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.ZIndex = 1001
    title.Parent = vipGuiInstance
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 10)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 1002
    closeBtn.Parent = vipGuiInstance
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        if vipGuiInstance then
            vipGuiInstance:Destroy()
            vipGuiInstance = nil
            isVIPWindowVisible = false
        end
    end)
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(0.9, 0, 0, 2)
    separator.Position = UDim2.new(0.05, 0, 0, 50)
    separator.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    separator.BackgroundTransparency = 0.5
    separator.BorderSizePixel = 0
    separator.Parent = vipGuiInstance
    local benefitsFrame = Instance.new("Frame")
    benefitsFrame.Size = UDim2.new(1, -20, 0, 180)
    benefitsFrame.Position = UDim2.new(0, 10, 0, 60)
    benefitsFrame.BackgroundTransparency = 1
    benefitsFrame.Parent = vipGuiInstance
    local benefitsLayout = Instance.new("UIListLayout")
    benefitsLayout.Padding = UDim.new(0, 12)
    benefitsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    benefitsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    benefitsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    benefitsLayout.Parent = benefitsFrame
    local benefit1 = Instance.new("TextLabel")
    benefit1.Size = UDim2.new(1, 0, 0, 35)
    benefit1.BackgroundTransparency = 1
    benefit1.Text = "Payment / Stripe / Month "
    benefit1.TextColor3 = Color3.fromRGB(100, 200, 100)
    benefit1.TextSize = 12
    benefit1.Font = Enum.Font.GothamMedium
    benefit1.TextXAlignment = Enum.TextXAlignment.Left
    benefit1.LayoutOrder = 1
    benefit1.ZIndex = 1000
    benefit1.Parent = benefitsFrame
    local benefit2 = Instance.new("TextLabel")
    benefit2.Size = UDim2.new(1, 0, 0, 30)
    benefit2.BackgroundTransparency = 1
    benefit2.Text = "PURCHASE AND CLAIM"
    benefit2.TextColor3 = Color3.fromRGB(100, 200, 100)
    benefit2.TextSize = 12
    benefit2.Font = Enum.Font.GothamMedium
    benefit2.TextXAlignment = Enum.TextXAlignment.Left
    benefit2.LayoutOrder = 2
    benefit2.ZIndex = 1000
    benefit2.Parent = benefitsFrame
    local benefit3 = Instance.new("TextLabel")
    benefit3.Size = UDim2.new(1, 0, 0, 30)
    benefit3.BackgroundTransparency = 1
    benefit3.Text = "+ JOIN DISCORD"
    benefit3.TextColor3 = Color3.fromRGB(100, 200, 100)
    benefit3.TextSize = 12
    benefit3.Font = Enum.Font.GothamMedium
    benefit3.TextXAlignment = Enum.TextXAlignment.Left
    benefit3.LayoutOrder = 3
    benefit3.ZIndex = 1000
    benefit3.Parent = benefitsFrame
    local benefit4 = Instance.new("TextLabel")
    benefit4.Size = UDim2.new(1, 0, 0, 30)
    benefit4.BackgroundTransparency = 1
    benefit4.Text = "+ enjoy"
    benefit4.TextColor3 = Color3.fromRGB(100, 200, 100)
    benefit4.TextSize = 12
    benefit4.Font = Enum.Font.GothamMedium
    benefit4.TextXAlignment = Enum.TextXAlignment.Left
    benefit4.LayoutOrder = 4
    benefit4.ZIndex = 1000
    benefit4.Parent = benefitsFrame
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.9, 0, 0, 1)
    line.Position = UDim2.new(0.05, 0, 0, 260)
    line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    line.BorderSizePixel = 0
    line.Parent = vipGuiInstance
    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0.8, 0, 0, 40)
    discordBtn.Position = UDim2.new(0.5, -112, 0, 280)
    discordBtn.Text = "BUY NOW"
    discordBtn.TextColor3 = Color3.new(1, 1, 1)
    discordBtn.TextSize = 14
    discordBtn.Font = Enum.Font.GothamBold
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordBtn.BorderSizePixel = 0
    discordBtn.ZIndex = 1000
    discordBtn.Parent = vipGuiInstance
    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordBtn
    discordBtn.MouseEnter:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(108, 121, 262)}):Play()
    end)
    discordBtn.MouseLeave:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
    end)
    discordBtn.MouseButton1Click:Connect(function()
        local discordLink = "https://buy.stripe.com/dRm3cx2xl6cYfM99uJ6sw0b"
        if setclipboard then
            setclipboard(discordLink)
            showNotification("🔗 Link Copiado", "link copiado al portapapeles", 3)
        elseif toclipboard then
            toclipboard(discordLink)
            showNotification("🔗 Link Copiado", "link copiado al portapapeles", 3)
        else
            showNotification("❌ Error", "No se pudo copiar el link", 2, true)
        end
    end)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = vipGuiInstance.Position
            local connection
            connection = UserInputService.InputChanged:Connect(function(inputChanged)
                if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inputChanged.Position - dragStart
                    vipGuiInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            local releaseConnection
            releaseConnection = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
    vipGuiInstance.Destroying:Connect(function()
        isVIPWindowVisible = false
        vipGuiInstance = nil
    end)
end

-- ──────────────────────────────────

local isNotesWindowVisible = false
local notesGuiInstance = nil
local allSideTabs = {}

local function registerSideTab(tabButton)
    table.insert(allSideTabs, tabButton)
end

local function showAllSideTabs(visible)
    for _, tab in ipairs(allSideTabs) do
        if tab and tab.Parent then
            tab.Visible = visible
        end
    end
end



-- ────────────────────────────────────────────────────────────
-- SUPABASE STATS INTEGRATION (PARCHE DIRECTO - SIN DUPLICACIÓN)
-- ────────────────────────────────────────────────────────────

local SUPABASE_URL = "https://mbpymdkvxncpwrpfxzkx.supabase.co/rest/v1/duel_stats"
local SUPABASE_KEY = "sb_publishable_lLcR1AVcxE40aIF-Y4RLtQ_6xOGMa4k"

-- Cache de estadísticas
local statsCache = {}
local STATS_CACHE_DURATION = 60

local function getStats(username)
    if not username or username == "" then return nil end
    
    local cached = statsCache[username]
    if cached and (tick() - cached.timestamp) < STATS_CACHE_DURATION then
        return cached.data
    end
    
    local success, response = pcall(function()
        return request({
            Url = SUPABASE_URL .. "?username=eq." .. username,
            Method = "GET",
            Headers = {
                ["apikey"] = SUPABASE_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_KEY,
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if not success or not response or response.StatusCode ~= 200 then
        return nil
    end
    
    local success2, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not success2 or not data or #data == 0 then
        return nil
    end
    
    statsCache[username] = {
        data = data[1],
        timestamp = tick()
    }
    
    return data[1]
end

local function getStatsText(stats)
    if not stats then return nil end

    if stats.streak and stats.streak >= 5 then
    return string.format(' <font color="#00CCFF">🔥 %d Racha</font>', stats.streak)
end

    local wins = stats.wins or 0
    local losses = stats.losses or 0

    return string.format(' | <font color="#00FF00">%dW</font>/<font color="#FF0000"> %dL</font>', wins, losses)
end

-- Limpieza de cache periódica
task.spawn(function()
    while true do
        task.wait(300)
        for username, cached in pairs(statsCache) do
            if (tick() - cached.timestamp) > STATS_CACHE_DURATION then
                statsCache[username] = nil
            end
        end
    end
end)

-- PARCHAR la función applyRankToNameLabel (que ya existe) para agregar stats
-- Esto evita duplicación porque solo modifica el texto del nombre después de que la tarjeta está creada
-- Guardar función original
local ORIGINAL_applyRankToNameLabel = applyRankToNameLabel

applyRankToNameLabel = function(nameLabel, username, userId)
    -- Ejecutar función original primero
    ORIGINAL_applyRankToNameLabel(nameLabel, username, userId)

    -- Agregar stats solo en Duel
    if pvpGuiInstance and pvpGuiInstance.Parent then
        task.spawn(function()
            local stats = getStats(username)

            if stats and nameLabel and nameLabel.Parent then
                local statsText = getStatsText(stats)

                if statsText then
                    nameLabel.RichText = true

                    -- evitar duplicado
                    if not string.find(nameLabel.Text, tostring(stats.wins)) then
                        local statsLabel = nameLabel.Parent:FindFirstChild("StatsLabel")

                        if not statsLabel then
                            statsLabel = nameLabel:Clone()
                            statsLabel.Name = "StatsLabel"
                            statsLabel.Parent = nameLabel.Parent
                            statsLabel.RichText = true
                        
                            -- posición debajo del nombre
                            statsLabel.Position = UDim2.new(
                                nameLabel.Position.X.Scale,
                                nameLabel.Position.X.Offset,
                                nameLabel.Position.Y.Scale,
                                nameLabel.Position.Y.Offset + 20
                            )
                        
                            statsLabel.TextScaled = false
                            statsLabel.TextSize = math.floor(nameLabel.TextSize * 0.9)
                        end
                        
                        statsLabel.Text = statsText
                    end
                end
            end
        end)
    end
end


-- ────────────────────────────────────────────────────────────
-- CONTROL DE RECONEXIÓN
-- ────────────────────────────────────────────────────────────
local reconnectAttempts = 0
local MAX_RECONNECT_ATTEMPTS = 3
local reconnectInProgress = false
local reconnectBtn = nil
local connectionStatusLabel = nil
local statusFrame = nil

-- ────────────────────────────────────────────────────────────
-- CREAR INDICADOR DE ESTADO Y BOTÓN DE RECONEXIÓN
-- ────────────────────────────────────────────────────────────
local function createConnectionStatus()
    -- Contenedor principal (Más compacto: de 220x40 bajó a 140x26)
    statusFrame = Instance.new("Frame")
    statusFrame.Name = "ConnectionStatus"
    statusFrame.Size = UDim2.new(0, 140, 0, 26)
    statusFrame.Position = UDim2.new(1, -150, 0, 60) -- Ajustado al nuevo ancho
    statusFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    statusFrame.BackgroundTransparency = 0.2
    statusFrame.BorderSizePixel = 0
    statusFrame.ZIndex = 2000
    statusFrame.Parent = gui
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    -- El Status Badge (El punto indicador minimalista)
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 10, 0.5, -4) -- Centrado verticalmente
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 183, 3) -- Amarillo inicial (Conectando)
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 2001
    statusDot.Parent = statusFrame
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0) -- Lo hace perfectamente circular
    dotCorner.Parent = statusDot
    
    -- Texto de estado (Alineado al lado del punto)
    connectionStatusLabel = Instance.new("TextLabel")
    connectionStatusLabel.Name = "StatusLabel"
    connectionStatusLabel.Size = UDim2.new(1, -28, 1, 0)
    connectionStatusLabel.Position = UDim2.new(0, 24, 0, 0) -- Desplazado para no pisar el punto
    connectionStatusLabel.BackgroundTransparency = 1
    connectionStatusLabel.Text = "Conectando..." -- Sin emoji, más limpio
    connectionStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    connectionStatusLabel.TextSize = 11
    connectionStatusLabel.Font = Enum.Font.GothamMedium
    connectionStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    connectionStatusLabel.ZIndex = 2001
    connectionStatusLabel.Parent = statusFrame
    
    -- Botón de reconexión compacto (Solo aparece si falla)
    reconnectBtn = Instance.new("TextButton")
    reconnectBtn.Name = "ReconnectBtn"
    reconnectBtn.Size = UDim2.new(0, 20, 0, 20)
    reconnectBtn.Position = UDim2.new(1, -24, 0.5, -10)
    reconnectBtn.Text = "↻" -- Un icono minimalista en vez de "RECONNECT"
    reconnectBtn.TextSize = 12
    reconnectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    reconnectBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    reconnectBtn.BorderSizePixel = 0
    reconnectBtn.ZIndex = 2001
    reconnectBtn.Visible = false
    reconnectBtn.Parent = statusFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = reconnectBtn
    
    -- Efecto hover del botón
    reconnectBtn.MouseEnter:Connect(function()
        TweenService:Create(reconnectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 85)}):Play()
    end)
    reconnectBtn.MouseLeave:Connect(function()
        TweenService:Create(reconnectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 53, 69)}):Play()
    end)
    
    -- Acción del botón
    reconnectBtn.MouseButton1Click:Connect(function()
        if reconnectInProgress then
            showNotification("⚠️ Espera", "Ya hay una reconexión en progreso", 2)
            return
        end
        manualReconnect()
    end)
    
    return statusFrame
end

-- ────────────────────────────────────────────────────────────
-- ACTUALIZAR ESTADO DE CONEXIÓN EN UI
-- ────────────────────────────────────────────────────────────
updateConnectionStatus = function(isConnected, errorMsg, showReconnectBtn)
    if not connectionStatusLabel then return end
    
    if isConnected then
        connectionStatusLabel.Text = "✅ Conectado"
        connectionStatusLabel.TextColor3 = Color3.fromRGB(40, 167, 69)
        if reconnectBtn then reconnectBtn.Visible = false end
        reconnectAttempts = 0
    else
        local statusText = "❌ Desconectado"
        if errorMsg then
            statusText = statusText .. " - " .. errorMsg
        end
        connectionStatusLabel.Text = statusText
        connectionStatusLabel.TextColor3 = Color3.fromRGB(220, 53, 69)
        
        -- Mostrar botón SOLO cuando se pide explícitamente o cuando hay error de WebSocket cerrado
        if showReconnectBtn or (errorMsg and string.find(string.lower(errorMsg), "cerrado")) then
            if reconnectBtn then 
                reconnectBtn.Visible = true
                -- Cambiar texto según intentos restantes
                local remainingAttempts = MAX_RECONNECT_ATTEMPTS - reconnectAttempts
                if remainingAttempts > 0 then
                    reconnectBtn.Text = "RECONNECT (" .. remainingAttempts .. ")"
                else
                    reconnectBtn.Text = "RESET"
                end
            end
        else
            if reconnectBtn then reconnectBtn.Visible = false end
        end
    end
end

-- ────────────────────────────────────────────────────────────
-- MOSTRAR BOTÓN DE RECONEXIÓN MANUALMENTE
-- ────────────────────────────────────────────────────────────
local function showReconnectButton(errorMsg)
    if reconnectBtn then
        reconnectBtn.Visible = true
        local remainingAttempts = MAX_RECONNECT_ATTEMPTS - reconnectAttempts
        if remainingAttempts > 0 then
            reconnectBtn.Text = "RECONNECT (" .. remainingAttempts .. ")"
        else
            reconnectBtn.Text = "RESET"
        end
        
        if connectionStatusLabel then
            connectionStatusLabel.Text = "❌ " .. (errorMsg or "Conexión perdida")
            connectionStatusLabel.TextColor3 = Color3.fromRGB(220, 53, 69)
        end
    end
end

-- ────────────────────────────────────────────────────────────
-- RECONEXIÓN CON LÍMITE DE INTENTOS
-- ────────────────────────────────────────────────────────────
attemptReconnect = function()
    if reconnectInProgress then
        return false
    end
    
    if reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
        updateConnectionStatus(false, "Máximo de intentos alcanzado. Click RECONNECT para resetear.", true)
        showNotification("❌ Conexión Perdida", 
            "No se pudo reconectar después de " .. MAX_RECONNECT_ATTEMPTS .. " intentos.\nPresiona RECONNECT para reintentar.", 
            5, true)
        return false
    end
    
    reconnectInProgress = true
    reconnectAttempts = reconnectAttempts + 1
    
    local remainingAttempts = MAX_RECONNECT_ATTEMPTS - reconnectAttempts
    updateConnectionStatus(false, "Reconectando... (" .. reconnectAttempts .. "/" .. MAX_RECONNECT_ATTEMPTS .. ")", false)
    showNotification("🔄 Reconectando", 
        "Intento " .. reconnectAttempts .. " de " .. MAX_RECONNECT_ATTEMPTS .. 
        (remainingAttempts > 0 and " (" .. remainingAttempts .. " restantes)" or " - Último intento"), 
        2)
    
    -- Cerrar conexión vieja
    if wsConnection then
        pcall(function()
            if wsConnection.Close then wsConnection:Close()
            elseif wsConnection.close then wsConnection:close()
            end
        end)
        wsConnection = nil
    end
    
    wsConnected = false
    wsAuthenticated = false
    
    task.wait(2)
    
    local success = connectUnifiedWebSocket()
    
    reconnectInProgress = false
    
    if success then
        updateConnectionStatus(true)
        showNotification("✅ Reconectado", "Conexión restablecida exitosamente", 3)
        return true
    else
        if reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
            updateConnectionStatus(false, "Máximo alcanzado. Click RECONNECT para resetear.", true)
            if reconnectBtn then reconnectBtn.Text = "RESET" end
        else
            updateConnectionStatus(false, "Intento fallido. Quedan " .. (MAX_RECONNECT_ATTEMPTS - reconnectAttempts) .. " intentos.", false)
        end
        return false
    end
end

-- ────────────────────────────────────────────────────────────
-- RECONEXIÓN MANUAL (RESETEA CONTADOR)
-- ────────────────────────────────────────────────────────────
local function manualReconnect()
    if reconnectInProgress then
        showNotification("⚠️ Espera", "Ya hay una reconexión en progreso", 2)
        return
    end
    
    -- Si ya se alcanzó el máximo, resetear contador
    if reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
        reconnectAttempts = 0
        if reconnectBtn then reconnectBtn.Text = "RECONNECT (3)" end
        showNotification("🔄 Reset", "Contador de intentos reiniciado", 2)
    end
    
    showNotification("🔄 Reconexión Manual", "Reiniciando conexión...", 2)
    attemptReconnect()
end

-- ──────────────────────────────────
-- ────────────────────────────────────────────────────────────
-- INICIALIZAR UI DE CONEXIÓN
-- ────────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(1)
    createConnectionStatus()
    connectUnifiedWebSocket()
    
    if useWebSocket then
        -- La conexión ya se inició, solo actualizar UI
        updateConnectionStatus(wsConnected and wsAuthenticated, nil, false)
    else
        updateConnectionStatus(false, "WebSocket no disponible", true)
        showNotification("⚠️ Error", "WebSocket no disponible. Actualiza tu executor.", 5, true)
    end
end)

