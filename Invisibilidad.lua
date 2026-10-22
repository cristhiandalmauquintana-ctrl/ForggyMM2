--// Invisibility.lua - Froggy Hub Module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__FROGGY_INVIS_CLEANUP then pcall(env.__FROGGY_INVIS_CLEANUP) end

local Config = {
    Enabled = false,
    Transparency = 1,
    Version = "v1.0"
}
env.FROGGY_INVIS_CONFIG = Config

local connections = {}
local originalStates = {}

local function setPartInvisible(part, isInvisible)
    if not part or not part.Parent then return end
    if not originalStates[part] then
        originalStates[part] = {
            Transparency = part.Transparency,
            LocalTransparencyModifier = part.LocalTransparencyModifier
        }
    end
    if isInvisible then
        part.Transparency = Config.Transparency
        part.LocalTransparencyModifier = Config.Transparency
    else
        local orig = originalStates[part]
        part.Transparency = orig.Transparency
        part.LocalTransparencyModifier = orig.LocalTransparencyModifier
        originalStates[part] = nil
    end
end

local function processCharacter(character)
    if not character then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            setPartInvisible(obj, Config.Enabled)
        elseif obj:IsA("Accessory") or obj:IsA("Hat") then
            local handle = obj:FindFirstChild("Handle")
            if handle then setPartInvisible(handle, Config.Enabled) end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if Config.Enabled then
                if not originalStates[obj] then originalStates[obj] = obj.Transparency end
                obj.Transparency = 1
            else
                if originalStates[obj] then obj.Transparency = originalStates[obj]; originalStates[obj] = nil end
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            if Config.Enabled then
                if not originalStates[obj] then originalStates[obj] = obj.Enabled end
                obj.Enabled = false
            else
                if originalStates[obj] ~= nil then obj.Enabled = originalStates[obj]; originalStates[obj] = nil end
            end
        end
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if Config.Enabled and LocalPlayer.Character then
        processCharacter(LocalPlayer.Character)
    end
end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(1)
    if Config.Enabled then processCharacter(newCharacter) end
end))

function Config.Set(value)
    Config.Enabled = value and true or false
    if LocalPlayer.Character then
        if Config.Enabled then
            processCharacter(LocalPlayer.Character)
        else
            for part, data in pairs(originalStates) do
                if part and part.Parent then
                    if part:IsA("BasePart") or part:IsA("MeshPart") then
                        part.Transparency = data.Transparency
                        part.LocalTransparencyModifier = data.LocalTransparencyModifier
                    elseif part:IsA("Decal") or part:IsA("Texture") then
                        part.Transparency = data
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                        part.Enabled = data
                    end
                end
            end
            originalStates = {}
        end
    end
end

env.__FROGGY_INVIS_CLEANUP = function()
    Config.Enabled = false
    for _, c in ipairs(connections) do c:Disconnect() end
    Config.Set(false)
    env.FROGGY_INVIS_CONFIG = nil
    env.__FROGGY_INVIS_CLEANUP = nil
end
