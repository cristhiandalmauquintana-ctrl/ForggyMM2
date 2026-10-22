--// MM2 Hub - Silent Aim (v1.3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local env = (getgenv and getgenv()) or _G
if env.__MM2_SA_CLEANUP then pcall(env.__MM2_SA_CLEANUP) end

local Config = { Enabled = false, FOV = 250, ShowFOV = true, Version = "v1.3" }
env.MM2_SA_CONFIG = Config
local connections = {}

local fovGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
fovGui.Name = "MM2_FOV"
fovGui.ResetOnSpawn = false
local fovCircle = Instance.new("Frame", fovGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5); fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1; fovCircle.BorderSizePixel = 0; fovCircle.Visible = false
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(92, 200, 255); fovStroke.Thickness = 2; fovStroke.Transparency = 0.3

local function getRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function getTarget()
    local myRole = getRole(LocalPlayer)
    local closest = nil
    local shortestDist = Config.FOV
    local center = Camera.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local role = getRole(player)

            local isValid = false
            if myRole == "Sheriff" and role == "Murderer" then isValid = true end
            if myRole == "Murderer" and role ~= "Murderer" then isValid = true end

            if isValid and hum and hum.Health > 0 and root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen and pos.Z > 0 then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortestDist then closest = root; shortestDist = dist end
                end
            end
        end
    end
    return closest
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
    if Config.Enabled and (self == Mouse or self == Camera) then
        local target = getTarget()
        if target then
            if key == "Hit" then return CFrame.new(target.Position) end
            if key == "Target" then return target end
        end
    end
    return oldIndex(self, key)
end)
setreadonly(mt, true)

table.insert(connections, RunService.RenderStepped:Connect(function()
    if Config.Enabled and Config.ShowFOV then
        fovCircle.Visible = true
        fovCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    else
        fovCircle.Visible = false
    end
end))

env.__MM2_SA_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    fovGui:Destroy()
    pcall(function() setreadonly(mt, false); mt.__index = oldIndex; setreadonly(mt, true) end)
    env.MM2_SA_CONFIG = nil; env.__MM2_SA_CLEANUP = nil
end
