--[[
    Vape-Style UI Library v2 for Roblox
    完美兼容 PC & 手机端
    挂载到 CoreGui
    
    核心改进:
    - 主菜单控制窗口开关
    - 智能窗口排列不超屏
    - 通知/欢迎消息系统
    - 丰富动画 & 音效
    - 窗口状态持久化
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- LIBRARY
-- ============================================================
local Library = {}
Library.__index = Library
Library.Flags = {}
Library.Categories = {}
Library.Connections = {}
Library.Coroutines = {}
Library.Initialized = false
Library.Visible = true
Library.ToggleKey = Enum.KeyCode.RightShift
Library.AccentColor = Color3.fromRGB(67, 160, 255)
Library.ColorMode = "Static"
Library.DynamicSpeed = 1
Library.BackgroundTransparency = 0.08
Library.CurrentAccent = Color3.fromRGB(67, 160, 255)
Library.AccentObjects = {}
Library.AccentGradients = {}
Library.StartTime = os.clock()
Library.AutoSave = false
Library.SaveFile = "VapeUIConfig.json"
Library.SoundEnabled = true
Library.WatermarkEnabled = false
Library.ArrayListEnabled = false
Library.KeybindActiveWhenHidden = true
Library.MobileBallVisible = true
Library.EnabledModules = {}
Library.OpenWindows = {}
Library.WindowStates = {}
Library.NotificationQueue = {}

-- ============================================================
-- PLATFORM
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local SCREEN_SIZE = workspace.CurrentCamera.ViewportSize
local SCALE = IS_MOBILE and 1.2 or 1
local MIN_TOUCH = 38
local WINDOW_WIDTH = math.clamp(195 * SCALE, 170, 260)
local WINDOW_GAP = 8
local TOP_OFFSET = IS_MOBILE and 55 or 45

-- Update screen size on change
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    SCREEN_SIZE = workspace.CurrentCamera.ViewportSize
end)

-- ============================================================
-- SOUNDS
-- ============================================================
local Sounds = {
    Click = "rbxassetid://6895079853",
    Toggle_On = "rbxassetid://6895079853",
    Toggle_Off = "rbxassetid://6895079853",
    Notification = "rbxassetid://4590662766",
    Open = "rbxassetid://6895079853",
    Close = "rbxassetid://6895079853",
    Slider = "rbxassetid://6895079853",
    Expand = "rbxassetid://6895079853",
    Welcome = "rbxassetid://4590662766",
    Error = "rbxassetid://4590657391",
    Success = "rbxassetid://4590662766",
}

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    Background = Color3.fromRGB(18, 18, 28),
    CategoryHeader = Color3.fromRGB(25, 25, 40),
    ModuleBackground = Color3.fromRGB(22, 22, 35),
    ModuleHover = Color3.fromRGB(32, 32, 50),
    ModuleEnabled = Color3.fromRGB(28, 28, 44),
    ElementBackground = Color3.fromRGB(28, 28, 42),
    ElementBorder = Color3.fromRGB(45, 45, 65),
    TextPrimary = Color3.fromRGB(235, 235, 245),
    TextSecondary = Color3.fromRGB(155, 155, 175),
    TextDim = Color3.fromRGB(95, 95, 115),
    SliderBackground = Color3.fromRGB(38, 38, 55),
    ToggleOff = Color3.fromRGB(50, 50, 68),
    Separator = Color3.fromRGB(40, 40, 58),
    Shadow = Color3.fromRGB(0, 0, 0),
    Notification = Color3.fromRGB(22, 22, 35),
    NotifSuccess = Color3.fromRGB(40, 200, 120),
    NotifError = Color3.fromRGB(255, 70, 70),
    NotifInfo = Color3.fromRGB(67, 160, 255),
    NotifWarn = Color3.fromRGB(255, 180, 40),
    MenuButton = Color3.fromRGB(28, 28, 44),
    MenuButtonHover = Color3.fromRGB(38, 38, 58),
}

-- ============================================================
-- UTILITY
-- ============================================================
local Utility = {}

function Utility.Create(className, properties, children)
    local inst = Instance.new(className)
    if properties then
        for prop, val in pairs(properties) do
            if prop ~= "Parent" then
                pcall(function() inst[prop] = val end)
            end
        end
        if properties.Parent then
            inst.Parent = properties.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

function Utility.Tween(instance, duration, properties, easingStyle, easingDir, callback)
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDir = easingDir or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, easingStyle, easingDir), properties)
    tween:Play()
    if callback then
        tween.Completed:Connect(callback)
    end
    return tween
end

function Utility.Spring(instance, duration, properties)
    return Utility.Tween(instance, duration, properties, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function Utility.Bounce(instance, duration, properties)
    return Utility.Tween(instance, duration, properties, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
end

function Utility.Elastic(instance, duration, properties)
    return Utility.Tween(instance, duration, properties, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
end

function Utility.SmoothIn(instance, duration, properties)
    return Utility.Tween(instance, duration, properties, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
end

function Utility.PlaySound(soundId, volume, pitch)
    if not Library.SoundEnabled then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.4
        sound.PlaybackSpeed = pitch or 1
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
end

function Utility.ClickSound()
    Utility.PlaySound(Sounds.Click, 0.3, 1.1 + math.random() * 0.2)
end

function Utility.ToggleOnSound()
    Utility.PlaySound(Sounds.Toggle_On, 0.35, 1.15)
end

function Utility.ToggleOffSound()
    Utility.PlaySound(Sounds.Toggle_Off, 0.25, 0.85)
end

function Utility.SliderSound()
    Utility.PlaySound(Sounds.Slider, 0.15, 1.3 + math.random() * 0.3)
end

function Utility.ExpandSound()
    Utility.PlaySound(Sounds.Expand, 0.25, 1.0)
end

function Utility.NotifSound(type_)
    if type_ == "error" then
        Utility.PlaySound(Sounds.Error, 0.4, 0.9)
    elseif type_ == "success" then
        Utility.PlaySound(Sounds.Success, 0.4, 1.1)
    else
        Utility.PlaySound(Sounds.Notification, 0.35, 1.0)
    end
end

function Utility.Ripple(parent, x, y)
    local absPos = parent.AbsolutePosition
    local absSize = parent.AbsoluteSize
    local maxDist = math.max(
        (Vector2.new(x, y) - absPos).Magnitude,
        (Vector2.new(x, y) - (absPos + absSize)).Magnitude,
        (Vector2.new(x, y) - (absPos + Vector2.new(absSize.X, 0))).Magnitude,
        (Vector2.new(x, y) - (absPos + Vector2.new(0, absSize.Y))).Magnitude
    ) * 1.2
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, x - absPos.X, 0, y - absPos.Y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = parent.ZIndex + 10,
        Parent = parent,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ripple })
    local targetSize = UDim2.new(0, maxDist * 2, 0, maxDist * 2)
    Utility.Tween(ripple, 0.45, { Size = targetSize, BackgroundTransparency = 1 })
    task.delay(0.5, function()
        pcall(function() ripple:Destroy() end)
    end)
end

function Utility.Lerp(a, b, t) return a + (b - a) * t end

function Utility.LerpColor(c1, c2, t)
    return Color3.new(Utility.Lerp(c1.R, c2.R, t), Utility.Lerp(c1.G, c2.G, t), Utility.Lerp(c1.B, c2.B, t))
end

function Utility.Darken(color, factor)
    factor = factor or 0.35
    return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

function Utility.RoundNum(num, dec)
    local mult = 10 ^ (dec or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utility.FormatTime(sec)
    return string.format("%02d:%02d:%02d", math.floor(sec/3600), math.floor((sec%3600)/60), math.floor(sec%60))
end

-- ============================================================
-- ACCENT COLOR ENGINE
-- ============================================================
local AccentEngine = { Running = true }

function AccentEngine:Start()
    local co = task.spawn(function()
        while AccentEngine.Running do
            local t = os.clock()
            local spd = Library.DynamicSpeed

            if Library.ColorMode == "Static" then
                Library.CurrentAccent = Library.AccentColor
            elseif Library.ColorMode == "Breathing" then
                local breath = (math.sin(t * spd * 2) + 1) / 2
                Library.CurrentAccent = Utility.LerpColor(Utility.Darken(Library.AccentColor, 0.3), Library.AccentColor, breath)
            elseif Library.ColorMode == "Rainbow" then
                Library.CurrentAccent = Color3.fromHSV((t * spd * 0.08) % 1, 0.75, 1)
            elseif Library.ColorMode == "Gradient" then
                Library.CurrentAccent = Color3.fromHSV((t * spd * 0.06) % 1, 0.7, 1)
            end

            for _, obj in pairs(Library.AccentObjects) do
                if obj and obj.Instance and obj.Instance.Parent then
                    pcall(function()
                        if obj.Property then
                            obj.Instance[obj.Property] = Library.CurrentAccent
                        end
                    end)
                end
            end

            if Library.ColorMode == "Gradient" then
                for _, gObj in pairs(Library.AccentGradients) do
                    if gObj and gObj.Gradient and gObj.Gradient.Parent then
                        pcall(function()
                            local h1 = (t * spd * 0.06) % 1
                            local h2 = (h1 + 0.35) % 1
                            gObj.Gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, 0.75, 1)),
                                ColorSequenceKeypoint.new(1, Color3.fromHSV(h2, 0.75, 1)),
                            })
                            gObj.Gradient.Rotation = (t * spd * 40) % 360
                        end)
                    end
                end
            else
                for _, gObj in pairs(Library.AccentGradients) do
                    if gObj and gObj.Gradient and gObj.Gradient.Parent then
                        pcall(function()
                            gObj.Gradient.Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent)
                            gObj.Gradient.Rotation = 0
                        end)
                    end
                end
            end

            task.wait(1/60)
        end
    end)
    table.insert(Library.Coroutines, co)
end

function AccentEngine:Stop()
    AccentEngine.Running = false
end

function AccentEngine:Register(instance, property)
    local id = #Library.AccentObjects + 1
    Library.AccentObjects[id] = { Instance = instance, Property = property }
    return id
end

function AccentEngine:RegisterGradient(gradientInstance)
    local id = #Library.AccentGradients + 1
    Library.AccentGradients[id] = { Gradient = gradientInstance }
    return id
end

-- ============================================================
-- DRAG SYSTEM (Cross-platform, long-press for mobile)
-- ============================================================
local DragSystem = {}

function DragSystem:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos
    local longPressActive = false
    local LONG_PRESS_TIME = 0.2

    local function beginDrag(pos)
        dragging = true
        dragStart = pos
        startPos = frame.Position
    end

    local function updateDrag(pos)
        if not dragging then return end
        local delta = pos - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, SCREEN_SIZE.X - frame.AbsoluteSize.X)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, SCREEN_SIZE.Y - frame.AbsoluteSize.Y)
        Utility.Tween(frame, 0.06, {
            Position = UDim2.new(0, newX, 0, newY)
        }, Enum.EasingStyle.Linear)
    end

    local function endDrag()
        dragging = false
        longPressActive = false
    end

    -- Mouse
    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag(input.Position)
        end
    end)
    local c2 = handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then endDrag() end
    end)
    local c3 = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and not longPressActive then
            updateDrag(input.Position)
        end
    end)

    -- Touch
    local touchStart, touchTime
    local c4 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = input.Position
            touchTime = os.clock()
            task.spawn(function()
                task.wait(LONG_PRESS_TIME)
                if touchStart and os.clock() - touchTime >= LONG_PRESS_TIME then
                    longPressActive = true
                    beginDrag(touchStart)
                end
            end)
        end
    end)
    local c5 = UserInputService.TouchMoved:Connect(function(input)
        if dragging and longPressActive then
            updateDrag(input.Position)
        end
    end)
    local c6 = UserInputService.TouchEnded:Connect(function()
        endDrag()
        touchStart = nil
    end)

    for _, c in ipairs({c1,c2,c3,c4,c5,c6}) do
        table.insert(Library.Connections, c)
    end
end

-- ============================================================
-- CONFIG MANAGER
-- ============================================================
local ConfigManager = {}

function ConfigManager:Save()
    pcall(function()
        local data = { Flags = {}, WindowStates = Library.WindowStates }
        for k, v in pairs(Library.Flags) do
            if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                data.Flags[k] = v
            elseif typeof(v) == "Color3" then
                data.Flags[k] = { T = "C3", R = v.R, G = v.G, B = v.B }
            elseif typeof(v) == "EnumItem" then
                data.Flags[k] = { T = "EI", ET = tostring(v.EnumType), N = v.Name }
            end
        end
        writefile(Library.SaveFile, HttpService:JSONEncode(data))
    end)
end

function ConfigManager:Load()
    pcall(function()
        if isfile and isfile(Library.SaveFile) then
            local data = HttpService:JSONDecode(readfile(Library.SaveFile))
            if data.Flags then
                for k, v in pairs(data.Flags) do
                    if type(v) == "table" then
                        if v.T == "C3" then
                            Library.Flags[k] = Color3.new(v.R, v.G, v.B)
                        elseif v.T == "EI" then
                            pcall(function() Library.Flags[k] = Enum[v.ET][v.N] end)
                        end
                    else
                        Library.Flags[k] = v
                    end
                end
            end
            if data.WindowStates then
                Library.WindowStates = data.WindowStates
            end
        end
    end)
end

function ConfigManager:AutoCheck()
    if Library.AutoSave then ConfigManager:Save() end
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
function Library:Notify(info)
    info = info or {}
    local title = info.Title or "Notification"
    local content = info.Content or ""
    local duration = info.Duration or 3.5
    local type_ = info.Type or "info" -- info, success, error, warn

    local typeColors = {
        info = Theme.NotifInfo,
        success = Theme.NotifSuccess,
        error = Theme.NotifError,
        warn = Theme.NotifWarn,
    }
    local typeIcons = {
        info = "ℹ",
        success = "✓",
        error = "✕",
        warn = "⚠",
    }

    Utility.NotifSound(type_)

    local notifColor = typeColors[type_] or Theme.NotifInfo
    local notifIcon = typeIcons[type_] or "ℹ"

    -- Calculate position based on existing notifications
    local existingCount = #Library.NotificationQueue
    local yOffset = 10 + existingCount * (65 * SCALE + 8)

    local notifWidth = math.clamp(280 * SCALE, 240, 380)
    local notifHeight = 58 * SCALE

    local notif = Utility.Create("Frame", {
        Name = "Notification",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, notifWidth + 20, 0, yOffset),
        Size = UDim2.new(0, notifWidth, 0, notifHeight),
        BackgroundColor3 = Theme.Notification,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 500,
        ClipsDescendants = true,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    Utility.Create("UIStroke", {
        Color = notifColor,
        Thickness = 1,
        Transparency = 0.4,
        Parent = notif,
    })

    -- Shadow
    Utility.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 30, 1, 30),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 499,
        Parent = notif,
    })

    -- Accent bar top
    local topBar = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2.5),
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        ZIndex = 502,
        Parent = notif,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = topBar })

    -- Progress bar (bottom)
    local progressBg = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 501,
        Parent = notif,
    })
    local progressFill = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        ZIndex = 502,
        Parent = progressBg,
    })

    -- Icon
    Utility.Create("TextLabel", {
        Size = UDim2.new(0, 30 * SCALE, 0, 30 * SCALE),
        Position = UDim2.new(0, 10, 0.5, -15 * SCALE),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18 * SCALE,
        TextColor3 = notifColor,
        Text = notifIcon,
        ZIndex = 502,
        Parent = notif,
    })

    -- Title
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -50 * SCALE, 0, 18 * SCALE),
        Position = UDim2.new(0, 42 * SCALE, 0, 7),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 502,
        Parent = notif,
    })

    -- Content
    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -50 * SCALE, 0, 20 * SCALE),
        Position = UDim2.new(0, 42 * SCALE, 0, 26 * SCALE),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10.5 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = content,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = true,
        ZIndex = 502,
        Parent = notif,
    })

    table.insert(Library.NotificationQueue, notif)

    -- Slide in animation
    Utility.Spring(notif, 0.5, {
        Position = UDim2.new(1, -10, 0, yOffset)
    })

    -- Progress bar countdown
    Utility.Tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

    -- Auto dismiss
    task.delay(duration, function()
        -- Slide out
        Utility.Tween(notif, 0.35, {
            Position = UDim2.new(1, notifWidth + 20, 0, notif.Position.Y.Offset)
        }, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            -- Remove from queue and reposition remaining
            for i, n in ipairs(Library.NotificationQueue) do
                if n == notif then
                    table.remove(Library.NotificationQueue, i)
                    break
                end
            end
            pcall(function() notif:Destroy() end)

            -- Reposition remaining notifications
            for i, n in ipairs(Library.NotificationQueue) do
                if n and n.Parent then
                    local targetY = 10 + (i - 1) * (65 * SCALE + 8)
                    Utility.Spring(n, 0.35, {
                        Position = UDim2.new(1, -10, 0, targetY)
                    })
                end
            end
        end)
    end)

    return notif
end

-- ============================================================
-- SMART WINDOW POSITIONING
-- ============================================================
function Library:CalculateWindowPosition(index)
    local padding = WINDOW_GAP
    local startX = padding
    local startY = TOP_OFFSET + padding
    local maxCols = math.floor((SCREEN_SIZE.X - padding) / (WINDOW_WIDTH + padding))
    maxCols = math.max(maxCols, 1)

    local col = ((index - 1) % maxCols)
    local row = math.floor((index - 1) / maxCols)

    local x = startX + col * (WINDOW_WIDTH + padding)
    local y = startY + row * (350 * SCALE + padding)

    -- Ensure within screen
    x = math.clamp(x, padding, SCREEN_SIZE.X - WINDOW_WIDTH - padding)
    y = math.clamp(y, startY, SCREEN_SIZE.Y - 100)

    return UDim2.new(0, x, 0, y)
end

function Library:RepositionWindows()
    local visIndex = 0
    for _, cat in ipairs(Library.Categories) do
        if cat.Frame and cat.Frame.Visible then
            visIndex = visIndex + 1
            local pos = Library:CalculateWindowPosition(visIndex)
            Utility.Spring(cat.Frame, 0.4, { Position = pos })
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
function Library:Init(settings)
    settings = settings or {}
    Library.SaveFile = settings.SaveFile or "VapeUIConfig.json"
    Library.ToggleKey = settings.ToggleKey or Enum.KeyCode.RightShift
    Library.AccentColor = settings.AccentColor or Color3.fromRGB(67, 160, 255)
    Library.CurrentAccent = Library.AccentColor
    Library.Title = settings.Title or "Vape Client"

    ConfigManager:Load()

    pcall(function()
        if CoreGui:FindFirstChild("VapeUILibrary") then
            CoreGui:FindFirstChild("VapeUILibrary"):Destroy()
        end
    end)

    Library.ScreenGui = Utility.Create("ScreenGui", {
        Name = "VapeUILibrary",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = CoreGui,
    })

    Library.MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = Library.ScreenGui,
    })

    -- ====================
    -- MAIN MENU BAR (Top)
    -- ====================
    local menuBarHeight = 32 * SCALE
    Library.MenuBar = Utility.Create("Frame", {
        Name = "MenuBar",
        Position = UDim2.new(0, 0, 0, -menuBarHeight),
        Size = UDim2.new(1, 0, 0, menuBarHeight),
        BackgroundColor3 = Theme.CategoryHeader,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = 80,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UIStroke", {
        Color = Theme.ElementBorder,
        Thickness = 1,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Library.MenuBar,
    })

    -- Menu accent bar
    local menuAccent = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 82,
        Parent = Library.MenuBar,
    })
    local menuAccentGrad = Utility.Create("UIGradient", {
        Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent),
        Parent = menuAccent,
    })
    AccentEngine:Register(menuAccent, "BackgroundColor3")
    AccentEngine:RegisterGradient(menuAccentGrad)

    -- Title in menu bar
    Library.MenuTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 120 * SCALE, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13 * SCALE,
        TextColor3 = Library.CurrentAccent,
        Text = Library.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 82,
        Parent = Library.MenuBar,
    })
    AccentEngine:Register(Library.MenuTitle, "TextColor3")

    -- Menu button container
    Library.MenuButtonContainer = Utility.Create("Frame", {
        Name = "Buttons",
        Size = UDim2.new(1, -130 * SCALE, 1, -4),
        Position = UDim2.new(0, 125 * SCALE, 0, 2),
        BackgroundTransparency = 1,
        ZIndex = 81,
        ClipsDescendants = true,
        Parent = Library.MenuBar,
    })

    -- If mobile, use ScrollingFrame for buttons
    if IS_MOBILE then
        local scroll = Utility.Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            ScrollingDirection = Enum.ScrollingDirection.X,
            Parent = Library.MenuButtonContainer,
        })
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = scroll,
        })
        Library._MenuBtnParent = scroll
    else
        Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 3),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = Library.MenuButtonContainer,
        })
        Library._MenuBtnParent = Library.MenuButtonContainer
    end

    -- Animate menu bar in
    Utility.Spring(Library.MenuBar, 0.6, { Position = UDim2.new(0, 0, 0, 0) })

    -- ====================
    -- WATERMARK
    -- ====================
    Library.Watermark = Utility.Create("Frame", {
        Name = "Watermark",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, menuBarHeight + 5),
        Size = UDim2.new(0, 210 * SCALE, 0, 24 * SCALE),
        BackgroundColor3 = Theme.Notification,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 90,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Library.Watermark })
    Utility.Create("UIStroke", { Color = Library.CurrentAccent, Thickness = 1, Transparency = 0.5, Parent = Library.Watermark })

    Library.WatermarkLabel = Utility.Create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 10.5 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 91,
        Parent = Library.Watermark,
    })

    local wmCo = task.spawn(function()
        while AccentEngine.Running do
            if Library.WatermarkEnabled and Library.Watermark.Visible then
                pcall(function()
                    local fps = math.floor(1 / RunService.RenderStepped:Wait())
                    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                    local rt = Utility.FormatTime(os.clock() - Library.StartTime)
                    Library.WatermarkLabel.Text = string.format("%s | %dFPS | %dms | %s", Library.Title, fps, ping, rt)
                end)
            else
                task.wait(0.5)
            end
        end
    end)
    table.insert(Library.Coroutines, wmCo)

    -- ====================
    -- ARRAYLIST
    -- ====================
    Library.ArrayList = Utility.Create("Frame", {
        Name = "ArrayList",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -5, 0, menuBarHeight + 32 * SCALE),
        Size = UDim2.new(0, 160 * SCALE, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 90,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.Name,
        Padding = UDim.new(0, 2),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = Library.ArrayList,
    })

    -- ====================
    -- FLOATING BALL (Mobile)
    -- ====================
    Library.FloatingBall = Utility.Create("Frame", {
        Name = "FloatingBall",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 30, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Library.CurrentAccent,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Visible = IS_MOBILE and Library.MobileBallVisible,
        ZIndex = 300,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Library.FloatingBall })
    Utility.Create("UIStroke", {
        Color = Color3.new(1, 1, 1),
        Thickness = 1.5,
        Transparency = 0.4,
        Parent = Library.FloatingBall,
    })
    AccentEngine:Register(Library.FloatingBall, "BackgroundColor3")

    local ballLabel = Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "V",
        ZIndex = 301,
        Parent = Library.FloatingBall,
    })

    -- Animate ball in
    if IS_MOBILE then
        Utility.Elastic(Library.FloatingBall, 0.7, {
            Size = UDim2.new(0, 44, 0, 44)
        })
    end

    DragSystem:MakeDraggable(Library.FloatingBall, Library.FloatingBall)

    -- Ball tap detection
    local ballTouchPos = nil
    Library.FloatingBall.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            ballTouchPos = input.Position
        end
    end)
    Library.FloatingBall.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if ballTouchPos and (input.Position - ballTouchPos).Magnitude < 12 then
                Library:ToggleUI()
                Utility.ClickSound()
                -- Ball pulse animation
                Utility.Spring(Library.FloatingBall, 0.15, { Size = UDim2.new(0, 50, 0, 50) })
                task.delay(0.15, function()
                    Utility.Spring(Library.FloatingBall, 0.3, { Size = UDim2.new(0, 44, 0, 44) })
                end)
            end
            ballTouchPos = nil
        end
    end)

    -- ====================
    -- KEYBOARD TOGGLE
    -- ====================
    local tkConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Library.ToggleKey then
            Library:ToggleUI()
        end
    end)
    table.insert(Library.Connections, tkConn)

    -- Start engine
    AccentEngine:Start()
    Library.Initialized = true

    -- Build settings
    Library:_BuildSettingsCategory()

    -- Welcome notification
    task.delay(0.8, function()
        Library:Notify({
            Title = "Welcome!",
            Content = Library.Title .. " loaded successfully.",
            Duration = 4,
            Type = "success",
        })
        task.wait(0.5)
        Library:Notify({
            Title = "Controls",
            Content = IS_MOBILE and "Tap floating ball to toggle UI." or "Press RightShift to toggle UI.",
            Duration = 5,
            Type = "info",
        })
    end)

    return Library
end

-- ============================================================
-- TOGGLE UI
-- ============================================================
function Library:ToggleUI()
    Library.Visible = not Library.Visible

    if Library.Visible then
        Utility.PlaySound(Sounds.Open, 0.3, 1.05)
        -- Show menu bar
        Utility.Spring(Library.MenuBar, 0.45, { Position = UDim2.new(0, 0, 0, 0) })
        Library.MenuBar.Visible = true
        -- Show open windows
        for _, cat in ipairs(Library.Categories) do
            if cat._shouldBeVisible then
                cat.Frame.Visible = true
                cat.Frame.BackgroundTransparency = 1
                Utility.Spring(cat.Frame, 0.35, { BackgroundTransparency = Library.BackgroundTransparency })
                -- Fade children
                for _, desc in pairs(cat.Frame:GetDescendants()) do
                    pcall(function()
                        if desc:IsA("GuiObject") and desc.Name ~= "Ripple" and desc.Name ~= "Shadow" then
                            local stored = desc:GetAttribute("_origBT")
                            if stored then
                                Utility.Tween(desc, 0.3, { BackgroundTransparency = stored })
                            end
                            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                local storedTT = desc:GetAttribute("_origTT")
                                if storedTT then
                                    Utility.Tween(desc, 0.3, { TextTransparency = storedTT })
                                end
                            end
                        end
                    end)
                end
            end
        end
    else
        Utility.PlaySound(Sounds.Close, 0.25, 0.9)
        -- Hide menu bar
        local mbh = Library.MenuBar.AbsoluteSize.Y
        Utility.Tween(Library.MenuBar, 0.3, { Position = UDim2.new(0, 0, 0, -mbh) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        -- Hide windows
        for _, cat in ipairs(Library.Categories) do
            if cat.Frame.Visible then
                cat._shouldBeVisible = true
                -- Store original transparencies
                for _, desc in pairs(cat.Frame:GetDescendants()) do
                    pcall(function()
                        if desc:IsA("GuiObject") and desc.Name ~= "Ripple" and desc.Name ~= "Shadow" then
                            desc:SetAttribute("_origBT", desc.BackgroundTransparency)
                            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                desc:SetAttribute("_origTT", desc.TextTransparency)
                                Utility.Tween(desc, 0.2, { TextTransparency = 1 })
                            end
                            Utility.Tween(desc, 0.2, { BackgroundTransparency = 1 })
                        end
                    end)
                end
                Utility.Tween(cat.Frame, 0.25, { BackgroundTransparency = 1 }, nil, nil, function()
                    if not Library.Visible then cat.Frame.Visible = false end
                end)
            else
                cat._shouldBeVisible = false
            end
        end
    end

    if Library.Watermark then
        Library.Watermark.Visible = Library.Visible and Library.WatermarkEnabled
    end
    if Library.ArrayList then
        Library.ArrayList.Visible = Library.Visible and Library.ArrayListEnabled
    end
end

-- ============================================================
-- CATEGORY
-- ============================================================
local Category = {}
Category.__index = Category

function Library:CreateCategory(info)
    info = info or {}
    local name = info.Name or "Category"
    local icon = info.Icon or ""
    local startVisible = false -- All categories start HIDDEN
    if info.AutoShow then startVisible = true end

    -- Check saved window state
    if Library.WindowStates[name] ~= nil then
        startVisible = Library.WindowStates[name]
    end

    local catWidth = WINDOW_WIDTH
    local headerH = 30 * SCALE

    local cat = setmetatable({}, Category)
    cat.Name = name
    cat.Modules = {}
    cat.Collapsed = false
    cat._shouldBeVisible = startVisible

    -- Count visible windows for positioning
    local visCount = 0
    for _, c in ipairs(Library.Categories) do
        if c.Frame and c.Frame.Visible then visCount = visCount + 1 end
    end

    local pos = info.Position or Library:CalculateWindowPosition(visCount + 1)

    -- Category Frame
    cat.Frame = Utility.Create("Frame", {
        Name = "Cat_" .. name,
        Position = pos,
        Size = UDim2.new(0, catWidth, 0, headerH),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = startVisible and Library.BackgroundTransparency or 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = startVisible,
        ZIndex = 10,
        Parent = Library.MainFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = cat.Frame })
    Utility.Create("UIStroke", {
        Color = Theme.ElementBorder,
        Thickness = 1,
        Transparency = 0.55,
        Parent = cat.Frame,
    })

    -- Shadow
    Utility.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 3),
        Size = UDim2.new(1, 20, 1, 20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 9,
        Parent = cat.Frame,
    })

    -- Accent top bar
    local accentBar = Utility.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2.5),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = cat.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = accentBar })
    local abGrad = Utility.Create("UIGradient", { Parent = accentBar })
    AccentEngine:Register(accentBar, "BackgroundColor3")
    AccentEngine:RegisterGradient(abGrad)

    -- Header
    local header = Utility.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, headerH),
        BackgroundColor3 = Theme.CategoryHeader,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = cat.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = header })

    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -35 * SCALE, 1, 0),
        Position = UDim2.new(0, 10 * SCALE, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12.5 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = header,
    })

    local collapseBtn = Utility.Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6 * SCALE, 0.5, 0),
        Size = UDim2.new(0, 20 * SCALE, 0, 20 * SCALE),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = "▼",
        ZIndex = 14,
        Parent = header,
    })

    -- Module container
    cat.ModuleContainer = Utility.Create("ScrollingFrame", {
        Name = "Modules",
        Position = UDim2.new(0, 0, 0, headerH),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.CurrentAccent,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        ZIndex = 11,
        Parent = cat.Frame,
    })
    AccentEngine:Register(cat.ModuleContainer, "ScrollBarImageColor3")

    local modLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
        Parent = cat.ModuleContainer,
    })
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        Parent = cat.ModuleContainer,
    })

    local maxH = math.clamp(SCREEN_SIZE.Y - TOP_OFFSET - 80, 150, 380 * SCALE)

    cat._UpdateSize = function()
        if cat.Collapsed then
            Utility.Tween(cat.ModuleContainer, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
            Utility.Tween(cat.Frame, 0.25, { Size = UDim2.new(0, catWidth, 0, headerH) })
        else
            local contentH = modLayout.AbsoluteContentSize.Y + 8
            local displayH = math.min(contentH, maxH)
            Utility.Tween(cat.ModuleContainer, 0.25, { Size = UDim2.new(1, 0, 0, displayH) })
            Utility.Tween(cat.Frame, 0.25, { Size = UDim2.new(0, catWidth, 0, headerH + displayH) })
        end
    end

    modLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cat._UpdateSize()
    end)
    task.defer(cat._UpdateSize)

    -- Collapse
    collapseBtn.MouseButton1Click:Connect(function()
        cat.Collapsed = not cat.Collapsed
        Utility.ClickSound()
        Utility.Spring(collapseBtn, 0.3, { Rotation = cat.Collapsed and -90 or 0 })
        cat._UpdateSize()
    end)

    -- Draggable
    DragSystem:MakeDraggable(cat.Frame, header)

    -- ====================
    -- Add menu bar button for this category
    -- ====================
    local menuBtnW = math.clamp(#name * 8 * SCALE + 16, 55, 140)
    cat.MenuButton = Utility.Create("TextButton", {
        Name = "MenuBtn_" .. name,
        Size = UDim2.new(0, menuBtnW, 0, 24 * SCALE),
        BackgroundColor3 = startVisible and Library.CurrentAccent or Theme.MenuButton,
        BackgroundTransparency = startVisible and 0.15 or 0.1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11 * SCALE,
        TextColor3 = startVisible and Theme.TextPrimary or Theme.TextSecondary,
        Text = name,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 83,
        LayoutOrder = #Library.Categories + 1,
        Parent = Library._MenuBtnParent,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = cat.MenuButton })

    if startVisible then
        AccentEngine:Register(cat.MenuButton, "BackgroundColor3")
    end

    -- Menu button click = toggle window
    cat.MenuButton.MouseButton1Click:Connect(function()
        local isVis = cat.Frame.Visible
        Utility.ClickSound()

        if isVis then
            -- Close window with animation
            Utility.PlaySound(Sounds.Close, 0.2, 0.95)
            cat._shouldBeVisible = false
            Library.WindowStates[name] = false

            -- Scale down + fade
            Utility.Tween(cat.Frame, 0.25, {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, catWidth, 0, headerH * 0.5),
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                cat.Frame.Visible = false
                cat.Frame.Size = UDim2.new(0, catWidth, 0, headerH)
                Library:RepositionWindows()
            end)

            -- Dim children
            for _, desc in pairs(cat.Frame:GetDescendants()) do
                pcall(function()
                    if desc:IsA("GuiObject") and desc.Name ~= "Shadow" then
                        Utility.Tween(desc, 0.2, { BackgroundTransparency = 1 })
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            Utility.Tween(desc, 0.2, { TextTransparency = 1 })
                        end
                    end
                end)
            end

            -- Button deselect
            Utility.Tween(cat.MenuButton, 0.2, {
                BackgroundColor3 = Theme.MenuButton,
                TextColor3 = Theme.TextSecondary,
            })
        else
            -- Open window with animation
            Utility.PlaySound(Sounds.Open, 0.25, 1.1)
            cat._shouldBeVisible = true
            Library.WindowStates[name] = true

            -- Calculate position
            local visI = 1
            for _, c in ipairs(Library.Categories) do
                if c.Frame.Visible then visI = visI + 1 end
            end
            cat.Frame.Position = Library:CalculateWindowPosition(visI)
            cat.Frame.BackgroundTransparency = 1
            cat.Frame.Visible = true

            -- Restore children
            for _, desc in pairs(cat.Frame:GetDescendants()) do
                pcall(function()
                    if desc:IsA("GuiObject") and desc.Name ~= "Shadow" and desc.Name ~= "Ripple" then
                        local orig = desc:GetAttribute("_origBT")
                        if orig then
                            Utility.Tween(desc, 0.35, { BackgroundTransparency = orig })
                        else
                            if desc.BackgroundTransparency == 1 then
                                -- leave transparent
                            else
                                Utility.Tween(desc, 0.35, { BackgroundTransparency = 0 })
                            end
                        end
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            local origTT = desc:GetAttribute("_origTT")
                            Utility.Tween(desc, 0.35, { TextTransparency = origTT or 0 })
                        end
                    end
                end)
            end

            -- Frame appear animation
            Utility.Spring(cat.Frame, 0.4, {
                BackgroundTransparency = Library.BackgroundTransparency,
            })
            cat._UpdateSize()

            -- Button select
            Utility.Tween(cat.MenuButton, 0.2, {
                BackgroundColor3 = Library.CurrentAccent,
                TextColor3 = Theme.TextPrimary,
            })
            AccentEngine:Register(cat.MenuButton, "BackgroundColor3")
        end

        ConfigManager:AutoCheck()
    end)

    -- Hover
    cat.MenuButton.MouseEnter:Connect(function()
        if not cat.Frame.Visible then
            Utility.Tween(cat.MenuButton, 0.12, { BackgroundColor3 = Theme.MenuButtonHover })
        end
    end)
    cat.MenuButton.MouseLeave:Connect(function()
        if not cat.Frame.Visible then
            Utility.Tween(cat.MenuButton, 0.12, { BackgroundColor3 = Theme.MenuButton })
        end
    end)

    -- Entrance animation if visible
    if startVisible then
        cat.Frame.BackgroundTransparency = 1
        task.defer(function()
            Utility.Spring(cat.Frame, 0.5, { BackgroundTransparency = Library.BackgroundTransparency })
        end)
    end

    table.insert(Library.Categories, cat)
    return cat
end

-- ============================================================
-- MODULE
-- ============================================================
local Module = {}
Module.__index = Module

function Category:CreateModule(info)
    info = info or {}
    local name = info.Name or "Module"
    local flag = info.Flag or name
    local default = info.Default or false
    local callback = info.Callback or function() end
    local keybind = info.Keybind
    local cat = self

    local mod = setmetatable({}, Module)
    mod.Name = name
    mod.Flag = flag
    mod.Enabled = default
    mod.Callback = callback
    mod.Elements = {}
    mod.Category = self
    mod.Expanded = false
    mod.Keybind = keybind

    if Library.Flags[flag] ~= nil and type(Library.Flags[flag]) == "boolean" then
        mod.Enabled = Library.Flags[flag]
    end
    Library.Flags[flag] = mod.Enabled

    local modH = math.max(28 * SCALE, MIN_TOUCH)

    mod.Frame = Utility.Create("Frame", {
        Name = "Mod_" .. name,
        Size = UDim2.new(1, 0, 0, modH),
        BackgroundColor3 = Theme.ModuleBackground,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = self.ModuleContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = mod.Frame })

    -- Accent indicator
    mod.AccentBar = Utility.Create("Frame", {
        Size = UDim2.new(0, 2.5, 1, -6),
        Position = UDim2.new(0, 2, 0, 3),
        BackgroundColor3 = Library.CurrentAccent,
        BackgroundTransparency = mod.Enabled and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = mod.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = mod.AccentBar })
    AccentEngine:Register(mod.AccentBar, "BackgroundColor3")

    -- Name
    mod.NameLabel = Utility.Create("TextLabel", {
        Size = UDim2.new(1, -50 * SCALE, 0, modH),
        Position = UDim2.new(0, 11 * SCALE, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11.5 * SCALE,
        TextColor3 = mod.Enabled and Theme.TextPrimary or Theme.TextSecondary,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
        Parent = mod.Frame,
    })

    -- Toggle switch
    local switchW = 30 * SCALE
    local switchH = 15 * SCALE
    local switchFrame = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6 * SCALE, 0, modH / 2),
        Size = UDim2.new(0, switchW, 0, switchH),
        BackgroundColor3 = mod.Enabled and Library.CurrentAccent or Theme.ToggleOff,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = mod.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchFrame })
    if mod.Enabled then AccentEngine:Register(switchFrame, "BackgroundColor3") end
    mod._SwitchFrame = switchFrame

    local circleSize = switchH - 4
    local circle = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = mod.Enabled and UDim2.new(1, -circleSize - 2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, circleSize, 0, circleSize),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = switchFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })
    mod._Circle = circle

    -- Expand indicator (arrow appears when elements exist)
    mod._ExpandArrow = Utility.Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(switchW + 12) * SCALE, 0, modH / 2),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 8 * SCALE,
        TextColor3 = Theme.TextDim,
        Text = "",
        ZIndex = 13,
        Visible = false,
        Parent = mod.Frame,
    })

    -- Elements container
    mod.ElementsContainer = Utility.Create("Frame", {
        Name = "Elements",
        Position = UDim2.new(0, 0, 0, modH),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = mod.Frame,
    })

    local elemLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = mod.ElementsContainer,
    })
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 5),
        Parent = mod.ElementsContainer,
    })

    mod._elemLayout = elemLayout

    mod._UpdateElementSize = function()
        local contentH = elemLayout.AbsoluteContentSize.Y + 10
        if mod.Expanded and #mod.Elements > 0 then
            Utility.Tween(mod.ElementsContainer, 0.28, { Size = UDim2.new(1, 0, 0, contentH) })
            Utility.Tween(mod.Frame, 0.28, { Size = UDim2.new(1, 0, 0, modH + contentH) })
        else
            Utility.Tween(mod.ElementsContainer, 0.22, { Size = UDim2.new(1, 0, 0, 0) })
            Utility.Tween(mod.Frame, 0.22, { Size = UDim2.new(1, 0, 0, modH) })
        end
        task.defer(function()
            if cat._UpdateSize then cat._UpdateSize() end
        end)
    end

    elemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if mod.Expanded then mod._UpdateElementSize() end
    end)

    -- Show expand arrow when elements are added
    mod._CheckArrow = function()
        if #mod.Elements > 0 then
            mod._ExpandArrow.Text = "▶"
            mod._ExpandArrow.Visible = true
        end
    end

    -- Toggle state
    mod._SetState = function(state)
        mod.Enabled = state
        Library.Flags[mod.Flag] = state

        -- Visual
        Utility.Tween(mod.NameLabel, 0.2, {
            TextColor3 = state and Theme.TextPrimary or Theme.TextSecondary
        })
        Utility.Tween(mod.AccentBar, 0.25, {
            BackgroundTransparency = state and 0 or 1
        })
        Utility.Spring(mod._Circle, 0.3, {
            Position = state and UDim2.new(1, -circleSize - 2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        })
        if state then
            Utility.Tween(switchFrame, 0.2, { BackgroundColor3 = Library.CurrentAccent })
            AccentEngine:Register(switchFrame, "BackgroundColor3")
            Utility.ToggleOnSound()
            -- Pulse animation on frame
            Utility.Tween(mod.Frame, 0.1, { BackgroundColor3 = Theme.ModuleEnabled })
        else
            Utility.Tween(switchFrame, 0.2, { BackgroundColor3 = Theme.ToggleOff })
            Utility.ToggleOffSound()
            Utility.Tween(mod.Frame, 0.15, { BackgroundColor3 = Theme.ModuleBackground })
        end

        Library:_UpdateArrayList(name, state)
        pcall(callback, state)
        ConfigManager:AutoCheck()
    end

    -- Click to toggle
    local toggleBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, modH),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 16,
        Parent = mod.Frame,
    })

    toggleBtn.MouseButton1Click:Connect(function()
        mod._SetState(not mod.Enabled)
        -- Ripple
        local mp = UserInputService:GetMouseLocation()
        Utility.Ripple(mod.Frame, mp.X, mp.Y - (GuiService:GetGuiInset().Y))
    end)

    -- Hover
    toggleBtn.MouseEnter:Connect(function()
        Utility.Tween(mod.Frame, 0.12, { BackgroundColor3 = Theme.ModuleHover })
    end)
    toggleBtn.MouseLeave:Connect(function()
        Utility.Tween(mod.Frame, 0.12, {
            BackgroundColor3 = mod.Enabled and Theme.ModuleEnabled or Theme.ModuleBackground
        })
    end)

    -- Right click (PC) or long press (mobile) to expand
    toggleBtn.MouseButton2Click:Connect(function()
        if #mod.Elements > 0 then
            mod.Expanded = not mod.Expanded
            Utility.ExpandSound()
            Utility.Spring(mod._ExpandArrow, 0.3, { Rotation = mod.Expanded and 90 or 0 })
            mod._UpdateElementSize()
        end
    end)

    -- Mobile long press
    local pressStart = 0
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressStart = os.clock()
        end
    end)
    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if os.clock() - pressStart >= 0.45 and #mod.Elements > 0 then
                mod.Expanded = not mod.Expanded
                Utility.ExpandSound()
                Utility.Spring(mod._ExpandArrow, 0.3, { Rotation = mod.Expanded and 90 or 0 })
                mod._UpdateElementSize()
            end
        end
    end)

    -- Keybind
    if keybind then
        local kc = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not Library.Visible and not Library.KeybindActiveWhenHidden then return end
            if input.KeyCode == keybind then
                mod._SetState(not mod.Enabled)
            end
        end)
        table.insert(Library.Connections, kc)
    end

    if mod.Enabled then
        Library:_UpdateArrayList(name, true)
        pcall(callback, true)
    end

    table.insert(self.Modules, mod)
    task.defer(function() self._UpdateSize() end)
    return mod
end

-- ============================================================
-- ARRAYLIST
-- ============================================================
function Library:_UpdateArrayList(name, enabled)
    if not Library.ArrayList then return end
    if enabled then
        if not Library.ArrayList:FindFirstChild("AL_" .. name) then
            local lbl = Utility.Create("TextLabel", {
                Name = "AL_" .. name,
                Size = UDim2.new(0, 0, 0, 15 * SCALE),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Theme.Notification,
                BackgroundTransparency = 0.25,
                Font = Enum.Font.GothamMedium,
                TextSize = 10.5 * SCALE,
                TextColor3 = Library.CurrentAccent,
                Text = "  " .. name .. "  ",
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTransparency = 1,
                ZIndex = 91,
                Parent = Library.ArrayList,
            })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = lbl })
            AccentEngine:Register(lbl, "TextColor3")
            Utility.Spring(lbl, 0.35, { TextTransparency = 0 })
        end
    else
        local ex = Library.ArrayList:FindFirstChild("AL_" .. name)
        if ex then
            Utility.Tween(ex, 0.2, { TextTransparency = 1 }, nil, nil, function()
                pcall(function() ex:Destroy() end)
            end)
        end
    end
end

-- ============================================================
-- SLIDER
-- ============================================================
function Module:CreateSlider(info)
    info = info or {}
    local sName = info.Name or "Slider"
    local flag = info.Flag or (self.Flag .. "_" .. sName)
    local minV = info.Min or 0
    local maxV = info.Max or 100
    local defV = info.Default or minV
    local inc = info.Increment or 1
    local suffix = info.Suffix or ""
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and type(Library.Flags[flag]) == "number" then
        defV = Library.Flags[flag]
    end
    Library.Flags[flag] = defV

    local sH = math.max(36 * SCALE, MIN_TOUCH)

    local sFrame = Utility.Create("Frame", {
        Name = "Slider_" .. sName,
        Size = UDim2.new(1, 0, 0, sH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 14 * SCALE),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = sName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = sFrame,
    })

    local valLabel = Utility.Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0.45, 0, 0, 14 * SCALE),
        Position = UDim2.new(1, -6, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = tostring(defV) .. suffix,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 14,
        Parent = sFrame,
    })

    local track = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 18 * SCALE),
        Size = UDim2.new(1, -14, 0, 7 * SCALE),
        BackgroundColor3 = Theme.SliderBackground,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = sFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    local pct = math.clamp((defV - minV) / (maxV - minV), 0, 1)
    local fill = Utility.Create("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = track,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
    local fGrad = Utility.Create("UIGradient", { Parent = fill })
    AccentEngine:Register(fill, "BackgroundColor3")
    AccentEngine:RegisterGradient(fGrad)

    local knob = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        Size = UDim2.new(0, 12 * SCALE, 0, 12 * SCALE),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 16,
        Parent = track,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local sliding = false
    local curVal = defV
    local lastSoundTick = 0

    local function update(posX)
        local aPos = track.AbsolutePosition.X
        local aSize = track.AbsoluteSize.X
        local rel = math.clamp((posX - aPos) / aSize, 0, 1)
        local raw = minV + (maxV - minV) * rel
        local snap = math.floor(raw / inc + 0.5) * inc
        snap = math.clamp(Utility.RoundNum(snap, 4), minV, maxV)
        curVal = snap
        Library.Flags[flag] = snap
        local p = (snap - minV) / (maxV - minV)
        Utility.Tween(fill, 0.06, { Size = UDim2.new(p, 0, 1, 0) }, Enum.EasingStyle.Linear)
        Utility.Tween(knob, 0.06, { Position = UDim2.new(p, 0, 0.5, 0) }, Enum.EasingStyle.Linear)
        valLabel.Text = tostring(snap) .. suffix
        -- Slider tick sound
        if os.clock() - lastSoundTick > 0.08 then
            Utility.SliderSound()
            lastSoundTick = os.clock()
        end
        pcall(cb, snap)
        ConfigManager:AutoCheck()
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            -- Knob grow
            Utility.Spring(knob, 0.15, { Size = UDim2.new(0, 15 * SCALE, 0, 15 * SCALE) })
            update(input.Position.X)
        end
    end)

    local sc1 = UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    local sc2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if sliding then
                sliding = false
                Utility.Spring(knob, 0.2, { Size = UDim2.new(0, 12 * SCALE, 0, 12 * SCALE) })
            end
        end
    end)
    table.insert(Library.Connections, sc1)
    table.insert(Library.Connections, sc2)

    local elem = {
        Type = "Slider", Frame = sFrame,
        SetValue = function(_, v)
            v = math.clamp(v, minV, maxV)
            curVal = v; Library.Flags[flag] = v
            local pp = (v - minV) / (maxV - minV)
            fill.Size = UDim2.new(pp, 0, 1, 0)
            knob.Position = UDim2.new(pp, 0, 0.5, 0)
            valLabel.Text = tostring(v) .. suffix
            pcall(cb, v)
        end,
        GetValue = function() return curVal end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- TOGGLE (Sub)
-- ============================================================
function Module:CreateToggle(info)
    info = info or {}
    local tName = info.Name or "Toggle"
    local flag = info.Flag or (self.Flag .. "_" .. tName)
    local def = info.Default or false
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and type(Library.Flags[flag]) == "boolean" then
        def = Library.Flags[flag]
    end
    Library.Flags[flag] = def

    local tH = math.max(26 * SCALE, MIN_TOUCH)

    local tFrame = Utility.Create("Frame", {
        Name = "Tog_" .. tName,
        Size = UDim2.new(1, 0, 0, tH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -35 * SCALE, 1, 0),
        Position = UDim2.new(0, 7, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10.5 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = tName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = tFrame,
    })

    local boxSize = 16 * SCALE
    local box = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.new(0, boxSize, 0, boxSize),
        BackgroundColor3 = def and Library.CurrentAccent or Theme.ToggleOff,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = tFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
    if def then AccentEngine:Register(box, "BackgroundColor3") end

    local check = Utility.Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12 * SCALE,
        TextColor3 = Color3.new(1, 1, 1),
        Text = def and "✓" or "",
        TextTransparency = def and 0 or 1,
        ZIndex = 15,
        Parent = box,
    })

    local state = def

    local function toggle()
        state = not state
        Library.Flags[flag] = state
        if state then
            Utility.Tween(box, 0.2, { BackgroundColor3 = Library.CurrentAccent })
            AccentEngine:Register(box, "BackgroundColor3")
            check.Text = "✓"
            Utility.Spring(check, 0.25, { TextTransparency = 0 })
            -- Box bounce
            Utility.Spring(box, 0.15, { Size = UDim2.new(0, boxSize + 3, 0, boxSize + 3) })
            task.delay(0.15, function()
                Utility.Spring(box, 0.2, { Size = UDim2.new(0, boxSize, 0, boxSize) })
            end)
            Utility.ToggleOnSound()
        else
            Utility.Tween(box, 0.2, { BackgroundColor3 = Theme.ToggleOff })
            Utility.Tween(check, 0.15, { TextTransparency = 1 })
            Utility.ToggleOffSound()
        end
        pcall(cb, state)
        ConfigManager:AutoCheck()
    end

    local btn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        ZIndex = 16, Parent = tFrame,
    })
    btn.MouseButton1Click:Connect(function()
        toggle()
        local mp = UserInputService:GetMouseLocation()
        Utility.Ripple(tFrame, mp.X, mp.Y - GuiService:GetGuiInset().Y)
    end)

    local elem = {
        Type = "Toggle", Frame = tFrame,
        SetValue = function(_, v) if state ~= v then toggle() end end,
        GetValue = function() return state end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- DROPDOWN
-- ============================================================
function Module:CreateDropdown(info)
    info = info or {}
    local dName = info.Name or "Dropdown"
    local flag = info.Flag or (self.Flag .. "_" .. dName)
    local options = info.Options or {}
    local def = info.Default or (options[1] or "")
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and type(Library.Flags[flag]) == "string" then
        def = Library.Flags[flag]
    end
    Library.Flags[flag] = def

    local dClosedH = math.max(30 * SCALE, MIN_TOUCH)
    local dItemH = math.max(24 * SCALE, MIN_TOUCH - 8)
    local dOpen = false

    local dFrame = Utility.Create("Frame", {
        Name = "Drop_" .. dName,
        Size = UDim2.new(1, 0, 0, dClosedH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, dClosedH),
        Position = UDim2.new(0, 7, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = dName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = dFrame,
    })

    local selLabel = Utility.Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0.5, -8, 0, dClosedH),
        Position = UDim2.new(1, -22 * SCALE, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10 * SCALE,
        TextColor3 = Library.CurrentAccent,
        Text = def,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 14,
        Parent = dFrame,
    })
    AccentEngine:Register(selLabel, "TextColor3")

    local arrow = Utility.Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0, dClosedH / 2),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextDim,
        Text = "▼",
        ZIndex = 14,
        Parent = dFrame,
    })

    local optsCont = Utility.Create("Frame", {
        Position = UDim2.new(0, 3, 0, dClosedH),
        Size = UDim2.new(1, -6, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 14,
        Parent = dFrame,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
        Parent = optsCont,
    })

    local function buildOpts()
        for _, c in pairs(optsCont:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(options) do
            local ob = Utility.Create("TextButton", {
                Size = UDim2.new(1, 0, 0, dItemH),
                BackgroundColor3 = Theme.ModuleBackground,
                BackgroundTransparency = 0.15,
                Font = Enum.Font.Gotham,
                TextSize = 10 * SCALE,
                TextColor3 = opt == def and Library.CurrentAccent or Theme.TextSecondary,
                Text = opt,
                BorderSizePixel = 0,
                ZIndex = 15,
                LayoutOrder = i,
                AutoButtonColor = false,
                Parent = optsCont,
            })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ob })
            if opt == def then AccentEngine:Register(ob, "TextColor3") end

            ob.MouseButton1Click:Connect(function()
                Library.Flags[flag] = opt
                selLabel.Text = opt
                Utility.ClickSound()
                for _, c in pairs(optsCont:GetChildren()) do
                    if c:IsA("TextButton") then
                        if c.Text == opt then
                            c.TextColor3 = Library.CurrentAccent
                            AccentEngine:Register(c, "TextColor3")
                        else
                            Utility.Tween(c, 0.12, { TextColor3 = Theme.TextSecondary })
                        end
                    end
                end
                pcall(cb, opt)
                ConfigManager:AutoCheck()
                -- Close
                dOpen = false
                Utility.Spring(arrow, 0.2, { Rotation = 0 })
                Utility.Tween(dFrame, 0.2, { Size = UDim2.new(1, 0, 0, dClosedH) })
                task.defer(function() self._UpdateElementSize() end)
            end)

            ob.MouseEnter:Connect(function()
                Utility.Tween(ob, 0.1, { BackgroundTransparency = 0 })
            end)
            ob.MouseLeave:Connect(function()
                Utility.Tween(ob, 0.1, { BackgroundTransparency = 0.15 })
            end)
        end
    end
    buildOpts()

    local hdrBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, dClosedH),
        BackgroundTransparency = 1, Text = "",
        ZIndex = 16, Parent = dFrame,
    })
    hdrBtn.MouseButton1Click:Connect(function()
        dOpen = not dOpen
        Utility.ClickSound()
        Utility.Spring(arrow, 0.25, { Rotation = dOpen and 180 or 0 })
        local totalH = dOpen and (dClosedH + #options * (dItemH + 1) + 6) or dClosedH
        Utility.Tween(dFrame, 0.25, { Size = UDim2.new(1, 0, 0, totalH) })
        if dOpen then
            optsCont.Size = UDim2.new(1, -6, 0, #options * (dItemH + 1))
        end
        task.defer(function() self._UpdateElementSize() end)
    end)

    local elem = {
        Type = "Dropdown", Frame = dFrame,
        SetValue = function(_, v)
            if table.find(options, v) then
                Library.Flags[flag] = v; selLabel.Text = v
                for _, c in pairs(optsCont:GetChildren()) do
                    if c:IsA("TextButton") then
                        c.TextColor3 = c.Text == v and Library.CurrentAccent or Theme.TextSecondary
                    end
                end
                pcall(cb, v)
            end
        end,
        GetValue = function() return Library.Flags[flag] end,
        UpdateOptions = function(_, newOpts) options = newOpts; buildOpts() end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- COLOR PICKER
-- ============================================================
function Module:CreateColorPicker(info)
    info = info or {}
    local cpName = info.Name or "Color"
    local flag = info.Flag or (self.Flag .. "_" .. cpName)
    local def = info.Default or Color3.fromRGB(255, 0, 0)
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and typeof(Library.Flags[flag]) == "Color3" then
        def = Library.Flags[flag]
    end
    Library.Flags[flag] = def

    local cpClosedH = math.max(26 * SCALE, MIN_TOUCH)
    local cpOpenH = 110 * SCALE
    local cpOpen = false
    local h, s, v = Color3.toHSV(def)

    local cpFrame = Utility.Create("Frame", {
        Name = "CP_" .. cpName,
        Size = UDim2.new(1, 0, 0, cpClosedH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cpFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -35 * SCALE, 0, cpClosedH),
        Position = UDim2.new(0, 7, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = cpName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = cpFrame,
    })

    local preview = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0, cpClosedH / 2),
        Size = UDim2.new(0, 20 * SCALE, 0, 14 * SCALE),
        BackgroundColor3 = def,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })
    Utility.Create("UIStroke", { Color = Theme.ElementBorder, Thickness = 1, Parent = preview })

    local svSize = 75 * SCALE
    local svField = Utility.Create("ImageLabel", {
        Position = UDim2.new(0, 7, 0, cpClosedH + 4),
        Size = UDim2.new(0, svSize, 0, svSize),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://4155801252",
        ZIndex = 15,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = svField })
    Utility.Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4155801252",
        ImageColor3 = Color3.new(0, 0, 0),
        Rotation = 270,
        ZIndex = 16,
        Parent = svField,
    })

    local svCur = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.new(0, 9 * SCALE, 0, 9 * SCALE),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 17,
        Parent = svField,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCur })
    Utility.Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Parent = svCur })

    local hueW = 14 * SCALE
    local hueBar = Utility.Create("Frame", {
        Position = UDim2.new(0, 7 + svSize + 6, 0, cpClosedH + 4),
        Size = UDim2.new(0, hueW, 0, svSize),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = hueBar })
    Utility.Create("UIGradient", {
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
        Parent = hueBar,
    })

    local hueCur = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, h, 0),
        Size = UDim2.new(1, 4, 0, 4 * SCALE),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 16,
        Parent = hueBar,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCur })

    local hexBox = Utility.Create("TextBox", {
        Position = UDim2.new(0, 7 + svSize + 6 + hueW + 6, 0, cpClosedH + 4),
        Size = UDim2.new(1, -(7 + svSize + 6 + hueW + 6 + 7), 0, 20 * SCALE),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.15,
        Font = Enum.Font.Code,
        TextSize = 9 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = string.format("#%02X%02X%02X", def.R*255, def.G*255, def.B*255),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ZIndex = 15,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hexBox })

    local function updColor()
        local c = Color3.fromHSV(h, s, v)
        Library.Flags[flag] = c
        preview.BackgroundColor3 = c
        svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCur.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCur.Position = UDim2.new(0.5, 0, h, 0)
        hexBox.Text = string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
        pcall(cb, c)
        ConfigManager:AutoCheck()
    end

    local svDrag, hueDrag = false, false

    svField.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            svDrag = true
            local p, ap, as = inp.Position, svField.AbsolutePosition, svField.AbsoluteSize
            s = math.clamp((p.X - ap.X)/as.X, 0, 1)
            v = 1 - math.clamp((p.Y - ap.Y)/as.Y, 0, 1)
            updColor()
        end
    end)
    local svc1 = UserInputService.InputChanged:Connect(function(inp)
        if svDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local p, ap, as = inp.Position, svField.AbsolutePosition, svField.AbsoluteSize
            s = math.clamp((p.X - ap.X)/as.X, 0, 1)
            v = 1 - math.clamp((p.Y - ap.Y)/as.Y, 0, 1)
            updColor()
        end
    end)
    local svc2 = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then svDrag = false end
    end)

    hueBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            hueDrag = true
            h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y, 0, 0.999)
            updColor()
        end
    end)
    local hc1 = UserInputService.InputChanged:Connect(function(inp)
        if hueDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y, 0, 0.999)
            updColor()
        end
    end)
    local hc2 = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then hueDrag = false end
    end)

    for _, c in ipairs({svc1,svc2,hc1,hc2}) do table.insert(Library.Connections, c) end

    hexBox.FocusLost:Connect(function()
        local txt = hexBox.Text:gsub("#","")
        if #txt == 6 then
            local r,g,b = tonumber(txt:sub(1,2),16), tonumber(txt:sub(3,4),16), tonumber(txt:sub(5,6),16)
            if r and g and b then
                h,s,v = Color3.toHSV(Color3.fromRGB(r,g,b))
                updColor()
            end
        end
    end)

    local togArea = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, cpClosedH),
        BackgroundTransparency = 1, Text = "",
        ZIndex = 16, Parent = cpFrame,
    })
    togArea.MouseButton1Click:Connect(function()
        cpOpen = not cpOpen
        Utility.ClickSound()
        Utility.Tween(cpFrame, 0.25, {
            Size = UDim2.new(1, 0, 0, cpOpen and (cpClosedH + cpOpenH) or cpClosedH)
        })
        task.defer(function() self._UpdateElementSize() end)
    end)

    local elem = {
        Type = "ColorPicker", Frame = cpFrame,
        SetValue = function(_, c) h,s,v = Color3.toHSV(c); updColor() end,
        GetValue = function() return Color3.fromHSV(h,s,v) end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- TEXTBOX
-- ============================================================
function Module:CreateTextBox(info)
    info = info or {}
    local tName = info.Name or "TextBox"
    local flag = info.Flag or (self.Flag .. "_" .. tName)
    local def = info.Default or ""
    local ph = info.Placeholder or "Enter..."
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and type(Library.Flags[flag]) == "string" then def = Library.Flags[flag] end
    Library.Flags[flag] = def

    local tH = math.max(42 * SCALE, MIN_TOUCH + 8)

    local tFrame = Utility.Create("Frame", {
        Name = "TB_" .. tName,
        Size = UDim2.new(1, 0, 0, tH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14 * SCALE),
        Position = UDim2.new(0, 7, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 9.5 * SCALE,
        TextColor3 = Theme.TextDim,
        Text = tName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = tFrame,
    })

    local input = Utility.Create("TextBox", {
        Size = UDim2.new(1, -14, 0, 20 * SCALE),
        Position = UDim2.new(0, 7, 0, 16 * SCALE),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.15,
        Font = Enum.Font.Gotham,
        TextSize = 10.5 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = def,
        PlaceholderText = ph,
        PlaceholderColor3 = Theme.TextDim,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ZIndex = 14,
        Parent = tFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = input })
    Utility.Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = input })

    input.Focused:Connect(function()
        Utility.Tween(input, 0.15, { BackgroundColor3 = Theme.ModuleHover })
        Utility.ClickSound()
    end)
    input.FocusLost:Connect(function()
        Utility.Tween(input, 0.15, { BackgroundColor3 = Theme.SliderBackground })
        Library.Flags[flag] = input.Text
        pcall(cb, input.Text)
        ConfigManager:AutoCheck()
    end)

    local elem = {
        Type = "TextBox", Frame = tFrame,
        SetValue = function(_, v) input.Text = v; Library.Flags[flag] = v end,
        GetValue = function() return input.Text end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- BUTTON
-- ============================================================
function Module:CreateButton(info)
    info = info or {}
    local bName = info.Name or "Button"
    local cb = info.Callback or function() end

    local bH = math.max(26 * SCALE, MIN_TOUCH)

    local bFrame = Utility.Create("Frame", {
        Name = "Btn_" .. bName,
        Size = UDim2.new(1, 0, 0, bH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bFrame })

    local btn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 10.5 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = bName,
        ZIndex = 14,
        AutoButtonColor = false,
        Parent = bFrame,
    })

    btn.MouseButton1Click:Connect(function()
        Utility.ClickSound()
        -- Flash
        Utility.Tween(bFrame, 0.08, { BackgroundColor3 = Library.CurrentAccent })
        Utility.Spring(btn, 0.1, { TextColor3 = Theme.TextPrimary })
        task.delay(0.12, function()
            Utility.Tween(bFrame, 0.2, { BackgroundColor3 = Theme.ElementBackground })
            Utility.Tween(btn, 0.2, { TextColor3 = Theme.TextSecondary })
        end)
        local mp = UserInputService:GetMouseLocation()
        Utility.Ripple(bFrame, mp.X, mp.Y - GuiService:GetGuiInset().Y)
        pcall(cb)
    end)

    btn.MouseEnter:Connect(function()
        Utility.Tween(btn, 0.1, { TextColor3 = Theme.TextPrimary })
    end)
    btn.MouseLeave:Connect(function()
        Utility.Tween(btn, 0.1, { TextColor3 = Theme.TextSecondary })
    end)

    local elem = { Type = "Button", Frame = bFrame }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- LABEL
-- ============================================================
function Module:CreateLabel(info)
    info = info or {}
    local text = info.Name or info.Text or "Label"

    local lH = math.max(20 * SCALE, 20)

    local lFrame = Utility.Create("Frame", {
        Name = "Lbl",
        Size = UDim2.new(1, 0, 0, lH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = lFrame })

    local lbl = Utility.Create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextDim,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 14,
        Parent = lFrame,
    })

    local elem = {
        Type = "Label", Frame = lFrame, TextInstance = lbl,
        SetText = function(_, t) lbl.Text = t end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- KEYBIND
-- ============================================================
function Module:CreateKeybind(info)
    info = info or {}
    local kName = info.Name or "Keybind"
    local flag = info.Flag or (self.Flag .. "_" .. kName)
    local def = info.Default or Enum.KeyCode.Unknown
    local cb = info.Callback or function() end

    if Library.Flags[flag] ~= nil and typeof(Library.Flags[flag]) == "EnumItem" then def = Library.Flags[flag] end
    Library.Flags[flag] = def

    local kH = math.max(26 * SCALE, MIN_TOUCH)
    local listening = false

    local kFrame = Utility.Create("Frame", {
        Name = "KB_" .. kName,
        Size = UDim2.new(1, 0, 0, kH),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = kFrame })

    Utility.Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 7, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE,
        TextColor3 = Theme.TextSecondary,
        Text = kName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = kFrame,
    })

    local keyBtn = Utility.Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.new(0, 55 * SCALE, 0, 18 * SCALE),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.15,
        Font = Enum.Font.GothamMedium,
        TextSize = 9.5 * SCALE,
        TextColor3 = Theme.TextPrimary,
        Text = "[" .. (def == Enum.KeyCode.Unknown and "None" or def.Name) .. "]",
        BorderSizePixel = 0,
        ZIndex = 14,
        AutoButtonColor = false,
        Parent = kFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = keyBtn })

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "[...]"
        Utility.Tween(keyBtn, 0.15, { BackgroundColor3 = Library.CurrentAccent })
        Utility.ClickSound()
    end)

    local kc = UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                keyBtn.Text = "[" .. (Library.Flags[flag] == Enum.KeyCode.Unknown and "None" or Library.Flags[flag].Name) .. "]"
            else
                Library.Flags[flag] = input.KeyCode
                listening = false
                keyBtn.Text = "[" .. input.KeyCode.Name .. "]"
                pcall(cb, input.KeyCode)
                ConfigManager:AutoCheck()
            end
            Utility.Tween(keyBtn, 0.15, { BackgroundColor3 = Theme.SliderBackground })
        end
    end)
    table.insert(Library.Connections, kc)

    local elem = {
        Type = "Keybind", Frame = kFrame,
        SetValue = function(_, k)
            Library.Flags[flag] = k
            keyBtn.Text = "[" .. (k == Enum.KeyCode.Unknown and "None" or k.Name) .. "]"
            pcall(cb, k)
        end,
        GetValue = function() return Library.Flags[flag] end,
    }
    table.insert(self.Elements, elem)
    self._CheckArrow()
    task.defer(self._UpdateElementSize)
    return elem
end

-- ============================================================
-- BUILT-IN SETTINGS
-- ============================================================
function Library:_BuildSettingsCategory()
    local settings = Library:CreateCategory({ Name = "Settings", AutoShow = false })

    -- Sound
    local soundMod = settings:CreateModule({
        Name = "Sound Effects", Flag = "S_Sound", Default = true,
        Callback = function(s) Library.SoundEnabled = s end,
    })

    -- Visual
    local visMod = settings:CreateModule({
        Name = "Visual", Flag = "S_Visual", Default = true,
        Callback = function() end,
    })

    visMod:CreateDropdown({
        Name = "Color Mode", Flag = "S_ColorMode",
        Options = {"Static","Breathing","Rainbow","Gradient"},
        Default = Library.ColorMode,
        Callback = function(m) Library.ColorMode = m end,
    })
    visMod:CreateSlider({
        Name = "Dynamic Speed", Flag = "S_DynSpeed",
        Min = 0.1, Max = 5, Default = 1, Increment = 0.1, Suffix = "x",
        Callback = function(v) Library.DynamicSpeed = v end,
    })
    visMod:CreateColorPicker({
        Name = "Accent Color", Flag = "S_AccentColor",
        Default = Library.AccentColor,
        Callback = function(c) Library.AccentColor = c; if Library.ColorMode == "Static" then Library.CurrentAccent = c end end,
    })
    visMod:CreateSlider({
        Name = "BG Transparency", Flag = "S_BGTrans",
        Min = 0, Max = 0.95, Default = Library.BackgroundTransparency, Increment = 0.05,
        Callback = function(v)
            Library.BackgroundTransparency = v
            for _, cat in ipairs(Library.Categories) do
                if cat.Frame and cat.Frame.Visible then
                    Utility.Tween(cat.Frame, 0.2, { BackgroundTransparency = v })
                end
            end
        end,
    })
    visMod:CreateToggle({
        Name = "Mobile Ball", Flag = "S_MobBall",
        Default = Library.MobileBallVisible,
        Callback = function(s) Library.MobileBallVisible = s; Library.FloatingBall.Visible = IS_MOBILE and s end,
    })

    -- Interact
    local intMod = settings:CreateModule({
        Name = "Interaction", Flag = "S_Interact", Default = true,
        Callback = function() end,
    })

    intMod:CreateKeybind({
        Name = "Toggle Key", Flag = "S_TogKey",
        Default = Library.ToggleKey,
        Callback = function(k) Library.ToggleKey = k end,
    })
    intMod:CreateToggle({
        Name = "Keys When Hidden", Flag = "S_KeysHidden",
        Default = true,
        Callback = function(s) Library.KeybindActiveWhenHidden = s end,
    })
    intMod:CreateToggle({
        Name = "FPS/Ping Watermark", Flag = "S_Watermark",
        Default = false,
        Callback = function(s)
            Library.WatermarkEnabled = s
            Library.Watermark.Visible = s and Library.Visible
        end,
    })
    intMod:CreateToggle({
        Name = "ArrayList", Flag = "S_ArrList",
        Default = false,
        Callback = function(s)
            Library.ArrayListEnabled = s
            Library.ArrayList.Visible = s and Library.Visible
        end,
    })
    intMod:CreateToggle({
        Name = "Auto Save", Flag = "S_AutoSave",
        Default = false,
        Callback = function(s) Library.AutoSave = s; if s then ConfigManager:Save() end end,
    })

    -- System
    local sysMod = settings:CreateModule({
        Name = "System", Flag = "S_System", Default = true,
        Callback = function() end,
    })

    sysMod:CreateButton({
        Name = "⚠ Destroy UI",
        Callback = function()
            Library:Notify({ Title = "Goodbye!", Content = "UI destroyed.", Duration = 2, Type = "warn" })
            task.delay(1, function() Library:Destroy() end)
        end,
    })
    sysMod:CreateButton({
        Name = "💾 Save Config",
        Callback = function()
            ConfigManager:Save()
            Library:Notify({ Title = "Saved", Content = "Config saved to file.", Duration = 2, Type = "success" })
        end,
    })
    sysMod:CreateButton({
        Name = "📂 Load Config",
        Callback = function()
            ConfigManager:Load()
            Library:Notify({ Title = "Loaded", Content = "Config loaded.", Duration = 2, Type = "info" })
        end,
    })

    local rtLabel = sysMod:CreateLabel({ Name = "Runtime: 00:00:00" })
    local rtCo = task.spawn(function()
        while AccentEngine.Running do
            pcall(function() rtLabel:SetText("Runtime: " .. Utility.FormatTime(os.clock() - Library.StartTime)) end)
            task.wait(1)
        end
    end)
    table.insert(Library.Coroutines, rtCo)
end

-- ============================================================
-- DESTROY
-- ============================================================
function Library:Destroy()
    AccentEngine:Stop()
    for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
    Library.Connections = {}
    Library.AccentObjects = {}
    Library.AccentGradients = {}
    Library.Categories = {}
    Library.Flags = {}
    pcall(function() Library.ScreenGui:Destroy() end)
    Library.Initialized = false
end

return Library
