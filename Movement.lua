--// MM2 Hub - Movement (TSB Edition v1.2)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MM2_MOVE_CLEANUP then pcall(env.__MM2_MOVE_CLEANUP) end

local Config = {
    SpeedEnabled = false,
    Speed = 36,             -- TSB-friendly (16 base, 36 ya vuela visualmente)
    JumpEnabled = false,
    JumpPower = 60,         -- 50 base, 60 se nota pero no canta
    RespectStuns = true,    -- no sobrescribe si el juego te rootea/stunea
    MinGameSpeed = 6,       -- si el juego te pone por debajo de esto, es stun/root
    Version = "v1.2-TSB"
}
env.MM2_MOVE_CONFIG = Config

local connections = {}
local hum, originalSpeed, originalJumpPower, originalUseJumpPower

local function bindCharacter(char)
    local h = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if not h then return end
    hum = h
    originalSpeed = math.max(h.WalkSpeed, 16) -- evita heredar 0 de un stun previo
    originalJumpPower = h.JumpPower
    originalUseJumpPower = h.UseJumpPower
end

local function unbindCharacter() hum = nil end

if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(bindCharacter))
table.insert(connections, LocalPlayer.CharacterRemoving:Connect(unbindCharacter))

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not hum or not hum.Parent or hum.Health <= 0 then return end

    local currentSpeed = hum.WalkSpeed
    local targetSpeed = Config.SpeedEnabled and Config.Speed or (originalSpeed or 16)

    -- TSB: si el juego te stunea/rootea/bloquea, no peleamos con él
    if Config.RespectStuns and currentSpeed < Config.MinGameSpeed and currentSpeed ~= targetSpeed then
        return
    end

    if currentSpeed ~= targetSpeed then
        hum.WalkSpeed = targetSpeed
    end

    if Config.JumpEnabled then
        if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
        if hum.JumpPower ~= Config.JumpPower then hum.JumpPower = Config.JumpPower end
    else
        if hum.UseJumpPower ~= originalUseJumpPower then hum.UseJumpPower = originalUseJumpPower end
        if hum.JumpPower ~= originalJumpPower then hum.JumpPower = originalJumpPower end
    end
end))

env.__MM2_MOVE_CLEANUP = function()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if hum and hum.Parent then
        pcall(function()
            hum.WalkSpeed = originalSpeed or 16
            hum.JumpPower = originalJumpPower or 50
            hum.UseJumpPower = originalUseJumpPower
        end)
    end
    env.MM2_MOVE_CONFIG = nil
    env.__MM2_MOVE_CLEANUP = nil
end
