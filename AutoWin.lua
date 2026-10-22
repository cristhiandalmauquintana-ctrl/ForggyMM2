--// MM2 Hub - Auto-Win (v1.0 - Letal y Seguro)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_AUTOWIN_CLEANUP then pcall(env.__MM2_AUTOWIN_CLEANUP) end

local Config = { Enabled = false, Version = "v1.0" }
env.MM2_AUTOWIN_CONFIG = Config
local connections = {}
local originalAnchor = false
local originalSize = nil
local actionTimer = 0
local ACTION_DELAY = 0.3 -- Delay entre acciones para no ser detectado

-- Detección de roles
local function getRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function findTarget(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and getRole(p) == role then
                return p
            end
        end
    end
    return nil
end

local function equipAndAttack(toolName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not hum then return end
    
    local tool = char:FindFirstChild(toolName) or (backpack and backpack:FindFirstChild(toolName))
    if tool then
        if tool.Parent ~= char then
            pcall(function() hum:EquipTool(tool) end)
        end
        pcall(function() tool:Activate() end)
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then
        -- Restaurar si se apaga
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = originalAnchor
            if originalSize then hrp.Size = originalSize end
        end
        return
    end

    actionTimer = actionTimer + dt
    if actionTimer < ACTION_DELAY then return end
    actionTimer = 0

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not myHum or myHum.Health <= 0 then return end

    local myRole = getRole(LocalPlayer)

    if myRole == "Sheriff" then
        -- 1. LÓGICA SHERIFF
        local murderer = findTarget("Murderer")
        if murderer and murderer.Character then
            local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
            if mRoot then
                -- Flotar encima del Murderer
                hrp.Anchored = true
                hrp.CFrame = CFrame.lookAt(mRoot.Position + Vector3.new(0, 15, 0), mRoot.Position)
                equipAndAttack("Gun")
            end
        end
    elseif myRole == "Murderer" then
        -- 2. LÓGICA MURDERER
        -- Busca Inocentes primero, si no hay, va por el Sheriff
        local target = findTarget("Innocent") or findTarget("Sheriff")
        if target and target.Character then
            local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                -- Teletransportarse detrás
                hrp.Anchored = false
                hrp.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                equipAndAttack("Knife")
            end
        end
    else
        -- 3. LÓGICA INOCENTE (Supervivencia)
        if not originalSize then originalSize = hrp.Size end
        hrp.Anchored = true
        hrp.CFrame = CFrame.new(0, 500, 0) -- Vuela al cielo
        hrp.Size = Vector3.new(0.1, 0.1, 0.1) -- Hitbox mínima
    end
end))

env.__MM2_AUTOWIN_CLEANUP = function()
    Config.Enabled = false
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = originalAnchor
        if originalSize then hrp.Size = originalSize end
    end
    for _, c in ipairs(connections) do c:Disconnect() end
    env.MM2_AUTOWIN_CONFIG = nil; env.__MM2_AUTOWIN_CLEANUP = nil
end
