--// Movement.lua - Froggy Hub Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- 🔥 Esta es la variable que el panel busca
local Config = {
    WalkSpeed = 16,
    JumpPower = 50,
    Enabled = false
}
env.FROGGY_MOVE_CONFIG = Config

local connections = {}

-- Bucle para aplicar la velocidad y el salto
table.insert(connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.Enabled then
            hum.WalkSpeed = Config.WalkSpeed
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpPower
        end
    end
end))

env.__FROGGY_MOVE_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    env.FROGGY_MOVE_CONFIG = nil
    env.__FROGGY_MOVE_CLEANUP = nil
end
