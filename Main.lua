--// FroggyHub MM2 | Clean Slate - v3.0 (Auto-Win Edition)

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "ForggyMM2"
local BRANCH = "main"
local HUB_VERSION = "v3.0"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local ESP_FILES = { "ESP.lua" }
local MOVE_FILES = { "Movement.lua" }
local TP_FILES = { "Teleport.lua" }
local AUTOWIN_FILES = { "AutoWin.lua" }
local LOGO_FILES = { "logo.png", "Logo.png" }

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if env.__MM2_PANEL_CLEANUP then pcall(env.__MM2_PANEL_CLEANUP) end

local function downloadModule(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then return res end
    end
    return nil
end

local function loadModule(names, configKey)
    local src = downloadModule(names)
    if not src then warn("[FroggyHub] No se pudo descargar: " .. configKey); return nil end
    local chunk, err = loadstring(src)
    if not chunk then warn("[FroggyHub] Error de sintaxis en " .. configKey .. ": " .. tostring(err)); return nil end
    local ok, runErr = pcall(chunk)
    if not ok then warn("[FroggyHub] Error ejecutando " .. configKey .. ": " .. tostring(runErr)); return nil end
    return env[configKey]
end

local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    for _, name in ipairs(LOGO_FILES) do
        local ok, data = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_logo.png"
            if pcall(writefile, path, data) then local okAsset, asset = pcall(getAsset, path); if okAsset and asset and asset ~= "" then return asset end end
        end
    end
    return nil
end

local logoAsset = fetchLogo()

local Themes = {
    Zafiro = {
        Void = Color3.fromRGB(5, 7, 22), Bg = Color3.fromRGB(9, 12, 36), BgA = Color3.fromRGB(14, 18, 54),
        BgB = Color3.fromRGB(28, 14, 62), Row = Color3.fromRGB(16, 21, 58), Sapphire = Color3.fromRGB(46, 92, 255),
        Violet = Color3.fromRGB(139, 82, 255), Cyan = Color3.fromRGB(92, 200, 255), Text = Color3.fromRGB(232, 238, 255),
        Dim = Color3.fromRGB(130, 145, 200), Off = Color3.fromRGB(30, 36, 86),
    },
}
local C = Themes.Zafiro

local function tw(obj, t, props, style, dir) local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props); tween:Play(); return tween end
local function make(class, props, parent) local o = Instance.new(class); for k, v in pairs(props) do o[k] = v end; if parent then o.Parent = parent end; return o end
local function corner(obj, r) return make("UICorner", { CornerRadius = UDim.new(0, r) }, obj) end
local function gradient(obj, c1, c2, rot) return make("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 0 }, obj) end

local conns = {}
local function track(c) conns[#conns + 1] = c return c end
local activeTouch = nil

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
local gui = make("ScreenGui", { Name = "FroggyHub_MM2", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parentGui)

local Config, MoveConfig, TPConfig, AutoWinConfig
local ready = false

local WIN_W, WIN_H = 580, 340
local main = make("Frame", { Name = "Main", Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Bg, ClipsDescendants = true, Visible = false, Active = false }, gui)
corner(main, 16)
local mainScale = make("UIScale", { Scale = 0.5 }, main)
local bgGrad = gradient(main, C.BgA, C.BgB, 45)
local stroke = make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.1 }, main)
local strokeGrad = make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Sapphire), ColorSequenceKeypoint.new(0.5, C.Violet), ColorSequenceKeypoint.new(1, C.Cyan) }) }, stroke)

local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, ZIndex = 10 }, main)
local brand = make("Frame", { Position = UDim2.fromOffset(20, 8), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 11 }, header)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, brand)

local title = make("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "FroggyHub", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 11 }, brand)
make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Cyan), ColorSequenceKeypoint.new(0.5, C.Violet), ColorSequenceKeypoint.new(1, C.Cyan) }) }, title)

local pill = make("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(46, 20), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 11 }, brand)
corner(pill, 10); gradient(pill, C.Sapphire, C.Violet, 0)
make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "MM2", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 12, ZIndex = 12 }, pill)

local versionBadge = make("TextLabel", { LayoutOrder = 3, Size = UDim2.fromOffset(36, 16), BackgroundColor3 = C.Cyan, BackgroundTransparency = 0.8, Text = HUB_VERSION, TextColor3 = C.Cyan, Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 11 }, brand)
corner(versionBadge, 6)

local function headerButton(text, xOff, color)
    local b = make("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, xOff, 0, 13), BackgroundColor3 = C.Row, BackgroundTransparency = 0.2, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, ZIndex = 12 }, header)
    corner(b, 8)
    b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = color, BackgroundTransparency = 0 }) end)
    b.MouseLeave:Connect(function() tw(b, 0.2, { BackgroundColor3 = C.Row, BackgroundTransparency = 0.2 }) end)
    return b
end
local closeBtn = headerButton("✕", -38, Color3.fromRGB(220, 60, 90))
local hideBtn = headerButton("–", -70, C.Sapphire)

local TABS = {
    { id = "main",     name = "Auto-Win",  live = true },
    { id = "visual",   name = "Visual",    live = true },
    { id = "player",   name = "Movimiento",live = true },
    { id = "tp",       name = "Teleport",  live = true },
    { id = "settings", name = "Ajustes",   desc = "Cambia el tema y personaliza la interfaz.", settings = true },
}
local TAB_H = 34
local SIDE_H = 250
local function tabY(i) return TABS[i].settings and (SIDE_H - TAB_H) or ((i - 1) * 35) end

local side = make("CanvasGroup", { Name = "Sidebar", Position = UDim2.fromOffset(14, 68), Size = UDim2.fromOffset(132, SIDE_H), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 10 }, main)
local indicator = make("Frame", { Size = UDim2.new(1, 0, 0, TAB_H), Position = UDim2.fromOffset(0, tabY(1)), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, ZIndex = 10 }, side)
corner(indicator, 10); gradient(indicator, C.Sapphire, C.Violet, 0)

local tabButtons = {}
for i, tab in ipairs(TABS) do
    local b = make("TextButton", { Size = UDim2.new(1, 0, 0, TAB_H), Position = UDim2.fromOffset(0, tabY(i)), BackgroundTransparency = 1, Text = tab.name, TextColor3 = (i == 1) and C.Text or C.Dim, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 11 }, side)
    make("UIPadding", { PaddingLeft = UDim.new(0, 14) }, b)
    tabButtons[i] = b
end

local content = make("Frame", { Name = "Content", Position = UDim2.fromOffset(162, 68), Size = UDim2.fromOffset(404, SIDE_H), BackgroundTransparency = 1, ZIndex = 10 }, main)

local function newPage()
    local page = make("ScrollingFrame", { 
        Size = UDim2.fromScale(1, 1), 
        BackgroundTransparency = 1, 
        BorderSizePixel = 0, 
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false, 
        ZIndex = 10,
        Active = false
    }, content)
    make("UIPadding", { PaddingBottom = UDim.new(0, 10), PaddingRight = UDim.new(0, 4) }, page)
    make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    return page
end

local function createToggleCard(parent, name, desc, version, get, set, available)
    local card = make("Frame", { BackgroundColor3 = C.Row, BackgroundTransparency = 0.15, Size = UDim2.new(1, 0, 0, 96), ZIndex = 10 }, parent)
    corner(card, 14)
    local cs = make("UIStroke", { Color = C.Sapphire, Transparency = 0.6, Thickness = 1 }, card)
    local btn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 11 }, card)
    
    make("TextLabel", { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, Text = name, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, btn)
    local descText = available and (desc .. (version and ("  |  " .. version) or "")) or "módulo no cargado"
    make("TextLabel", { Size = UDim2.new(1, -28, 0, 28), Position = UDim2.fromOffset(14, 34), BackgroundTransparency = 1, Text = descText, TextColor3 = available and C.Dim or Color3.fromRGB(220, 90, 110), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 12 }, btn)
    
    local state = make("TextLabel", { Size = UDim2.fromOffset(60, 16), Position = UDim2.fromOffset(14, 70), BackgroundTransparency = 1, Text = "OFF", TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, btn)
    local sw = make("Frame", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -60, 0, 66), BackgroundColor3 = C.Off, ZIndex = 12 }, btn)
    corner(sw, 12)
    local swGrad = gradient(sw, C.Sapphire, C.Violet, 0)
    swGrad.Enabled = false
    local knob = make("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.Dim, ZIndex = 13 }, sw)
    corner(knob, 9)

    local function render()
        local on = available and get() and true or false
        swGrad.Enabled = on
        state.Text = on and "ON" or "OFF"
        tw(state, 0.25, { TextColor3 = on and C.Cyan or C.Dim })
        tw(sw, 0.25, { BackgroundColor3 = on and Color3.new(1, 1, 1) or C.Off })
        tw(knob, 0.3, { Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = on and Color3.new(1, 1, 1) or C.Dim }, Enum.EasingStyle.Back)
        tw(cs, 0.3, { Color = on and C.Cyan or C.Sapphire, Transparency = on and 0.1 or 0.6 })
    end

    if available then
        btn.MouseButton1Click:Connect(function() set(not get()) render() end)
    end
    render()
    return card
end

local pages = {}
for i, tab in ipairs(TABS) do pages[i] = newPage() end

local current = 1
local function selectTab(i)
    if i == current or not ready then return end
    local old = pages[current]; current = i
    tw(indicator, 0.4, { Position = UDim2.fromOffset(0, tabY(i)) })
    for k, b in ipairs(tabButtons) do tw(b, 0.25, { TextColor3 = (k == i) and C.Text or C.Dim }) end
    old.Visible = false
    local new = pages[i]; new.Visible = true
end
for i, b in ipairs(tabButtons) do b.MouseButton1Click:Connect(function() selectTab(i) end) end

local function makeDraggable(handle, getPos, setPos, onTap)
    local dragging, dragStart, startPos, moved
    track(handle.InputBegan:Connect(function(input)
        if activeTouch then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeTouch = input
            dragging = true; dragStart = input.Position; startPos = getPos(); moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeTouch = nil
                    if not moved and onTap then onTap() end
                    conn:Disconnect()
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging or activeTouch ~= input then return end
        local d = input.Position - dragStart
        if d.Magnitude > 5 then moved = true end
        if moved then setPos(startPos.X + d.X, startPos.Y + d.Y) end
    end))
end

makeDraggable(header, function() return Vector2.new(main.AbsolutePosition.X, main.AbsolutePosition.Y) end, function(x, y) main.Position = UDim2.fromOffset(x, y) end)

local BUBBLE_SIZE = 46
local bubble = make("TextButton", { Size = UDim2.fromOffset(BUBBLE_SIZE, BUBBLE_SIZE), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Row, Text = "", Visible = false, AutoButtonColor = false, ZIndex = 100 }, gui)
corner(bubble, BUBBLE_SIZE / 2)
local bubbleStroke = make("UIStroke", { Thickness = 2, Color = C.Sapphire }, bubble)
gradient(bubble, C.BgA, C.BgB, 45)

if logoAsset then
    make("ImageLabel", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = logoAsset, ScaleType = Enum.ScaleType.Fit }, bubble)
else
    make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F", TextColor3 = C.Cyan, Font = Enum.Font.GothamBlack, TextSize = 22 }, bubble)
end

local shown = true
local function setShown(v)
    if not ready or shown == v then return end
    shown = v
    if v then
        bubble.Visible = false; main.Visible = true
        tw(mainScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
    else
        local t = tw(mainScale, 0.3, { Scale = 0.01 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Once(function() 
            if not shown then 
                main.Visible = false; bubble.Visible = true; 
                bubble.Position = UDim2.fromOffset(main.AbsolutePosition.X, main.AbsolutePosition.Y)
            end 
        end)
    end
end

makeDraggable(bubble, function() return Vector2.new(bubble.AbsolutePosition.X, bubble.AbsolutePosition.Y) end, function(x, y) bubble.Position = UDim2.fromOffset(x, y) end, function() setShown(true) end)
hideBtn.MouseButton1Click:Connect(function() setShown(false) end)

env.__MM2_PANEL_CLEANUP = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    if env.__MM2_ESP_CLEANUP then pcall(env.__MM2_ESP_CLEANUP) end
    if env.__MM2_MOVE_CLEANUP then pcall(env.__MM2_MOVE_CLEANUP) end
    if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end
    if env.__MM2_AUTOWIN_CLEANUP then pcall(env.__MM2_AUTOWIN_CLEANUP) end
    gui:Destroy(); env.__MM2_PANEL_CLEANUP = nil
end
closeBtn.MouseButton1Click:Connect(function() env.__MM2_PANEL_CLEANUP() end)

task.spawn(function()
    task.wait(2)
    main.Visible = true
    tw(mainScale, 0.7, { Scale = 1 }, Enum.EasingStyle.Back)
    tw(side, 0.5, { GroupTransparency = 0 })

    Config = loadModule(ESP_FILES, "MM2_ESP_CONFIG")
    MoveConfig = loadModule(MOVE_FILES, "MM2_MOVE_CONFIG")
    TPConfig = loadModule(TP_FILES, "MM2_TP_CONFIG")
    AutoWinConfig = loadModule(AUTOWIN_FILES, "MM2_AUTOWIN_CONFIG")

    -- PESTAÑA 1: AUTO-WIN
    if AutoWinConfig then
        createToggleCard(pages[1], "Activar Auto-Win", "Gana la partida automáticamente.", AutoWinConfig.Version, function() return AutoWinConfig.Enabled end, function(v) AutoWinConfig.Enabled = v end, true)
    else
        createSoonCard(pages[1], "Auto-Win (No cargado)")
    end

    -- PESTAÑA 2: VISUAL (ESP)
    createToggleCard(pages[2], "ESP General", "Activa el ESP.", Config and Config.Version, function() return Config and Config.Enabled end, function(v) Config.Enabled = v end, Config ~= nil)
    if Config then
        createToggleCard(pages[2], "Cajas 2D", "Cajas en el enemigo.", nil, function() return Config.Boxes end, function(v) Config.Boxes = v end, true)
        createToggleCard(pages[2], "Nombres y Roles", "Muestra Asesino/Sheriff.", nil, function() return Config.Names end, function(v) Config.Names = v end, true)
    end

    -- PESTAÑA 3: MOVIMIENTO
    if MoveConfig then
        createToggleCard(pages[3], "Velocidad", "Aumenta la velocidad.", MoveConfig.Version, function() return MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end, true)
        createToggleCard(pages[3], "Salto Alto", "Aumenta el salto.", MoveConfig.Version, function() return MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end, true)
    end

    -- PESTAÑA 4: TELEPORT
    if TPConfig then
        createToggleCard(pages[4], "TP a Jugador", "Va al jugador más cercano.", TPConfig.Version, function() return TPConfig.TpPlayer end, function(v) TPConfig.TpPlayer = v end, true)
        createToggleCard(pages[4], "TP a Moneda", "Busca monedas y teletransporta.", TPConfig.Version, function() return TPConfig.TpCoin end, function(v) TPConfig.TpCoin = v end, true)
    end

    pages[1].Visible = true
    ready = true
end)
