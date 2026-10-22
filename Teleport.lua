--// MM2 Hub - Teleport (v1.0)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end

local Config = { TpPlayer = false, TpCoin = false, Version = "v1.0" }
env.MM2_TP_CONFIG = Config
local connections = {}

table.insert(connections, RunService.Heartbeat:Connect(function()
    if Config.TpPlayer then
        -- Lógica futura para TP al jugador
    end
    if Config.TpCoin then
        -- Lógica futura para TP a la moneda
    end
end))

env.__MM2_TP_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    env.MM2_TP_CONFIG = nil; env.__MM2_TP_CLEANUP = nil
end
