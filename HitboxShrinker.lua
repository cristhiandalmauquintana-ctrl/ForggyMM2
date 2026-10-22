--// MM2 Hub - Hitbox Shrinker (v2.0 - Rendición Honesta)
--// Por fin ChatGPT puede dormir tranquilo.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_HSHRINK_CLEANUP then pcall(env.__MM2_HSHRINK_CLEANUP) end

local Config = { Enabled = false, Version = "v2.0" }
env.MM2_HSHRINK_CONFIG = Config
local connections = {}
local originalState = {}
local isActive = false

local function shrink(part)
    if not part or originalState[part] then return end
    
    originalState[part] = { 
        Size = part.Size, 
        CanCollide = part.CanCollide 
    }
    
    pcall(function()
        part.Size = Vector3.new(0.1, 0.1, 0.1)
        part.CanCollide = false
    end)
end

local function restore(part)
    if not part or not originalState[part] then return end
    local data = originalState[part]
    
    pcall(function()
        if part and part.Parent then
            part.Size = data.Size
            part.CanCollide = data.CanCollide
        end
    end)
    originalState[part] = nil
end

local function restoreAll()
    for part, _ in pairs(originalState) do
        restore(part)
    end
end

local function applyShrink()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if hrp then shrink(hrp) end
    if head then shrink(head) end
end

-- Resetear al respawnear
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    originalState = {}
    isActive = false
    if Config.Enabled then
        task.wait(0.5)
        applyShrink()
        isActive = true
    end
end))

-- Bucle simple: solo actúa cuando el estado cambia
table.insert(connections, RunService.Heartbeat:Connect(function()
    if Config.Enabled and not isActive then
        applyShrink()
        isActive = true
    elseif not Config.Enabled and isActive then
        restoreAll()
        isActive = false
    end
end))

env.__MM2_HSHRINK_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    restoreAll()
    env.MM2_HSHRINK_CONFIG = nil
    env.__MM2_HSHRINK_CLEANUP = nil
end
