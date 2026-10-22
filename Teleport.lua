--// MM2 Hub - Teleport (Placeholder - Listo para lógica)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end

local Config = { TpPlayer = false, TpCoin = false }
env.MM2_TP_CONFIG = Config
local connections = {}

-- Bucle para TP a Jugador (Lógica futura aquí)
table.insert(connections, RunService.Heartbeat:Connect(function()
    if Config.TpPlayer then
        -- Lógica para buscar al jugador más cercano y teletransportarse
    end
end))

-- Bucle para TP a Moneda (Lógica futura aquí)
table.insert(connections, RunService.Heartbeat:Connect(function()
    if Config.TpCoin then
        -- Lógica para buscar monedas en el mapa y teletransportarse
    end
end))

env.__MM2_TP_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    env.MM2_TP_CONFIG = nil; env.__MM2_TP_CLEANUP = nil
end
