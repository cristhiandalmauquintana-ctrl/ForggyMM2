--// MM2 Hub - ESP (v1.3 - Players, Weapons & Coins)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_ESP_CLEANUP then pcall(env.__MM2_ESP_CLEANUP) end

local Config = { 
    Enabled = false, 
    Boxes = true, 
    Names = true, 
    ShowWeapons = true, 
    ShowCoins = true, 
    Version = "v1.3" 
}
env.MM2_ESP_CONFIG = Config
local connections = {}

local drawGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
drawGui.Name = "MM2_ESP"

local RoleColors = { 
    ["Murderer"] = Color3.fromRGB(255, 0, 0), 
    ["Sheriff"] = Color3.fromRGB(0, 150, 255), 
    ["Innocent"] = Color3.fromRGB(0, 255, 0), 
    ["Default"] = Color3.fromRGB(255, 255, 255) 
}
local Objects = {}
local ItemObjects = {} -- Guardar los textos de armas/monedas

local function getPlayerRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
    if (char and char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end
    local box = Instance.new("Frame", drawGui); box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false
    local stroke = Instance.new("UIStroke", box); stroke.Thickness = 2
    local label = Instance.new("TextLabel", box); label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 0, 14); label.Position = UDim2.new(0, 0, -1, -14); label.Font = Enum.Font.GothamBold; label.TextSize = 12; label.TextStrokeTransparency = 0.5; label.Visible = Config.Names
    Objects[player] = { Box = box, Stroke = stroke, Label = label }
end

-- 🔥 FUNCIÓN PARA CREAR TEXTO 3D EN ITEMS (Armas/Monedas) 🔥
local function createItemESP(item, text, color)
    if ItemObjects[item] then return end
    local billboard = Instance.new("BillboardGui", drawGui)
    billboard.Name = "ItemESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(100, 30)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    
    local label = Instance.new("TextLabel", billboard)
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.3
    label.Text = text
    
    billboard.Adornee = item
    ItemObjects[item] = billboard
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p) if Objects[p] then Objects[p].Box:Destroy(); Objects[p] = nil end end)

local camera = workspace.CurrentCamera
local timer = 0
table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    timer = timer + dt
    if timer < 0.05 then return end
    timer = 0
    
    -- 1. ESP de Jugadores
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

    -- 2. ESP de Armas y Monedas (Escaneo de Workspace)
    if Config.Enabled and (Config.ShowWeapons or Config.ShowCoins) then
        for _, item in ipairs(Workspace:GetChildren()) do
            local name = string.lower(item.Name)
            
            -- Lógica para Monedas
            if Config.ShowCoins and string.find(name, "coin") and not ItemObjects[item] then
                createItemESP(item, "💰 Moneda", Color3.fromRGB(255, 215, 0))
            end
            
            -- Lógica para Cuchillo (Murderer)
            if Config.ShowWeapons and (string.find(name, "knife") or string.find(name, "murderer")) and not ItemObjects[item] then
                createItemESP(item, "🔪 Cuchillo", Color3.fromRGB(255, 0, 0))
            end
            
            -- Lógica para Pistola (Sheriff)
            if Config.ShowWeapons and (string.find(name, "gun") or string.find(name, "revolver") or string.find(name, "sheriff")) and not ItemObjects[item] then
                createItemESP(item, "🔫 Pistola", Color3.fromRGB(0, 150, 255))
            end
        end
    end
end))

-- Limpieza de items que ya no existen (recogidos)
table.insert(connections, RunService.Stepped:Connect(function()
    for item, gui in pairs(ItemObjects) do
        if not item or not item.Parent then
            gui:Destroy()
            ItemObjects[item] = nil
        elseif not Config.Enabled or (not Config.ShowWeapons and not Config.ShowCoins) then
            gui:Destroy()
            ItemObjects[item] = nil
        elseif (string.find(string.lower(item.Name), "coin") and not Config.ShowCoins) or
               ((string.find(string.lower(item.Name), "knife") or string.find(string.lower(item.Name), "gun")) and not Config.ShowWeapons) then
            gui:Destroy()
            ItemObjects[item] = nil
        end
    end
end))

env.__MM2_ESP_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    drawGui:Destroy(); env.MM2_ESP_CONFIG = nil; env.__MM2_ESP_CLEANUP = nil
end
