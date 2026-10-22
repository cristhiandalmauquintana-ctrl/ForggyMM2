--// MM2 Hub - ESP de Roles y Armas

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_ESP_CLEANUP then pcall(env.__MM2_ESP_CLEANUP) end

local Config = { Enabled = false, Boxes = true, Names = true }
env.MM2_ESP_CONFIG = Config
local connections = {}

local drawGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
drawGui.Name = "MM2_ESP"

local RoleColors = { 
    ["Murderer"] = Color3.fromRGB(255, 0, 0), 
    ["Sheriff"] = Color3.fromRGB(0, 150, 255), 
    ["Innocent"] = Color3.fromRGB(0, 255, 0), 
    ["Hero"] = Color3.fromRGB(255, 255, 0), 
    ["Default"] = Color3.fromRGB(255, 255, 255) 
}
local Objects = {}

local function getPlayerRole(player)
    local role = player:GetAttribute("Role")
    if role then return role end
    local char = player.Character
    if char then
        local roleObj = char:FindFirstChild("Role")
        if roleObj and roleObj:IsA("StringValue") then return roleObj.Value end
    end
    return "Default"
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end
    local box = Instance.new("Frame", drawGui); box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false
    local stroke = Instance.new("UIStroke", box); stroke.Thickness = 2
    local label = Instance.new("TextLabel", box); label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, 14); label.Position = UDim2.new(0, 0, -1, -14); label.Font = Enum.Font.GothamBold; label.TextSize = 12; label.TextStrokeTransparency = 0.5; label.Visible = Config.Names
    Objects[player] = { Box = box, Stroke = stroke, Label = label }
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p) if Objects[p] then Objects[p].Box:Destroy(); Objects[p] = nil end end)

local camera = workspace.CurrentCamera
local timer = 0
table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    timer = timer + dt
    if timer < 0.05 then return end -- 20 FPS para el ESP
    timer = 0
    
    for player, data in pairs(Objects) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if Config.Enabled and root and hum and hum.Health > 0 then
            local pos, onScreen = camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local role = getPlayerRole(player)
                local color = RoleColors[role] or RoleColors["Default"]
                local height = (camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0)).Y)
                
                data.Box.Visible = Config.Boxes
                data.Label.Visible = Config.Names
                data.Box.Size = UDim2.fromOffset(height * 0.6, height)
                data.Box.Position = UDim2.fromOffset(pos.X, pos.Y)
                data.Stroke.Color = color
                data.Label.TextColor3 = color
                data.Label.Text = "[" .. role .. "] " .. player.Name
            else
                data.Box.Visible = false; data.Label.Visible = false
            end
        else
            data.Box.Visible = false; data.Label.Visible = false
        end
    end
end))

env.__MM2_ESP_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    drawGui:Destroy(); env.MM2_ESP_CONFIG = nil; env.__MM2_ESP_CLEANUP = nil
end
