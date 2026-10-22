--// MM2 Hub - GodMode (v3.2 - Fixed __newindex Bug)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_GOD_CLEANUP then pcall(env.__MM2_GOD_CLEANUP) end

local Config = { Enabled = false, Version = "v3.2" }
env.MM2_GOD_CONFIG = Config

local connections = {}
local isRestoring = false -- 🔥 Flag para el bypass

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldNewIndex = mt.__newindex
setreadonly(mt, false)

-- 1. Bloquear TakeDamage (Cuchillo/Pistola)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if Config.Enabled and method == "TakeDamage" then
        if self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
            return -- Bloquea el daño
        end
    end
    return oldNamecall(self, ...)
end)

-- 2. Bloquear cambios de Health EXCEPTO cuando nosotros lo hagamos
mt.__newindex = newcclosure(function(self, key, value)
    if Config.Enabled and not isRestoring then
        if self:IsA("Humanoid") and (key == "Health" or key == "MaxHealth") then
            if self.Parent == LocalPlayer.Character then
                return -- Bloquea cambios externos
            end
        end
    end
    return oldNewIndex(self, key, value)
end)
setreadonly(mt, true)

-- 3. Bucle de restauración (usa el bypass)
local conn = RunService.Heartbeat:Connect(function()
    if Config.Enabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health < hum.MaxHealth then
            isRestoring = true -- 🔥 Permite el cambio
            pcall(function()
                oldNewIndex(hum, "Health", hum.MaxHealth)
            end)
            task.wait() -- Deja que el juego procese
            isRestoring = false
        end
    end
end)

env.__MM2_GOD_CLEANUP = function()
    if conn then conn:Disconnect() end
    pcall(function() 
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        mt.__newindex = oldNewIndex
        setreadonly(mt, true)
    end)
    env.MM2_GOD_CONFIG = nil
    env.__MM2_GOD_CLEANUP = nil
end
