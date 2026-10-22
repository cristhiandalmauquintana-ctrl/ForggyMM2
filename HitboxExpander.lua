--// MM2 Hub - Safe Hitbox Expander (v2.0 - R15)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_HITBOX_CLEANUP then pcall(env.__MM2_HITBOX_CLEANUP) end

local Config = { 
    Enabled = false, 
    Size = 8, 
    TargetPart = "HumanoidRootPart", -- Opciones: "HumanoidRootPart" o "Head"
    Transparency = 0.5, -- Un poco transparente para verlo
    Version = "v2.0" 
}
env.MM2_HITBOX_CONFIG = Config
local connections = {}
local expandedParts = {}

local function expand(part)
    if expandedParts[part] then return end
    
    -- Guardar propiedades originales
    expandedParts[part] = { 
        Size = part.Size, 
        CanCollide = part.CanCollide, 
        Massless = part.Massless,
        Transparency = part.Transparency
    }
    
    pcall(function()
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        part.CanCollide = false 
        part.Massless = true
        part.Transparency = Config.Transparency
    end)
end

local function restore(part)
    if not expandedParts[part] then return end
    local data = expandedParts[part]
    
    pcall(function()
        if part and part.Parent then
            part.Size = data.Size
            part.CanCollide = data.CanCollide
            part.Massless = data.Massless
            part.Transparency = data.Transparency
        end
    end)
    expandedParts[part] = nil
end

local function getTargetPart(character)
    if Config.TargetPart == "Head" then
        return character:FindFirstChild("Head")
    else
        return character:FindFirstChild("HumanoidRootPart")
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    -- Limpieza de partes que ya no existen (jugadores muertos o que se fueron)
    for part, _ in pairs(expandedParts) do
        if not part or not part.Parent then
            restore(part)
        end
    end

    if not Config.Enabled then
        for part, _ in pairs(expandedParts) do restore(part) end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local target = getTargetPart(player.Character)
            
            if hum and hum.Health > 0 and target then
                expand(target)
            elseif target then
                -- Si el jugador está muerto, restaurar
                restore(target)
            end
        end
    end
end))

env.__MM2_HITBOX_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    for part, _ in pairs(expandedParts) do restore(part) end
    env.MM2_HITBOX_CONFIG = nil; env.__MM2_HITBOX_CLEANUP = nil
end
