--// Main.lua - Froggy Hub (TSB) | UI + Loader

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "ForggyMM2"
local BRANCH = "main"
local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)
local LOGO_FILES = { "logo.png", "Logo.png" }
local INVIS_FILES = { "Invisibility.lua", "invisibility.lua" }

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- DESCARGADORES
------------------------------------------------------------
local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    for _, name in ipairs(LOGO_FILES) do
        local url = BASE_URL .. name .. "?v=" .. os.time()
        local ok, data = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_Logo.png"
            if pcall(writefile, path, data) then
                local okAsset, asset = pcall(getAsset, path)
                if okAsset and asset and asset ~= "" then return asset end
            end
        end
    end
    return nil
end

local function downloadModule(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then return res end
    end
    return nil
end

local function loadModule(names, configKey)
    local src = downloadModule(names)
    if not src then return nil end
    local chunk, err = loadstring(src)
    if type(chunk) ~= "function" then warn("[Froggy Hub] Error de sintaxis: " .. tostring(err)) return nil end
    local ok, runErr = pcall(chunk)
    if not ok then warn("[Froggy Hub] Error ejecutando módulo: " .. tostring(runErr)) return nil end
    return (getgenv and getgenv() or _G)[configKey]
end

local MyLogo = fetchLogo() or "rbxassetid://123456789"

------------------------------------------------------------
-- CONFIG Y TEMA (Mismo de Claude)
------------------------------------------------------------
local CONFIG = {
	Name = "Froggy Hub",
	Version = "v1.0",
	LogoId = MyLogo,
	BaseSize = Vector2.new(560, 360),
	HeaderHeight = 48,
	SidebarWidth = 124,
	NotifyTime = 3,
}

local Theme = {
	BgDeep = Color3.fromRGB(4, 9, 7), Bg = Color3.fromRGB(8, 18, 13), Swamp = Color3.fromRGB(14, 42, 30),
	Card = Color3.fromRGB(16, 32, 25), CardHover = Color3.fromRGB(25, 50, 39), Neon = Color3.fromRGB(57, 255, 120),
	Mint = Color3.fromRGB(152, 255, 205), Gold = Color3.fromRGB(255, 208, 64), Text = Color3.fromRGB(228, 247, 237),
	SubText = Color3.fromRGB(130, 172, 152), Off = Color3.fromRGB(42, 62, 52), Danger = Color3.fromRGB(255, 95, 95),
}

local function new(className, props, parent)
	local inst = Instance.new(className)
	if props then for k, v in pairs(props) do inst[k] = v end end
	if parent then inst.Parent = parent end
	return inst
end
local function tween(inst, duration, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play(); return t
end
local function addCorner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
local function addStroke(p, c, t, tr) return new("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0 }, p) end
local function safeCall(cb, ...) if typeof(cb) ~= "function" then return end; pcall(cb, ...) end
local orderCounters = setmetatable({}, { __mode = "k" })
local function nextOrder(p) orderCounters[p] = (orderCounters[p] or 0) + 1; return orderCounters[p] end
local connections = {}

------------------------------------------------------------
-- CARGA DE MÓDULOS
------------------------------------------------------------
local InvisConfig = loadModule(INVIS_FILES, "FROGGY_INVIS_CONFIG")

------------------------------------------------------------
-- UI (Claude's Code base)
------------------------------------------------------------
local oldGui = playerGui:FindFirstChild("FroggyHub")
if oldGui then oldGui:Destroy() end
local screenGui = new("ScreenGui", { Name = "FroggyHub", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100 }, playerGui)
local main = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(CONFIG.BaseSize.X, CONFIG.BaseSize.Y), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ClipsDescendants = true }, screenGui)
addCorner(main, 14); addStroke(main, Theme.Neon, 1.5, 0.35)
local uiScale = new("UIScale", { Scale = 0 }, main)
local function computeScale() local vp = screenGui.AbsoluteSize; return math.max(math.min(vp.X / (CONFIG.BaseSize.X + 40), vp.Y / (CONFIG.BaseSize.Y + 40), 1), 0.5) end

-- Fondo animado simplificado para ahorrar espacio
local bgLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Bg, ZIndex = 1 }, main)
addCorner(bgLayer, 14)
new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.BgDeep), ColorSequenceKeypoint.new(0.5, Theme.Swamp), ColorSequenceKeypoint.new(1, Theme.BgDeep) }), Rotation = 45 }, bgLayer)

local header = new("Frame", { Size = UDim2.new(1, 0, 0, CONFIG.HeaderHeight), BackgroundColor3 = Theme.BgDeep, BackgroundTransparency = 0.35, ZIndex = 4 }, main)
local logo = new("ImageLabel", { Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(32, 32), Image = CONFIG.LogoId, BackgroundTransparency = 1, ZIndex = 5 }, header)
addCorner(logo, 16); addStroke(logo, Theme.Gold, 1.5, 0.2)

new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(54, 6), Size = UDim2.fromOffset(150, 22), Font = Enum.Font.GothamBold, Text = CONFIG.Name, TextSize = 17, TextColor3 = Theme.Neon, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, header)
local closeBtn = new("TextButton", { Position = UDim2.new(1, -40, 0.5, -14), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Card, Text = "X", TextColor3 = Theme.Text, ZIndex = 5 }, header)
addCorner(closeBtn, 8)

local body = new("Frame", { Position = UDim2.fromOffset(0, CONFIG.HeaderHeight), Size = UDim2.new(1, 0, 1, -CONFIG.HeaderHeight), BackgroundTransparency = 1, ZIndex = 4 }, main)
local sidebar = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, CONFIG.SidebarWidth, 1, -16), BackgroundColor3 = Theme.BgDeep, BackgroundTransparency = 0.3, ZIndex = 4 }, body)
addCorner(sidebar, 10)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)

local contentArea = new("Frame", { Position = UDim2.fromOffset(CONFIG.SidebarWidth + 16, 8), Size = UDim2.new(1, -(CONFIG.SidebarWidth + 24), 1, -16), BackgroundTransparency = 1, ZIndex = 4 }, body)
local Pages, currentPage = {}, nil

local function selectPage(name)
	if currentPage == name then return end
	currentPage = name
	for pageName, page in pairs(Pages) do
		local active = (pageName == name)
		tween(page.Button, 0.2, { BackgroundTransparency = active and 0 or 1, TextColor3 = active and Theme.Neon or Theme.SubText })
		page.Frame.Visible = active
	end
end

local function createPage(name)
	local button = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 1, Text = name, TextSize = 14, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(sidebar), ZIndex = 5 }, sidebar)
	addCorner(button, 8); new("UIPadding", { PaddingLeft = UDim.new(0, 14) }, button)
	local frame = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 4 }, contentArea)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	Pages[name] = { Button = button, Frame = frame }
	button.Activated:Connect(function() selectPage(name) end)
	return frame
end

local function createToggle(parent, name, desc, default, cb)
	local row = new("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.Card, Text = "", LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
	addCorner(row, 10)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -80, 0, 18), Font = Enum.Font.GothamMedium, Text = name, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, row)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -80, 0, 14), Font = Enum.Font.Gotham, Text = desc, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, row)
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = default and Theme.Neon or Theme.Off, ZIndex = 6 }, row)
	addCorner(track, 11)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = default and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Text, ZIndex = 7 }, track)
	addCorner(knob, 8)
	local state = default
	row.Activated:Connect(function()
		state = not state
		tween(track, 0.15, { BackgroundColor3 = state and Theme.Neon or Theme.Off })
		tween(knob, 0.2, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
		safeCall(cb, state)
	end)
	return { Set = function(v) if state ~= v then state = v; row:Activated() end end }
end

local function createButton(parent, name, cb)
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Card, Text = name, TextColor3 = Theme.Mint, LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
	addCorner(btn, 10)
	btn.Activated:Connect(function() safeCall(cb) end)
end

------------------------------------------------------------
-- CONTENIDO (CONECTADO AL MÓDULO)
------------------------------------------------------------
local pCombat = createPage("Combat")
createButton(pCombat, "🔥 FLING MASIVO", function()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bv = Instance.new("BodyVelocity", root)
                bv.Velocity = Vector3.new(math.random(-500, 500), 1000, math.random(-500, 500))
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                game:GetService("Debris"):AddItem(bv, 3)
                count = count + 1
            end
        end
    end
end)

local pVisuals = createPage("Visuals")
createToggle(pVisuals, "Invisibilidad", "Desaparece del mapa", false, function(state)
    if InvisConfig then
        InvisConfig.Set(state)
    else
        warn("Módulo de invisibilidad no cargado.")
    end
end)

local pMove = createPage("Movement")
createButton(pMove, "Reset Caracter", function()
    if player.Character then player.Character:BreakJoints() end
end)

selectPage("Combat")
tween(uiScale, 0.5, { Scale = computeScale() }, Enum.EasingStyle.Back)
closeBtn.Activated:Connect(function() screenGui:Destroy() end)
