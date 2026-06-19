--[[
    Vape-Style UI Library for Roblox
    Compatible with PC & Mobile
    Author: Architecture-level implementation
    All instances mount to CoreGui
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
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- LIBRARY TABLE
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
Library.ColorMode = "Static" -- Static, Breathing, Rainbow, Gradient
Library.DynamicSpeed = 1
Library.BackgroundTransparency = 0.15
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

-- ============================================================
-- PLATFORM DETECTION
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local SCALE_FACTOR = IS_MOBILE and 1.25 or 1
local MIN_TOUCH = 36

-- ============================================================
-- UTILITY MODULE
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

function Utility.Tween(instance, tweenInfo, properties)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility.QuickTween(instance, duration, properties, easingStyle, easingDir)
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDir = easingDir or Enum.EasingDirection.Out
    return Utility.Tween(instance, TweenInfo.new(duration, easingStyle, easingDir), properties)
end

function Utility.Ripple(button, x, y)
    local absSize = button.AbsoluteSize
    local absPos = button.AbsolutePosition
    local maxDist = math.max(
        (Vector2.new(x, y) - absPos).Magnitude,
        (Vector2.new(x, y) - (absPos + absSize)).Magnitude,
        (Vector2.new(x, y) - (absPos + Vector2.new(absSize.X, 0))).Magnitude,
        (Vector2.new(x, y) - (absPos + Vector2.new(0, absSize.Y))).Magnitude
    )
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, x - absPos.X, 0, y - absPos.Y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 5,
        Parent = button,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ripple })
    local targetSize = UDim2.new(0, maxDist * 2, 0, maxDist * 2)
    Utility.QuickTween(ripple, 0.4, { Size = targetSize, BackgroundTransparency = 1 })
    task.delay(0.45, function()
        ripple:Destroy()
    end)
end

function Utility.PlaySound(soundId, volume)
    if not Library.SoundEnabled then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId or "rbxassetid://6895079853"
        sound.Volume = volume or 0.5
        sound.PlayOnRemove = false
        sound.Parent = SoundService
        sound:Play()
        task.delay(sound.TimeLength + 0.2, function()
            sound:Destroy()
        end)
    end)
end

function Utility.ClickSound()
    Utility.PlaySound("rbxassetid://6895079853", 0.3)
end

function Utility.ToggleSound(state)
    if state then
        Utility.PlaySound("rbxassetid://6895079853", 0.35)
    else
        Utility.PlaySound("rbxassetid://6895079853", 0.25)
    end
end

function Utility.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utility.LerpColor(c1, c2, t)
    return Color3.new(
        Utility.Lerp(c1.R, c2.R, t),
        Utility.Lerp(c1.G, c2.G, t),
        Utility.Lerp(c1.B, c2.B, t)
    )
end

function Utility.Darken(color, factor)
    factor = factor or 0.4
    return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

function Utility.RoundNumber(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Utility.FormatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

function Utility.DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = Utility.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ============================================================
-- THEME / COLORS
-- ============================================================
local Theme = {
    Background = Color3.fromRGB(20, 20, 30),
    CategoryHeader = Color3.fromRGB(30, 30, 45),
    ModuleBackground = Color3.fromRGB(25, 25, 38),
    ModuleHover = Color3.fromRGB(35, 35, 52),
    ElementBackground = Color3.fromRGB(32, 32, 48),
    ElementBorder = Color3.fromRGB(50, 50, 70),
    TextPrimary = Color3.fromRGB(230, 230, 240),
    TextSecondary = Color3.fromRGB(160, 160, 180),
    TextDim = Color3.fromRGB(100, 100, 120),
    SliderBackground = Color3.fromRGB(40, 40, 58),
    ToggleOff = Color3.fromRGB(55, 55, 75),
    Separator = Color3.fromRGB(45, 45, 65),
    Shadow = Color3.fromRGB(0, 0, 0),
    Watermark = Color3.fromRGB(15, 15, 22),
}

-- ============================================================
-- ACCENT COLOR ENGINE (task.spawn coroutines)
-- ============================================================
local AccentEngine = {}
AccentEngine.Running = true

function AccentEngine:Start()
    -- Main accent color computation loop
    local co = task.spawn(function()
        while AccentEngine.Running do
            local dt = os.clock()
            local speed = Library.DynamicSpeed

            if Library.ColorMode == "Static" then
                Library.CurrentAccent = Library.AccentColor
            elseif Library.ColorMode == "Breathing" then
                -- Sine wave between accent and its dark version
                local breathVal = (math.sin(dt * speed * 2) + 1) / 2 -- 0 to 1
                local darkColor = Utility.Darken(Library.AccentColor, 0.35)
                Library.CurrentAccent = Utility.LerpColor(darkColor, Library.AccentColor, breathVal)
            elseif Library.ColorMode == "Rainbow" then
                -- Full HSV hue cycle
                local hue = (dt * speed * 0.08) % 1
                Library.CurrentAccent = Color3.fromHSV(hue, 0.75, 1)
            elseif Library.ColorMode == "Gradient" then
                -- For gradient mode, the CurrentAccent is still used for non-gradient elements
                local hue1 = (dt * speed * 0.06) % 1
                Library.CurrentAccent = Color3.fromHSV(hue1, 0.7, 1)
            end

            -- Update all registered accent objects
            for _, obj in pairs(Library.AccentObjects) do
                if obj and obj.Instance and obj.Instance.Parent then
                    pcall(function()
                        if obj.Property then
                            obj.Instance[obj.Property] = Library.CurrentAccent
                        end
                    end)
                end
            end

            -- Update gradient objects
            if Library.ColorMode == "Gradient" then
                for _, gObj in pairs(Library.AccentGradients) do
                    if gObj and gObj.Gradient and gObj.Gradient.Parent then
                        pcall(function()
                            local hue1 = (dt * speed * 0.06) % 1
                            local hue2 = (hue1 + 0.35) % 1
                            gObj.Gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(hue1, 0.75, 1)),
                                ColorSequenceKeypoint.new(1, Color3.fromHSV(hue2, 0.75, 1)),
                            })
                            gObj.Gradient.Rotation = (dt * speed * 40) % 360
                        end)
                    end
                end
            else
                -- Non-gradient mode: set all gradients to solid accent
                for _, gObj in pairs(Library.AccentGradients) do
                    if gObj and gObj.Gradient and gObj.Gradient.Parent then
                        pcall(function()
                            gObj.Gradient.Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent)
                            gObj.Gradient.Rotation = 0
                        end)
                    end
                end
            end

            task.wait(1 / 60)
        end
    end)
    table.insert(Library.Coroutines, co)
end

function AccentEngine:Stop()
    AccentEngine.Running = false
end

function AccentEngine:RegisterAccent(instance, property)
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
-- DRAG SYSTEM (Cross-Platform, LongPress for mobile)
-- ============================================================
local DragSystem = {}

function DragSystem:MakeDraggable(frame, handle, onDragStart, onDragEnd)
    handle = handle or frame
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    local longPressActive = false
    local longPressThreshold = 0.25 -- seconds for mobile long press

    -- PC: standard mouse drag
    local function beginDrag(inputObj)
        dragging = true
        dragStart = inputObj.Position
        startPos = frame.Position
        if onDragStart then pcall(onDragStart) end
    end

    local function updateDrag(inputObj)
        if not dragging then return end
        local delta = inputObj.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        -- Smooth drag with tween
        Utility.QuickTween(frame, 0.08, { Position = newPos }, Enum.EasingStyle.Linear)
    end

    local function endDrag()
        if dragging then
            dragging = false
            if onDragEnd then pcall(onDragEnd) end
        end
        longPressActive = false
    end

    -- Mouse (PC)
    local conn1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag(input)
        end
    end)

    local conn2 = handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            endDrag()
        end
    end)

    local conn3 = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            updateDrag(input)
        end
    end)

    -- Touch (Mobile) - Using long press to initiate drag to avoid joystick conflict
    local touchStartTime = 0
    local touchStartPos = nil
    local touchId = nil
    local longPressCheckCo = nil

    local conn4 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStartTime = os.clock()
            touchStartPos = input.Position
            touchId = input

            -- Long press detection coroutine
            longPressCheckCo = task.spawn(function()
                task.wait(longPressThreshold)
                -- Check if finger is still roughly in same position
                if touchId and not dragging then
                    longPressActive = true
                    dragging = true
                    dragStart = input.Position
                    startPos = frame.Position
                    if onDragStart then pcall(onDragStart) end
                    -- Haptic feedback attempt
                    pcall(function()
                        game:GetService("HapticService"):SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.2)
                        task.wait(0.1)
                        game:GetService("HapticService"):SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
                    end)
                end
            end)
        end
    end)

    local conn5 = UserInputService.TouchMoved:Connect(function(input)
        if dragging and longPressActive then
            updateDrag(input)
        end
    end)

    local conn6 = UserInputService.TouchEnded:Connect(function(input)
        endDrag()
        touchId = nil
    end)

    -- Store connections for cleanup
    table.insert(Library.Connections, conn1)
    table.insert(Library.Connections, conn2)
    table.insert(Library.Connections, conn3)
    table.insert(Library.Connections, conn4)
    table.insert(Library.Connections, conn5)
    table.insert(Library.Connections, conn6)

    return {
        Disconnect = function()
            conn1:Disconnect()
            conn2:Disconnect()
            conn3:Disconnect()
            conn4:Disconnect()
            conn5:Disconnect()
            conn6:Disconnect()
        end
    }
end

-- ============================================================
-- SAVE / LOAD CONFIGURATION
-- ============================================================
local ConfigManager = {}

function ConfigManager:Save()
    local success, err = pcall(function()
        local data = {}
        for flagName, flagValue in pairs(Library.Flags) do
            if type(flagValue) == "boolean" or type(flagValue) == "number" or type(flagValue) == "string" then
                data[flagName] = flagValue
            elseif typeof(flagValue) == "Color3" then
                data[flagName] = { Type = "Color3", R = flagValue.R, G = flagValue.G, B = flagValue.B }
            elseif typeof(flagValue) == "EnumItem" then
                data[flagName] = { Type = "EnumItem", EnumType = tostring(flagValue.EnumType), Name = flagValue.Name }
            elseif type(flagValue) == "table" then
                data[flagName] = { Type = "Table", Value = flagValue }
            end
        end
        local json = HttpService:JSONEncode(data)
        writefile(Library.SaveFile, json)
    end)
    if not success then
        warn("[VapeUI] Config save failed: " .. tostring(err))
    end
end

function ConfigManager:Load()
    local success, err = pcall(function()
        if isfile and isfile(Library.SaveFile) then
            local json = readfile(Library.SaveFile)
            local data = HttpService:JSONDecode(json)
            for flagName, flagValue in pairs(data) do
                if type(flagValue) == "table" and flagValue.Type then
                    if flagValue.Type == "Color3" then
                        Library.Flags[flagName] = Color3.new(flagValue.R, flagValue.G, flagValue.B)
                    elseif flagValue.Type == "EnumItem" then
                        pcall(function()
                            Library.Flags[flagName] = Enum[flagValue.EnumType][flagValue.Name]
                        end)
                    elseif flagValue.Type == "Table" then
                        Library.Flags[flagName] = flagValue.Value
                    end
                else
                    Library.Flags[flagName] = flagValue
                end
            end
        end
    end)
    if not success then
        warn("[VapeUI] Config load failed: " .. tostring(err))
    end
end

function ConfigManager:AutoSaveCheck()
    if Library.AutoSave then
        ConfigManager:Save()
    end
end

-- ============================================================
-- MAIN UI CONSTRUCTION
-- ============================================================
function Library:Init(settings)
    settings = settings or {}
    Library.SaveFile = settings.SaveFile or "VapeUIConfig.json"
    Library.ToggleKey = settings.ToggleKey or Enum.KeyCode.RightShift
    Library.AccentColor = settings.AccentColor or Color3.fromRGB(67, 160, 255)
    Library.CurrentAccent = Library.AccentColor
    Library.Title = settings.Title or "Vape Client"

    -- Attempt to load saved config
    ConfigManager:Load()

    -- Destroy previous UI if exists
    pcall(function()
        if CoreGui:FindFirstChild("VapeUILibrary") then
            CoreGui:FindFirstChild("VapeUILibrary"):Destroy()
        end
    end)

    -- ScreenGui
    Library.ScreenGui = Utility.Create("ScreenGui", {
        Name = "VapeUILibrary",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = CoreGui,
    })

    -- Main container (holds all categories)
    Library.MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = Library.ScreenGui,
    })

    -- ========================================================
    -- WATERMARK (FPS / Ping / Runtime)
    -- ========================================================
    Library.Watermark = Utility.Create("Frame", {
        Name = "Watermark",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 220 * SCALE_FACTOR, 0, 28 * SCALE_FACTOR),
        BackgroundColor3 = Theme.Watermark,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Visible = Library.WatermarkEnabled,
        ZIndex = 100,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Library.Watermark })
    Utility.Create("UIStroke", {
        Color = Library.CurrentAccent,
        Thickness = 1.2,
        Transparency = 0.3,
        Parent = Library.Watermark,
    })
    local wmAccentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = Library.Watermark,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = wmAccentBar })
    local wmGradient = Utility.Create("UIGradient", {
        Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent),
        Parent = wmAccentBar,
    })
    AccentEngine:RegisterAccent(wmAccentBar, "BackgroundColor3")
    AccentEngine:RegisterGradient(wmGradient)

    Library.WatermarkLabel = Utility.Create("TextLabel", {
        Name = "Info",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = Library.Title .. " | FPS: -- | Ping: -- | 00:00:00",
        ZIndex = 102,
        Parent = Library.Watermark,
    })

    -- Watermark update loop
    local wmCo = task.spawn(function()
        while AccentEngine.Running do
            if Library.WatermarkEnabled and Library.Watermark then
                pcall(function()
                    local fps = math.floor(1 / RunService.RenderStepped:Wait())
                    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                    local runtime = Utility.FormatTime(os.clock() - Library.StartTime)
                    Library.WatermarkLabel.Text = string.format(
                        "%s | FPS: %d | Ping: %dms | %s",
                        Library.Title, fps, ping, runtime
                    )
                end)
            else
                task.wait(0.5)
            end
        end
    end)
    table.insert(Library.Coroutines, wmCo)

    -- ========================================================
    -- ARRAYLIST (Side module list)
    -- ========================================================
    Library.ArrayList = Utility.Create("Frame", {
        Name = "ArrayList",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -5, 0, 45 * SCALE_FACTOR),
        Size = UDim2.new(0, 180 * SCALE_FACTOR, 0, 0),
        BackgroundTransparency = 1,
        Visible = Library.ArrayListEnabled,
        ZIndex = 100,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.Name,
        Padding = UDim.new(0, 2),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = Library.ArrayList,
    })

    -- ========================================================
    -- MOBILE FLOATING BALL
    -- ========================================================
    Library.FloatingBall = Utility.Create("ImageButton", {
        Name = "FloatingBall",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 45, 0.5, 0),
        Size = UDim2.new(0, 42, 0, 42),
        BackgroundColor3 = Library.CurrentAccent,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Image = "",
        AutoButtonColor = false,
        Visible = IS_MOBILE and Library.MobileBallVisible,
        ZIndex = 200,
        Parent = Library.ScreenGui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Library.FloatingBall })
    Utility.Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1.5,
        Transparency = 0.5,
        Parent = Library.FloatingBall,
    })
    AccentEngine:RegisterAccent(Library.FloatingBall, "BackgroundColor3")

    local ballIcon = Utility.Create("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "V",
        ZIndex = 201,
        Parent = Library.FloatingBall,
    })

    -- Make floating ball draggable
    DragSystem:MakeDraggable(Library.FloatingBall, Library.FloatingBall)

    -- Toggle UI on ball tap (short tap vs drag detection)
    local ballDragged = false
    local ballTouchStart = nil

    Library.FloatingBall.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            ballTouchStart = input.Position
        end
    end)

    Library.FloatingBall.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if ballTouchStart then
                local dist = (input.Position - ballTouchStart).Magnitude
                if dist < 10 then
                    -- Short tap -> toggle UI
                    Library:ToggleUI()
                    Utility.ClickSound()
                end
            end
            ballTouchStart = nil
        end
    end)

    -- ========================================================
    -- PC KEYBOARD TOGGLE
    -- ========================================================
    local toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Library.ToggleKey then
            Library:ToggleUI()
        end
    end)
    table.insert(Library.Connections, toggleConn)

    -- Start accent engine
    AccentEngine:Start()

    Library.Initialized = true

    -- Build the built-in Settings category
    Library:_BuildSettingsCategory()

    return Library
end

function Library:ToggleUI()
    Library.Visible = not Library.Visible
    local targetTransparency = Library.Visible and 0 or 1
    -- Animate all categories
    for _, cat in ipairs(Library.Categories) do
        if cat.Frame then
            if Library.Visible then
                cat.Frame.Visible = true
                Utility.QuickTween(cat.Frame, 0.3, {
                    BackgroundTransparency = Library.BackgroundTransparency,
                })
                -- Fade in all children
                for _, desc in pairs(cat.Frame:GetDescendants()) do
                    pcall(function()
                        if desc:IsA("Frame") or desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextBox") then
                            if desc.Name ~= "Ripple" then
                                local origTrans = desc:GetAttribute("OriginalTransparency")
                                if origTrans then
                                    Utility.QuickTween(desc, 0.3, { BackgroundTransparency = origTrans })
                                end
                                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                    local origTextTrans = desc:GetAttribute("OriginalTextTransparency")
                                    if origTextTrans then
                                        Utility.QuickTween(desc, 0.3, { TextTransparency = origTextTrans })
                                    else
                                        Utility.QuickTween(desc, 0.3, { TextTransparency = 0 })
                                    end
                                end
                            end
                        end
                    end)
                end
            else
                -- Fade out all children first, then hide
                for _, desc in pairs(cat.Frame:GetDescendants()) do
                    pcall(function()
                        if desc:IsA("Frame") or desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextBox") then
                            if desc.Name ~= "Ripple" then
                                desc:SetAttribute("OriginalTransparency", desc.BackgroundTransparency)
                                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                    desc:SetAttribute("OriginalTextTransparency", desc.TextTransparency)
                                end
                                Utility.QuickTween(desc, 0.25, { BackgroundTransparency = 1 })
                                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                    Utility.QuickTween(desc, 0.25, { TextTransparency = 1 })
                                end
                            end
                        end
                    end)
                end
                task.delay(0.3, function()
                    if not Library.Visible then
                        cat.Frame.Visible = false
                    end
                end)
            end
        end
    end

    -- Watermark follows visibility unless specifically toggled
    if Library.Watermark then
        Library.Watermark.Visible = Library.Visible and Library.WatermarkEnabled
    end
    if Library.ArrayList then
        Library.ArrayList.Visible = Library.Visible and Library.ArrayListEnabled
    end
end

function Library:Destroy()
    AccentEngine:Stop()
    for _, conn in ipairs(Library.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Library.Connections = {}
    Library.Coroutines = {}
    Library.AccentObjects = {}
    Library.AccentGradients = {}
    Library.Categories = {}
    Library.Flags = {}
    Library.EnabledModules = {}
    pcall(function()
        if Library.ScreenGui then
            Library.ScreenGui:Destroy()
        end
    end)
    Library.Initialized = false
end

-- ============================================================
-- CATEGORY CREATION
-- ============================================================
local Category = {}
Category.__index = Category

function Library:CreateCategory(info)
    info = info or {}
    local categoryName = info.Name or "Category"
    local categoryIcon = info.Icon or ""
    local defaultPosition = info.Position or UDim2.new(0, 30 + (#Library.Categories * (200 * SCALE_FACTOR + 15)), 0, 80)

    local catWidth = (info.Width or 195) * SCALE_FACTOR
    local catHeaderHeight = 32 * SCALE_FACTOR

    local cat = setmetatable({}, Category)
    cat.Name = categoryName
    cat.Modules = {}
    cat.Collapsed = false

    -- Category Frame
    cat.Frame = Utility.Create("Frame", {
        Name = "Category_" .. categoryName,
        Position = defaultPosition,
        Size = UDim2.new(0, catWidth, 0, catHeaderHeight),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Library.BackgroundTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 10,
        Parent = Library.MainFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = cat.Frame })
    Utility.Create("UIStroke", {
        Color = Theme.ElementBorder,
        Thickness = 1,
        Transparency = 0.5,
        Parent = cat.Frame,
    })

    -- Shadow
    local shadow = Utility.Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 25, 1, 25),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 9,
        Parent = cat.Frame,
    })

    -- Accent top bar
    local accentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        Size = UDim2.new(1, 0, 0, 2.5),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = cat.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = accentBar })
    local accentGrad = Utility.Create("UIGradient", {
        Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent),
        Parent = accentBar,
    })
    AccentEngine:RegisterAccent(accentBar, "BackgroundColor3")
    AccentEngine:RegisterGradient(accentGrad)

    -- Header
    local header = Utility.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, catHeaderHeight),
        BackgroundColor3 = Theme.CategoryHeader,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = cat.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = header })

    -- Category Title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40 * SCALE_FACTOR, 1, 0),
        Position = UDim2.new(0, 10 * SCALE_FACTOR, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        Text = categoryName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = header,
    })

    -- Collapse Arrow
    local collapseArrow = Utility.Create("TextButton", {
        Name = "CollapseBtn",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8 * SCALE_FACTOR, 0.5, 0),
        Size = UDim2.new(0, 22 * SCALE_FACTOR, 0, 22 * SCALE_FACTOR),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = "▼",
        ZIndex = 14,
        Parent = header,
    })

    -- Module container (scrollable)
    cat.ModuleContainer = Utility.Create("ScrollingFrame", {
        Name = "ModuleContainer",
        Position = UDim2.new(0, 0, 0, catHeaderHeight),
        Size = UDim2.new(1, 0, 0, 0), -- will be resized dynamically
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.CurrentAccent,
        ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = 11,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = cat.Frame,
    })
    AccentEngine:RegisterAccent(cat.ModuleContainer, "ScrollBarImageColor3")

    local moduleLayout = Utility.Create("UIListLayout", {
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

    -- Dynamic resize function
    local maxVisibleHeight = 350 * SCALE_FACTOR
    cat._UpdateSize = function()
        if cat.Collapsed then
            Utility.QuickTween(cat.ModuleContainer, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
            Utility.QuickTween(cat.Frame, 0.25, { Size = UDim2.new(0, catWidth, 0, catHeaderHeight) })
        else
            local contentHeight = moduleLayout.AbsoluteContentSize.Y + 8
            local displayHeight = math.min(contentHeight, maxVisibleHeight)
            Utility.QuickTween(cat.ModuleContainer, 0.25, {
                Size = UDim2.new(1, 0, 0, displayHeight)
            })
            Utility.QuickTween(cat.Frame, 0.25, {
                Size = UDim2.new(0, catWidth, 0, catHeaderHeight + displayHeight)
            })
            cat.ModuleContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        end
    end

    moduleLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cat._UpdateSize()
    end)
    task.defer(function() cat._UpdateSize() end)

    -- Collapse toggle
    collapseArrow.MouseButton1Click:Connect(function()
        cat.Collapsed = not cat.Collapsed
        Utility.ClickSound()
        if cat.Collapsed then
            Utility.QuickTween(collapseArrow, 0.2, { Rotation = -90 })
        else
            Utility.QuickTween(collapseArrow, 0.2, { Rotation = 0 })
        end
        cat._UpdateSize()
    end)

    -- Collapse on touch tap for mobile (tap header area excluding collapse button)
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            -- Distinguish from drag; quick tap on header
        end
    end)

    -- Make category draggable
    DragSystem:MakeDraggable(cat.Frame, header)

    table.insert(Library.Categories, cat)
    return cat
end

-- ============================================================
-- MODULE CREATION
-- ============================================================
local Module = {}
Module.__index = Module

function Category:CreateModule(info)
    info = info or {}
    local moduleName = info.Name or "Module"
    local flagName = info.Flag or moduleName
    local defaultState = info.Default or false
    local callback = info.Callback or function() end
    local keybind = info.Keybind or nil
    local tooltip = info.Tooltip or ""

    local mod = setmetatable({}, Module)
    mod.Name = moduleName
    mod.Flag = flagName
    mod.Enabled = defaultState
    mod.Callback = callback
    mod.Keybind = keybind
    mod.Elements = {}
    mod.Category = self
    mod.Expanded = false

    if Library.Flags[flagName] ~= nil then
        mod.Enabled = Library.Flags[flagName]
    end
    Library.Flags[flagName] = mod.Enabled

    local moduleHeight = math.max(30 * SCALE_FACTOR, MIN_TOUCH)

    -- Module Frame
    mod.Frame = Utility.Create("Frame", {
        Name = "Module_" .. moduleName,
        Size = UDim2.new(1, 0, 0, moduleHeight),
        BackgroundColor3 = Theme.ModuleBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = self.ModuleContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = mod.Frame })

    -- Accent indicator (left bar)
    mod.AccentIndicator = Utility.Create("Frame", {
        Name = "AccentIndicator",
        Size = UDim2.new(0, 3, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Library.CurrentAccent,
        BackgroundTransparency = mod.Enabled and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = mod.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = mod.AccentIndicator })
    AccentEngine:RegisterAccent(mod.AccentIndicator, "BackgroundColor3")

    -- Module name label
    mod.NameLabel = Utility.Create("TextLabel", {
        Name = "NameLabel",
        Size = UDim2.new(1, -55 * SCALE_FACTOR, 0, moduleHeight),
        Position = UDim2.new(0, 12 * SCALE_FACTOR, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12.5 * SCALE_FACTOR,
        TextColor3 = mod.Enabled and Theme.TextPrimary or Theme.TextSecondary,
        Text = moduleName,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
        Parent = mod.Frame,
    })

    -- Toggle switch (visual)
    local toggleFrame = Utility.Create("Frame", {
        Name = "ToggleSwitch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8 * SCALE_FACTOR, 0, moduleHeight / 2),
        Size = UDim2.new(0, 34 * SCALE_FACTOR, 0, 17 * SCALE_FACTOR),
        BackgroundColor3 = mod.Enabled and Library.CurrentAccent or Theme.ToggleOff,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = mod.Frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleFrame })
    if mod.Enabled then
        AccentEngine:RegisterAccent(toggleFrame, "BackgroundColor3")
    end
    mod._ToggleSwitchFrame = toggleFrame

    local toggleCircle = Utility.Create("Frame", {
        Name = "Circle",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = mod.Enabled and UDim2.new(1, -15 * SCALE_FACTOR, 0.5, 0) or UDim2.new(0, 2 * SCALE_FACTOR, 0.5, 0),
        Size = UDim2.new(0, 13 * SCALE_FACTOR, 0, 13 * SCALE_FACTOR),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = toggleFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleCircle })

    -- Elements container (expandable, shown when module is clicked to expand)
    mod.ElementsContainer = Utility.Create("Frame", {
        Name = "ElementsContainer",
        Position = UDim2.new(0, 0, 0, moduleHeight),
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
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 5),
        Parent = mod.ElementsContainer,
    })

    mod._elemLayout = elemLayout

    -- Update elements container size
    mod._UpdateElementSize = function()
        local contentH = elemLayout.AbsoluteContentSize.Y + 10
        if mod.Expanded and #mod.Elements > 0 then
            Utility.QuickTween(mod.ElementsContainer, 0.25, { Size = UDim2.new(1, 0, 0, contentH) })
            Utility.QuickTween(mod.Frame, 0.25, { Size = UDim2.new(1, 0, 0, moduleHeight + contentH) })
        else
            Utility.QuickTween(mod.ElementsContainer, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
            Utility.QuickTween(mod.Frame, 0.2, { Size = UDim2.new(1, 0, 0, moduleHeight) })
        end
        task.defer(function()
            if self._UpdateSize then self._UpdateSize() end
        end)
    end

    elemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        mod._UpdateElementSize()
    end)

    -- Module toggle function
    mod._SetState = function(state)
        mod.Enabled = state
        Library.Flags[mod.Flag] = state

        -- Visual update
        Utility.QuickTween(mod.NameLabel, 0.2, {
            TextColor3 = state and Theme.TextPrimary or Theme.TextSecondary
        })
        Utility.QuickTween(mod.AccentIndicator, 0.2, {
            BackgroundTransparency = state and 0 or 1
        })
        Utility.QuickTween(toggleCircle, 0.25, {
            Position = state and UDim2.new(1, -15 * SCALE_FACTOR, 0.5, 0) or UDim2.new(0, 2 * SCALE_FACTOR, 0.5, 0)
        })
        if state then
            Utility.QuickTween(toggleFrame, 0.2, { BackgroundColor3 = Library.CurrentAccent })
        else
            Utility.QuickTween(toggleFrame, 0.2, { BackgroundColor3 = Theme.ToggleOff })
        end

        -- ArrayList update
        Library:_UpdateArrayList(moduleName, state)

        Utility.ToggleSound(state)
        pcall(callback, state)
        ConfigManager:AutoSaveCheck()
    end

    -- Click to toggle (the toggle switch area)
    local toggleBtn = Utility.Create("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(1, 0, 0, moduleHeight),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 16,
        Parent = mod.Frame,
    })

    toggleBtn.MouseButton1Click:Connect(function()
        mod._SetState(not mod.Enabled)
    end)

    -- Hover effect
    toggleBtn.MouseEnter:Connect(function()
        Utility.QuickTween(mod.Frame, 0.15, { BackgroundColor3 = Theme.ModuleHover })
    end)
    toggleBtn.MouseLeave:Connect(function()
        Utility.QuickTween(mod.Frame, 0.15, { BackgroundColor3 = Theme.ModuleBackground })
    end)

    -- Right-click (PC) or long press (mobile) to expand elements
    toggleBtn.MouseButton2Click:Connect(function()
        if #mod.Elements > 0 then
            mod.Expanded = not mod.Expanded
            mod._UpdateElementSize()
            Utility.ClickSound()
        end
    end)

    -- Mobile long press to expand
    local longPressTime = 0
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            longPressTime = os.clock()
        end
    end)
    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local duration = os.clock() - longPressTime
            if duration >= 0.5 and #mod.Elements > 0 then
                -- Long press: toggle expand
                mod.Expanded = not mod.Expanded
                mod._UpdateElementSize()
                Utility.ClickSound()
            end
        end
    end)

    -- Keybind support
    if keybind then
        local kbConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not Library.Visible and not Library.KeybindActiveWhenHidden then return end
            if input.KeyCode == keybind then
                mod._SetState(not mod.Enabled)
            end
        end)
        table.insert(Library.Connections, kbConn)
    end

    -- Apply initial state visuals without animation
    if mod.Enabled then
        Library:_UpdateArrayList(moduleName, true)
        pcall(callback, true)
    end

    table.insert(self.Modules, mod)
    task.defer(function()
        self._UpdateSize()
    end)
    return mod
end

-- ============================================================
-- ARRAYLIST MANAGEMENT
-- ============================================================
function Library:_UpdateArrayList(moduleName, enabled)
    if not Library.ArrayList then return end
    if enabled then
        if not Library.ArrayList:FindFirstChild("AL_" .. moduleName) then
            local label = Utility.Create("TextLabel", {
                Name = "AL_" .. moduleName,
                Size = UDim2.new(0, 0, 0, 16 * SCALE_FACTOR),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Theme.Watermark,
                BackgroundTransparency = 0.3,
                Font = Enum.Font.GothamMedium,
                TextSize = 11 * SCALE_FACTOR,
                TextColor3 = Library.CurrentAccent,
                Text = "  " .. moduleName .. "  ",
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 101,
                Parent = Library.ArrayList,
            })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = label })
            AccentEngine:RegisterAccent(label, "TextColor3")
            -- Animate in
            label.TextTransparency = 1
            Utility.QuickTween(label, 0.3, { TextTransparency = 0 })
        end
    else
        local existing = Library.ArrayList:FindFirstChild("AL_" .. moduleName)
        if existing then
            Utility.QuickTween(existing, 0.2, { TextTransparency = 1 })
            task.delay(0.25, function()
                pcall(function() existing:Destroy() end)
            end)
        end
    end
end

-- ============================================================
-- SLIDER
-- ============================================================
function Module:CreateSlider(info)
    info = info or {}
    local sliderName = info.Name or "Slider"
    local flagName = info.Flag or (self.Flag .. "_" .. sliderName)
    local minVal = info.Min or 0
    local maxVal = info.Max or 100
    local defaultVal = info.Default or minVal
    local increment = info.Increment or 1
    local suffix = info.Suffix or ""
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and type(Library.Flags[flagName]) == "number" then
        defaultVal = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultVal

    local sliderHeight = math.max(38 * SCALE_FACTOR, MIN_TOUCH)

    local sliderFrame = Utility.Create("Frame", {
        Name = "Slider_" .. sliderName,
        Size = UDim2.new(1, 0, 0, sliderHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sliderFrame })

    local sliderLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.55, 0, 0, 16 * SCALE_FACTOR),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = sliderName,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 14,
        Parent = sliderFrame,
    })

    local valueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0.4, 0, 0, 16 * SCALE_FACTOR),
        Position = UDim2.new(1, -6, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        Text = tostring(defaultVal) .. suffix,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 14,
        Parent = sliderFrame,
    })

    -- Slider track
    local trackFrame = Utility.Create("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 20 * SCALE_FACTOR),
        Size = UDim2.new(1, -16, 0, 8 * SCALE_FACTOR),
        BackgroundColor3 = Theme.SliderBackground,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = sliderFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackFrame })

    -- Fill
    local initialPercent = (defaultVal - minVal) / (maxVal - minVal)
    local fillFrame = Utility.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(math.clamp(initialPercent, 0, 1), 0, 1, 0),
        BackgroundColor3 = Library.CurrentAccent,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = trackFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fillFrame })
    local fillGrad = Utility.Create("UIGradient", {
        Color = ColorSequence.new(Library.CurrentAccent, Library.CurrentAccent),
        Parent = fillFrame,
    })
    AccentEngine:RegisterAccent(fillFrame, "BackgroundColor3")
    AccentEngine:RegisterGradient(fillGrad)

    -- Knob
    local knob = Utility.Create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(math.clamp(initialPercent, 0, 1), 0, 0.5, 0),
        Size = UDim2.new(0, 14 * SCALE_FACTOR, 0, 14 * SCALE_FACTOR),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 16,
        Parent = trackFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
    Utility.Create("UIStroke", {
        Color = Library.CurrentAccent,
        Thickness = 1.5,
        Parent = knob,
    })

    -- Slider logic
    local sliding = false
    local currentValue = defaultVal

    local function updateSlider(inputPos)
        local trackAbsPos = trackFrame.AbsolutePosition.X
        local trackAbsSize = trackFrame.AbsoluteSize.X
        local relativeX = math.clamp((inputPos - trackAbsPos) / trackAbsSize, 0, 1)
        local rawVal = minVal + (maxVal - minVal) * relativeX
        local snapped = math.floor(rawVal / increment + 0.5) * increment
        snapped = math.clamp(snapped, minVal, maxVal)
        snapped = Utility.RoundNumber(snapped, 4)
        currentValue = snapped
        Library.Flags[flagName] = snapped

        local percent = (snapped - minVal) / (maxVal - minVal)
        Utility.QuickTween(fillFrame, 0.08, { Size = UDim2.new(percent, 0, 1, 0) }, Enum.EasingStyle.Linear)
        Utility.QuickTween(knob, 0.08, { Position = UDim2.new(percent, 0, 0.5, 0) }, Enum.EasingStyle.Linear)
        valueLabel.Text = tostring(snapped) .. suffix

        pcall(callback, snapped)
        ConfigManager:AutoSaveCheck()
    end

    -- Mouse input
    trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(input.Position.X)
        end
    end)

    local slideConn1 = UserInputService.InputChanged:Connect(function(input)
        if sliding then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input.Position.X)
            end
        end
    end)

    local slideConn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    table.insert(Library.Connections, slideConn1)
    table.insert(Library.Connections, slideConn2)

    local element = {
        Type = "Slider",
        Frame = sliderFrame,
        SetValue = function(_, val)
            val = math.clamp(val, minVal, maxVal)
            currentValue = val
            Library.Flags[flagName] = val
            local percent = (val - minVal) / (maxVal - minVal)
            fillFrame.Size = UDim2.new(percent, 0, 1, 0)
            knob.Position = UDim2.new(percent, 0, 0.5, 0)
            valueLabel.Text = tostring(val) .. suffix
            pcall(callback, val)
        end,
        GetValue = function()
            return currentValue
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- TOGGLE (Sub-toggle within module)
-- ============================================================
function Module:CreateToggle(info)
    info = info or {}
    local toggleName = info.Name or "Toggle"
    local flagName = info.Flag or (self.Flag .. "_" .. toggleName)
    local defaultVal = info.Default or false
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and type(Library.Flags[flagName]) == "boolean" then
        defaultVal = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultVal

    local toggleHeight = math.max(28 * SCALE_FACTOR, MIN_TOUCH)

    local toggleFrame = Utility.Create("Frame", {
        Name = "Toggle_" .. toggleName,
        Size = UDim2.new(1, 0, 0, toggleHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = toggleFrame })

    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -40 * SCALE_FACTOR, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = toggleName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = toggleFrame,
    })

    -- Checkbox
    local checkBox = Utility.Create("Frame", {
        Name = "CheckBox",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8 * SCALE_FACTOR, 0.5, 0),
        Size = UDim2.new(0, 18 * SCALE_FACTOR, 0, 18 * SCALE_FACTOR),
        BackgroundColor3 = defaultVal and Library.CurrentAccent or Theme.ToggleOff,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = toggleFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = checkBox })

    local checkMark = Utility.Create("TextLabel", {
        Name = "CheckMark",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13 * SCALE_FACTOR,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = defaultVal and "✓" or "",
        ZIndex = 15,
        Parent = checkBox,
    })

    if defaultVal then
        AccentEngine:RegisterAccent(checkBox, "BackgroundColor3")
    end

    local state = defaultVal

    local function toggle()
        state = not state
        Library.Flags[flagName] = state
        if state then
            Utility.QuickTween(checkBox, 0.2, { BackgroundColor3 = Library.CurrentAccent })
            checkMark.Text = "✓"
            AccentEngine:RegisterAccent(checkBox, "BackgroundColor3")
        else
            Utility.QuickTween(checkBox, 0.2, { BackgroundColor3 = Theme.ToggleOff })
            checkMark.Text = ""
        end
        Utility.ToggleSound(state)
        pcall(callback, state)
        ConfigManager:AutoSaveCheck()
    end

    local toggleBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 16,
        Parent = toggleFrame,
    })
    toggleBtn.MouseButton1Click:Connect(toggle)

    local element = {
        Type = "Toggle",
        Frame = toggleFrame,
        SetValue = function(_, val)
            if state ~= val then
                toggle()
            end
        end,
        GetValue = function()
            return state
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- DROPDOWN
-- ============================================================
function Module:CreateDropdown(info)
    info = info or {}
    local dropName = info.Name or "Dropdown"
    local flagName = info.Flag or (self.Flag .. "_" .. dropName)
    local options = info.Options or {}
    local defaultOption = info.Default or (options[1] or "")
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and type(Library.Flags[flagName]) == "string" then
        defaultOption = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultOption

    local dropClosedHeight = math.max(32 * SCALE_FACTOR, MIN_TOUCH)
    local dropItemHeight = math.max(26 * SCALE_FACTOR, MIN_TOUCH - 6)
    local dropOpen = false

    local dropFrame = Utility.Create("Frame", {
        Name = "Dropdown_" .. dropName,
        Size = UDim2.new(1, 0, 0, dropClosedHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = dropFrame })

    local dropLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.45, 0, 0, dropClosedHeight),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = dropName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = dropFrame,
    })

    local selectedLabel = Utility.Create("TextLabel", {
        Name = "Selected",
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0.5, -8, 0, dropClosedHeight),
        Position = UDim2.new(1, -25 * SCALE_FACTOR, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Library.CurrentAccent,
        Text = defaultOption,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 14,
        Parent = dropFrame,
    })
    AccentEngine:RegisterAccent(selectedLabel, "TextColor3")

    local arrow = Utility.Create("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0, dropClosedHeight / 2),
        Size = UDim2.new(0, 16 * SCALE_FACTOR, 0, 16 * SCALE_FACTOR),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12 * SCALE_FACTOR,
        TextColor3 = Theme.TextDim,
        Text = "▼",
        ZIndex = 14,
        Parent = dropFrame,
    })

    -- Options container
    local optionsContainer = Utility.Create("Frame", {
        Name = "Options",
        Position = UDim2.new(0, 4, 0, dropClosedHeight),
        Size = UDim2.new(1, -8, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 14,
        Parent = dropFrame,
    })
    local optLayout = Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = optionsContainer,
    })

    -- Create option buttons
    local function buildOptions()
        for _, child in pairs(optionsContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, option in ipairs(options) do
            local optBtn = Utility.Create("TextButton", {
                Name = "Option_" .. option,
                Size = UDim2.new(1, 0, 0, dropItemHeight),
                BackgroundColor3 = Theme.ModuleBackground,
                BackgroundTransparency = 0.2,
                Font = Enum.Font.Gotham,
                TextSize = 11 * SCALE_FACTOR,
                TextColor3 = (option == defaultOption) and Library.CurrentAccent or Theme.TextSecondary,
                Text = option,
                BorderSizePixel = 0,
                ZIndex = 15,
                LayoutOrder = i,
                Parent = optionsContainer,
            })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = optBtn })

            if option == defaultOption then
                AccentEngine:RegisterAccent(optBtn, "TextColor3")
            end

            optBtn.MouseButton1Click:Connect(function()
                Library.Flags[flagName] = option
                selectedLabel.Text = option
                Utility.ClickSound()

                -- Reset all option colors, highlight selected
                for _, child in pairs(optionsContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        if child.Text == option then
                            child.TextColor3 = Library.CurrentAccent
                            AccentEngine:RegisterAccent(child, "TextColor3")
                        else
                            Utility.QuickTween(child, 0.15, { TextColor3 = Theme.TextSecondary })
                        end
                    end
                end

                pcall(callback, option)
                ConfigManager:AutoSaveCheck()

                -- Close dropdown
                dropOpen = false
                Utility.QuickTween(arrow, 0.2, { Rotation = 0 })
                local closedSize = UDim2.new(1, 0, 0, dropClosedHeight)
                Utility.QuickTween(dropFrame, 0.25, { Size = closedSize })
                task.defer(function() self._UpdateElementSize() end)
            end)

            -- Hover
            optBtn.MouseEnter:Connect(function()
                Utility.QuickTween(optBtn, 0.1, { BackgroundTransparency = 0 })
            end)
            optBtn.MouseLeave:Connect(function()
                Utility.QuickTween(optBtn, 0.1, { BackgroundTransparency = 0.2 })
            end)
        end
    end
    buildOptions()

    -- Toggle dropdown open/close
    local headerBtn = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, dropClosedHeight),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 16,
        Parent = dropFrame,
    })

    headerBtn.MouseButton1Click:Connect(function()
        dropOpen = not dropOpen
        Utility.ClickSound()
        if dropOpen then
            Utility.QuickTween(arrow, 0.2, { Rotation = 180 })
            local totalH = dropClosedHeight + #options * (dropItemHeight + 2) + 6
            Utility.QuickTween(dropFrame, 0.25, { Size = UDim2.new(1, 0, 0, totalH) })
            optionsContainer.Size = UDim2.new(1, -8, 0, #options * (dropItemHeight + 2))
        else
            Utility.QuickTween(arrow, 0.2, { Rotation = 0 })
            Utility.QuickTween(dropFrame, 0.25, { Size = UDim2.new(1, 0, 0, dropClosedHeight) })
        end
        task.defer(function() self._UpdateElementSize() end)
    end)

    local element = {
        Type = "Dropdown",
        Frame = dropFrame,
        SetValue = function(_, val)
            if table.find(options, val) then
                Library.Flags[flagName] = val
                selectedLabel.Text = val
                for _, child in pairs(optionsContainer:GetChildren()) do
                    if child:IsA("TextButton") then
                        if child.Text == val then
                            child.TextColor3 = Library.CurrentAccent
                        else
                            child.TextColor3 = Theme.TextSecondary
                        end
                    end
                end
                pcall(callback, val)
            end
        end,
        GetValue = function()
            return Library.Flags[flagName]
        end,
        UpdateOptions = function(_, newOptions)
            options = newOptions
            buildOptions()
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- COLOR PICKER
-- ============================================================
function Module:CreateColorPicker(info)
    info = info or {}
    local cpName = info.Name or "Color"
    local flagName = info.Flag or (self.Flag .. "_" .. cpName)
    local defaultColor = info.Default or Color3.fromRGB(255, 0, 0)
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and typeof(Library.Flags[flagName]) == "Color3" then
        defaultColor = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultColor

    local cpClosedHeight = math.max(28 * SCALE_FACTOR, MIN_TOUCH)
    local cpOpenHeight = 120 * SCALE_FACTOR
    local cpOpen = false

    local h, s, v = Color3.toHSV(defaultColor)

    local cpFrame = Utility.Create("Frame", {
        Name = "ColorPicker_" .. cpName,
        Size = UDim2.new(1, 0, 0, cpClosedHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cpFrame })

    local cpLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -40 * SCALE_FACTOR, 0, cpClosedHeight),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = cpName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = cpFrame,
    })

    -- Color preview
    local colorPreview = Utility.Create("Frame", {
        Name = "Preview",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0, cpClosedHeight / 2),
        Size = UDim2.new(0, 22 * SCALE_FACTOR, 0, 16 * SCALE_FACTOR),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = colorPreview })
    Utility.Create("UIStroke", { Color = Theme.ElementBorder, Thickness = 1, Parent = colorPreview })

    -- Saturation-Value field
    local svFieldSize = 80 * SCALE_FACTOR
    local svField = Utility.Create("ImageLabel", {
        Name = "SVField",
        Position = UDim2.new(0, 8, 0, cpClosedHeight + 5),
        Size = UDim2.new(0, svFieldSize, 0, svFieldSize),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Image = "rbxassetid://4155801252", -- white to transparent gradient
        ZIndex = 15,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = svField })

    -- Darkness overlay
    local darkOverlay = Utility.Create("ImageLabel", {
        Name = "DarkOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4155801252",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 16,
        Rotation = 270,
        Parent = svField,
    })

    -- SV cursor
    local svCursor = Utility.Create("Frame", {
        Name = "Cursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.new(0, 10 * SCALE_FACTOR, 0, 10 * SCALE_FACTOR),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 17,
        Parent = svField,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })
    Utility.Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Parent = svCursor })

    -- Hue bar
    local hueBarWidth = 16 * SCALE_FACTOR
    local hueBar = Utility.Create("Frame", {
        Name = "HueBar",
        Position = UDim2.new(0, 8 + svFieldSize + 8, 0, cpClosedHeight + 5),
        Size = UDim2.new(0, hueBarWidth, 0, svFieldSize),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = hueBar })
    -- Hue gradient
    local hueGradient = Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Rotation = 90,
        Parent = hueBar,
    })

    -- Hue cursor
    local hueCursor = Utility.Create("Frame", {
        Name = "HueCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, h, 0),
        Size = UDim2.new(1, 4, 0, 5 * SCALE_FACTOR),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 16,
        Parent = hueBar,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCursor })
    Utility.Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })

    -- HEX input
    local hexBox = Utility.Create("TextBox", {
        Name = "HexInput",
        Position = UDim2.new(0, 8 + svFieldSize + 8 + hueBarWidth + 8, 0, cpClosedHeight + 5),
        Size = UDim2.new(1, -(8 + svFieldSize + 8 + hueBarWidth + 8 + 8), 0, 22 * SCALE_FACTOR),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.2,
        Font = Enum.Font.Code,
        TextSize = 10 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        Text = "#" .. string.format("%02X%02X%02X", math.floor(defaultColor.R*255), math.floor(defaultColor.G*255), math.floor(defaultColor.B*255)),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ZIndex = 15,
        PlaceholderText = "#FFFFFF",
        Parent = cpFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hexBox })

    local function updateColor()
        local newColor = Color3.fromHSV(h, s, v)
        Library.Flags[flagName] = newColor
        colorPreview.BackgroundColor3 = newColor
        svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        hexBox.Text = "#" .. string.format("%02X%02X%02X", math.floor(newColor.R*255), math.floor(newColor.G*255), math.floor(newColor.B*255))
        pcall(callback, newColor)
        ConfigManager:AutoSaveCheck()
    end

    -- SV field interaction
    local svDragging = false
    svField.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            local pos = input.Position
            local absPos = svField.AbsolutePosition
            local absSize = svField.AbsoluteSize
            s = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
            v = 1 - math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
            updateColor()
        end
    end)

    local svConn1 = UserInputService.InputChanged:Connect(function(input)
        if svDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local absPos = svField.AbsolutePosition
                local absSize = svField.AbsoluteSize
                s = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
                v = 1 - math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
                updateColor()
            end
        end
    end)
    local svConn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)
    table.insert(Library.Connections, svConn1)
    table.insert(Library.Connections, svConn2)

    -- Hue bar interaction
    local hueDragging = false
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            local pos = input.Position
            local absPos = hueBar.AbsolutePosition
            local absSize = hueBar.AbsoluteSize
            h = math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 0.999)
            updateColor()
        end
    end)
    local hueConn1 = UserInputService.InputChanged:Connect(function(input)
        if hueDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local absPos = hueBar.AbsolutePosition
                local absSize = hueBar.AbsoluteSize
                h = math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 0.999)
                updateColor()
            end
        end
    end)
    local hueConn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    table.insert(Library.Connections, hueConn1)
    table.insert(Library.Connections, hueConn2)

    -- Hex input
    hexBox.FocusLost:Connect(function(enterPressed)
        local text = hexBox.Text:gsub("#", "")
        if #text == 6 then
            local r = tonumber(text:sub(1, 2), 16)
            local g = tonumber(text:sub(3, 4), 16)
            local b = tonumber(text:sub(5, 6), 16)
            if r and g and b then
                local newCol = Color3.fromRGB(r, g, b)
                h, s, v = Color3.toHSV(newCol)
                updateColor()
            end
        end
    end)

    -- Toggle open/close
    local toggleArea = Utility.Create("TextButton", {
        Size = UDim2.new(1, 0, 0, cpClosedHeight),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 16,
        Parent = cpFrame,
    })

    toggleArea.MouseButton1Click:Connect(function()
        cpOpen = not cpOpen
        Utility.ClickSound()
        if cpOpen then
            Utility.QuickTween(cpFrame, 0.25, { Size = UDim2.new(1, 0, 0, cpClosedHeight + cpOpenHeight) })
        else
            Utility.QuickTween(cpFrame, 0.25, { Size = UDim2.new(1, 0, 0, cpClosedHeight) })
        end
        task.defer(function() self._UpdateElementSize() end)
    end)

    local element = {
        Type = "ColorPicker",
        Frame = cpFrame,
        SetValue = function(_, color)
            h, s, v = Color3.toHSV(color)
            updateColor()
        end,
        GetValue = function()
            return Color3.fromHSV(h, s, v)
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- TEXTBOX
-- ============================================================
function Module:CreateTextBox(info)
    info = info or {}
    local tbName = info.Name or "TextBox"
    local flagName = info.Flag or (self.Flag .. "_" .. tbName)
    local defaultText = info.Default or ""
    local placeholder = info.Placeholder or "Enter text..."
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and type(Library.Flags[flagName]) == "string" then
        defaultText = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultText

    local tbHeight = math.max(45 * SCALE_FACTOR, MIN_TOUCH + 10)

    local tbFrame = Utility.Create("Frame", {
        Name = "TextBox_" .. tbName,
        Size = UDim2.new(1, 0, 0, tbHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tbFrame })

    local tbLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -10, 0, 16 * SCALE_FACTOR),
        Position = UDim2.new(0, 8, 0, 2),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10 * SCALE_FACTOR,
        TextColor3 = Theme.TextDim,
        Text = tbName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = tbFrame,
    })

    local inputBox = Utility.Create("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -16, 0, 22 * SCALE_FACTOR),
        Position = UDim2.new(0, 8, 0, 18 * SCALE_FACTOR),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.2,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        Text = defaultText,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextDim,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ZIndex = 14,
        Parent = tbFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = inputBox })
    Utility.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = inputBox,
    })

    -- Focus highlight
    inputBox.Focused:Connect(function()
        Utility.QuickTween(inputBox, 0.15, { BackgroundColor3 = Theme.ModuleHover })
    end)
    inputBox.FocusLost:Connect(function(enterPressed)
        Utility.QuickTween(inputBox, 0.15, { BackgroundColor3 = Theme.SliderBackground })
        Library.Flags[flagName] = inputBox.Text
        pcall(callback, inputBox.Text)
        ConfigManager:AutoSaveCheck()
    end)

    local element = {
        Type = "TextBox",
        Frame = tbFrame,
        SetValue = function(_, val)
            inputBox.Text = val
            Library.Flags[flagName] = val
        end,
        GetValue = function()
            return inputBox.Text
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- BUTTON
-- ============================================================
function Module:CreateButton(info)
    info = info or {}
    local btnName = info.Name or "Button"
    local callback = info.Callback or function() end

    local btnHeight = math.max(28 * SCALE_FACTOR, MIN_TOUCH)

    local btnFrame = Utility.Create("Frame", {
        Name = "Button_" .. btnName,
        Size = UDim2.new(1, 0, 0, btnHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btnFrame })

    local btn = Utility.Create("TextButton", {
        Name = "Btn",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = btnName,
        ZIndex = 14,
        Parent = btnFrame,
    })

    btn.MouseButton1Click:Connect(function()
        Utility.ClickSound()
        -- Button flash effect
        Utility.QuickTween(btnFrame, 0.1, { BackgroundColor3 = Library.CurrentAccent })
        task.delay(0.15, function()
            Utility.QuickTween(btnFrame, 0.2, { BackgroundColor3 = Theme.ElementBackground })
        end)
        -- Ripple
        local absPos = btnFrame.AbsolutePosition
        local absSize = btnFrame.AbsoluteSize
        Utility.Ripple(btnFrame, absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2)
        pcall(callback)
    end)

    btn.MouseEnter:Connect(function()
        Utility.QuickTween(btn, 0.12, { TextColor3 = Theme.TextPrimary })
    end)
    btn.MouseLeave:Connect(function()
        Utility.QuickTween(btn, 0.12, { TextColor3 = Theme.TextSecondary })
    end)

    local element = { Type = "Button", Frame = btnFrame }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- LABEL
-- ============================================================
function Module:CreateLabel(info)
    info = info or {}
    local labelText = info.Name or info.Text or "Label"

    local lblHeight = math.max(22 * SCALE_FACTOR, 22)

    local lblFrame = Utility.Create("Frame", {
        Name = "Label_" .. labelText,
        Size = UDim2.new(1, 0, 0, lblHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = lblFrame })

    local lbl = Utility.Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10.5 * SCALE_FACTOR,
        TextColor3 = Theme.TextDim,
        Text = labelText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 14,
        Parent = lblFrame,
    })

    local element = {
        Type = "Label",
        Frame = lblFrame,
        TextInstance = lbl,
        SetText = function(_, text)
            lbl.Text = text
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- KEYBIND
-- ============================================================
function Module:CreateKeybind(info)
    info = info or {}
    local kbName = info.Name or "Keybind"
    local flagName = info.Flag or (self.Flag .. "_" .. kbName)
    local defaultKey = info.Default or Enum.KeyCode.Unknown
    local callback = info.Callback or function() end

    if Library.Flags[flagName] ~= nil and typeof(Library.Flags[flagName]) == "EnumItem" then
        defaultKey = Library.Flags[flagName]
    end
    Library.Flags[flagName] = defaultKey

    local kbHeight = math.max(28 * SCALE_FACTOR, MIN_TOUCH)
    local listening = false

    local kbFrame = Utility.Create("Frame", {
        Name = "Keybind_" .. kbName,
        Size = UDim2.new(1, 0, 0, kbHeight),
        BackgroundColor3 = Theme.ElementBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 13,
        Parent = self.ElementsContainer,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = kbFrame })

    local kbLabel = Utility.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11 * SCALE_FACTOR,
        TextColor3 = Theme.TextSecondary,
        Text = kbName,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
        Parent = kbFrame,
    })

    local keyDisplayText = defaultKey == Enum.KeyCode.Unknown and "None" or defaultKey.Name
    local keyBtn = Utility.Create("TextButton", {
        Name = "KeyBtn",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 60 * SCALE_FACTOR, 0, 20 * SCALE_FACTOR),
        BackgroundColor3 = Theme.SliderBackground,
        BackgroundTransparency = 0.2,
        Font = Enum.Font.GothamMedium,
        TextSize = 10 * SCALE_FACTOR,
        TextColor3 = Theme.TextPrimary,
        Text = "[" .. keyDisplayText .. "]",
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = kbFrame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = keyBtn })

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "[...]"
        Utility.QuickTween(keyBtn, 0.15, { BackgroundColor3 = Library.CurrentAccent })
        Utility.ClickSound()
    end)

    local kbConn = UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                if key == Enum.KeyCode.Escape then
                    -- Cancel
                    listening = false
                    keyBtn.Text = "[" .. (Library.Flags[flagName] == Enum.KeyCode.Unknown and "None" or Library.Flags[flagName].Name) .. "]"
                    Utility.QuickTween(keyBtn, 0.15, { BackgroundColor3 = Theme.SliderBackground })
                else
                    Library.Flags[flagName] = key
                    listening = false
                    keyBtn.Text = "[" .. key.Name .. "]"
                    Utility.QuickTween(keyBtn, 0.15, { BackgroundColor3 = Theme.SliderBackground })
                    pcall(callback, key)
                    ConfigManager:AutoSaveCheck()
                end
            end
        end
    end)
    table.insert(Library.Connections, kbConn)

    local element = {
        Type = "Keybind",
        Frame = kbFrame,
        SetValue = function(_, key)
            Library.Flags[flagName] = key
            keyBtn.Text = "[" .. (key == Enum.KeyCode.Unknown and "None" or key.Name) .. "]"
            pcall(callback, key)
        end,
        GetValue = function()
            return Library.Flags[flagName]
        end,
    }
    table.insert(self.Elements, element)
    task.defer(function() self._UpdateElementSize() end)
    return element
end

-- ============================================================
-- BUILT-IN SETTINGS CATEGORY
-- ============================================================
function Library:_BuildSettingsCategory()
    local settingsCat = Library:CreateCategory({
        Name = "Settings",
        Position = UDim2.new(0.5, -100 * SCALE_FACTOR, 0.5, -180 * SCALE_FACTOR),
        Width = 210,
    })

    -- ==== SOUND SETTINGS ====
    local soundModule = settingsCat:CreateModule({
        Name = "Sound Effects",
        Flag = "Settings_SoundEnabled",
        Default = true,
        Callback = function(state)
            Library.SoundEnabled = state
        end,
    })

    -- ==== VISUAL CUSTOMIZATION ====
    local visualModule = settingsCat:CreateModule({
        Name = "Visual Settings",
        Flag = "Settings_VisualModule",
        Default = true,
        Callback = function() end,
    })
    -- Force expand
    visualModule.Expanded = true

    -- Color Mode Dropdown
    visualModule:CreateDropdown({
        Name = "Color Mode",
        Flag = "Settings_ColorMode",
        Options = { "Static", "Breathing", "Rainbow", "Gradient" },
        Default = Library.ColorMode,
        Callback = function(mode)
            Library.ColorMode = mode
        end,
    })

    -- Dynamic Speed Slider
    visualModule:CreateSlider({
        Name = "Dynamic Speed",
        Flag = "Settings_DynamicSpeed",
        Min = 0.1,
        Max = 5,
        Default = Library.DynamicSpeed,
        Increment = 0.1,
        Suffix = "x",
        Callback = function(val)
            Library.DynamicSpeed = val
        end,
    })

    -- Accent Color Picker
    visualModule:CreateColorPicker({
        Name = "Accent Color",
        Flag = "Settings_AccentColor",
        Default = Library.AccentColor,
        Callback = function(color)
            Library.AccentColor = color
            if Library.ColorMode == "Static" then
                Library.CurrentAccent = color
            end
        end,
    })

    -- Background Transparency Slider
    visualModule:CreateSlider({
        Name = "BG Transparency",
        Flag = "Settings_BGTransparency",
        Min = 0,
        Max = 1,
        Default = Library.BackgroundTransparency,
        Increment = 0.05,
        Callback = function(val)
            Library.BackgroundTransparency = val
            for _, cat in ipairs(Library.Categories) do
                if cat.Frame then
                    Utility.QuickTween(cat.Frame, 0.2, { BackgroundTransparency = val })
                end
            end
        end,
    })

    -- Mobile Ball Toggle
    visualModule:CreateToggle({
        Name = "Mobile Float Ball",
        Flag = "Settings_MobileBall",
        Default = Library.MobileBallVisible,
        Callback = function(state)
            Library.MobileBallVisible = state
            if Library.FloatingBall then
                Library.FloatingBall.Visible = IS_MOBILE and state
            end
        end,
    })

    -- Force update after element creation
    task.defer(function() visualModule._UpdateElementSize() end)

    -- ==== INTERACTION / CONFIG ====
    local interactModule = settingsCat:CreateModule({
        Name = "Interaction",
        Flag = "Settings_InteractModule",
        Default = true,
        Callback = function() end,
    })
    interactModule.Expanded = true

    -- Toggle Key
    interactModule:CreateKeybind({
        Name = "Toggle Key",
        Flag = "Settings_ToggleKey",
        Default = Library.ToggleKey,
        Callback = function(key)
            Library.ToggleKey = key
        end,
    })

    -- Keybind active when hidden
    interactModule:CreateToggle({
        Name = "Keys When Hidden",
        Flag = "Settings_KeysWhenHidden",
        Default = Library.KeybindActiveWhenHidden,
        Callback = function(state)
            Library.KeybindActiveWhenHidden = state
        end,
    })

    -- Watermark
    interactModule:CreateToggle({
        Name = "FPS/Ping Watermark",
        Flag = "Settings_Watermark",
        Default = Library.WatermarkEnabled,
        Callback = function(state)
            Library.WatermarkEnabled = state
            if Library.Watermark then
                Library.Watermark.Visible = state and Library.Visible
            end
        end,
    })

    -- ArrayList
    interactModule:CreateToggle({
        Name = "ArrayList",
        Flag = "Settings_ArrayList",
        Default = Library.ArrayListEnabled,
        Callback = function(state)
            Library.ArrayListEnabled = state
            if Library.ArrayList then
                Library.ArrayList.Visible = state and Library.Visible
            end
        end,
    })

    -- Auto Save
    interactModule:CreateToggle({
        Name = "Auto Save Config",
        Flag = "Settings_AutoSave",
        Default = Library.AutoSave,
        Callback = function(state)
            Library.AutoSave = state
            if state then
                ConfigManager:Save()
            end
        end,
    })

    task.defer(function() interactModule._UpdateElementSize() end)

    -- ==== SYSTEM TOOLS ====
    local systemModule = settingsCat:CreateModule({
        Name = "System",
        Flag = "Settings_SystemModule",
        Default = true,
        Callback = function() end,
    })
    systemModule.Expanded = true

    -- Destroy UI Button
    systemModule:CreateButton({
        Name = "⚠ Destroy UI",
        Callback = function()
            Library:Destroy()
        end,
    })

    -- Save Config Button
    systemModule:CreateButton({
        Name = "💾 Save Config",
        Callback = function()
            ConfigManager:Save()
        end,
    })

    -- Load Config Button
    systemModule:CreateButton({
        Name = "📂 Load Config",
        Callback = function()
            ConfigManager:Load()
        end,
    })

    -- Runtime Label
    local runtimeLabel = systemModule:CreateLabel({
        Name = "Runtime: 00:00:00",
    })

    -- Runtime update loop
    local rtCo = task.spawn(function()
        while AccentEngine.Running do
            pcall(function()
                local elapsed = os.clock() - Library.StartTime
                runtimeLabel:SetText("Runtime: " .. Utility.FormatTime(elapsed))
            end)
            task.wait(1)
        end
    end)
    table.insert(Library.Coroutines, rtCo)

    task.defer(function() systemModule._UpdateElementSize() end)

    -- Final size updates
    task.defer(function()
        task.wait(0.1)
        settingsCat._UpdateSize()
    end)
end

-- ============================================================
-- RETURN
-- ============================================================
return Library
