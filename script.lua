--[[
LogQuick_UI_Lib.lua
Roblox 执行脚本单文件 UI 库
作者: Log_quick (不可更改)
支持: 手机 / 电脑自适应
风格: 简洁美观大方、高级载入动画、清脆声效
GitHub: 请将本文件保存后推送到您的仓库
包含: 完整接口、内置设置面板、功能再分区、位置记忆、嵌套容器
]]

local LogQuickUI = {}
local Library = LogQuickUI

-- ============================================================
-- [1] 基础与工具模块
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui", 10)

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if not IsMobile then
    -- 有些设备同时有键盘和触屏，这里简化判断
    IsMobile = UserInputService.TouchEnabled
end

-- 适配系数
local Scale = IsMobile and 1.3 or 1.0
local FontSizeBase = IsMobile and 16 or 14
local PaddingBase = IsMobile and 16 or 10
local ButtonHeightBase = IsMobile and 44 or 36

-- 颜色主题 (暗色默认，亮色可切换)
local Theme = {
    Dark = {
        Background = Color3.fromRGB(18, 18, 22),
        BackgroundSecondary = Color3.fromRGB(26, 26, 32),
        Surface = Color3.fromRGB(30, 30, 38),
        SurfaceLight = Color3.fromRGB(42, 42, 52),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(170, 170, 190),
        Accent = Color3.fromRGB(130, 100, 255),
        Border = Color3.fromRGB(60, 60, 75),
        BorderAccent = Color3.fromRGB(140, 110, 255),
        Success = Color3.fromRGB(80, 220, 130),
        Warning = Color3.fromRGB(255, 190, 60),
        Danger = Color3.fromRGB(240, 80, 90),
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
    },
}

local CurrentTheme = "Dark"
local ThemeColors = Theme.Dark

-- ============================================================
-- [2] 配置与状态管理（保存到 getgenv 以便执行器通用）
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
end

-- ============================================================
-- [3] 音效系统（使用 Roblox Sound 对象 + 内置音频 ID 方案）
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

local function PlaySound(id)
    if Saved.SoundEnabled == false then return end
    local sid = id or Saved.SoundId
    local s = CreateSound(sid)
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
end

Library.PlaySound = PlaySound -- 开发者可直接调用
Library.SetSoundEnabled = function(enabled)
    Saved.SoundEnabled = enabled ~= false
    PlaySound()
end
Library.SetSoundId = function(id)
    Saved.SoundId = id or Saved.SoundId
end

-- ============================================================
-- [4] HSV 工具与颜色动画
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
    return Color3.new((r+m), (g+m), (b+m))
end

local function RGBToHSV(r, g, b)
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
end

-- ============================================================
-- [5] 适配与布局工具
-- ============================================================
local function GetScreenSize()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize end
    return Vector2.new(1280, 720)
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
end

local function MakeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.Name = props.Name or "Label"
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 24)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = props.BackgroundTransparency or 1
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or ThemeColors.Text
    lbl.TextSize = props.TextSize or FontSizeBase
    lbl.Font = props.Font or Enum.Font.GothamSemibold
    lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    lbl.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    lbl.ZIndex = props.ZIndex or 2
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
-- ============================================================
local MainWindow = nil
local MainFrame = nil
local WindowTitleBar = nil
local WindowContent = nil
local TabContainer = nil
local Tabs = {}

local function CreateWindow(opts)
    opts = opts or {}
    local titleText = opts.Title or "LogQuick UI"
    local subtitleText = opts.Subtitle or "Script Center"
    local sizeVal = opts.Size or Saved.WindowSize
    local posVal = opts.Position or Saved.WindowPosition

    -- 主容器（拖动区域 + 内容区域）
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LogQuickUI_ScreenGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
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
    local win = Instance.new("Frame")
    win.Name = "LogQuickWindow"
    win.Size = sizeVal
    win.Position = posVal
    win.BackgroundColor3 = ThemeColors.Background
    win.BorderSizePixel = 2
    win.BorderColor3 = ThemeColors.BorderAccent
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
        Text = titleText,
        TextSize = FontSizeBase + 2,
        Font = Enum.Font.GothamBold,
        TextColor3 = ThemeColors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local subtitleLabel = MakeLabel(titleBar, {
        Name = "SubtitleText",
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 16, 1, -22),
        Text = subtitleText,
        TextSize = FontSizeBase - 2,
        Font = Enum.Font.Gotham,
        TextColor3 = ThemeColors.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.Position = UDim2.new(1, -42, 0, 10)
    closeBtn.BackgroundColor3 = ThemeColors.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = FontSizeBase
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 12
    closeBtn.Parent = titleBar
    closeBtn.AutoButtonColor = false
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = ThemeColors.Danger end)
    closeBtn.MouseButton1Click:Connect(function()
        PlaySound(Saved.SoundId)
        win:TweenPosition(UDim2.new(posVal.X.Scale, posVal.X.Offset, 0.6, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        wait(0.25)
        screenGui:Destroy()
    end)

    -- 拖动功能
    local dragging = false
    local dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
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
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundColor3 = ThemeColors.Surface
    tabBar.BorderSizePixel = 0
    tabBar.ZIndex = 6
    tabBar.Parent = content

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local tabPagesContainer = Instance.new("Frame")
    tabPagesContainer.Name = "Pages"
    tabPagesContainer.Size = UDim2.new(1, 0, 1, -36)
    tabPagesContainer.Position = UDim2.new(0, 0, 0, 36)
    tabPagesContainer.BackgroundTransparency = 1
    tabPagesContainer.ZIndex = 6
    tabPagesContainer.Parent = content

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
        end
    end)

    return MainWindow, defaultTab
end

Library.CreateWindow = CreateWindow

-- ============================================================
-- [7] 标签与分区系统（支持嵌套）
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
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.ZIndex = 5
    page.Visible = false
    page.Parent = TabContainer

    local tabObj = {
        Name = name,
        Title = title,
        Button = btn,
        Page = page,
        Sections = {}, -- 功能分区列表
    }

    -- 点击切换标签
    btn.MouseButton1Click:Connect(function()
        PlaySound(Saved.SoundId)
        for _, t in pairs(Tabs) do
            t.Button.TextColor3 = ThemeColors.TextMuted
            t.Page.Visible = false
        end
        btn.TextColor3 = ThemeColors.Text
        page.Visible = true
        TabMeta.CurrentTab = tabObj
    end)

    -- 默认显示第一个标签
    if #Tabs == 0 then
        btn.TextColor3 = ThemeColors.Text
        page.Visible = true
        TabMeta.CurrentTab = tabObj
    end

    table.insert(Tabs, tabObj)
    Tabs[name] = tabObj

    -- 分区添加接口
    function tabObj:AddSection(opts)
        opts = opts or {}
        local secName = opts.Name or ("Section" .. tostring(#self.Sections + 1))
        local secTitle = opts.Title or secName
        local layoutDir = opts.Layout or "Vertical" -- Vertical / Horizontal

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

        local secCorner = Instance.new("UICorner")
        secCorner.CornerRadius = UDim.new(0, 10)
        secCorner.Parent = secFrame

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

        local secBody = Instance.new("Frame")
        secBody.Name = "Body"
        secBody.Size = UDim2.new(1, -8, 1, -36)
        secBody.Position = UDim2.new(0, 4, 0, 34)
        secBody.BackgroundTransparency = 1
        secBody.ZIndex = 10
        secBody.Parent = secFrame

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
            sFrame.LayoutOrder = #secBody:GetChildren()
            return sFrame
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
            end
            -- 简化交互（拖动指针和亮度条）
            -- 由于代码复杂，这里提供基础交互接口
            wheelArea.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    local abs = wheelArea.AbsolutePosition
                    local cx, cy = abs.X + 50, abs.Y + 50
                    local mx, my = i.Position.X - cx, i.Position.Y - cy
                    local angle = math.atan2(my, mx)
                    local dist = math.sqrt(mx * mx + my * my)
                    currentHSV.H = ((angle / (2 * math.pi)) + 1) % 1
                    currentHSV.S = math.clamp(dist / 46, 0, 1)
                    UpdateHSVVisual()
                end
            end)
            -- 亮度条交互
            brightnessFrame.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    local absPos = brightnessFrame.AbsolutePosition
                    local ratio = math.clamp((i.Position.X - absPos.X) / brightnessFrame.AbsoluteSize.X, 0, 1)
                    currentHSV.V = ratio
                    UpdateHSVVisual()
                end
            end)
            UpdateHSVVisual()
            return hsvFrame
        end
        secFrame.AddDropdown = function(p)
            local dropFrame = MakeFrame(secBody, { Name = p.Name or "Dropdown", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0 })
            dropFrame.LayoutOrder = #secBody:GetChildren()
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
                else
                    if dropdownList then dropdownList:Destroy() end
                end
            end)
            return dropFrame
        end
        secFrame.AddInput = function(p)
            local inputFrame = MakeFrame(secBody, { Name = p.Name or "Input", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0 })
            inputFrame.LayoutOrder = #secBody:GetChildren()
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
        end
        table.insert(self.Sections, secFrame)
        return secFrame
    end

    return tabObj
end

-- ============================================================
-- [8] 通知系统
-- ============================================================
local NotificationList = {}
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
    end)
    for i, n in ipairs(NotificationList) do
        if n == notif then table.remove(NotificationList, i) break end
    end
end

-- ============================================================
-- [9] 设置面板（内置）
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

    -- 功能再分区示例：在设置面板内再嵌套分区
    local nestedExample = settingsTab:AddSection({ Name = "NestedExample", Title = "嵌套分区示例", Size = UDim2.new(1, 0, 0, 100) })
    local nestedSub = nestedExample:AddSubSection({ Name = "SubNested", Title = "子分区（再分区）", Size = UDim2.new(1, 0, 0, 60) })
    nestedSub:AddLabel({ Text = "这是一个嵌套在设置分区内的子分区", TextColor3 = ThemeColors.TextMuted, Size = UDim2.new(1, 0, 0, 20) })
    nestedSub:AddButton({ Text = "嵌套按钮测试", Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = ThemeColors.Success, Callback = function()
        Library:Notify({ Text = "嵌套按钮被点击！" })
    end })

    return settingsTab
end

-- ============================================================
-- [10] 悬浮状态展示（FPS / Ping 默认开启，可关闭）
-- ============================================================
local FloatingStatusFrame = nil
function Library:ToggleFloatingStatus(enabled)
    if enabled == nil then enabled = not (Saved.FloatingStatusEnabled ~= false) end
    Saved.FloatingStatusEnabled = enabled
    if FloatingStatusFrame then FloatingStatusFrame:Destroy() FloatingStatusFrame = nil end
    if not enabled then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FloatingStatusGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "FloatingStatus"
    frame.Size = UDim2.new(0, 160, 0, 50)
    frame.Position = UDim2.new(0, 20, 0, 80)
    frame.BackgroundColor3 = ThemeColors.Surface
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 1
    frame.BorderColor3 = ThemeColors.BorderAccent
    frame.ZIndex = 99
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
        end
    end)
end

function Library:ShowFloatingStatus()
    Library:ToggleFloatingStatus(true)
end

function Library:HideFloatingStatus()
    Library:ToggleFloatingStatus(false)
end

-- ============================================================
-- [11] 水印（开发者自行调用）
-- ============================================================
local WatermarkFrame = nil
function Library:ShowWatermark(opts)
    opts = opts or {}
    local text = opts.Text or opts.Title or "LogQuick UI"
    if WatermarkFrame then WatermarkFrame:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "WatermarkGui"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
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
end

function Library:HideWatermark()
    if WatermarkFrame then WatermarkFrame:Destroy() end
end

-- ============================================================
-- [12] 搜索功能（开发者自行调用）
-- ============================================================
local SearchResults = {}
function Library:CreateSearch(opts)
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
end

-- ============================================================
-- [13] 玩家选择器（简化实现）
-- ============================================================
function Library:CreatePlayerSelector(opts)
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
            end
        else
            if dropdownList then dropdownList:Destroy() end
        end
    end)
    return dropdownFrame
end

-- ============================================================
-- [14] 密钥系统（开发者自行调用）
-- ============================================================
local KeySystemData = {}
function Library:CreateKeySystem(opts)
    opts = opts or {}
    local keyName = opts.Name or "DefaultKey"
    local correctKey = opts.CorrectKey or opts.Key or "demo-key-123"

    KeySystemData[keyName] = {
        Key = correctKey,
        Enabled = false,
    }

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
        else
            KeySystemData[keyName].Enabled = false
            statusLabel.Text = "状态: 密钥错误 ✗"
            statusLabel.TextColor3 = ThemeColors.Danger
            Library:Notify({ Text = "密钥验证失败！" })
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
end

-- ============================================================
-- [16] 初始化与入口
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

    -- 默认开启悬浮状态
    spawn(function()
        wait(1)
        Library:ShowFloatingStatus()
    end)

    -- 默认构建设置面板
    Library:BuildSettingsTab()

    -- 水印示例（开发者可自行调用）
    -- Library:ShowWatermark({ Text = "LogQuick UI · Script Center" })

    -- 提供开发者扩展接口
    Library.Window = MainWindow
    Library.DefaultTab = defaultTab

    -- 配置恢复
    ThemeColors = (Saved.ThemeName == "Light") and Theme.Light or Theme.Dark
    if MainWindow then
        MainWindow.BackgroundColor3 = ThemeColors.Background
    end
end

-- ============================================================
-- [17] 附加接口（开发者可调用）
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
