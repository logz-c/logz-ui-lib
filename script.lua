-- Roblox UI Library by Log_quick
-- Complete Single File Implementation

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local UILibrary = {
    Version = "1.0.0",
    Author = "Log_quick",
    Windows = {},
    Themes = {},
    Settings = {},
    Notifications = {},
    IsMobile = false,
}

-- ==================== 移动端检测 ====================
local function DetectMobile()
    local UserAgent = game:HttpGet("https://httpbin.org/user-agent")
    return UserInputService.TouchEnabled and #UserInputService:GetConnectedGamepads() == 0
end

UILibrary.IsMobile = DetectMobile()

-- ==================== 主题系统 ====================
UILibrary.Themes = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 20),
        Secondary = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(66, 135, 245),
        Border = Color3.fromRGB(255, 255, 255),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(66, 135, 245),
        Border = Color3.fromRGB(0, 0, 0),
    },
    Purple = {
        Background = Color3.fromRGB(25, 20, 35),
        Secondary = Color3.fromRGB(35, 30, 45),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(150, 100, 255),
        Border = Color3.fromRGB(150, 100, 255),
    },
    Cyberpunk = {
        Background = Color3.fromRGB(10, 10, 20),
        Secondary = Color3.fromRGB(15, 15, 30),
        Text = Color3.fromRGB(0, 255, 200),
        Accent = Color3.fromRGB(255, 0, 150),
        Border = Color3.fromRGB(0, 255, 200),
    }
}

-- ==================== 存储系统 ====================
local function LoadSettings()
    local success, data = pcall(function()
        local stored = readfile("UILibrary_Settings.json")
        return HttpService:JSONDecode(stored)
    end)
    return success and data or {
        Theme = "Dark",
        Opacity = 1,
        BorderColor = Color3.fromRGB(255, 255, 255),
        BorderMode = "Solid",
        UISize = 1,
        Position = UDim2.new(0, 100, 0, 100),
        ShowFloatingStats = true,
        BackgroundImage = "",
        SoundEnabled = true,
    }
end

local function SaveSettings()
    writefile("UILibrary_Settings.json", HttpService:JSONEncode(UILibrary.Settings))
end

UILibrary.Settings = LoadSettings()

-- ==================== 声音系统 ====================
local SoundManager = {}

function SoundManager:PlaySound(soundName, volume)
    if not UILibrary.Settings.SoundEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.Volume = volume or 0.5
    sound.Parent = workspace
    
    -- 使用SoundId (可以替换为实际的音效ID)
    local soundIds = {
        click = "rbxassetid://12221967",
        open = "rbxassetid://12221944",
        close = "rbxassetid://12221960",
        notify = "rbxassetid://12221967",
    }
    
    sound.SoundId = soundIds[soundName] or soundIds.click
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 0.5)
end

-- ==================== UI创建基础 ====================
local function CreateWindow(title, subtitle)
    local screenSize = game:GetService("UserInputService"):GetMouseLocation()
    local mainWindow = Instance.new("ScreenGui")
    mainWindow.Name = "UILibraryWindow_" .. title
    mainWindow.ResetOnSpawn = false
    mainWindow.Enabled = true
    
    if UILibrary.IsMobile then
        mainWindow.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    else
        mainWindow.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- 主容器
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 300 * UILibrary.Settings.UISize, 0, 400 * UILibrary.Settings.UISize)
    container.Position = UILibrary.Settings.Position
    container.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Background
    container.BackgroundTransparency = 1 - UILibrary.Settings.Opacity
    container.BorderSizePixel = 2
    container.BorderColor3 = UILibrary.Settings.BorderColor
    container.ClipsDescendants = true
    container.Parent = mainWindow
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = container
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -40, 0, 30)
    titleText.Position = UDim2.new(0, 10, 0, 5)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    titleText.TextSize = 18 * UILibrary.Settings.UISize
    titleText.Text = title
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    if subtitle then
        local subtitleText = Instance.new("TextLabel")
        subtitleText.Name = "Subtitle"
        subtitleText.Size = UDim2.new(1, -40, 0, 15)
        subtitleText.Position = UDim2.new(0, 10, 0, 32)
        subtitleText.BackgroundTransparency = 1
        subtitleText.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
        subtitleText.TextSize = 12 * UILibrary.Settings.UISize
        subtitleText.Text = subtitle
        subtitleText.TextXAlignment = Enum.TextXAlignment.Left
        subtitleText.Font = Enum.Font.Gotham
        subtitleText.Parent = titleBar
    end
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Text = "✕"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        SoundManager:PlaySound("close", 0.5)
        mainWindow:Destroy()
    end)
    
    -- 拖动功能
    local dragging = false
    local dragStart = Vector2.new()
    local windowStart = UDim2.new()
    
    titleBar.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = UserInputService:GetMouseLocation()
            windowStart = container.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - dragStart
            local newPos = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + delta.X, 
                                     windowStart.Y.Scale, windowStart.Y.Offset + delta.Y)
            container.Position = newPos
            UILibrary.Settings.Position = newPos
            SaveSettings()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- 内容容器
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -10, 1, -60)
    contentFrame.Position = UDim2.new(0, 5, 0, 55)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = container
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentFrame
    
    local window = {
        MainWindow = mainWindow,
        Container = container,
        Content = contentFrame,
        Title = titleText,
        SoundManager = SoundManager,
        Sections = {},
    }
    
    table.insert(UILibrary.Windows, window)
    SoundManager:PlaySound("open", 0.6)
    
    return window
end

-- ==================== 区域系统 ====================
function UILibrary:CreateSection(window, sectionName)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. sectionName
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    section.BorderSizePixel = 1
    section.BorderColor3 = UILibrary.Settings.BorderColor
    section.Parent = window.Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "SectionTitle"
    sectionTitle.Size = UDim2.new(1, -10, 0, 25)
    sectionTitle.Position = UDim2.new(0, 5, 0, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    sectionTitle.TextSize = 14 * UILibrary.Settings.UISize
    sectionTitle.Text = sectionName
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Parent = section
    
    local sectionContent = Instance.new("Frame")
    sectionContent.Name = "SectionContent"
    sectionContent.Size = UDim2.new(1, -10, 1, -30)
    sectionContent.Position = UDim2.new(0, 5, 0, 28)
    sectionContent.BackgroundTransparency = 1
    sectionContent.Parent = section
    
    local sectionLayout = Instance.new("UIListLayout")
    sectionLayout.Padding = UDim.new(0, 5)
    sectionLayout.Parent = sectionContent
    
    local sectionObj = {
        Frame = section,
        Content = sectionContent,
        Title = sectionTitle,
        Items = {},
    }
    
    table.insert(window.Sections, sectionObj)
    return sectionObj
end

-- ==================== UI元素 ====================

-- 按钮
function UILibrary:CreateButton(section, buttonText, callback)
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = "Button_" .. buttonText
    buttonFrame.Size = UDim2.new(1, 0, 0, 35)
    buttonFrame.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    buttonFrame.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    buttonFrame.TextSize = 12 * UILibrary.Settings.UISize
    buttonFrame.Text = buttonText
    buttonFrame.Font = Enum.Font.GothamBold
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = section.Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = buttonFrame
    
    buttonFrame.MouseButton1Click:Connect(function()
        SoundManager:PlaySound("click", 0.5)
        if callback then callback() end
    end)
    
    buttonFrame.MouseEnter:Connect(function()
        buttonFrame.BackgroundColor3 = Color3.fromHSV(
            UILibrary.Themes[UILibrary.Settings.Theme].Accent:GetHSV()
        )
    end)
    
    return buttonFrame
end

-- 开关
function UILibrary:CreateToggle(section, toggleText, defaultValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. toggleText
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = section.Content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    label.TextSize = 12 * UILibrary.Settings.UISize
    label.Text = toggleText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = toggleFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 35, 0, 20)
    toggleButton.Position = UDim2.new(1, -35, 0, 5)
    toggleButton.BackgroundColor3 = defaultValue and UILibrary.Themes[UILibrary.Settings.Theme].Accent or Color3.fromRGB(100, 100, 100)
    toggleButton.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    toggleButton.TextSize = 10
    toggleButton.Text = defaultValue and "ON" or "OFF"
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggleButton
    
    local isToggled = defaultValue
    
    toggleButton.MouseButton1Click:Connect(function()
        SoundManager:PlaySound("click", 0.5)
        isToggled = not isToggled
        toggleButton.BackgroundColor3 = isToggled and UILibrary.Themes[UILibrary.Settings.Theme].Accent or Color3.fromRGB(100, 100, 100)
        toggleButton.Text = isToggled and "ON" or "OFF"
        if callback then callback(isToggled) end
    end)
    
    return {Frame = toggleFrame, Button = toggleButton, GetValue = function() return isToggled end}
end

-- 滑块
function UILibrary:CreateSlider(section, sliderText, minValue, maxValue, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider_" .. sliderText
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = section.Content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    label.TextSize = 12 * UILibrary.Settings.UISize
    label.Text = sliderText .. ": " .. tostring(math.floor(defaultValue))
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = sliderFrame
    
    local sliderBackground = Instance.new("Frame")
    sliderBackground.Name = "Background"
    sliderBackground.Size = UDim2.new(1, 0, 0, 5)
    sliderBackground.Position = UDim2.new(0, 0, 0, 25)
    sliderBackground.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sliderBackground.BorderSizePixel = 0
    sliderBackground.Parent = sliderFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBackground
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBackground
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "Slider"
    sliderButton.Size = UDim2.new(0, 15, 0, 15)
    sliderButton.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), -7.5, 0, 20)
    sliderButton.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = sliderButton
    
    local currentValue = defaultValue
    local dragging = false
    
    sliderButton.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local relativeX = math.clamp(mouse.X - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
            local percentage = relativeX / sliderBackground.AbsoluteSize.X
            currentValue = math.floor(minValue + (maxValue - minValue) * percentage)
            
            sliderButton.Position = UDim2.new(percentage, -7.5, 0, 20)
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            label.Text = sliderText .. ": " .. tostring(currentValue)
            
            if callback then callback(currentValue) end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return {Frame = sliderFrame, GetValue = function() return currentValue end}
end

-- 输入框
function UILibrary:CreateInput(section, inputText, placeholder, callback)
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "Input_" .. inputText
    inputFrame.Size = UDim2.new(1, 0, 0, 50)
    inputFrame.BackgroundTransparency = 1
    inputFrame.Parent = section.Content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    label.TextSize = 12 * UILibrary.Settings.UISize
    label.Text = inputText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = inputFrame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(1, 0, 0, 25)
    inputBox.Position = UDim2.new(0, 0, 0, 23)
    inputBox.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    inputBox.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    inputBox.PlaceholderText = placeholder
    inputBox.Text = ""
    inputBox.TextSize = 12
    inputBox.Font = Enum.Font.Gotham
    inputBox.BorderSizePixel = 1
    inputBox.BorderColor3 = UILibrary.Settings.BorderColor
    inputBox.Parent = inputFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputBox
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            callback(inputBox.Text)
        end
    end)
    
    return {Frame = inputFrame, TextBox = inputBox, GetValue = function() return inputBox.Text end}
end

-- 下拉菜单
function UILibrary:CreateDropdown(section, dropdownText, options, defaultIndex, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = "Dropdown_" .. dropdownText
    dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = section.Content
    
    local selectedValue = options[defaultIndex or 1]
    
    local button = Instance.new("TextButton")
    button.Name = "DropdownButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    button.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    button.TextSize = 12
    button.Text = selectedValue .. " ▼"
    button.Font = Enum.Font.Gotham
    button.BorderSizePixel = 1
    button.BorderColor3 = UILibrary.Settings.BorderColor
    button.Parent = dropdownFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
    local isOpen = false
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name = "OptionsFrame"
    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 30)
    optionsFrame.Position = UDim2.new(0, 0, 1, 2)
    optionsFrame.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    optionsFrame.BorderSizePixel = 1
    optionsFrame.BorderColor3 = UILibrary.Settings.BorderColor
    optionsFrame.Visible = false
    optionsFrame.Parent = dropdownFrame
    
    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UDim.new(0, 4)
    optionsCorner.Parent = optionsFrame
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 0)
    optionsLayout.Parent = optionsFrame
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
        optionButton.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
        optionButton.TextSize = 12
        optionButton.Text = option
        optionButton.Font = Enum.Font.Gotham
        optionButton.BorderSizePixel = 0
        optionButton.Parent = optionsFrame
        
        optionButton.MouseButton1Click:Connect(function()
            SoundManager:PlaySound("click", 0.5)
            selectedValue = option
            button.Text = selectedValue .. " ▼"
            optionsFrame.Visible = false
            isOpen = false
            if callback then callback(selectedValue) end
        end)
    end
    
    button.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsFrame.Visible = isOpen
    end)
    
    return {Frame = dropdownFrame, GetValue = function() return selectedValue end}
end

-- HSV颜色盘
function UILibrary:CreateColorPicker(section, colorText, defaultColor, callback)
    local colorFrame = Instance.new("Frame")
    colorFrame.Name = "ColorPicker_" .. colorText
    colorFrame.Size = UDim2.new(1, 0, 0, 180)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = section.Content
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    label.TextSize = 12 * UILibrary.Settings.UISize
    label.Text = colorText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = colorFrame
    
    -- SV选择器
    local svPicker = Instance.new("Frame")
    svPicker.Name = "SVPicker"
    svPicker.Size = UDim2.new(1, 0, 0, 120)
    svPicker.Position = UDim2.new(0, 0, 0, 25)
    svPicker.BackgroundColor3 = defaultColor
    svPicker.BorderSizePixel = 1
    svPicker.BorderColor3 = UILibrary.Settings.BorderColor
    svPicker.Parent = colorFrame
    
    local svCorner = Instance.new("UICorner")
    svCorner.CornerRadius = UDim.new(0, 4)
    svCorner.Parent = svPicker
    
    local svCursor = Instance.new("Frame")
    svCursor.Name = "Cursor"
    svCursor.Size = UDim2.new(0, 8, 0, 8)
    svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    svCursor.BorderSizePixel = 1
    svCursor.BorderColor3 = Color3.fromRGB(0, 0, 0)
    svCursor.Parent = svPicker
    
    local currentColor = defaultColor
    local h, s, v = defaultColor:GetHSV()
    
    local function UpdateColor()
        if callback then callback(currentColor) end
    end
    
    svPicker.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local relX = math.clamp((mouse.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
            local relY = math.clamp((mouse.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
            
            s = relX
            v = 1 - relY
            currentColor = Color3.fromHSV(h, s, v)
            
            svCursor.Position = UDim2.new(relX, -4, relY, -4)
            svPicker.BackgroundColor3 = currentColor
            UpdateColor()
        end
    end)
    
    return {Frame = colorFrame, GetValue = function() return currentColor end}
end

-- 标签
function UILibrary:CreateLabel(section, labelText)
    local labelFrame = Instance.new("TextLabel")
    labelFrame.Name = "Label_" .. labelText
    labelFrame.Size = UDim2.new(1, 0, 0, 25)
    labelFrame.BackgroundTransparency = 1
    labelFrame.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    labelFrame.TextSize = 12 * UILibrary.Settings.UISize
    labelFrame.Text = labelText
    labelFrame.TextXAlignment = Enum.TextXAlignment.Left
    labelFrame.Font = Enum.Font.Gotham
    labelFrame.Parent = section.Content
    
    return labelFrame
end

-- 通知系统
function UILibrary:SendNotification(title, message, duration, soundEnabled)
    duration = duration or 3
    
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "Notification"
    notificationGui.ResetOnSpawn = false
    notificationGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 300, 0, 100)
    notificationFrame.Position = UDim2.new(1, -320, 0, 20)
    notificationFrame.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Secondary
    notificationFrame.BorderSizePixel = 2
    notificationFrame.BorderColor3 = UILibrary.Settings.BorderColor
    notificationFrame.Parent = notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 30)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    titleLabel.TextSize = 14
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notificationFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -10, 0, 55)
    messageLabel.Position = UDim2.new(0, 5, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Text
    messageLabel.TextSize = 12
    messageLabel.Text = message
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Parent = notificationFrame
    
    if soundEnabled then
        SoundManager:PlaySound("notify", 0.6)
    end
    
    task.wait(duration)
    notificationGui:Destroy()
end

-- ==================== UI设置面板 ====================
function UILibrary:CreateSettingsPanel()
    local settingsWindow = CreateWindow("UI Settings", "Customization Panel")
    
    -- 主题部分
    local themeSection = self:CreateSection(settingsWindow, "Theme")
    
    self:CreateDropdown(themeSection, "Select Theme", {"Dark", "Light", "Purple", "Cyberpunk"}, 1, function(value)
        UILibrary.Settings.Theme = value
        SaveSettings()
        self:SendNotification("Theme Changed", "Theme set to " .. value, 2)
    end)
    
    -- 颜色选择
    local colorSection = self:CreateSection(settingsWindow, "Custom Color")
    self:CreateColorPicker(colorSection, "Pick Custom Color", Color3.fromRGB(66, 135, 245), function(color)
        UILibrary.Settings.BorderColor = color
        SaveSettings()
    end)
    
    -- 透明度
    local opacitySection = self:CreateSection(settingsWindow, "Opacity")
    self:CreateSlider(opacitySection, "UI Opacity", 0.3, 1, UILibrary.Settings.Opacity, function(value)
        UILibrary.Settings.Opacity = value / 100
        SaveSettings()
    end)
    
    -- 大小
    local sizeSection = self:CreateSection(settingsWindow, "UI Size")
    self:CreateSlider(sizeSection, "UI Scale", 0.5, 2, UILibrary.Settings.UISize, function(value)
        UILibrary.Settings.UISize = value / 100
        SaveSettings()
    end)
    
    -- 声音
    local soundSection = self:CreateSection(settingsWindow, "Sound")
    self:CreateToggle(soundSection, "Enable Sound", UILibrary.Settings.SoundEnabled, function(value)
        UILibrary.Settings.SoundEnabled = value
        SaveSettings()
    end)
    
    -- 浮动统计
    local statsSection = self:CreateSection(settingsWindow, "Statistics")
    self:CreateToggle(statsSection, "Show Floating Stats", UILibrary.Settings.ShowFloatingStats, function(value)
        UILibrary.Settings.ShowFloatingStats = value
        SaveSettings()
    end)
    
    -- 关于
    local aboutSection = self:CreateSection(settingsWindow, "About")
    self:CreateLabel(aboutSection, "UI Library v" .. UILibrary.Version)
    self:CreateLabel(aboutSection, "Author: " .. UILibrary.Author)
    
    self:SendNotification("Welcome!", "UI Library loaded successfully!", 3)
    
    return settingsWindow
end

-- ==================== 浮动统计窗口 ====================
function UILibrary:CreateFloatingStats()
    local statsGui = Instance.new("ScreenGui")
    statsGui.Name = "FloatingStats"
    statsGui.ResetOnSpawn = false
    statsGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0, 150, 0, 80)
    statsFrame.Position = UDim2.new(1, -160, 1, -90)
    statsFrame.BackgroundColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Background
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.BorderSizePixel = 1
    statsFrame.BorderColor3 = UILibrary.Settings.BorderColor
    statsFrame.Parent = statsGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = statsFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = statsFrame
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -10, 0, 20)
    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    fpsLabel.TextSize = 11
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.Parent = statsFrame
    
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, -10, 0, 20)
    pingLabel.BackgroundTransparency = 1
    pingLabel.TextColor3 = UILibrary.Themes[UILibrary.Settings.Theme].Accent
    pingLabel.TextSize = 11
    pingLabel.Text = "Ping: 0ms"
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.Parent = statsFrame
    
    local lastUpdate = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastUpdate >= 1 then
            fpsLabel.Text = "FPS: " .. frameCount
            frameCount = 0
            lastUpdate = currentTime
        end
        
        local ping = Players:FindFirstChild(Players.LocalPlayer.Name)
        if ping then
            pingLabel.Text = "Ping: " .. tostring(math.floor(game:GetService("Stats").Network.ServerReplicator:FindFirstChild("DataReceiveKbps") and game:GetService("Stats").Network.ServerReplicator.DataReceiveKbps.Value or 0)) .. "ms"
        end
    end)
    
    return statsGui
end

-- ==================== API导出 ====================
return {
    CreateWindow = function(title, subtitle) return CreateWindow(title, subtitle) end,
    CreateSection = function(window, name) return UILibrary:CreateSection(window, name) end,
    CreateButton = function(section, text, callback) return UILibrary:CreateButton(section, text, callback) end,
    CreateToggle = function(section, text, default, callback) return UILibrary:CreateToggle(section, text, default, callback) end,
    CreateSlider = function(section, text, min, max, default, callback) return UILibrary:CreateSlider(section, text, min, max, default, callback) end,
    CreateInput = function(section, text, placeholder, callback) return UILibrary:CreateInput(section, text, placeholder, callback) end,
    CreateDropdown = function(section, text, options, default, callback) return UILibrary:CreateDropdown(section, text, options, default, callback) end,
    CreateColorPicker = function(section, text, default, callback) return UILibrary:CreateColorPicker(section, text, default, callback) end,
    CreateLabel = function(section, text) return UILibrary:CreateLabel(section, text) end,
    SendNotification = function(title, message, duration) return UILibrary:SendNotification(title, message, duration) end,
    CreateSettingsPanel = function() return UILibrary:CreateSettingsPanel() end,
    CreateFloatingStats = function() return UILibrary:CreateFloatingStats() end,
    IsMobile = UILibrary.IsMobile,
    Version = UILibrary.Version,
    Author = UILibrary.Author,
}
