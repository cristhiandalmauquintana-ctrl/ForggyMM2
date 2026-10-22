--// MM2 Hub - Auto-Win (v4.1 - Void Launch)
--// El Sheriff lanza al Murderer fuera del mapa.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local env = (getgenv and getgenv()) or _G
if env.__MM2_AUTOWIN_CLEANUP then pcall(env.__MM2_AUTOWIN_CLEANUP) end

local Config = { Enabled = false, Version = "v4.1" }
env.MM2_AUTOWIN_CONFIG = Config

local connections = {}
local originalSize = nil
local originalPosition = nil
local wasEnabled = false
local lastAttack = 0

--==================================================
-- DETECCIÓN DE ROL
--==================================================
local function getRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then return "Murderer" end
    if (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))) or
       (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))) then return "Sheriff" end
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

local function findGun()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, name in ipairs({"Gun", "Revolver"}) do
        local tool = char and char:FindFirstChild(name)
        if tool then return tool end
        tool = backpack and backpack:FindFirstChild(name)
        if tool then return tool end
    end
    return nil
end

local function findKnife()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, name in ipairs({"Knife", "KnifeHandle"}) do
        local tool = char and char:FindFirstChild(name)
        if tool then return tool end
        tool = backpack and backpack:FindFirstChild(name)
        if tool then return tool end
    end
    return nil
end

--==================================================
-- 🔥 SHERIFF: LANZAR AL MURDERER FUERA DEL MAPA
--==================================================
local function sheriffVoidLaunch(myRoot, murdererRoot)
    local murdererChar = murdererRoot.Parent
    local murdererHum = murdererChar and murdererChar:FindFirstChildOfClass("Humanoid")
    if not murdererHum then return end
    
    -- 1. TP exactamente a la posición del Murderer
    myRoot.Anchored = true
    myRoot.CFrame = murdererRoot.CFrame
    
    -- 2. Ragdoll (pierde control)
    pcall(function()
        murdererHum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    
    -- 3. Aplicar velocidad HORIZONTAL masiva (fuera del mapa)
    -- Elegimos una dirección aleatoria en X/Z
    local dir = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
    if dir.Magnitude < 1 then dir = Vector3.new(1, 0, 0) end
    dir = dir.Unit
    
    local bvHorizontal = Instance.new("BodyVelocity")
    bvHorizontal.Velocity = dir * 500 -- 500 studs/s horizontales
    bvHorizontal.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bvHorizontal.Parent = murdererRoot
    
    -- 4. Aplicar velocidad VERTICAL (hacia arriba)
    local bvVertical = Instance.new("BodyVelocity")
    bvVertical.Velocity = Vector3.new(0, 200, 0)
    bvVertical.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bvVertical.Parent = murdererRoot
    
    -- 5. Girar mientras vuela
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(30, 30, 30)
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.Parent = murdererRoot
    
    -- 6. Limpiar después de 3 segundos (ya estará fuera del mapa)
    task.delay(3, function()
        if bvHorizontal then bvHorizontal:Destroy() end
        if bvVertical then bvVertical:Destroy() end
        if bav then bav:Destroy() end
    end)
    
    -- 7. Disparar mientras vuela (por si acaso)
    if Camera then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, murdererRoot.Position)
    end
    
    task.spawn(function()
        local gun = findGun()
        if not gun then return end
        
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHum then return end
        
        pcall(function() myHum:EquipTool(gun) end)
        task.wait(0.1)
        
        -- 3 disparos mientras vuela
        for i = 1, 3 do
            if murdererHum and murdererHum.Health > 0 and murdererRoot and murdererRoot.Parent then
                if Camera then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, murdererRoot.Position)
                end
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end)
                pcall(function() gun:Activate() end)
                task.wait(0.15)
            else
                break
            end
        end
    end)
    
    print("[AutoWin] 🚀 Murderer lanzado al vacío!")
end

--==================================================
-- MURDERER (sin cambios)
--==================================================
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

local function murdererAction(myRoot, targetRoot)
    myRoot.Anchored = false
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    expandHitbox(targetRoot)
    
    local knife = findKnife()
    if not knife then return end
    
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum then return end
    
    pcall(function() myHum:EquipTool(knife) end)
    task.wait(0.1)
    
    pcall(function() knife:Activate() end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end

--==================================================
-- LOOP PRINCIPAL
--==================================================
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    -- Detectar ON/OFF
    if Config.Enabled and not wasEnabled then
        wasEnabled = true
        originalPosition = hrp.CFrame
        originalSize = hrp.Size
        
        local role = getRole(LocalPlayer)
        if role == "Innocent" then
            hrp.Anchored = true
            hrp.CFrame = CFrame.new(0, 500, 0)
            hrp.Size = Vector3.new(0.1, 0.1, 0.1)
        end
    elseif not Config.Enabled and wasEnabled then
        wasEnabled = false
        hrp.Anchored = false
        
        if originalPosition then
            hrp.CFrame = originalPosition
            originalPosition = nil
        end
        if originalSize then
            hrp.Size = originalSize
            originalSize = nil
        end
        restoreHitboxes()
    end
    
    if not Config.Enabled then return end
    if hum.Health <= 0 then return end
    
    local now = os.clock()
    if now - lastAttack < 3 then return end
    
    local myRole = getRole(LocalPlayer)
    
    if myRole == "Sheriff" then
        local murdererRoot = findTarget("Murderer")
        if murdererRoot then
            local mHum = murdererRoot.Parent and murdererRoot.Parent:FindFirstChildOfClass("Humanoid")
            if mHum and mHum.Health > 0 then
                lastAttack = now
                sheriffVoidLaunch(hrp, murdererRoot)
            end
        end
        
    elseif myRole == "Murderer" then
        local target = findTarget("Innocent") or findTarget("Sheriff")
        if target then
            lastAttack = now
            murdererAction(hrp, target)
        end
        
    else
        if not hrp.Anchored then
            hrp.Anchored = true
            hrp.CFrame = CFrame.new(0, 500, 0)
            hrp.Size = Vector3.new(0.1, 0.1, 0.1)
        end
    end
end))

--==================================================
-- LIMPIEZA
--==================================================
env.__MM2_AUTOWIN_CLEANUP = function()
    Config.Enabled = false
    wasEnabled = false
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if originalPosition then hrp.CFrame = originalPosition end
        if originalSize then hrp.Size = originalSize end
        hrp.Anchored = false
    end
    
    restoreHitboxes()
    
    -- Limpiar BodyVelocity/BodyAngularVelocity de todos los jugadores
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local mRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if mRoot then
                for _, obj in ipairs(mRoot:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") then
                        obj:Destroy()
                    end
                end
            end
        end
    end
    
    for _, c in ipairs(connections) do c:Disconnect() end
    env.MM2_AUTOWIN_CONFIG = nil
    env.__MM2_AUTOWIN_CLEANUP = nil
end
