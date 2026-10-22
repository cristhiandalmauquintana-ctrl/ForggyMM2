--[[
	╔══════════════════════════════════════════════════════════╗
	║  FROGGY HUB v1.2 — Panel de Control de Desarrollo        ║
	║  Tema: Charca de Rana (Frog Pond)                        ║
	╚══════════════════════════════════════════════════════════╝
]]

------------------------------------------------------------
-- 1. SERVICIOS Y CARGADOR DE GITHUB
------------------------------------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "ForggyMM2"
local BRANCH = "main"
local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return "rbxassetid://123456789" end
    local url = BASE_URL .. "logo.png?v=" .. os.time()
    local ok, data = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
        local path = "FroggyHub_Logo.png"
        if pcall(writefile, path, data) then
            local okAsset, asset = pcall(getAsset, path)
            if okAsset and asset and asset ~= "" then return asset end
        end
    end
    return "rbxassetid://123456789"
end

local function loadModule(filename, configKey)
    local url = BASE_URL .. filename .. "?v=" .. os.time()
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(src) ~= "string" or src:sub(1, 3) == "404" then return nil end
    local chunk, err = loadstring(src)
    if type(chunk) ~= "function" then warn("Error en "..filename..": "..tostring(err)) return nil end
    local runOk, runErr = pcall(chunk)
    if not runOk then warn("Error ejecutando "..filename..": "..tostring(runErr)) return nil end
    return (getgenv and getgenv() or _G)[configKey]
end

local LogoId = fetchLogo()
local InvisConfig = loadModule("Invisibility.lua", "FROGGY_INVIS_CONFIG")
local MoveConfig = loadModule("Movement.lua", "FROGGY_MOVE_CONFIG")

------------------------------------------------------------
-- 2. CONFIGURACIÓN Y TEMA
------------------------------------------------------------
local CONFIG = {
	Name = "Froggy Hub",
	Version = "v1.2",
	LogoId = LogoId,
	BaseSize = Vector2.new(560, 360),
	HeaderHeight = 48,
	SidebarWidth = 124,
	NotifyTime = 3,
}

local Theme = {
	BgDeep = Color3.fromRGB(4, 9, 7),
	Bg = Color3.fromRGB(8, 18, 13),
	Swamp = Color3.fromRGB(14, 42, 30),
	Card = Color3.fromRGB(16, 32, 25),
	CardHover = Color3.fromRGB(25, 50, 39),
	Neon = Color3.fromRGB(57, 255, 120),
	Mint = Color3.fromRGB(152, 255, 205),
	Gold = Color3.fromRGB(255, 208, 64),
	Text = Color3.fromRGB(228, 247, 237),
	SubText = Color3.fromRGB(130, 172, 152),
	Off = Color3.fromRGB(42, 62, 52),
	Danger = Color3.fromRGB(255, 95, 95),
}

------------------------------------------------------------
-- 3. UTILIDADES
------------------------------------------------------------
local function new(className, props, parent)
	local inst = Instance.new(className)
	if props then for key, value in pairs(props) do inst[key] = value end end
	if parent then inst.Parent = parent end
	return inst
end
local function tween(inst, duration, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
local function addCorner(parent, radius) return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent) end
local function addStroke(parent, color, thickness, transparency)
	return new("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end
local function safeCall(callback, ...)
	if typeof(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then warn("[Froggy Hub] Error en callback: " .. tostring(err)) end
end
local function bindHover(gui, onEnter, onLeave)
	gui.MouseEnter:Connect(onEnter)
	gui.MouseLeave:Connect(onLeave)
	gui.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then onEnter() end end)
	gui.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then onLeave() end end)
end
local orderCounters = setmetatable({}, { __mode = "k" })
local function nextOrder(parent) orderCounters[parent] = (orderCounters[parent] or 0) + 1; return orderCounters[parent] end
local connections = {}

------------------------------------------------------------
-- 4. SCREENGUI + FONDO ANIMADO (ONDAS Y LUCIÉRNAGAS)
------------------------------------------------------------
local oldGui = playerGui:FindFirstChild("FroggyHub")
if oldGui then oldGui:Destroy() end

local screenGui = new("ScreenGui", { Name = "FroggyHub", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local main = new("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(CONFIG.BaseSize.X, CONFIG.BaseSize.Y), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ClipsDescendants = true }, screenGui)
addCorner(main, 14); addStroke(main, Theme.Neon, 1.5, 0.35)

local uiScale = new("UIScale", { Scale = 0 }, main)
local userScale = 1
local function computeScale()
	local vp = screenGui.AbsoluteSize
	local auto = math.min(vp.X / (CONFIG.BaseSize.X + 40), vp.Y / (CONFIG.BaseSize.Y + 40), 1)
	return math.max(auto, 0.5) * userScale
end
local function defaultPosition() return UDim2.new(0.5, 0, 0.5, -(CONFIG.BaseSize.Y / 2) * computeScale()) end
main.Position = defaultPosition()

local fxEnabled = true
local bgLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 1 }, main)
addCorner(bgLayer, 14)
local bgGradient = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.BgDeep), ColorSequenceKeypoint.new(0.5, Theme.Swamp), ColorSequenceKeypoint.new(1, Theme.BgDeep) }) }, bgLayer)

local waveLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Neon, BorderSizePixel = 0, ZIndex = 2 }, main)
addCorner(waveLayer, 14)
local waveGradient = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.93), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(0.75, 0.93), NumberSequenceKeypoint.new(1, 1) }) }, waveLayer)

local function loopRotation(gradient, duration, goal)
	gradient.Rotation = 0
	local t = TweenService:Create(gradient, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = goal })
	t:Play(); return t
end
local bgTween = loopRotation(bgGradient, 28, 360)
local waveTween = loopRotation(waveGradient, 18, -360)

local fxLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, main)
local function spawnFirefly()
	if not screenGui.Parent or not fxEnabled then return end
	local size = math.random(3, 6); local x = math.random(); local duration = math.random(70, 120) / 10
	local fly = new("Frame", { Size = UDim2.fromOffset(size, size), Position = UDim2.new(x, 0, 1, 12), BackgroundColor3 = (math.random() < 0.5) and Theme.Gold or Theme.Mint, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, fxLayer)
	addCorner(fly, size); addStroke(fly, fly.BackgroundColor3, 2, 0.8)
	tween(fly, 1, { BackgroundTransparency = 0.25 })
	local move = tween(fly, duration, { Position = UDim2.new(x, math.random(-50, 50), 0, -12) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	task.spawn(function() move.Completed:Wait(); fly:Destroy(); spawnFirefly() end)
end
for _ = 1, 14 do task.delay(math.random() * 6, spawnFirefly) end
local function setFxEnabled(enabled)
	fxEnabled = enabled; fxLayer.Visible = enabled; waveLayer.Visible = enabled
	if enabled then bgTween:Play(); waveTween:Play() else bgTween:Pause(); waveTween:Pause() end
end

------------------------------------------------------------
-- 5. NOTIFICACIONES
------------------------------------------------------------
local notificationsEnabled = true
local notifyCounter = 0
local notifyHolder = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(270, 400), BackgroundTransparency = 1, ZIndex = 50 }, screenGui)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }, notifyHolder)
local function Notify(title, text)
	if not notificationsEnabled then return end
	notifyCounter += 1
	local wrapper = new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, LayoutOrder = notifyCounter, ZIndex = 50 }, notifyHolder)
	local card = new("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.new(1, 300, 0, 0), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 51 }, wrapper)
	addCorner(card, 10); addStroke(card, Theme.Neon, 1.2, 0.3)
	new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 4, 1, -16), BackgroundColor3 = Theme.Gold, BorderSizePixel = 0, ZIndex = 52 }, card)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 7), Size = UDim2.new(1, -32, 0, 18), Font = Enum.Font.GothamBold, Text = tostring(title or "Froggy Hub"), TextSize = 14, TextColor3 = Theme.Mint, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 52 }, card)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 26), Size = UDim2.new(1, -32, 0, 28), Font = Enum.Font.Gotham, Text = tostring(text or ""), TextSize = 12, TextColor3 = Theme.Text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 52 }, card)
	local progress = new("Frame", { Position = UDim2.new(0, 10, 1, -6), Size = UDim2.new(1, -20, 0, 2), BackgroundColor3 = Theme.Gold, BorderSizePixel = 0, ZIndex = 52 }, card)
	task.spawn(function()
		tween(card, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(progress, CONFIG.NotifyTime + 0.4, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
		task.wait(0.4 + CONFIG.NotifyTime)
		local out = tween(card, 0.4, { Position = UDim2.new(1, 300, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		out.Completed:Wait(); wrapper:Destroy()
	end)
end

------------------------------------------------------------
-- 6. CABECERA
------------------------------------------------------------
local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, CONFIG.HeaderHeight), BackgroundColor3 = Theme.BgDeep, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 4 }, main)
new("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Neon, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 4 }, header)
local logo = new("ImageLabel", { Name = "Logo", Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Swamp, BorderSizePixel = 0, Image = CONFIG.LogoId, ScaleType = Enum.ScaleType.Fit, ZIndex = 5 }, header)
addCorner(logo, 16); addStroke(logo, Theme.Gold, 1.5, 0.2)
new("TextLabel", { Name = "Title", BackgroundTransparency = 1, Position = UDim2.fromOffset(54, 6), Size = UDim2.fromOffset(150, 22), Font = Enum.Font.GothamBold, Text = CONFIG.Name, TextSize = 17, TextColor3 = Theme.Neon, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, header)
new("TextLabel", { Name = "Version", BackgroundTransparency = 1, Position = UDim2.fromOffset(54, 27), Size = UDim2.fromOffset(100, 14), Font = Enum.Font.GothamMedium, Text = CONFIG.Version, TextSize = 11, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, header)

local function createHeaderButton(text, xOffset, hoverColor)
	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOffset, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Card, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = text, TextSize = 16, TextColor3 = Theme.Text, ZIndex = 5 }, header)
	addCorner(btn, 8); local stroke = addStroke(btn, Theme.Neon, 1, 0.8)
	bindHover(btn, function() tween(btn, 0.15, { BackgroundColor3 = hoverColor }); tween(stroke, 0.15, { Transparency = 0.3 }) end, function() tween(btn, 0.15, { BackgroundColor3 = Theme.Card }); tween(stroke, 0.15, { Transparency = 0.8 }) end)
	return btn
end
local closeBtn = createHeaderButton("×", -10, Theme.Danger)
local minimizeBtn = createHeaderButton("–", -44, Theme.Swamp)

do -- Arrastre multi-touch
	local dragging, dragInput, dragStart, startPos = false, nil, Vector3.zero, main.Position
	header.InputBegan:Connect(function(input)
		if dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragInput = input; dragStart = input.Position; startPos = main.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragInput then return end
		if (input == dragInput) or (input.UserInputType == Enum.UserInputType.MouseMovement and dragInput.UserInputType == Enum.UserInputType.MouseButton1) then
			local delta = input.Position - dragStart
			tween(main, 0.06, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) })
		end
	end))
end

------------------------------------------------------------
-- 7. CUERPO: PÁGINAS
------------------------------------------------------------
local body = new("Frame", { Name = "Body", Position = UDim2.fromOffset(0, CONFIG.HeaderHeight), Size = UDim2.new(1, 0, 1, -CONFIG.HeaderHeight), BackgroundTransparency = 1, ZIndex = 4 }, main)
local sidebar = new("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, CONFIG.SidebarWidth, 1, -16), BackgroundColor3 = Theme.BgDeep, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 4 }, body)
addCorner(sidebar, 10); addStroke(sidebar, Theme.Neon, 1, 0.88)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)

local contentArea = new("Frame", { Name = "Content", Position = UDim2.fromOffset(CONFIG.SidebarWidth + 16, 8), Size = UDim2.new(1, -(CONFIG.SidebarWidth + 24), 1, -16), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 4 }, body)
local Pages, currentPage = {}, nil

local function selectPage(name)
	if currentPage == name then return end
	currentPage = name
	for pageName, page in pairs(Pages) do
		local active = (pageName == name)
		tween(page.Button, 0.2, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = Theme.CardHover })
		tween(page.Button, 0.2, { TextColor3 = active and Theme.Neon or Theme.SubText })
		tween(page.Indicator, 0.25, { Size = UDim2.new(0, 3, 0, active and 20 or 0) }, Enum.EasingStyle.Back)
		if active then
			page.Frame.Position = UDim2.fromOffset(0, 14); page.Frame.Visible = true
			tween(page.Frame, 0.25, { Position = UDim2.fromOffset(0, 0) })
		else
			page.Frame.Visible = false
		end
	end
end

local function createPage(name)
	local button = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 1, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = name, TextSize = 14, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(sidebar), ZIndex = 5 }, sidebar)
	addCorner(button, 8); new("UIPadding", { PaddingLeft = UDim.new(0, 14) }, button)
	local indicator = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -11, 0.5, 0), Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = Theme.Neon, BorderSizePixel = 0, ZIndex = 6 }, button)
	addCorner(indicator, 2)
	local frame = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Neon, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 4 }, contentArea)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, frame)
	Pages[name] = { Button = button, Frame = frame, Indicator = indicator }
	button.Activated:Connect(function() selectPage(name) end)
	bindHover(button, function() if currentPage ~= name then tween(button, 0.15, { BackgroundTransparency = 0.55 }) end end, function() if currentPage ~= name then tween(button, 0.15, { BackgroundTransparency = 1 }) end end)
	return frame
end

local function createSection(parent, text)
	return new("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = string.upper(text), TextSize = 11, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
end

local function createToggle(parent, name, description, defaultState, onChangeCallback)
	local hasDesc = (type(description) == "string" and description ~= "")
	local state = (defaultState == true)
	local row = new("TextButton", { Size = UDim2.new(1, 0, 0, hasDesc and 54 or 42), BackgroundColor3 = Theme.Card, AutoButtonColor = false, Text = "", LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
	addCorner(row, 10); local stroke = addStroke(row, Theme.Neon, 1, 0.85)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, hasDesc and 8 or 0), Size = UDim2.new(1, -86, 0, hasDesc and 18 or 42), Font = Enum.Font.GothamMedium, Text = name, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, row)
	if hasDesc then new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -86, 0, 16), Font = Enum.Font.Gotham, Text = description, TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6 }, row) end
	local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(46, 24), BackgroundColor3 = state and Theme.Neon or Theme.Off, BorderSizePixel = 0, ZIndex = 6 }, row)
	addCorner(track, 12)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 7 }, track)
	addCorner(knob, 9)
	local function setState(value, silent)
		state = value
		tween(track, 0.2, { BackgroundColor3 = state and Theme.Neon or Theme.Off })
		tween(knob, 0.25, { Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, Enum.EasingStyle.Back)
		if not silent then safeCall(onChangeCallback, state) end
	end
	row.Activated:Connect(function() setState(not state) end)
	return { Frame = row, Set = function(v, s) setState(v == true, s) end, Get = function() return state end }
end

local function createSlider(parent, name, min, max, default, step, onChangeCallback)
	local decimals = #(tostring(step):match("%.(%d+)") or "")
	local value = default
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Theme.Card, LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
	addCorner(row, 10); addStroke(row, Theme.Neon, 1, 0.85)
	new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -96, 0, 18), Font = Enum.Font.GothamMedium, Text = name, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, row)
	local valueLabel = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(80, 18), Font = Enum.Font.GothamBold, Text = "", TextSize = 14, TextColor3 = Theme.Gold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 }, row)
	local hit = new("TextButton", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 24), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 6 }, row)
	local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Theme.Off, BorderSizePixel = 0, ZIndex = 6 }, hit)
	addCorner(track, 3)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Neon, BorderSizePixel = 0, ZIndex = 7 }, track)
	addCorner(fill, 3); new("UIGradient", { Color = ColorSequence.new(Theme.Mint, Theme.Neon) }, fill)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 8 }, track)
	addCorner(knob, 8); addStroke(knob, Theme.Gold, 2, 0.2)
	local function render(animate)
		local alpha = (value - min) / (max - min); valueLabel.Text = string.format("%." .. decimals .. "f", value)
		if animate then tween(fill, 0.08, { Size = UDim2.fromScale(alpha, 1) }); tween(knob, 0.08, { Position = UDim2.fromScale(alpha, 0.5) })
		else fill.Size = UDim2.fromScale(alpha, 1); knob.Position = UDim2.fromScale(alpha, 0.5) end
	end
	local function setValue(raw, silent)
		local snapped = min + math.floor((raw - min) / step + 0.5) * step; snapped = math.clamp(snapped, min, max)
		snapped = tonumber(string.format("%." .. decimals .. "f", snapped)) or snapped
		if snapped == value then return end
		value = snapped; render(true); if not silent then safeCall(onChangeCallback, value) end
	end
	local function updateFromX(x) local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1); setValue(min + alpha * (max - min)) end
	local scroller = parent:IsA("ScrollingFrame") and parent or nil
	local dragging, activeInput = false, nil
	hit.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; activeInput = input; if scroller then scroller.ScrollingEnabled = false end; updateFromX(input.Position.X) end end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input) if dragging and activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseMovement) then updateFromX(input.Position.X) end end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input) if dragging and activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1) then dragging = false; activeInput = nil; if scroller then scroller.ScrollingEnabled = true end end end))
	render(false)
	return { Frame = row, Set = function(v, s) setValue(v, s) end, Get = function() return value end }
end

local function createButton(parent, name, onClickCallback)
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Card, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = name, TextSize = 14, TextColor3 = Theme.Mint, LayoutOrder = nextOrder(parent), ZIndex = 5 }, parent)
	addCorner(btn, 10); addStroke(btn, Theme.Neon, 1, 0.6)
	bindHover(btn, function() tween(btn, 0.15, { BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.Neon }) end, function() tween(btn, 0.15, { BackgroundColor3 = Theme.Card, TextColor3 = Theme.Mint }) end)
	btn.Activated:Connect(function() safeCall(onClickCallback) end)
	return { Frame = btn }
end

------------------------------------------------------------
-- 8. CONTENIDO DE LAS PÁGINAS
------------------------------------------------------------
local combatPage = createPage("Combat")
createSection(combatPage, "Caos Masivo")
createButton(combatPage, "🔥 FLING MASIVO", function()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(math.random(-500, 500), 1000, math.random(-500, 500))
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = root
                game:GetService("Debris"):AddItem(bv, 3)
                count = count + 1
            end
        end
    end
    Notify("Caos", count .. " jugadores enviados al cielo.")
end)

local visualsPage = createPage("Visuals")
createSection(visualsPage, "Invisibilidad")
createToggle(visualsPage, "Invisibilidad Real", "Invisible para otros (Desync)", false, function(enabled)
    if InvisConfig then
        InvisConfig.Set(enabled)
        Notify("Invisibilidad", enabled and "Activada" or "Desactivada")
    else
        Notify("Error", "Módulo no cargado.")
    end
end)

local movementPage = createPage("Movement")
createSection(movementPage, "Ajustes de Movimiento")
createToggle(movementPage, "Activar Movimiento", "Habilita los sliders de abajo", false, function(enabled)
    if MoveConfig then
        MoveConfig.Enabled = enabled
        Notify("Movimiento", enabled and "Activado" or "Desactivado")
    end
end)

createSlider(movementPage, "Walk Speed", 16, 200, 16, 1, function(value)
    if MoveConfig then
        MoveConfig.WalkSpeed = value
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and MoveConfig.Enabled then hum.WalkSpeed = value end
    end
end)

createSlider(movementPage, "Jump Power", 50, 300, 50, 5, function(value)
    if MoveConfig then
        MoveConfig.JumpPower = value
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and MoveConfig.Enabled then hum.JumpPower = value end
    end
end)

createSection(movementPage, "Vuelo")
local isFlying = false
local flyVel, flyGyro, flyConn
createToggle(movementPage, "Fly (Volar)", "Vuela por el mapa", false, function(enabled)
    isFlying = enabled
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if enabled then
        flyVel = Instance.new("BodyVelocity", hrp)
        flyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyVel.Velocity = Vector3.new(0,0,0)
        flyGyro = Instance.new("BodyGyro", hrp)
        flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyGyro.P = 1000
        
        flyConn = RunService.Heartbeat:Connect(function()
            if not isFlying or not flyVel or not flyVel.Parent then return end
            local cam = workspace.CurrentCamera
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local moveDir = hum and hum.MoveDirection or Vector3.new(0,0,0)
            flyVel.Velocity = moveDir * 100 + Vector3.new(0, 20, 0)
            flyGyro.CFrame = cam.CFrame
        end)
        Notify("Vuelo", "Activado")
    else
        if flyVel then flyVel:Destroy() end
        if flyGyro then flyGyro:Destroy() end
        if flyConn then flyConn:Disconnect() end
        Notify("Vuelo", "Desactivado")
    end
end)

local settingsPage = createPage("Settings")
createSection(settingsPage, "Interfaz")
createToggle(settingsPage, "Notificaciones", "Avisos abajo a la derecha", true, function(enabled) notificationsEnabled = enabled end)
createToggle(settingsPage, "Efectos de Fondo", "Ondas y luciérnagas", true, function(enabled) setFxEnabled(enabled) end)
createSlider(settingsPage, "UI Scale", 0.7, 1.3, 1, 0.05, function(value) userScale = value; tween(uiScale, 0.15, { Scale = computeScale() }) end)
createButton(settingsPage, "Reset Position", function() tween(main, 0.4, { Position = defaultPosition() }) end)

------------------------------------------------------------
-- 9. MINIMIZAR / CERRAR / ATAJOS
------------------------------------------------------------
local minimized, closing = false, false
local function setMinimized(value)
	minimized = value
	minimizeBtn.Text = minimized and "+" or "–"
	if minimized then
		local t = tween(main, 0.3, { Size = UDim2.fromOffset(CONFIG.BaseSize.X, CONFIG.HeaderHeight) }, Enum.EasingStyle.Quint)
		t.Completed:Connect(function() if minimized then body.Visible = false end end)
	else
		body.Visible = true
		tween(main, 0.3, { Size = UDim2.fromOffset(CONFIG.BaseSize.X, CONFIG.BaseSize.Y) }, Enum.EasingStyle.Quint)
	end
end
minimizeBtn.Activated:Connect(function() setMinimized(not minimized) end)
closeBtn.Activated:Connect(function()
	if closing then return end
	closing = true; fxEnabled = false
	local t = tween(uiScale, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	t.Completed:Wait(); screenGui:Destroy()
end)

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if not closing then tween(uiScale, 0.2, { Scale = computeScale() }) end end)
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed) if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end end))
screenGui.Destroying:Connect(function() fxEnabled = false; for _, connection in ipairs(connections) do connection:Disconnect() end end)

------------------------------------------------------------
-- 10. ANIMACIÓN DE ENTRADA
------------------------------------------------------------
selectPage("Combat")
tween(uiScale, 0.5, { Scale = computeScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
task.delay(0.6, function() Notify("Froggy Hub " .. CONFIG.Version, "Panel cargado. ¡Listo para el caos!") end)
