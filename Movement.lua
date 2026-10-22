--// MM2 Hub - Movement (v1.0)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_MOVE_CLEANUP then pcall(env.__MM2_MOVE_CLEANUP) end

local Config = { SpeedEnabled = false, Speed = 50, JumpEnabled = false, JumpPower = 100, Version = "v1.0" }
env.MM2_MOVE_CONFIG = Config
local connections = {}

table.insert(connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.SpeedEnabled then hum.WalkSpeed = Config.Speed else hum.WalkSpeed = 16 end
    if Config.JumpEnabled then hum.UseJumpPower = true; hum.JumpPower = Config.JumpPower else hum.JumpPower = 50 end
end))

env.__MM2_MOVE_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    env.MM2_MOVE_CONFIG = nil; env.__MM2_MOVE_CLEANUP = nil
end
