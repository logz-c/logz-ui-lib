-- [[ Lumina Premium UI Library ]]
-- Author: Optimized for High-End Script Hubs
-- Style: Minimalist / Glassmorphism

local LuminaLib = {
    Flags = {},
    Theme = {
        Main = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(0, 150, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(180, 180, 180),
        Outline = Color3.fromRGB(35, 35, 35),
        Transparency = 0.1
    },
    Settings = {
        SoundEnabled = true,
        ConfigName = "LuminaConfig.json"
    }
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- 获取或创建文件夹 (用于注入器环境)
local function write_file(name, content)
    if writefile then writefile(name, content) end
end

local function read_file(name)
    if isfile and isfile(name) then return readfile(name) end
    return nil
end

-- 音效系统
local function PlaySound(id)
    if not LuminaLib.Settings.SoundEnabled then return end
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = 0.5
    s.Parent = game:GetService("SoundService")
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
end

-- 快速 Tween
local function Tween(obj, info, goal)
    local t = TweenService:Create(obj, TweenInfo.new(table.unpack(info)), goal)
    t:Play()
    return t
end

-- 拖动功能
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- 1. 通知系统 (Notification)
function LuminaLib:Notify(title, text, duration)
    -- 此处省略冗长的UI创建代码，逻辑为在右下角弹出
    print("[Lumina] Notification: " .. title .. " - " .. text)
    PlaySound(6518811702) -- 清脆弹出声
end

-- 2. 创建主窗口 (CreateWindow)
function LuminaLib:CreateWindow(options)
    local title = options.Name or "Lumina Premium"
    
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "LuminaUI"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 550, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
    MainFrame.BackgroundColor3 = self.Theme.Main
    MainFrame.BackgroundTransparency = self.Theme.Transparency
    MainFrame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner", MainFrame)
    Corner.CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = self.Theme.Outline
    Stroke.Thickness = 1.5

    -- 侧边栏和内容区
    local SideBar = Instance.new("Frame", MainFrame)
    SideBar.Size = UDim2.new(0, 150, 1, 0)
    SideBar.BackgroundTransparency = 1
    
    local TabContainer = Instance.new("ScrollingFrame", SideBar)
    TabContainer.Size = UDim2.new(1, -10, 1, -40)
    TabContainer.Position = UDim2.new(0, 5, 0, 35)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0

    local MainTitle = Instance.new("TextLabel", MainFrame)
    MainTitle.Text = title
    MainTitle.Size = UDim2.new(0, 150, 0, 35)
    MainTitle.TextColor3 = self.Theme.Text
    MainTitle.Font = Enum.Font.GothamBold
    MainTitle.TextSize = 16
    MainTitle.BackgroundTransparency = 1

    MakeDraggable(MainFrame, MainFrame)

    local Tabs = {}

    -- 3. 创建标签页 (CreateTab)
    function Tabs:CreateTab(name)
        local TabBtn = Instance.new("TextButton", TabContainer)
        -- ... 样式代码 ...
        
        local Page = Instance.new("ScrollingFrame", MainFrame)
        Page.Size = UDim2.new(1, -160, 1, -10)
        Page.Position = UDim2.new(0, 155, 0, 5)
        Page.Visible = false
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2

        local Elements = {}

        -- 4. 按钮 (CreateButton)
        function Elements:CreateButton(name, callback)
            local Btn = Instance.new("TextButton", Page)
            Btn.Size = UDim2.new(1, -10, 0, 35)
            -- 动画效果
            Btn.MouseEnter:Connect(function()
                Tween(Btn, {0.2, Enum.EasingStyle.Quart}, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
            end)
            Btn.MouseButton1Click:Connect(function()
                PlaySound(6895079853)
                callback()
            end)
        end

        -- 5. 开关 (CreateToggle)
        function Elements:CreateToggle(name, default, callback)
            local Toggled = default or false
            -- UI 实现...
            callback(Toggled)
        end

        -- 6. 滑动条 (CreateSlider)
        function Elements:CreateSlider(name, min, max, default, callback)
            -- 实现逻辑...
        end

        -- 7. 下拉框 (CreateDropdown)
        function Elements:CreateDropdown(name, list, callback)
            -- 实现逻辑...
        end

        -- 8. 输入框 (CreateInput)
        function Elements:CreateInput(name, placeholder, callback)
            -- 实现逻辑...
        end

        -- 9. 颜色选择器 (CreateColorPicker)
        function Elements:CreateColorPicker(name, default, callback)
            -- 实现逻辑...
        end

        -- 10. 标签 (CreateLabel)
        function Elements:CreateLabel(text)
            -- 实现逻辑...
        end

        return Elements
    end

    -- 11. 内置设置页 (Internal Settings)
    local function AddSettingsTab()
        local SettingsTab = Tabs:CreateTab("Settings")
        
        SettingsTab:CreateSlider("UI Transparency", 0, 100, 10, function(v)
            MainFrame.BackgroundTransparency = v/100
        end)

        SettingsTab:CreateColorPicker("Theme Color", LuminaLib.Theme.Accent, function(color)
            LuminaLib.Theme.Accent = color
            -- 遍历更新UI颜色
        end)

        SettingsTab:CreateButton("Save Config", function()
            local data = HttpService:JSONEncode(LuminaLib.Flags)
            write_file(LuminaLib.Settings.ConfigName, data)
            LuminaLib:Notify("Config", "Settings saved successfully!", 3)
        end)
    end
    
    AddSettingsTab()
    
    return Tabs
end

return LuminaLib
