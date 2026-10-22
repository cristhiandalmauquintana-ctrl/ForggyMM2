--// MM2 Hub - Teleport (v1.2 - Event Driven)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end

local Config = { TpPlayer = false, TpCoin = false, Version = "v1.2" }
env.MM2_TP_CONFIG = Config
local connection

-- Función que hace el teletransporte al jugador
local function teleportToPlayer()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local closest, shortest = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < shortest then 
                    closest = root
                    shortest = d 
                end
            end
        end
    end
    
    if closest then 
        myRoot.CFrame = closest.CFrame + Vector3.new(0, 3, 0) 
    end
end

-- Función que hace el teletransporte a la moneda
local function teleportToCoin()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local closest, shortest = nil, math.huge
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("BasePart") then
            local name = string.lower(item.Name)
            if name == "coin" or name == "coint" then
                local d = (item.Position - myRoot.Position).Magnitude
                if d < shortest then 
                    closest = item
                    shortest = d 
                end
            end
        end
    end
    
    if closest then 
        myRoot.CFrame = CFrame.new(closest.Position + Vector3.new(0, 2, 0)) 
    end
end

-- 🔥 Bucle ultra ligero: solo comprueba si hay que hacer TP
connection = RunService.Heartbeat:Connect(function()
    if Config.TpPlayer then
        Config.TpPlayer = false -- Se apaga solo
        teleportToPlayer()
    elseif Config.TpCoin then
        Config.TpCoin = false -- Se apaga solo
        teleportToCoin()
    end
end)

env.__MM2_TP_CLEANUP = function()
    if connection then connection:Disconnect() end
    env.MM2_TP_CONFIG = nil; env.__MM2_TP_CLEANUP = nil
end
