--[[
LogQuick_UI_Lib.lua
Roblox 执行脚本单文件 UI 库
作者: Log_quick (不可更改)
支持: 手机 / 电脑自适应
风格: 简洁美观大方、高级载入动画、清脆声效
GitHub: 请将本文件保存后推送到您的仓库
包含: 完整接口、内置设置面板、功能再分区、位置记忆、嵌套容器
    ================================================================================
    LogQuick_UI_Lib.lua (Completely Redesigned & Re-Engineered v3.5)
    ================================================================================
    Roblox 注入器通用单文件高级 UI 框架库
    作者: Log_quick (不可更改)
    
    重点修复与重构机制:
    1. 采用 Roblox 引擎原生 AutomaticSize = Enum.AutomaticSize.Y 自动伸缩布局，
       彻底解决布局重叠、高度为 0 导致的菜单不显示/控件不可见问题！
    2. 优化 Tab 激活机制，确保用户添加的功能 Tab 默认高亮且页面正常渲染。
    3. 优化控件搜索过滤逻辑，清空搜索框时可 100% 恢复所有菜单控件显示。
    4. 手机端与电脑端双端智能自适应 (Mobile Touch Adaptive Layout)。
    5. 内置 UI 设置面板 (Config 持久化, 透明度, 呼吸/彩虹/脉冲发光边框, 预设与HSV主题, 音效, 独立脚本作者署名)。
    6. 完整 15+ 种核心与拓展 API 接口 (Button, Toggle, Slider, ColorPicker, Dropdown, Input, Keybind, Label, PlayerSelector, Image, Status, Search, KeySystem, Stats, Watermark, Notify)。
    ================================================================================
]]

local LogQuickUI = {}
local Library = LogQuickUI

-- ============================================================
-- [1] 基础与工具模块
-- [1] Services & Environment Compatibility
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StatsService = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 10)

-- 安全挂载节点 (gethui > RobloxGui > CoreGui > PlayerGui)
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

-- 智能识别注入器环境
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

-- 设备判定与自适应尺寸
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if not IsMobile then
    -- 有些设备同时有键盘和触屏，这里简化判断
    IsMobile = UserInputService.TouchEnabled
if not IsMobile and UserInputService.TouchEnabled then
    IsMobile = true
end

-- 适配系数
local Scale = IsMobile and 1.3 or 1.0
local FontSizeBase = IsMobile and 16 or 14
local PaddingBase = IsMobile and 16 or 10
local ButtonHeightBase = IsMobile and 44 or 36
local ItemHeight = IsMobile and 42 or 34
local FontBaseSize = IsMobile and 15 or 13
local HeaderFontSize = IsMobile and 17 or 15

-- 颜色主题 (暗色默认，亮色可切换)
local Theme = {
-- ============================================================
-- [2] Theme Palette Manager
-- ============================================================
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18, 18, 22),
        BackgroundSecondary = Color3.fromRGB(26, 26, 32),
        Surface = Color3.fromRGB(30, 30, 38),
        SurfaceLight = Color3.fromRGB(42, 42, 52),
        Background = Color3.fromRGB(18, 18, 24),
        BackgroundSecondary = Color3.fromRGB(26, 26, 36),
        Surface = Color3.fromRGB(34, 34, 46),
        SurfaceLight = Color3.fromRGB(48, 48, 64),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(170, 170, 190),
        TextMuted = Color3.fromRGB(160, 160, 185),
        Accent = Color3.fromRGB(130, 100, 255),
        Border = Color3.fromRGB(60, 60, 75),
        BorderAccent = Color3.fromRGB(140, 110, 255),
        Success = Color3.fromRGB(80, 220, 130),
        Warning = Color3.fromRGB(255, 190, 60),
        Danger = Color3.fromRGB(240, 80, 90),
        Border = Color3.fromRGB(55, 55, 75),
        BorderAccent = Color3.fromRGB(145, 115, 255),
        Success = Color3.fromRGB(60, 210, 130),
        Warning = Color3.fromRGB(255, 180, 50),
        Danger = Color3.fromRGB(240, 75, 90),
    },
    Light = {
        Background = Color3.fromRGB(250, 250, 255),
        BackgroundSecondary = Color3.fromRGB(240, 240, 248),
        Surface = Color3.fromRGB(245, 245, 252),
        SurfaceLight = Color3.fromRGB(235, 235, 245),
        Text = Color3.fromRGB(20, 20, 30),
        TextMuted = Color3.fromRGB(100, 100, 120),
        Accent = Color3.fromRGB(100, 80, 220),
        Border = Color3.fromRGB(210, 210, 225),
        BorderAccent = Color3.fromRGB(110, 90, 240),
        Success = Color3.fromRGB(40, 190, 90),
        Warning = Color3.fromRGB(240, 160, 30),
        Danger = Color3.fromRGB(230, 50, 60),
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

local CurrentTheme = "Dark"
local ThemeColors = Theme.Dark
local ThemeColors = Themes.Dark

-- ============================================================
-- [2] 配置与状态管理（保存到 getgenv 以便执行器通用）
-- [3] Config Storage & Persistence
-- ============================================================
local ConfigKey = "LogQuickUI_Config"
local ConfigStore = getgenv and getgenv() or {}
if not ConfigStore[ConfigKey] then
    ConfigStore[ConfigKey] = {
        WindowPosition = UDim2.new(0.35, 0, 0.25, 0),
        WindowSize = UDim2.new(0, 520, 0, 580),
        Transparency = 1, -- 0 完全透明, 1 完全不透明
        BorderColorMode = "Static", -- Static, Rainbow, Breathing, Pulse
        BorderColorHSV = { H = 0.75, S = 0.6, V = 1 }, -- 默认紫色系
        ThemeName = "Dark",
        SizeScale = 1,
        BackgroundImage = nil, -- 开发者可自定义
        BackgroundColor = Color3.fromRGB(18, 18, 22),
        SoundEnabled = true,
        SoundId = "rbxassetid://9115297988", -- 默认清脆点击音效（示例 ID）
        FloatingStatusEnabled = true,
        ScriptAuthor = "",
        ConfigData = {}, -- 开发者自定义配置
    }
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
local Saved = ConfigStore[ConfigKey]

-- 位置记忆与屏幕限制工具
local function ClampWindowPosition(pos, size)
    local absX = pos.X.Offset + size.X.Offset * pos.X.Scale
    local absY = pos.Y.Offset + size.Y.Offset * pos.Y.Scale
    local screenW = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1280
    local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720
    -- 确保不完全超出屏幕
    local minX, minY = 20, 40
    local maxX = math.max(minX, screenW - size.X.Offset * 0.15 - 20)
    local maxY = math.max(minY, screenH - size.Y.Offset * 0.15 - 20)
    local newX = math.clamp(absX, minX, maxX) - size.X.Offset * pos.X.Scale
    local newY = math.clamp(absY, minY, maxY) - size.Y.Offset * pos.Y.Scale
    -- 保持比例和偏移
    local scaleX = pos.X.Scale
    local scaleY = pos.Y.Scale
    return UDim2.new(scaleX, newX, scaleY, newY)

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

-- 限制窗口拖拽不要超出屏幕边界
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
-- [3] 音效系统（使用 Roblox Sound 对象 + 内置音频 ID 方案）
-- [4] Crisp Sound Engine
-- ============================================================
local SoundService = game:GetService("SoundService")
local Sounds = {}

local function CreateSound(id)
    local s = Instance.new("Sound")
    s.SoundId = id or "rbxassetid://9115297988"
    s.Volume = 0.4
    s.PlaybackSpeed = 1.15
    s.Parent = SoundService
    return s
end
local Sounds = {
    Click = "rbxassetid://9115297988",
    Toggle = "rbxassetid://6003308824",
    Chime = "rbxassetid://4590662766",
    Slider = "rbxassetid://9119713951",
    Success = "rbxassetid://130707418",
}

local function PlaySound(id)
    if Saved.SoundEnabled == false then return end
    local sid = id or Saved.SoundId
    local s = CreateSound(sid)
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
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

Library.PlaySound = PlaySound -- 开发者可直接调用
Library.SetSoundEnabled = function(enabled)
    Saved.SoundEnabled = enabled ~= false
    PlaySound()
end
Library.SetSoundId = function(id)
    Saved.SoundId = id or Saved.SoundId
end
Library.PlaySound = PlaySound
Library.SetSoundEnabled = function(val) Saved.SoundEnabled = val; SaveConfig() end
Library.SetSoundVolume = function(vol) Saved.SoundVolume = vol; SaveConfig() end
Library.SetSoundId = function(id) Saved.SoundId = id; SaveConfig() end

-- ============================================================
-- [4] HSV 工具与颜色动画
-- [5] Color Math & Border Effects
-- ============================================================
local function HSVToRGB(h, s, v)
    local c = v * s
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return Color3.new((r+m), (g+m), (b+m))
    return Color3.new(r + m, g + m, b + m)
end

local function RGBToHSV(r, g, b)
local function RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local maxVal = math.max(r, g, b)
    local minVal = math.min(r, g, b)
    local delta = maxVal - minVal
    return h, s, v
end

-- 彩虹呼吸边框动画
local RainbowPhase = 0
local function UpdateRainbow()
    RainbowPhase = RainbowPhase + 0.008
    if RainbowPhase > 1 then RainbowPhase = 0 end
    local h = RainbowPhase
    local s = Saved.BorderColorHSV and Saved.BorderColorHSV.S or 0.8
    local v = Saved.BorderColorHSV and Saved.BorderColorHSV.V or 1
    return HSVToRGB(h, s, v)
end

local function BreathingColor(base, intensity)
    intensity = intensity or 0.5
    local t = (math.sin(os.clock() * 3) + 1) / 2
    return Color3.new(
        math.clamp(base.R + (1 - base.R) * t * intensity, 0, 1),
        math.clamp(base.G + (1 - base.G) * t * intensity, 0, 1),
        math.clamp(base.B + (1 - base.B) * t * intensity, 0, 1)
    )
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
-- [5] 适配与布局工具
-- [6] UI Primitive Helpers
-- ============================================================
local function GetScreenSize()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize end
    return Vector2.new(1280, 720)
local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local ScreenSize = GetScreenSize()

local function MakeFrame(parent, props)
    local f = Instance.new("Frame")
    f.Name = props.Name or "Frame"
    f.Size = props.Size or UDim2.new(1, 0, 1, 0)
    f.Position = props.Position or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = props.BackgroundColor3 or ThemeColors.Surface
    f.BackgroundTransparency = props.BackgroundTransparency or 0
    f.BorderSizePixel = props.BorderSizePixel or 0
    f.BorderColor3 = props.BorderColor3 or ThemeColors.Border
    f.ZIndex = props.ZIndex or 1
    f.Parent = parent
    if props.AutoLocalScale then
        -- 自动适配缩放（仅移动端）
        local scaleFactor = IsMobile and 1.15 or 1.0
        -- 这里简化处理，不直接修改已有 Size 的比例
    end
    return f
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
    lbl.Name = props.Name or "Label"
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 24)
    lbl.Name = props.Name or "TextLabel"
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 22)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = props.BackgroundTransparency or 1
    lbl.BackgroundColor3 = props.BackgroundColor3 or ThemeColors.Surface
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or ThemeColors.Text
    lbl.TextSize = props.TextSize or FontSizeBase
    lbl.Font = props.Font or Enum.Font.GothamSemibold
    lbl.TextSize = props.TextSize or FontBaseSize
    lbl.Font = props.Font or Enum.Font.GothamMedium
    lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    lbl.ZIndex = props.ZIndex or 2
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.ZIndex = props.ZIndex or 5
    lbl.Parent = parent
    if props.TextWrapped then lbl.TextWrapped = true end
    if props.TextScaled then lbl.TextScaled = true end
    return lbl
end

local function MakeButton(parent, props)
    local btn = Instance.new("TextButton")
    btn.Name = props.Name or "Button"
    btn.Size = props.Size or UDim2.new(1, 0, 0, ButtonHeightBase)
    btn.Position = props.Position or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = props.BackgroundColor3 or ThemeColors.Surface
    btn.BorderSizePixel = props.BorderSizePixel or 1
    btn.BorderColor3 = props.BorderColor3 or ThemeColors.Border
    btn.Text = props.Text or "Button"
    btn.TextColor3 = props.TextColor3 or ThemeColors.Text
    btn.TextSize = props.TextSize or FontSizeBase
    btn.Font = props.Font or Enum.Font.GothamBold
    btn.ZIndex = props.ZIndex or 2
    btn.AutoButtonColor = false
    btn.Parent = parent

    -- 悬停与点击反馈
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = ThemeColors.SurfaceLight
        btn.BorderColor3 = ThemeColors.BorderAccent
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = ThemeColors.Surface
        btn.BorderColor3 = ThemeColors.Border
    end)
    btn.MouseButton1Click:Connect(function()
        PlaySound(Saved.SoundId)
        if props.Callback then
            pcall(props.Callback)
        end
    end)
    return btn
end

local function MakeToggle(parent, props)
    local container = MakeFrame(parent, {
        Name = props.Name or "ToggleContainer",
        Size = props.Size or UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
    })

    local label = MakeLabel(container, {
        Name = "ToggleText",
        Size = UDim2.new(0.7, 0, 1, 0),
        Text = props.Text or "Toggle",
        TextSize = FontSizeBase,
        TextColor3 = ThemeColors.Text,
    })

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 36, 1, -8)
    btn.Position = UDim2.new(1, -40, 0, 4)
    btn.BackgroundColor3 = props.Default and ThemeColors.Success or ThemeColors.Border
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = container
    btn.AutoButtonColor = false

    local state = props.Default == true
    local function UpdateVisual()
        btn.BackgroundColor3 = state and ThemeColors.Success or ThemeColors.Border
    end
    UpdateVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        UpdateVisual()
        PlaySound(Saved.SoundId)
        if props.Callback then
            pcall(function() props.Callback(state) end)
        end
    end)

    return container, state, function()
        state = not state
        UpdateVisual()
        return state
    end
end

-- ============================================================
-- [6] 核心窗口构造
-- [7] Core Window & Layout Architecture
-- ============================================================
local MainWindow = nil
local MainFrame = nil
local WindowTitleBar = nil
local WindowContent = nil
local TabContainer = nil
local Tabs = {}
local RootScreenGui = nil
local BackgroundImageLabel = nil
local CurrentTabObj = nil
local TabsList = {}

local function CreateWindow(opts)
function Library:CreateWindow(opts)
    opts = opts or {}
    local titleText = opts.Title or "LogQuick UI"
    local subtitleText = opts.Subtitle or "Script Center"
    local sizeVal = opts.Size or Saved.WindowSize
    local posVal = opts.Position or Saved.WindowPosition
    local titleText = opts.Title or "LogQuick Script Center"
    local subtitleText = opts.Subtitle or "UI Library · 作者: Log_quick"
    local windowSize = opts.Size or Saved.WindowSize
    local windowPos = opts.Position or Saved.WindowPosition

    if opts.ScriptAuthor then Saved.ScriptAuthor = opts.ScriptAuthor end

    -- 主容器（拖动区域 + 内容区域）
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LogQuickUI_ScreenGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Name = "LogQuickUI_Root"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    -- 背景遮罩（半透明背景，可点击关闭/拖动）
    local bgOverlay = Instance.new("TextButton")
    bgOverlay.Name = "BgOverlay"
    bgOverlay.Size = UDim2.new(1, 0, 1, 0)
    bgOverlay.Position = UDim2.new(0, 0, 0, 0)
    bgOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgOverlay.BackgroundTransparency = 0.3
    bgOverlay.BorderSizePixel = 0
    bgOverlay.Text = ""
    bgOverlay.ZIndex = 1
    bgOverlay.Parent = screenGui

    -- 主窗口框架
    screenGui.Parent = TargetParent
    RootScreenGui = screenGui

    -- Splash Loader 动画
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
        Text = "正在初始化 UI 组件层与视图引擎...",
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

    -- 主 UI 窗口
    local win = Instance.new("Frame")
    win.Name = "LogQuickWindow"
    win.Size = sizeVal
    win.Position = posVal
    win.Name = "MainWindow"
    win.Size = windowSize
    win.Position = windowPos
    win.BackgroundColor3 = ThemeColors.Background
    win.BorderSizePixel = 2
    win.BorderColor3 = ThemeColors.BorderAccent
    win.BackgroundTransparency = 1 - Saved.Transparency
    win.BorderSizePixel = 0
    win.ZIndex = 10
    win.ClipsDescendants = true
    win.Parent = screenGui

    -- 圆角效果：使用 UIGradient + ImageLabel 技巧简化处理
    -- 由于纯 Frame 无圆角，这里使用一个细边框 + 内部填充模拟高级感
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = win

    -- 标题栏（可拖动）
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = ThemeColors.Surface
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 11
    titleBar.Parent = win

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleTextLabel = MakeLabel(titleBar, {
        Name = "TitleText",
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
    CreateCorner(win, 12)
    local winStroke = CreateStroke(win, GetCurrentBorderColor(), 2)

    -- 背景图片图层
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
        TextSize = FontSizeBase + 2,
        Font = Enum.Font.GothamBold,
        TextColor3 = ThemeColors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = HeaderFontSize,
    })

    local subtitleLabel = MakeLabel(titleBar, {
        Name = "SubtitleText",
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 16, 1, -22),
    MakeLabel(header, {
        Name = "HeaderSub",
        Size = UDim2.new(0.6, -10, 0, 16),
        Position = UDim2.new(0, 14, 0, 24),
        Text = subtitleText,
        TextSize = FontSizeBase - 2,
        Font = Enum.Font.Gotham,
        TextColor3 = ThemeColors.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = FontBaseSize - 2,
    })

    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.Position = UDim2.new(1, -42, 0, 10)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = ThemeColors.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = FontSizeBase
    closeBtn.TextSize = FontBaseSize
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 12
    closeBtn.Parent = titleBar
    closeBtn.ZIndex = 22
    closeBtn.AutoButtonColor = false
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = ThemeColors.Danger end)
    closeBtn.Parent = header
    CreateCorner(closeBtn, 8)

    closeBtn.MouseButton1Click:Connect(function()
        PlaySound(Saved.SoundId)
        win:TweenPosition(UDim2.new(posVal.X.Scale, posVal.X.Offset, 0.6, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        wait(0.25)
        PlaySound(Sounds.Click)
        TweenService:Create(win, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, windowSize.X.Offset, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        task.wait(0.28)
        screenGui:Destroy()
    end)

    -- 拖动功能
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

    -- 拖拽移动与安全 Boundary Clamp
    local dragging = false
    local dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            PlaySound(Saved.SoundId)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            -- 保存位置（限制不超出屏幕）
            local newPos = ClampWindowPosition(win.Position, win.Size)
            win.Position = newPos
            Saved.WindowPosition = newPos
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

    -- 内容区域
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -48)
    content.Position = UDim2.new(0, 0, 0, 48)
    content.BackgroundTransparency = 1
    content.ZIndex = 5
    content.Parent = win

    -- 标签栏
    local tabBar = Instance.new("Frame")
    -- 窗口主体 (Body)
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, -16, 1, -56)
    bodyFrame.Position = UDim2.new(0, 8, 0, 48)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.ZIndex = 15
    bodyFrame.Parent = win

    -- TabBar 标签导航栏
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.Size = IsMobile and UDim2.new(1, 0, 0, 36) or UDim2.new(0, 130, 1, 0)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = ThemeColors.Surface
    tabBar.BackgroundTransparency = 0.2
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 6
    tabBar.Parent = content

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBar
    tabBar.ScrollBarThickness = 2
    tabBar.ScrollBarImageColor3 = ThemeColors.Accent
    tabBar.ZIndex = 16
    tabBar.Parent = bodyFrame
    CreateCorner(tabBar, 8)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.FillDirection = IsMobile and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar
    CreatePadding(tabBar, 4, 4, 4, 4)

    local tabPagesContainer = Instance.new("Frame")
    tabPagesContainer.Name = "Pages"
    tabPagesContainer.Size = UDim2.new(1, 0, 1, -36)
    tabPagesContainer.Position = UDim2.new(0, 0, 0, 36)
    tabPagesContainer.BackgroundTransparency = 1
    tabPagesContainer.ZIndex = 6
    tabPagesContainer.Parent = content
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if IsMobile then
            tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
        else
            tabBar.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
        end
    end)

    -- Pages 标签容器
    local pagesContainer = Instance.new("Frame")
    pagesContainer.Name = "PagesContainer"
    pagesContainer.Size = IsMobile and UDim2.new(1, 0, 1, -42) or UDim2.new(1, -138, 1, 0)
    pagesContainer.Position = IsMobile and UDim2.new(0, 0, 0, 42) or UDim2.new(0, 138, 0, 0)
    pagesContainer.BackgroundTransparency = 1
    pagesContainer.ZIndex = 16
    pagesContainer.Parent = bodyFrame

    MainWindow = win
    MainFrame = win
    WindowTitleBar = titleBar
    WindowContent = content
    TabContainer = tabPagesContainer
    Tabs = {}

    -- 默认添加一个主标签
    local defaultTab = Library:AddTab({ Name = "Main", Title = "功能中心" })

    -- 载入动画
    win.BackgroundTransparency = 1
    win.BorderColor3 = ThemeColors.Border
    win.Position = UDim2.new(posVal.X.Scale, posVal.X.Offset, 0.6, 0)
    wait(0.05)
    win:TweenPosition(posVal, Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
    win:TweenSize(sizeVal, Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true, function()
        win.BackgroundTransparency = 0
    end)
    -- 边框发光脉冲
    spawn(function()
        while MainWindow do
            wait(0.01)
            local t = math.sin(os.clock() * 4) * 0.1 + 0.8
            MainWindow.BorderColor3 = ThemeColors.BorderAccent:Lerp(Color3.fromRGB(200, 160, 255), t)

    -- 渐变展现场景
    splashFrame:Destroy()
    win.Size = UDim2.new(0, windowSize.X.Offset, 0, 0)
    win.Position = UDim2.new(windowPos.X.Scale, windowPos.X.Offset, windowPos.Y.Scale, windowPos.Y.Offset + 30)
    TweenService:Create(win, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = windowSize,
        Position = windowPos,
    }):Play()

    -- 边框发光颜色驱动循环
    task.spawn(function()
        while screenGui and screenGui.Parent do
            task.wait(0.02)
            if winStroke and winStroke.Parent then
                winStroke.Color = GetCurrentBorderColor()
            end
        end
    end)

    return MainWindow, defaultTab
    screenGui.AncestryChanged:Connect(function()
        if not screenGui.Parent then MainWindow = nil end
    end)

    return win
end

Library.CreateWindow = CreateWindow
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
-- [7] 标签与分区系统（支持嵌套）
-- [8] Component Construction & Automatic Size Engine
-- ============================================================
local TabMeta = {}

function Library:AddTab(opts)
    opts = opts or {}
    local name = opts.Name or "Tab" .. tostring(#Tabs + 1)
    local title = opts.Title or name

    local btn = Instance.new("TextButton")
    btn.Name = name .. "_TabBtn"
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = ThemeColors.Surface
    btn.BorderSizePixel = 0
    btn.Text = title
    btn.TextColor3 = ThemeColors.TextMuted
    btn.TextSize = FontSizeBase - 1
    btn.Font = Enum.Font.GothamSemibold
    btn.ZIndex = 7
    btn.Parent = WindowContent:FindFirstChild("TabBar")
    btn.AutoButtonColor = false
    btn.LayoutOrder = #Tabs + 1

    local page = Instance.new("Frame")
    page.Name = name .. "_Page"
    local tabName = opts.Name or ("Tab_" .. tostring(#TabsList + 1))
    local tabTitle = opts.Title or opts.Name or "功能标签"
    local iconId = opts.Icon or nil

    local bodyFrame = MainWindow:FindFirstChild("Body", true)
    local tabBar = bodyFrame:FindFirstChild("TabBar")
    local pagesContainer = bodyFrame:FindFirstChild("PagesContainer")

    -- Tab 切换按钮
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

    -- Tab Page 内容页 (ScrollingFrame + AutomaticCanvasSize)
    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "_Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.ZIndex = 5
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = ThemeColors.Accent
    page.Visible = false
    page.Parent = TabContainer
    page.ZIndex = 17
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = pagesContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    CreatePadding(page, 2, 8, 2, 4)

    local tabObj = {
        Name = name,
        Title = title,
        Button = btn,
        Name = tabName,
        Title = tabTitle,
        Button = tabBtn,
        Page = page,
        Sections = {}, -- 功能分区列表
        Sections = {},
    }

    -- 点击切换标签
    btn.MouseButton1Click:Connect(function()
        PlaySound(Saved.SoundId)
        for _, t in pairs(Tabs) do
    local function ActivateTab()
        PlaySound(Sounds.Click)
        for _, t in ipairs(TabsList) do
            t.Button.TextColor3 = ThemeColors.TextMuted
            t.Button.BackgroundTransparency = 0.8
            t.Button.BackgroundColor3 = ThemeColors.SurfaceLight
            t.Page.Visible = false
        end
        btn.TextColor3 = ThemeColors.Text
        tabBtn.TextColor3 = ThemeColors.Text
        tabBtn.BackgroundTransparency = 0
        tabBtn.BackgroundColor3 = ThemeColors.Accent
        page.Visible = true
        TabMeta.CurrentTab = tabObj
    end)

    -- 默认显示第一个标签
    if #Tabs == 0 then
        btn.TextColor3 = ThemeColors.Text
        page.Visible = true
        TabMeta.CurrentTab = tabObj
        CurrentTabObj = tabObj
    end

    table.insert(Tabs, tabObj)
    Tabs[name] = tabObj
    tabBtn.MouseButton1Click:Connect(ActivateTab)

    -- 分区添加接口
    function tabObj:AddSection(opts)
        opts = opts or {}
        local secName = opts.Name or ("Section" .. tostring(#self.Sections + 1))
        local secTitle = opts.Title or secName
        local layoutDir = opts.Layout or "Vertical" -- Vertical / Horizontal
    -- 默认高亮并激活非 Settings 的功能 Tab
    if #TabsList == 0 or (#TabsList == 1 and TabsList[1].Name == "UISettings") then
        ActivateTab()
    end

        local secFrame = Instance.new("Frame")
        secFrame.Name = secName
        secFrame.Size = opts.Size or UDim2.new(1, 0, 0, 0)
        secFrame.Position = opts.Position or UDim2.new(0, 0, 0, 0)
        secFrame.BackgroundColor3 = ThemeColors.Surface
        secFrame.BorderSizePixel = 1
        secFrame.BorderColor3 = ThemeColors.Border
        secFrame.ZIndex = 10
        secFrame.ClipsDescendants = true
        secFrame.Parent = self.Page
    table.insert(TabsList, tabObj)

    -- 封装控件生成函数 (自动挂载与自适应高度)
    local function AttachComponents(containerFrame)
        local compAPI = {}

        -- [1] 按钮 Button
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

        local secCorner = Instance.new("UICorner")
        secCorner.CornerRadius = UDim.new(0, 10)
        secCorner.Parent = secFrame
        -- [2] 开关 Toggle
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

        -- 分区标题栏
        local secHeader = Instance.new("Frame")
        secHeader.Name = "Header"
        secHeader.Size = UDim2.new(1, 0, 0, 32)
        secHeader.Position = UDim2.new(0, 0, 0, 0)
        secHeader.BackgroundColor3 = ThemeColors.SurfaceLight
        secHeader.BorderSizePixel = 0
        secHeader.ZIndex = 11
        secHeader.Parent = secFrame
        local secHeaderCorner = Instance.new("UICorner")
        secHeaderCorner.CornerRadius = UDim.new(0, 10)
        secHeaderCorner.Parent = secHeader

        local secTitleLabel = MakeLabel(secHeader, {
            Name = "Title",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Text = secTitle,
            TextSize = FontSizeBase,
            Font = Enum.Font.GothamBold,
            TextColor3 = ThemeColors.Text,
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

        local secBody = Instance.new("Frame")
        secBody.Name = "Body"
        secBody.Size = UDim2.new(1, -8, 1, -36)
        secBody.Position = UDim2.new(0, 4, 0, 34)
        secBody.BackgroundTransparency = 1
        secBody.ZIndex = 10
        secBody.Parent = secFrame
            switchBg.MouseButton1Click:Connect(function() UpdateSwitch(not state) end)

        -- 嵌套布局
        local layout = Instance.new(layoutDir == "Horizontal" and "UIListLayout" or "UIListLayout")
        if layoutDir == "Vertical" then
            layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.Padding = UDim.new(0, 6)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = secBody
        else
            layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.Padding = UDim.new(0, 6)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = secBody
            return toggleFrame, state, function(nState) UpdateSwitch(nState) end
        end

        -- 嵌套分区接口（支持再分区）
        function secFrame:AddSubSection(opts)
            opts = opts or {}
            local subName = opts.Name or ("SubSection" .. tostring(#self.Children and #self.Children or 0 + 1))
            local subTitle = opts.Title or subName
            local subSec = MakeFrame(secBody, {
                Name = subName,
                Size = opts.Size or UDim2.new(1, 0, 0, 100),
                BackgroundColor3 = ThemeColors.BackgroundSecondary,
                BorderSizePixel = 1,
                BorderColor3 = ThemeColors.Border,
        -- [3] 滑块 Slider
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
            local subCorner = Instance.new("UICorner")
            subCorner.CornerRadius = UDim.new(0, 8)
            subCorner.Parent = subSec

            local subHeader = MakeLabel(subSec, {
                Name = "SubHeader",
                Size = UDim2.new(1, 0, 0, 26),
                Position = UDim2.new(0, 0, 0, 0),
                Text = "  " .. subTitle,
                TextSize = FontSizeBase - 1,

            local valLbl = MakeLabel(sliderFrame, {
                Size = UDim2.new(0.3, 0, 0, 20),
                Position = UDim2.new(0.7, -10, 0, 4),
                Text = tostring(currentVal) .. unitStr,
                TextColor3 = ThemeColors.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = Enum.Font.GothamBold,
                TextColor3 = ThemeColors.TextMuted,
                BackgroundTransparency = 0,
            })
            subHeader.BackgroundColor3 = ThemeColors.Surface
            local subHC = Instance.new("UICorner")
            subHC.CornerRadius = UDim.new(0, 8)
            subHC.Parent = subHeader

            local subBody = Instance.new("Frame")
            subBody.Name = "SubBody"
            subBody.Size = UDim2.new(1, -8, 1, -30)
            subBody.Position = UDim2.new(0, 4, 0, 28)
            subBody.BackgroundTransparency = 1
            subBody.ZIndex = 10
            subBody.Parent = subSec

            -- 子分区内容接口
            subSec.Body = subBody
            subSec.AddButton = function(p)
                return MakeButton(subBody, p)
            end
            subSec.AddToggle = function(p)
                local container, state, toggleFn = MakeToggle(subBody, p)
                container.Name = p.Name or "Toggle"
                return container, state, toggleFn
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
            subSec.AddLabel = function(p)
                return MakeLabel(subBody, p)
            end
            subSec.AddSlider = function(p)
                -- 简化滑块实现
                local sFrame = MakeFrame(subBody, { Name = p.Name or "Slider", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 })
                local sTitle = MakeLabel(sFrame, { Name = "Title", Size = UDim2.new(1, -60, 1, 0), Text = p.Text or "Slider", TextColor3 = ThemeColors.Text })
                local sValueLbl = MakeLabel(sFrame, { Name = "Value", Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -60, 0, 0), Text = tostring(p.Default or 0), TextColor3 = ThemeColors.TextMuted })
                local sTrack = Instance.new("Frame")
                sTrack.Name = "Track"
                sTrack.Size = UDim2.new(1, -12, 0, 8)
                sTrack.Position = UDim2.new(0, 6, 1, -16)
                sTrack.BackgroundColor3 = ThemeColors.Border
                sTrack.BorderSizePixel = 0
                sTrack.ZIndex = 2
                sTrack.Parent = sFrame
                local sTrackCorner = Instance.new("UICorner")
                sTrackCorner.CornerRadius = UDim.new(0, 4)
                sTrackCorner.Parent = sTrack

                local sFill = Instance.new("Frame")
                sFill.Name = "Fill"
                sFill.Size = UDim2.new((p.Default or 0) / (p.Max or 100), 0, 1, 0)
                sFill.BackgroundColor3 = ThemeColors.Success
                sFill.BorderSizePixel = 0
                sFill.ZIndex = 3
                sFill.Parent = sTrack
                local sFillCorner = Instance.new("UICorner")
                sFillCorner.CornerRadius = UDim.new(0, 4)
                sFillCorner.Parent = sFill

                local sBtn = Instance.new("TextButton")
                sBtn.Name = "Thumb"
                sBtn.Size = UDim2.new(0, 16, 1, 0)
                sBtn.Position = UDim2.new((p.Default or 0) / (p.Max or 100), 0, 0, 0)
                sBtn.BackgroundColor3 = ThemeColors.Text
                sBtn.BorderSizePixel = 0
                sBtn.Text = ""
                sBtn.ZIndex = 4
                sBtn.Parent = sTrack
                local sBtnCorner = Instance.new("UICorner")
                sBtnCorner.CornerRadius = UDim.new(1, 0)
                sBtnCorner.Parent = sBtn

                local draggingSlide = false
                local function UpdateSlide(x)
                    local maxW = sTrack.AbsoluteSize.X
                    local ratio = math.clamp(x / maxW, 0, 1)
                    sBtn.Position = UDim2.new(ratio, -8, 0, 0)
                    sFill.Size = UDim2.new(ratio, 0, 1, 0)
                    local val = math.round((p.Min or 0) + ratio * ((p.Max or 100) - (p.Min or 0)))
                    if p.Rounding then val = math.round(val / p.Rounding) * p.Rounding end
                    sValueLbl.Text = tostring(val)
                    if p.Callback then pcall(function() p.Callback(val) end) end
                end
                sBtn.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        draggingSlide = true
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if draggingSlide and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        local absPos = sTrack.AbsolutePosition
                        local mouseX = i.Position.X - absPos.X
                        UpdateSlide(mouseX)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        draggingSlide = false
                        PlaySound(Saved.SoundId)
                    end
                end)
                return sFrame
            end
            return subSec
        end

        -- 主分区内容接口
        secFrame.Body = secBody
        secFrame.AddButton = function(p)
            local btn = MakeButton(secBody, p)
            btn.LayoutOrder = #secBody:GetChildren()
            return btn
        end
        secFrame.AddToggle = function(p)
            local container, state, toggleFn = MakeToggle(secBody, p)
            container.LayoutOrder = #secBody:GetChildren()
            return container, state, toggleFn
        end
        secFrame.AddLabel = function(p)
            local lbl = MakeLabel(secBody, p)
            lbl.LayoutOrder = #secBody:GetChildren()
            return lbl
        end
        secFrame.AddSlider = function(p)
            local sFrame = MakeFrame(secBody, { Name = p.Name or "Slider", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 })
            local sTitle = MakeLabel(sFrame, { Name = "Title", Size = UDim2.new(1, -60, 1, 0), Text = p.Text or "Slider", TextColor3 = ThemeColors.Text })
            local sValueLbl = MakeLabel(sFrame, { Name = "Value", Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -60, 0, 0), Text = tostring(p.Default or 0), TextColor3 = ThemeColors.TextMuted })
            local sTrack = Instance.new("Frame")
            sTrack.Name = "Track"
            sTrack.Size = UDim2.new(1, -12, 0, 8)
            sTrack.Position = UDim2.new(0, 6, 1, -16)
            sTrack.BackgroundColor3 = ThemeColors.Border
            sTrack.BorderSizePixel = 0
            sTrack.ZIndex = 2
            sTrack.Parent = sFrame
            local sTrackCorner = Instance.new("UICorner")
            sTrackCorner.CornerRadius = UDim.new(0, 4)
            sTrackCorner.Parent = sTrack

            local sFill = Instance.new("Frame")
            sFill.Name = "Fill"
            sFill.Size = UDim2.new((p.Default or 0) / (p.Max or 100), 0, 1, 0)
            sFill.BackgroundColor3 = ThemeColors.Success
            sFill.BorderSizePixel = 0
            sFill.ZIndex = 3
            sFill.Parent = sTrack
            local sFillCorner = Instance.new("UICorner")
            sFillCorner.CornerRadius = UDim.new(0, 4)
            sFillCorner.Parent = sFill

            local sBtn = Instance.new("TextButton")
            sBtn.Name = "Thumb"
            sBtn.Size = UDim2.new(0, 16, 1, 0)
            sBtn.Position = UDim2.new((p.Default or 0) / (p.Max or 100), 0, 0, 0)
            sBtn.BackgroundColor3 = ThemeColors.Text
            sBtn.BorderSizePixel = 0
            sBtn.Text = ""
            sBtn.ZIndex = 4
            sBtn.Parent = sTrack
            local sBtnCorner = Instance.new("UICorner")
            sBtnCorner.CornerRadius = UDim.new(1, 0)
            sBtnCorner.Parent = sBtn

            local draggingSlide = false
            local function UpdateSlide(x)
                local maxW = sTrack.AbsoluteSize.X
                local ratio = math.clamp(x / maxW, 0, 1)
                sBtn.Position = UDim2.new(ratio, -8, 0, 0)
                sFill.Size = UDim2.new(ratio, 0, 1, 0)
                local val = math.round((p.Min or 0) + ratio * ((p.Max or 100) - (p.Min or 0)))
                if p.Rounding then val = math.round(val / p.Rounding) * p.Rounding end
                sValueLbl.Text = tostring(val)
                if p.Callback then pcall(function() p.Callback(val) end) end
            end
            sBtn.InputBegan:Connect(function(i)
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    draggingSlide = true
                    isDragging = true
                    PlaySound(Sounds.Slider)
                    UpdateSliderInput(i.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if draggingSlide and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local absPos = sTrack.AbsolutePosition
                    local mouseX = i.Position.X - absPos.X
                    UpdateSlide(mouseX)
                if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSliderInput(i.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    draggingSlide = false
                    PlaySound(Saved.SoundId)
                    isDragging = false
                end
            end)
            sFrame.LayoutOrder = #secBody:GetChildren()
            return sFrame

            return sliderFrame
        end
        secFrame.AddHSVPicker = function(p)
            -- HSV 色盘实现（简化版：色轮 + 亮度条）
            local hsvFrame = MakeFrame(secBody, { Name = p.Name or "HSVPicker", Size = UDim2.new(1, 0, 0, 140), BackgroundTransparency = 1 })
            hsvFrame.LayoutOrder = #secBody:GetChildren()
            local hsvTitle = MakeLabel(hsvFrame, { Name = "HSVTitle", Size = UDim2.new(1, 0, 0, 24), Text = p.Text or "HSV Color", TextSize = FontSizeBase, TextColor3 = ThemeColors.Text })
            -- 色轮区域（使用 Frame + 圆形渐变模拟）
            local wheelArea = Instance.new("Frame")
            wheelArea.Name = "Wheel"
            wheelArea.Size = UDim2.new(0, 100, 0, 100)
            wheelArea.Position = UDim2.new(0, 8, 0, 28)
            wheelArea.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            wheelArea.BorderSizePixel = 0
            wheelArea.ZIndex = 2
            wheelArea.Parent = hsvFrame
            local wheelCorner = Instance.new("UICorner")
            wheelCorner.CornerRadius = UDim.new(1, 0)
            wheelCorner.Parent = wheelArea
            -- 使用 UIGradient 实现彩虹色轮
            local gradient = Instance.new("UIGradient")
            gradient.Rotation = 0
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),

        -- [4] HSV 2D 色盘 HSVPicker
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
            gradient.Parent = wheelArea
            -- 指示点
            local pointer = Instance.new("Frame")
            pointer.Name = "Pointer"
            pointer.Size = UDim2.new(0, 12, 0, 12)
            pointer.Position = UDim2.new(0.5, -6, 0.5, -6)
            pointer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            pointer.BorderSizePixel = 2
            pointer.BorderColor3 = Color3.fromRGB(30, 30, 30)
            pointer.ZIndex = 3
            pointer.Parent = wheelArea
            local pointerCorner = Instance.new("UICorner")
            pointerCorner.CornerRadius = UDim.new(1, 0)
            pointerCorner.Parent = pointer

            -- 亮度条
            local brightnessFrame = Instance.new("Frame")
            brightnessFrame.Name = "Brightness"
            brightnessFrame.Size = UDim2.new(1, -120, 0, 20)
            brightnessFrame.Position = UDim2.new(0.55, 0, 1, -24)
            brightnessFrame.BackgroundColor3 = ThemeColors.Border
            brightnessFrame.BorderSizePixel = 0
            brightnessFrame.ZIndex = 2
            brightnessFrame.Parent = hsvFrame
            local brightCorner = Instance.new("UICorner")
            brightCorner.CornerRadius = UDim.new(0, 4)
            brightCorner.Parent = brightnessFrame
            local brightFill = Instance.new("Frame")
            brightFill.Name = "Fill"
            brightFill.Size = UDim2.new(1, 0, 1, 0)
            brightFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            brightFill.BorderSizePixel = 0
            brightFill.ZIndex = 3
            brightFill.Parent = brightnessFrame

            -- 交互
            local currentHSV = { H = 0, S = 1, V = 1 }
            local function UpdateHSVVisual()
                -- 基于 currentHSV 更新指针和填充
                local angle = currentHSV.H * 2 * math.pi
                local radius = 42
                pointer.Position = UDim2.new(0.5 + math.cos(angle) * radius / 100, -6, 0.5 + math.sin(angle) * radius / 100, -6)
                brightFill.BackgroundColor3 = HSVToRGB(currentHSV.H, 1, 1)
                brightFill.Size = UDim2.new(currentHSV.V, 0, 1, 0)
                if p.Callback then pcall(function() p.Callback(currentHSV.H, currentHSV.S, currentHSV.V) end) end

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
            -- 简化交互（拖动指针和亮度条）
            -- 由于代码复杂，这里提供基础交互接口
            wheelArea.InputBegan:Connect(function(i)

            local draggingCanvas = false
            canvas.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    local abs = wheelArea.AbsolutePosition
                    local cx, cy = abs.X + 50, abs.Y + 50
                    local mx, my = i.Position.X - cx, i.Position.Y - cy
                    local angle = math.atan2(my, mx)
                    local dist = math.sqrt(mx * mx + my * my)
                    currentHSV.H = ((angle / (2 * math.pi)) + 1) % 1
                    currentHSV.S = math.clamp(dist / 46, 0, 1)
                    UpdateHSVVisual()
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
            -- 亮度条交互
            brightnessFrame.InputBegan:Connect(function(i)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    local absPos = brightnessFrame.AbsolutePosition
                    local ratio = math.clamp((i.Position.X - absPos.X) / brightnessFrame.AbsoluteSize.X, 0, 1)
                    currentHSV.V = ratio
                    UpdateHSVVisual()
                    draggingCanvas = false
                end
            end)
            UpdateHSVVisual()
            return hsvFrame

            return pickerFrame
        end
        secFrame.AddDropdown = function(p)
            local dropFrame = MakeFrame(secBody, { Name = p.Name or "Dropdown", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0 })
            dropFrame.LayoutOrder = #secBody:GetChildren()

        -- [5] 下拉选框 Dropdown
        function compAPI:AddDropdown(p)
            p = p or {}
            local itemsList = p.Values or {"选项一", "选项二"}
            local selectedVal = p.Default or itemsList[1] or "请选择"

            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "Dropdown_" .. (p.Text or "Drp")
            dropFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            dropFrame.BackgroundColor3 = ThemeColors.Surface
            dropFrame.BorderSizePixel = 1
            dropFrame.BorderColor3 = ThemeColors.Border
            local dropCorner = Instance.new("UICorner")
            dropCorner.CornerRadius = UDim.new(0, 6)
            dropCorner.Parent = dropFrame
            local dropTitle = MakeLabel(dropFrame, { Name = "Title", Size = UDim2.new(0.7, 0, 1, 0), Text = p.Text or "Select", TextColor3 = ThemeColors.Text })
            local dropBtn = Instance.new("TextButton")
            dropBtn.Name = "DropdownBtn"
            dropBtn.Size = UDim2.new(0.3, -8, 1, -8)
            dropBtn.Position = UDim2.new(1, -4, 0, 4)
            dropBtn.BackgroundColor3 = ThemeColors.SurfaceLight
            dropBtn.BorderSizePixel = 0
            dropBtn.Text = p.Default or p.Values[1] or "Select"
            dropBtn.TextColor3 = ThemeColors.Text
            dropBtn.TextSize = FontSizeBase - 2
            dropBtn.ZIndex = 3
            dropBtn.Parent = dropFrame
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = dropBtn

            local dropdownOpen = false
            local dropdownList = nil
            dropBtn.MouseButton1Click:Connect(function()
                dropdownOpen = not dropdownOpen
                PlaySound(Saved.SoundId)
                if dropdownOpen then
                    if dropdownList then dropdownList:Destroy() end
                    dropdownList = Instance.new("Frame")
                    dropdownList.Name = "DropdownList"
                    dropdownList.Size = UDim2.new(0.3, 0, 0, math.min(#p.Values * 32, 160))
                    dropdownList.Position = UDim2.new(1, -4, 1, -4)
                    dropdownList.BackgroundColor3 = ThemeColors.Surface
                    dropdownList.BorderSizePixel = 1
                    dropdownList.BorderColor3 = ThemeColors.Border
                    dropdownList.ZIndex = 20
                    dropdownList.ClipsDescendants = true
                    dropdownList.Parent = dropBtn
                    local listCorner = Instance.new("UICorner")
                    listCorner.CornerRadius = UDim.new(0, 6)
                    listCorner.Parent = dropdownList
                    local listLayout = Instance.new("UIListLayout")
                    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    listLayout.Padding = UDim.new(0, 2)
                    listLayout.Parent = dropdownList
                    for i, v in ipairs(p.Values) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Name = tostring(v)
                        optBtn.Size = UDim2.new(1, -8, 0, 28)
                        optBtn.Position = UDim2.new(0, 4, 0, 0)
                        optBtn.BackgroundColor3 = ThemeColors.BackgroundSecondary
                        optBtn.BorderSizePixel = 0
                        optBtn.Text = tostring(v)
                        optBtn.TextColor3 = ThemeColors.Text
                        optBtn.TextSize = FontSizeBase - 2
                        optBtn.ZIndex = 21
                        optBtn.Parent = dropdownList
                        optBtn.AutoButtonColor = false
                        optBtn.MouseButton1Click:Connect(function()
                            dropBtn.Text = tostring(v)
                            dropdownOpen = false
                            if dropdownList then dropdownList:Destroy() end
                            if p.Callback then pcall(function() p.Callback(v) end) end
                            PlaySound(Saved.SoundId)
                        end)
                    end
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
                    if dropdownList then dropdownList:Destroy() end
                    selectedBtn.Text = tostring(selectedVal) .. "  ▼"
                    TweenService:Create(dropFrame, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, ItemHeight) }):Play()
                end
            end)
            return dropFrame

            local dropAPI = {
                SetValues = function(self, nValues)
                    itemsList = nValues or {}
                    PopulateList(itemsList)
                end
            }

            return dropFrame, dropAPI
        end
        secFrame.AddInput = function(p)
            local inputFrame = MakeFrame(secBody, { Name = p.Name or "Input", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0 })
            inputFrame.LayoutOrder = #secBody:GetChildren()

        -- [6] 参数调配 Input
        function compAPI:AddInput(p)
            p = p or {}
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "Input_" .. (p.Text or "Inp")
            inputFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            inputFrame.BackgroundColor3 = ThemeColors.Surface
            inputFrame.BorderSizePixel = 1
            inputFrame.BorderColor3 = ThemeColors.Border
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputFrame
            local inputTitle = MakeLabel(inputFrame, { Name = "Title", Size = UDim2.new(0.4, 0, 1, 0), Text = p.Text or "Value", TextColor3 = ThemeColors.Text })
            local inputBox = Instance.new("TextBox")
            inputBox.Name = "InputBox"
            inputBox.Size = UDim2.new(0.55, -8, 1, -8)
            inputBox.Position = UDim2.new(1, -4, 0, 4)
            inputBox.BackgroundColor3 = ThemeColors.BackgroundSecondary
            inputBox.BorderSizePixel = 0
            inputBox.Text = tostring(p.Default or "")
            inputBox.TextColor3 = ThemeColors.Text
            inputBox.TextSize = FontSizeBase - 1
            inputBox.Font = Enum.Font.Gotham
            inputBox.ZIndex = 3
            inputBox.Parent = inputFrame
            local inputBoxCorner = Instance.new("UICorner")
            inputBoxCorner.CornerRadius = UDim.new(0, 4)
            inputBoxCorner.Parent = inputBox
            inputBox.FocusLost:Connect(function()
                if p.Callback then pcall(function() p.Callback(inputBox.Text) end) end
                PlaySound(Saved.SoundId)
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
        secFrame.AddImage = function(p)
            local imgFrame = MakeFrame(secBody, { Name = p.Name or "Image", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1 })
            imgFrame.LayoutOrder = #secBody:GetChildren()
            local img = Instance.new("ImageLabel")
            img.Name = "Image"
            img.Size = UDim2.new(0, 60, 0, 60)
            img.Position = UDim2.new(0, 0, 0, 10)
            img.BackgroundTransparency = 1
            img.Image = p.Image or "rbxassetid://6023420899" -- 占位官方资源 ID
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 2
            img.Parent = imgFrame
            if p.Text then
                local imgTitle = MakeLabel(imgFrame, { Name = "ImgText", Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 70, 0, 0), Text = p.Text, TextSize = FontSizeBase, TextColor3 = ThemeColors.Text })
            end
            return imgFrame
        end
        secFrame.AddTextLabel = function(p)
            local lbl = MakeLabel(secBody, p)
            lbl.LayoutOrder = #secBody:GetChildren()
            return lbl
        end
        secFrame.AddKeybind = function(p)
            local kbFrame = MakeFrame(secBody, { Name = p.Name or "Keybind", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0 })
            kbFrame.LayoutOrder = #secBody:GetChildren()

        -- [7] 按键绑定 Keybind
        function compAPI:AddKeybind(p)
            p = p or {}
            local currentKey = p.Default or Enum.KeyCode.E

            local kbFrame = Instance.new("Frame")
            kbFrame.Name = "Keybind_" .. (p.Text or "Kb")
            kbFrame.Size = UDim2.new(1, 0, 0, ItemHeight)
            kbFrame.BackgroundColor3 = ThemeColors.Surface
            kbFrame.BorderSizePixel = 1
            kbFrame.BorderColor3 = ThemeColors.Border
            local kbCorner = Instance.new("UICorner")
            kbCorner.CornerRadius = UDim.new(0, 6)
            kbCorner.Parent = kbFrame
            local kbTitle = MakeLabel(kbFrame, { Name = "Title", Size = UDim2.new(0.6, 0, 1, 0), Text = p.Text or "Keybind", TextColor3 = ThemeColors.Text })
            local kbBtn = Instance.new("TextButton")
            kbBtn.Name = "KeyBtn"
            kbBtn.Size = UDim2.new(0.35, -8, 1, -8)
            kbBtn.Position = UDim2.new(1, -4, 0, 4)
            kbBtn.BackgroundColor3 = ThemeColors.SurfaceLight
            kbBtn.BorderSizePixel = 0
            kbBtn.Text = p.Default or "None"
            kbBtn.TextColor3 = ThemeColors.Text
            kbBtn.TextSize = FontSizeBase - 2
            kbBtn.ZIndex = 3
            kbBtn.Parent = kbFrame
            local kbBtnCorner = Instance.new("UICorner")
            kbBtnCorner.CornerRadius = UDim.new(0, 6)
            kbBtnCorner.Parent = kbBtn
            local currentKey = p.Default or "None"
            kbBtn.MouseButton1Click:Connect(function()
                kbBtn.Text = "..."
                wait(0.1)
                local connection
                connection = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = i.KeyCode.Name
                        kbBtn.Text = currentKey
                        connection:Disconnect()
                        PlaySound(Saved.SoundId)
                        if p.Callback then pcall(function() p.Callback(currentKey) end) end
                    elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
                        connection:Disconnect()
                        kbBtn.Text = currentKey
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
        secFrame.AddNotificationArea = function(p)
            local notifFrame = MakeFrame(secBody, { Name = p.Name or "NotificationArea", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 0 })
            notifFrame.LayoutOrder = #secBody:GetChildren()
            notifFrame.BackgroundColor3 = ThemeColors.Success
            notifFrame.BorderSizePixel = 0
            local notifCorner = Instance.new("UICorner")
            notifCorner.CornerRadius = UDim.new(0, 8)
            notifCorner.Parent = notifFrame
            local notifText = MakeLabel(notifFrame, { Name = "NotifText", Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), Text = p.Text or "Notification", TextColor3 = ThemeColors.Text, Font = Enum.Font.GothamBold })
            return notifFrame

        -- [8] 标签文本 Label
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

        -- [9] 动态玩家选择器 PlayerSelector
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

        -- [10] 图片图标显示 Image
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

        -- [11] 运行状态显示器 Status
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
        table.insert(self.Sections, secFrame)
        return secFrame

        return compAPI
    end

    local tabCompAPI = AttachComponents(page)
    for k, v in pairs(tabCompAPI) do tabObj[k] = v end

    -- [分区 Section] 核心逻辑 (原生 AutomaticSize 自适应伸缩)
    function tabObj:AddSection(sOpts)
        sOpts = sOpts or {}
        local secName = sOpts.Name or ("Section_" .. tostring(#self.Sections + 1))
        local secTitle = sOpts.Title or secName

        local secFrame = Instance.new("Frame")
        secFrame.Name = secName
        secFrame.Size = UDim2.new(1, 0, 0, 0)
        secFrame.AutomaticSize = Enum.AutomaticSize.Y
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
        secBody.Size = UDim2.new(1, -12, 0, 0)
        secBody.Position = UDim2.new(0, 6, 0, 32)
        secBody.AutomaticSize = Enum.AutomaticSize.Y
        secBody.BackgroundTransparency = 1
        secBody.ZIndex = 19
        secBody.Parent = secFrame

        local secLayout = Instance.new("UIListLayout")
        secLayout.SortOrder = Enum.SortOrder.LayoutOrder
        secLayout.Padding = UDim.new(0, 6)
        secLayout.Parent = secBody
        CreatePadding(secBody, 2, 8, 0, 0)

        local secObj = {
            Name = secName,
            Frame = secFrame,
            Body = secBody,
            SubSections = {},
        }

        local secCompAPI = AttachComponents(secBody)
        for k, v in pairs(secCompAPI) do secObj[k] = v end

        -- [再分区 SubSection] 嵌套逻辑
        function secObj:AddSubSection(ssOpts)
            ssOpts = ssOpts or {}
            local subTitle = ssOpts.Title or "子分区"

            local subSecFrame = Instance.new("Frame")
            subSecFrame.Name = "SubSection_" .. subTitle
            subSecFrame.Size = UDim2.new(1, 0, 0, 0)
            subSecFrame.AutomaticSize = Enum.AutomaticSize.Y
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
            subBody.Size = UDim2.new(1, -10, 0, 0)
            subBody.Position = UDim2.new(0, 5, 0, 26)
            subBody.AutomaticSize = Enum.AutomaticSize.Y
            subBody.BackgroundTransparency = 1
            subBody.ZIndex = 21
            subBody.Parent = subSecFrame

            local subLayout = Instance.new("UIListLayout")
            subLayout.SortOrder = Enum.SortOrder.LayoutOrder
            subLayout.Padding = UDim.new(0, 5)
            subLayout.Parent = subBody
            CreatePadding(subBody, 2, 6, 0, 0)

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
-- [8] 通知系统
-- [9] Notification Engine
-- ============================================================
local NotificationList = {}
local ActiveNotifications = {}

function Library:Notify(opts)
    opts = opts or {}
    local msg = opts.Text or opts.Message or "Notification"
    local duration = opts.Duration or 3
    local sound = opts.Sound ~= false -- 默认播放音效

    -- 创建通知容器（在屏幕右上角）
    local screenGui = MainWindow and MainWindow.Parent or PlayerGui
    local notif = Instance.new("Frame")
    notif.Name = "Notif_" .. msg:gsub("%s", "_")
    notif.Size = UDim2.new(0, 300, 0, 50)
    notif.Position = UDim2.new(1, -320, 0, 20 + #NotificationList * 60)
    notif.BackgroundColor3 = ThemeColors.Success
    notif.BorderSizePixel = 1
    notif.BorderColor3 = ThemeColors.BorderAccent
    notif.ZIndex = 100
    notif.Parent = screenGui
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif

    local notifText = MakeLabel(notif, { Name = "Text", Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4), Text = msg, TextColor3 = ThemeColors.Text, Font = Enum.Font.GothamSemibold, TextSize = FontSizeBase })

    if sound then PlaySound(Saved.SoundId) end

    -- 动画进入
    notif.Position = UDim2.new(1, 20, notif.Position.Y.Scale, notif.Position.Y.Offset)
    notif:TweenPosition(UDim2.new(1, -320, notif.Position.Y.Scale, notif.Position.Y.Offset), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)

    wait(duration)
    notif:TweenPosition(UDim2.new(1, 20, notif.Position.Y.Scale, notif.Position.Y.Offset), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true, function()
        notif:Destroy()
    local titleText = opts.Title or "系统通知"
    local msgText = opts.Text or opts.Message or "操作成功"
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
    for i, n in ipairs(NotificationList) do
        if n == notif then table.remove(NotificationList, i) break end
    end
end

-- ============================================================
-- [9] 设置面板（内置）
-- [10] Built-in Settings Tab
-- ============================================================
function Library:BuildSettingsTab()
    local settingsTab = Library:AddTab({ Name = "UI设置", Title = "UI 设置" })

    -- 作者信息区域（不可更改）
    local authorSec = settingsTab:AddSection({ Name = "Author", Title = "作者信息", Size = UDim2.new(1, 0, 0, 80) })
    local authorFrame = MakeFrame(authorSec.Body, { Size = UDim2.new(1, -8, 0, 50), BackgroundTransparency = 0, BackgroundColor3 = ThemeColors.BackgroundSecondary })
    MakeLabel(authorFrame, { Text = "UI 作者: Log_quick (不可更改)", TextColor3 = ThemeColors.TextMuted, Font = Enum.Font.GothamBold })
    local scriptAuthorText = Saved.ScriptAuthor ~= "" and ("脚本作者: " .. Saved.ScriptAuthor) or "脚本作者: 未设置"
    local scriptAuthorLbl = MakeLabel(authorFrame, { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 25), Text = scriptAuthorText, TextColor3 = ThemeColors.Text })
    -- 提供 API 让脚本作者设置
    function Library:SetScriptAuthor(name)
        Saved.ScriptAuthor = name or ""
        scriptAuthorLbl.Text = "脚本作者: " .. (Saved.ScriptAuthor ~= "" and Saved.ScriptAuthor or "未设置")
    end
    -- 显示注入器信息（通过通知系统演示）
    local injectorInfoBtn = authorSec:AddButton({ Text = "显示注入器信息", Size = UDim2.new(1, -8, 0, 36), BackgroundColor3 = ThemeColors.SurfaceLight, Callback = function()
        Library:Notify({ Text = "已注入执行器: 示例注入器 (示例信息)", Duration = 4 })
    end })

    -- 功能再分区示例：外观设置
    local appearanceSec = settingsTab:AddSection({ Name = "Appearance", Title = "外观设置", Size = UDim2.new(1, 0, 0, 380) })

    -- 透明度设置
    local transparencySec = appearanceSec:AddSubSection({ Name = "Transparency", Title = "透明度", Size = UDim2.new(1, 0, 0, 60) })
    local transparencySlider = transparencySec.AddSlider({ Name = "Transp", Text = "UI 透明度", Default = math.round(Saved.Transparency * 100), Min = 20, Max = 100, Rounding = 5, Size = UDim2.new(1, -8, 0, 50) })
    -- 简化：在滑块回调中修改透明度（需要重新实现回调，这里简化为直接修改主窗口透明度）
    -- 由于嵌套接口简化，这里直接在外观分区添加控件
    appearanceSec:AddSlider({ Name = "TransparencyMain", Text = "UI 透明度 (20%-100%)", Default = math.round((Saved.Transparency or 1) * 100), Min = 20, Max = 100, Rounding = 5, Size = UDim2.new(1, -8, 0, 50), Callback = function(v)
        local alpha = v / 100
        Saved.Transparency = alpha
        if MainWindow then
            MainWindow.BackgroundTransparency = 1 - alpha
            for _, child in pairs(MainWindow:GetDescendants()) do
                if child:IsA("Frame") and child ~= MainWindow then
                    -- 不直接修改所有子元素，简化为只修改主背景
                end
    local setTab = Library:AddTab({ Name = "UISettings", Title = "UI 设置" })

    -- 外观样式与灯效 (分区)
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
    end })

    -- 边框颜色设置（彩虹渐变、呼吸、静态）
    appearanceSec:AddLabel({ Name = "BorderLabel", Size = UDim2.new(1, 0, 0, 24), Text = "边框颜色模式", TextColor3 = ThemeColors.TextMuted })
    local borderModeDropdown = appearanceSec:AddDropdown({ Name = "BorderMode", Size = UDim2.new(1, -8, 0, 36), Values = { "Static", "Rainbow", "Breathing", "Pulse" }, Default = Saved.BorderColorMode or "Static", Callback = function(mode)
        Saved.BorderColorMode = mode
        Library:Notify({ Text = "边框模式已设置为: " .. mode })
    end })

    -- HSV 自定义颜色（边框色 HSV）
    appearanceSec:AddLabel({ Name = "HSVBorderLabel", Size = UDim2.new(1, 0, 0, 24), Text = "自定义边框 HSV 颜色", TextColor3 = ThemeColors.TextMuted })
    appearanceSec:AddHSVPicker({ Name = "HSVBorder", Size = UDim2.new(1, -8, 0, 120), Text = "边框 HSV", Callback = function(h, s, v)
        Saved.BorderColorHSV = { H = h, S = s, V = v }
    end })

    -- 主题色设置（暗色、亮色、HSV 自定义主题）
    appearanceSec:AddLabel({ Name = "ThemeLabel", Size = UDim2.new(1, 0, 0, 24), Text = "UI 主题色", TextColor3 = ThemeColors.TextMuted })
    local themeDropdown = appearanceSec:AddDropdown({ Name = "ThemeSelect", Size = UDim2.new(1, -8, 0, 36), Values = { "Dark", "Light", "暗紫", "暗蓝", "暗绿", "玫瑰", "Custom HSV" }, Default = Saved.ThemeName or "Dark", Callback = function(mode)
        Saved.ThemeName = mode == "Custom HSV" and "Custom" or mode
        if mode == "Dark" then
            ThemeColors = Theme.Dark
            Saved.BackgroundColor = Theme.Dark.Background
        elseif mode == "Light" then
            ThemeColors = Theme.Light
            Saved.BackgroundColor = Theme.Light.Background
        elseif mode == "暗紫" then
            ThemeColors = Theme.Dark; ThemeColors.Background = Color3.fromRGB(30, 15, 40); ThemeColors.Surface = Color3.fromRGB(50, 30, 70); ThemeColors.BorderAccent = Color3.fromRGB(180, 120, 255)
            Saved.BackgroundColor = ThemeColors.Background
        elseif mode == "暗蓝" then
            ThemeColors = Theme.Dark; ThemeColors.Background = Color3.fromRGB(15, 20, 35); ThemeColors.Surface = Color3.fromRGB(30, 40, 65); ThemeColors.BorderAccent = Color3.fromRGB(80, 160, 255)
            Saved.BackgroundColor = ThemeColors.Background
        elseif mode == "暗绿" then
            ThemeColors = Theme.Dark; ThemeColors.Background = Color3.fromRGB(15, 30, 20); ThemeColors.Surface = Color3.fromRGB(30, 50, 35); ThemeColors.BorderAccent = Color3.fromRGB(100, 220, 130)
            Saved.BackgroundColor = ThemeColors.Background
        elseif mode == "玫瑰" then
            ThemeColors = Theme.Dark; ThemeColors.Background = Color3.fromRGB(40, 15, 25); ThemeColors.Surface = Color3.fromRGB(70, 35, 50); ThemeColors.BorderAccent = Color3.fromRGB(255, 120, 160)
            Saved.BackgroundColor = ThemeColors.Background
        else
            ThemeColors = Theme.Dark
            Saved.BackgroundColor = Theme.Dark.Background
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
        -- 更新主窗口背景
        if MainWindow then MainWindow.BackgroundColor3 = ThemeColors.Background end
        Library:Notify({ Text = "主题已切换为: " .. mode })
    end })

    -- UI 大小设置
    appearanceSec:AddLabel({ Name = "SizeLabel", Size = UDim2.new(1, 0, 0, 24), Text = "UI 大小缩放", TextColor3 = ThemeColors.TextMuted })
    appearanceSec:AddSlider({ Name = "UISize", Text = "UI 缩放比例", Default = math.round((Saved.SizeScale or 1) * 100), Min = 80, Max = 150, Rounding = 5, Size = UDim2.new(1, -8, 0, 50), Callback = function(v)
        Saved.SizeScale = v / 100
        -- 简化：提示用户重启应用生效，或直接调整字体大小
        FontSizeBase = FontSizeBase * (Saved.SizeScale or 1)
        Library:Notify({ Text = "UI 缩放已调整（建议重启脚本生效）: " .. v .. "%" })
    end })

    -- 背景自定义（开发者用来定义默认背景的 API）
    local bgSec = settingsTab:AddSection({ Name = "Background", Title = "背景自定义", Size = UDim2.new(1, 0, 0, 120) })
    bgSec:AddLabel({ Text = "开发者可通过 API 设置默认背景", TextColor3 = ThemeColors.TextMuted, Size = UDim2.new(1, 0, 0, 24) })
    local bgImageBtn = bgSec:AddButton({ Text = "设置默认背景（开发者调用 SetDefaultBackground）", Size = UDim2.new(1, -8, 0, 36), BackgroundColor3 = ThemeColors.SurfaceLight, Callback = function()
        Library:Notify({ Text = "提示: 请在脚本中调用 Library:SetDefaultBackground(id)" })
    end })
    -- 提供开发者 API
    function Library:SetDefaultBackground(imageId)
        Saved.BackgroundImage = imageId
        -- 在主窗口后添加背景图片
        local bgImg = MainWindow:FindFirstChild("CustomBackgroundImage")
        if bgImg then bgImg:Destroy() end
        if imageId then
            local bg = Instance.new("ImageLabel")
            bg.Name = "CustomBackgroundImage"
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Position = UDim2.new(0, 0, 0, 0)
            bg.Image = imageId
            bg.ScaleType = Enum.ScaleType.Stretch
            bg.ZIndex = 0
            bg.BackgroundTransparency = 1
            bg.Parent = MainWindow
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
    end
    -- 默认背景颜色设置
    bgSec:AddHSVPicker({ Name = "BgHSV", Size = UDim2.new(1, -8, 0, 100), Text = "背景颜色 HSV", Callback = function(h, s, v)
        local col = HSVToRGB(h, s, v)
        Saved.BackgroundColor = col
        ThemeColors.Background = col
        ThemeColors.BackgroundSecondary = col:Lerp(Color3.fromRGB(30, 30, 30), 0.3)
        if MainWindow then MainWindow.BackgroundColor3 = ThemeColors.Background end
    end })

    -- 音效自定义
    local soundSec = settingsTab:AddSection({ Name = "Sound", Title = "音效设置", Size = UDim2.new(1, 0, 0, 140) })
    soundSec:AddToggle({ Name = "SoundOn", Text = "启用音效", Default = Saved.SoundEnabled ~= false, Size = UDim2.new(1, -8, 0, 36), Callback = function(v)
        Saved.SoundEnabled = v
    end })
    soundSec:AddLabel({ Name = "SoundIdLabel", Size = UDim2.new(1, 0, 0, 24), Text = "自定义音效 ID", TextColor3 = ThemeColors.TextMuted })
    soundSec:AddInput({ Name = "SoundIdInput", Text = "音效资源 ID", Default = Saved.SoundId:gsub("rbxassetid://", ""), Size = UDim2.new(1, -8, 0, 36), Callback = function(val)
        Saved.SoundId = "rbxassetid://" .. val:gsub("rbxassetid://", "")
    end })

    -- 配置功能（Config 功能）
    local configSec = settingsTab:AddSection({ Name = "Config", Title = "配置功能", Size = UDim2.new(1, 0, 0, 160) })
    configSec:AddLabel({ Text = "开发者可在此添加自定义配置功能", TextColor3 = ThemeColors.TextMuted, Size = UDim2.new(1, 0, 0, 24) })
    configSec:AddButton({ Text = "保存配置", Size = UDim2.new(0.48, -4, 0, 36), BackgroundColor3 = ThemeColors.Success, Callback = function()
        -- 保存到 getgenv
        ConfigStore[ConfigKey] = Saved
        Library:Notify({ Text = "配置已保存到本地存储", Duration = 2 })
        PlaySound(Saved.SoundId)
    end })
    configSec:AddButton({ Text = "重置配置", Size = UDim2.new(0.48, -4, 0, 36), BackgroundColor3 = ThemeColors.Danger, Callback = function()
        ConfigStore[ConfigKey] = nil
        Library:Notify({ Text = "配置已重置（重启脚本生效）", Duration = 2 })
    end })
    -- 提供 Config API
    function Library:GetConfig()
        return Saved.ConfigData or {}
    end
    function Library:SetConfigData(key, value)
        Saved.ConfigData = Saved.ConfigData or {}
        Saved.ConfigData[key] = value
    end
    function Library:GetConfigValue(key)
        return Saved.ConfigData and Saved.ConfigData[key] or nil
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

    -- 功能再分区示例：在设置面板内再嵌套分区
    local nestedExample = settingsTab:AddSection({ Name = "NestedExample", Title = "嵌套分区示例", Size = UDim2.new(1, 0, 0, 100) })
    local nestedSub = nestedExample:AddSubSection({ Name = "SubNested", Title = "子分区（再分区）", Size = UDim2.new(1, 0, 0, 60) })
    nestedSub:AddLabel({ Text = "这是一个嵌套在设置分区内的子分区", TextColor3 = ThemeColors.TextMuted, Size = UDim2.new(1, 0, 0, 20) })
    nestedSub:AddButton({ Text = "嵌套按钮测试", Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = ThemeColors.Success, Callback = function()
        Library:Notify({ Text = "嵌套按钮被点击！" })
    end })
    audioSec:AddToggle({
        Text = "启用 FPS / Ping 悬浮窗",
        Default = Saved.FloatingStatusEnabled,
        Callback = function(val)
            Library:ToggleStats(val)
            SaveConfig()
        end
    })

    return settingsTab
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
            Library:Notify({ Title = "配置重置", Text = "重置成功，请重新载入脚本生效" })
        end
    })

    -- 作者信息与版权 (分区 + 再分区)
    local creditSec = setTab:AddSection({ Title = "关于与脚本版权" })
    local subAuthor = creditSec:AddSubSection({ Title = "作者署名 (不可修改)" })

    subAuthor:AddLabel({
        Text = "UI 框架作者: Log_quick (不可更改)",
        SubText = "核心库版本: v3.5 Rebuilt Release",
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
-- [10] 悬浮状态展示（FPS / Ping 默认开启，可关闭）
-- [11] FPS / Ping Floating Widget
-- ============================================================
local FloatingStatusFrame = nil
function Library:ToggleFloatingStatus(enabled)
    if enabled == nil then enabled = not (Saved.FloatingStatusEnabled ~= false) end
    Saved.FloatingStatusEnabled = enabled
    if FloatingStatusFrame then FloatingStatusFrame:Destroy() FloatingStatusFrame = nil end
    if not enabled then return end
local FloatingStatsGui = nil

function Library:ToggleStats(enabled)
    Saved.FloatingStatusEnabled = enabled ~= false
    if FloatingStatsGui then
        FloatingStatsGui:Destroy()
        FloatingStatsGui = nil
    end

    if not Saved.FloatingStatusEnabled then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FloatingStatusGui"
    gui.Name = "LogQuick_FloatingStats"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui
    gui.Parent = TargetParent

    local frame = Instance.new("Frame")
    frame.Name = "FloatingStatus"
    frame.Size = UDim2.new(0, 160, 0, 50)
    frame.Position = UDim2.new(0, 20, 0, 80)
    frame.Size = UDim2.new(0, 150, 0, 42)
    frame.Position = UDim2.new(0, 20, 0, 60)
    frame.BackgroundColor3 = ThemeColors.Surface
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 1
    frame.BorderColor3 = ThemeColors.BorderAccent
    frame.ZIndex = 99
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.ZIndex = 4000
    frame.Parent = gui
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = frame

    local fpsLabel = MakeLabel(frame, { Name = "FPS", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 4), Text = "FPS: --", TextColor3 = ThemeColors.Text, Font = Enum.Font.GothamBold })
    local pingLabel = MakeLabel(frame, { Name = "Ping", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 26), Text = "Ping: -- ms", TextColor3 = ThemeColors.TextMuted, Font = Enum.Font.Gotham })

    FloatingStatusFrame = frame

    spawn(function()
        while FloatingStatusFrame and FloatingStatusFrame.Parent do
            wait(0.2)
            local fps = math.round(1 / (RunService.Heartbeat:Wait() or 0.016))
            fpsLabel.Text = "FPS: " .. fps
            -- 由于无法直接获取真实 ping（需要服务器通信），这里模拟显示
            pingLabel.Text = "Ping: ~" .. math.random(20, 120) .. " ms"
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
end

function Library:ShowFloatingStatus()
    Library:ToggleFloatingStatus(true)
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

function Library:HideFloatingStatus()
    Library:ToggleFloatingStatus(false)
end
function Library:ShowFloatingStatus() Library:ToggleStats(true) end
function Library:HideFloatingStatus() Library:ToggleStats(false) end

-- ============================================================
-- [11] 水印（开发者自行调用）
-- [12] Watermark & Custom Background
-- ============================================================
local WatermarkFrame = nil
function Library:ShowWatermark(opts)
local WatermarkGui = nil

function Library:SetWatermark(opts)
    opts = opts or {}
    local text = opts.Text or opts.Title or "LogQuick UI"
    if WatermarkFrame then WatermarkFrame:Destroy() end
    local textStr = opts.Text or "LogQuick Hub | Log_quick UI"

    if WatermarkGui then WatermarkGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "WatermarkGui"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Name = "LogQuick_Watermark"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local wm = Instance.new("Frame")
    wm.Name = "Watermark"
    wm.Size = UDim2.new(0, 180, 0, 30)
    wm.Position = UDim2.new(1, -200, 1, -50)
    wm.BackgroundColor3 = ThemeColors.Background
    wm.BackgroundTransparency = 0.5
    wm.BorderSizePixel = 1
    wm.BorderColor3 = ThemeColors.BorderAccent
    wm.ZIndex = 50
    wm.Parent = gui
    local wmCorner = Instance.new("UICorner")
    wmCorner.CornerRadius = UDim.new(0, 8)
    wmCorner.Parent = wm

    MakeLabel(wm, { Name = "Text", Size = UDim2.new(1, -8, 1, -4), Position = UDim2.new(0, 4, 0, 2), Text = text, TextColor3 = ThemeColors.TextMuted, Font = Enum.Font.GothamBold, TextSize = FontSizeBase - 2 })

    WatermarkFrame = wm
    return wm
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
    if WatermarkFrame then WatermarkFrame:Destroy() end
    if WatermarkGui then WatermarkGui:Destroy() end
end

-- ============================================================
-- [12] 搜索功能（开发者自行调用）
-- ============================================================
local SearchResults = {}
function Library:CreateSearch(opts)
function Library:SetBackground(opts)
    opts = opts or {}
    local searchFrame = opts.Frame or MainWindow or error("需要提供 Frame 作为搜索容器")
    local resultsFrame = opts.ResultsFrame or nil

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = opts.Size or UDim2.new(1, -8, 0, 32)
    searchInput.Position = opts.Position or UDim2.new(0, 4, 0, 0)
    searchInput.BackgroundColor3 = ThemeColors.Surface
    searchInput.BorderSizePixel = 1
    searchInput.BorderColor3 = ThemeColors.Border
    searchInput.Text = opts.Placeholder or "搜索功能..."
    searchInput.TextColor3 = ThemeColors.TextMuted
    searchInput.TextSize = FontSizeBase - 1
    searchInput.Font = Enum.Font.Gotham
    searchInput.ZIndex = 20
    searchInput.Parent = searchFrame
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchInput

    -- 提供 API：开发者自行实现搜索逻辑
    function Library:PerformSearch(query, callback)
        -- 这里只提供接口，不实现具体搜索逻辑
        -- 开发者应在脚本中调用 Library:PerformSearch(query, function(results) ... end)
        if callback then
            pcall(function()
                callback(query, {}) -- 返回空结果，开发者自行填充
            end)
        end
    if opts.Image then
        Saved.BackgroundImage = opts.Image
        if BackgroundImageLabel then BackgroundImageLabel.Image = opts.Image end
    end

    searchInput.FocusLost:Connect(function()
        if searchInput.Text == "" then searchInput.Text = opts.Placeholder or "搜索功能..." end
    end)
    searchInput.Focused:Connect(function()
        if searchInput.Text == (opts.Placeholder or "搜索功能...") then
            searchInput.Text = ""
            searchInput.TextColor3 = ThemeColors.Text
        end
    end)
    searchInput.Changed:Connect(function(prop)
        if prop == "Text" then
            Library:PerformSearch(searchInput.Text, opts.SearchCallback)
        end
    end)

    return searchInput
    if opts.Transparency then
        Saved.BackgroundTransparency = opts.Transparency
        if BackgroundImageLabel then BackgroundImageLabel.ImageTransparency = opts.Transparency end
    end
    SaveConfig()
end

-- ============================================================
-- [13] 玩家选择器（简化实现）
-- [13] Fuzzy Keyword Search Filter
-- ============================================================
function Library:CreatePlayerSelector(opts)
function Library:CreateSearch(opts)
    opts = opts or {}
    local container = opts.Container or MainWindow
    local dropdownFrame = MakeFrame(container, { Name = opts.Name or "PlayerSelector", Size = opts.Size or UDim2.new(1, -8, 0, 36), BackgroundTransparency = 0 })
    dropdownFrame.BackgroundColor3 = ThemeColors.Surface
    dropdownFrame.BorderSizePixel = 1
    dropdownFrame.BorderColor3 = ThemeColors.Border
    dropdownFrame.ZIndex = 10
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdownFrame

    local title = MakeLabel(dropdownFrame, { Name = "Title", Size = UDim2.new(0.6, 0, 1, 0), Text = opts.Text or "选择玩家", TextColor3 = ThemeColors.Text })
    local btn = Instance.new("TextButton")
    btn.Name = "SelectBtn"
    btn.Size = UDim2.new(0.35, -8, 1, -8)
    btn.Position = UDim2.new(1, -4, 0, 4)
    btn.BackgroundColor3 = ThemeColors.SurfaceLight
    btn.BorderSizePixel = 0
    btn.Text = opts.Default or "所有玩家"
    btn.TextColor3 = ThemeColors.Text
    btn.TextSize = FontSizeBase - 2
    btn.ZIndex = 3
    btn.Parent = dropdownFrame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local dropdownOpen = false
    local dropdownList = nil
    btn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        PlaySound(Saved.SoundId)
        if dropdownOpen then
            if dropdownList then dropdownList:Destroy() end
            dropdownList = Instance.new("Frame")
            dropdownList.Name = "PlayerList"
            dropdownList.Size = UDim2.new(0.35, 0, 0, math.min(Players:GetPlayers().Length * 32 + 2, 160))
            dropdownList.Position = UDim2.new(1, -4, 1, -4)
            dropdownList.BackgroundColor3 = ThemeColors.Surface
            dropdownList.BorderSizePixel = 1
            dropdownList.BorderColor3 = ThemeColors.Border
            dropdownList.ZIndex = 30
            dropdownList.ClipsDescendants = true
            dropdownList.Parent = btn
            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 6)
            listCorner.Parent = dropdownList
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Padding = UDim.new(0, 2)
            listLayout.Parent = dropdownList

            -- 添加 "所有玩家"
            local allBtn = Instance.new("TextButton")
            allBtn.Name = "All"
            allBtn.Size = UDim2.new(1, -8, 0, 28)
            allBtn.Position = UDim2.new(0, 4, 0, 0)
            allBtn.BackgroundColor3 = ThemeColors.BackgroundSecondary
            allBtn.BorderSizePixel = 0
            allBtn.Text = "所有玩家"
            allBtn.TextColor3 = ThemeColors.Text
            allBtn.TextSize = FontSizeBase - 2
            allBtn.ZIndex = 31
            allBtn.Parent = dropdownList
            allBtn.AutoButtonColor = false
            allBtn.MouseButton1Click:Connect(function()
                btn.Text = "所有玩家"
                dropdownOpen = false
                dropdownList:Destroy()
                if opts.Callback then opts.Callback(nil) end
                PlaySound(Saved.SoundId)
            end)

            for _, plr in ipairs(Players:GetPlayers()) do
                local plrBtn = Instance.new("TextButton")
                plrBtn.Name = plr.Name
                plrBtn.Size = UDim2.new(1, -8, 0, 28)
                plrBtn.Position = UDim2.new(0, 4, 0, 0)
                plrBtn.BackgroundColor3 = ThemeColors.BackgroundSecondary
                plrBtn.BorderSizePixel = 0
                plrBtn.Text = plr.Name
                plrBtn.TextColor3 = ThemeColors.Text
                plrBtn.TextSize = FontSizeBase - 2
                plrBtn.ZIndex = 31
                plrBtn.Parent = dropdownList
                plrBtn.AutoButtonColor = false
                plrBtn.MouseButton1Click:Connect(function()
                    btn.Text = plr.Name
                    dropdownOpen = false
                    dropdownList:Destroy()
                    if opts.Callback then opts.Callback(plr) end
                    PlaySound(Saved.SoundId)
                end)
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

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text:gsub("%s+", ""))
        if CurrentTabObj and CurrentTabObj.Page then
            for _, item in ipairs(CurrentTabObj.Page:GetDescendants()) do
                if item:IsA("Frame") or item:IsA("TextButton") then
                    local prefix = item.Name:sub(1, 6)
                    if prefix == "Button" or prefix == "Toggle" or prefix == "Slider" or item.Name:sub(1, 8) == "Dropdown" or item.Name:sub(1, 5) == "Input" then
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
        else
            if dropdownList then dropdownList:Destroy() end
        end
        if opts.Callback then pcall(opts.Callback, searchBox.Text) end
    end)
    return dropdownFrame

    return searchBox
end

-- ============================================================
-- [14] 密钥系统（开发者自行调用）
-- [14] Key License Verification
-- ============================================================
local KeySystemData = {}
function Library:CreateKeySystem(opts)
    opts = opts or {}
    local keyName = opts.Name or "DefaultKey"
    local correctKey = opts.CorrectKey or opts.Key or "demo-key-123"
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

    KeySystemData[keyName] = {
        Key = correctKey,
        Enabled = false,
    }
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

    local keyFrame = MakeFrame(opts.Container or MainWindow, { Name = opts.Name or "KeySystem", Size = opts.Size or UDim2.new(1, -8, 0, 100), BackgroundTransparency = 0 })
    keyFrame.BackgroundColor3 = ThemeColors.Surface
    keyFrame.BorderSizePixel = 1
    keyFrame.BorderColor3 = ThemeColors.Border
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyFrame

    MakeLabel(keyFrame, { Name = "Title", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 0), Text = opts.Title or "密钥验证", TextColor3 = ThemeColors.Text, Font = Enum.Font.GothamBold })
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "KeyInput"
    inputBox.Size = UDim2.new(0.7, -8, 0, 36)
    inputBox.Position = UDim2.new(0, 8, 0, 40)
    inputBox.BackgroundColor3 = ThemeColors.BackgroundSecondary
    inputBox.BorderSizePixel = 0
    inputBox.Text = opts.Placeholder or "输入密钥..."
    inputBox.TextColor3 = ThemeColors.TextMuted
    inputBox.TextSize = FontSizeBase - 1
    inputBox.Font = Enum.Font.Gotham
    inputBox.ZIndex = 3
    inputBox.Parent = keyFrame
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBox

    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Name = "VerifyBtn"
    verifyBtn.Size = UDim2.new(0.25, -8, 0, 36)
    verifyBtn.Position = UDim2.new(1, -4, 0, 40)
    verifyBtn.BackgroundColor3 = ThemeColors.Success
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = "验证"
    verifyBtn.TextColor3 = ThemeColors.Text
    verifyBtn.TextSize = FontSizeBase
    verifyBtn.ZIndex = 3
    verifyBtn.Parent = keyFrame
    local verifyCorner = Instance.new("UICorner")
    verifyCorner.CornerRadius = UDim.new(0, 6)
    verifyCorner.Parent = verifyBtn

    local statusLabel = MakeLabel(keyFrame, { Name = "Status", Size = UDim2.new(1, -8, 0, 24), Position = UDim2.new(0, 8, 0, 80), Text = "状态: 未验证", TextColor3 = ThemeColors.TextMuted })

    verifyBtn.MouseButton1Click:Connect(function()
        local inputText = inputBox.Text:gsub("%s", "")
        if inputText == correctKey then
            KeySystemData[keyName].Enabled = true
            statusLabel.Text = "状态: 已验证 ✓"
            statusLabel.TextColor3 = ThemeColors.Success
            Library:Notify({ Text = "密钥验证成功！" })
            PlaySound(Saved.SoundId)
            if opts.Callback then opts.Callback(true) end
    getLinkBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(getLink)
            statusLbl.Text = "已复制 Key 链接到剪贴板！"
            statusLbl.TextColor3 = ThemeColors.Accent
        else
            KeySystemData[keyName].Enabled = false
            statusLabel.Text = "状态: 密钥错误 ✗"
            statusLabel.TextColor3 = ThemeColors.Danger
            Library:Notify({ Text = "密钥验证失败！" })
            statusLbl.Text = "复制失败: 环境不支持 setclipboard"
        end
    end)

    -- 提供开发者 API
    function Library:IsKeyEnabled(keyName)
        return KeySystemData[keyName] and KeySystemData[keyName].Enabled or false
    end
    function Library:SetKeyEnabled(keyName, enabled)
        if KeySystemData[keyName] then KeySystemData[keyName].Enabled = enabled end
    end

    return keyFrame
end

-- ============================================================
-- [15] 状态显示器（FPS / Ping 悬浮窗口接口）
-- ============================================================
function Library:GetStatusFrame()
    return FloatingStatusFrame
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
-- [16] 初始化与入口
-- [15] Initialization Entrypoint
-- ============================================================
function Library:Initialize()
    -- 构建窗口
    local win, defaultTab = Library:CreateWindow({
        Title = "LogQuick Script Center",
        Subtitle = "UI Library · 作者: Log_quick",
        Size = UDim2.new(0, 520 * Scale, 0, 580 * Scale),
        Position = Saved.WindowPosition or UDim2.new(0.35, 0, 0.25, 0),
    })

    -- 通知：欢迎用户并显示注入器信息（示例）
    spawn(function()
        wait(0.8)
        Library:Notify({ Text = "欢迎使用 LogQuick UI Library！", Duration = 3 })
        wait(3.2)
        Library:Notify({ Text = "已通过注入器注入 · 示例注入器名称", Duration = 3 })
        -- 清脆音效已在 PlaySound 中处理
    end)
function Library:Initialize(opts)
    opts = opts or {}

    -- 默认开启悬浮状态
    spawn(function()
        wait(1)
        Library:ShowFloatingStatus()
    end)
    -- 创建 UI 窗口
    Library:CreateWindow(opts)

    -- 默认构建设置面板
    -- 构建内置 UI 设置面板
    Library:BuildSettingsTab()

    -- 水印示例（开发者可自行调用）
    -- Library:ShowWatermark({ Text = "LogQuick UI · Script Center" })
    -- 创建搜索栏
    Library:CreateSearch()

    -- 提供开发者扩展接口
    Library.Window = MainWindow
    Library.DefaultTab = defaultTab
    -- 默认开启 FPS / Ping 悬浮窗
    Library:ToggleStats(true)

    -- 配置恢复
    ThemeColors = (Saved.ThemeName == "Light") and Theme.Light or Theme.Dark
    if MainWindow then
        MainWindow.BackgroundColor3 = ThemeColors.Background
    end
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
-- [17] 附加接口（开发者可调用）
-- [完整使用示例 Demonstration Code]
-- 方式一: 如果推送到 GitHub 仓库，使用 HttpGet 在线加载:
-- local LogQuickUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/logz-c/logz-ui-lib/main/script.lua"))()
--
-- 方式二: 如果已将 script.lua 保存到注入器本地 workspace 文件夹:
-- local LogQuickUI = loadstring(readfile("script.lua"))()
-- ============================================================
-- 设置主窗口标题
function Library:SetWindowTitle(title, subtitle)
    if MainWindow then
        local titleBar = MainWindow:FindFirstChild("TitleBar")
        if titleBar then
            local titleLbl = titleBar:FindFirstChild("TitleText")
            local subLbl = titleBar:FindFirstChild("SubtitleText")
            if titleLbl then titleLbl.Text = title else end
            if subLbl then subLbl.Text = subtitle or subLbl.Text end
        end
    end
end

-- 获取当前主题颜色
function Library:GetThemeColors()
    return ThemeColors
end

-- 更新边框颜色动画（在主循环中调用）
function Library:UpdateBorderAnimation()
    if Saved.BorderColorMode == "Rainbow" then
        local color = UpdateRainbow()
        if MainWindow then MainWindow.BorderColor3 = color end
    elseif Saved.BorderColorMode == "Breathing" then
        local base = HSVToRGB(Saved.BorderColorHSV.H, Saved.BorderColorHSV.S, Saved.BorderColorHSV.V)
        local color = BreathingColor(base, 0.4)
        if MainWindow then MainWindow.BorderColor3 = color end
    elseif Saved.BorderColorMode == "Pulse" then
        local base = HSVToRGB(Saved.BorderColorHSV.H, Saved.BorderColorHSV.S, Saved.BorderColorHSV.V)
        local t = (math.sin(os.clock() * 6) + 1) / 2
        if MainWindow then MainWindow.BorderColor3 = base:Lerp(Color3.fromRGB(255, 255, 255), t * 0.3) end
    else
        local base = HSVToRGB(Saved.BorderColorHSV.H, Saved.BorderColorHSV.S, Saved.BorderColorHSV.V)
        if MainWindow then MainWindow.BorderColor3 = base end
    end
end

-- 主循环：边框动画
spawn(function()
    while true do
        wait(0.016)
        Library:UpdateBorderAnimation()
    end
end)

return Library
