--[[
    ================================================================================
    LogQuick_UI_Lib.lua
    ================================================================================
    Roblox 注入器通用单文件高级 UI 框架库
    
    作者: Log_quick (不可更改)
    支持: 手机端 (触屏自适应与触控响应) / 电脑端 (固定标准高分辨率尺寸)
    风格: 现代极简流线玻璃质感、炫彩发光边框、高级开屏 Splash 载入动画、全清脆声效
    
    【核心接口清单】
    - 窗口与设置: CreateWindow, SetTitle, BuildSettingsTab, SaveConfig, LoadConfig, SetBackground, SetScriptAuthor
    - 功能再分区: AddTab -> AddSection -> AddSubSection
    - 核心 UI 控件: AddButton, AddToggle, AddSlider, AddHSVPicker, AddDropdown, AddInput, AddKeybind, AddLabel, AddPlayerSelector, AddImage, AddStatus
    - 高级拓展工具: Notify (通知), CreateSearch (关键字搜索), CreateKeySystem (卡密验证), ToggleStats (FPS/Ping悬浮窗), SetWatermark (水印挂件)
    ================================================================================
]]

local LogQuickUI = {}
local Library = LogQuickUI

-- ============================================================
-- [1] Services & Environment Compatibility Layer
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local StatsService = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 10)

-- 挂载节点判定 (gethui > RobloxGui > CoreGui > PlayerGui)
local TargetParent = nil
if gethui then
    TargetParent = gethui()
elseif CoreGui and CoreGui:FindFirstChild("RobloxGui") then
    TargetParent = CoreGui.RobloxGui
elseif CoreGui then
    TargetParent = CoreGui
else
    TargetParent = PlayerGui
end

-- 识别注入器/执行器名称
local function GetExecutorName()
    if identifyexecutor then
        local name, version = identifyexecutor()
        return tostring(name) .. (version and (" " .. tostring(version)) or "")
    elseif getexecutorname then
        return tostring(getexecutorname())
    elseif Synapse then return "Synapse X"
    elseif KRNL_LOADED then return "Krnl"
    elseif Fluxus then return "Fluxus"
    elseif Delta then return "Delta"
    elseif Wave then return "Wave"
    elseif Solara then return "Solara"
    elseif Celery then return "Celery"
    elseif Hydrogen then return "Hydrogen"
    elseif Codex then return "Codex"
    end
    return "通用注入器 (Executor)"
end

-- 设备检测与自适应（手机端自适应放大触控域，电脑端保持标准 fixed 布局）
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if not IsMobile and UserInputService.TouchEnabled then
    IsMobile = true
end

local ItemHeight = IsMobile and 42 or 34
local FontBaseSize = IsMobile and 15 or 13
local HeaderFontSize = IsMobile and 17 or 15

-- ============================================================
-- [2] Theme Palette System
-- ============================================================
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18, 18, 24),
        BackgroundSecondary = Color3.fromRGB(26, 26, 36),
        Surface = Color3.fromRGB(34, 34, 46),
        SurfaceLight = Color3.fromRGB(48, 48, 64),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(160, 160, 185),
        Accent = Color3.fromRGB(130, 100, 255),
        Border = Color3.fromRGB(55, 55, 75),
        BorderAccent = Color3.fromRGB(145, 115, 255),
        Success = Color3.fromRGB(60, 210, 130),
        Warning = Color3.fromRGB(255, 180, 50),
        Danger = Color3.fromRGB(240, 75, 90),
    },
    Light = {
        Background = Color3.fromRGB(245, 246, 250),
        BackgroundSecondary = Color3.fromRGB(232, 234, 242),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceLight = Color3.fromRGB(222, 225, 238),
        Text = Color3.fromRGB(25, 28, 40),
        TextMuted = Color3.fromRGB(110, 115, 135),
        Accent = Color3.fromRGB(100, 80, 230),
        Border = Color3.fromRGB(205, 210, 225),
        BorderAccent = Color3.fromRGB(120, 100, 245),
        Success = Color3.fromRGB(40, 180, 100),
        Warning = Color3.fromRGB(230, 150, 20),
        Danger = Color3.fromRGB(230, 50, 70),
    },
    Cyberpunk = {
        Background = Color3.fromRGB(13, 11, 24),
        BackgroundSecondary = Color3.fromRGB(22, 18, 42),
        Surface = Color3.fromRGB(30, 22, 56),
        SurfaceLight = Color3.fromRGB(48, 35, 88),
        Text = Color3.fromRGB(0, 240, 255),
        TextMuted = Color3.fromRGB(180, 140, 220),
        Accent = Color3.fromRGB(255, 0, 128),
        Border = Color3.fromRGB(80, 30, 110),
        BorderAccent = Color3.fromRGB(255, 0, 180),
        Success = Color3.fromRGB(0, 255, 170),
        Warning = Color3.fromRGB(255, 215, 0),
        Danger = Color3.fromRGB(255, 40, 80),
    },
    Emerald = {
        Background = Color3.fromRGB(11, 24, 18),
        BackgroundSecondary = Color3.fromRGB(18, 40, 30),
        Surface = Color3.fromRGB(24, 54, 40),
        SurfaceLight = Color3.fromRGB(36, 78, 58),
        Text = Color3.fromRGB(236, 253, 245),
        TextMuted = Color3.fromRGB(130, 190, 160),
        Accent = Color3.fromRGB(16, 185, 129),
        Border = Color3.fromRGB(35, 80, 60),
        BorderAccent = Color3.fromRGB(52, 211, 153),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(239, 68, 68),
    },
    Sunset = {
        Background = Color3.fromRGB(26, 15, 26),
        BackgroundSecondary = Color3.fromRGB(43, 22, 44),
        Surface = Color3.fromRGB(60, 30, 60),
        SurfaceLight = Color3.fromRGB(85, 42, 85),
        Text = Color3.fromRGB(255, 247, 237),
        TextMuted = Color3.fromRGB(210, 160, 190),
        Accent = Color3.fromRGB(249, 115, 22),
        Border = Color3.fromRGB(90, 45, 80),
        BorderAccent = Color3.fromRGB(251, 146, 60),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(234, 179, 8),
        Danger = Color3.fromRGB(239, 68, 68),
    },
    Midnight = {
        Background = Color3.fromRGB(11, 14, 23),
        BackgroundSecondary = Color3.fromRGB(21, 27, 43),
        Surface = Color3.fromRGB(28, 36, 58),
        SurfaceLight = Color3.fromRGB(42, 54, 85),
        Text = Color3.fromRGB(240, 246, 255),
        TextMuted = Color3.fromRGB(140, 160, 195),
        Accent = Color3.fromRGB(59, 130, 246),
        Border = Color3.fromRGB(45, 60, 95),
        BorderAccent = Color3.fromRGB(96, 165, 250),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
    },
}

local ThemeColors = Themes.Dark

-- ============================================================
-- [3] Config Storage (JSON Serialization)
-- ============================================================
local ConfigFolder = "LogQuickStorage"
local ConfigFile = ConfigFolder .. "/LogQuickUI_Config.json"

local Saved = {
    WindowPosition = UDim2.new(0.5, -280, 0.5, -220),
    WindowSize = UDim2.new(0, 560, 0, 440),
    Transparency = 1.0,
    BorderColorMode = "Pulse", -- Static, Rainbow, Breathing, Pulse
    BorderColorHSV = { H = 0.72, S = 0.65, V = 1.0 },
    ThemeName = "Dark",
    SizeScale = 1.0,
    BackgroundImage = "",
    BackgroundTransparency = 0.3,
    SoundEnabled = true,
    SoundVolume = 0.5,
    SoundId = "rbxassetid://9115297988",
    FloatingStatusEnabled = true,
    ScriptAuthor = "开发者",
    ConfigData = {},
}

local function SaveConfig()
    if writefile and HttpService then
        pcall(function()
            if isfolder and not isfolder(ConfigFolder) and makefolder then
                makefolder(ConfigFolder)
            end
            local saveTable = {
                WindowPosition = { Saved.WindowPosition.X.Scale, Saved.WindowPosition.X.Offset, Saved.WindowPosition.Y.Scale, Saved.WindowPosition.Y.Offset },
                WindowSize = { Saved.WindowSize.X.Scale, Saved.WindowSize.X.Offset, Saved.WindowSize.Y.Scale, Saved.WindowSize.Y.Offset },
                Transparency = Saved.Transparency,
                BorderColorMode = Saved.BorderColorMode,
                BorderColorHSV = Saved.BorderColorHSV,
                ThemeName = Saved.ThemeName,
                SizeScale = Saved.SizeScale,
                BackgroundImage = Saved.BackgroundImage,
                BackgroundTransparency = Saved.BackgroundTransparency,
                SoundEnabled = Saved.SoundEnabled,
                SoundVolume = Saved.SoundVolume,
                SoundId = Saved.SoundId,
                FloatingStatusEnabled = Saved.FloatingStatusEnabled,
                ScriptAuthor = Saved.ScriptAuthor,
                ConfigData = Saved.ConfigData,
            }
            writefile(ConfigFile, HttpService:JSONEncode(saveTable))
        end)
    end
end

local function LoadConfig()
    if readfile and HttpService then
        pcall(function()
            if isfile and isfile(ConfigFile) then
                local raw = readfile(ConfigFile)
                local decoded = HttpService:JSONDecode(raw)
                if decoded then
                    if decoded.WindowPosition then
                        Saved.WindowPosition = UDim2.new(decoded.WindowPosition[1], decoded.WindowPosition[2], decoded.WindowPosition[3], decoded.WindowPosition[4])
                    end
                    if decoded.WindowSize then
                        Saved.WindowSize = UDim2.new(decoded.WindowSize[1], decoded.WindowSize[2], decoded.WindowSize[3], decoded.WindowSize[4])
                    end
                    if decoded.Transparency ~= nil then Saved.Transparency = decoded.Transparency end
                    if decoded.BorderColorMode ~= nil then Saved.BorderColorMode = decoded.BorderColorMode end
                    if decoded.BorderColorHSV ~= nil then Saved.BorderColorHSV = decoded.BorderColorHSV end
                    if decoded.ThemeName ~= nil then Saved.ThemeName = decoded.ThemeName end
                    if decoded.SizeScale ~= nil then Saved.SizeScale = decoded.SizeScale end
                    if decoded.BackgroundImage ~= nil then Saved.BackgroundImage = decoded.BackgroundImage end
                    if decoded.BackgroundTransparency ~= nil then Saved.BackgroundTransparency = decoded.BackgroundTransparency end
                    if decoded.SoundEnabled ~= nil then Saved.SoundEnabled = decoded.SoundEnabled end
                    if decoded.SoundVolume ~= nil then Saved.SoundVolume = decoded.SoundVolume end
                    if decoded.SoundId ~= nil then Saved.SoundId = decoded.SoundId end
                    if decoded.FloatingStatusEnabled ~= nil then Saved.FloatingStatusEnabled = decoded.FloatingStatusEnabled end
                    if decoded.ScriptAuthor ~= nil then Saved.ScriptAuthor = decoded.ScriptAuthor end
                    if decoded.ConfigData ~= nil then Saved.ConfigData = decoded.ConfigData end
                end
            end
        end)
    end
end

LoadConfig()

-- 拖拽坐标限制在屏幕内 (Clamp Window Boundaries)
local function ClampWindowPosition(pos, winSize)
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local sizeX = winSize.X.Offset
    local sizeY = winSize.Y.Offset

    local absX = pos.X.Scale * viewport.X + pos.X.Offset
    local absY = pos.Y.Scale * viewport.Y + pos.Y.Offset

    local minX = 10
    local maxX = math.max(minX, viewport.X - sizeX - 10)
    local minY = 10
    local maxY = math.max(minY, viewport.Y - 50)

    local clampedX = math.clamp(absX, minX, maxX)
    local clampedY = math.clamp(absY, minY, maxY)

    return UDim2.new(0, clampedX, 0, clampedY)
end

-- ============================================================
-- [4] Crisp Sound Engine
-- ============================================================
local Sounds = {
    Click = "rbxassetid://9115297988",
    Toggle = "rbxassetid://6003308824",
    Chime = "rbxassetid://4590662766",
    Slider = "rbxassetid://9119713951",
    Success = "rbxassetid://130707418",
}

local function PlaySound(soundId)
    if not Saved.SoundEnabled then return end
    local id = soundId or Saved.SoundId or Sounds.Click
    task.spawn(function()
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = id
            sound.Volume = Saved.SoundVolume or 0.5
            sound.PlaybackSpeed = 1.05 + math.random() * 0.08
            sound.Parent = SoundService
            sound:Play()
            sound.Ended:Connect(function() sound:Destroy() end)
            task.delay(3, function() if sound and sound.Parent then sound:Destroy() end end)
        end)
    end)
end

Library.PlaySound = PlaySound
Library.SetSoundEnabled = function(val) Saved.SoundEnabled = val; SaveConfig() end
Library.SetSoundVolume = function(vol) Saved.SoundVolume = vol; SaveConfig() end
Library.SetSoundId = function(id) Saved.SoundId = id; SaveConfig() end

-- ============================================================
-- [5] Color Math & Dynamic Rainbow/Breathing/Pulse Animation
-- ============================================================
local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs(((h * 6) % 2) - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 1/6 then r, g, b = c, x, 0
    elseif h < 2/6 then r, g, b = x, c, 0
    elseif h < 3/6 then r, g, b = 0, c, x
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return Color3.new(r + m, g + m, b + m)
end

local function RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local maxVal = math.max(r, g, b)
    local minVal = math.min(r, g, b)
    local delta = maxVal - minVal
    local h, s, v = 0, 0, maxVal
    if delta ~= 0 then
        s = delta / maxVal
        if maxVal == r then h = ((g - b) / delta) % 6
        elseif maxVal == g then h = ((b - r) / delta) + 2
        else h = ((r - g) / delta) + 4 end
        h = h / 6
    end
    return h, s, v
end

local RainbowPhase = 0
local function GetCurrentBorderColor()
    if Saved.BorderColorMode == "Rainbow" then
        RainbowPhase = (RainbowPhase + 0.005) % 1
        local s = Saved.BorderColorHSV and Saved.BorderColorHSV.S or 0.8
        local v = Saved.BorderColorHSV and Saved.BorderColorHSV.V or 1.0
        return HSVToRGB(RainbowPhase, s, v)
    elseif Saved.BorderColorMode == "Breathing" then
        local base = HSVToRGB(Saved.BorderColorHSV.H or 0.7, Saved.BorderColorHSV.S or 0.7, Saved.BorderColorHSV.V or 1.0)
        local t = (math.sin(os.clock() * 3) + 1) / 2
        return base:Lerp(Color3.fromRGB(255, 255, 255), t * 0.35)
    elseif Saved.BorderColorMode == "Pulse" then
        local base = HSVToRGB(Saved.BorderColorHSV.H or 0.7, Saved.BorderColorHSV.S or 0.7, Saved.BorderColorHSV.V or 1.0)
        local t = (math.sin(os.clock() * 6) + 1) / 2
        return base:Lerp(ThemeColors.Accent, t * 0.5)
    else
        return HSVToRGB(Saved.BorderColorHSV.H or 0.7, Saved.BorderColorHSV.S or 0.7, Saved.BorderColorHSV.V or 1.0)
    end
end

-- ============================================================
-- [6] Base Helper Creators
-- ============================================================
local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or ThemeColors.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function CreatePadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 4)
    p.PaddingBottom = UDim.new(0, bottom or 4)
    p.PaddingLeft = UDim.new(0, left or 8)
    p.PaddingRight = UDim.new(0, right or 8)
    p.Parent = parent
    return p
end

local function MakeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.Name = props.Name or "TextLabel"
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 22)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = props.BackgroundTransparency or 1
    lbl.BackgroundColor3 = props.BackgroundColor3 or ThemeColors.Surface
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or ThemeColors.Text
    lbl.TextSize = props.TextSize or FontBaseSize
    lbl.Font = props.Font or Enum.Font.GothamMedium
    lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.ZIndex = props.ZIndex or 5
    lbl.Parent = parent
    if props.TextWrapped then lbl.TextWrapped = true end
    return lbl
end

-- ============================================================
-- [7] Window & Layout Constructor
-- ============================================================
local MainWindow = nil
local RootScreenGui = nil
local MainFrame = nil
local BackgroundImageLabel = nil
local SearchInputBox = nil
local CurrentTabObj = nil
local TabsList = {}

function Library:CreateWindow(opts)
    opts = opts or {}
    local titleText = opts.Title or "LogQuick Script Center"
    local subtitleText = opts.Subtitle or "UI Library · 作者: Log_quick"
    local windowSize = opts.Size or Saved.WindowSize
    local windowPos = opts.Position or Saved.WindowPosition

    if opts.ScriptAuthor then Saved.ScriptAuthor = opts.ScriptAuthor end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LogQuickUI_Root"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = TargetParent
    RootScreenGui = screenGui

    -- [Splash 开屏载入动画]
    local splashFrame = Instance.new("Frame")
    splashFrame.Name = "SplashLoader"
    splashFrame.Size = UDim2.new(0, 320, 0, 180)
    splashFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
    splashFrame.BackgroundColor3 = ThemeColors.Background
    splashFrame.BorderSizePixel = 0
    splashFrame.ZIndex = 1000
    splashFrame.Parent = screenGui
    CreateCorner(splashFrame, 14)
    CreateStroke(splashFrame, ThemeColors.Accent, 2)

    MakeLabel(splashFrame, {
        Size = UDim2.new(1, -30, 0, 28),
        Position = UDim2.new(0, 15, 0, 25),
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextSize = FontBaseSize + 4,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    MakeLabel(splashFrame, {
        Size = UDim2.new(1, -30, 0, 20),
        Position = UDim2.new(0, 15, 0, 55),
        Text = "正在加载 UI 引擎与依赖框架...",
        TextColor3 = ThemeColors.TextMuted,
        TextSize = FontBaseSize - 1,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local progressBarBg = Instance.new("Frame")
    progressBarBg.Size = UDim2.new(1, -40, 0, 8)
    progressBarBg.Position = UDim2.new(0, 20, 1, -45)
    progressBarBg.BackgroundColor3 = ThemeColors.Surface
    progressBarBg.BorderSizePixel = 0
    progressBarBg.ZIndex = 1001
    progressBarBg.Parent = splashFrame
    CreateCorner(progressBarBg, 4)

    local progressBarFill = Instance.new("Frame")
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = ThemeColors.Accent
    progressBarFill.BorderSizePixel = 0
    progressBarFill.ZIndex = 1002
    progressBarFill.Parent = progressBarBg
    CreateCorner(progressBarFill, 4)

    PlaySound(Sounds.Chime)
    TweenService:Create(progressBarFill, TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()

    task.wait(0.88)

    -- 主窗口框架
    local win = Instance.new("Frame")
    win.Name = "MainWindow"
    win.Size = windowSize
    win.Position = windowPos
    win.BackgroundColor3 = ThemeColors.Background
    win.BackgroundTransparency = 1 - Saved.Transparency
    win.BorderSizePixel = 0
    win.ZIndex = 10
    win.ClipsDescendants = true
    win.Parent = screenGui
    CreateCorner(win, 12)
    local winStroke = CreateStroke(win, GetCurrentBorderColor(), 2)

    -- 背景图层
    local bgImg = Instance.new("ImageLabel")
    bgImg.Name = "CustomBackground"
    bgImg.Size = UDim2.new(1, 0, 1, 0)
    bgImg.BackgroundTransparency = 1
    bgImg.Image = Saved.BackgroundImage or ""
    bgImg.ImageTransparency = Saved.BackgroundTransparency or 0.3
    bgImg.ScaleType = Enum.ScaleType.Crop
    bgImg.ZIndex = 11
    bgImg.Parent = win
    BackgroundImageLabel = bgImg

    -- Header 标题栏
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = ThemeColors.Surface
    header.BorderSizePixel = 0
    header.ZIndex = 20
    header.Parent = win
    CreateCorner(header, 12)

    MakeLabel(header, {
        Name = "HeaderTitle",
        Size = UDim2.new(0.6, -10, 0, 22),
        Position = UDim2.new(0, 14, 0, 4),
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextSize = HeaderFontSize,
    })

    MakeLabel(header, {
        Name = "HeaderSub",
        Size = UDim2.new(0.6, -10, 0, 16),
        Position = UDim2.new(0, 14, 0, 24),
        Text = subtitleText,
        TextColor3 = ThemeColors.TextMuted,
        TextSize = FontBaseSize - 2,
    })

    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = ThemeColors.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = FontBaseSize
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 22
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    CreateCorner(closeBtn, 8)

    closeBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        TweenService:Create(win, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, windowSize.X.Offset, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.wait(0.28)
        screenGui:Destroy()
    end)

    -- 最小化按钮
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinBtn"
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -70, 0, 8)
    minBtn.BackgroundColor3 = ThemeColors.SurfaceLight
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = ThemeColors.Text
    minBtn.TextSize = FontBaseSize
    minBtn.Font = Enum.Font.GothamBold
    minBtn.ZIndex = 22
    minBtn.AutoButtonColor = false
    minBtn.Parent = header
    CreateCorner(minBtn, 8)

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, windowSize.X.Offset, 0, 44)
            }):Play()
        else
            TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = windowSize
            }):Play()
        end
    end)

    -- 拖拽移动与屏幕限制
    local dragging = false
    local dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local rawPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            local clamped = ClampWindowPosition(rawPos, win.Size)
            win.Position = clamped
            Saved.WindowPosition = clamped
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                SaveConfig()
            end
        end
    end)

    -- 窗口主体 Body Frame
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, -16, 1, -56)
    bodyFrame.Position = UDim2.new(0, 8, 0, 48)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.ZIndex = 15
    bodyFrame.Parent = win

    -- 标签栏 (Tab 导航)
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.Size = IsMobile and UDim2.new(1, 0, 0, 36) or UDim2.new(0, 130, 1, 0)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = ThemeColors.Surface
    tabBar.BackgroundTransparency = 0.2
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 2
    tabBar.ScrollBarImageColor3 = ThemeColors.Accent
    tabBar.ZIndex = 16
    tabBar.Parent = bodyFrame
    CreateCorner(tabBar, 8)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = IsMobile and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar
    CreatePadding(tabBar, 4, 4, 4, 4)

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if IsMobile then
            tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
        else
            tabBar.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
        end
    end)

    -- 内容容器 Pages
    local pagesContainer = Instance.new("Frame")
    pagesContainer.Name = "PagesContainer"
    pagesContainer.Size = IsMobile and UDim2.new(1, 0, 1, -42) or UDim2.new(1, -138, 1, 0)
    pagesContainer.Position = IsMobile and UDim2.new(0, 0, 0, 42) or UDim2.new(0, 138, 0, 0)
    pagesContainer.BackgroundTransparency = 1
    pagesContainer.ZIndex = 16
    pagesContainer.Parent = bodyFrame

    MainWindow = win
    MainFrame = win

    -- 淡出 Splash Loader，展示主 UI
    splashFrame:Destroy()
    win.Size = UDim2.new(0, windowSize.X.Offset, 0, 0)
    win.Position = UDim2.new(windowPos.X.Scale, windowPos.X.Offset, windowPos.Y.Scale, windowPos.Y.Offset + 30)
    TweenService:Create(win, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = windowSize,
        Position = windowPos,
    }):Play()

    -- 循环发光边框更新
    task.spawn(function()
        while screenGui and screenGui.Parent do
            task.wait(0.02)
            if winStroke and winStroke.Parent then
                winStroke.Color = GetCurrentBorderColor()
            end
        end
    end)

    screenGui.AncestryChanged:Connect(function()
        if not screenGui.Parent then MainWindow = nil end
    end)

    return win
end

-- 动态标题修改 API
function Library:SetTitle(title, subtitle)
    if MainWindow then
        local header = MainWindow:FindFirstChild("Header", true)
        if header then
            local tLbl = header:FindFirstChild("HeaderTitle")
            local sLbl = header:FindFirstChild("HeaderSub")
            if tLbl and title then tLbl.Text = title end
            if sLbl and subtitle then sLbl.Text = subtitle end
        end
    end
end

-- ============================================================
-- [8] Component System (Tab -> Section -> SubSection)
-- ============================================================
function Library:AddTab(opts)
    opts = opts or {}
    local tabName = opts.Name or ("Tab_" .. tostring(#TabsList + 1))
    local tabTitle = opts.Title or opts.Name or "功能标签"
    local iconId = opts.Icon or nil

    local bodyFrame = MainWindow:FindFirstChild("Body", true)
    local tabBar = bodyFrame:FindFirstChild("TabBar")
    local pagesContainer = bodyFrame:FindFirstChild("PagesContainer")

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "_Btn"
    tabBtn.Size = IsMobile and UDim2.new(0, 95, 1, 0) or UDim2.new(1, 0, 0, 34)
    tabBtn.BackgroundColor3 = ThemeColors.SurfaceLight
    tabBtn.BackgroundTransparency = 0.8
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = (iconId and "  " or "") .. tabTitle
    tabBtn.TextColor3 = ThemeColors.TextMuted
    tabBtn.TextSize = FontBaseSize - 1
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextTruncate = Enum.TextTruncate.AtEnd
    tabBtn.AutoButtonColor = false
    tabBtn.ZIndex = 18
    tabBtn.Parent = tabBar
    CreateCorner(tabBtn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = ThemeColors.Accent
    page.Visible = false
    page.ZIndex = 17
    page.Parent = pagesContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    CreatePadding(page, 2, 8, 2, 4)

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 16)
    end)

    local tabObj = {
        Name = tabName,
        Title = tabTitle,
        Button = tabBtn,
        Page = page,
        Sections = {},
    }

    local function ActivateTab()
        PlaySound(Sounds.Click)
        for _, t in ipairs(TabsList) do
            t.Button.TextColor3 = ThemeColors.TextMuted
            t.Button.BackgroundTransparency = 0.8
            t.Button.BackgroundColor3 = ThemeColors.SurfaceLight
            t.Page.Visible = false
        end
        tabBtn.TextColor3 = ThemeColors.Text
        tabBtn.BackgroundTransparency = 0
        tabBtn.BackgroundColor3 = ThemeColors.Accent
        page.Visible = true
        CurrentTabObj = tabObj
    end

    tabBtn.MouseButton1Click:Connect(ActivateTab)

    if #TabsList == 0 then ActivateTab() end

    table.insert(TabsList, tabObj)

    -- 通用控件附加方法实现
    local function AttachComponents(containerFrame)
        local compAPI = {}

        function compAPI:AddButton(p)
            p = p or {}
            local btnFrame = Instance.new("TextButton")
            btnFrame.Name = "Button_" .. (p.Text or "Btn")
            btnFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            btnFrame.BackgroundColor3 = p.BackgroundColor3 or ThemeColors.SurfaceLight
            btnFrame.BorderSizePixel = 0
            btnFrame.Text = p.Text or "点击按钮"
            btnFrame.TextColor3 = ThemeColors.Text
            btnFrame.TextSize = FontBaseSize
            btnFrame.Font = Enum.Font.GothamSemibold
            btnFrame.AutoButtonColor = false
            btnFrame.ZIndex = 20
            btnFrame.Parent = containerFrame
            CreateCorner(btnFrame, 6)

            btnFrame.MouseEnter:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.15), { BackgroundColor3 = ThemeColors.Accent }):Play()
            end)
            btnFrame.MouseLeave:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.15), { BackgroundColor3 = p.BackgroundColor3 or ThemeColors.SurfaceLight }):Play()
            end)
            btnFrame.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                if p.Callback then pcall(p.Callback) end
            end)
            return btnFrame
        end

        function compAPI:AddToggle(p)
            p = p or {}
            local state = p.Default == true
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = "Toggle_" .. (p.Text or "Tgl")
            toggleFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            toggleFrame.BackgroundColor3 = ThemeColors.Surface
            toggleFrame.BorderSizePixel = 0
            toggleFrame.ZIndex = 20
            toggleFrame.Parent = containerFrame
            CreateCorner(toggleFrame, 6)

            MakeLabel(toggleFrame, {
                Size = UDim2.new(0.7, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Text = p.Text or "开关选项",
            })

            local switchBg = Instance.new("TextButton")
            switchBg.Name = "Switch"
            switchBg.Size = UDim2.new(0, 42, 0, 22)
            switchBg.Position = UDim2.new(1, -50, 0.5, -11)
            switchBg.BackgroundColor3 = state and ThemeColors.Success or ThemeColors.Border
            switchBg.BorderSizePixel = 0
            switchBg.Text = ""
            switchBg.AutoButtonColor = false
            switchBg.ZIndex = 21
            switchBg.Parent = toggleFrame
            CreateCorner(switchBg, 11)

            local knob = Instance.new("Frame")
            knob.Name = "Knob"
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 22
            knob.Parent = switchBg
            CreateCorner(knob, 8)

            local function UpdateSwitch(val)
                state = val
                PlaySound(Sounds.Toggle)
                if state then
                    TweenService:Create(switchBg, TweenInfo.new(0.2), { BackgroundColor3 = ThemeColors.Success }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), { Position = UDim2.new(1, -19, 0.5, -8) }):Play()
                else
                    TweenService:Create(switchBg, TweenInfo.new(0.2), { BackgroundColor3 = ThemeColors.Border }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2), { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
                end
                if p.Callback then pcall(p.Callback, state) end
            end

            switchBg.MouseButton1Click:Connect(function() UpdateSwitch(not state) end)

            return toggleFrame, state, function(nState) UpdateSwitch(nState) end
        end

        function compAPI:AddSlider(p)
            p = p or {}
            local minVal = p.Min or 0
            local maxVal = p.Max or 100
            local defaultVal = math.clamp(p.Default or minVal, minVal, maxVal)
            local currentVal = defaultVal
            local roundStep = p.Rounding or 1
            local unitStr = p.Unit or ""

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = "Slider_" .. (p.Text or "Sld")
            sliderFrame.Size = UDim2.new(1, 0, 0, ItemHeight + 14)
            sliderFrame.BackgroundColor3 = ThemeColors.Surface
            sliderFrame.BorderSizePixel = 0
            sliderFrame.ZIndex = 20
            sliderFrame.Parent = containerFrame
            CreateCorner(sliderFrame, 6)

            MakeLabel(sliderFrame, {
                Size = UDim2.new(0.65, 0, 0, 20),
                Position = UDim2.new(0, 10, 0, 4),
                Text = p.Text or "数值调节",
            })

            local valLbl = MakeLabel(sliderFrame, {
                Size = UDim2.new(0.3, 0, 0, 20),
                Position = UDim2.new(0.7, -10, 0, 4),
                Text = tostring(currentVal) .. unitStr,
                TextColor3 = ThemeColors.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = Enum.Font.GothamBold,
            })

            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -20, 0, 8)
            track.Position = UDim2.new(0, 10, 1, -14)
            track.BackgroundColor3 = ThemeColors.Border
            track.BorderSizePixel = 0
            track.Text = ""
            track.AutoButtonColor = false
            track.ZIndex = 21
            track.Parent = sliderFrame
            CreateCorner(track, 4)

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
            fill.BackgroundColor3 = ThemeColors.Accent
            fill.BorderSizePixel = 0
            fill.ZIndex = 22
            fill.Parent = track
            CreateCorner(fill, 4)

            local thumb = Instance.new("Frame")
            thumb.Name = "Thumb"
            thumb.Size = UDim2.new(0, 14, 0, 14)
            thumb.Position = UDim2.new(1, -7, 0.5, -7)
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thumb.BorderSizePixel = 0
            thumb.ZIndex = 23
            thumb.Parent = fill
            CreateCorner(thumb, 7)

            local isDragging = false
            local function UpdateSliderInput(inputX)
                local absPos = track.AbsolutePosition.X
                local absSize = track.AbsoluteSize.X
                local ratio = math.clamp((inputX - absPos) / absSize, 0, 1)
                local rawVal = minVal + ratio * (maxVal - minVal)
                currentVal = math.round(rawVal / roundStep) * roundStep
                currentVal = math.clamp(currentVal, minVal, maxVal)

                fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
                valLbl.Text = tostring(currentVal) .. unitStr

                if p.Callback then pcall(p.Callback, currentVal) end
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    PlaySound(Sounds.Slider)
                    UpdateSliderInput(i.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSliderInput(i.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)

            return sliderFrame
        end

        function compAPI:AddHSVPicker(p)
            p = p or {}
            local curColor = p.Default or Color3.fromRGB(255, 0, 0)
            local curH, curS, curV = RGBToHSV(curColor)

            local pickerFrame = Instance.new("Frame")
            pickerFrame.Name = "HSVPicker_" .. (p.Text or "Clr")
            pickerFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            pickerFrame.BackgroundColor3 = ThemeColors.Surface
            pickerFrame.BorderSizePixel = 0
            pickerFrame.ClipsDescendants = true
            pickerFrame.ZIndex = 20
            pickerFrame.Parent = containerFrame
            CreateCorner(pickerFrame, 6)

            MakeLabel(pickerFrame, {
                Size = UDim2.new(0.6, 0, 0, ItemHeight),
                Position = UDim2.new(0, 10, 0, 0),
                Text = p.Text or "自定义颜色",
            })

            local previewBtn = Instance.new("TextButton")
            previewBtn.Name = "Preview"
            previewBtn.Size = UDim2.new(0, 36, 0, 22)
            previewBtn.Position = UDim2.new(1, -46, 0, (ItemHeight - 22) / 2)
            previewBtn.BackgroundColor3 = curColor
            previewBtn.BorderSizePixel = 0
            previewBtn.Text = ""
            previewBtn.AutoButtonColor = false
            previewBtn.ZIndex = 21
            previewBtn.Parent = pickerFrame
            CreateCorner(previewBtn, 6)

            local expandPanel = Instance.new("Frame")
            expandPanel.Name = "ExpandPanel"
            expandPanel.Size = UDim2.new(1, -20, 0, 110)
            expandPanel.Position = UDim2.new(0, 10, 0, ItemHeight + 4)
            expandPanel.BackgroundTransparency = 1
            expandPanel.ZIndex = 22
            expandPanel.Parent = pickerFrame

            local canvas = Instance.new("ImageLabel")
            canvas.Name = "Canvas"
            canvas.Size = UDim2.new(0, 110, 0, 100)
            canvas.Position = UDim2.new(0, 0, 0, 0)
            canvas.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            canvas.BorderSizePixel = 0
            canvas.Image = "rbxassetid://4155801252"
            canvas.ZIndex = 23
            canvas.Parent = expandPanel
            CreateCorner(canvas, 6)

            local cursor = Instance.new("Frame")
            cursor.Size = UDim2.new(0, 10, 0, 10)
            cursor.Position = UDim2.new(curH, -5, 1 - curS, -5)
            cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cursor.BorderSizePixel = 1
            cursor.BorderColor3 = Color3.fromRGB(0, 0, 0)
            cursor.ZIndex = 24
            cursor.Parent = canvas
            CreateCorner(cursor, 5)

            local valBar = Instance.new("ImageLabel")
            valBar.Name = "ValBar"
            valBar.Size = UDim2.new(1, -125, 0, 20)
            valBar.Position = UDim2.new(0, 120, 0, 10)
            valBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            valBar.BorderSizePixel = 0
            valBar.ZIndex = 23
            valBar.Parent = expandPanel
            CreateCorner(valBar, 4)

            local valGradient = Instance.new("UIGradient")
            valGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
            valGradient.Parent = valBar

            local isExpanded = false
            previewBtn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                isExpanded = not isExpanded
                if isExpanded then
                    TweenService:Create(pickerFrame, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, ItemHeight + 120) }):Play()
                else
                    TweenService:Create(pickerFrame, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, ItemHeight) }):Play()
                end
            end)

            local function FireColorUpdate()
                curColor = HSVToRGB(curH, curS, curV)
                previewBtn.BackgroundColor3 = curColor
                if p.Callback then pcall(p.Callback, curColor, curH, curS, curV) end
            end

            local draggingCanvas = false
            canvas.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    draggingCanvas = true
                    local absPos = canvas.AbsolutePosition
                    local absSize = canvas.AbsoluteSize
                    curH = math.clamp((i.Position.X - absPos.X) / absSize.X, 0, 1)
                    curS = 1 - math.clamp((i.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    cursor.Position = UDim2.new(curH, -5, 1 - curS, -5)
                    FireColorUpdate()
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if draggingCanvas and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local absPos = canvas.AbsolutePosition
                    local absSize = canvas.AbsoluteSize
                    curH = math.clamp((i.Position.X - absPos.X) / absSize.X, 0, 1)
                    curS = 1 - math.clamp((i.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                    cursor.Position = UDim2.new(curH, -5, 1 - curS, -5)
                    FireColorUpdate()
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    draggingCanvas = false
                end
            end)

            return pickerFrame
        end

        function compAPI:AddDropdown(p)
            p = p or {}
            local itemsList = p.Values or {"选项一", "选项二"}
            local selectedVal = p.Default or itemsList[1] or "请选择"

            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "Dropdown_" .. (p.Text or "Drp")
            dropFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            dropFrame.BackgroundColor3 = ThemeColors.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.ClipsDescendants = true
            dropFrame.ZIndex = 25
            dropFrame.Parent = containerFrame
            CreateCorner(dropFrame, 6)

            MakeLabel(dropFrame, {
                Size = UDim2.new(0.5, 0, 0, ItemHeight),
                Position = UDim2.new(0, 10, 0, 0),
                Text = p.Text or "下拉选择",
            })

            local selectedBtn = Instance.new("TextButton")
            selectedBtn.Name = "SelectedBtn"
            selectedBtn.Size = UDim2.new(0.45, 0, 0, ItemHeight - 10)
            selectedBtn.Position = UDim2.new(0.52, 0, 0, 5)
            selectedBtn.BackgroundColor3 = ThemeColors.SurfaceLight
            selectedBtn.BorderSizePixel = 0
            selectedBtn.Text = tostring(selectedVal) .. "  ▼"
            selectedBtn.TextColor3 = ThemeColors.Text
            selectedBtn.TextSize = FontBaseSize - 1
            selectedBtn.Font = Enum.Font.GothamMedium
            selectedBtn.AutoButtonColor = false
            selectedBtn.ZIndex = 26
            selectedBtn.Parent = dropFrame
            CreateCorner(selectedBtn, 6)

            local listContainer = Instance.new("ScrollingFrame")
            listContainer.Name = "ListContainer"
            listContainer.Size = UDim2.new(1, -20, 0, 120)
            listContainer.Position = UDim2.new(0, 10, 0, ItemHeight + 4)
            listContainer.BackgroundTransparency = 1
            listContainer.BorderSizePixel = 0
            listContainer.ScrollBarThickness = 3
            listContainer.ScrollBarImageColor3 = ThemeColors.Accent
            listContainer.ZIndex = 27
            listContainer.Parent = dropFrame

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 4)
            listLayout.Parent = listContainer

            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 6)
            end)

            local isOpen = false
            local function PopulateList(newItems)
                for _, child in ipairs(listContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, item in ipairs(newItems or itemsList) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 28)
                    optBtn.BackgroundColor3 = ThemeColors.BackgroundSecondary
                    optBtn.BorderSizePixel = 0
                    optBtn.Text = tostring(item)
                    optBtn.TextColor3 = ThemeColors.Text
                    optBtn.TextSize = FontBaseSize - 1
                    optBtn.Font = Enum.Font.GothamMedium
                    optBtn.AutoButtonColor = false
                    optBtn.ZIndex = 28
                    optBtn.Parent = listContainer
                    CreateCorner(optBtn, 4)

                    optBtn.MouseButton1Click:Connect(function()
                        PlaySound(Sounds.Click)
                        selectedVal = item
                        selectedBtn.Text = tostring(selectedVal) .. "  ▼"
                        isOpen = false
                        TweenService:Create(dropFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, ItemHeight) }):Play()
                        if p.Callback then pcall(p.Callback, selectedVal) end
                    end)
                end
            end

            PopulateList(itemsList)

            selectedBtn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                isOpen = not isOpen
                if isOpen then
                    selectedBtn.Text = tostring(selectedVal) .. "  ▲"
                    local totalH = math.min(#itemsList * 32 + 10, 130)
                    TweenService:Create(dropFrame, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, ItemHeight + totalH) }):Play()
                else
                    selectedBtn.Text = tostring(selectedVal) .. "  ▼"
                    TweenService:Create(dropFrame, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, ItemHeight) }):Play()
                end
            end)

            local dropAPI = {
                SetValues = function(self, nValues)
                    itemsList = nValues or {}
                    PopulateList(itemsList)
                end
            }

            return dropFrame, dropAPI
        end

        function compAPI:AddInput(p)
            p = p or {}
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "Input_" .. (p.Text or "Inp")
            inputFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            inputFrame.BackgroundColor3 = ThemeColors.Surface
            inputFrame.BorderSizePixel = 0
            inputFrame.ZIndex = 20
            inputFrame.Parent = containerFrame
            CreateCorner(inputFrame, 6)

            MakeLabel(inputFrame, {
                Size = UDim2.new(0.5, 0, 0, ItemHeight),
                Position = UDim2.new(0, 10, 0, 0),
                Text = p.Text or "内容/参数输入",
            })

            local box = Instance.new("TextBox")
            box.Name = "Box"
            box.Size = UDim2.new(0.45, 0, 0, ItemHeight - 10)
            box.Position = UDim2.new(0.52, 0, 0, 5)
            box.BackgroundColor3 = ThemeColors.BackgroundSecondary
            box.BorderSizePixel = 0
            box.Text = tostring(p.Default or "")
            box.PlaceholderText = p.Placeholder or "输入内容..."
            box.TextColor3 = ThemeColors.Text
            box.PlaceholderColor3 = ThemeColors.TextMuted
            box.TextSize = FontBaseSize - 1
            box.Font = Enum.Font.Gotham
            box.ClearTextOnFocus = false
            box.ZIndex = 21
            box.Parent = inputFrame
            CreateCorner(box, 6)

            box.FocusLost:Connect(function(enterPressed)
                PlaySound(Sounds.Click)
                if p.Callback then pcall(p.Callback, box.Text, enterPressed) end
            end)

            return inputFrame
        end

        function compAPI:AddKeybind(p)
            p = p or {}
            local currentKey = p.Default or Enum.KeyCode.E

            local kbFrame = Instance.new("Frame")
            kbFrame.Name = "Keybind_" .. (p.Text or "Kb")
            kbFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            kbFrame.BackgroundColor3 = ThemeColors.Surface
            kbFrame.BorderSizePixel = 0
            kbFrame.ZIndex = 20
            kbFrame.Parent = containerFrame
            CreateCorner(kbFrame, 6)

            MakeLabel(kbFrame, {
                Size = UDim2.new(0.6, 0, 0, ItemHeight),
                Position = UDim2.new(0, 10, 0, 0),
                Text = p.Text or "按键绑定",
            })

            local bindBtn = Instance.new("TextButton")
            bindBtn.Name = "BindBtn"
            bindBtn.Size = UDim2.new(0.35, 0, 0, ItemHeight - 10)
            bindBtn.Position = UDim2.new(0.62, 0, 0, 5)
            bindBtn.BackgroundColor3 = ThemeColors.SurfaceLight
            bindBtn.BorderSizePixel = 0
            bindBtn.Text = currentKey.Name or tostring(currentKey)
            bindBtn.TextColor3 = ThemeColors.Accent
            bindBtn.TextSize = FontBaseSize - 1
            bindBtn.Font = Enum.Font.GothamBold
            bindBtn.AutoButtonColor = false
            bindBtn.ZIndex = 21
            bindBtn.Parent = kbFrame
            CreateCorner(bindBtn, 6)

            bindBtn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                bindBtn.Text = "请按任意键..."
                bindBtn.TextColor3 = ThemeColors.Warning

                local conn
                conn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        bindBtn.Text = currentKey.Name
                        bindBtn.TextColor3 = ThemeColors.Accent
                        conn:Disconnect()
                        if p.Callback then pcall(p.Callback, currentKey) end
                    end
                end)
            end)

            return kbFrame
        end

        function compAPI:AddLabel(p)
            p = p or {}
            local lblFrame = Instance.new("Frame")
            lblFrame.Name = "Label_" .. (p.Text or "Lbl")
            lblFrame.Size = UDim2.new(1, 0, 0, p.SubText and (ItemHeight + 12) or (ItemHeight - 6))
            lblFrame.BackgroundColor3 = ThemeColors.Surface
            lblFrame.BackgroundTransparency = 0.5
            lblFrame.BorderSizePixel = 0
            lblFrame.ZIndex = 20
            lblFrame.Parent = containerFrame
            CreateCorner(lblFrame, 6)

            MakeLabel(lblFrame, {
                Size = UDim2.new(1, -20, 0, 22),
                Position = UDim2.new(0, 10, 0, 4),
                Text = p.Text or "提示文本",
                Font = Enum.Font.GothamSemibold,
            })

            if p.SubText then
                MakeLabel(lblFrame, {
                    Size = UDim2.new(1, -20, 0, 18),
                    Position = UDim2.new(0, 10, 0, 24),
                    Text = p.SubText,
                    TextColor3 = ThemeColors.TextMuted,
                    TextSize = FontBaseSize - 2,
                })
            end

            return lblFrame
        end

        function compAPI:AddPlayerSelector(p)
            p = p or {}
            local function GetPlayerNames()
                local list = {"所有玩家"}
                for _, plr in ipairs(Players:GetPlayers()) do
                    table.insert(list, plr.Name)
                end
                return list
            end

            local dropFrame, dropAPI = compAPI:AddDropdown({
                Text = p.Text or "玩家选择器",
                Values = GetPlayerNames(),
                Default = p.Default or "所有玩家",
                Callback = p.Callback,
            })

            local function RefreshPlayers()
                dropAPI:SetValues(GetPlayerNames())
            end

            Players.PlayerAdded:Connect(RefreshPlayers)
            Players.PlayerRemoving:Connect(RefreshPlayers)

            return dropFrame
        end

        function compAPI:AddImage(p)
            p = p or {}
            local imgFrame = Instance.new("Frame")
            imgFrame.Name = "Image_" .. (p.Text or "Img")
            imgFrame.Size = UDim2.new(1, 0, 0, p.Height or 100)
            imgFrame.BackgroundColor3 = ThemeColors.Surface
            imgFrame.BorderSizePixel = 0
            imgFrame.ZIndex = 20
            imgFrame.Parent = containerFrame
            CreateCorner(imgFrame, 6)

            local imgLabel = Instance.new("ImageLabel")
            imgLabel.Size = UDim2.new(0, (p.Height or 100) - 16, 0, (p.Height or 100) - 16)
            imgLabel.Position = UDim2.new(0, 8, 0, 8)
            imgLabel.BackgroundTransparency = 1
            imgLabel.Image = p.Image or "rbxassetid://6023420899"
            imgLabel.ScaleType = Enum.ScaleType.Fit
            imgLabel.ZIndex = 21
            imgLabel.Parent = imgFrame

            if p.Text then
                MakeLabel(imgFrame, {
                    Size = UDim2.new(1, -((p.Height or 100) + 16), 1, -16),
                    Position = UDim2.new(0, (p.Height or 100) + 8, 0, 8),
                    Text = p.Text,
                    TextWrapped = true,
                })
            end

            return imgFrame
        end

        function compAPI:AddStatus(p)
            p = p or {}
            local statusFrame = Instance.new("Frame")
            statusFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            statusFrame.BackgroundColor3 = ThemeColors.Surface
            statusFrame.BorderSizePixel = 0
            statusFrame.ZIndex = 20
            statusFrame.Parent = containerFrame
            CreateCorner(statusFrame, 6)

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 12, 0.5, -5)
            dot.BackgroundColor3 = p.Color or ThemeColors.Success
            dot.BorderSizePixel = 0
            dot.ZIndex = 21
            dot.Parent = statusFrame
            CreateCorner(dot, 5)

            MakeLabel(statusFrame, {
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 30, 0, 0),
                Text = p.Text or "运行状态: 正常",
                Font = Enum.Font.GothamBold,
            })

            return statusFrame
        end

        return compAPI
    end

    local tabCompAPI = AttachComponents(page)
    for k, v in pairs(tabCompAPI) do tabObj[k] = v end

    -- [分区 Section] 接口
    function tabObj:AddSection(sOpts)
        sOpts = sOpts or {}
        local secName = sOpts.Name or ("Section_" .. tostring(#self.Sections + 1))
        local secTitle = sOpts.Title or secName

        local secFrame = Instance.new("Frame")
        secFrame.Name = secName
        secFrame.Size = UDim2.new(1, 0, 0, 0)
        secFrame.BackgroundColor3 = ThemeColors.BackgroundSecondary
        secFrame.BorderSizePixel = 0
        secFrame.ZIndex = 18
        secFrame.Parent = self.Page
        CreateCorner(secFrame, 8)

        local secHeader = Instance.new("Frame")
        secHeader.Name = "Header"
        secHeader.Size = UDim2.new(1, 0, 0, 28)
        secHeader.BackgroundColor3 = ThemeColors.Surface
        secHeader.BorderSizePixel = 0
        secHeader.ZIndex = 19
        secHeader.Parent = secFrame
        CreateCorner(secHeader, 8)

        MakeLabel(secHeader, {
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = secTitle,
            Font = Enum.Font.GothamBold,
            TextColor3 = ThemeColors.Text,
            TextSize = FontBaseSize,
        })

        local secBody = Instance.new("Frame")
        secBody.Name = "Body"
        secBody.Size = UDim2.new(1, -12, 1, -34)
        secBody.Position = UDim2.new(0, 6, 0, 32)
        secBody.BackgroundTransparency = 1
        secBody.ZIndex = 19
        secBody.Parent = secFrame

        local secLayout = Instance.new("UIListLayout")
        secLayout.SortOrder = Enum.SortOrder.LayoutOrder
        secLayout.Padding = UDim.new(0, 6)
        secLayout.Parent = secBody

        secLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            secFrame.Size = UDim2.new(1, 0, 0, secLayout.AbsoluteContentSize.Y + 38)
        end)

        local secObj = {
            Name = secName,
            Frame = secFrame,
            Body = secBody,
            SubSections = {},
        }

        local secCompAPI = AttachComponents(secBody)
        for k, v in pairs(secCompAPI) do secObj[k] = v end

        -- [再分区 SubSection] 嵌套接口
        function secObj:AddSubSection(ssOpts)
            ssOpts = ssOpts or {}
            local subTitle = ssOpts.Title or "子分区"

            local subSecFrame = Instance.new("Frame")
            subSecFrame.Name = "SubSection_" .. subTitle
            subSecFrame.Size = UDim2.new(1, 0, 0, 0)
            subSecFrame.BackgroundColor3 = ThemeColors.Surface
            subSecFrame.BorderSizePixel = 0
            subSecFrame.ZIndex = 20
            subSecFrame.Parent = self.Body
            CreateCorner(subSecFrame, 6)

            MakeLabel(subSecFrame, {
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.new(0, 8, 0, 2),
                Text = "▶ " .. subTitle,
                Font = Enum.Font.GothamBold,
                TextColor3 = ThemeColors.TextMuted,
                TextSize = FontBaseSize - 1,
            })

            local subBody = Instance.new("Frame")
            subBody.Name = "SubBody"
            subBody.Size = UDim2.new(1, -10, 1, -28)
            subBody.Position = UDim2.new(0, 5, 0, 26)
            subBody.BackgroundTransparency = 1
            subBody.ZIndex = 21
            subBody.Parent = subSecFrame

            local subLayout = Instance.new("UIListLayout")
            subLayout.SortOrder = Enum.SortOrder.LayoutOrder
            subLayout.Padding = UDim.new(0, 5)
            subLayout.Parent = subBody

            subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                subSecFrame.Size = UDim2.new(1, 0, 0, subLayout.AbsoluteContentSize.Y + 32)
            end)

            local subObj = {
                Name = subTitle,
                Frame = subSecFrame,
                Body = subBody,
            }

            local subCompAPI = AttachComponents(subBody)
            for k, v in pairs(subCompAPI) do subObj[k] = v end

            table.insert(self.SubSections, subObj)
            return subObj
        end

        table.insert(self.Sections, secObj)
        return secObj
    end

    return tabObj
end

-- ============================================================
-- [9] Toast Notification Engine
-- ============================================================
local ActiveNotifications = {}

function Library:Notify(opts)
    opts = opts or {}
    local titleText = opts.Title or "系统通知"
    local msgText = opts.Text or opts.Message or "操作已执行"
    local duration = opts.Duration or 3.5
    local playAudio = opts.Sound ~= false

    if playAudio then PlaySound(Sounds.Chime) end

    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotifPill"
    notifFrame.Size = UDim2.new(0, 260, 0, 58)
    notifFrame.Position = UDim2.new(1, 20, 1, -80 - (#ActiveNotifications * 66))
    notifFrame.BackgroundColor3 = ThemeColors.Surface
    notifFrame.BorderSizePixel = 0
    notifFrame.ZIndex = 5000
    notifFrame.Parent = RootScreenGui or TargetParent
    CreateCorner(notifFrame, 10)
    CreateStroke(notifFrame, ThemeColors.Accent, 1.5)

    MakeLabel(notifFrame, {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 6),
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextColor3 = ThemeColors.Text,
    })

    MakeLabel(notifFrame, {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 10, 0, 26),
        Text = msgText,
        TextColor3 = ThemeColors.TextMuted,
        TextSize = FontBaseSize - 1,
    })

    table.insert(ActiveNotifications, notifFrame)

    TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -270, 1, -80 - ((#ActiveNotifications - 1) * 66))
    }):Play()

    task.spawn(function()
        task.wait(duration)
        if notifFrame and notifFrame.Parent then
            TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset)
            }):Play()
            task.wait(0.32)
            for idx, item in ipairs(ActiveNotifications) do
                if item == notifFrame then
                    table.remove(ActiveNotifications, idx)
                    break
                end
            end
            notifFrame:Destroy()
        end
    end)
end

-- ============================================================
-- [10] Built-in Settings Tab (有序再分区架构)
-- ============================================================
function Library:BuildSettingsTab()
    local setTab = Library:AddTab({ Name = "UISettings", Title = "UI 设置" })

    -- 外观与灯效 (分区)
    local styleSec = setTab:AddSection({ Title = "外观样式与动画" })

    styleSec:AddSlider({
        Text = "UI 透明度",
        Min = 0.2,
        Max = 1.0,
        Default = Saved.Transparency,
        Rounding = 0.05,
        Callback = function(v)
            Saved.Transparency = v
            if MainWindow then MainWindow.BackgroundTransparency = 1 - v end
            SaveConfig()
        end
    })

    styleSec:AddDropdown({
        Text = "边框灯效模式",
        Values = {"Static", "Rainbow", "Breathing", "Pulse"},
        Default = Saved.BorderColorMode,
        Callback = function(mode)
            Saved.BorderColorMode = mode
            SaveConfig()
        end
    })

    styleSec:AddHSVPicker({
        Text = "边框基准 HSV 颜色",
        Default = HSVToRGB(Saved.BorderColorHSV.H, Saved.BorderColorHSV.S, Saved.BorderColorHSV.V),
        Callback = function(clr, h, s, v)
            Saved.BorderColorHSV = { H = h, S = s, V = v }
            SaveConfig()
        end
    })

    -- 主题配色方案 (分区)
    local themeSec = setTab:AddSection({ Title = "主题配色方案" })

    themeSec:AddDropdown({
        Text = "预设配色主题",
        Values = {"Dark", "Light", "Cyberpunk", "Emerald", "Sunset", "Midnight"},
        Default = Saved.ThemeName,
        Callback = function(tName)
            if Themes[tName] then
                ThemeColors = Themes[tName]
                Saved.ThemeName = tName
                if MainWindow then MainWindow.BackgroundColor3 = ThemeColors.Background end
                Library:Notify({ Title = "主题切换", Text = "当前主题已更改为: " .. tName })
                SaveConfig()
            end
        end
    })

    -- 背景与音效定义 (分区)
    local audioSec = setTab:AddSection({ Title = "背景与音效定义" })

    audioSec:AddToggle({
        Text = "开启交互音效",
        Default = Saved.SoundEnabled,
        Callback = function(state)
            Saved.SoundEnabled = state
            SaveConfig()
        end
    })

    audioSec:AddSlider({
        Text = "音效音量",
        Min = 0.1,
        Max = 1.0,
        Default = Saved.SoundVolume,
        Rounding = 0.05,
        Callback = function(vol)
            Saved.SoundVolume = vol
            SaveConfig()
        end
    })

    audioSec:AddInput({
        Text = "自定义背景图片 ID",
        Default = Saved.BackgroundImage or "",
        Placeholder = "rbxassetid://...",
        Callback = function(txt)
            Saved.BackgroundImage = txt
            if BackgroundImageLabel then BackgroundImageLabel.Image = txt end
            SaveConfig()
        end
    })

    audioSec:AddToggle({
        Text = "启用 FPS / Ping 悬浮窗",
        Default = Saved.FloatingStatusEnabled,
        Callback = function(val)
            Library:ToggleStats(val)
            SaveConfig()
        end
    })

    -- 配置管理 (分区)
    local cfgSec = setTab:AddSection({ Title = "配置持久化管理" })

    cfgSec:AddButton({
        Text = "立即保存当前 UI 配置",
        Callback = function()
            SaveConfig()
            Library:Notify({ Title = "配置保存", Text = "UI 状态已安全保存至本地！" })
        end
    })

    cfgSec:AddButton({
        Text = "重置 UI 配置为默认",
        Callback = function()
            Saved.Transparency = 1.0
            Saved.BorderColorMode = "Pulse"
            Saved.ThemeName = "Dark"
            Saved.SoundEnabled = true
            SaveConfig()
            Library:Notify({ Title = "配置重置", Text = "请重新载入脚本以应用默认设置" })
        end
    })

    -- 作者信息与版权 (分区 + 再分区) - 保障 Log_quick 标注不可篡改
    local creditSec = setTab:AddSection({ Title = "关于与脚本版权" })
    local subAuthor = creditSec:AddSubSection({ Title = "作者署名 (不可修改)" })

    subAuthor:AddLabel({
        Text = "UI 框架作者: Log_quick (不可更改)",
        SubText = "核心库版本: v3.0 Master Release",
    })

    local scriptAuthorLbl = subAuthor:AddLabel({
        Text = "脚本作者: " .. (Saved.ScriptAuthor or "开发者"),
        SubText = "已关联脚本版权",
    })

    subAuthor:AddStatus({
        Text = "已注入环境: " .. GetExecutorName(),
        Color = ThemeColors.Success,
    })

    function Library:SetScriptAuthor(name)
        Saved.ScriptAuthor = name or "开发者"
        scriptAuthorLbl.Text = "脚本作者: " .. Saved.ScriptAuthor
        SaveConfig()
    end

    return setTab
end

-- ============================================================
-- [11] FPS / Ping Stats Floating Overlay
-- ============================================================
local FloatingStatsGui = nil

function Library:ToggleStats(enabled)
    Saved.FloatingStatusEnabled = enabled ~= false
    if FloatingStatsGui then
        FloatingStatsGui:Destroy()
        FloatingStatsGui = nil
    end

    if not Saved.FloatingStatusEnabled then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LogQuick_FloatingStats"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = TargetParent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 42)
    frame.Position = UDim2.new(0, 20, 0, 60)
    frame.BackgroundColor3 = ThemeColors.Surface
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.ZIndex = 4000
    frame.Parent = gui
    CreateCorner(frame, 8)
    CreateStroke(frame, ThemeColors.Accent, 1)

    local fpsLbl = MakeLabel(frame, {
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 8, 0, 3),
        Text = "FPS: --",
        Font = Enum.Font.GothamBold,
        TextSize = FontBaseSize - 1,
    })

    local pingLbl = MakeLabel(frame, {
        Size = UDim2.new(1, -12, 0, 16),
        Position = UDim2.new(0, 8, 0, 21),
        Text = "Ping: -- ms",
        TextColor3 = ThemeColors.TextMuted,
        TextSize = FontBaseSize - 2,
    })

    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    FloatingStatsGui = gui

    task.spawn(function()
        local lastTime = os.clock()
        local frameCount = 0
        while FloatingStatsGui and FloatingStatsGui.Parent do
            frameCount = frameCount + 1
            local curTime = os.clock()
            if curTime - lastTime >= 0.5 then
                local fps = math.round(frameCount / (curTime - lastTime))
                fpsLbl.Text = "FPS: " .. tostring(fps)
                frameCount = 0
                lastTime = curTime

                local pingVal = 0
                pcall(function()
                    pingVal = math.round(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                pingLbl.Text = "Ping: " .. tostring(pingVal) .. " ms"
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

function Library:ShowFloatingStatus() Library:ToggleStats(true) end
function Library:HideFloatingStatus() Library:ToggleStats(false) end

-- ============================================================
-- [12] Watermark & Custom Background API
-- ============================================================
local WatermarkGui = nil

function Library:SetWatermark(opts)
    opts = opts or {}
    local textStr = opts.Text or "LogQuick Hub | Log_quick UI"

    if WatermarkGui then WatermarkGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LogQuick_Watermark"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = TargetParent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 26)
    frame.Position = UDim2.new(1, -250, 0, 10)
    frame.BackgroundColor3 = ThemeColors.Background
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.ZIndex = 4500
    frame.Parent = gui
    CreateCorner(frame, 6)
    CreateStroke(frame, ThemeColors.Accent, 1)

    MakeLabel(frame, {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = textStr,
        Font = Enum.Font.GothamBold,
        TextSize = FontBaseSize - 2,
        TextColor3 = ThemeColors.Text,
    })

    WatermarkGui = gui
    return frame
end

function Library:HideWatermark()
    if WatermarkGui then WatermarkGui:Destroy() end
end

function Library:SetBackground(opts)
    opts = opts or {}
    if opts.Image then
        Saved.BackgroundImage = opts.Image
        if BackgroundImageLabel then BackgroundImageLabel.Image = opts.Image end
    end
    if opts.Transparency then
        Saved.BackgroundTransparency = opts.Transparency
        if BackgroundImageLabel then BackgroundImageLabel.ImageTransparency = opts.Transparency end
    end
    SaveConfig()
end

-- ============================================================
-- [13] Fuzzy Filter Search System
-- ============================================================
function Library:CreateSearch(opts)
    opts = opts or {}
    if not MainWindow then return end

    local header = MainWindow:FindFirstChild("Header", true)
    if not header then return end

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(0, 140, 0, 26)
    searchBox.Position = UDim2.new(1, -220, 0, 9)
    searchBox.BackgroundColor3 = ThemeColors.SurfaceLight
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = opts.Placeholder or "🔍 搜索功能..."
    searchBox.Text = ""
    searchBox.TextColor3 = ThemeColors.Text
    searchBox.PlaceholderColor3 = ThemeColors.TextMuted
    searchBox.TextSize = FontBaseSize - 2
    searchBox.Font = Enum.Font.Gotham
    searchBox.ZIndex = 23
    searchBox.Parent = header
    CreateCorner(searchBox, 6)

    SearchInputBox = searchBox

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text)
        if CurrentTabObj and CurrentTabObj.Page then
            for _, item in ipairs(CurrentTabObj.Page:GetDescendants()) do
                if item:IsA("Frame") or item:IsA("TextButton") then
                    if item.Name:sub(1, 6) == "Button" or item.Name:sub(1, 6) == "Toggle" or item.Name:sub(1, 6) == "Slider" or item.Name:sub(1, 8) == "Dropdown" or item.Name:sub(1, 5) == "Input" then
                        if query == "" then
                            item.Visible = true
                        else
                            local matchName = string.lower(item.Name)
                            local labelChild = item:FindFirstChildWhichIsA("TextLabel")
                            local labelText = labelChild and string.lower(labelChild.Text) or ""
                            if string.find(matchName, query, 1, true) or string.find(labelText, query, 1, true) then
                                item.Visible = true
                            else
                                item.Visible = false
                            end
                        end
                    end
                end
            end
        end
        if opts.Callback then pcall(opts.Callback, searchBox.Text) end
    end)

    return searchBox
end

-- ============================================================
-- [14] Modal Key License Verification System
-- ============================================================
function Library:CreateKeySystem(opts)
    opts = opts or {}
    local keyTitle = opts.Title or "LogQuick 密钥验证系统"
    local targetKey = opts.Key or "demo-key-888"
    local getLink = opts.KeyLink or "https://github.com/logz-c"

    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "LogQuick_KeySystem"
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.IgnoreGuiInset = true
    keyGui.Parent = TargetParent

    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 340, 0, 200)
    modal.Position = UDim2.new(0.5, -170, 0.5, -100)
    modal.BackgroundColor3 = ThemeColors.Background
    modal.BorderSizePixel = 0
    modal.ZIndex = 6000
    modal.Parent = keyGui
    CreateCorner(modal, 12)
    CreateStroke(modal, ThemeColors.Accent, 2)

    MakeLabel(modal, {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 15),
        Text = keyTitle,
        Font = Enum.Font.GothamBold,
        TextSize = HeaderFontSize,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local inputKeyBox = Instance.new("TextBox")
    inputKeyBox.Size = UDim2.new(1, -40, 0, 38)
    inputKeyBox.Position = UDim2.new(0, 20, 0, 60)
    inputKeyBox.BackgroundColor3 = ThemeColors.Surface
    inputKeyBox.BorderSizePixel = 0
    inputKeyBox.PlaceholderText = "请输入您的 Key 卡密..."
    inputKeyBox.Text = ""
    inputKeyBox.TextColor3 = ThemeColors.Text
    inputKeyBox.PlaceholderColor3 = ThemeColors.TextMuted
    inputKeyBox.Font = Enum.Font.Gotham
    inputKeyBox.TextSize = FontBaseSize
    inputKeyBox.ZIndex = 6001
    inputKeyBox.Parent = modal
    CreateCorner(inputKeyBox, 6)

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.44, 0, 0, 36)
    submitBtn.Position = UDim2.new(0, 20, 0, 115)
    submitBtn.BackgroundColor3 = ThemeColors.Success
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "提交验证"
    submitBtn.TextColor3 = ThemeColors.Text
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = FontBaseSize
    submitBtn.ZIndex = 6001
    submitBtn.Parent = modal
    CreateCorner(submitBtn, 6)

    local getLinkBtn = Instance.new("TextButton")
    getLinkBtn.Size = UDim2.new(0.44, 0, 0, 36)
    getLinkBtn.Position = UDim2.new(0.52, 0, 0, 115)
    getLinkBtn.BackgroundColor3 = ThemeColors.SurfaceLight
    getLinkBtn.BorderSizePixel = 0
    getLinkBtn.Text = "获取 Key 链接"
    getLinkBtn.TextColor3 = ThemeColors.Text
    getLinkBtn.Font = Enum.Font.GothamSemibold
    getLinkBtn.TextSize = FontBaseSize
    getLinkBtn.ZIndex = 6001
    getLinkBtn.Parent = modal
    CreateCorner(getLinkBtn, 6)

    local statusLbl = MakeLabel(modal, {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 165),
        Text = "状态: 等待输入 Key",
        TextColor3 = ThemeColors.TextMuted,
        TextSize = FontBaseSize - 2,
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    getLinkBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(getLink)
            statusLbl.Text = "已复制 Key 链接到剪贴板！"
            statusLbl.TextColor3 = ThemeColors.Accent
        else
            statusLbl.Text = "复制失败: 环境不支持 setclipboard"
        end
    end)

    submitBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        if inputKeyBox.Text == targetKey then
            statusLbl.Text = "密钥验证成功！正在载入..."
            statusLbl.TextColor3 = ThemeColors.Success
            PlaySound(Sounds.Success)
            task.wait(0.6)
            keyGui:Destroy()
            if opts.Callback then pcall(opts.Callback, true) end
        else
            statusLbl.Text = "卡密错误，请重新输入！"
            statusLbl.TextColor3 = ThemeColors.Danger
            if opts.Callback then pcall(opts.Callback, false) end
        end
    end)
end

-- ============================================================
-- [15] Initialization Entrypoint
-- ============================================================
function Library:Initialize(opts)
    opts = opts or {}

    -- 创建 UI 窗口
    Library:CreateWindow(opts)

    -- 构建内置 UI 设置面板
    Library:BuildSettingsTab()

    -- 构建搜索栏
    Library:CreateSearch()

    -- 默认开启 FPS / Ping 悬浮窗
    Library:ToggleStats(true)

    -- 欢迎与环境识别通知
    task.spawn(function()
        task.wait(0.5)
        Library:Notify({
            Title = "LogQuick UI 载入成功",
            Text = "欢迎使用 LogQuick Script Center",
            Duration = 3,
        })
        task.wait(1.2)
        Library:Notify({
            Title = "注入检测",
            Text = "已成功通过 " .. GetExecutorName() .. " 注入",
            Duration = 3.5,
        })
    end)
end

return Library

-- ============================================================
-- [完整使用示例 Demonstration Code]
-- 方式一: 如果推送到 GitHub 仓库，使用 HttpGet 在线加载:
-- local LogQuickUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logz-c/logz-ui-lib/main/script.lua"))()
--
-- 方式二: 如果已将 script.lua 保存到注入器本地 workspace 文件夹:
-- local LogQuickUI = loadstring(readfile("script.lua"))()
-- ============================================================
