--// Invisibility.lua - Froggy Hub (Reset Desync Method)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- Esta es la variable que el Main.lua busca
local Config = { Enabled = false, Version = "v2.0" }
env.FROGGY_INVIS_CONFIG = Config

local connections = {}
local heartbeatConn = nil

-- Función que oculta el cuerpo pero mantiene la hitbox viva
local function applyInvisibility(char)
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
            -- 🔥 CLAVE: Aseguramos que la hitbox siga activa para que nuestros golpes conecten
            part.CanQuery = true
            part.CanTouch = true
            
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
            
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
            part.Enabled = false
            
        elseif part:IsA("BillboardGui") then
            part.Enabled = false
        end
    end
    
    -- Ocultar el nombre y la barra de vida
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

-- Restaurar todo al apagar
local function restoreVisibility(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.LocalTransparencyModifier = 0
            if part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
            part.Enabled = true
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    end
end

-- Bucle de seguridad (por si el juego intenta volver a hacernos visibles)
local function startHeartbeat(char)
    if heartbeatConn then heartbeatConn:Disconnect() end
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if Config.Enabled and char and char.Parent then
            applyInvisibility(char)
        end
    end)
end

-- Escuchar cuando el personaje respawnea (Para volver a aplicar el truco)
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
    if Config.Enabled then
        task.wait(0.3) -- Esperar a que cargue el personaje
        applyInvisibility(newChar)
        startHeartbeat(newChar)
    end
end))

-- Función que el Main llama cuando se activa el toggle
function Config.Set(value)
    Config.Enabled = value
    
    if value then
        -- 🔥 EL TRUCO: Matamos al personaje localmente para forzar el reset
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0 -- Esto engaña al servidor y hace que te vuelvas invisible
            end
        end
    else
        -- Restaurar visibilidad al apagar
        if heartbeatConn then heartbeatConn:Disconnect() end
        restoreVisibility(LocalPlayer.Character)
    end
end

env.__FROGGY_INVIS_CLEANUP = function()
    Config.Enabled = false
    for _, c in ipairs(connections) do c:Disconnect() end
    if heartbeatConn then heartbeatConn:Disconnect() end
    restoreVisibility(LocalPlayer.Character)
    env.FROGGY_INVIS_CONFIG = nil
    env.__FROGGY_INVIS_CLEANUP = nil
end
