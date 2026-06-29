--[[
    Advanced Script Hub UI Library
    Version: 2.0
    Features: Tabs, Buttons, Toggles, Sliders, Dropdowns, TextInputs,
              KeyBinds, ColorPickers, Notifications, Config System,
              Sound Effects, Advanced Animations
]]

local Library = {}
Library.__index = Library

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Configuration
local LIBRARY_NAME = "ScriptHub"
local CONFIG_FOLDER = LIBRARY_NAME .. "/Configs"

-- Theme
local Theme = {
    Primary = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(30, 30, 45),
    Tertiary = Color3.fromRGB(35, 35, 55),
    Accent = Color3.fromRGB(100, 120, 255),
    AccentDark = Color3.fromRGB(70, 90, 200),
    Text = Color3.fromRGB(230, 230, 240),
    TextDark = Color3.fromRGB(150, 150, 170),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(255, 200, 80),
    Error = Color3.fromRGB(255, 80, 80),
    Border = Color3.fromRGB(50, 50, 70),
    Shadow = Color3.fromRGB(10, 10, 15),
    Transparent = Color3.fromRGB(0, 0, 0),
    TabInactive = Color3.fromRGB(40, 40, 60),
    TabActive = Color3.fromRGB(100, 120, 255),
    ToggleOff = Color3.fromRGB(60, 60, 80),
    ToggleOn = Color3.fromRGB(100, 120, 255),
    SliderBar = Color3.fromRGB(50, 50, 70),
    SliderFill = Color3.fromRGB(100, 120, 255),
    InputBG = Color3.fromRGB(20, 20, 30),
    NotifBG = Color3.fromRGB(30, 30, 48),
}

-- Sound IDs
local Sounds = {
    Click = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895079853",
    Notify = "rbxassetid://6026984224",
    Open = "rbxassetid://6895079853",
    Close = "rbxassetid://6895079853",
    Slider = "rbxassetid://6895079853",
    Error = "rbxassetid://6026984224",
    Success = "rbxassetid://6026984224",
}

-- Utility Functions
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            if typeof(v) == "Instance" then
                v.Parent = inst
            else
                inst[k] = v
            end
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Tween(obj, duration, props, style, direction)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    tw:Play()
    return tw
end

local function PlaySound(soundId, volume)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = volume or 0.3
        sound.PlayOnRemove = false
        sound.Parent = CoreGui
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
end

local function AddCorner(parent, radius)
    return Create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent
    })
end

local function AddPadding(parent, t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft = UDim.new(0, l or 8),
        PaddingRight = UDim.new(0, r or 8),
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
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 24, 1, 24),
        ZIndex = parent.ZIndex - 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = parent
    })
    return shadow
end

local function Ripple(button)
    local ripple = Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0, Mouse.X - button.AbsolutePosition.X, 0, Mouse.Y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = button.ZIndex + 5,
        Parent = button
    })
    AddCorner(ripple, 999)
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    local tw = Tween(ripple, 0.5, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    tw.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- Config System
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new()
    local self = setmetatable({}, ConfigSystem)
    self.Flags = {}
    self.ConfigData = {}
    return self
end

function ConfigSystem:SetFlag(flag, value)
    self.Flags[flag] = value
end

function ConfigSystem:GetFlag(flag)
    return self.Flags[flag]
end

function ConfigSystem:SaveConfig(name)
    local data = {}
    for flag, value in pairs(self.Flags) do
        local t = typeof(value)
        if t == "boolean" or t == "number" or t == "string" then
            data[flag] = {Type = t, Value = value}
        elseif t == "Color3" then
            data[flag] = {Type = "Color3", Value = {value.R, value.G, value.B}}
        elseif t == "EnumItem" then
            data[flag] = {Type = "EnumItem", Value = tostring(value)}
        end
    end
    
    local json = HttpService:JSONEncode(data)
    
    if writefile then
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        makefolder(LIBRARY_NAME)
        makefolder(CONFIG_FOLDER)
        writefile(path, json)
        return true
    end
    return false
end

function ConfigSystem:LoadConfig(name)
    if readfile then
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if isfile(path) then
            local json = readfile(path)
            local data = HttpService:JSONDecode(json)
            for flag, info in pairs(data) do
                if info.Type == "Color3" then
                    self.Flags[flag] = Color3.new(info.Value[1], info.Value[2], info.Value[3])
                elseif info.Type == "EnumItem" then
                    -- Parse enum
                    local enumStr = info.Value
                    local parts = string.split(enumStr, ".")
                    if #parts == 3 then
                        pcall(function()
                            self.Flags[flag] = Enum[parts[2]][parts[3]]
                        end)
                    end
                else
                    self.Flags[flag] = info.Value
                end
            end
            return true
        end
    end
    return false
end

function ConfigSystem:DeleteConfig(name)
    if delfile then
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path)
            return true
        end
    end
    return false
end

function ConfigSystem:GetConfigs()
    local configs = {}
    if listfiles then
        pcall(function()
            makefolder(LIBRARY_NAME)
            makefolder(CONFIG_FOLDER)
            for _, file in ipairs(listfiles(CONFIG_FOLDER)) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(configs, name)
                end
            end
        end)
    end
    return configs
end

-- Main Library
function Library.new(title, subtitle)
    local self = setmetatable({}, Library)
    self.Title = title or "Script Hub"
    self.Subtitle = subtitle or "v2.0"
    self.Tabs = {}
    self.ActiveTab = nil
    self.Toggled = true
    self.ToggleKey = Enum.KeyCode.RightControl
    self.Config = ConfigSystem.new()
    self.Notifications = {}
    self.SoundEnabled = true
    self.AnimationsEnabled = true
    self.DragEnabled = true
    
    self:Build()
    return self
end

function Library:PlaySound(id, vol)
    if self.SoundEnabled then
        PlaySound(id, vol)
    end
end

function Library:Build()
    -- Destroy existing
    pcall(function()
        CoreGui:FindFirstChild(LIBRARY_NAME .. "_UI"):Destroy()
    end)
    
    -- ScreenGui
    self.ScreenGui = Create("ScreenGui", {
        Name = LIBRARY_NAME .. "_UI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = CoreGui
    })
    
    -- Main Frame
    self.MainFrame = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true,
        Parent = self.ScreenGui
    })
    AddCorner(self.MainFrame, 12)
    AddStroke(self.MainFrame, Theme.Border, 1.5, 0.3)
    AddShadow(self.MainFrame)
    
    -- Open Animation
    PlaySound(Sounds.Open, 0.5)
    Tween(self.MainFrame, 0.6, {Size = UDim2.new(0, 680, 0, 480)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Title Bar
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 50),
        Parent = self.MainFrame
    })
    AddCorner(self.TitleBar, 12)
    -- Fix bottom corners
    Create("Frame", {
        Name = "BottomFix",
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
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
    AddGradient(accentLine, Theme.Accent, Theme.AccentDark, 0)
    task.delay(0.3, function()
        Tween(accentLine, 0.8, {Size = UDim2.new(1, 0, 0, 2)})
    end)
    
    -- Title Text
    self.TitleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- Subtitle
    self.SubtitleLabel = Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16 + self.TitleLabel.TextBounds.X + 8, 0, 0),
        Size = UDim2.new(0.3, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = self.Subtitle,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- Close Button
    local closeBtn = Create("TextButton", {
        Name = "Close",
        BackgroundColor3 = Theme.Error,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -42, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.Error,
        TextSize = 20,
        Parent = self.TitleBar
    })
    AddCorner(closeBtn, 6)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.2, {BackgroundTransparency = 0.3})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.2, {BackgroundTransparency = 0.8})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:PlaySound(Sounds.Close, 0.4)
        self:Toggle()
    end)
    
    -- Minimize Button
    local minBtn = Create("TextButton", {
        Name = "Minimize",
        BackgroundColor3 = Theme.Warning,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -72, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = Theme.Warning,
        TextSize = 14,
        Parent = self.TitleBar
    })
    AddCorner(minBtn, 6)
    
    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, 0.2, {BackgroundTransparency = 0.3})
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, 0.2, {BackgroundTransparency = 0.8})
    end)
    minBtn.MouseButton1Click:Connect(function()
        self:PlaySound(Sounds.Click, 0.3)
        self:Toggle()
    end)
    
    -- Tab Sidebar
    self.TabSidebar = Create("ScrollingFrame", {
        Name = "TabSidebar",
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(0, 160, 1, -52),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    AddPadding(self.TabSidebar, 8, 8, 8, 8)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.TabSidebar
    })
    -- Bottom corners fix
    AddCorner(self.TabSidebar, 12)
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 12),
        BorderSizePixel = 0,
        Parent = self.TabSidebar
    })
    Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(1, -12, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        BorderSizePixel = 0,
        Parent = self.TabSidebar
    })
    
    -- Sidebar Divider
    Create("Frame", {
        Name = "Divider",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 160, 0, 52),
        Size = UDim2.new(0, 1, 1, -52),
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })
    
    -- Content Area
    self.ContentArea = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 162, 0, 52),
        Size = UDim2.new(1, -162, 1, -52),
        ClipsDescendants = true,
        Parent = self.MainFrame
    })
    
    -- Notification Container
    self.NotifContainer = Create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 320, 1, -32),
        Parent = self.ScreenGui
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = self.NotifContainer
    })
    
    -- Dragging
    self:SetupDrag()
    
    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)
    
    -- Welcome Notification
    task.delay(1, function()
        self:Notify("Welcome", "Press " .. tostring(self.ToggleKey) .. " to toggle UI", "info", 5)
    end)
end

function Library:SetupDrag()
    local dragging, dragInput, dragStart, startPos
    
    self.TitleBar.InputBegan:Connect(function(input)
        if not self.DragEnabled then return end
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
            Tween(self.MainFrame, 0.08, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }, Enum.EasingStyle.Linear)
        end
    end)
end

function Library:Toggle()
    self.Toggled = not self.Toggled
    if self.Toggled then
        self:PlaySound(Sounds.Open, 0.4)
        self.MainFrame.Visible = true
        Tween(self.MainFrame, 0.5, {
            Size = UDim2.new(0, 680, 0, 480)
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        self.MainFrame.BackgroundTransparency = 0
    else
        self:PlaySound(Sounds.Close, 0.4)
        local tw = Tween(self.MainFrame, 0.4, {
            Size = UDim2.new(0, 680, 0, 0)
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw.Completed:Connect(function()
            if not self.Toggled then
                self.MainFrame.Visible = false
            end
        end)
    end
end

function Library:Destroy()
    self:PlaySound(Sounds.Close, 0.4)
    local tw = Tween(self.MainFrame, 0.4, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tw.Completed:Connect(function()
        self.ScreenGui:Destroy()
    end)
end

-- Notification System
function Library:Notify(title, message, ntype, duration)
    ntype = ntype or "info"
    duration = duration or 4
    
    self:PlaySound(Sounds.Notify, 0.4)
    
    local color = Theme.Accent
    local icon = "ℹ"
    if ntype == "success" then color = Theme.Success; icon = "✓"
    elseif ntype == "warning" then color = Theme.Warning; icon = "⚠"
    elseif ntype == "error" then color = Theme.Error; icon = "✕" end
    
    local notifFrame = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.NotifBG,
        Size = UDim2.new(0, 320, 0, 0),
        ClipsDescendants = true,
        Parent = self.NotifContainer
    })
    AddCorner(notifFrame, 10)
    AddStroke(notifFrame, color, 1, 0.6)
    AddShadow(notifFrame)
    
    -- Accent bar
    Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        Parent = notifFrame
    })
    
    -- Icon
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = color,
        TextSize = 18,
        Parent = notifFrame
    })
    
    -- Title
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 8),
        Size = UDim2.new(1, -56, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notifFrame
    })
    
    -- Message
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 28),
        Size = UDim2.new(1, -56, 0, 30),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notifFrame
    })
    
    -- Progress bar
    local progressBar = Create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        Parent = notifFrame
    })
    
    -- Animate in
    Tween(notifFrame, 0.4, {Size = UDim2.new(0, 320, 0, 65)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Progress
    Tween(progressBar, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
    
    -- Animate out
    task.delay(duration, function()
        local tw = Tween(notifFrame, 0.4, {
            Size = UDim2.new(0, 320, 0, 0),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw.Completed:Connect(function()
            notifFrame:Destroy()
        end)
    end)
end

-- Tab System
function Library:AddTab(name, icon)
    icon = icon or "📋"
    
    local tab = {
        Name = name,
        Elements = {},
        Library = self
    }
    
    -- Tab Button
    tab.Button = Create("TextButton", {
        Name = name,
        BackgroundColor3 = Theme.TabInactive,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #self.Tabs,
        Parent = self.TabSidebar
    })
    AddCorner(tab.Button, 8)
    
    -- Tab Icon
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Font = Enum.Font.Gotham,
        Text = icon,
        TextColor3 = Theme.TextDark,
        TextSize = 16,
        Parent = tab.Button
    })
    
    -- Tab Label
    tab.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Button
    })
    
    -- Active Indicator
    tab.Indicator = Create("Frame", {
        Name = "Indicator",
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0, 0, 0.15, 0),
        Size = UDim2.new(0, 0, 0.7, 0),
        BorderSizePixel = 0,
        Parent = tab.Button
    })
    AddCorner(tab.Indicator, 2)
    
    -- Tab Content
    tab.Content = Create("ScrollingFrame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        BorderSizePixel = 0,
        Parent = self.ContentArea
    })
    AddPadding(tab.Content, 10, 10, 12, 12)
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = tab.Content
    })
    
    -- Tab Button Events
    tab.Button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tab.Button, 0.2, {BackgroundTransparency = 0.3})
        end
        self:PlaySound(Sounds.Hover, 0.15)
    end)
    
    tab.Button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tab.Button, 0.2, {BackgroundTransparency = 0.5})
        end
    end)
    
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
        self:PlaySound(Sounds.Click, 0.3)
    end)
    
    table.insert(self.Tabs, tab)
    
    -- Auto-select first tab
    if #self.Tabs == 1 then
        task.defer(function()
            self:SelectTab(tab)
        end)
    end
    
    -- Add element methods to tab
    setmetatable(tab, {__index = Library})
    
    return tab
end

function Library:SelectTab(tab)
    -- Deactivate current
    if self.ActiveTab then
        local old = self.ActiveTab
        old.Content.Visible = false
        Tween(old.Button, 0.3, {BackgroundColor3 = Theme.TabInactive, BackgroundTransparency = 0.5})
        Tween(old.Label, 0.3, {TextColor3 = Theme.TextDark})
        Tween(old.Indicator, 0.3, {Size = UDim2.new(0, 0, 0.7, 0)})
    end
    
    -- Activate new
    self.ActiveTab = tab
    tab.Content.Visible = true
    Tween(tab.Button, 0.3, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85})
    Tween(tab.Label, 0.3, {TextColor3 = Theme.Text})
    Tween(tab.Indicator, 0.3, {Size = UDim2.new(0, 3, 0.7, 0)})
    
    -- Animate content children in
    for i, child in ipairs(tab.Content:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundTransparency = 1
            task.delay(i * 0.03, function()
                Tween(child, 0.3, {BackgroundTransparency = 0})
            end)
        end
    end
end

-- Section
function Library.AddSection(tab, title)
    local section = Create("Frame", {
        Name = "Section_" .. title,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -4, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = string.upper(title),
        TextColor3 = Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    local line = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = section
    })
    AddGradient(line, Theme.Accent, Theme.Transparent, 0)
    
    return section
end

-- 1. Button
function Library.AddButton(tab, options)
    options = options or {}
    local name = options.Name or "Button"
    local callback = options.Callback or function() end
    local description = options.Description or nil
    
    local height = description and 52 or 38
    
    local container = Create("Frame", {
        Name = "Button_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    local btn = Create("TextButton", {
        Name = "Btn",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = "",
        AutoButtonColor = false,
        Parent = container
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, description and 6 or 0),
        Size = UDim2.new(1, -28, 0, description and 22 or height),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    if description then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 26),
            Size = UDim2.new(1, -28, 0, 18),
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = Theme.TextDark,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end
    
    -- Arrow icon on right
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -34, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "→",
        TextColor3 = Theme.TextDark,
        TextSize = 16,
        Parent = container
    })
    
    btn.MouseEnter:Connect(function()
        Tween(container, 0.2, {BackgroundColor3 = Theme.Accent})
        tab.Library:PlaySound(Sounds.Hover, 0.15)
    end)
    
    btn.MouseLeave:Connect(function()
        Tween(container, 0.2, {BackgroundColor3 = Theme.Tertiary})
    end)
    
    btn.MouseButton1Click:Connect(function()
        tab.Library:PlaySound(Sounds.Click, 0.3)
        Ripple(btn)
        
        -- Press animation
        Tween(container, 0.1, {Size = UDim2.new(1, -4, 0, height - 2)})
        task.delay(0.1, function()
            Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, height)})
        end)
        
        pcall(callback)
    end)
    
    return {
        SetText = function(_, text)
            container:FindFirstChild("TextLabel", true).Text = text
        end
    }
end

-- 2. Toggle
function Library.AddToggle(tab, options)
    options = options or {}
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local description = options.Description or nil
    
    local height = description and 52 or 38
    local state = default
    
    tab.Library.Config:SetFlag(flag, state)
    
    local container = Create("Frame", {
        Name = "Toggle_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, description and 6 or 0),
        Size = UDim2.new(1, -70, 0, description and 22 or height),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    if description then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 26),
            Size = UDim2.new(1, -70, 0, 18),
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = Theme.TextDark,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end
    
    -- Toggle Switch
    local toggleBG = Create("Frame", {
        Name = "ToggleBG",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 44, 0, 24),
        Parent = container
    })
    AddCorner(toggleBG, 12)
    
    local toggleCircle = Create("Frame", {
        Name = "Circle",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        Parent = toggleBG
    })
    AddCorner(toggleCircle, 9)
    
    local btn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        Parent = container
    })
    
    local function updateToggle(val, skipCallback)
        state = val
        tab.Library.Config:SetFlag(flag, state)
        
        Tween(toggleBG, 0.3, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
        Tween(toggleCircle, 0.3, {
            Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        }, Enum.EasingStyle.Back)
        
        -- Glow effect
        if state then
            local glow = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.5,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 10, 1, 10),
                Parent = toggleBG
            })
            AddCorner(glow, 16)
            Tween(glow, 0.5, {BackgroundTransparency = 1, Size = UDim2.new(1, 20, 1, 20)}).Completed:Connect(function()
                glow:Destroy()
            end)
        end
        
        if not skipCallback then
            pcall(callback, state)
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        tab.Library:PlaySound(Sounds.Toggle, 0.3)
        updateToggle(not state)
    end)
    
    btn.MouseEnter:Connect(function()
        Tween(container, 0.2, {BackgroundColor3 = Color3.fromRGB(
            Theme.Tertiary.R * 255 + 10,
            Theme.Tertiary.G * 255 + 10,
            Theme.Tertiary.B * 255 + 10
        ):lerp(Theme.Tertiary, 0)})
    end)
    btn.MouseLeave:Connect(function()
        Tween(container, 0.2, {BackgroundColor3 = Theme.Tertiary})
    end)
    
    return {
        Set = function(_, val)
            updateToggle(val)
        end,
        Get = function()
            return state
        end,
        SetText = function(_, text)
            container:FindFirstChild("TextLabel", true).Text = text
        end
    }
end

-- 3. Slider
function Library.AddSlider(tab, options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local increment = options.Increment or 1
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local suffix = options.Suffix or ""
    
    local value = default
    tab.Library.Config:SetFlag(flag, value)
    
    local container = Create("Frame", {
        Name = "Slider_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 56),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(0.6, 0, 0, 20),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local valueLabel = Create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 6),
        Size = UDim2.new(0.4, -14, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = tostring(value) .. suffix,
        TextColor3 = Theme.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    -- Slider Track
    local sliderTrack = Create("Frame", {
        Name = "Track",
        BackgroundColor3 = Theme.SliderBar,
        Position = UDim2.new(0, 14, 0, 34),
        Size = UDim2.new(1, -28, 0, 8),
        Parent = container
    })
    AddCorner(sliderTrack, 4)
    
    -- Slider Fill
    local initialFill = (default - min) / (max - min)
    local sliderFill = Create("Frame", {
        Name = "Fill",
        BackgroundColor3 = Theme.SliderFill,
        Size = UDim2.new(initialFill, 0, 1, 0),
        Parent = sliderTrack
    })
    AddCorner(sliderFill, 4)
    AddGradient(sliderFill, Theme.Accent, Theme.AccentDark, 0)
    
    -- Slider Knob
    local knob = Create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(initialFill, 0, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        ZIndex = 5,
        Parent = sliderTrack
    })
    AddCorner(knob, 8)
    AddStroke(knob, Theme.Accent, 2, 0)
    
    local dragging = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * pos
        value = math.floor(rawValue / increment + 0.5) * increment
        value = math.clamp(value, min, max)
        
        local fillPercent = (value - min) / (max - min)
        
        Tween(sliderFill, 0.1, {Size = UDim2.new(fillPercent, 0, 1, 0)}, Enum.EasingStyle.Linear)
        Tween(knob, 0.1, {Position = UDim2.new(fillPercent, 0, 0.5, 0)}, Enum.EasingStyle.Linear)
        valueLabel.Text = tostring(value) .. suffix
        
        tab.Library.Config:SetFlag(flag, value)
        pcall(callback, value)
    end
    
    local sliderBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 30),
        Text = "",
        Parent = container
    })
    
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
        tab.Library:PlaySound(Sounds.Slider, 0.15)
        Tween(knob, 0.2, {Size = UDim2.new(0, 20, 0, 20)})
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            Tween(knob, 0.2, {Size = UDim2.new(0, 16, 0, 16)})
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    sliderBtn.MouseButton1Down:Connect(function(x, y)
        -- Immediate update on click
    end)
    
    -- Also handle click to position
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)
    
    return {
        Set = function(_, val)
            value = math.clamp(val, min, max)
            local fillPercent = (value - min) / (max - min)
            Tween(sliderFill, 0.3, {Size = UDim2.new(fillPercent, 0, 1, 0)})
            Tween(knob, 0.3, {Position = UDim2.new(fillPercent, 0, 0.5, 0)})
            valueLabel.Text = tostring(value) .. suffix
            tab.Library.Config:SetFlag(flag, value)
            pcall(callback, value)
        end,
        Get = function()
            return value
        end
    }
end

-- 4. Dropdown
function Library.AddDropdown(tab, options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local items = options.Items or {}
    local default = options.Default or nil
    local multi = options.Multi or false
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    
    local selected = multi and {} or default
    local opened = false
    
    if multi and default then
        if typeof(default) == "table" then
            selected = default
        end
    end
    
    tab.Library.Config:SetFlag(flag, selected)
    
    local container = Create("Frame", {
        Name = "Dropdown_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = true,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 0, 42),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local function getDisplayText()
        if multi then
            local sel = {}
            for k, v in pairs(selected) do
                if v then table.insert(sel, k) end
            end
            return #sel > 0 and table.concat(sel, ", ") or "None"
        else
            return selected or "Select..."
        end
    end
    
    local selectedLabel = Create("TextLabel", {
        Name = "Selected",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.4, 0, 0, 0),
        Size = UDim2.new(0.6, -40, 0, 42),
        Font = Enum.Font.Gotham,
        Text = getDisplayText(),
        TextColor3 = Theme.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = container
    })
    
    -- Arrow
    local arrow = Create("TextLabel", {
        Name = "Arrow",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 20, 0, 42),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        Rotation = 0,
        Parent = container
    })
    
    -- Items Container
    local itemsContainer = Create("Frame", {
        Name = "Items",
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0, 8, 0, 46),
        Size = UDim2.new(1, -16, 0, 0),
        ClipsDescendants = true,
        Parent = container
    })
    AddCorner(itemsContainer, 6)
    
    local itemsList = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = itemsContainer
    })
    AddPadding(itemsContainer, 4, 4, 4, 4)
    
    local itemButtons = {}
    
    local function createItemButton(item)
        local isSelected = false
        if multi then
            isSelected = selected[item] or false
        else
            isSelected = selected == item
        end
        
        local itemBtn = Create("TextButton", {
            Name = item,
            BackgroundColor3 = isSelected and Theme.Accent or Theme.Tertiary,
            BackgroundTransparency = isSelected and 0.7 or 0,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            Text = item,
            TextColor3 = isSelected and Theme.Accent or Theme.Text,
            TextSize = 12,
            AutoButtonColor = false,
            Parent = itemsContainer
        })
        AddCorner(itemBtn, 6)
        
        itemBtn.MouseEnter:Connect(function()
            Tween(itemBtn, 0.15, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7})
        end)
        itemBtn.MouseLeave:Connect(function()
            local isSel = multi and (selected[item] or false) or (selected == item)
            Tween(itemBtn, 0.15, {
                BackgroundColor3 = isSel and Theme.Accent or Theme.Tertiary,
                BackgroundTransparency = isSel and 0.7 or 0
            })
        end)
        
        itemBtn.MouseButton1Click:Connect(function()
            tab.Library:PlaySound(Sounds.Click, 0.25)
            
            if multi then
                selected[item] = not (selected[item] or false)
                local isSel = selected[item]
                Tween(itemBtn, 0.2, {
                    BackgroundColor3 = isSel and Theme.Accent or Theme.Tertiary,
                    BackgroundTransparency = isSel and 0.7 or 0
                })
                itemBtn.TextColor3 = isSel and Theme.Accent or Theme.Text
            else
                selected = item
                for _, btn in pairs(itemButtons) do
                    Tween(btn, 0.2, {BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0})
                    btn.TextColor3 = Theme.Text
                end
                Tween(itemBtn, 0.2, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7})
                itemBtn.TextColor3 = Theme.Accent
                
                -- Close dropdown after single select
                task.delay(0.15, function()
                    opened = false
                    local totalHeight = 42
                    Tween(container, 0.3, {Size = UDim2.new(1, 0, 0, totalHeight)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    Tween(arrow, 0.3, {Rotation = 0})
                end)
            end
            
            selectedLabel.Text = getDisplayText()
            tab.Library.Config:SetFlag(flag, selected)
            pcall(callback, selected)
        end)
        
        table.insert(itemButtons, itemBtn)
    end
    
    for _, item in ipairs(items) do
        createItemButton(item)
    end
    
    -- Toggle dropdown
    local toggleBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Text = "",
        Parent = container
    })
    
    toggleBtn.MouseButton1Click:Connect(function()
        opened = not opened
        tab.Library:PlaySound(Sounds.Click, 0.25)
        
        if opened then
            local itemCount = #items
            local itemsHeight = itemCount * 32 + 10
            local totalHeight = 50 + itemsHeight
            Tween(container, 0.35, {Size = UDim2.new(1, 0, 0, totalHeight)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Tween(arrow, 0.3, {Rotation = 180})
        else
            Tween(container, 0.3, {Size = UDim2.new(1, 0, 0, 42)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Tween(arrow, 0.3, {Rotation = 0})
        end
    end)
    
    return {
        Set = function(_, val)
            selected = val
            selectedLabel.Text = getDisplayText()
            tab.Library.Config:SetFlag(flag, selected)
            pcall(callback, selected)
        end,
        Get = function()
            return selected
        end,
        Refresh = function(_, newItems)
            items = newItems
            for _, btn in pairs(itemButtons) do
                btn:Destroy()
            end
            itemButtons = {}
            for _, item in ipairs(items) do
                createItemButton(item)
            end
        end
    }
end

-- 5. TextInput
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
    tab.Library.Config:SetFlag(flag, value)
    
    local container = Create("Frame", {
        Name = "Input_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 42),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local inputBG = Create("Frame", {
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0.4, 4, 0, 6),
        Size = UDim2.new(0.6, -18, 0, 30),
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
        PlaceholderColor3 = Theme.TextDark,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBG
    })
    
    textBox.Focused:Connect(function()
        tab.Library:PlaySound(Sounds.Click, 0.2)
        Tween(inputStroke, 0.3, {Color = Theme.Accent, Transparency = 0})
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        Tween(inputStroke, 0.3, {Color = Theme.Border, Transparency = 0.5})
        
        local text = textBox.Text
        if numeric then
            text = tonumber(text) or value
            textBox.Text = tostring(text)
        end
        
        value = text
        tab.Library.Config:SetFlag(flag, value)
        pcall(callback, value)
        if enterPressed then
            pcall(finished, value)
        end
    end)
    
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        if numeric then
            textBox.Text = textBox.Text:gsub("[^%d%.%-]", "")
        end
    end)
    
    return {
        Set = function(_, val)
            value = val
            textBox.Text = tostring(val)
            tab.Library.Config:SetFlag(flag, val)
        end,
        Get = function()
            return value
        end
    }
end

-- 6. KeyBind
function Library.AddKeybind(tab, options)
    options = options or {}
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    local changedCallback = options.Changed or function() end
    
    local key = default
    local listening = false
    
    tab.Library.Config:SetFlag(flag, key)
    
    local container = Create("Frame", {
        Name = "Keybind_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local keyBtn = Create("TextButton", {
        Name = "KeyBtn",
        BackgroundColor3 = Theme.InputBG,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = key.Name or "None",
        TextColor3 = Theme.Accent,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = container
    })
    AddCorner(keyBtn, 6)
    AddStroke(keyBtn, Theme.Accent, 1, 0.5)
    
    keyBtn.MouseButton1Click:Connect(function()
        tab.Library:PlaySound(Sounds.Click, 0.25)
        listening = true
        keyBtn.Text = "..."
        Tween(keyBtn, 0.2, {BackgroundColor3 = Theme.Accent})
        keyBtn.TextColor3 = Theme.Primary
    end)
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    key = Enum.KeyCode.Unknown
                    keyBtn.Text = "None"
                else
                    key = input.KeyCode
                    keyBtn.Text = key.Name
                end
                listening = false
                Tween(keyBtn, 0.2, {BackgroundColor3 = Theme.InputBG})
                keyBtn.TextColor3 = Theme.Accent
                tab.Library.Config:SetFlag(flag, key)
                pcall(changedCallback, key)
            end
        elseif not processed and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
            pcall(callback)
        end
    end)
    
    return {
        Set = function(_, newKey)
            key = newKey
            keyBtn.Text = key.Name or "None"
            tab.Library.Config:SetFlag(flag, key)
        end,
        Get = function()
            return key
        end
    }
end

-- 7. ColorPicker
function Library.AddColorPicker(tab, options)
    options = options or {}
    local name = options.Name or "Color"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local flag = options.Flag or name
    local callback = options.Callback or function() end
    
    local color = default
    local opened = false
    local hue, sat, val = Color3.toHSV(default)
    
    tab.Library.Config:SetFlag(flag, color)
    
    local container = Create("Frame", {
        Name = "ColorPicker_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 42),
        ClipsDescendants = true,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.6, 0, 0, 42),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    -- Color Preview
    local preview = Create("Frame", {
        Name = "Preview",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = color,
        Position = UDim2.new(1, -14, 0, 21),
        Size = UDim2.new(0, 40, 0, 24),
        Parent = container
    })
    AddCorner(preview, 6)
    AddStroke(preview, Color3.fromRGB(255, 255, 255), 1, 0.7)
    
    local previewBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Text = "",
        Parent = container
    })
    
    -- Saturation/Value picker
    local svPicker = Create("ImageLabel", {
        Name = "SVPicker",
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        Position = UDim2.new(0, 14, 0, 50),
        Size = UDim2.new(1, -60, 0, 120),
        Image = "rbxassetid://4155801252",
        BorderSizePixel = 0,
        Parent = container
    })
    AddCorner(svPicker, 6)
    
    -- SV Cursor
    local svCursor = Create("Frame", {
        Name = "Cursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(sat, 0, 1 - val, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 5,
        Parent = svPicker
    })
    AddCorner(svCursor, 6)
    AddStroke(svCursor, Color3.fromRGB(0, 0, 0), 2, 0)
    
    -- Hue Slider
    local hueSlider = Create("Frame", {
        Name = "HueSlider",
        Position = UDim2.new(1, -38, 0, 50),
        Size = UDim2.new(0, 18, 0, 120),
        Parent = container
    })
    AddCorner(hueSlider, 4)
    
    -- Hue Gradient
    Create("UIGradient", {
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
        Parent = hueSlider
    })
    
    -- Hue Cursor
    local hueCursor = Create("Frame", {
        Name = "HueCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0.5, 0, hue, 0),
        Size = UDim2.new(1, 4, 0, 6),
        ZIndex = 5,
        Parent = hueSlider
    })
    AddCorner(hueCursor, 3)
    AddStroke(hueCursor, Color3.fromRGB(0, 0, 0), 1, 0)
    
    -- Hex Display
    local hexInput = Create("TextBox", {
        BackgroundColor3 = Theme.InputBG,
        Position = UDim2.new(0, 14, 0, 178),
        Size = UDim2.new(1, -28, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = "#" .. color:ToHex(),
        TextColor3 = Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = true,
        Parent = container
    })
    AddCorner(hexInput, 6)
    
    local function updateColor()
        color = Color3.fromHSV(hue, sat, val)
        preview.BackgroundColor3 = color
        svPicker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
        hueCursor.Position = UDim2.new(0.5, 0, hue, 0)
        hexInput.Text = "#" .. color:ToHex()
        tab.Library.Config:SetFlag(flag, color)
        pcall(callback, color)
    end
    
    -- SV Picking
    local svDragging = false
    svPicker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            sat = math.clamp((input.Position.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
            val = 1 - math.clamp((input.Position.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
            updateColor()
        end
    end)
    
    -- Hue Picking
    local hueDragging = false
    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            hue = math.clamp((input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y, 0, 1)
            updateColor()
        end
    end)
    
    -- Hex input
    hexInput.FocusLost:Connect(function()
        local hex = hexInput.Text:gsub("#", "")
        pcall(function()
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            if r and g and b then
                color = Color3.fromRGB(r, g, b)
                hue, sat, val = Color3.toHSV(color)
                updateColor()
            end
        end)
    end)
    
    -- Toggle
    previewBtn.MouseButton1Click:Connect(function()
        opened = not opened
        tab.Library:PlaySound(Sounds.Click, 0.25)
        
        if opened then
            Tween(container, 0.35, {Size = UDim2.new(1, 0, 0, 215)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween(container, 0.3, {Size = UDim2.new(1, 0, 0, 42)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end
    end)
    
    return {
        Set = function(_, c)
            color = c
            hue, sat, val = Color3.toHSV(c)
            updateColor()
        end,
        Get = function()
            return color
        end
    }
end

-- 8. Label / Info
function Library.AddLabel(tab, options)
    options = options or {}
    local text = options.Text or "Label"
    local description = options.Description or nil
    
    local height = description and 48 or 32
    
    local container = Create("Frame", {
        Name = "Label",
        BackgroundColor3 = Theme.Tertiary,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    
    -- Info icon
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, description and 4 or 0),
        Size = UDim2.new(0, 20, 0, description and 22 or height),
        Font = Enum.Font.GothamBold,
        Text = "ℹ",
        TextColor3 = Theme.Accent,
        TextSize = 14,
        Parent = container
    })
    
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, description and 4 or 0),
        Size = UDim2.new(1, -48, 0, description and 22 or height),
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = container
    })
    
    if description then
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 36, 0, 24),
            Size = UDim2.new(1, -48, 0, 18),
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = Theme.TextDark,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container
        })
    end
    
    return {
        SetText = function(_, t)
            label.Text = t
        end
    }
end

-- 9. Paragraph (multi-line text)
function Library.AddParagraph(tab, options)
    options = options or {}
    local title = options.Title or "Paragraph"
    local content = options.Content or ""
    
    local container = Create("Frame", {
        Name = "Paragraph_" .. title,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    AddPadding(container, 12, 12, 14, 14)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = container
    })
    
    local contentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = 2,
        Parent = container
    })
    
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = container
    })
    
    return {
        SetTitle = function(_, t) container:FindFirstChild("TextLabel").Text = t end,
        SetContent = function(_, c) contentLabel.Text = c end
    }
end

-- 10. Separator
function Library.AddSeparator(tab, text)
    local container = Create("Frame", {
        Name = "Separator",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    local line1 = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = container
    })
    
    if text then
        local lbl = Create("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Theme.Primary,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Enum.Font.GothamBold,
            Text = "  " .. text .. "  ",
            TextColor3 = Theme.TextDark,
            TextSize = 11,
            Parent = container
        })
    end
end

-- 11. Progress Bar
function Library.AddProgressBar(tab, options)
    options = options or {}
    local name = options.Name or "Progress"
    local default = options.Default or 0
    local flag = options.Flag or name
    
    tab.Library.Config:SetFlag(flag, default)
    
    local container = Create("Frame", {
        Name = "Progress_" .. name,
        BackgroundColor3 = Theme.Tertiary,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    AddCorner(container, 8)
    AddStroke(container, Theme.Border, 1, 0.7)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(0.7, 0, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local percentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.7, 0, 0, 6),
        Size = UDim2.new(0.3, -14, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = math.floor(default * 100) .. "%",
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container
    })
    
    local track = Create("Frame", {
        BackgroundColor3 = Theme.SliderBar,
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -28, 0, 10),
        Parent = container
    })
    AddCorner(track, 5)
    
    local fill = Create("Frame", {
        BackgroundColor3 = Theme.SliderFill,
        Size = UDim2.new(default, 0, 1, 0),
        Parent = track
    })
    AddCorner(fill, 5)
    AddGradient(fill, Theme.Accent, Theme.AccentDark, 0)
    
    return {
        Set = function(_, val)
            val = math.clamp(val, 0, 1)
            Tween(fill, 0.5, {Size = UDim2.new(val, 0, 1, 0)})
            percentLabel.Text = math.floor(val * 100) .. "%"
            tab.Library.Config:SetFlag(flag, val)
        end,
        Get = function()
            return tab.Library.Config:GetFlag(flag)
        end
    }
end

-- 12. Multi-Button Row
function Library.AddButtonRow(tab, options)
    options = options or {}
    local buttons = options.Buttons or {}
    
    local container = Create("Frame", {
        Name = "ButtonRow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = container
    })
    
    local btnCount = #buttons
    local refs = {}
    
    for i, btnInfo in ipairs(buttons) do
        local btn = Create("TextButton", {
            Name = btnInfo.Name or "Btn" .. i,
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.6,
            Size = UDim2.new(1 / btnCount, -(6 * (btnCount - 1) / btnCount), 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = btnInfo.Name or "Button",
            TextColor3 = Theme.Text,
            TextSize = 13,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = container
        })
        AddCorner(btn, 8)
        
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.2, {BackgroundTransparency = 0.3})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.2, {BackgroundTransparency = 0.6})
        end)
        btn.MouseButton1Click:Connect(function()
            tab.Library:PlaySound(Sounds.Click, 0.3)
            Ripple(btn)
            pcall(btnInfo.Callback or function() end)
        end)
        
        refs[btnInfo.Name or ("Btn" .. i)] = btn
    end
    
    return refs
end

-- Built-in Settings Tab
function Library:AddSettingsTab()
    local settingsTab = self:AddTab("Settings", "⚙")
    
    -- UI Settings Section
    Library.AddSection(settingsTab, "UI Settings")
    
    Library.AddToggle(settingsTab, {
        Name = "Sound Effects",
        Default = self.SoundEnabled,
        Flag = "UI_SoundEnabled",
        Callback = function(val)
            self.SoundEnabled = val
        end
    })
    
    Library.AddToggle(settingsTab, {
        Name = "Draggable UI",
        Default = self.DragEnabled,
        Flag = "UI_DragEnabled",
        Callback = function(val)
            self.DragEnabled = val
        end
    })
    
    Library.AddKeybind(settingsTab, {
        Name = "Toggle Keybind",
        Default = self.ToggleKey,
        Flag = "UI_ToggleKey",
        Changed = function(key)
            self.ToggleKey = key
            self:Notify("Settings", "Toggle key changed to: " .. key.Name, "info", 3)
        end
    })
    
    -- Theme Section
    Library.AddSection(settingsTab, "Theme")
    
    Library.AddColorPicker(settingsTab, {
        Name = "Accent Color",
        Default = Theme.Accent,
        Flag = "UI_AccentColor",
        Callback = function(color)
            Theme.Accent = color
            -- Optionally update UI elements here
        end
    })
    
    -- Config Section
    Library.AddSection(settingsTab, "Configuration")
    
    local configInput = Library.AddTextInput(settingsTab, {
        Name = "Config Name",
        Default = "",
        Placeholder = "Enter config name...",
        Flag = "UI_ConfigName"
    })
    
    Library.AddButtonRow(settingsTab, {
        Buttons = {
            {
                Name = "Save",
                Callback = function()
                    local configName = self.Config:GetFlag("UI_ConfigName")
                    if configName and configName ~= "" then
                        if self.Config:SaveConfig(configName) then
                            self:Notify("Config", 'Saved config: "' .. configName .. '"', "success", 3)
                        else
                            self:Notify("Config", "Failed to save config (no file system)", "error", 3)
                        end
                    else
                        self:Notify("Config", "Please enter a config name", "warning", 3)
                    end
                end
            },
            {
                Name = "Load",
                Callback = function()
                    local configName = self.Config:GetFlag("UI_ConfigName")
                    if configName and configName ~= "" then
                        if self.Config:LoadConfig(configName) then
                            self:Notify("Config", 'Loaded config: "' .. configName .. '"', "success", 3)
                        else
                            self:Notify("Config", "Config not found", "error", 3)
                        end
                    else
                        self:Notify("Config", "Please enter a config name", "warning", 3)
                    end
                end
            },
            {
                Name = "Delete",
                Callback = function()
                    local configName = self.Config:GetFlag("UI_ConfigName")
                    if configName and configName ~= "" then
                        if self.Config:DeleteConfig(configName) then
                            self:Notify("Config", 'Deleted config: "' .. configName .. '"', "success", 3)
                        else
                            self:Notify("Config", "Config not found", "error", 3)
                        end
                    end
                end
            }
        }
    })
    
    -- Config list dropdown
    local configDropdown = Library.AddDropdown(settingsTab, {
        Name = "Saved Configs",
        Items = self.Config:GetConfigs(),
        Flag = "UI_SelectedConfig",
        Callback = function(val)
            configInput:Set(val)
        end
    })
    
    Library.AddButton(settingsTab, {
        Name = "Refresh Config List",
        Callback = function()
            configDropdown:Refresh(self.Config:GetConfigs())
            self:Notify("Config", "Config list refreshed", "info", 2)
        end
    })
    
    Library.AddSeparator(settingsTab, "Info")
    
    Library.AddParagraph(settingsTab, {
        Title = "Script Hub",
        Content = "Advanced UI Library v2.0\nDeveloped for Roblox exploit environments.\n\nControls:\n• " .. self.ToggleKey.Name .. " - Toggle UI\n• Drag title bar to move\n• Right click for context menus"
    })
    
    Library.AddButton(settingsTab, {
        Name = "Destroy UI",
        Description = "Completely remove the UI from the game",
        Callback = function()
            self:Destroy()
        end
    })
    
    return settingsTab
end

return Library
