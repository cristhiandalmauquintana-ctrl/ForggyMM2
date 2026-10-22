--// MM2 Hub - ESP (v2.1 - Final)

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
    Version = "v2.1" 
}
env.MM2_ESP_CONFIG = Config
local connections = {}

local drawGui = Instance.new("ScreenGui")
drawGui.Name = "MM2_ESP"
drawGui.ResetOnSpawn = false
drawGui.Parent = game:GetService("CoreGui")

local RoleColors = { 
    ["Murderer"] = Color3.fromRGB(255, 0, 0), 
    ["Sheriff"] = Color3.fromRGB(0, 150, 255), 
    ["Innocent"] = Color3.fromRGB(0, 255, 0), 
    ["Unknown"] = Color3.fromRGB(200, 200, 200) 
}

local Objects = {}
local ItemObjects = {}

-- 🔥 FIX 1: Detección de roles con mejor lógica
local roundStartTime = os.clock()
local function getPlayerRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    
    local backpack = player:FindFirstChild("Backpack")
    
    if (char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then 
        return "Murderer" 
    end
    if (char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then 
        return "Sheriff" 
    end
    
    -- 🔥 Si la ronda acaba de empezar (menos de 3 segundos), es "Unknown"
    -- Después de 3 segundos sin arma, es inocente de verdad
    if os.clock() - roundStartTime < 3 then
        return "Unknown"
    end
    return "Innocent"
end

local function createESP(player)
    if player == LocalPlayer or Objects[player] then return end
    
    local box = Instance.new("Frame", drawGui)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local stroke = Instance.new("UIStroke", box)
    stroke.Thickness = 2
    
    local label = Instance.new("TextLabel", drawGui)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 200, 0, 14)
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.5
    label.Visible = false
    
    Objects[player] = { Box = box, Stroke = stroke, Label = label }
end

local function createItemESP(item, text, color, category)
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
    -- 🔥 Guardamos la categoría para la limpieza selectiva
    ItemObjects[item] = { Gui = billboard, Category = category }
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p) 
    if Objects[p] then 
        Objects[p].Box:Destroy() 
        Objects[p].Label:Destroy()
        Objects[p] = nil 
    end 
end)

-- Resetear el tiempo de ronda cuando el juego haga spawn a los jugadores
Players.PlayerAdded:Connect(function()
    roundStartTime = os.clock()
end)

local timer = 0
local itemTimer = 0

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    timer = timer + dt
    itemTimer = itemTimer + dt
    
    -- Actualizar jugadores
    if timer >= 0.05 then
        timer = 0
        for player, data in pairs(Objects) do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if Config.Enabled and root and hum and hum.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local role = getPlayerRole(player)
                    local color = RoleColors[role] or RoleColors["Unknown"]
                    
                    local topPos = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                    local botPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(topPos.Y - botPos.Y)
                    local width = height * 0.6
                    
                    data.Box.Visible = Config.Boxes
                    data.Box.Size = UDim2.fromOffset(width, height)
                    data.Box.Position = UDim2.fromOffset(pos.X, pos.Y)
                    data.Stroke.Color = color
                    
                    data.Label.Visible = Config.Names
                    data.Label.Position = UDim2.fromOffset(pos.X, pos.Y - (height / 2) - 4)
                    data.Label.TextColor3 = color
                    data.Label.Text = "[" .. role .. "] " .. player.Name
                else
                    data.Box.Visible = false
                    data.Label.Visible = false
                end
            elseif data then
                data.Box.Visible = false
                data.Label.Visible = false
            end
        end
    end

    -- Escanear items
    if itemTimer >= 1.0 then
        itemTimer = 0
        if Config.Enabled then
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("BasePart") then
                    local name = string.lower(item.Name)
                    
                    -- Solo si la categoría está activa
                    if Config.ShowCoins and (name == "coin" or name == "coint") and not ItemObjects[item] then
                        createItemESP(item, "💰 Moneda", Color3.fromRGB(255, 215, 0), "Coin")
                    end
                    
                    if Config.ShowWeapons and (name == "knife" or name == "knifehandle") and not ItemObjects[item] then
                        createItemESP(item, "🔪 Cuchillo", Color3.fromRGB(255, 0, 0), "Weapon")
                    end
                    
                    if Config.ShowWeapons and (name == "gun" or name == "revolver") and not ItemObjects[item] then
                        createItemESP(item, "🔫 Pistola", Color3.fromRGB(0, 150, 255), "Weapon")
                    end
                end
            end
        end
    end
end))

-- 🔥 FIX 2: Limpieza selectiva por categoría
table.insert(connections, RunService.Stepped:Connect(function()
    for item, data in pairs(ItemObjects) do
        local shouldRemove = false
        
        if not item or not item.Parent or not Config.Enabled then
            shouldRemove = true
        elseif data.Category == "Coin" and not Config.ShowCoins then
            shouldRemove = true
        elseif data.Category == "Weapon" and not Config.ShowWeapons then
            shouldRemove = true
        end
        
        if shouldRemove then
            data.Gui:Destroy()
            ItemObjects[item] = nil
        end
    end
end))

env.__MM2_ESP_CLEANUP = function()
    for _, c in ipairs(connections) do c:Disconnect() end
    if drawGui then drawGui:Destroy() end
    env.MM2_ESP_CONFIG = nil
    env.__MM2_ESP_CLEANUP = nil
end
