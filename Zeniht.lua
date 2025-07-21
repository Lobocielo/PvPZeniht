-- ZENIHT PvP Script Final
-- Webhook listo
local webhookUrl = "https://discord.com/api/webhooks/1395923560916193301/Q2gD4P3Xy6HMRLFczAlo7FEgT5FkmstXI_U_wOCQeObuJgI6VmDMFMHKFHc97O4MBgPL"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local teamCheck = false
local fov = 120
local aimbotEnabled = false
local headAimEnabled = false
local espEnabled = true
local currentTarget = nil
local currentTargetDistance = "N/A"

-- Cambié tema a rojo fuerte oscuro, nada pastel
local themeColor = Color3.fromRGB(180, 30, 30) -- rojo oscuro fuerte

local highlightedPlayers = {}

-- ✅ Aimbot
local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if teamCheck and player.Team == LocalPlayer.Team then continue end
                local part = headAimEnabled and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if part then
                    local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if visible and dist < shortest and dist <= fov then
                        closest = player
                        shortest = dist
                        currentTargetDistance = math.floor((myPos - part.Position).Magnitude)
                    end
                end
            end
        end
    end
    return closest
end

local function lockOnTarget()
    if currentTarget and currentTarget.Character then
        local part = headAimEnabled and currentTarget.Character:FindFirstChild("Head") or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local pred = part.Position + (part.Velocity * math.clamp(0.05 + (currentTargetDistance / 2000), 0.02, 0.1))
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

-- ✅ ESP Highlight (reparado)
local function createHighlight(player)
    local function tryHighlight()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        if highlightedPlayers[player] then highlightedPlayers[player]:Destroy() end

        local h = Instance.new("Highlight")
        h.Name = "ZENIHT_HIGHLIGHT"
        h.Adornee = player.Character
        h.FillColor = themeColor
        h.FillTransparency = 0.5
        h.OutlineColor = Color3.new(1, 1, 1)
        h.OutlineTransparency = 0.2
        h.Enabled = espEnabled
        h.Parent = player.Character
        highlightedPlayers[player] = h
    end

    if player.Character then task.delay(0.3, function() pcall(tryHighlight) end) end
    player.CharacterAdded:Connect(function(c) task.wait(0.5) pcall(tryHighlight) end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createHighlight(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createHighlight(p) end end)

-- ✅ Webhook
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
        ["footer"] = {["text"] = "ZENIHT PvP"}
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

-- ✅ Server Hop
local function serverHop()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(servers.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
            break
        end
    end
end

-- ✅ GUI (Rojo y Negro)
local function createGUI()
    if game.CoreGui:FindFirstChild("Aimlock_GUI") then game.CoreGui.Aimlock_GUI:Destroy() end

    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "Aimlock_GUI"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 220, 0, 270) -- un poco más alto para el crédito
    frame.Position = UDim2.new(1, -240, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- casi negro
    frame.BorderSizePixel = 2
    frame.BorderColor3 = themeColor
    frame.Active = true
    frame.Draggable = true

    local function makeButton(text, posY, callback)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 200, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(30, 0, 0) -- rojo oscuro para botones
        btn.BorderSizePixel = 2
        btn.BorderColor3 = themeColor
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.MouseButton1Click:Connect(function() callback(btn) end)
        return btn
    end

    local aimBtn = makeButton("Aimlock: OFF", 30, function(btn)
        aimbotEnabled = not aimbotEnabled
        btn.Text = aimbotEnabled and "Aimlock: ON" or "Aimlock: OFF"
    end)

    local headBtn = makeButton("Head Aim: OFF", 70, function(btn)
        headAimEnabled = not headAimEnabled
        btn.Text = headAimEnabled and "Head Aim: ON" or "Head Aim: OFF"
    end)

    local espBtn = makeButton("ESP: ON", 110, function(btn)
        espEnabled = not espEnabled
        btn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
        for _, h in pairs(highlightedPlayers) do if h then h.Enabled = espEnabled end end
    end)

    local webhookBtn = makeButton("📤 Enviar Target", 150, function()
        sendTargetToWebhook()
    end)

    local serverhopBtn = makeButton("↪ Server Hop", 190, function()
        serverHop()
    end)

    local dist = Instance.new("TextLabel", frame)
    dist.Position = UDim2.new(0, 10, 0, 230)
    dist.Size = UDim2.new(0, 200, 0, 20)
    dist.TextColor3 = Color3.new(1, 1, 1)
    dist.BackgroundTransparency = 1
    dist.TextScaled = true
    dist.Font = Enum.Font.GothamBold

    RunService.RenderStepped:Connect(function()
        dist.Text = "Distancia: " .. tostring(currentTargetDistance) .. "m"
    end)

    -- Texto de crédito abajo
    local creditLabel = Instance.new("TextLabel", frame)
    creditLabel.Position = UDim2.new(0, 10, 0, 255)
    creditLabel.Size = UDim2.new(0, 200, 0, 15)
    creditLabel.BackgroundTransparency = 1
    creditLabel.TextColor3 = themeColor
    creditLabel.TextScaled = false
    creditLabel.Font = Enum.Font.GothamBold
    creditLabel.Text = "Creado por ZENIHT"
    creditLabel.TextXAlignment = Enum.TextXAlignment.Center
end

-- Cargar GUI
createGUI()

-- Anti-Kick por seguridad
pcall(function()
    hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if getnamecallmethod() == "Kick" or tostring(self) == "Kick" then return warn("ZENIHT Kick bloqueado") end
        return self(...)
    end))
end)
