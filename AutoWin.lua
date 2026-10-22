--// MM2 Hub - Auto-Win (v2.0 - Full Combat)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local env = (getgenv and getgenv()) or _G
if env.__MM2_AUTOWIN_CLEANUP then pcall(env.__MM2_AUTOWIN_CLEANUP) end

local Config = { Enabled = false, Version = "v2.0" }
env.MM2_AUTOWIN_CONFIG = Config
local connections = {}

local originalSize = nil
local originalAnchor = false
local lastAttack = 0
local ATTACK_DELAY = 0.2

-- 🔥 SILENT AIM: apunta al enemigo automáticamente
local targetPart = nil

local function getRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function findTarget(role)
    local closest, shortest = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root and getRole(p) == role then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < shortest then
                    closest = root
                    shortest = d
                end
            end
        end
    end
    return closest
end

-- Hook de Silent Aim (solo para Sheriff)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if Config.Enabled and targetPart and (self == Mouse or self == Camera) then
        local myRole = getRole(LocalPlayer)
        if myRole == "Sheriff" then
            if key == "Hit" then return CFrame.new(targetPart.Position) end
            if key == "Target" then return targetPart end
            if key == "UnitRay" then
                local origin = oldIndex(self, "Origin")
                return Ray.new(origin, (targetPart.Position - origin).Unit * 1000)
            end
        end
    end
    return oldIndex(self, key)
end)
setreadonly(mt, true)

-- Auto-attack
local function attack(toolName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local tool = char:FindFirstChild(toolName) 
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        tool = backpack and backpack:FindFirstChild(toolName)
    end
    
    if tool then
        if tool.Parent ~= char then
            pcall(function() hum:EquipTool(tool) end)
        end
        pcall(function()
            tool:Activate()
        end)
    end
end

-- Hitbox expander (para Murderer)
local expandedParts = {}
local function expandHitbox(target)
    if not target or expandedParts[target] then return end
    expandedParts[target] = target.Size
    pcall(function()
        target.Size = Vector3.new(8, 8, 8)
        target.CanCollide = false
        target.Transparency = 0.7
    end)
end

local function restoreHitboxes()
    for part, size in pairs(expandedParts) do
        pcall(function()
            if part and part.Parent then
                part.Size = size
                part.CanCollide = true
                part.Transparency = 0
            end
        end)
    end
    expandedParts = {}
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not Config.Enabled then
        targetPart = nil
        restoreHitboxes()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = originalAnchor
            if originalSize then hrp.Size = originalSize end
        end
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not myHum or myHum.Health <= 0 then return end

    local myRole = getRole(LocalPlayer)
    local now = os.clock()

    if myRole == "Sheriff" then
        -- 🚔 SHERIFF: Flotar + Silent Aim + Auto-Shoot
        local murdererRoot = findTarget("Murderer")
        if murdererRoot then
            targetPart = murdererRoot
            hrp.Anchored = true
            hrp.CFrame = CFrame.lookAt(murdererRoot.Position + Vector3.new(0, 15, 0), murdererRoot.Position)
            
            if now - lastAttack >= 0.4 then
                lastAttack = now
                attack("Gun")
            end
        end
    elseif myRole == "Murderer" then
        -- 🔪 MURDERER: TP + Hitbox Expander + Auto-M1
        local target = findTarget("Innocent") or findTarget("Sheriff")
        if target then
            targetPart = target
            hrp.Anchored = false
            hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
            expandHitbox(target)
            
            if now - lastAttack >= ATTACK_DELAY then
                lastAttack = now
                attack("Knife")
                pcall(function()
                    local virtualUser = game:GetService("VirtualUser")
                    virtualUser:CaptureController()
                    virtualUser:ClickButton1(Vector2.new(0,0))
                end)
            end
        end
    else
        -- 🛡️ INOCENTE: Volar al cielo + hitbox shrink
        if not originalSize then originalSize = hrp.Size end
        hrp.Anchored = true
        hrp.CFrame = CFrame.new(0, 500, 0)
        hrp.Size = Vector3.new(0.1, 0.1, 0.1)
    end
end))

env.__MM2_AUTOWIN_CLEANUP = function()
    Config.Enabled = false
    targetPart = nil
    restoreHitboxes()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = originalAnchor
        if originalSize then hrp.Size = originalSize end
    end
    for _, c in ipairs(connections) do c:Disconnect() end
    pcall(function() setreadonly(mt, false); mt.__index = oldIndex; setreadonly(mt, true) end)
    env.MM2_AUTOWIN_CONFIG = nil; env.__MM2_AUTOWIN_CLEANUP = nil
end
