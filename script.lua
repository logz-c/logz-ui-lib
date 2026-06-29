--[[
    ╔══════════════════════════════════════════════╗
    ║  Advanced Script Hub UI Library v3.0         ║
    ║  Features:                                   ║
    ║  - 18+ Interface Types                       ║
    ║  - Full Config System (Save/Load/Delete)     ║
    ║  - Advanced Settings (Theme/Size/Opacity)    ║
    ║  - Mobile Support (Toggle + Lock Buttons)    ║
    ║  - Screen Adaptive Layout                    ║
    ║  - Default Semi-Transparent                  ║
    ║  - Sound Effects & Animations                ║
    ║  - Notification System                       ║
    ╚══════════════════════════════════════════════╝
]]

local Library = {}
Library.__index = Library

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local LIBRARY_NAME = "ScriptHub"
local CONFIG_FOLDER = LIBRARY_NAME .. "/Configs"
local SETTINGS_FILE = LIBRARY_NAME .. "/ui_settings.json"

-- Detect Platform
local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function GetScreenSize()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    return viewport
end

-- Default Theme
local DefaultTheme = {
    Primary = Color3.fromRGB(18, 18, 28),
    Secondary = Color3.fromRGB(24, 24, 38),
    Tertiary = Color3.fromRGB(32, 32, 50),
    Accent = Color3.fromRGB(88, 110, 255),
    AccentDark = Color3.fromRGB(60, 80, 200),
    AccentLight = Color3.fromRGB(120, 140, 255),
    Text = Color3.fromRGB(225, 225, 240),
    TextDark = Color3.fromRGB(140, 140, 165),
    TextMuted = Color3.fromRGB(90, 90, 115),
    Success = Color3.fromRGB(65, 200, 110),
    Warning = Color3.fromRGB(255, 190, 60),
    Error = Color3.fromRGB(255, 70, 70),
    Border = Color3.fromRGB(45, 45, 68),
    Shadow = Color3.fromRGB(8, 8, 14),
    InputBG = Color3.fromRGB(14, 14, 22),
    NotifBG = Color3.fromRGB(22, 22, 36),
    TabInactive = Color3.fromRGB(36, 36, 54),
    ToggleOff = Color3.fromRGB(50, 50, 72),
    SliderBar = Color3.fromRGB(40, 40, 60),
}

local Theme = {}
for k, v in pairs(DefaultTheme) do Theme[k] = v end

-- Sound IDs
local Sounds = {
    Click = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079853",
    Notify = "rbxassetid://6026984224",
    Open = "rbxassetid://6895079853",
    Close = "rbxassetid://6895079853",
    Slider = "rbxassetid://6895079853",
}

-- UI Settings (persistable)
local UISettings = {
    Opacity = 0.35,
    Scale = 1.0,
    FontScale = 1.0,
    CornerRadius = 10,
    AnimSpeed = 1.0,
    SoundEnabled = true,
    DragEnabled = true,
    AccentColor = DefaultTheme.Accent,
    BackgroundColor = DefaultTheme.Primary,
    SidebarWidth = 150,
    Locked = false,
}

-- ═══════════════════════════════════
-- Utility Functions
-- ═══════════════════════════════════
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            if typeof(v) == "Instance" then
                v.Parent = inst
            else
                pcall(function() inst[k] = v end)
            end
        end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return end
    duration = (duration or 0.3) / (UISettings.AnimSpeed or 1)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    tw:Play()
    return tw
end

local function PlaySound(soundId, volume)
    if not UISettings.SoundEnabled then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.25
        sound.Parent = CoreGui
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
end

local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or UISettings.CornerRadius),
        Parent = parent
    })
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function AddPadding(parent, t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft = UDim.new(0, l or 6),
        PaddingRight = UDim.new(0, r or 6),
        Parent = parent
    })
end

local function AddGradient(parent, c1, c2, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2)
        }),
        Rotation = rotation or 90,
        Parent = parent
    })
end

local function AddShadow(parent)
    return Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = -1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = parent
    })
end

local function Ripple(button)
    pcall(function()
        local absPos = button.AbsolutePosition
        local mousePos = UserInputService:GetMouseLocation()
        local ripple = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.75,
            Position = UDim2.new(0, mousePos.X - absPos.X, 0, mousePos.Y - absPos.Y - GuiService:GetGuiInset().Y),
            Size = UDim2.new(0, 0, 0, 0),
            ZIndex = button.ZIndex + 10,
            Parent = button
        })
        AddCorner(ripple, 999)
        local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
        local tw = Tween(ripple, 0.5, {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1
        })
        if tw then
            tw.Completed:Connect(function() ripple:Destroy() end)
        end
    end)
end

local function ScaleSize(baseWidth, baseHeight)
    local s = UISettings.Scale or 1
    return UDim2.new(0, math.floor(baseWidth * s), 0, math.floor(baseHeight * s))
end

local function ScaleFont(baseSize)
    return math.floor(baseSize * (UISettings.FontScale or 1))
end

local function GetAdaptiveSize()
    local screen = GetScreenSize()
    local isMobile = IsMobile()
    local baseW, baseH

    if isMobile then
        baseW = math.min(screen.X * 0.92, 600)
        baseH = math.min(screen.Y * 0.75, 420)
    else
        baseW = math.min(math.max(screen.X * 0.42, 520), 720)
        baseH = math.min(math.max(screen.Y * 0.55, 380), 520)
    end

    local s = UISettings.Scale or 1
    return UDim2.new(0, math.floor(baseW * s), 0, math.floor(baseH * s))
end

local function GetSidebarWidth()
    local screen = GetScreenSize()
    local isMobile = IsMobile()
    local base = isMobile and 120 or (UISettings.SidebarWidth or 150)
    return math.floor(base * (UISettings.Scale or 1))
end

-- ═══════════════════════════════════
-- Config System
-- ═══════════════════════════════════
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new()
    local self = setmetatable({}, ConfigSystem)
    self.Flags = {}
    return self
end

function ConfigSystem:Set(flag, value)
    self.Flags[flag] = value
end

function ConfigSystem:Get(flag)
    return self.Flags[flag]
end

function ConfigSystem:SaveConfig(name)
    local data = {}
    for flag, value in pairs(self.Flags) do
        local t = typeof(value)
        if t == "boolean" or t == "number" or t == "string" then
            data[flag] = {T = t, V = value}
        elseif t == "Color3" then
            data[flag] = {T = "Color3", V = {value.R, value.G, value.B}}
        elseif t == "EnumItem" then
            data[flag] = {T = "Enum", V = tostring(value)}
        end
    end
    local ok = pcall(function()
        makefolder(LIBRARY_NAME)
        makefolder(CONFIG_FOLDER)
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return ok
end

function ConfigSystem:LoadConfig(name)
    local ok = pcall(function()
        local raw = readfile(CONFIG_FOLDER .. "/" .. name .. ".json")
        local data = HttpService:JSONDecode(raw)
        for flag, info in pairs(data) do
            if info.T == "Color3" then
                self.Flags[flag] = Color3.new(info.V[1], info.V[2], info.V[3])
            elseif info.T == "Enum" then
                pcall(function()
                    local parts = string.split(info.V, ".")
                    self.Flags[flag] = Enum[parts[2]][parts[3]]
                end)
            else
                self.Flags[flag] = info.V
            end
        end
    end)
    return ok
end

function ConfigSystem:DeleteConfig(name)
    local ok = pcall(function()
        delfile(CONFIG_FOLDER .. "/" .. name .. ".json")
    end)
    return ok
end

function ConfigSystem:GetConfigs()
    local configs = {}
    pcall(function()
        makefolder(LIBRARY_NAME)
        makefolder(CONFIG_FOLDER)
        for _, file in ipairs(listfiles(CONFIG_FOLDER)) do
            local n = file:match("([^/\\]+)%.json$")
            if n then table.insert(configs, n) end
        end
    end)
    return configs
end

-- Save/Load UI Settings
local function SaveUISettings()
    pcall(function()
        makefolder(LIBRARY_NAME)
        local data = {
            Opacity = UISettings.Opacity,
            Scale = UISettings.Scale,
            FontScale = UISettings.FontScale,
            CornerRadius = UISettings.CornerRadius,
            AnimSpeed = UISettings.AnimSpeed,
            SoundEnabled = UISettings.SoundEnabled,
            DragEnabled = UISettings.DragEnabled,
            AccentR = UISettings.AccentColor.R,
            AccentG = UISettings.AccentColor.G,
            AccentB = UISettings.AccentColor.B,
            BGr = UISettings.BackgroundColor.R,
            BGg = UISettings.BackgroundColor.G,
            BGb = UISettings.BackgroundColor.B,
            SidebarWidth = UISettings.SidebarWidth,
        }
        writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadUISettings()
    pcall(function()
        if isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            UISettings.Opacity = data.Opacity or 0.35
            UISettings.Scale = data.Scale or 1.0
            UISettings.FontScale = data.FontScale or 1.0
            UISettings.CornerRadius = data.CornerRadius or 10
            UISettings.AnimSpeed = data.AnimSpeed or 1.0
            UISettings.SoundEnabled = data.SoundEnabled ~= false
            UISettings.DragEnabled = data.DragEnabled ~= false
            UISettings.SidebarWidth = data.SidebarWidth or 150
            if data.AccentR then
                UISettings.AccentColor = Color3.new(data.AccentR, data.AccentG, data.AccentB)
                Theme.Accent = UISettings.AccentColor
            end
            if data.BGr then
                UISettings.BackgroundColor = Color3.new(data.BGr, data.BGg, data.BGb)
                Theme.Primary = UISettings.BackgroundColor
            end
        end
    end)
end

LoadUISettings()

-- ═══════════════════════════════════
-- Main Library Constructor
-- ═══════════════════════════════════
function Library.new(title, subtitle)
    local self = setmetatable({}, Library)
    self.Title = title or "Script Hub"
    self.Subtitle = subtitle or "v3.0"
    self.Tabs = {}
    self.ActiveTab = nil
    self.Toggled = true
    self.ToggleKey = Enum.KeyCode.RightControl
    self.Config = ConfigSystem.new()
    self.Elements = {} -- Track all elements for theme updates
    self.IsMobile = IsMobile()
    self.Locked = false

    self:_Build()
    return self
end

function Library:_Build()
    -- Clean up
    pcall(function() CoreGui:FindFirstChild(LIBRARY_NAME .. "_UI"):Destroy() end)

    self.ScreenGui = Create("ScreenGui", {
        Name = LIBRARY_NAME .. "_UI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = CoreGui
    })

    local adaptiveSize = GetAdaptiveSize()
    local sidebarW = GetSidebarWidth()

    -- ── Main Frame ──
    self.MainFrame = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Primary,
        BackgroundTransparency = UISettings.Opacity,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true,
        Parent = self.ScreenGui
    })
    AddCorner(self.MainFrame, UISettings.CornerRadius + 2)
    local mainStroke = AddStroke(self.MainFrame, Theme.Border, 1.5, 0.3)
    AddShadow(self.MainFrame)

    -- Open animation
    PlaySound(Sounds.Open, 0.4)
    Tween(self.MainFrame, 0.65, {Size = adaptiveSize}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- ── Title Bar ──
    local titleBarH = math.floor(44 * (UISettings.Scale or 1))
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.1, 0),
        Size = UDim2.new(1, 0, 0, titleBarH),
        Parent = self.MainFrame
    })
    AddCorner(self.TitleBar, UISettings.CornerRadius + 2)
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.1, 0),
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BorderSizePixel = 0,
        Parent = self.TitleBar
    })

    -- Accent Line
    local accentLine = Create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(0, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.TitleBar
    })
    AddGradient(accentLine, Theme.Accent, Theme.AccentDark or Theme.Accent, 0)
    task.delay(0.3, function()
        Tween(accentLine, 0.9, {Size = UDim2.new(1, 0, 0, 2)})
    end)

    -- Title
    self.TitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })

    self.SubtitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 4, 0, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = self.Subtitle,
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })

    -- Window Buttons
    local btnSize = math.floor(22 * (UISettings.Scale or 1))
    local function makeWindowBtn(name, text, color, offset)
        local btn = Create("TextButton", {
            Name = name,
            BackgroundColor3 = color,
            BackgroundTransparency = 0.8,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, offset, 0.5, 0),
            Size = UDim2.new(0, btnSize, 0, btnSize),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = color,
            TextSize = ScaleFont(text == "×" and 18 or 12),
            AutoButtonColor = false,
            Parent = self.TitleBar
        })
        AddCorner(btn, 6)
        btn.MouseEnter:Connect(function() Tween(btn, 0.2, {BackgroundTransparency = 0.3}) end)
        btn.MouseLeave:Connect(function() Tween(btn, 0.2, {BackgroundTransparency = 0.8}) end)
        return btn
    end

    local closeBtn = makeWindowBtn("Close", "×", Theme.Error, -12)
    local minBtn = makeWindowBtn("Min", "—", Theme.Warning, -12 - btnSize - 6)

    closeBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Close, 0.4)
        self:Destroy()
    end)
    minBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click, 0.3)
        self:Toggle()
    end)

    -- ── Sidebar ──
    self.Sidebar = Create("ScrollingFrame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.05, 0),
        Position = UDim2.new(0, 0, 0, titleBarH + 2),
        Size = UDim2.new(0, sidebarW, 1, -(titleBarH + 2)),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    AddCorner(self.Sidebar, UISettings.CornerRadius)
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.05, 0),
        Size = UDim2.new(1, 0, 0, 8),
        BorderSizePixel = 0,
        Parent = self.Sidebar
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.05, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 8, 1, 0),
        BorderSizePixel = 0,
        Parent = self.Sidebar
    })
    AddPadding(self.Sidebar, 6, 6, 6, 6)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        Parent = self.Sidebar
    })

    -- Sidebar Divider
    Create("Frame", {
        Name = "SidebarDivider",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        Position = UDim2.new(0, sidebarW, 0, titleBarH + 2),
        Size = UDim2.new(0, 1, 1, -(titleBarH + 2)),
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })

    -- ── Content Area ──
    self.ContentArea = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarW + 2, 0, titleBarH + 2),
        Size = UDim2.new(1, -(sidebarW + 2), 1, -(titleBarH + 2)),
        ClipsDescendants = true,
        Parent = self.MainFrame
    })

    -- ── Notification Container ──
    self.NotifContainer = Create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -12),
        Size = UDim2.new(0, math.min(300, GetScreenSize().X * 0.4), 1, -24),
        ZIndex = 100,
        Parent = self.ScreenGui
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = self.NotifContainer
    })

    -- ── Mobile Buttons ──
    if self.IsMobile then
        self:_BuildMobileButtons()
    end

    -- ── Dragging ──
    self:_SetupDrag()

    -- ── Keybind Toggle ──
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)

    -- Welcome
    task.delay(1, function()
        local keyStr = self.IsMobile and "the floating button" or tostring(self.ToggleKey.Name)
        self:Notify("Welcome", "Press " .. keyStr .. " to toggle UI", "info", 5)
    end)
end

-- ═══════════════════════════════════
-- Mobile Floating Buttons
-- ═══════════════════════════════════
function Library:_BuildMobileButtons()
    -- Container for mobile buttons
    self.MobileContainer = Create("Frame", {
        Name = "MobileButtons",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.new(0, 50, 0, 110),
        ZIndex = 200,
        Parent = self.ScreenGui
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = self.MobileContainer
    })

    -- Toggle Button (open/close UI)
    self.MobileToggleBtn = Create("TextButton", {
        Name = "ToggleBtn",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.2,
        Size = UDim2.new(0, 48, 0, 48),
        Font = Enum.Font.GothamBold,
        Text = "☰",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 22,
        AutoButtonColor = false,
        LayoutOrder = 1,
        ZIndex = 201,
        Parent = self.MobileContainer
    })
    AddCorner(self.MobileToggleBtn, 24)
    AddStroke(self.MobileToggleBtn, Theme.Accent, 2, 0.3)
    AddShadow(self.MobileToggleBtn)

    self.MobileToggleBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click, 0.3)
        self:Toggle()
        -- Animate button
        Tween(self.MobileToggleBtn, 0.15, {Size = UDim2.new(0, 42, 0, 42)})
        task.delay(0.15, function()
            Tween(self.MobileToggleBtn, 0.2, {Size = UDim2.new(0, 48, 0, 48)}, Enum.EasingStyle.Back)
        end)
        self.MobileToggleBtn.Text = self.Toggled and "☰" or "▶"
    end)

    -- Lock Button (lock/unlock position)
    self.MobileLockBtn = Create("TextButton", {
        Name = "LockBtn",
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.2,
        Size = UDim2.new(0, 48, 0, 48),
        Font = Enum.Font.GothamBold,
        Text = "🔓",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 20,
        AutoButtonColor = false,
        LayoutOrder = 2,
        ZIndex = 201,
        Parent = self.MobileContainer
    })
    AddCorner(self.MobileLockBtn, 24)
    AddStroke(self.MobileLockBtn, Theme.Border, 1.5, 0.4)
    AddShadow(self.MobileLockBtn)

    self.MobileLockBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Toggle, 0.3)
        self.Locked = not self.Locked
        UISettings.DragEnabled = not self.Locked

        if self.Locked then
            self.MobileLockBtn.Text = "🔒"
            Tween(self.MobileLockBtn, 0.3, {BackgroundColor3 = Theme.Error, BackgroundTransparency = 0.3})
            self:Notify("UI", "Position locked", "warning", 2)
        else
            self.MobileLockBtn.Text = "🔓"
            Tween(self.MobileLockBtn, 0.3, {BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0.2})
            self:Notify("UI", "Position unlocked", "success", 2)
        end

        -- Animate
        Tween(self.MobileLockBtn, 0.1, {Rotation = self.Locked and 15 or -15})
        task.delay(0.1, function()
            Tween(self.MobileLockBtn, 0.2, {Rotation = 0}, Enum.EasingStyle.Back)
        end)
    end)

    -- Make mobile buttons draggable
    self:_MakeDraggable(self.MobileContainer)
end

function Library:_MakeDraggable(frame)
    local dragging, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════
-- Dragging System
-- ═══════════════════════════════════
function Library:_SetupDrag()
    local dragging, dragInput, dragStart, startPos

    self.TitleBar.InputBegan:Connect(function(input)
        if not UISettings.DragEnabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(self.MainFrame, 0.06, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }, Enum.EasingStyle.Linear)
        end
    end)
end

-- ═══════════════════════════════════
-- Toggle / Destroy
-- ═══════════════════════════════════
function Library:Toggle()
    self.Toggled = not self.Toggled
    if self.Toggled then
        PlaySound(Sounds.Open, 0.4)
        self.MainFrame.Visible = true
        Tween(self.MainFrame, 0.5, {
            Size = GetAdaptiveSize(),
            BackgroundTransparency = UISettings.Opacity
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        PlaySound(Sounds.Close, 0.4)
        local tw = Tween(self.MainFrame, 0.35, {
            Size = UDim2.new(0, self.MainFrame.AbsoluteSize.X, 0, 0),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        if tw then
            tw.Completed:Connect(function()
                if not self.Toggled then self.MainFrame.Visible = false end
            end)
        end
    end
    if self.MobileToggleBtn then
        self.MobileToggleBtn.Text = self.Toggled and "☰" or "▶"
    end
end

function Library:Destroy()
    PlaySound(Sounds.Close, 0.4)
    local tw = Tween(self.MainFrame, 0.4, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    if tw then
        tw.Completed:Connect(function()
            self.ScreenGui:Destroy()
        end)
    else
        task.delay(0.5, function() pcall(function() self.ScreenGui:Destroy() end) end)
    end
end

-- ═══════════════════════════════════
-- Apply Theme Updates
-- ═══════════════════════════════════
function Library:ApplyTheme()
    Theme.Accent = UISettings.AccentColor
    Theme.Primary = UISettings.BackgroundColor

    pcall(function()
        self.MainFrame.BackgroundColor3 = Theme.Primary
        self.MainFrame.BackgroundTransparency = UISettings.Opacity
        self.TitleBar.BackgroundColor3 = Theme.Secondary
        self.TitleBar.BackgroundTransparency = math.max(UISettings.Opacity - 0.1, 0)
        self.Sidebar.BackgroundColor3 = Theme.Secondary
        self.Sidebar.BackgroundTransparency = math.max(UISettings.Opacity - 0.05, 0)
    end)

    -- Resize
    pcall(function()
        local newSize = GetAdaptiveSize()
        Tween(self.MainFrame, 0.4, {Size = newSize})
    end)

    SaveUISettings()
end

-- ═══════════════════════════════════
-- Notification System
-- ═══════════════════════════════════
function Library:Notify(title, message, ntype, duration)
    ntype = ntype or "info"
    duration = duration or 4
    PlaySound(Sounds.Notify, 0.35)

    local color = Theme.Accent
    local icon = "ℹ"
    if ntype == "success" then color = Theme.Success; icon = "✓"
    elseif ntype == "warning" then color = Theme.Warning; icon = "⚠"
    elseif ntype == "error" then color = Theme.Error; icon = "✕" end

    local notifW = math.min(300, GetScreenSize().X * 0.4)

    local notif = Create("Frame", {
        BackgroundColor3 = Theme.NotifBG,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.1, 0),
        Size = UDim2.new(0, notifW, 0, 0),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.NotifContainer
    })
    AddCorner(notif, 8)
    AddStroke(notif, color, 1, 0.5)

    Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = notif
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = color,
        TextSize = ScaleFont(16),
        ZIndex = 101,
        Parent = notif
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 6),
        Size = UDim2.new(1, -48, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 101,
        Parent = notif
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 24),
        Size = UDim2.new(1, -48, 0, 28),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 101,
        Parent = notif
    })

    local progress = Create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.4,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 102,
        Parent = notif
    })

    Tween(notif, 0.4, {Size = UDim2.new(0, notifW, 0, 58)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(progress, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        local tw = Tween(notif, 0.35, {
            Size = UDim2.new(0, notifW, 0, 0),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        if tw then
            tw.Completed:Connect(function() notif:Destroy() end)
        else
            task.delay(0.4, function() pcall(function() notif:Destroy() end) end)
        end
    end)
end

-- ═══════════════════════════════════
-- Tab System
-- ═══════════════════════════════════
function Library:AddTab(name, icon)
    icon = icon or "📋"

    local tab = {
        Name = name,
        Library = self,
        Elements = {},
    }

    local tabBtnH = math.floor(34 * (UISettings.Scale or 1))

    tab.Button = Create("TextButton", {
        Name = name,
        BackgroundColor3 = Theme.TabInactive,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, tabBtnH),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #self.Tabs,
        Parent = self.Sidebar
    })
    AddCorner(tab.Button, 7)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 22, 1, 0),
        Font = Enum.Font.Gotham,
        Text = icon,
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(14),
        Parent = tab.Button
    })

    tab.Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = tab.Button
    })

    tab.Indicator = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 0.15, 0),
        Size = UDim2.new(0, 0, 0.7, 0),
        BorderSizePixel = 0,
        Parent = tab.Button
    })
    AddCorner(tab.Indicator, 2)

    tab.Content = Create("ScrollingFrame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        BorderSizePixel = 0,
        Parent = self.ContentArea
    })
    AddPadding(tab.Content, 8, 8, 10, 10)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = tab.Content
    })

    tab.Button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then Tween(tab.Button, 0.2, {BackgroundTransparency = 0.3}) end
        PlaySound(Sounds.Hover, 0.1)
    end)
    tab.Button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then Tween(tab.Button, 0.2, {BackgroundTransparency = 0.5}) end
    end)
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
        PlaySound(Sounds.Click, 0.25)
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then task.defer(function() self:SelectTab(tab) end) end

    setmetatable(tab, {__index = Library})
    return tab
end

function Library:SelectTab(tab)
    if self.ActiveTab then
        local old = self.ActiveTab
        old.Content.Visible = false
        Tween(old.Button, 0.3, {BackgroundColor3 = Theme.TabInactive, BackgroundTransparency = 0.5})
        Tween(old.Label, 0.3, {TextColor3 = Theme.TextDark})
        Tween(old.Indicator, 0.3, {Size = UDim2.new(0, 0, 0.7, 0)})
    end

    self.ActiveTab = tab
    tab.Content.Visible = true
    Tween(tab.Button, 0.3, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85})
    Tween(tab.Label, 0.3, {TextColor3 = Theme.Text})
    Tween(tab.Indicator, 0.3, {Size = UDim2.new(0, 3, 0.7, 0)})

    -- Stagger animate children
    for i, child in ipairs(tab.Content:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundTransparency = 1
            task.delay(i * 0.025, function()
                if child and child.Parent then
                    Tween(child, 0.25, {BackgroundTransparency = 0})
                end
            end)
        end
    end
end

-- ═══════════════════════════════════
-- Element Helpers
-- ═══════════════════════════════════
local function getOrder(tab)
    local count = 0
    for _, c in pairs(tab.Content:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then count = count + 1 end
    end
    return count
end

local function elementContainer(tab, name, height)
    local container = Create("Frame", {
        Name = name,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0),
        Size = UDim2.new(1, 0, 0, math.floor(height * (UISettings.Scale or 1))),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
    AddCorner(container, UISettings.CornerRadius - 2)
    AddStroke(container, Theme.Border, 1, 0.65)
    return container
end

-- ═══════════════════════════════════
-- 1. AddSection
-- ═══════════════════════════════════
function Library.AddSection(tab, title)
    local section = Create("Frame", {
        Name = "Section_" .. title,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, math.floor(24 * (UISettings.Scale or 1))),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = string.upper(title),
        TextColor3 = Theme.TextMuted,
        TextSize = ScaleFont(10),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })

    local line = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = section
    })
    AddGradient(line, Theme.Accent, Color3.new(0, 0, 0), 0)
end

-- ═══════════════════════════════════
-- 2. AddButton
-- ═══════════════════════════════════
function Library.AddButton(tab, options)
    options = options or {}
    local name = options.Name or "Button"
    local desc = options.Description
    local callback = options.Callback or function() end

    local h = desc and 50 or 36
    local container = elementContainer(tab, "Btn_" .. name, h)

    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = container
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, desc and 5 or 0),
        Size = UDim2.new(1, -36, 0, desc and 20 or h),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 24),
            Size = UDim2.new(1, -36, 0, 16),
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = Theme.TextDark,
            TextSize = ScaleFont(10),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end

    Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "→",
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(14),
        Parent = container
    })

    btn.MouseEnter:Connect(function() Tween(container, 0.2, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6}) end)
    btn.MouseLeave:Connect(function() Tween(container, 0.2, {BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0)}) end)
    btn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click, 0.3)
        Ripple(btn)
        Tween(container, 0.08, {Size = UDim2.new(1, -4, 0, math.floor(h * (UISettings.Scale or 1)) - 2)})
        task.delay(0.08, function()
            Tween(container, 0.15, {Size = UDim2.new(1, 0, 0, math.floor(h * (UISettings.Scale or 1)))}, Enum.EasingStyle.Back)
        end)
        pcall(callback)
    end)

    return {SetText = function(_, t) for _, c in pairs(container:GetChildren()) do if c:IsA("TextLabel") and c.TextXAlignment == Enum.TextXAlignment.Left then c.Text = t; break end end end}
end

-- ═══════════════════════════════════
-- 3. AddToggle
-- ═══════════════════════════════════
function Library.AddToggle(tab, options)
    options = options or {}
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local desc = options.Description

    local h = desc and 50 or 36
    local state = default
    tab.Library.Config:Set(flag, state)

    local container = elementContainer(tab, "Tog_" .. name, h)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, desc and 5 or 0),
        Size = UDim2.new(1, -68, 0, desc and 20 or h),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 24),
            Size = UDim2.new(1, -68, 0, 16),
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = Theme.TextDark,
            TextSize = ScaleFont(10),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end

    local togBG = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 22),
        Parent = container
    })
    AddCorner(togBG, 11)

    local togCircle = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Parent = togBG
    })
    AddCorner(togCircle, 8)

    local btn = Create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = container})

    local function update(val, silent)
        state = val
        tab.Library.Config:Set(flag, state)
        Tween(togBG, 0.25, {BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff})
        Tween(togCircle, 0.25, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, Enum.EasingStyle.Back)
        if state then
            local glow = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.5,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 8, 1, 8),
                Parent = togBG
            })
            AddCorner(glow, 14)
            local tw = Tween(glow, 0.4, {BackgroundTransparency = 1, Size = UDim2.new(1, 18, 1, 18)})
            if tw then tw.Completed:Connect(function() glow:Destroy() end) end
        end
        if not silent then pcall(callback, state) end
    end

    btn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Toggle, 0.25)
        update(not state)
    end)

    local element = {
        Set = function(_, v) update(v) end,
        Get = function() return state end,
        SetText = function(_, t)
            for _, c in pairs(container:GetChildren()) do
                if c:IsA("TextLabel") and c.TextXAlignment == Enum.TextXAlignment.Left then c.Text = t; break end
            end
        end
    }
    table.insert(tab.Elements, element)
    return element
end

-- ═══════════════════════════════════
-- 4. AddSlider
-- ═══════════════════════════════════
function Library.AddSlider(tab, options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = math.clamp(options.Default or min, min, max)
    local increment = options.Increment or 1
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local suffix = options.Suffix or ""

    local value = default
    tab.Library.Config:Set(flag, value)

    local container = elementContainer(tab, "Sld_" .. name, 52)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(0.6, 0, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local valLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 4),
        Size = UDim2.new(0.4, -12, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = tostring(value) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })

    local track = Create("Frame", {
        BackgroundColor3 = Theme.SliderBar,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 6),
        Parent = container
    })
    AddCorner(track, 3)

    local initFill = (default - min) / (max - min)
    local fill = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(initFill, 0, 1, 0),
        Parent = track
    })
    AddCorner(fill, 3)
    AddGradient(fill, Theme.Accent, Theme.AccentDark, 0)

    local knob = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(initFill, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 5,
        Parent = track
    })
    AddCorner(knob, 7)
    AddStroke(knob, Theme.Accent, 2, 0)

    local dragging = false

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
        value = math.clamp(value, min, max)
        local fp = (value - min) / (max - min)
        Tween(fill, 0.08, {Size = UDim2.new(fp, 0, 1, 0)}, Enum.EasingStyle.Linear)
        Tween(knob, 0.08, {Position = UDim2.new(fp, 0, 0.5, 0)}, Enum.EasingStyle.Linear)
        valLabel.Text = tostring(value) .. suffix
        tab.Library.Config:Set(flag, value)
        pcall(callback, value)
    end

    local sliderBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 30),
        Text = "",
        ZIndex = 6,
        Parent = container
    })

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            PlaySound(Sounds.Slider, 0.1)
            Tween(knob, 0.15, {Size = UDim2.new(0, 18, 0, 18)})
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            Tween(knob, 0.15, {Size = UDim2.new(0, 14, 0, 14)})
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    local element = {
        Set = function(_, v)
            value = math.clamp(v, min, max)
            local fp = (value - min) / (max - min)
            Tween(fill, 0.3, {Size = UDim2.new(fp, 0, 1, 0)})
            Tween(knob, 0.3, {Position = UDim2.new(fp, 0, 0.5, 0)})
            valLabel.Text = tostring(value) .. suffix
            tab.Library.Config:Set(flag, value)
            pcall(callback, value)
        end,
        Get = function() return value end
    }
    table.insert(tab.Elements, element)
    return element
end

-- ═══════════════════════════════════
-- 5. AddDropdown
-- ═══════════════════════════════════
function Library.AddDropdown(tab, options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local items = options.Items or {}
    local default = options.Default
    local multi = options.Multi or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    local selected = multi and (typeof(default) == "table" and default or {}) or default
    local opened = false
    tab.Library.Config:Set(flag, selected)

    local container = Create("Frame", {
        Name = "DD_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0),
        Size = UDim2.new(1, 0, 0, math.floor(38 * (UISettings.Scale or 1))),
        ClipsDescendants = true,
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
    AddCorner(container, UISettings.CornerRadius - 2)
    AddStroke(container, Theme.Border, 1, 0.65)

    local function getDisplay()
        if multi then
            local sel = {}
            for k, v in pairs(selected) do if v then table.insert(sel, k) end end
            return #sel > 0 and table.concat(sel, ", ") or "None"
        else
            return selected or "Select..."
        end
    end

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.4, 0, 0, 38),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local selLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -32, 0, 38),
        Font = Enum.Font.Gotham,
        Text = getDisplay(),
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(11),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container
    })

    local arrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 18, 0, 38),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(9),
        Rotation = 0,
        Parent = container
    })

    local itemsFrame = Create("Frame", {
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0, 6, 0, 42),
        Size = UDim2.new(1, -12, 0, 0),
        ClipsDescendants = true,
        Parent = container
    })
    AddCorner(itemsFrame, 6)
    AddPadding(itemsFrame, 3, 3, 3, 3)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = itemsFrame
    })

    local itemBtns = {}

    local function createItem(item)
        local isSel = multi and (selected[item] or false) or (selected == item)
        local ib = Create("TextButton", {
            Name = item,
            BackgroundColor3 = isSel and Theme.Accent or Theme.Tertiary,
            BackgroundTransparency = isSel and 0.7 or 0,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.Gotham,
            Text = item,
            TextColor3 = isSel and Theme.Accent or Theme.Text,
            TextSize = ScaleFont(11),
            AutoButtonColor = false,
            Parent = itemsFrame
        })
        AddCorner(ib, 5)

        ib.MouseEnter:Connect(function() Tween(ib, 0.12, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6}) end)
        ib.MouseLeave:Connect(function()
            local s = multi and (selected[item] or false) or (selected == item)
            Tween(ib, 0.12, {BackgroundColor3 = s and Theme.Accent or Theme.Tertiary, BackgroundTransparency = s and 0.7 or 0})
        end)

        ib.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.2)
            if multi then
                selected[item] = not (selected[item] or false)
                local s = selected[item]
                ib.TextColor3 = s and Theme.Accent or Theme.Text
                Tween(ib, 0.15, {BackgroundColor3 = s and Theme.Accent or Theme.Tertiary, BackgroundTransparency = s and 0.7 or 0})
            else
                selected = item
                for _, b in pairs(itemBtns) do
                    Tween(b, 0.15, {BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0})
                    b.TextColor3 = Theme.Text
                end
                ib.TextColor3 = Theme.Accent
                Tween(ib, 0.15, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7})
                task.delay(0.12, function()
                    opened = false
                    Tween(container, 0.25, {Size = UDim2.new(1, 0, 0, math.floor(38 * (UISettings.Scale or 1)))}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    Tween(arrow, 0.25, {Rotation = 0})
                end)
            end
            selLabel.Text = getDisplay()
            tab.Library.Config:Set(flag, selected)
            pcall(callback, selected)
        end)

        table.insert(itemBtns, ib)
    end

    for _, item in ipairs(items) do createItem(item) end

    local toggleBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        ZIndex = 3,
        Parent = container
    })

    toggleBtn.MouseButton1Click:Connect(function()
        opened = not opened
        PlaySound(Sounds.Click, 0.2)
        if opened then
            local ih = #items * 30 + 8
            local total = 46 + ih
            Tween(container, 0.3, {Size = UDim2.new(1, 0, 0, math.floor(total * (UISettings.Scale or 1)))}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(arrow, 0.25, {Rotation = 180})
        else
            Tween(container, 0.25, {Size = UDim2.new(1, 0, 0, math.floor(38 * (UISettings.Scale or 1)))}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Tween(arrow, 0.25, {Rotation = 0})
        end
    end)

    return {
        Set = function(_, v) selected = v; selLabel.Text = getDisplay(); tab.Library.Config:Set(flag, selected); pcall(callback, selected) end,
        Get = function() return selected end,
        Refresh = function(_, newItems)
            items = newItems
            for _, b in pairs(itemBtns) do b:Destroy() end
            itemBtns = {}
            for _, item in ipairs(items) do createItem(item) end
            if opened then
                local ih = #items * 30 + 8
                Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, math.floor((46 + ih) * (UISettings.Scale or 1)))})
            end
        end
    }
end

-- ═══════════════════════════════════
-- 6. AddTextInput
-- ═══════════════════════════════════
function Library.AddTextInput(tab, options)
    options = options or {}
    local name = options.Name or "Input"
    local default = options.Default or ""
    local placeholder = options.Placeholder or "Type here..."
    local numeric = options.Numeric or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local finished = options.Finished or function() end

    local value = default
    tab.Library.Config:Set(flag, value)

    local container = elementContainer(tab, "Inp_" .. name, 38)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.38, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local inputBG = Create("Frame", {
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0.38, 4, 0, 5),
        Size = UDim2.new(0.62, -16, 0, 28),
        Parent = container
    })
    AddCorner(inputBG, 6)
    local inputStroke = AddStroke(inputBG, Theme.Border, 1, 0.5)

    local textBox = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.Gotham,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextMuted,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBG
    })

    textBox.Focused:Connect(function()
        PlaySound(Sounds.Click, 0.15)
        Tween(inputStroke, 0.2, {Color = Theme.Accent, Transparency = 0})
    end)
    textBox.FocusLost:Connect(function(enter)
        Tween(inputStroke, 0.2, {Color = Theme.Border, Transparency = 0.5})
        local t = textBox.Text
        if numeric then t = tonumber(t) or value; textBox.Text = tostring(t) end
        value = t
        tab.Library.Config:Set(flag, value)
        pcall(callback, value)
        if enter then pcall(finished, value) end
    end)
    if numeric then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            textBox.Text = textBox.Text:gsub("[^%d%.%-]", "")
        end)
    end

    return {
        Set = function(_, v) value = v; textBox.Text = tostring(v); tab.Library.Config:Set(flag, v) end,
        Get = function() return value end
    }
end

-- ═══════════════════════════════════
-- 7. AddKeybind
-- ═══════════════════════════════════
function Library.AddKeybind(tab, options)
    options = options or {}
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local changed = options.Changed or function() end

    local key = default
    local listening = false
    tab.Library.Config:Set(flag, key)

    local container = elementContainer(tab, "KB_" .. name, 36)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local keyBtn = Create("TextButton", {
        BackgroundColor3 = Theme.InputBG,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = key ~= Enum.KeyCode.Unknown and key.Name or "None",
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(11),
        AutoButtonColor = false,
        Parent = container
    })
    AddCorner(keyBtn, 6)
    AddStroke(keyBtn, Theme.Accent, 1, 0.5)

    keyBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click, 0.2)
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, 0.15, {BackgroundColor3 = Theme.Accent})
        keyBtn.TextColor3 = Theme.Primary
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or input.KeyCode
                keyBtn.Text = key ~= Enum.KeyCode.Unknown and key.Name or "None"
                listening = false
                Tween(keyBtn, 0.15, {BackgroundColor3 = Theme.InputBG})
                keyBtn.TextColor3 = Theme.Accent
                tab.Library.Config:Set(flag, key)
                pcall(changed, key)
            end
        elseif not processed and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
            pcall(callback)
        end
    end)

    return {
        Set = function(_, k) key = k; keyBtn.Text = k ~= Enum.KeyCode.Unknown and k.Name or "None"; tab.Library.Config:Set(flag, k) end,
        Get = function() return key end
    }
end

-- ═══════════════════════════════════
-- 8. AddColorPicker
-- ═══════════════════════════════════
function Library.AddColorPicker(tab, options)
    options = options or {}
    local name = options.Name or "Color"
    local default = options.Default or Color3.new(1, 1, 1)
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    local color = default
    local opened = false
    local h, s, v = Color3.toHSV(default)
    tab.Library.Config:Set(flag, color)

    local container = Create("Frame", {
        Name = "CP_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0),
        Size = UDim2.new(1, 0, 0, math.floor(38 * (UISettings.Scale or 1))),
        ClipsDescendants = true,
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
    AddCorner(container, UISettings.CornerRadius - 2)
    AddStroke(container, Theme.Border, 1, 0.65)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.6, 0, 0, 38),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(13),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local preview = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = color,
        Position = UDim2.new(1, -12, 0, 19),
        Size = UDim2.new(0, 36, 0, 22),
        Parent = container
    })
    AddCorner(preview, 6)
    AddStroke(preview, Color3.new(1, 1, 1), 1, 0.7)

    -- SV Picker
    local svPicker = Create("ImageLabel", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Position = UDim2.new(0, 10, 0, 44),
        Size = UDim2.new(1, -52, 0, 100),
        Image = "rbxassetid://4155801252",
        BorderSizePixel = 0,
        Parent = container
    })
    AddCorner(svPicker, 6)

    local svCursor = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 5,
        Parent = svPicker
    })
    AddCorner(svCursor, 5)
    AddStroke(svCursor, Color3.new(0, 0, 0), 2, 0)

    -- Hue Bar
    local hueBar = Create("Frame", {
        Position = UDim2.new(1, -34, 0, 44),
        Size = UDim2.new(0, 16, 0, 100),
        Parent = container
    })
    AddCorner(hueBar, 4)
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
        }),
        Rotation = 90,
        Parent = hueBar
    })

    local hueCursor = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0.5, 0, h, 0),
        Size = UDim2.new(1, 4, 0, 5),
        ZIndex = 5,
        Parent = hueBar
    })
    AddCorner(hueCursor, 2)
    AddStroke(hueCursor, Color3.new(0, 0, 0), 1, 0)

    -- Hex Input
    local hexBox = Create("TextBox", {
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0, 10, 0, 150),
        Size = UDim2.new(1, -20, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "#" .. color:ToHex(),
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(11),
        ClearTextOnFocus = true,
        Parent = container
    })
    AddCorner(hexBox, 5)

    local function updateColor()
        color = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = color
        svPicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        hexBox.Text = "#" .. color:ToHex()
        tab.Library.Config:Set(flag, color)
        pcall(callback, color)
    end

    local svDrag, hueDrag = false, false

    svPicker.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then svDrag = true end end)
    hueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hueDrag = true end end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            svDrag = false; hueDrag = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            if svDrag then
                s = math.clamp((i.Position.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((i.Position.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
                updateColor()
            end
            if hueDrag then
                h = math.clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                updateColor()
            end
        end
    end)

    hexBox.FocusLost:Connect(function()
        pcall(function()
            local hex = hexBox.Text:gsub("#", "")
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            if r and g and b then
                color = Color3.fromRGB(r, g, b)
                h, s, v = Color3.toHSV(color)
                updateColor()
            end
        end)
    end)

    local previewBtn = Create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), Text = "", ZIndex = 3, Parent = container})
    previewBtn.MouseButton1Click:Connect(function()
        opened = not opened
        PlaySound(Sounds.Click, 0.2)
        local closedH = math.floor(38 * (UISettings.Scale or 1))
        local openH = math.floor(182 * (UISettings.Scale or 1))
        Tween(container, 0.3, {Size = UDim2.new(1, 0, 0, opened and openH or closedH)}, Enum.EasingStyle.Back, opened and Enum.EasingDirection.Out or Enum.EasingDirection.In)
    end)

    return {
        Set = function(_, c) color = c; h, s, v = Color3.toHSV(c); updateColor() end,
        Get = function() return color end
    }
end

-- ═══════════════════════════════════
-- 9. AddLabel
-- ═══════════════════════════════════
function Library.AddLabel(tab, options)
    options = options or {}
    local text = options.Text or "Label"
    local desc = options.Description

    local h = desc and 44 or 30
    local container = elementContainer(tab, "Lbl", h)
    container.BackgroundTransparency = 0.4

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, desc and 3 or 0),
        Size = UDim2.new(0, 18, 0, desc and 20 or h),
        Font = Enum.Font.GothamBold,
        Text = "ℹ",
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(13),
        Parent = container
    })

    local lbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, desc and 3 or 0),
        Size = UDim2.new(1, -38, 0, desc and 20 or h),
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = container
    })

    if desc then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 22),
            Size = UDim2.new(1, -38, 0, 16),
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = Theme.TextDark,
            TextSize = ScaleFont(10),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end

    return {SetText = function(_, t) lbl.Text = t end}
end

-- ═══════════════════════════════════
-- 10. AddParagraph
-- ═══════════════════════════════════
function Library.AddParagraph(tab, options)
    options = options or {}
    local title = options.Title or "Paragraph"
    local content = options.Content or ""

    local container = Create("Frame", {
        Name = "Para_" .. title,
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
    AddCorner(container, UISettings.CornerRadius - 2)
    AddStroke(container, Theme.Border, 1, 0.65)
    AddPadding(container, 10, 10, 12, 12)

    local titleLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(14),
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = container
    })

    local contentLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Theme.TextDark,
        TextSize = ScaleFont(11),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = container
    })

    Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = container})

    return {
        SetTitle = function(_, t) titleLbl.Text = t end,
        SetContent = function(_, c) contentLbl.Text = c end
    }
end

-- ═══════════════════════════════════
-- 11. AddSeparator
-- ═══════════════════════════════════
function Library.AddSeparator(tab, text)
    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })

    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = container
    })

    if text then
        Create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Primary,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 16),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Enum.Font.GothamBold,
            Text = "  " .. text .. "  ",
            TextColor3 = Theme.TextMuted,
            TextSize = ScaleFont(10),
            Parent = container
        })
    end
end

-- ═══════════════════════════════════
-- 12. AddProgressBar
-- ═══════════════════════════════════
function Library.AddProgressBar(tab, options)
    options = options or {}
    local name = options.Name or "Progress"
    local default = options.Default or 0
    local flag = options.Flag or name

    tab.Library.Config:Set(flag, default)

    local container = elementContainer(tab, "Prog_" .. name, 46)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 4),
        Size = UDim2.new(0.65, 0, 0, 16),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local pctLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.65, 0, 0, 4),
        Size = UDim2.new(0.35, -12, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = math.floor(default * 100) .. "%",
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })

    local track = Create("Frame", {
        BackgroundColor3 = Theme.SliderBar,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -24, 0, 8),
        Parent = container
    })
    AddCorner(track, 4)

    local fill = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(default, 0, 1, 0),
        Parent = track
    })
    AddCorner(fill, 4)
    AddGradient(fill, Theme.Accent, Theme.AccentDark, 0)

    return {
        Set = function(_, val)
            val = math.clamp(val, 0, 1)
            Tween(fill, 0.4, {Size = UDim2.new(val, 0, 1, 0)})
            pctLbl.Text = math.floor(val * 100) .. "%"
            tab.Library.Config:Set(flag, val)
        end,
        Get = function() return tab.Library.Config:Get(flag) end
    }
end

-- ═══════════════════════════════════
-- 13. AddButtonRow
-- ═══════════════════════════════════
function Library.AddButtonRow(tab, options)
    options = options or {}
    local buttons = options.Buttons or {}

    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, math.floor(34 * (UISettings.Scale or 1))),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = container
    })

    local n = #buttons
    local refs = {}

    for i, info in ipairs(buttons) do
        local btn = Create("TextButton", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.55,
            Size = UDim2.new(1 / n, -(5 * (n - 1) / n), 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = info.Name or "Btn",
            TextColor3 = Theme.Text,
            TextSize = ScaleFont(12),
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = container
        })
        AddCorner(btn, 7)

        btn.MouseEnter:Connect(function() Tween(btn, 0.15, {BackgroundTransparency = 0.3}) end)
        btn.MouseLeave:Connect(function() Tween(btn, 0.15, {BackgroundTransparency = 0.55}) end)
        btn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click, 0.25)
            Ripple(btn)
            pcall(info.Callback or function() end)
        end)

        refs[info.Name or ("Btn" .. i)] = btn
    end

    return refs
end

-- ═══════════════════════════════════
-- 14. AddTextDisplay (read-only status)
-- ═══════════════════════════════════
function Library.AddTextDisplay(tab, options)
    options = options or {}
    local name = options.Name or "Status"
    local default = options.Default or "N/A"

    local container = elementContainer(tab, "TD_" .. name, 34)

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })

    local valLbl = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = default,
        TextColor3 = Theme.Accent,
        TextSize = ScaleFont(12),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })

    return {
        Set = function(_, t) valLbl.Text = tostring(t) end,
        Get = function() return valLbl.Text end
    }
end

-- ═══════════════════════════════════
-- 15. AddDivider (visual spacer)
-- ═══════════════════════════════════
function Library.AddDivider(tab, height)
    Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 6),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
end

-- ═══════════════════════════════════
-- 16. AddImage
-- ═══════════════════════════════════
function Library.AddImage(tab, options)
    options = options or {}
    local imageId = options.Image or ""
    local height = options.Height or 120

    local container = Create("Frame", {
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = math.max(UISettings.Opacity - 0.15, 0),
        Size = UDim2.new(1, 0, 0, math.floor(height * (UISettings.Scale or 1))),
        LayoutOrder = getOrder(tab),
        Parent = tab.Content
    })
    AddCorner(container, UISettings.CornerRadius - 2)
    AddStroke(container, Theme.Border, 1, 0.65)

    local img = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.new(1, -8, 1, -8),
        Image = imageId,
        ScaleType = Enum.ScaleType.Fit,
        Parent = container
    })
    AddCorner(img, UISettings.CornerRadius - 4)

    return {
        SetImage = function(_, id) img.Image = id end
    }
end

-- ═══════════════════════════════════
-- 17. AddMultiToggle (toggle group)
-- ═══════════════════════════════════
function Library.AddMultiToggle(tab, options)
    options = options or {}
    local name = options.Name or "Options"
    local items = options.Items or {}
    local defaults = options.Defaults or {}
    local flag = options.Flag or name
    local callback = options.Callback or function() end

    local states = {}
    for _, item in ipairs(items) do
        states[item] = defaults[item] or false
    end
    tab.Library.Config:Set(flag, states)

    Library.AddSection(tab, name)

    local toggleRefs = {}
    for _, item in ipairs(items) do
        local tog = Library.AddToggle(tab, {
            Name = item,
            Default = states[item],
            Flag = flag .. "_" .. item,
            Callback = function(v)
                states[item] = v
                tab.Library.Config:Set(flag, states)
                pcall(callback, states)
            end
        })
        toggleRefs[item] = tog
    end

    return {
        Set = function(_, item, val) if toggleRefs[item] then toggleRefs[item]:Set(val) end end,
        Get = function() return states end,
        GetItem = function(_, item) return states[item] end
    }
end

-- ═══════════════════════════════════
-- 18. Built-in Settings Tab
-- ═══════════════════════════════════
function Library:AddSettingsTab()
    local st = self:AddTab("Settings", "⚙")

    -- ── Appearance ──
    Library.AddSection(st, "Appearance")

    Library.AddSlider(st, {
        Name = "UI Opacity",
        Min = 0,
        Max = 100,
        Default = math.floor(UISettings.Opacity * 100),
        Increment = 5,
        Suffix = "%",
        Flag = "SET_Opacity",
        Callback = function(v)
            UISettings.Opacity = v / 100
            self:ApplyTheme()
        end
    })

    Library.AddSlider(st, {
        Name = "UI Scale",
        Min = 50,
        Max = 150,
        Default = math.floor((UISettings.Scale or 1) * 100),
        Increment = 5,
        Suffix = "%",
        Flag = "SET_Scale",
        Callback = function(v)
            UISettings.Scale = v / 100
            local newSize = GetAdaptiveSize()
            Tween(self.MainFrame, 0.4, {Size = newSize})
            SaveUISettings()
        end
    })

    Library.AddSlider(st, {
        Name = "Font Scale",
        Min = 70,
        Max = 140,
        Default = math.floor((UISettings.FontScale or 1) * 100),
        Increment = 5,
        Suffix = "%",
        Flag = "SET_FontScale",
        Callback = function(v)
            UISettings.FontScale = v / 100
            SaveUISettings()
            self:Notify("Settings", "Font scale updated. Some changes apply on next reload.", "info", 3)
        end
    })

    Library.AddSlider(st, {
        Name = "Corner Radius",
        Min = 0,
        Max = 20,
        Default = UISettings.CornerRadius,
        Increment = 1,
        Suffix = " px",
        Flag = "SET_CornerRadius",
        Callback = function(v)
            UISettings.CornerRadius = v
            SaveUISettings()
        end
    })

    Library.AddSlider(st, {
        Name = "Animation Speed",
        Min = 50,
        Max = 200,
        Default = math.floor((UISettings.AnimSpeed or 1) * 100),
        Increment = 10,
        Suffix = "%",
        Flag = "SET_AnimSpeed",
        Callback = function(v)
            UISettings.AnimSpeed = v / 100
            SaveUISettings()
        end
    })

    Library.AddSlider(st, {
        Name = "Sidebar Width",
        Min = 100,
        Max = 220,
        Default = UISettings.SidebarWidth,
        Increment = 5,
        Suffix = " px",
        Flag = "SET_SidebarWidth",
        Callback = function(v)
            UISettings.SidebarWidth = v
            SaveUISettings()
            self:Notify("Settings", "Sidebar width updated. Reload UI to apply.", "info", 3)
        end
    })

    -- ── Theme Colors ──
    Library.AddSection(st, "Theme Colors")

    Library.AddColorPicker(st, {
        Name = "Accent Color",
        Default = UISettings.AccentColor,
        Flag = "SET_AccentColor",
        Callback = function(c)
            UISettings.AccentColor = c
            Theme.Accent = c
            self:ApplyTheme()
        end
    })

    Library.AddColorPicker(st, {
        Name = "Background Color",
        Default = UISettings.BackgroundColor,
        Flag = "SET_BGColor",
        Callback = function(c)
            UISettings.BackgroundColor = c
            Theme.Primary = c
            self:ApplyTheme()
        end
    })

    Library.AddButton(st, {
        Name = "Reset Theme to Default",
        Description = "Restore all colors to their original values",
        Callback = function()
            UISettings.AccentColor = DefaultTheme.Accent
            UISettings.BackgroundColor = DefaultTheme.Primary
            UISettings.Opacity = 0.35
            UISettings.Scale = 1.0
            UISettings.FontScale = 1.0
            UISettings.CornerRadius = 10
            UISettings.AnimSpeed = 1.0
            UISettings.SidebarWidth = 150
            for k, v in pairs(DefaultTheme) do Theme[k] = v end
            self:ApplyTheme()
            self:Notify("Settings", "Theme reset to defaults", "success", 3)
        end
    })

    -- ── Controls ──
    Library.AddSection(st, "Controls")

    Library.AddToggle(st, {
        Name = "Sound Effects",
        Default = UISettings.SoundEnabled,
        Flag = "SET_Sound",
        Callback = function(v)
            UISettings.SoundEnabled = v
            SaveUISettings()
        end
    })

    Library.AddToggle(st, {
        Name = "Draggable UI",
        Default = UISettings.DragEnabled,
        Flag = "SET_Drag",
        Description = "Allow dragging the UI window",
        Callback = function(v)
            UISettings.DragEnabled = v
            self.Locked = not v
            SaveUISettings()
        end
    })

    Library.AddKeybind(st, {
        Name = "Toggle Keybind",
        Default = self.ToggleKey,
        Flag = "SET_ToggleKey",
        Changed = function(key)
            self.ToggleKey = key
            self:Notify("Settings", "Toggle key: " .. key.Name, "info", 2)
        end
    })

    -- ── Config System ──
    Library.AddSection(st, "Configuration")

    local configNameInput = Library.AddTextInput(st, {
        Name = "Config Name",
        Default = "",
        Placeholder = "Enter config name...",
        Flag = "SET_ConfigName"
    })

    Library.AddButtonRow(st, {
        Buttons = {
            {
                Name = "💾 Save",
                Callback = function()
                    local cn = self.Config:Get("SET_ConfigName")
                    if cn and cn ~= "" then
                        if self.Config:SaveConfig(cn) then
                            self:Notify("Config", 'Saved: "' .. cn .. '"', "success", 3)
                        else
                            self:Notify("Config", "Save failed (no filesystem)", "error", 3)
                        end
                    else
                        self:Notify("Config", "Enter a config name first", "warning", 3)
                    end
                end
            },
            {
                Name = "📂 Load",
                Callback = function()
                    local cn = self.Config:Get("SET_ConfigName")
                    if cn and cn ~= "" then
                        if self.Config:LoadConfig(cn) then
                            self:Notify("Config", 'Loaded: "' .. cn .. '"', "success", 3)
                        else
                            self:Notify("Config", "Config not found", "error", 3)
                        end
                    else
                        self:Notify("Config", "Enter a config name first", "warning", 3)
                    end
                end
            },
            {
                Name = "🗑 Delete",
                Callback = function()
                    local cn = self.Config:Get("SET_ConfigName")
                    if cn and cn ~= "" then
                        if self.Config:DeleteConfig(cn) then
                            self:Notify("Config", 'Deleted: "' .. cn .. '"', "success", 3)
                        else
                            self:Notify("Config", "Config not found", "error", 3)
                        end
                    end
                end
            }
        }
    })

    local cfgDropdown = Library.AddDropdown(st, {
        Name = "Saved Configs",
        Items = self.Config:GetConfigs(),
        Flag = "SET_SelectedConfig",
        Callback = function(v)
            configNameInput:Set(v)
        end
    })

    Library.AddButton(st, {
        Name = "🔄 Refresh Config List",
        Callback = function()
            cfgDropdown:Refresh(self.Config:GetConfigs())
            self:Notify("Config", "List refreshed", "info", 2)
        end
    })

    -- ── About ──
    Library.AddSection(st, "About")

    Library.AddParagraph(st, {
        Title = "📋 Script Hub UI Library v3.0",
        Content = "Features:\n"
            .. "• 18+ UI Interfaces\n"
            .. "• Config Save/Load/Delete\n"
            .. "• Theme Customization (Colors, Opacity, Scale)\n"
            .. "• Mobile Support (Touch + Floating Buttons)\n"
            .. "• Screen Adaptive Layout\n"
            .. "• Sound Effects & Smooth Animations\n"
            .. "• Notification System (4 types)\n"
            .. "\nPlatform: " .. (IsMobile() and "📱 Mobile" or "💻 Desktop")
            .. "\nScreen: " .. math.floor(GetScreenSize().X) .. "x" .. math.floor(GetScreenSize().Y)
    })

    Library.AddButton(st, {
        Name = "🔴 Destroy UI",
        Description = "Completely remove the UI from the game",
        Callback = function()
            self:Destroy()
        end
    })

    return st
end

return Library
