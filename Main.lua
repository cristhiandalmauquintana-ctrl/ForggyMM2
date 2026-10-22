--// FroggyHub MM2 | Emerald Edition - v4.1
--// Diseño: ChatGPT | Lógica: DeepSeek | Pestaña Info: Nueva

local GITHUB_USER = "cristhiandalmauquintana-ctrl"
local GITHUB_REPO = "ForggyMM2"
local BRANCH = "main"
local HUB_VERSION = "v4.1"
local HUB_DATE = "22 de Octubre 2026"
local HUB_AUTHOR = "FroggyHub"

local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local ESP_FILES = { "ESP.lua" }
local MOVE_FILES = { "Movement.lua" }
local TP_FILES = { "Teleport.lua" }
local AUTOWIN_FILES = { "AutoWin.lua" }
local LOGO_FILES = { "logo.png", "Logo.png" }

local env = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if env.__MM2_PANEL_CLEANUP then pcall(env.__MM2_PANEL_CLEANUP) end
print("[FroggyHub] Iniciando Emerald " .. HUB_VERSION .. "...")

--==================================================
-- DESCARGA
--==================================================
local function downloadModule(names)
    for _, name in ipairs(names) do
        local ok, res = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(res) == "string" and #res > 0 and res:sub(1, 3) ~= "404" then return res end
    end
    return nil
end

local function loadModule(names, configKey)
    local src = downloadModule(names)
    if not src then warn("[FroggyHub] ❌ No se pudo descargar: " .. configKey) return nil end
    local chunk, err = loadstring(src)
    if not chunk then warn("[FroggyHub] ❌ Sintaxis en " .. configKey .. ": " .. tostring(err)) return nil end
    local ok, runErr = pcall(chunk)
    if not ok then warn("[FroggyHub] ❌ Ejecución en " .. configKey .. ": " .. tostring(runErr)) return nil end
    print("[FroggyHub] ✅ " .. configKey .. " cargado")
    return env[configKey]
end

local function fetchLogo()
    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then return nil end
    for _, name in ipairs(LOGO_FILES) do
        local ok, data = pcall(function() return game:HttpGet(BASE_URL .. name .. "?v=" .. os.time(), true) end)
        if ok and type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG" then
            local path = "FroggyHub_logo.png"
            if pcall(writefile, path, data) then
                local okAsset, asset = pcall(getAsset, path)
                if okAsset and asset and asset ~= "" then return asset end
            end
        end
    end
    return nil
end

local logoAsset = fetchLogo()

--==================================================
-- TEMA EMERALD
--==================================================
local THEME = {
    Background = Color3.fromRGB(5, 15, 12),
    Panel = Color3.fromRGB(9, 25, 20),
    Card = Color3.fromRGB(13, 37, 28),
    Emerald = Color3.fromRGB(0, 255, 145),
    EmeraldDark = Color3.fromRGB(0, 155, 91),
    Mint = Color3.fromRGB(143, 255, 204),
    White = Color3.fromRGB(240, 255, 247),
    Muted = Color3.fromRGB(135, 171, 153),
    Border = Color3.fromRGB(35, 100, 72),
    Danger = Color3.fromRGB(220, 70, 90),
}

--==================================================
-- HELPERS
--==================================================
local function create(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function tween(obj, dur, props, style)
    local anim = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    anim:Play()
    return anim
end

local function round(obj, r) return create("UICorner", { CornerRadius = UDim.new(0, r) }, obj) end
local function outline(obj, color, trans, thick) return create("UIStroke", { Color = color, Transparency = trans or 0, Thickness = thick or 1 }, obj) end

local connections = {}
local function track(c) table.insert(connections, c); return c end

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
local oldGui = parentGui:FindFirstChild("FroggyEmeraldUI")
if oldGui then oldGui:Destroy() end

local gui = create("ScreenGui", {
    Name = "FroggyEmeraldUI", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

--==================================================
-- VENTANA PRINCIPAL
--==================================================
local main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(600, 380),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0, ClipsDescendants = true, Active = false,
}, gui)
round(main, 18)
outline(main, THEME.EmeraldDark, 0.15, 1.5)

local mainScale = create("UIScale", { Scale = 0.9 }, main)

local function updateScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    mainScale.Scale = math.clamp(math.min(vp.X / 680, vp.Y / 440), 0.65, 1)
end
updateScale()

--==================================================
-- FONDO ANIMADO
--==================================================
local bg = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Background, BorderSizePixel = 0, ZIndex = 0 }, main)
round(bg, 18)

local bgGrad = create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 18, 13)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 47, 31)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 13, 12)),
    }),
}, bg)

local glows = {}
for i = 1, 3 do
    local glow = create("Frame", {
        Size = UDim2.fromOffset(240, 240),
        Position = UDim2.new((i - 1) * 0.38, -80, (i % 2 == 0) and 0.6 or 0.1, -60),
        BackgroundColor3 = THEME.Emerald, BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 1,
    }, bg)
    round(glow, 120)
    create("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
        Rotation = 45,
    }, glow)
    table.insert(glows, glow)
end

local light = create("Frame", {
    Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(0, -220, 0, 0),
    BackgroundTransparency = 1, ZIndex = 2,
}, bg)
create("UIGradient", {
    Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.93), NumberSequenceKeypoint.new(1, 1) }),
    Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, THEME.Emerald), ColorSequenceKeypoint.new(1, THEME.Mint) }),
}, light)

--==================================================
-- HEADER
--==================================================
local header = create("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, ZIndex = 5, Active = true }, main)

local logo = create("Frame", {
    Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(18, 14),
    BackgroundColor3 = THEME.Card, BorderSizePixel = 0, ZIndex = 6,
}, header)
round(logo, 14); outline(logo, THEME.Emerald, 0.35, 1)

if logoAsset then
    create("ImageLabel", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Image = logoAsset, ScaleType = Enum.ScaleType.Fit, ZIndex = 7 }, logo)
else
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F", TextColor3 = THEME.Emerald, Font = Enum.Font.GothamBlack, TextSize = 26, ZIndex = 7 }, logo)
end

local title = create("TextLabel", {
    Position = UDim2.fromOffset(72, 13), Size = UDim2.fromOffset(220, 28),
    BackgroundTransparency = 1, Text = "FroggyHub", TextColor3 = THEME.White,
    Font = Enum.Font.GothamBlack, TextSize = 23, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
}, header)
create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, THEME.White), ColorSequenceKeypoint.new(1, THEME.Emerald) }) }, title)

create("TextLabel", {
    Position = UDim2.fromOffset(73, 40), Size = UDim2.fromOffset(220, 17),
    BackgroundTransparency = 1, Text = "EMERALD EDITION  •  " .. HUB_VERSION,
    TextColor3 = THEME.Muted, Font = Enum.Font.GothamMedium, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
}, header)

local statusDot = create("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 26),
    Size = UDim2.fromOffset(9, 9), BackgroundColor3 = THEME.Emerald, BorderSizePixel = 0, ZIndex = 6,
}, header)
round(statusDot, 9)
create("TextLabel", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -79, 0, 22),
    Size = UDim2.fromOffset(75, 18), BackgroundTransparency = 1,
    Text = "ONLINE", TextColor3 = THEME.Mint, Font = Enum.Font.GothamBold,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
}, header)

local closeBtn = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -15, 0, 15),
    Size = UDim2.fromOffset(30, 30), BackgroundColor3 = THEME.Card,
    Text = "×", TextColor3 = THEME.Muted, Font = Enum.Font.GothamBold,
    TextSize = 22, AutoButtonColor = false, ZIndex = 8,
}, header)
round(closeBtn, 10)
track(closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(105, 35, 50), TextColor3 = THEME.White }) end))
track(closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.2, { BackgroundColor3 = THEME.Card, TextColor3 = THEME.Muted }) end))

local minBtn = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -52, 0, 15),
    Size = UDim2.fromOffset(30, 30), BackgroundColor3 = THEME.Card,
    Text = "–", TextColor3 = THEME.Muted, Font = Enum.Font.GothamBold,
    TextSize = 20, AutoButtonColor = false, ZIndex = 8,
}, header)
round(minBtn, 10)
track(minBtn.MouseEnter:Connect(function() tween(minBtn, 0.2, { BackgroundColor3 = THEME.EmeraldDark, TextColor3 = THEME.White }) end))
track(minBtn.MouseLeave:Connect(function() tween(minBtn, 0.2, { BackgroundColor3 = THEME.Card, TextColor3 = THEME.Muted }) end))

local divider = create("Frame", {
    Position = UDim2.fromOffset(18, 70), Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = THEME.EmeraldDark, BackgroundTransparency = 0.35,
    BorderSizePixel = 0, ZIndex = 5,
}, main)

--==================================================
-- SIDEBAR
--==================================================
local sidebar = create("Frame", {
    Position = UDim2.fromOffset(16, 88), Size = UDim2.new(0, 145, 1, -106),
    BackgroundColor3 = THEME.Panel, BackgroundTransparency = 0.18,
    BorderSizePixel = 0, ZIndex = 5,
}, main)
round(sidebar, 14); outline(sidebar, THEME.Border, 0.65, 1)
create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, sidebar)

local content = create("Frame", {
    Position = UDim2.fromOffset(175, 88), Size = UDim2.new(1, -191, 1, -106),
    BackgroundTransparency = 1, ZIndex = 5,
}, main)

local pages = {}
local currentPage = nil

local function createPage(name, icon)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = THEME.EmeraldDark,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        LayoutOrder = #pages + 1, ZIndex = 6,
    }, sidebar)
    round(button, 10)

    local iconLabel = create("TextLabel", {
        Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(25, 42),
        BackgroundTransparency = 1, Text = icon, TextColor3 = THEME.Muted,
        Font = Enum.Font.GothamBold, TextSize = 17, ZIndex = 7,
    }, button)

    local label = create("TextLabel", {
        Position = UDim2.fromOffset(39, 0), Size = UDim2.new(1, -45, 1, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = THEME.Muted,
        Font = Enum.Font.GothamSemibold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, button)

    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.Emerald,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), Visible = false, ZIndex = 5, Active = false,
    }, content)
    create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    create("UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingRight = UDim.new(0, 5) }, page)

    local entry = { Button = button, Label = label, Icon = iconLabel, Page = page, Name = name }
    table.insert(pages, entry)

    local function select()
        if currentPage == entry then return end
        for _, item in ipairs(pages) do
            local sel = item == entry
            item.Page.Visible = sel
            tween(item.Button, 0.2, { BackgroundTransparency = sel and 0.15 or 1 })
            tween(item.Label, 0.2, { TextColor3 = sel and THEME.White or THEME.Muted })
            tween(item.Icon, 0.2, { TextColor3 = sel and THEME.Emerald or THEME.Muted })
        end
        currentPage = entry
    end
    track(button.MouseButton1Click:Connect(select))
    return page
end

local homePage = createPage("Auto-Win", "★")
local visualPage = createPage("Visual", "◉")
local movementPage = createPage("Movimiento", "➤")
local teleportPage = createPage("Teleport", "✈")
local infoPage = createPage("Info", "ℹ")
local settingsPage = createPage("Ajustes", "⚙")

--==================================================
-- COMPONENTES REUTILIZABLES
--==================================================
local function createToggle(parent, name, desc, version, get, set, available)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 82), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 6,
    }, parent)
    round(card, 12); outline(card, THEME.Border, 0.6, 1)

    local accent = create("Frame", {
        Position = UDim2.fromOffset(0, 13), Size = UDim2.new(0, 3, 0, 56),
        BackgroundColor3 = available and THEME.Emerald or THEME.Danger,
        BorderSizePixel = 0, ZIndex = 7,
    }, card)
    round(accent, 3)

    local btn = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 11 }, card)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 13), Size = UDim2.new(1, -90, 0, 22),
        BackgroundTransparency = 1, Text = name, TextColor3 = THEME.White,
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, btn)

    local descText = available and (desc .. (version and ("  |  " .. version) or "")) or "módulo no cargado"
    create("TextLabel", {
        Position = UDim2.fromOffset(15, 38), Size = UDim2.new(1, -28, 0, 30),
        BackgroundTransparency = 1, Text = descText,
        TextColor3 = available and THEME.Muted or THEME.Danger,
        Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 7,
    }, btn)

    local sw = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0, 41),
        Size = UDim2.fromOffset(40, 20), BackgroundColor3 = THEME.Border,
        BorderSizePixel = 0, ZIndex = 8,
    }, btn)
    round(sw, 10)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = THEME.Muted,
        BorderSizePixel = 0, ZIndex = 9,
    }, sw)
    round(knob, 8)

    local function render()
        local on = available and get() and true or false
        tween(sw, 0.2, { BackgroundColor3 = on and THEME.Emerald or THEME.Border })
        tween(knob, 0.25, { Position = on and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = on and THEME.White or THEME.Muted }, Enum.EasingStyle.Back)
    end

    if available then
        btn.MouseButton1Click:Connect(function() set(not get()); render() end)
        btn.MouseEnter:Connect(function() tween(card, 0.15, { BackgroundTransparency = 0 }) end)
        btn.MouseLeave:Connect(function() tween(card, 0.15, { BackgroundTransparency = 0.12 }) end)
    end
    render()
    return card
end

local function createSlider(parent, name, desc, minV, maxV, stepV, get, set, available)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 82), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 6,
    }, parent)
    round(card, 12); outline(card, THEME.Border, 0.6, 1)

    local accent = create("Frame", {
        Position = UDim2.fromOffset(0, 13), Size = UDim2.new(0, 3, 0, 56),
        BackgroundColor3 = THEME.Mint, BorderSizePixel = 0, ZIndex = 7,
    }, card)
    round(accent, 3)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 10), Size = UDim2.new(1, -80, 0, 18),
        BackgroundTransparency = 1, Text = name, TextColor3 = THEME.White,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, card)

    local valueLabel = create("TextLabel", {
        Position = UDim2.fromOffset(15, 10), Size = UDim2.new(1, -30, 0, 18),
        BackgroundTransparency = 1, Text = tostring(get()), TextColor3 = THEME.Emerald,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7,
    }, card)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 30), Size = UDim2.new(1, -28, 0, 14),
        BackgroundTransparency = 1, Text = desc, TextColor3 = THEME.Muted,
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, card)

    local hit = create("Frame", {
        Position = UDim2.fromOffset(15, 50), Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1, ZIndex = 8, Active = true,
    }, card)

    local trackFrame = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = THEME.Border,
        BorderSizePixel = 0, ZIndex = 9,
    }, hit)
    round(trackFrame, 2)

    local fill = create("Frame", {
        Size = UDim2.fromScale((get() - minV) / (maxV - minV), 1),
        BackgroundColor3 = THEME.Emerald, BorderSizePixel = 0, ZIndex = 10,
    }, trackFrame)
    round(fill, 2)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((get() - minV) / (maxV - minV), 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = THEME.White,
        BorderSizePixel = 0, ZIndex = 11,
    }, trackFrame)
    round(knob, 7); outline(knob, THEME.Emerald, 0, 2)

    local dragging = false
    local function update(x)
        local w = math.max(1, trackFrame.AbsoluteSize.X)
        local rel = math.clamp((x - trackFrame.AbsolutePosition.X) / w, 0, 1)
        local v = minV + rel * (maxV - minV)
        v = math.floor(v / stepV + 0.5) * stepV
        v = math.clamp(v, minV, maxV)
        set(v); valueLabel.Text = tostring(v)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
    end

    track(hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(input.Position.X)
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false; conn:Disconnect() end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update(input.Position.X)
        end
    end))
    return card
end

local function createSoon(parent, label)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 82), BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 6,
    }, parent)
    round(card, 12); outline(card, THEME.Muted, 0.7, 1)
    create("TextLabel", {
        Position = UDim2.fromOffset(15, 13), Size = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1, Text = label, TextColor3 = THEME.Muted,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, card)
    local badge = create("TextLabel", {
        Position = UDim2.fromOffset(15, 45), Size = UDim2.fromOffset(100, 18),
        BackgroundColor3 = THEME.EmeraldDark, BackgroundTransparency = 0.7,
        Text = "PRÓXIMAMENTE", TextColor3 = THEME.White,
        Font = Enum.Font.GothamBold, TextSize = 9, ZIndex = 7,
    }, card)
    round(badge, 9)
    return card
end

--==================================================
-- PESTAÑA INFO (LOGO CENTRADO + CRÉDITOS)
--==================================================
local function buildInfoPage()
    -- Logo grande centrado
    local logoFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 140),
        BackgroundTransparency = 1, ZIndex = 6,
    }, infoPage)

    local bigLogo = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.fromOffset(110, 110),
        BackgroundColor3 = THEME.Card, BorderSizePixel = 0, ZIndex = 7,
    }, logoFrame)
    round(bigLogo, 55)
    outline(bigLogo, THEME.Emerald, 0.2, 2.5)

    if logoAsset then
        create("ImageLabel", {
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 1, Image = logoAsset,
            ScaleType = Enum.ScaleType.Fit, ZIndex = 8,
        }, bigLogo)
    else
        create("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Text = "F", TextColor3 = THEME.Emerald,
            Font = Enum.Font.GothamBlack, TextSize = 55, ZIndex = 8,
        }, bigLogo)
    end

    -- Nombre debajo del logo
    create("TextLabel", {
        Position = UDim2.new(0, 0, 0, 118), Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1, Text = HUB_AUTHOR,
        TextColor3 = THEME.Emerald, Font = Enum.Font.GothamBlack,
        TextSize = 18, ZIndex = 7,
    }, logoFrame)

    -- Tarjeta de versión
    local versionCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.12,
        BorderSizePixel = 0, ZIndex = 6,
    }, infoPage)
    round(versionCard, 12); outline(versionCard, THEME.Border, 0.6, 1)

    create("Frame", {
        Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 3, 0, 46),
        BackgroundColor3 = THEME.Emerald, BorderSizePixel = 0, ZIndex = 7,
    }, versionCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 10), Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1, Text = "VERSIÓN DEL SCRIPT",
        TextColor3 = THEME.Muted, Font = Enum.Font.GothamBold, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, versionCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 30), Size = UDim2.new(1, -30, 0, 26),
        BackgroundTransparency = 1, Text = HUB_VERSION .. "  •  Emerald Edition",
        TextColor3 = THEME.White, Font = Enum.Font.GothamBlack, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, versionCard)

    -- Tarjeta de fecha
    local dateCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.12,
        BorderSizePixel = 0, ZIndex = 6,
    }, infoPage)
    round(dateCard, 12); outline(dateCard, THEME.Border, 0.6, 1)

    create("Frame", {
        Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 3, 0, 46),
        BackgroundColor3 = THEME.Mint, BorderSizePixel = 0, ZIndex = 7,
    }, dateCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 10), Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1, Text = "ÚLTIMA ACTUALIZACIÓN",
        TextColor3 = THEME.Muted, Font = Enum.Font.GothamBold, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, dateCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 30), Size = UDim2.new(1, -30, 0, 26),
        BackgroundTransparency = 1, Text = HUB_DATE,
        TextColor3 = THEME.White, Font = Enum.Font.GothamBlack, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, dateCard)

    -- Tarjeta de créditos
    local creditsCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.12,
        BorderSizePixel = 0, ZIndex = 6,
    }, infoPage)
    round(creditsCard, 12); outline(creditsCard, THEME.Border, 0.6, 1)

    create("Frame", {
        Position = UDim2.fromOffset(0, 12), Size = UDim2.new(0, 3, 0, 66),
        BackgroundColor3 = THEME.EmeraldDark, BorderSizePixel = 0, ZIndex = 7,
    }, creditsCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 10), Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1, Text = "DESARROLLADO POR",
        TextColor3 = THEME.Muted, Font = Enum.Font.GothamBold, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, creditsCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 30), Size = UDim2.new(1, -30, 0, 22),
        BackgroundTransparency = 1, Text = HUB_AUTHOR,
        TextColor3 = THEME.Emerald, Font = Enum.Font.GothamBlack, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, creditsCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(15, 54), Size = UDim2.new(1, -30, 0, 22),
        BackgroundTransparency = 1, Text = "Diseño Emerald • Lógica Funcional",
        TextColor3 = THEME.Muted, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, creditsCard)

    -- Tarjeta de estado
    local statusCard = create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = THEME.Card, BackgroundTransparency = 0.12,
        BorderSizePixel = 0, ZIndex = 6,
    }, infoPage)
    round(statusCard, 12); outline(statusCard, THEME.Emerald, 0.4, 1.5)

    local pulseDot = create("Frame", {
        Position = UDim2.fromOffset(15, 27), Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = THEME.Emerald, BorderSizePixel = 0, ZIndex = 7,
    }, statusCard)
    round(pulseDot, 7)

    create("TextLabel", {
        Position = UDim2.fromOffset(38, 20), Size = UDim2.new(1, -50, 0, 26),
        BackgroundTransparency = 1, Text = "SISTEMA OPERATIVO",
        TextColor3 = THEME.White, Font = Enum.Font.GothamBlack, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, statusCard)

    create("TextLabel", {
        Position = UDim2.fromOffset(38, 42), Size = UDim2.new(1, -50, 0, 18),
        BackgroundTransparency = 1, Text = "Todos los módulos cargados correctamente",
        TextColor3 = THEME.Mint, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    }, statusCard)
end

--==================================================
-- ARRASTRE (Multi-touch fix)
--==================================================
local activeTouch = nil
local function makeDraggable(handle)
    local dragging, startPos, startPos2, moved
    track(handle.InputBegan:Connect(function(input)
        if activeTouch then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeTouch = input
            dragging = true; startPos = input.Position; startPos2 = main.Position; moved = false
            local conn; conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false; activeTouch = nil
                    conn:Disconnect()
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragging or activeTouch ~= input then return end
        local d = input.Position - startPos
        if d.Magnitude > 5 then moved = true end
        if moved then
            main.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + d.X, startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
        end
    end))
end
makeDraggable(header)

--==================================================
-- BURBUJA CON LOGO (FIXED)
--==================================================
local BUBBLE = 52
local bubble = create("TextButton", {
    Size = UDim2.fromOffset(BUBBLE, BUBBLE), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = THEME.Card, BorderSizePixel = 0, Text = "",
    Visible = false, AutoButtonColor = false, ZIndex = 100,
}, gui)
round(bubble, BUBBLE / 2)
outline(bubble, THEME.Emerald, 0.2, 2)

if logoAsset then
    create("ImageLabel", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1, Image = logoAsset, ScaleType = Enum.ScaleType.Fit, ZIndex = 101 }, bubble)
else
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "F", TextColor3 = THEME.Emerald, Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 101 }, bubble)
end

-- 🔥 FIX: setShown ANTES del drag de la burbuja
local shown = true
local setShown
setShown = function(v)
    if shown == v then return end
    shown = v
    if v then
        bubble.Visible = false
        main.Visible = true
        local cam = workspace.CurrentCamera
        local target = 0.9
        if cam then
            local vp = cam.ViewportSize
            target = math.clamp(math.min(vp.X / 680, vp.Y / 440), 0.65, 1)
        end
        tween(mainScale, 0.45, { Scale = target }, Enum.EasingStyle.Back)
    else
        local t = tween(mainScale, 0.3, { Scale = 0.01 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Once(function()
            if not shown then
                main.Visible = false
                bubble.Visible = true
                bubble.Position = UDim2.fromOffset(main.AbsolutePosition.X, main.AbsolutePosition.Y)
            end
        end)
    end
end

-- Arrastrar / clic de la burbuja
local bubbleDragging, bubbleMoved
track(bubble.InputBegan:Connect(function(input)
    if activeTouch then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeTouch = input
        bubbleDragging = true
        local startPos = input.Position
        local startAbs = Vector2.new(bubble.AbsolutePosition.X, bubble.AbsolutePosition.Y)
        bubbleMoved = false

        local conn; conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                bubbleDragging = false
                activeTouch = nil
                if not bubbleMoved then setShown(true) end
                conn:Disconnect()
            end
        end)

        track(UserInputService.InputChanged:Connect(function(inp)
            if not bubbleDragging or activeTouch ~= input then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = inp.Position - startPos
            if d.Magnitude > 5 then bubbleMoved = true end
            if bubbleMoved then
                bubble.Position = UDim2.fromOffset(startAbs.X + d.X, startAbs.Y + d.Y)
            end
        end))
    end
end))

-- Botón minimizar
track(minBtn.MouseButton1Click:Connect(function() setShown(false) end))

--==================================================
-- ANIMACIONES
--==================================================
local animRunning = true
track(RunService.RenderStepped:Connect(function()
    if not animRunning or not gui.Parent then return end
    bgGrad.Rotation = (bgGrad.Rotation + 0.08) % 360
end))

for i, g in ipairs(glows) do
    task.spawn(function()
        while animRunning and gui.Parent do
            local target = UDim2.new(math.random(5, 85) / 100, -100, math.random(10, 85) / 100, -100)
            local t = tween(g, math.random(4, 7), { Position = target })
            t.Completed:Wait()
            task.wait(0.2 * i)
        end
    end)
end

task.spawn(function()
    while animRunning and gui.Parent do
        tween(light, 2.5, { Position = UDim2.new(1, 180, 0, 0) })
        task.wait(3)
        if not animRunning then break end
        light.Position = UDim2.new(0, -220, 0, 0)
        task.wait(1)
    end
end)

--==================================================
-- CARGA DE MÓDULOS Y CONSTRUCCIÓN
--==================================================
local Config, MoveConfig, TPConfig, AutoWinConfig

env.__MM2_PANEL_CLEANUP = function()
    animRunning = false
    if env.__MM2_ESP_CLEANUP then pcall(env.__MM2_ESP_CLEANUP) end
    if env.__MM2_MOVE_CLEANUP then pcall(env.__MM2_MOVE_CLEANUP) end
    if env.__MM2_TP_CLEANUP then pcall(env.__MM2_TP_CLEANUP) end
    if env.__MM2_AUTOWIN_CLEANUP then pcall(env.__MM2_AUTOWIN_CLEANUP) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    env.__MM2_PANEL_CLEANUP = nil
end
closeBtn.MouseButton1Click:Connect(function()
    tween(mainScale, 0.25, { Scale = 0 })
    task.delay(0.3, env.__MM2_PANEL_CLEANUP)
end)

task.spawn(function()
    task.wait(0.3)
    print("[FroggyHub] Cargando módulos...")
    Config = loadModule(ESP_FILES, "MM2_ESP_CONFIG")
    MoveConfig = loadModule(MOVE_FILES, "MM2_MOVE_CONFIG")
    TPConfig = loadModule(TP_FILES, "MM2_TP_CONFIG")
    AutoWinConfig = loadModule(AUTOWIN_FILES, "MM2_AUTOWIN_CONFIG")

    print("[FroggyHub] Construyendo UI...")

    -- PESTAÑA AUTO-WIN
    if AutoWinConfig then
        createToggle(homePage, "Auto-Win", "Teletransporta y ataca automáticamente según tu rol.", AutoWinConfig.Version, function() return AutoWinConfig.Enabled end, function(v) AutoWinConfig.Enabled = v end, true)
        createSoon(homePage, "Kill All")
        createSoon(homePage, "Auto-Farm")
    else
        createSoon(homePage, "Auto-Win (No cargado)")
    end

    -- PESTAÑA VISUAL
    if Config then
        createToggle(visualPage, "ESP General", "Activa el ESP completo.", Config.Version, function() return Config.Enabled end, function(v) Config.Enabled = v end, true)
        createToggle(visualPage, "Cajas 2D", "Cajas alrededor del enemigo.", nil, function() return Config.Boxes end, function(v) Config.Boxes = v end, true)
        createToggle(visualPage, "Nombres y Roles", "Muestra Asesino/Sheriff.", nil, function() return Config.Names end, function(v) Config.Names = v end, true)
        createToggle(visualPage, "ESP Armas", "Armas en el suelo.", nil, function() return Config.ShowWeapons end, function(v) Config.ShowWeapons = v end, true)
        createToggle(visualPage, "ESP Monedas", "Monedas en el suelo.", nil, function() return Config.ShowCoins end, function(v) Config.ShowCoins = v end, true)
    else
        createSoon(visualPage, "ESP (No cargado)")
    end

    -- PESTAÑA MOVIMIENTO
    if MoveConfig then
        createToggle(movementPage, "Velocidad", "Aumenta la velocidad.", MoveConfig.Version, function() return MoveConfig.SpeedEnabled end, function(v) MoveConfig.SpeedEnabled = v end, true)
        createSlider(movementPage, "Velocidad (studs/s)", "Ajusta la velocidad exacta.", 16, 200, 4, function() return MoveConfig.Speed end, function(v) MoveConfig.Speed = v end, true)
        createToggle(movementPage, "Salto Alto", "Aumenta el salto.", MoveConfig.Version, function() return MoveConfig.JumpEnabled end, function(v) MoveConfig.JumpEnabled = v end, true)
        createSlider(movementPage, "Salto (power)", "Ajusta la fuerza del salto.", 50, 300, 10, function() return MoveConfig.JumpPower end, function(v) MoveConfig.JumpPower = v end, true)
    else
        createSoon(movementPage, "Movimiento (No cargado)")
    end

    -- PESTAÑA TELEPORT
    if TPConfig then
        createToggle(teleportPage, "TP a Jugador", "Va al jugador más cercano.", TPConfig.Version, function() return TPConfig.TpPlayer end, function(v) TPConfig.TpPlayer = v end, true)
        createToggle(teleportPage, "TP a Moneda", "Busca monedas y teletransporta.", TPConfig.Version, function() return TPConfig.TpCoin end, function(v) TPConfig.TpCoin = v end, true)
    else
        createSoon(teleportPage, "Teleport (No cargado)")
    end

    -- PESTAÑA INFO
    buildInfoPage()

    -- PESTAÑA AJUSTES
    createSoon(settingsPage, "Selector de temas")
    createSoon(settingsPage, "Guardar configuración")
    createSoon(settingsPage, "Restablecer ajustes")

    -- Estado inicial
    homePage.Visible = true
    currentPage = pages[1]
    for _, item in ipairs(pages) do
        local sel = item == currentPage
        item.Button.BackgroundTransparency = sel and 0.15 or 1
        item.Label.TextColor3 = sel and THEME.White or THEME.Muted
        item.Icon.TextColor3 = sel and THEME.Emerald or THEME.Muted
    end

    main.Position = UDim2.fromScale(0.5, 0.54)
    main.BackgroundTransparency = 1
    tween(main, 0.6, { Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)

    print("[FroggyHub] ✅ Emerald UI v" .. HUB_VERSION .. " construida correctamente.")
end)
