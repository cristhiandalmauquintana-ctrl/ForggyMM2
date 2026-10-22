--// MM2 Hub - Hitbox Expander (v1.0)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_HITBOX_CLEANUP then pcall(env.__MM2_HITBOX_CLEANUP) end

local Config = { Enabled = false, Size = 10, Version = "v1.0" }
env.MM2_HITBOX_CONFIG = Config
local connections = {}
local expandedParts = {}

local function expand(part)
    if expandedParts[part] then return end
    expandedParts[part] = { Size = part.Size, CanCollide = part.CanCollide, Massless = part.Massless }
    pcall(function()
        part.Size = Vector3.new(Config.Size, Config.Size, Config.Size)
        part.CanCollide = false; part.Massless = true
    end)
end

local function restore(part)
    if not expandedParts[part] then return end
    local data = expandedParts[part]
    pcall(function()
        if part and part.Parent then
            part.Size = data.Size; part.CanCollide = data.CanCollide; part.Massless = data.Massless
        end
    end)
    expandedParts[part] = nil
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then for part, _ in pairs(expandedParts) do restore(part) end return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then expand(root)
            elseif root then restore(root) end
        end
    end
end))

env.__MM2_HITBOX_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    for part, _ in pairs(expandedParts) do restore(part) end
    env.MM2_HITBOX_CONFIG = nil; env.__MM2_HITBOX_CLEANUP = nil
end
