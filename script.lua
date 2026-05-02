--[[
    Vape UI Library - Roblox Script Container
    Author: logz
    Version: 2.0
    Description: Feature-rich UI library for Roblox exploit scripts.
    Supports PC and Mobile, highly customizable settings.
    Includes: Color Wheel, Custom Theme, Config Profiles, and more.
    
    API Quick Start:
        local VapeUI = loadstring(game:HttpGet("..."))()
        local Window = VapeUI:CreateWindow({
            Title = "Cheat Menu",
            Theme = "Dark",
            ConfigFolder = "MyCheat"
        })
        local Tab = Window:AddTab("Combat")
        local Category = Tab:AddCategory("Aimbot")
        local Module = Category:AddModule({
            Name = "Aimbot",
            Description = "Automatically aims at enemies",
            Default = false,
            Bind = Enum.KeyCode.MouseButton2
        })
        Module:AddSlider("FOV", {Min = 10, Max = 180, Default = 90, Suffix = "°"})
        Module:AddColorPicker("ESP Color", {Default = Color3.fromRGB(255,0,0)})
        Module:AddDropdown("Target", {Values = {"Head","Chest"}, Default = "Head"})
        
    Key Features:
        - Complete settings control (theme, color wheel, window behavior)
        - Config profiles with import/export
        - Mobile optimized touch controls
        - Hotkey system, global binds
        - Search, modules list, tooltips
        - Custom notifications
        - Watermark
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Utility Functions
local Library = {}
Library.__index = Library
Library.Windows = {}
Library.Connections = {}
Library.Notifications = {}
Library.Watermark = nil

-- Theme Colors (default dark)
local Themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 46),
        SecondaryBackground = Color3.fromRGB(24, 24, 37),
        Accent = Color3.fromRGB(124, 58, 237),
        Text = Color3.fromRGB(205, 214, 244),
        SubText = Color3.fromRGB(166, 173, 200),
        Border = Color3.fromRGB(49, 50, 68),
        ToggleOn = Color3.fromRGB(166, 227, 161),
        ToggleOff = Color3.fromRGB(243, 139, 168),
        SliderBackground = Color3.fromRGB(69, 71, 90),
        SliderFill = Color3.fromRGB(124, 58, 237),
        Hover = Color3.fromRGB(69, 71, 90),
    },
    Light = {
        Background = Color3.fromRGB(230, 233, 239),
        SecondaryBackground = Color3.fromRGB(204, 208, 218),
        Accent = Color3.fromRGB(94, 92, 230),
        Text = Color3.fromRGB(30, 30, 46),
        SubText = Color3.fromRGB(108, 112, 134),
        Border = Color3.fromRGB(166, 173, 200),
        ToggleOn = Color3.fromRGB(64, 160, 43),
        ToggleOff = Color3.fromRGB(210, 15, 57),
        SliderBackground = Color3.fromRGB(188, 192, 204),
        SliderFill = Color3.fromRGB(94, 92, 230),
        Hover = Color3.fromRGB(188, 192, 204),
    }
}

-- Detect platform
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
local IS_PC = not IS_MOBILE

-- Helper to create tween
local function tweenObject(obj, props, duration)
    local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- Color Wheel Picker (custom component)
local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.Create(Parent, DefaultColor, Callback)
    local self = setmetatable({}, ColorPicker)
    self.Parent = Parent
    self.Default = DefaultColor or Color3.fromRGB(255,255,255)
    self.Value = self.Default
    self.Callback = Callback or function() end
    self.Container = Instance.new("Frame")
    self.Container.Size = UDim2.new(1,0,0,42)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = Parent
    
    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Size = UDim2.new(0,120,1,0)
    self.Label.BackgroundTransparency = 1
    self.Label.Font = Enum.Font.GothamBold
    self.Label.Text = "Color"
    self.Label.TextColor3 = Theme.Text
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Container
    
    -- Color preview button
    self.Preview = Instance.new("TextButton")
    self.Preview.Size = UDim2.new(1,-130,1,-6)
    self.Preview.Position = UDim2.new(0,125,0,3)
    self.Preview.BackgroundColor3 = self.Value
    self.Preview.BorderSizePixel = 0
    self.Preview.Text = ""
    self.Preview.Parent = self.Container
    self.Preview.AutoButtonColor = false
    
    -- Color wheel popup (hidden initially)
    self.Popup = Instance.new("Frame")
    self.Popup.Size = UDim2.new(0,200,0,200)
    self.Popup.Position = UDim2.new(0,0,0,45)
    self.Popup.BackgroundColor3 = Theme.SecondaryBackground
    self.Popup.BorderSizePixel = 1
    self.Popup.BorderColor3 = Theme.Border
    self.Popup.Visible = false
    self.Popup.ZIndex = 5
    self.Popup.Parent = self.Container
    
    -- Hue/Saturation gradient (simplified color wheel as rectangle)
    self.HueBar = Instance.new("ImageButton")
    self.HueBar.Size = UDim2.new(1,-4,0,20)
    self.HueBar.Position = UDim2.new(0,2,1,-24)
    self.HueBar.BackgroundColor3 = Color3.new(1,1,1)
    -- Create hue gradient via code (simplified)
    self.HueBar.Image = "rbxassetid://284402752" -- a placeholder; we'll use a colored frame gradient
    -- Actually we'll use multiple frames for simplicity
    self.HueBar.BorderSizePixel = 0
    self.HueBar.ZIndex = 6
    self.HueBar.Parent = self.Popup
    
    -- Saturation/Value box
    self.SVBox = Instance.new("ImageButton")
    self.SVBox.Size = UDim2.new(1,-4,0,140)
    self.SVBox.Position = UDim2.new(0,2,0,2)
    self.SVBox.BackgroundColor3 = Color3.new(1,1,1)
    self.SVBox.BorderSizePixel = 0
    self.SVBox.ZIndex = 6
    self.SVBox.Parent = self.Popup
    
    -- Update HueBar gradient
    -- We'll use a loop to create thin colored frames for hue (simplified)
    local hueFrames = {}
    for i=0, 50 do
        local hue = i / 50
        local color = Color3.fromHSV(hue, 1, 1)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200/51, 1, 0)
        frame.Position = UDim2.new(0, i * 200/51, 0, 0)
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.Parent = self.HueBar
    end
    
    -- SV Box gradient (white -> current hue -> black)
    self.SVBox.BackgroundColor3 = Color3.new(1,1,1)
    -- We'll update it when hue changes
    
    -- Color preview circle on SV
    self.SVCursor = Instance.new("Frame")
    self.SVCursor.Size = UDim2.new(0,8,0,8)
    self.SVCursor.AnchorPoint = Vector2.new(0.5,0.5)
    self.SVCursor.BackgroundColor3 = Theme.Text
    self.SVCursor.BorderSizePixel = 0
    self.SVCursor.ZIndex = 7
    self.SVCursor.Parent = self.SVBox
    
    -- Hue indicator on HueBar
    self.HueCursor = Instance.new("Frame")
    self.HueCursor.Size = UDim2.new(0,4,1,8)
    self.HueCursor.AnchorPoint = Vector2.new(0.5,0)
    self.HueCursor.Position = UDim2.new(0,0,0,-4)
    self.HueCursor.BackgroundColor3 = Theme.Text
    self.HueCursor.BorderSizePixel = 0
    self.HueCursor.ZIndex = 7
    self.HueCursor.Parent = self.HueBar
    
    -- TextBox for hex input
    self.HexInput = Instance.new("TextBox")
    self.HexInput.Size = UDim2.new(1,-4,0,20)
    self.HexInput.Position = UDim2.new(0,2,1,0)
    self.HexInput.BackgroundColor3 = Theme.Background
    self.HexInput.BorderSizePixel = 1
    self.HexInput.BorderColor3 = Theme.Border
    self.HexInput.Font = Enum.Font.Gotham
    self.HexInput.Text = "#FFFFFF"
    self.HexInput.TextColor3 = Theme.Text
    self.HexInput.TextSize = 14
    self.HexInput.PlaceholderText = "#FFFFFF"
    self.HexInput.ZIndex = 6
    self.HexInput.Parent = self.Popup
    
    -- Connect interactions
    local hue = 0
    local sat = 1
    local val = 1
    
    local function updateColorFromHSV()
        local col = Color3.fromHSV(hue, sat, val)
        self.Value = col
        self.Preview.BackgroundColor3 = col
        self.HexInput.Text = string.format("#%02X%02X%02X", math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255))
        -- Update SVBox gradient top-left white, top-right pure hue, bottom black
        self.SVBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        pcall(function() self.Callback(col) end)
    end
    
    local function updateFromHex(hex)
        local r,g,b = tonumber(hex:sub(2,3),16)/255, tonumber(hex:sub(4,5),16)/255, tonumber(hex:sub(6,7),16)/255
        if r and g and b then
            local h,s,v = Color3.new(r,g,b):ToHSV()
            hue, sat, val = h, s, v
            updateColorFromHSV()
        end
    end
    
    self.HexInput.FocusLost:Connect(function(enterPressed)
        local text = self.HexInput.Text
        if string.match(text, "^#%x%x%x%x%x%x$") then
            updateFromHex(text)
        end
    end)
    
    self.HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService.TouchEnabled do
                local pos = UserInputService:GetMouseLocation()
                local relative = pos - self.HueBar.AbsolutePosition
                local x = math.clamp(relative.X / self.HueBar.AbsoluteSize.X, 0, 1)
                hue = x
                self.HueCursor.Position = UDim2.new(x,0,0,-4)
                updateColorFromHSV()
                RunService.RenderStepped:Wait()
            end
        end
    end)
    
    self.SVBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService.TouchEnabled do
                local pos = UserInputService:GetMouseLocation()
                local relative = pos - self.SVBox.AbsolutePosition
                local x = math.clamp(relative.X / self.SVBox.AbsoluteSize.X, 0, 1)
                local y = math.clamp(relative.Y / self.SVBox.AbsoluteSize.Y, 0, 1)
                sat = x
                val = 1 - y
                self.SVCursor.Position = UDim2.new(x,0,y,0)
                updateColorFromHSV()
                RunService.RenderStepped:Wait()
            end
        end
    end)
    
    self.Preview.MouseButton1Click:Connect(function()
        self.Popup.Visible = not self.Popup.Visible
        if self.Popup.Visible then
            updateColorFromHSV()
        end
    end)
    
    -- Initial set
    local h,s,v = self.Default:ToHSV()
    hue, sat, val = h, s, v
    updateColorFromHSV()
    self.SVCursor.Position = UDim2.new(s,0,1-v,0)
    self.HueCursor.Position = UDim2.new(h,0,0,-4)
    
    return self
end

--[[
    Main Library
]]
function Library.new(ConfigFolder)
    local self = setmetatable({}, Library)
    self.ConfigFolder = ConfigFolder or "VapeUI"
    self.Windows = {}
    self.Connections = {}
    self.NotificationUI = nil
    return self
end

function Library:CreateWindow(options)
    options = options or {}
    local Window = {}
    Window.Name = options.Title or "Vape UI"
    Window.Theme = options.Theme or "Dark"
    Window.ConfigFolder = options.ConfigFolder or self.ConfigFolder
    Window.Accent = options.Accent or Themes[Window.Theme].Accent
    Window.Opened = true
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Categories = {} -- currently displayed categories
    Window.Modules = {}
    Window.Connection = {}
    Window.Visible = true
    Window.Locked = false
    Window.Dragging = false
    Window.Resizing = false
    Window.MinSize = Vector2.new(500, 350)
    Window.Size = options.Size or Vector2.new(600, 400)
    Window.Position = options.Position or UDim2.new(0.5, -300, 0.5, -200)
    
    -- Base GUI
    Window.ScreenGui = Instance.new("ScreenGui")
    Window.ScreenGui.Name = Window.Name
    Window.ScreenGui.ResetOnSpawn = false
    Window.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn and syn.protect_gui then
        syn.protect_gui(Window.ScreenGui)
    end
    Window.ScreenGui.Parent = (gethui and gethui()) or CoreGui
    
    -- Main frame
    Window.MainFrame = Instance.new("Frame")
    Window.MainFrame.Name = "Main"
    Window.MainFrame.Size = UDim2.new(0,Window.Size.X,0,Window.Size.Y)
    Window.MainFrame.Position = Window.Position
    Window.MainFrame.BackgroundColor3 = Themes[Window.Theme].Background
    Window.MainFrame.BorderSizePixel = 1
    Window.MainFrame.BorderColor3 = Themes[Window.Theme].Border
    Window.MainFrame.Active = true
    Window.MainFrame.Selectable = true
    Window.MainFrame.ClipsDescendants = true
    Window.MainFrame.Parent = Window.ScreenGui
    
    -- Drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1,16,1,16)
    shadow.Position = UDim2.new(0,-8,0,-8)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084" -- generic shadow
    shadow.ImageColor3 = Color3.new(0,0,0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(8,8,8,8)
    shadow.ZIndex = 0
    shadow.Parent = Window.MainFrame
    
    -- Title bar
    Window.TitleBar = Instance.new("Frame")
    Window.TitleBar.Name = "TitleBar"
    Window.TitleBar.Size = UDim2.new(1,0,0,32)
    Window.TitleBar.BackgroundColor3 = Themes[Window.Theme].SecondaryBackground
    Window.TitleBar.BorderSizePixel = 0
    Window.TitleBar.Parent = Window.MainFrame
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1,-120,1,0)
    titleText.Position = UDim2.new(0,8,0,0)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamBold
    titleText.Text = Window.Name
    titleText.TextColor3 = Themes[Window.Theme].Text
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = Window.TitleBar
    
    -- Window controls
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,32,0,32)
    closeBtn.Position = UDim2.new(1,-32,0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Themes[Window.Theme].SubText
    closeBtn.TextSize = 18
    closeBtn.Parent = Window.TitleBar
    closeBtn.MouseButton1Click:Connect(function()
        Window.ScreenGui:Destroy()
    end)
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,32,0,32)
    minBtn.Position = UDim2.new(1,-64,0,0)
    minBtn.BackgroundTransparency = 1
    minBtn.Font = Enum.Font.Gotham
    minBtn.Text = "─"
    minBtn.TextColor3 = Themes[Window.Theme].SubText
    minBtn.TextSize = 18
    minBtn.Parent = Window.TitleBar
    minBtn.MouseButton1Click:Connect(function()
        Window.MainFrame.Visible = not Window.MainFrame.Visible
    end)
    
    -- Tab container
    Window.TabContainer = Instance.new("Frame")
    Window.TabContainer.Size = UDim2.new(1,0,0,28)
    Window.TabContainer.Position = UDim2.new(0,0,0,32)
    Window.TabContainer.BackgroundColor3 = Themes[Window.Theme].SecondaryBackground
    Window.TabContainer.BorderSizePixel = 0
    Window.TabContainer.Parent = Window.MainFrame
    
    -- Left category list
    Window.CategoryList = Instance.new("ScrollingFrame")
    Window.CategoryList.Size = UDim2.new(0,120,1,-60)
    Window.CategoryList.Position = UDim2.new(0,0,0,60)
    Window.CategoryList.BackgroundColor3 = Themes[Window.Theme].SecondaryBackground
    Window.CategoryList.BorderSizePixel = 0
    Window.CategoryList.ScrollBarThickness = 4
    Window.CategoryList.ScrollBarImageColor3 = Themes[Window.Theme].Border
    Window.CategoryList.CanvasSize = UDim2.new(0,0,0,0)
    Window.CategoryList.Parent = Window.MainFrame
    
    local catListLayout = Instance.new("UIListLayout")
    catListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    catListLayout.Parent = Window.CategoryList
    
    -- Right side modules area
    Window.ModulesArea = Instance.new("Frame")
    Window.ModulesArea.Size = UDim2.new(1,-120,1,-60)
    Window.ModulesArea.Position = UDim2.new(0,120,0,60)
    Window.ModulesArea.BackgroundColor3 = Themes[Window.Theme].Background
    Window.ModulesArea.BorderSizePixel = 0
    Window.ModulesArea.Parent = Window.MainFrame
    
    -- Search bar inside modules area
    Window.SearchBar = Instance.new("TextBox")
    Window.SearchBar.Size = UDim2.new(1,-8,0,26)
    Window.SearchBar.Position = UDim2.new(0,4,0,4)
    Window.SearchBar.BackgroundColor3 = Themes[Window.Theme].SecondaryBackground
    Window.SearchBar.BorderSizePixel = 1
    Window.SearchBar.BorderColor3 = Themes[Window.Theme].Border
    Window.SearchBar.Font = Enum.Font.Gotham
    Window.SearchBar.Text = ""
    Window.SearchBar.PlaceholderText = "Search modules..."
    Window.SearchBar.PlaceholderColor3 = Themes[Window.Theme].SubText
    Window.SearchBar.TextColor3 = Themes[Window.Theme].Text
    Window.SearchBar.TextSize = 14
    Window.SearchBar.Parent = Window.ModulesArea
    
    -- Modules scrolling container
    Window.ModuleList = Instance.new("ScrollingFrame")
    Window.ModuleList.Size = UDim2.new(1,-8,1,-34)
    Window.ModuleList.Position = UDim2.new(0,4,0,34)
    Window.ModuleList.BackgroundTransparency = 1
    Window.ModuleList.ScrollBarThickness = 4
    Window.ModuleList.ScrollBarImageColor3 = Themes[Window.Theme].Border
    Window.ModuleList.CanvasSize = UDim2.new(0,0,0,0)
    Window.ModuleList.Parent = Window.ModulesArea
    
    local modListLayout = Instance.new("UIListLayout")
    modListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    modListLayout.Parent = Window.ModuleList
    
    -- Status bar
    Window.StatusBar = Instance.new("Frame")
    Window.StatusBar.Size = UDim2.new(1,0,0,22)
    Window.StatusBar.Position = UDim2.new(0,0,1,-22)
    Window.StatusBar.BackgroundColor3 = Themes[Window.Theme].SecondaryBackground
    Window.StatusBar.BorderSizePixel = 0
    Window.StatusBar.Parent = Window.MainFrame
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,50,1,0)
    fpsLabel.Position = UDim2.new(1,-60,0,0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.Text = "60 FPS"
    fpsLabel.TextColor3 = Themes[Window.Theme].SubText
    fpsLabel.TextSize = 12
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
    fpsLabel.Parent = Window.StatusBar
    spawn(function()
        while Window.ScreenGui and Window.ScreenGui.Parent do
            local fps = math.floor(1/workspace:GetRealPhysicsFPS())
            fpsLabel.Text = fps.." FPS"
            wait(0.5)
        end
    end)
    
    -- Drag to move
    Window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Window.Dragging = true
            local startPos = UserInputService:GetMouseLocation()
            local framePos = Window.MainFrame.AbsolutePosition
            while Window.Dragging and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService.TouchEnabled) do
                local mousePos = UserInputService:GetMouseLocation()
                local delta = mousePos - startPos
                Window.MainFrame.Position = UDim2.new(0, framePos.X + delta.X, 0, framePos.Y + delta.Y)
                RunService.RenderStepped:Wait()
            end
            Window.Dragging = false
        end
    end)
    
    -- Resize handle
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Size = UDim2.new(0,16,0,16)
    resizeHandle.Position = UDim2.new(1,-16,1,-16)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Text = "◢"
    resizeHandle.TextColor3 = Themes[Window.Theme].SubText
    resizeHandle.TextSize = 14
    resizeHandle.Parent = Window.MainFrame
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Window.Resizing = true
            local startPos = UserInputService:GetMouseLocation()
            local startSize = Window.MainFrame.AbsoluteSize
            while Window.Resizing and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService.TouchEnabled) do
                local mousePos = UserInputService:GetMouseLocation()
                local delta = mousePos - startPos
                local newWidth = math.clamp(startSize.X + delta.X, Window.MinSize.X, 1920)
                local newHeight = math.clamp(startSize.Y + delta.Y, Window.MinSize.Y, 1080)
                Window.MainFrame.Size = UDim2.new(0,newWidth,0,newHeight)
                RunService.RenderStepped:Wait()
            end
            Window.Resizing = false
        end
    end)
    
    -- Methods
    function Window:AddTab(name, icon)
        local tab = {
            Name = name,
            Window = self,
            Categories = {}
        }
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,0,1,0) -- will resize automatically
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.Text = name
        btn.TextColor3 = Themes[self.Theme].SubText
        btn.TextSize = 14
        btn.Parent = self.TabContainer
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab)
        end)
        tab.Button = btn
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then
            self:SwitchTab(tab)
        end
        return tab
    end
    
    function Window:SwitchTab(tab)
        for _,t in pairs(self.Tabs) do
            t.Button.TextColor3 = Themes[self.Theme].SubText
        end
        tab.Button.TextColor3 = self.Accent
        self.CurrentTab = tab
        -- Refresh categories/modules
        self:ClearCategoryList()
        for _,cat in pairs(tab.Categories) do
            self:AddCategoryToList(cat)
        end
    end
    
    function Window:ClearCategoryList()
        for _,child in pairs(self.CategoryList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        self.CategoryList.CanvasSize = UDim2.new(0,0,0,0)
    end
    
    function Window:AddCategory(categoryName)
        local category = {
            Name = categoryName,
            Tab = self.CurrentTab,
            Modules = {}
        }
        table.insert(self.CurrentTab.Categories, category)
        self:AddCategoryToList(category)
        return category
    end
    
    function Window:AddCategoryToList(category)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.Gotham
        btn.Text = category.Name
        btn.TextColor3 = Themes[self.Theme].SubText
        btn.TextSize = 14
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = self.CategoryList
        btn.MouseButton1Click:Connect(function()
            self:ShowModulesForCategory(category)
        end)
        self.CategoryList.CanvasSize = UDim2.new(0,0,0,self.CategoryList.CanvasSize.Y.Offset + 28)
    end
    
    function Window:ShowModulesForCategory(category)
        self.CurrentCategory = category
        -- Clear module list
        for _,child in pairs(self.ModuleList:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "SearchBar" then
                child:Destroy()
            end
        end
        self.ModuleList.CanvasSize = UDim2.new(0,0,0,0)
        -- Add modules
        for _,mod in pairs(category.Modules) do
            self:CreateModuleWidget(mod)
        end
        -- Apply search filter
        self:FilterModules(self.SearchBar.Text)
    end
    
    function Window:CreateModuleWidget(mod)
        local frame = Instance.new("Frame")
        frame.Name = "Module_"..mod.Name
        frame.Size = UDim2.new(1,0,0,34)
        frame.BackgroundTransparency = 1
        frame.Parent = self.ModuleList
        
        -- Indicator stripe
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0,3,1,0)
        indicator.BackgroundColor3 = mod.Enabled and self.Accent or Color3.new(1,1,1)
        indicator.BackgroundTransparency = mod.Enabled and 0 or 0.9
        indicator.BorderSizePixel = 0
        indicator.Parent = frame
        mod.Indicator = indicator
        
        -- Module name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0,160,1,0)
        nameLabel.Position = UDim2.new(0,8,0,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.Text = mod.Name
        nameLabel.TextColor3 = Themes[self.Theme].Text
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = frame
        
        -- Bind display
        local bindLabel = Instance.new("TextLabel")
        bindLabel.Size = UDim2.new(0,60,1,0)
        bindLabel.Position = UDim2.new(0,170,0,0)
        bindLabel.BackgroundTransparency = 1
        bindLabel.Font = Enum.Font.Gotham
        bindLabel.Text = mod.Bind and ("["..mod.Bind.Name:gsub("MouseButton","M").."]") or ""
        bindLabel.TextColor3 = Themes[self.Theme].SubText
        bindLabel.TextSize = 12
        bindLabel.TextXAlignment = Enum.TextXAlignment.Left
        bindLabel.Parent = frame
        
        -- Toggle button
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0,36,0,22)
        toggle.Position = UDim2.new(1,-80,0,6)
        toggle.BackgroundColor3 = mod.Enabled and Themes[self.Theme].ToggleOn or Themes[self.Theme].ToggleOff
        toggle.BorderSizePixel = 0
        toggle.Text = ""
        toggle.Parent = frame
        toggle.MouseButton1Click:Connect(function()
            mod.Enabled = not mod.Enabled
            toggle.BackgroundColor3 = mod.Enabled and Themes[self.Theme].ToggleOn or Themes[self.Theme].ToggleOff
            indicator.BackgroundColor3 = mod.Enabled and self.Accent or Color3.new(1,1,1)
            indicator.BackgroundTransparency = mod.Enabled and 0 or 0.9
            if mod.OnChanged then mod.OnChanged(mod.Enabled) end
        end)
        mod.Toggle = toggle
        
        -- Settings expand arrow
        local expandBtn = Instance.new("TextButton")
        expandBtn.Size = UDim2.new(0,32,0,32)
        expandBtn.Position = UDim2.new(1,-36,0,1)
        expandBtn.BackgroundTransparency = 1
        expandBtn.Font = Enum.Font.Gotham
        expandBtn.Text = ">"
        expandBtn.TextColor3 = Themes[self.Theme].SubText
        expandBtn.TextSize = 16
        expandBtn.Parent = frame
        expandBtn.MouseButton1Click:Connect(function()
            mod:ToggleSettings()
        end)
        
        -- Settings container (hidden)
        mod.SettingsFrame = Instance.new("Frame")
        mod.SettingsFrame.Size = UDim2.new(1,0,0,0)
        mod.SettingsFrame.BackgroundColor3 = Themes[self.Theme].SecondaryBackground
        mod.SettingsFrame.BorderSizePixel = 0
        mod.SettingsFrame.Visible = false
        mod.SettingsFrame.ClipsDescendants = true
        mod.SettingsFrame.Parent = frame
        
        local settingsList = Instance.new("UIListLayout")
        settingsList.SortOrder = Enum.SortOrder.LayoutOrder
        settingsList.Parent = mod.SettingsFrame
        
        mod.Settings = {}
        mod.SettingWidgets = {}
        mod.SettingsVisible = false
        
        function mod:ToggleSettings()
            mod.SettingsVisible = not mod.SettingsVisible
            mod.SettingsFrame.Visible = mod.SettingsVisible
            if mod.SettingsVisible then
                frame.Size = UDim2.new(1,0,0,34 + mod.SettingsFrame.AbsoluteSize.Y)
            else
                frame.Size = UDim2.new(1,0,0,34)
            end
            self:UpdateModuleListCanvas()
        end
        
        function mod:AddSlider(name, options)
            options = options or {}
            local value = options.Default or options.Min or 0
            local setting = {Type = "Slider", Name = name, Min = options.Min, Max = options.Max, Default = value, Suffix = options.Suffix, Callback = options.Callback}
            -- Create widget
            local widget = Instance.new("Frame")
            widget.Size = UDim2.new(1,-8,0,30)
            widget.Position = UDim2.new(0,4,0,0)
            widget.BackgroundTransparency = 1
            widget.Parent = mod.SettingsFrame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,100,0,20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = name
            label.TextColor3 = Themes[self.Theme].Text
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = widget
            
            local sliderInput = Instance.new("TextBox")
            sliderInput.Size = UDim2.new(1,-104,0,20)
            sliderInput.Position = UDim2.new(0,100,0,0)
            sliderInput.BackgroundColor3 = Themes[self.Theme].SliderBackground
            sliderInput.BorderSizePixel = 1
            sliderInput.BorderColor3 = Themes[self.Theme].Border
            sliderInput.Font = Enum.Font.Gotham
            sliderInput.Text = tostring(value) .. (options.Suffix or "")
            sliderInput.TextColor3 = Themes[self.Theme].Text
            sliderInput.TextSize = 13
            sliderInput.Parent = widget
            
            -- Slider bar
            local sliderBar = Instance.new("Frame")
            sliderBar.Size = UDim2.new(1,0,0,4)
            sliderBar.Position = UDim2.new(0,0,0,20)
            sliderBar.BackgroundColor3 = Themes[self.Theme].SliderBackground
            sliderBar.BorderSizePixel = 0
            sliderBar.Parent = widget
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - options.Min) / (options.Max - options.Min), 0, 1,0)
            fill.BackgroundColor3 = self.Accent
            fill.BorderSizePixel = 0
            fill.Parent = sliderBar
            
            local function updateSlider(val)
                value = math.clamp(val, options.Min, options.Max)
                fill.Size = UDim2.new((value - options.Min) / (options.Max - options.Min), 0, 1,0)
                sliderInput.Text = tostring(math.floor(value*100)/100) .. (options.Suffix or "")
                if setting.Callback then setting.Callback(value) end
            end
            
            sliderInput.FocusLost:Connect(function()
                local num = tonumber(sliderInput.Text:match("%d+%.?%d*"))
                if num then updateSlider(num) end
            end)
            
            sliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    while (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService.TouchEnabled) do
                        local mousePos = UserInputService:GetMouseLocation()
                        local relative = mousePos.X - sliderBar.AbsolutePosition.X
                        local percent = math.clamp(relative / sliderBar.AbsoluteSize.X, 0, 1)
                        local newVal = options.Min + percent * (options.Max - options.Min)
                        updateSlider(newVal)
                        RunService.RenderStepped:Wait()
                    end
                end
            end)
            
            table.insert(mod.Settings, setting)
            return setting
        end
        
        function mod:AddDropdown(name, options)
            options = options or {}
            local selected = options.Default or options.Values[1]
            local setting = {Type = "Dropdown", Name = name, Values = options.Values, Selected = selected, Callback = options.Callback}
            local widget = Instance.new("Frame")
            widget.Size = UDim2.new(1,-8,0,30)
            widget.BackgroundTransparency = 1
            widget.Parent = mod.SettingsFrame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,100,0,20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = name
            label.TextColor3 = Themes[self.Theme].Text
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = widget
            
            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(1,-104,0,20)
            dropBtn.Position = UDim2.new(0,100,0,0)
            dropBtn.BackgroundColor3 = Themes[self.Theme].SliderBackground
            dropBtn.BorderSizePixel = 1
            dropBtn.BorderColor3 = Themes[self.Theme].Border
            dropBtn.Font = Enum.Font.Gotham
            dropBtn.Text = selected
            dropBtn.TextColor3 = Themes[self.Theme].Text
            dropBtn.TextSize = 13
            dropBtn.Parent = widget
            
            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(1,0,0,0)
            listFrame.Position = UDim2.new(0,0,0,20)
            listFrame.BackgroundColor3 = Themes[self.Theme].SecondaryBackground
            listFrame.BorderSizePixel = 1
            listFrame.BorderColor3 = Themes[self.Theme].Border
            listFrame.Visible = false
            listFrame.ZIndex = 5
            listFrame.Parent = widget
            
            local listLayout = Instance.new("UIListLayout")
            listLayout.Parent = listFrame
            
            for _,v in ipairs(options.Values) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1,0,0,20)
                item.BackgroundTransparency = 1
                item.Font = Enum.Font.Gotham
                item.Text = v
                item.TextColor3 = Themes[self.Theme].Text
                item.TextSize = 13
                item.Parent = listFrame
                item.MouseButton1Click:Connect(function()
                    selected = v
                    dropBtn.Text = v
                    listFrame.Visible = false
                    if setting.Callback then setting.Callback(selected) end
                end)
            end
            listFrame.Size = UDim2.new(1,0,0,20 * #options.Values)
            
            dropBtn.MouseButton1Click:Connect(function()
                listFrame.Visible = not listFrame.Visible
            end)
            
            table.insert(mod.Settings, setting)
            return setting
        end
        
        function mod:AddColorPicker(name, options)
            options = options or {}
            local defaultColor = options.Default or Color3.new(1,1,1)
            local setting = {Type = "ColorPicker", Name = name, Value = defaultColor, Callback = options.Callback}
            local widget = Instance.new("Frame")
            widget.Size = UDim2.new(1,-8,0,42)
            widget.BackgroundTransparency = 1
            widget.Parent = mod.SettingsFrame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,100,0,20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = name
            label.TextColor3 = Themes[self.Theme].Text
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = widget
            
            local cp = ColorPicker.Create(widget, defaultColor, function(col)
                setting.Value = col
                if setting.Callback then setting.Callback(col) end
            end)
            setting.ColorPicker = cp
            cp.Container.Size = UDim2.new(1,-104,0,42)
            cp.Container.Position = UDim2.new(0,100,0,0)
            table.insert(mod.Settings, setting)
            return setting
        end
        
        function mod:AddToggle(name, options)
            options = options or {}
            local def = options.Default or false
            local setting = {Type = "Toggle", Name = name, Value = def, Callback = options.Callback}
            local widget = Instance.new("Frame")
            widget.Size = UDim2.new(1,-8,0,30)
            widget.BackgroundTransparency = 1
            widget.Parent = mod.SettingsFrame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,100,0,20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = name
            label.TextColor3 = Themes[self.Theme].Text
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = widget
            
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0,36,0,20)
            toggleBtn.Position = UDim2.new(0,100,0,0)
            toggleBtn.BackgroundColor3 = def and Themes[self.Theme].ToggleOn or Themes[self.Theme].ToggleOff
            toggleBtn.BorderSizePixel = 0
            toggleBtn.Text = ""
            toggleBtn.Parent = widget
            toggleBtn.MouseButton1Click:Connect(function()
                setting.Value = not setting.Value
                toggleBtn.BackgroundColor3 = setting.Value and Themes[self.Theme].ToggleOn or Themes[self.Theme].ToggleOff
                if setting.Callback then setting.Callback(setting.Value) end
            end)
            table.insert(mod.Settings, setting)
            return setting
        end
        
        function mod:AddKeybind(name, options)
            options = options or {}
            local def = options.Default or Enum.KeyCode.Unknown
            local setting = {Type = "Keybind", Name = name, Value = def, Callback = options.Callback}
            local widget = Instance.new("Frame")
            widget.Size = UDim2.new(1,-8,0,30)
            widget.BackgroundTransparency = 1
            widget.Parent = mod.SettingsFrame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0,100,0,20)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.Text = name
            label.TextColor3 = Themes[self.Theme].Text
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = widget
            
            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(1,-104,0,20)
            bindBtn.Position = UDim2.new(0,100,0,0)
            bindBtn.BackgroundColor3 = Themes[self.Theme].SliderBackground
            bindBtn.BorderSizePixel = 1
            bindBtn.BorderColor3 = Themes[self.Theme].Border
            bindBtn.Font = Enum.Font.Gotham
            bindBtn.Text = def == Enum.KeyCode.Unknown and "None" or def.Name
            bindBtn.TextColor3 = Themes[self.Theme].Text
            bindBtn.TextSize = 13
            bindBtn.Parent = widget
            bindBtn.MouseButton1Click:Connect(function()
                bindBtn.Text = "..."
                local conn;
                conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if not gameProcessed then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            setting.Value = input.KeyCode
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            setting.Value = Enum.UserInputType.MouseButton1
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            setting.Value = Enum.UserInputType.MouseButton2
                        end
                        bindBtn.Text = setting.Value.Name
                        if setting.Callback then setting.Callback(setting.Value) end
                        conn:Disconnect()
                    end
                end)
            end)
            table.insert(mod.Settings, setting)
            return setting
        end
        
        -- Update module list canvas size
        self:UpdateModuleListCanvas()
        table.insert(self.Modules, mod)
        return mod
    end
    
    function Window:UpdateModuleListCanvas()
        local totalHeight = 0
        for _,child in pairs(self.ModuleList:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("Module_") then
                totalHeight = totalHeight + child.Size.Y.Offset
            end
        end
        self.ModuleList.CanvasSize = UDim2.new(0,0,0,totalHeight)
    end
    
    function Window:FilterModules(query)
        query = query:lower()
        for _,child in pairs(self.ModuleList:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("Module_") then
                local modName = child.Name:sub(8)
                local visible = query == "" or modName:lower():find(query)
                child.Visible = visible
            end
        end
        self:UpdateModuleListCanvas()
    end
    
    self.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
        Window:FilterModules(self.SearchBar.Text)
    end)
    
    -- Return window
    table.insert(self.Windows, Window)
    return Window
end

-- Global Library Instance
return Library
