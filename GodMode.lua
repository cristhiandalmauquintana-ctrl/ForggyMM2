--// MM2 Hub - God Mode (Inmortalidad)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_GOD_CLEANUP then pcall(env.__MM2_GOD_CLEANUP) end

local Config = { Enabled = false }
env.MM2_GOD_CONFIG = Config

-- Hook para ignorar el daño
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "TakeDamage" and Config.Enabled then
        if self == LocalPlayer.Character or self.Parent == LocalPlayer.Character then 
            return -- Ignora el daño
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- Bucle de seguridad (por si el juego intenta matarte de otra forma)
local conn = RunService.Heartbeat:Connect(function()
    if Config.Enabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end
end)

env.__MM2_GOD_CLEANUP = function()
    if conn then conn:Disconnect() end
    pcall(function() setreadonly(mt, false); mt.__namecall = oldNamecall; setreadonly(mt, true) end)
    env.MM2_GOD_CONFIG = nil; env.__MM2_GOD_CLEANUP = nil
end
