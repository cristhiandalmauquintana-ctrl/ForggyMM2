--// FroggyHub MM2 | Sapphire Edition - FIXED

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "ForggyMM2"
local BRANCH = "main"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local ESP_FILES = { "ESP.lua" }
local GODMODE_FILES = { "GodMode.lua" }
local MOVE_FILES = { "Movement.lua" }
local TP_FILES = { "Teleport.lua" }

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if env.__MM2_PANEL_CLEANUP then pcall(env.__MM2_PANEL_CLEANUP) end

-- LÓGICA DE DESCARGA
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
    local chunk = loadstring(src)
    if not chunk then return nil end
    local ok, runErr = pcall(chunk)
    if not ok then warn("Error cargando modulo: " .. tostring(runErr)) return nil end
    return env[configKey]
end

-- TEMAS
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

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
local gui = make("ScreenGui", { Name = "FroggyHub_MM2", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parentGui)

local Config, GodConfig, MoveConfig, TPConfig
local ready = false

-- VENTANA
local WIN_W, WIN_H = 580, 340
local main = make("Frame", { Name = "Main", Size = UDim2.fromOffset(WIN_W, WIN_H), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Bg, ClipsDescendants = true, Visible = false }, gui)
corner(main, 16)
local mainScale = make("UIScale", { Scale = 0.5 }, main)
local bgGrad = gradient(main, C.BgA, C.BgB, 45)
local stroke = make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.1 }, main)
local strokeGrad = make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Sapphire), ColorSequenceKeypoint.new(0.5, C.Violet), ColorSequenceKeypoint.new(1, C.Cyan) }) }, stroke)

-- Header
local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, ZIndex = 10 }, main)
local brand = make("Frame", { Position = UDim2.fromOffset(20, 8), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 11 }, header)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, brand)

local title = make("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "FroggyHub", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 11 }, brand)
make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Cyan), ColorSequenceKeypoint.new(0.5, C.Violet), ColorSequenceKeypoint.new(1, C.Cyan) }) }, title)

local pill = make("Frame", { LayoutOrder = 2, Size = UDim2.fromOffset(46, 20), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 11 }, brand)
corner(pill, 10); gradient(pill, C.Sapphire, C.Violet, 0)
make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "MM2", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 12, ZIndex = 12 }, pill)

local function headerButton(text, xOff, color)
    local b = make("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, xOff, 0, 13), BackgroundColor3 = C.Row, BackgroundTransparency = 0.2, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, ZIndex = 12 }, header)
    corner(b, 8)
    b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = color, BackgroundTransparency = 0 }) end)
    b.MouseLeave:Connect(function() tw(b, 0.2, { BackgroundColor3 = C.Row, BackgroundTransparency = 0.2 }) end)
    return b
end
local closeBtn = headerButton("✕", -38, Color3.fromRGB(220, 60, 90))
local hideBtn = headerButton("–", -70, C.Sapphire)

-- TABS
local TABS = {
    { id = "main",     name = "Principal", live = true },
    { id = "visual",   name = "Visual",    live = true },
    { id = "player",   name = "Jugador",   live = true },
    { id = "tp",       name = "Teleport",  live = true },
    { id = "settings", name = "Ajustes",   desc = "Cambia el tema y personaliza la interfaz.", settings = true },
}
local TAB_H = 34
local SIDE_H = 250
local function tabY(i) return TABS[i].settings and (SIDE_H - TAB_H) or ((i - 1) * 40) end

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
    return make("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 0, Visible = false, ZIndex = 10 }, content)
end

local mainCards = {}
local function createToggleCard(parent, name, desc, get, set, available)
    -- AQUÍ ESTÁ EL FIX: GroupTransparency = 0 en lugar de 1
    local card = make("CanvasGroup", { BackgroundColor3 = C.Row, BackgroundTransparency = 0.15, GroupTransparency = 0, ZIndex = 10 }, parent)
    corner(card, 14)
    local cs = make("UIStroke", { Color = C.Sapphire, Transparency = 0.6, Thickness = 1 }, card)
    local btn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 11 }, card)
    
    make("TextLabel", { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, Text = name, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, btn)
    make("TextLabel", { Size = UDim2.new(1, -28, 0, 28), Position = UDim2.fromOffset(14, 34), BackgroundTransparency = 1, Text = available and desc or "módulo no cargado", TextColor3 = available and C.Dim or Color3.fromRGB(220, 90, 110), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 12 }, btn)
    
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
        btn.MouseEnter:Connect(function() tw(card, 0.2, { BackgroundTransparency = 0 }) end)
        btn.MouseLeave:Connect(function() tw(card, 0.2, { BackgroundTransparency = 0.15 }) end)
    end
    render()
    mainCards[#mainCards + 1] = card
    return card
end

local function createSoonCard(parent, label)
    -- AQUÍ ESTÁ EL FIX: GroupTransparency = 0
    local card = make("CanvasGroup", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, GroupTransparency = 0, ZIndex = 10 }, parent)
    corner(card, 14)
    make("UIStroke", { Color = C.Violet, Transparency = 0.65, Thickness = 1 }, card)
    make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Row), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 24, 92)), ColorSequenceKeypoint.new(1, C.Row) }), Rotation = 20 }, card)
    make("TextLabel", { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 12), BackgroundTransparency = 1, Text = label, TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 }, card)
    local badge = make("TextLabel", { Size = UDim2.fromOffset(96, 18), Position = UDim2.fromOffset(14, 62), BackgroundColor3 = C.Violet, BackgroundTransparency = 0.7, Text = "PRÓXIMAMENTE", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, ZIndex = 12 }, card)
    corner(badge, 9)
    mainCards[#mainCards + 1] = card
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
    tw(old, 0.15, { GroupTransparency = 1 })
    task.delay(0.16, function() if pages[current] ~= old then old.Visible = false end end)
    local new = pages[i]; new.Position = UDim2.fromOffset(14, 0); new.GroupTransparency = 1; new.Visible = true
    tw(new, 0.35, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
end
for i, b in ipairs(tabButtons) do b.MouseButton1Click:Connect(function() selectTab(i) end) end

-- Arrastrar ventana
do
    local dragging, dragStart, startPos
    track(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
end

local shown = true
local function setShown(v)
    if not ready then return end
    shown = v
    if v then main.Visible = true; tw(mainScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
    else local t = tw(mainScale, 0.3, { Scale = 0.01 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In); t.Completed:Once(function() if not shown then main.Visible = false end end) end
end
hideBtn.MouseButton1Click:Connect(function() setShown(false) end)
track(UserInputService.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == Enum.KeyCode.RightShift then setShown(not shown) end end))

env.__MM2_PANEL_CLEANUP = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    if env.__MM2_ESP_CLEANUP then pcall(env.__MM2_ESP_CLEANUP) end
    if env.__MM2_GOD_CLEANUP then pcall(env.__MM2_GOD_CLEANUP) end
    if env.__MM2_MOVE_CLEANUP then pcall(env.__MM2_MOVE_CLEANUP) end
    if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end
    gui:Destroy(); env.__MM2_PANEL_CLEANUP = nil
end
closeBtn.MouseButton1Click:Connect(function() env.__MM2_PANEL_CLEANUP() end)

-- INTRO Y CONSTRUCCIÓN DE PÁGINAS
task.spawn(function()
    task.wait(2.5)
    main.Visible = true
    tw(mainScale, 0.7, { Scale = 1 }, Enum.EasingStyle.Back)
    tw(side, 0.5, { GroupTransparency = 0 })

    Config = loadModule(ESP_FILES, "MM2_ESP_CONFIG")
    GodConfig = loadModule(GODMODE_FILES, "MM2_GOD_CONFIG")
    MoveConfig = loadModule(MOVE_FILES, "MM2_MOVE_CONFIG")
    TPConfig = loadModule(TP_FILES, "MM2_TP_CONFIG")

    for _, p in ipairs(content:GetChildren()) do p:Destroy() end
    table.clear(mainCards)

    -- 1. PÁGINA PRINCIPAL
    pages[1] = newPage()
    make("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 96), CellPadding = UDim2.fromOffset(12, 12) }, pages[1])
    createToggleCard(pages[1], "God Mode", "Te vuelve inmortal contra cuchillos/balas.", function() return GodConfig and GodConfig.Enabled end, function(v) GodConfig.Enabled = v end, GodConfig ~= nil)
    createToggleCard(pages[1], "ESP General", "Activa el ESP rápidamente.", function() return Config and Config.Enabled end, function(v) Config.Enabled = v end, Config ~= nil)
    createSoonCard(pages[1], "Kill All")
    createSoonCard(pages[1], "Auto-Win")

    -- 2. PÁGINA VISUAL (ESP)
    pages[2] = newPage()
    make("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 96), CellPadding = UDim2.fromOffset(12, 12) }, pages[2])
    createToggleCard(pages[2], "Cajas 2D", "Dibuja cajas alrededor del enemigo.", function() return Config and Config.Boxes end, function(v) Config.Boxes = v end, Config ~= nil)
    createToggleCard(pages[2], "Nombres y Roles", "Muestra quién es Asesino/Sheriff.", function() return Config and Config.Names end, function(v) Config.Names = v end, Config ~= nil)
    createSoonCard(pages[2], "Tracers")
    createSoonCard(pages[2], "Chams (Color)")

    -- 3. PÁGINA JUGADOR (MOVIMIENTO)
    pages[3] = newPage()
    make("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 96), CellPadding = UDim2.fromOffset(12, 12) }, pages[3])
    createToggleCard(pages[3], "Velocidad (Speed)", "Aumenta tu velocidad de movimiento.", function() return MoveConfig and MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end, MoveConfig ~= nil)
    createToggleCard(pages[3], "Salto Alto (Jump)", "Aumenta la fuerza de salto.", function() return MoveConfig and MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end, MoveConfig ~= nil)

    -- 4. PÁGINA TELEPORT
    pages[4] = newPage()
    make("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 96), CellPadding = UDim2.fromOffset(12, 12) }, pages[4])
    createToggleCard(pages[4], "TP a Jugador", "Teletransporta al jugador más cercano.", function() return TPConfig and TPConfig.TpPlayer end, function(v) TPConfig.TpPlayer = v end, TPConfig ~= nil)
    createToggleCard(pages[4], "TP a Moneda", "Busca monedas y teletransporta.", function() return TPConfig and TPConfig.TpCoin end, function(v) TPConfig.TpCoin = v end, TPConfig ~= nil)

    -- 5. PÁGINA AJUSTES
    pages[5] = newPage()
    make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Selector de temas\n(Próximamente)", TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 16 }, pages[5])

    pages[1].Visible = true
    ready = true
end)
