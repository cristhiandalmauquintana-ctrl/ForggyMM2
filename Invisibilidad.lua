--// Froggy Hub - Invisibility (v1.3 - Dual Mode)
--// Local: invisible solo para ti (100% seguro)
--// Phantom: invisible para TODOS + puedes atacar (detectable)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__FROGGY_INVIS_CLEANUP then pcall(env.__FROGGY_INVIS_CLEANUP) end

local Config = {
    Enabled = false,
    Mode = "Local",          -- "Local" | "Phantom"
    PhantomLocalAlpha = 0.5, -- qué tan visible te ves tú en modo Phantom (0.5 = fantasma)
    Version = "v1.3"
}
env.FROGGY_INVIS_CONFIG = Config

local connection
local char = nil
local boundParts = {} -- [part] = { origTransparency = ..., origLTM = ... }

local function snapshot(part)
    if not part or not part:IsA("BasePart") then return end
    if boundParts[part] then return end
    boundParts[part] = {
        origTransparency = part.Transparency,
        origLTM = part.LocalTransparencyModifier,
    }
end

local function applyToPart(part)
    if not part or not part:IsA("BasePart") then return end
    snapshot(part)
    if Config.Mode == "Phantom" then
        part.Transparency = 1                               -- invisible para el servidor y demás clientes
        part.LocalTransparencyModifier = Config.PhantomLocalAlpha -- semi-visible para ti
    else
        part.LocalTransparencyModifier = 1                  -- solo te ocultas a ti mismo
    end
end

local function applyToCharacter(c)
    if not c then return end
    for _, obj in ipairs(c:GetDescendants()) do
        if obj:IsA("BasePart") then
            applyToPart(obj)
        elseif obj:IsA("Decal") then
            if not boundParts[obj] then
                boundParts[obj] = { origTransparency = obj.Transparency }
                obj.Transparency = 1
            end
        end
    end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end
end

local function restoreAll()
    for part, data in pairs(boundParts) do
        if part and part.Parent then
            pcall(function()
                if part:IsA("BasePart") then
                    part.Transparency = data.origTransparency or 0
                    part.LocalTransparencyModifier = data.origLTM or 0
                elseif part:IsA("Decal") then
                    part.Transparency = data.origTransparency or 0
                end
            end)
        end
    end
    boundParts = {}
end

local function restoreVisuals(c)
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
    end
end

-- Refuerzo agresivo: se ejecuta cada frame de renderizado para ganar la carrera
-- contra el servidor si intenta revertir la transparencia tras atacar/recibir daño.
local function reinforce()
    if not Config.Enabled then return end
    local c = LocalPlayer.Character
    if not c or c ~= char then return end

    for _, obj in ipairs(c:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not boundParts[obj] then
                applyToPart(obj) -- parte nueva (arma, accesorio, efecto)
            elseif Config.Mode == "Phantom" then
                if obj.Transparency ~= 1 then obj.Transparency = 1 end
                if obj.LocalTransparencyModifier ~= Config.PhantomLocalAlpha then
                    obj.LocalTransparencyModifier = Config.PhantomLocalAlpha
                end
            else
                if obj.LocalTransparencyModifier ~= 1 then
                    obj.LocalTransparencyModifier = 1
                end
            end
        end
    end
end

local function startLoop()
    if connection then return end
    -- RenderStepped = máxima frecuencia (se ejecuta antes de cada frame de cámara)
    connection = RunService.RenderStepped:Connect(reinforce)
end

local function stopLoop()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

function Config.Set(enabled, mode)
    if mode then Config.Mode = mode end
    Config.Enabled = enabled == true
    char = LocalPlayer.Character
    if Config.Enabled then
        if char then applyToCharacter(char) end
        startLoop()
    else
        stopLoop()
        restoreAll()
        restoreVisuals(char)
    end
end

function Config.SetMode(mode)
    if mode ~= "Local" and mode ~= "Phantom" then return end
    Config.Mode = mode
    if Config.Enabled then
        stopLoop()
        restoreAll()
        char = LocalPlayer.Character
        if char then applyToCharacter(char) end
        startLoop()
    end
end

function Config.Get() return Config.Enabled end

-- Respawn: reaplica si está activo
local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    if not Config.Enabled then return end
    newChar:WaitForChild("Humanoid", 5)
    task.wait(0.1)
    char = newChar
    applyToCharacter(newChar)
end)

env.__FROGGY_INVIS_CLEANUP = function()
    stopLoop()
    pcall(function() charAddedConn:Disconnect() end)
    pcall(function() Config.Set(false) end)
    env.FROGGY_INVIS_CONFIG = nil
    env.__FROGGY_INVIS_CLEANUP = nil
end

print("[Froggy Hub] Invisibility v1.3 (Dual Mode) cargado.")
