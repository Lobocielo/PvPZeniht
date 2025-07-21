-- KAVO UI - Aimbot PvP ZENIHT
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("ZENIHT PvP", "Ocean")

-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local webhookUrl = "https://discord.com/api/webhooks/1395907277151801354/fmH89bkny7tgFd6T1YKDLt_PQVP3IgeU1yM6FjsN1QyiazgkQDU8UTU5aEGExqu9X0_8"
local fov = 120
local aimbotEnabled = false
local headAim = false
local espEnabled = true
local currentTarget = nil
local currentTargetDistance = "N/A"
local highlightColor = Color3.fromRGB(135, 206, 250)
local teamCheck = true

-- ESP
local highlightTable = {}
local function createHighlight(player)
    local function setup(character)
        if character:FindFirstChild("HumanoidRootPart") then
            local h = Instance.new("Highlight")
            h.Adornee = character
            h.FillColor = highlightColor
            h.FillTransparency = 0.5
            h.OutlineColor = Color3.new(1, 1, 1)
            h.OutlineTransparency = 0.2
            h.Enabled = espEnabled
            h.Parent = character
            highlightTable[player] = h
        end
    end
    if player.Character then setup(player.Character) end
    player.CharacterAdded:Connect(function(c) task.wait(0.5) setup(c) end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createHighlight(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createHighlight(p) end end)

-- AIMBOT
local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if teamCheck and p.Team == LocalPlayer.Team then continue end
            local part = headAim and p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if visible and dist < shortest and dist <= fov then
                    closest = p
                    shortest = dist
                    currentTargetDistance = math.floor((Camera.CFrame.Position - part.Position).Magnitude)
                end
            end
        end
    end
    return closest
end

local function lockOnTarget()
    if currentTarget and currentTarget.Character then
        local part = headAim and currentTarget.Character:FindFirstChild("Head") or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local velocity = part.Velocity or Vector3.zero
            local pred = part.Position + (velocity * math.clamp(0.05 + (currentTargetDistance / 2000), 0.02, 0.1))
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pred), 0.2)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not currentTarget then currentTarget = getClosestTarget() end
        if currentTarget then lockOnTarget() end
    else
        currentTarget = nil
    end
end)

-- ANTIKICK
pcall(function()
    hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if getnamecallmethod() == "Kick" or tostring(self) == "Kick" then return warn("ZENIHT - Kick Blocked") end
        return self(...)
    end))
end)

-- SERVERHOP
local function serverHop()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(servers.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
            break
        end
    end
end

-- WEBHOOK INFO
local function sendTargetToWebhook()
    if not currentTarget then return end
    local embed = {
        ["title"] = "🎯 ZENIHT PvP Target",
        ["color"] = 3447003,
        ["fields"] = {
            {["name"] = "Jugador", ["value"] = currentTarget.Name, ["inline"] = true},
            {["name"] = "Distancia", ["value"] = tostring(currentTargetDistance).."m", ["inline"] = true},
            {["name"] = "JobId", ["value"] = game.JobId, ["inline"] = false},
            {["name"] = "PlaceId", ["value"] = tostring(game.PlaceId), ["inline"] = false}
        },
        ["footer"] = {["text"] = "Enviado por ZENIHT PvP"}
    }
    local payload = HttpService:JSONEncode({["embeds"] = {embed}})
    pcall(function()
        syn.request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
    end)
end

-- UI KAVO
local TabCombat = Window:NewTab("Combate")
local TabVisual = Window:NewTab("Visual")
local TabServ = Window:NewTab("Servidor")

local Combat = TabCombat:NewSection("Aimbot")
Combat:NewToggle("Aimlock", "Aimbot con predicción", function(v) aimbotEnabled = v end)
Combat:NewToggle("Head Aim", "Apunta a la cabeza", function(v) headAim = v end)
Combat:NewSlider("FOV", "Radio del aimbot", 360, 10, function(v) fov = v end)
Combat:NewButton("📤 Enviar target al Webhook", "", function() sendTargetToWebhook() end)

local Visual = TabVisual:NewSection("ESP")
Visual:NewToggle("ESP Highlight", "Resalta jugadores", function(val)
    espEnabled = val
    for _, h in pairs(highlightTable) do if h then h.Enabled = val end end
end)

local Serv = TabServ:NewSection("Servidor")
Serv:NewButton("↪ Server Hop", "Saltar a otro servidor", function() serverHop() end)
