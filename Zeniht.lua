-- // Cargar UI Kavo
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT PvP", "Ocean")

-- // Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Webhook
local webhookUrl = "https://discord.com/api/webhooks/1395907277151801354/fmH89bkny7tgFd6T1YKDLt_PQVP3IgeU1yM6FjsN1QyiazgkQDU8UTU5aEGExqu9X0_8"

-- // Variables
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local teamCheck = true
local fov = 120
local currentTarget = nil
local currentTargetDistance = "N/A"
local targetPart = "HumanoidRootPart"
local highlightTable = {}
local themeColor = Color3.fromRGB(135, 206, 250) -- celeste

-- // ESP
local function createHighlight(player)
    local function setup(character)
        if character:FindFirstChild("HumanoidRootPart") then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = character
            highlight.FillColor = themeColor
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0.2
            highlight.Parent = character
            highlightTable[player] = highlight
        end
    end
    if player.Character then setup(player.Character) end
    player.CharacterAdded:Connect(function(c) task.wait(0.5) setup(c) end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createHighlight(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createHighlight(p) end end)

-- // Target Finder
local function getClosestTarget()
    local closest, shortestDist = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if teamCheck and p.Team == LocalPlayer.Team then continue end
            local part = headAimEnabled and p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if visible and dist < shortestDist and dist <= fov then
                    closest = p
                    shortestDist = dist
                    currentTargetDistance = math.floor((Camera.CFrame.Position - part.Position).Magnitude)
                end
            end
        end
    end
    return closest
end

-- // Lock Target
local function lockTarget()
    if currentTarget and currentTarget.Character then
        local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local pred = part.Position + part.Velocity * math.clamp(0.05 + (currentTargetDistance / 2000), 0.02, 0.1)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pred), 0.2)
        end
    end
end

-- // Aimloop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockTarget() end
    else
        currentTarget = nil
    end
end)

-- // Anti-Kick
hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if getnamecallmethod() == "Kick" or tostring(self) == "Kick" then
        return warn("ZENIHT ANTI-KICK ACTIVADO")
    end
    return self(...)
end))

-- // Server Hop
local function serverHop()
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, v in pairs(servers.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
            break
        end
    end
end

-- // Webhook Target Info
local function sendTargetToWebhook()
    if not currentTarget or not currentTarget.Character then return end
    local embed = {
        ["title"] = "🎯 ZENIHT PvP Target",
        ["color"] = 3447003, -- Celeste embed
        ["fields"] = {
            {["name"] = "Jugador", ["value"] = currentTarget.Name, ["inline"] = true},
            {["name"] = "Distancia", ["value"] = tostring(currentTargetDistance).."m", ["inline"] = true},
            {["name"] = "JobId", ["value"] = game.JobId, ["inline"] = false},
            {["name"] = "PlaceId", ["value"] = tostring(game.PlaceId), ["inline"] = false},
        },
        ["footer"] = {["text"] = "ZENIHT PvP Logger"}
    }
    local payload = HttpService:JSONEncode({["embeds"] = {embed}})
    pcall(function()
        syn.request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    end)
end

-- // UI Tabs
local CombatTab = Window:NewTab("PvP")
local VisualTab = Window:NewTab("Visual")
local ServerTab = Window:NewTab("Server")

-- // Combat Controls
local Combat = CombatTab:NewSection("Aimbot")
Combat:NewToggle("Aimlock", "Activa aimbot con predicción", function(val) aimbotEnabled = val end)
Combat:NewToggle("Head Aim", "Apunta a la cabeza", function(val) headAimEnabled = val end)
Combat:NewSlider("FOV", "Radio del aimbot", 360, 10, function(val) fov = val end)
Combat:NewButton("📤 Enviar Target a Webhook", "Manda la info del objetivo al webhook", function()
    sendTargetToWebhook()
end)

-- // Visuals
local Visual = VisualTab:NewSection("ESP")
Visual:NewToggle("ESP Highlight", "Activa Highlight celeste", function(val)
    espEnabled = val
    for _, h in pairs(highlightTable) do if h then h.Enabled = val end end
end)

-- // Server Tools
local Server = ServerTab:NewSection("Servidor")
Server:NewButton("↪ Server Hop", "Cambia de servidor automáticamente", function()
    serverHop()
end)

