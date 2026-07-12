--[[
    ═══════════════════════════════════════════════════════════════
    █████╗ ███████╗████████╗██████╗  ██████╗ ██╗   ██╗██╗
    ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██║
    ███████║███████╗   ██║   ██████╔╝██║   ██║██║   ██║██║
    ██╔══██║╚════██║   ██║   ██╔══██╗██║   ██║██║   ██║██║
    ██║  ██║███████║   ██║   ██║  ██║╚██████╔╝╚██████╔╝██║
    ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝
    ═══════════════════════════════════════════════════════════════
    Advanced UI Library for Roblox Script Hub
    Version: 2.0.0
    Author: AstroUI Team
    License: MIT
    ═══════════════════════════════════════════════════════════════
]]

local AstroUI = {}
AstroUI.__index = AstroUI
AstroUI.Version = "2.0.0"

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Constants
local TWEEN_TIME = 0.3
local NOTIFICATION_DURATION = 5
local DEFAULT_THEME = {
    Primary = Color3.fromRGB(120, 120, 255),
    Secondary = Color3.fromRGB(80, 80, 200),
    Background = Color3.fromRGB(25, 25, 35),
    SecondaryBackground = Color3.fromRGB(35, 35, 50),
    TertiaryBackground = Color3.fromRGB(45, 45, 65),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 180, 200),
    Border = Color3.fromRGB(60, 60, 80),
    Success = Color3.fromRGB(100, 220, 120),
    Warning = Color3.fromRGB(255, 200, 100),
    Error = Color3.fromRGB(255, 100, 100),
    Info = Color3.fromRGB(100, 180, 255)
}

-- Sound Effects
local SOUNDS = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079853", 
    Success = "rbxassetid://6026984224",
    Error = "rbxassetid://1524245031",
    Notification = "rbxassetid://9086208751",
    Toggle = "rbxassetid://6895079853",
    Slide = "rbxassetid://6895079853"
}

-- Utility Functions
local Utils = {}

function Utils:Create(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            object[property] = value
        end
    end
    if properties.Parent then
        object.Parent = properties.Parent
    end
    return object
end

function Utils:Tween(object, properties, duration, easingStyle, easingDirection, callback)
    duration = duration or TWEEN_TIME
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    return tween
end

function Utils:Ripple(parent, x, y, color)
    local ripple = self:Create("ImageLabel", {
        Name = "Ripple",
        Parent = parent,
        BackgroundTransparency = 1,
        Image = "rbxassetid://2708891598",
        ImageColor3 = color or Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0.5,
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 1000
    })
    
    self:Tween(ripple, {
        Size = UDim2.new(0, 100, 0, 100),
        ImageTransparency = 1
    }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        ripple:Destroy()
    end)
end

function Utils:PlaySound(soundId, volume)
    volume = volume or 0.5
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    
    game:GetService("Debris"):AddItem(sound, 2)
end

function Utils:MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput, mousePos, framePos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            Utils:Tween(frame, {
                Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            }, 0.1)
        end
    end)
end

function Utils:AddCorner(parent, radius)
    radius = radius or 8
    return self:Create("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })
end

function Utils:AddStroke(parent, color, thickness)
    return self:Create("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 80),
        Thickness = thickness or 1,
        Parent = parent,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

function Utils:AddGradient(parent, color1, color2, rotation)
    return self:Create("UIGradient", {
        Color = ColorSequence.new(color1 or Color3.fromRGB(255, 255, 255), color2 or Color3.fromRGB(200, 200, 200)),
        Rotation = rotation or 90,
        Parent = parent
    })
end

function Utils:AddShadow(parent)
    local shadow = self:Create("ImageLabel", {
        Name = "Shadow",
        Parent = parent,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.7,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = parent.ZIndex - 1
    })
    return shadow
end

-- Configuration Manager
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.Configs = {}
    self.CurrentConfig = "default"
    return self
end

function ConfigManager:Save(configName, data)
    configName = configName or self.CurrentConfig
    self.Configs[configName] = HttpService:JSONEncode(data)
    
    if writefile then
        local success, err = pcall(function()
            writefile("AstroUI_" .. configName .. ".json", self.Configs[configName])
        end)
        return success
    end
    return false
end

function ConfigManager:Load(configName)
    configName = configName or self.CurrentConfig
    
    if readfile and isfile and isfile("AstroUI_" .. configName .. ".json") then
        local success, data = pcall(function()
            return readfile("AstroUI_" .. configName .. ".json")
        end)
        
        if success then
            local decoded = HttpService:JSONDecode(data)
            self.Configs[configName] = data
            return decoded
        end
    end
    
    return nil
end

function ConfigManager:Delete(configName)
    configName = configName or self.CurrentConfig
    self.Configs[configName] = nil
    
    if delfile and isfile and isfile("AstroUI_" .. configName .. ".json") then
        pcall(function()
            delfile("AstroUI_" .. configName .. ".json")
        end)
    end
end

function ConfigManager:List()
    local configs = {}
    
    if listfiles then
        local files = listfiles("AstroUI_*.json")
        for _, file in ipairs(files) do
            local name = file:match("AstroUI_(.+)%.json")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    return configs
end

-- Notification System
local NotificationManager = {}
NotificationManager.__index = NotificationManager
NotificationManager.Notifications = {}
NotificationManager.Container = nil

function NotificationManager:Initialize(parent)
    if not self.Container then
        self.Container = Utils:Create("Frame", {
            Name = "NotificationContainer",
            Parent = parent,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 0, 20),
            Size = UDim2.new(0, 300, 1, -40),
            AnchorPoint = Vector2.new(1, 0),
            ZIndex = 10000
        })
        
        Utils:Create("UIListLayout", {
            Parent = self.Container,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Right
        })
    end
end

function NotificationManager:Create(options)
    options = options or {}
    local title = options.Title or "Notification"
    local message = options.Message or "This is a notification"
    local duration = options.Duration or NOTIFICATION_DURATION
    local type = options.Type or "Info" -- Info, Success, Warning, Error
    local callback = options.Callback
    
    local typeColors = {
        Info = DEFAULT_THEME.Info,
        Success = DEFAULT_THEME.Success,
        Warning = DEFAULT_THEME.Warning,
        Error = DEFAULT_THEME.Error
    }
    
    local color = typeColors[type] or DEFAULT_THEME.Info
    
    Utils:PlaySound(type == "Error" and SOUNDS.Error or SOUNDS.Notification, 0.3)
    
    local notification = Utils:Create("Frame", {
        Name = "Notification",
        Parent = self.Container,
        BackgroundColor3 = DEFAULT_THEME.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = 10001
    })
    
    Utils:AddCorner(notification, 10)
    Utils:AddStroke(notification, color, 2)
    
    local accentBar = Utils:Create("Frame", {
        Name = "AccentBar",
        Parent = notification,
        BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 10002
    })
    
    local iconContainer = Utils:Create("Frame", {
        Name = "IconContainer",
        Parent = notification,
        BackgroundColor3 = color,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(0, 40, 0, 40),
        ZIndex = 10002
    })
    
    Utils:AddCorner(iconContainer, 20)
    
    local icon = Utils:Create("TextLabel", {
        Parent = iconContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = ({Info = "ℹ", Success = "✓", Warning = "⚠", Error = "✕"})[type] or "ℹ",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        ZIndex = 10003
    })
    
    local titleLabel = Utils:Create("TextLabel", {
        Name = "Title",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 65, 0, 15),
        Size = UDim2.new(1, -110, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = DEFAULT_THEME.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10002
    })
    
    local messageLabel = Utils:Create("TextLabel", {
        Name = "Message",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 65, 0, 38),
        Size = UDim2.new(1, -110, 0, 32),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = DEFAULT_THEME.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 10002
    })
    
    local closeButton = Utils:Create("TextButton", {
        Name = "CloseButton",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 10),
        Size = UDim2.new(0, 30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = DEFAULT_THEME.SubText,
        TextSize = 20,
        ZIndex = 10002
    })
    
    local progressBar = Utils:Create("Frame", {
        Name = "ProgressBar",
        Parent = notification,
        BackgroundColor3 = color,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        BorderSizePixel = 0,
        ZIndex = 10002
    })
    
    -- Animations
    Utils:Tween(notification, {Size = UDim2.new(1, 0, 0, 80)}, 0.3, Enum.EasingStyle.Back)
    
    closeButton.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        self:Remove(notification)
    end)
    
    if callback then
        notification.MouseButton1Click:Connect(callback)
    end
    
    -- Auto dismiss
    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local progress = math.clamp(1 - (elapsed / duration), 0, 1)
        progressBar.Size = UDim2.new(progress, 0, 0, 3)
        
        if elapsed >= duration then
            connection:Disconnect()
            self:Remove(notification)
        end
    end)
    
    table.insert(self.Notifications, {
        Frame = notification,
        Connection = connection
    })
    
    return notification
end

function NotificationManager:Remove(notification)
    Utils:Tween(notification, {
        Size = UDim2.new(1, 0, 0, 0)
    }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
        notification:Destroy()
    end)
    
    for i, notif in ipairs(self.Notifications) do
        if notif.Frame == notification then
            if notif.Connection then
                notif.Connection:Disconnect()
            end
            table.remove(self.Notifications, i)
            break
        end
    end
end

-- Main Library
function AstroUI.new(options)
    local self = setmetatable({}, AstroUI)
    
    options = options or {}
    self.Title = options.Title or "AstroUI Hub"
    self.Theme = options.Theme or DEFAULT_THEME
    self.ConfigSystem = options.ConfigSystem ~= false
    self.Transparency = options.Transparency or 0
    
    self.Tabs = {}
    self.CurrentTab = nil
    self.ConfigManager = ConfigManager.new()
    self.Flags = {}
    
    -- Create GUI
    self:CreateGUI()
    
    -- Initialize Notification Manager
    NotificationManager:Initialize(self.ScreenGui)
    
    -- Load saved settings
    if self.ConfigSystem then
        self:LoadSettings()
    end
    
    return self
end

function AstroUI:CreateGUI()
    -- Screen GUI
    local screenGui = Utils:Create("ScreenGui", {
        Name = "AstroUI_" .. HttpService:GenerateGUID(false),
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    self.ScreenGui = screenGui
    
    -- Main Frame
    local mainFrame = Utils:Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        BackgroundColor3 = self.Theme.Background,
        Position = UDim2.new(0.5, -400, 0.5, -300),
        Size = UDim2.new(0, 800, 0, 600),
        ClipsDescendants = true,
        BackgroundTransparency = self.Transparency
    })
    
    self.MainFrame = mainFrame
    
    Utils:AddCorner(mainFrame, 12)
    Utils:AddShadow(mainFrame)
    Utils:MakeDraggable(mainFrame, mainFrame)
    
    -- Header
    local header = Utils:Create("Frame", {
        Name = "Header",
        Parent = mainFrame,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 50),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(header, 12)
    
    local headerBottom = Utils:Create("Frame", {
        Parent = header,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    -- Title
    local titleLabel = Utils:Create("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(0, 300, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Version Label
    local versionLabel = Utils:Create("TextLabel", {
        Name = "Version",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 320, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "v" .. self.Version,
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Control Buttons Container
    local controlsContainer = Utils:Create("Frame", {
        Name = "Controls",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -150, 0, 10),
        Size = UDim2.new(0, 140, 0, 30)
    })
    
    Utils:Create("UIListLayout", {
        Parent = controlsContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    
    -- Settings Button
    local settingsBtn = self:CreateControlButton(controlsContainer, "⚙", function()
        self:ToggleSettings()
    end)
    
    -- Minimize Button
    local minimizeBtn = self:CreateControlButton(controlsContainer, "−", function()
        self:ToggleMinimize()
    end)
    
    -- Close Button
    local closeBtn = self:CreateControlButton(controlsContainer, "×", function()
        self:Destroy()
    end)
    
    -- Tab Container
    local tabContainer = Utils:Create("Frame", {
        Name = "TabContainer",
        Parent = mainFrame,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(0, 180, 1, -50),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    self.TabContainer = tabContainer
    
    Utils:Create("UIListLayout", {
        Parent = tabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    Utils:Create("UIPadding", {
        Parent = tabContainer,
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })
    
    -- Content Container
    local contentContainer = Utils:Create("Frame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 180, 0, 50),
        Size = UDim2.new(1, -180, 1, -50)
    })
    
    self.ContentContainer = contentContainer
    
    -- Settings Panel (Hidden by default)
    self:CreateSettingsPanel()
    
    -- Intro Animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    Utils:Tween(mainFrame, {
        Size = UDim2.new(0, 800, 0, 600)
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function AstroUI:CreateControlButton(parent, text, callback)
    local button = Utils:Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Size = UDim2.new(0, 30, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(button, 6)
    
    button.MouseEnter:Connect(function()
        Utils:PlaySound(SOUNDS.Hover, 0.2)
        Utils:Tween(button, {BackgroundColor3 = self.Theme.Primary}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utils:Tween(button, {BackgroundColor3 = self.Theme.TertiaryBackground}, 0.2)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        Utils:Ripple(button, button.AbsoluteSize.X/2, button.AbsoluteSize.Y/2, self.Theme.Primary)
        if callback then callback() end
    end)
    
    return button
end

function AstroUI:CreateSettingsPanel()
    local settingsPanel = Utils:Create("Frame", {
        Name = "SettingsPanel",
        Parent = self.MainFrame,
        BackgroundColor3 = self.Theme.Background,
        Position = UDim2.new(1, 0, 0, 50),
        Size = UDim2.new(0, 300, 1, -50),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        BackgroundTransparency = self.Transparency
    })
    
    self.SettingsPanel = settingsPanel
    
    Utils:AddStroke(settingsPanel, self.Theme.Border, 1)
    
    local settingsTitle = Utils:Create("TextLabel", {
        Name = "SettingsTitle",
        Parent = settingsPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(1, -40, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = "UI Settings",
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local settingsScroll = Utils:Create("ScrollingFrame", {
        Name = "SettingsScroll",
        Parent = settingsPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 60),
        Size = UDim2.new(1, -20, 1, -70),
        ScrollBarThickness = 4,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = self.Theme.Primary
    })
    
    local settingsLayout = Utils:Create("UIListLayout", {
        Parent = settingsScroll,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 15)
    })
    
    settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        settingsScroll.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y + 20)
    end)
    
    Utils:Create("UIPadding", {
        Parent = settingsScroll,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })
    
    -- Transparency Slider
    self:CreateSettingSlider(settingsScroll, "UI Transparency", 0, 0.9, self.Transparency, function(value)
        self:SetTransparency(value)
    end)
    
    -- Theme Color Picker
    self:CreateSettingColorPicker(settingsScroll, "Primary Color", self.Theme.Primary, function(color)
        self:SetThemeColor("Primary", color)
    end)
    
    -- Config Section
    local configSection = Utils:Create("Frame", {
        Name = "ConfigSection",
        Parent = settingsScroll,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(configSection, 8)
    
    local configTitle = Utils:Create("TextLabel", {
        Parent = configSection,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = "Configuration",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local configInput = Utils:Create("TextBox", {
        Name = "ConfigInput",
        Parent = configSection,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 15, 0, 45),
        Size = UDim2.new(1, -30, 0, 35),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Config name...",
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(configInput, 6)
    Utils:Create("UIPadding", {
        Parent = configInput,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    
    local buttonContainer = Utils:Create("Frame", {
        Parent = configSection,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 90),
        Size = UDim2.new(1, -30, 0, 50)
    })
    
    Utils:Create("UIListLayout", {
        Parent = buttonContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    
    self:CreateSmallButton(buttonContainer, "Save", function()
        local name = configInput.Text ~= "" and configInput.Text or "default"
        if self:SaveConfig(name) then
            NotificationManager:Create({
                Title = "Config Saved",
                Message = "Configuration '" .. name .. "' saved successfully!",
                Type = "Success",
                Duration = 3
            })
        end
    end)
    
    self:CreateSmallButton(buttonContainer, "Load", function()
        local name = configInput.Text ~= "" and configInput.Text or "default"
        if self:LoadConfig(name) then
            NotificationManager:Create({
                Title = "Config Loaded",
                Message = "Configuration '" .. name .. "' loaded successfully!",
                Type = "Success",
                Duration = 3
            })
        else
            NotificationManager:Create({
                Title = "Load Failed",
                Message = "Could not find configuration '" .. name .. "'",
                Type = "Error",
                Duration = 3
            })
        end
    end)
    
    self:CreateSmallButton(buttonContainer, "Delete", function()
        local name = configInput.Text ~= "" and configInput.Text or "default"
        self.ConfigManager:Delete(name)
        NotificationManager:Create({
            Title = "Config Deleted",
            Message = "Configuration '" .. name .. "' deleted!",
            Type = "Info",
            Duration = 3
        })
    end)
end

function AstroUI:CreateSmallButton(parent, text, callback)
    local button = Utils:Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(0, 80, 0, 35),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(button, 6)
    
    button.MouseEnter:Connect(function()
        Utils:Tween(button, {BackgroundColor3 = self.Theme.Secondary}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utils:Tween(button, {BackgroundColor3 = self.Theme.Primary}, 0.2)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        Utils:Ripple(button, button.AbsoluteSize.X/2, button.AbsoluteSize.Y/2, Color3.fromRGB(255, 255, 255))
        if callback then callback() end
    end)
    
    return button
end

function AstroUI:CreateSettingSlider(parent, name, min, max, default, callback)
    local container = Utils:Create("Frame", {
        Name = name,
        Parent = parent,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(container, 8)
    
    local label = Utils:Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utils:Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 10),
        Size = UDim2.new(0, 45, 0, 20),
        Font = Enum.Font.Gotham,
        Text = tostring(math.floor(default * 100)) .. "%",
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderBack = Utils:Create("Frame", {
        Name = "SliderBack",
        Parent = container,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 15, 0, 40),
        Size = UDim2.new(1, -30, 0, 6),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(sliderBack, 3)
    
    local sliderFill = Utils:Create("Frame", {
        Name = "SliderFill",
        Parent = sliderBack,
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(sliderFill, 3)
    
    local sliderButton = Utils:Create("Frame", {
        Name = "SliderButton",
        Parent = sliderBack,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(sliderButton, 8)
    Utils:AddStroke(sliderButton, self.Theme.Primary, 2)
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * pos
        
        Utils:Tween(sliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
        Utils:Tween(sliderButton, {Position = UDim2.new(pos, -8, 0.5, -8)}, 0.1)
        
        valueLabel.Text = tostring(math.floor(value * 100)) .. "%"
        
        if callback then
            callback(value)
        end
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Utils:PlaySound(SOUNDS.Slide, 0.3)
            updateSlider(input)
        end
    end)
    
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    return container
end

function AstroUI:CreateSettingColorPicker(parent, name, default, callback)
    local container = Utils:Create("Frame", {
        Name = name,
        Parent = parent,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(container, 8)
    
    local label = Utils:Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local colorDisplay = Utils:Create("Frame", {
        Name = "ColorDisplay",
        Parent = container,
        BackgroundColor3 = default,
        Position = UDim2.new(1, -45, 0.5, -12),
        Size = UDim2.new(0, 30, 0, 24),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(colorDisplay, 6)
    Utils:AddStroke(colorDisplay, self.Theme.Border, 1)
    
    local colorButton = Utils:Create("TextButton", {
        Parent = colorDisplay,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    colorButton.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        -- Open color picker (simplified version)
        local hue = 0
        local sat = 1
        local val = 1
        
        -- Cycle through rainbow colors on click
        hue = (hue + 0.1) % 1
        local color = Color3.fromHSV(hue, sat, val)
        colorDisplay.BackgroundColor3 = color
        
        if callback then
            callback(color)
        end
    end)
    
    return container
end

function AstroUI:ToggleSettings()
    local isVisible = self.SettingsPanel.Visible
    
    if not isVisible then
        self.SettingsPanel.Visible = true
        self.SettingsPanel.Position = UDim2.new(1, 0, 0, 50)
        Utils:Tween(self.SettingsPanel, {
            Position = UDim2.new(1, -300, 0, 50)
        }, 0.3, Enum.EasingStyle.Quad)
    else
        Utils:Tween(self.SettingsPanel, {
            Position = UDim2.new(1, 0, 0, 50)
        }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
            self.SettingsPanel.Visible = false
        end)
    end
    
    Utils:PlaySound(SOUNDS.Click, 0.3)
end

function AstroUI:ToggleMinimize()
    local isMinimized = self.MainFrame.Size.Y.Offset <= 50
    
    if not isMinimized then
        Utils:Tween(self.MainFrame, {
            Size = UDim2.new(0, 800, 0, 50)
        }, 0.3, Enum.EasingStyle.Quad)
    else
        Utils:Tween(self.MainFrame, {
            Size = UDim2.new(0, 800, 0, 600)
        }, 0.3, Enum.EasingStyle.Back)
    end
    
    Utils:PlaySound(SOUNDS.Click, 0.3)
end

function AstroUI:SetTransparency(value)
    self.Transparency = value
    
    local function updateTransparency(object)
        if object:IsA("Frame") or object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") or object:IsA("ImageLabel") then
            if object.BackgroundTransparency < 1 then
                object.BackgroundTransparency = value
            end
        end
        
        for _, child in ipairs(object:GetChildren()) do
            updateTransparency(child)
        end
    end
    
    updateTransparency(self.MainFrame)
end

function AstroUI:SetThemeColor(colorName, color)
    if self.Theme[colorName] then
        self.Theme[colorName] = color
        
        -- Update all UI elements with the new theme color
        -- This is a simplified version
        local function updateColors(object)
            if object:IsA("Frame") and object.BackgroundColor3 == self.Theme[colorName] then
                object.BackgroundColor3 = color
            elseif object:IsA("UIStroke") and object.Color == self.Theme[colorName] then
                object.Color = color
            end
            
            for _, child in ipairs(object:GetChildren()) do
                updateColors(child)
            end
        end
        
        updateColors(self.MainFrame)
    end
end

-- Tab System
function AstroUI:CreateTab(name, icon)
    icon = icon or "📑"
    
    local tab = {
        Name = name,
        Icon = icon,
        Button = nil,
        Content = nil,
        Elements = {}
    }
    
    -- Tab Button
    local tabButton = Utils:Create("TextButton", {
        Name = name,
        Parent = self.TabContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(tabButton, 8)
    
    local iconLabel = Utils:Create("TextLabel", {
        Name = "Icon",
        Parent = tabButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = self.Theme.SubText,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local nameLabel = Utils:Create("TextLabel", {
        Name = "Name",
        Parent = tabButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local indicator = Utils:Create("Frame", {
        Name = "Indicator",
        Parent = tabButton,
        BackgroundColor3 = self.Theme.Primary,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(indicator, 8)
    
    -- Tab Content
    local tabContent = Utils:Create("ScrollingFrame", {
        Name = name .. "Content",
        Parent = self.ContentContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 4,
        BorderSizePixel = 0,
        Visible = false,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = self.Theme.Primary
    })
    
    local contentLayout = Utils:Create("UIListLayout", {
        Parent = tabContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    Utils:Create("UIPadding", {
        Parent = tabContent,
        PaddingTop = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15)
    })
    
    tab.Button = tabButton
    tab.Content = tabContent
    
    -- Tab Button Click
    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
        Utils:PlaySound(SOUNDS.Click, 0.3)
        Utils:Ripple(tabButton, tabButton.AbsoluteSize.X/2, tabButton.AbsoluteSize.Y/2, self.Theme.Primary)
    end)
    
    tabButton.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            Utils:PlaySound(SOUNDS.Hover, 0.2)
            Utils:Tween(tabButton, {BackgroundColor3 = self.Theme.SecondaryBackground}, 0.2)
        end
    end)
    
    tabButton.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            Utils:Tween(tabButton, {BackgroundColor3 = self.Theme.TertiaryBackground}, 0.2)
        end
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Select first tab automatically
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    return setmetatable(tab, {__index = self})
end

function AstroUI:SelectTab(tab)
    -- Deselect current tab
    if self.CurrentTab then
        Utils:Tween(self.CurrentTab.Button, {BackgroundColor3 = self.Theme.TertiaryBackground}, 0.2)
        Utils:Tween(self.CurrentTab.Button.Indicator, {Size = UDim2.new(0, 0, 1, 0)}, 0.2)
        self.CurrentTab.Button.Icon.TextColor3 = self.Theme.SubText
        self.CurrentTab.Button.Name.TextColor3 = self.Theme.SubText
        self.CurrentTab.Content.Visible = false
    end
    
    -- Select new tab
    self.CurrentTab = tab
    Utils:Tween(tab.Button, {BackgroundColor3 = self.Theme.SecondaryBackground}, 0.2)
    Utils:Tween(tab.Button.Indicator, {Size = UDim2.new(0, 3, 1, 0)}, 0.3, Enum.EasingStyle.Back)
    tab.Button.Icon.TextColor3 = self.Theme.Primary
    tab.Button.Name.TextColor3 = self.Theme.Text
    tab.Content.Visible = true
end

-- UI Elements

-- 1. Button
function AstroUI:CreateButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local callback = options.Callback or function() end
    
    local buttonContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(buttonContainer, 8)
    
    local button = Utils:Create("TextButton", {
        Name = name,
        Parent = buttonContainer,
        BackgroundColor3 = self.Theme.Primary,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(1, -20, 0, 35),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(button, 6)
    
    button.MouseEnter:Connect(function()
        Utils:PlaySound(SOUNDS.Hover, 0.2)
        Utils:Tween(button, {BackgroundColor3 = self.Theme.Secondary}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Utils:Tween(button, {BackgroundColor3 = self.Theme.Primary}, 0.2)
    end)
    
    button.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        Utils:Ripple(button, button.AbsoluteSize.X/2, button.AbsoluteSize.Y/2, Color3.fromRGB(255, 255, 255))
        callback()
    end)
    
    return buttonContainer
end

-- 2. Toggle
function AstroUI:CreateToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local state = default
    
    if flag then
        self.Flags[flag] = state
    end
    
    local toggleContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(toggleContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = toggleContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleFrame = Utils:Create("Frame", {
        Name = "ToggleFrame",
        Parent = toggleContainer,
        BackgroundColor3 = state and self.Theme.Primary or self.Theme.TertiaryBackground,
        Position = UDim2.new(1, -55, 0.5, 0),
        Size = UDim2.new(0, 45, 0, 25),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(toggleFrame, 12)
    
    local toggleButton = Utils:Create("Frame", {
        Name = "ToggleButton",
        Parent = toggleFrame,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 19, 0, 19),
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(toggleButton, 10)
    
    local clickDetector = Utils:Create("TextButton", {
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    local function toggle()
        state = not state
        
        if flag then
            self.Flags[flag] = state
        end
        
        Utils:PlaySound(SOUNDS.Toggle, 0.3)
        
        Utils:Tween(toggleFrame, {
            BackgroundColor3 = state and self.Theme.Primary or self.Theme.TertiaryBackground
        }, 0.2)
        
        Utils:Tween(toggleButton, {
            Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        }, 0.2, Enum.EasingStyle.Quad)
        
        callback(state)
    end
    
    clickDetector.MouseButton1Click:Connect(toggle)
    
    return toggleContainer, function() return state end, toggle
end

-- 3. Slider
function AstroUI:CreateSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local value = default
    
    if flag then
        self.Flags[flag] = value
    end
    
    local sliderContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(sliderContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = sliderContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -70, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utils:Create("TextLabel", {
        Name = "ValueLabel",
        Parent = sliderContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -55, 0, 10),
        Size = UDim2.new(0, 40, 0, 20),
        Font = Enum.Font.Gotham,
        Text = tostring(value),
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderBack = Utils:Create("Frame", {
        Name = "SliderBack",
        Parent = sliderContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 15, 0, 38),
        Size = UDim2.new(1, -30, 0, 8),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(sliderBack, 4)
    
    local sliderFill = Utils:Create("Frame", {
        Name = "SliderFill",
        Parent = sliderBack,
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(sliderFill, 4)
    
    local sliderButton = Utils:Create("Frame", {
        Name = "SliderButton",
        Parent = sliderBack,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new((value - min) / (max - min), -10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(sliderButton, 10)
    Utils:AddStroke(sliderButton, self.Theme.Primary, 3)
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pos / increment + 0.5) * increment
        value = math.clamp(value, min, max)
        
        if flag then
            self.Flags[flag] = value
        end
        
        Utils:Tween(sliderFill, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}, 0.1)
        Utils:Tween(sliderButton, {Position = UDim2.new((value - min) / (max - min), -10, 0.5, -10)}, 0.1)
        
        valueLabel.Text = tostring(value)
        callback(value)
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            Utils:PlaySound(SOUNDS.Slide, 0.3)
            updateSlider(input)
        end
    end)
    
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    return sliderContainer, function() return value end
end

-- 4. Dropdown
function AstroUI:CreateDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local items = options.Items or {"Option 1", "Option 2", "Option 3"}
    local default = options.Default or items[1]
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local selected = default
    local isOpen = false
    
    if flag then
        self.Flags[flag] = selected
    end
    
    local dropdownContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        ClipsDescendants = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(dropdownContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = dropdownContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 0, 45),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local dropdownButton = Utils:Create("TextButton", {
        Name = "DropdownButton",
        Parent = dropdownContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 10, 1, 5),
        Size = UDim2.new(1, -20, 0, 35),
        Font = Enum.Font.Gotham,
        Text = selected,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(dropdownButton, 6)
    
    local arrow = Utils:Create("TextLabel", {
        Name = "Arrow",
        Parent = dropdownButton,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = self.Theme.SubText,
        TextSize = 10
    })
    
    local itemsList = Utils:Create("Frame", {
        Name = "ItemsList",
        Parent = dropdownButton,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 100,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(itemsList, 6)
    Utils:AddStroke(itemsList, self.Theme.Border, 1)
    
    local itemsLayout = Utils:Create("UIListLayout", {
        Parent = itemsList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2)
    })
    
    Utils:Create("UIPadding", {
        Parent = itemsList,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    
    local function closeDropdown()
        isOpen = false
        Utils:Tween(itemsList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
            itemsList.Visible = false
        end)
        Utils:Tween(arrow, {Rotation = 0}, 0.2)
    end
    
    local function openDropdown()
        isOpen = true
        itemsList.Visible = true
        local targetHeight = math.min(#items * 32 + 10, 200)
        Utils:Tween(itemsList, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3, Enum.EasingStyle.Quad)
        Utils:Tween(arrow, {Rotation = 180}, 0.2)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        if isOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)
    
    for _, item in ipairs(items) do
        local itemButton = Utils:Create("TextButton", {
            Name = item,
            Parent = itemsList,
            BackgroundColor3 = self.Theme.SecondaryBackground,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.Gotham,
            Text = item,
            TextColor3 = self.Theme.Text,
            TextSize = 12,
            AutoButtonColor = false,
            BackgroundTransparency = self.Transparency
        })
        
        Utils:AddCorner(itemButton, 4)
        
        itemButton.MouseEnter:Connect(function()
            Utils:Tween(itemButton, {BackgroundColor3 = self.Theme.Primary}, 0.2)
        end)
        
        itemButton.MouseLeave:Connect(function()
            Utils:Tween(itemButton, {BackgroundColor3 = self.Theme.SecondaryBackground}, 0.2)
        end)
        
        itemButton.MouseButton1Click:Connect(function()
            selected = item
            dropdownButton.Text = item
            
            if flag then
                self.Flags[flag] = selected
            end
            
            Utils:PlaySound(SOUNDS.Click, 0.3)
            closeDropdown()
            callback(item)
        end)
    end
    
    return dropdownContainer, function() return selected end
end

-- 5. TextBox
function AstroUI:CreateTextBox(options)
    options = options or {}
    local name = options.Name or "TextBox"
    local default = options.Default or ""
    local placeholder = options.Placeholder or "Enter text..."
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    if flag then
        self.Flags[flag] = default
    end
    
    local textboxContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(textboxContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = textboxContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local textbox = Utils:Create("TextBox", {
        Name = "TextBox",
        Parent = textboxContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 10, 0, 35),
        Size = UDim2.new(1, -20, 0, 30),
        Font = Enum.Font.Gotham,
        PlaceholderText = placeholder,
        Text = default,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(textbox, 6)
    
    Utils:Create("UIPadding", {
        Parent = textbox,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
    
    textbox.FocusLost:Connect(function(enterPressed)
        if flag then
            self.Flags[flag] = textbox.Text
        end
        
        if enterPressed then
            Utils:PlaySound(SOUNDS.Click, 0.3)
            callback(textbox.Text)
        end
    end)
    
    return textboxContainer, function() return textbox.Text end
end

-- 6. Keybind
function AstroUI:CreateKeybind(options)
    options = options or {}
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.E
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local keybind = default
    local listening = false
    
    if flag then
        self.Flags[flag] = keybind
    end
    
    local keybindContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(keybindContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = keybindContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -120, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local keybindButton = Utils:Create("TextButton", {
        Name = "KeybindButton",
        Parent = keybindContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(1, -105, 0.5, 0),
        Size = UDim2.new(0, 95, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.Gotham,
        Text = keybind.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        AutoButtonColor = false,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(keybindButton, 6)
    
    keybindButton.MouseButton1Click:Connect(function()
        listening = true
        keybindButton.Text = "..."
        Utils:PlaySound(SOUNDS.Click, 0.3)
        Utils:Tween(keybindButton, {BackgroundColor3 = self.Theme.Primary}, 0.2)
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            keybind = input.KeyCode
            keybindButton.Text = keybind.Name
            listening = false
            
            if flag then
                self.Flags[flag] = keybind
            end
            
            Utils:PlaySound(SOUNDS.Click, 0.3)
            Utils:Tween(keybindButton, {BackgroundColor3 = self.Theme.TertiaryBackground}, 0.2)
        elseif not gameProcessed and input.KeyCode == keybind then
            callback()
        end
    end)
    
    return keybindContainer, function() return keybind end
end

-- 7. ColorPicker
function AstroUI:CreateColorPicker(options)
    options = options or {}
    local name = options.Name or "Color Picker"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local callback = options.Callback or function() end
    local flag = options.Flag
    
    local color = default
    
    if flag then
        self.Flags[flag] = color
    end
    
    local colorContainer = Utils:Create("Frame", {
        Name = name .. "Container",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(colorContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = colorContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local colorDisplay = Utils:Create("Frame", {
        Name = "ColorDisplay",
        Parent = colorContainer,
        BackgroundColor3 = color,
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 30),
        AnchorPoint = Vector2.new(0, 0.5),
        BorderSizePixel = 0
    })
    
    Utils:AddCorner(colorDisplay, 6)
    Utils:AddStroke(colorDisplay, self.Theme.Border, 2)
    
    local colorButton = Utils:Create("TextButton", {
        Parent = colorDisplay,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    -- Simplified color picker (cycles through preset colors)
    local presetColors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 128, 0),
        Color3.fromRGB(128, 0, 255),
        Color3.fromRGB(255, 255, 255)
    }
    
    local currentColorIndex = 1
    
    colorButton.MouseButton1Click:Connect(function()
        Utils:PlaySound(SOUNDS.Click, 0.3)
        currentColorIndex = (currentColorIndex % #presetColors) + 1
        color = presetColors[currentColorIndex]
        
        Utils:Tween(colorDisplay, {BackgroundColor3 = color}, 0.2)
        
        if flag then
            self.Flags[flag] = color
        end
        
        callback(color)
    end)
    
    return colorContainer, function() return color end
end

-- 8. Label
function AstroUI:CreateLabel(options)
    options = options or {}
    local text = options.Text or "Label"
    
    local labelContainer = Utils:Create("Frame", {
        Name = "LabelContainer",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(labelContainer, 8)
    
    local label = Utils:Create("TextLabel", {
        Name = "Label",
        Parent = labelContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    
    return labelContainer, function(newText)
        label.Text = newText
    end
end

-- 9. Paragraph
function AstroUI:CreateParagraph(options)
    options = options or {}
    local title = options.Title or "Paragraph"
    local content = options.Content or "This is a paragraph of text."
    
    local paragraphContainer = Utils:Create("Frame", {
        Name = "ParagraphContainer",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 80),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(paragraphContainer, 8)
    
    local titleLabel = Utils:Create("TextLabel", {
        Name = "Title",
        Parent = paragraphContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local contentLabel = Utils:Create("TextLabel", {
        Name = "Content",
        Parent = paragraphContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 35),
        Size = UDim2.new(1, -30, 0, 35),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    return paragraphContainer
end

-- 10. Divider
function AstroUI:CreateDivider(options)
    options = options or {}
    local text = options.Text
    
    local dividerContainer = Utils:Create("Frame", {
        Name = "DividerContainer",
        Parent = self.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20)
    })
    
    if text then
        local leftLine = Utils:Create("Frame", {
            Name = "LeftLine",
            Parent = dividerContainer,
            BackgroundColor3 = self.Theme.Border,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0.4, -10, 0, 1),
            BorderSizePixel = 0
        })
        
        local label = Utils:Create("TextLabel", {
            Name = "Label",
            Parent = dividerContainer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.2, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = self.Theme.SubText,
            TextSize = 11
        })
        
        local rightLine = Utils:Create("Frame", {
            Name = "RightLine",
            Parent = dividerContainer,
            BackgroundColor3 = self.Theme.Border,
            Position = UDim2.new(0.6, 10, 0.5, 0),
            Size = UDim2.new(0.4, -10, 0, 1),
            BorderSizePixel = 0
        })
    else
        local line = Utils:Create("Frame", {
            Name = "Line",
            Parent = dividerContainer,
            BackgroundColor3 = self.Theme.Border,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0
        })
    end
    
    return dividerContainer
end

-- 11. Section
function AstroUI:CreateSection(name)
    local section = {
        Name = name,
        Content = nil,
        Elements = {}
    }
    
    local sectionContainer = Utils:Create("Frame", {
        Name = name .. "Section",
        Parent = self.Content,
        BackgroundColor3 = self.Theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 500),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(sectionContainer, 8)
    
    local sectionHeader = Utils:Create("Frame", {
        Name = "Header",
        Parent = sectionContainer,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Size = UDim2.new(1, 0, 0, 35),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    Utils:AddCorner(sectionHeader, 8)
    
    local headerBottom = Utils:Create("Frame", {
        Parent = sectionHeader,
        BackgroundColor3 = self.Theme.TertiaryBackground,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        BorderSizePixel = 0,
        BackgroundTransparency = self.Transparency
    })
    
    local sectionTitle = Utils:Create("TextLabel", {
        Name = "Title",
        Parent = sectionHeader,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local sectionContent = Utils:Create("Frame", {
        Name = "Content",
        Parent = sectionContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 0, 465),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    local contentLayout = Utils:Create("UIListLayout", {
        Parent = sectionContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    Utils:Create("UIPadding", {
        Parent = sectionContent,
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })
    
    section.Content = sectionContent
    
    return setmetatable(section, {__index = self})
end

-- Notification Methods
function AstroUI:Notify(options)
    return NotificationManager:Create(options)
end

-- Config Methods
function AstroUI:SaveConfig(name)
    name = name or "default"
    local data = {
        Flags = self.Flags,
        Theme = self.Theme,
        Transparency = self.Transparency
    }
    return self.ConfigManager:Save(name, data)
end

function AstroUI:LoadConfig(name)
    name = name or "default"
    local data = self.ConfigManager:Load(name)
    
    if data then
        if data.Flags then
            for flag, value in pairs(data.Flags) do
                self.Flags[flag] = value
            end
        end
        
        if data.Theme then
            self.Theme = data.Theme
        end
        
        if data.Transparency then
            self:SetTransparency(data.Transparency)
        end
        
        return true
    end
    
    return false
end

function AstroUI:LoadSettings()
    local data = self.ConfigManager:Load("settings")
    
    if data then
        if data.Theme then
            self.Theme = data.Theme
        end
        
        if data.Transparency then
            self:SetTransparency(data.Transparency)
        end
    end
end

function AstroUI:SaveSettings()
    local data = {
        Theme = self.Theme,
        Transparency = self.Transparency
    }
    return self.ConfigManager:Save("settings", data)
end

-- Destroy
function AstroUI:Destroy()
    Utils:Tween(self.MainFrame, {
        Size = UDim2.new(0, 0, 0, 0)
    }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
        self.ScreenGui:Destroy()
    end)
    
    Utils:PlaySound(SOUNDS.Click, 0.3)
end

-- Return Library
return AstroUI
