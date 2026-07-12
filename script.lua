--// Advanced Minimal UI Library
--// Made for Script Hub Injection

local UILib = {}
UILib.__index = UILib

--// Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// Default Settings
UILib.Settings = {
    ThemeColor = Color3.fromRGB(0,170,255),
    Transparency = 0.1,
    SoundEnabled = true
}

UILib.Config = {}

--// Sound
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://9118828564"
ClickSound.Volume = 1

function UILib:PlaySound()
    if self.Settings.SoundEnabled then
        ClickSound:Play()
    end
end

--// Tween helper
function UILib:Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

--// Notification
function UILib:Notify(title, text, duration)
    duration = duration or 3
    
    local Notif = Instance.new("TextLabel", self.ScreenGui)
    Notif.Size = UDim2.new(0,300,0,60)
    Notif.Position = UDim2.new(1,-320,1,-100)
    Notif.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Notif.BackgroundTransparency = 0.2
    Notif.Text = title.." - "..text
    Notif.TextColor3 = Color3.new(1,1,1)
    Notif.Font = Enum.Font.Gotham
    Notif.TextSize = 14
    
    self:Tween(Notif,{Position = UDim2.new(1,-320,1,-170)},0.4)
    
    task.delay(duration,function()
        self:Tween(Notif,{Position = UDim2.new(1,-320,1,-100)},0.4)
        task.wait(0.4)
        Notif:Destroy()
    end)
end

--// Create Window
function UILib:CreateWindow(title)
    local self = setmetatable({}, UILib)

    local ScreenGui = Instance.new("ScreenGui", PlayerGui)
    ScreenGui.Name = "AdvancedUILib"
    self.ScreenGui = ScreenGui

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0,600,0,400)
    Main.Position = UDim2.new(0.5,-300,0.5,-200)
    Main.BackgroundColor3 = Color3.fromRGB(15,15,15)
    Main.BackgroundTransparency = self.Settings.Transparency
    Main.BorderSizePixel = 0
    self.Main = Main

    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0,12)

    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1,0,0,40)
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextColor3 = self.Settings.ThemeColor
    Title.BackgroundTransparency = 1

    -- Dragging
    local dragging = false
    local dragInput, mousePos, framePos
    
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = Main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - mousePos
            Main.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self.Tabs = {}

    return self
end

--// Tab
function UILib:AddTab(name)
    local Tab = Instance.new("Frame", self.Main)
    Tab.Size = UDim2.new(1,-20,1,-60)
    Tab.Position = UDim2.new(0,10,0,50)
    Tab.BackgroundTransparency = 1
    
    self.Tabs[name] = Tab
    return Tab
end

--// Section
function UILib:AddSection(tab, text)
    local Label = Instance.new("TextLabel", tab)
    Label.Size = UDim2.new(1,0,0,30)
    Label.Text = text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.TextColor3 = self.Settings.ThemeColor
    Label.BackgroundTransparency = 1
end

--// Button
function UILib:AddButton(tab, text, callback)
    local Button = Instance.new("TextButton", tab)
    Button.Size = UDim2.new(0,200,0,35)
    Button.Text = text
    Button.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Button.TextColor3 = Color3.new(1,1,1)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14

    Instance.new("UICorner", Button)

    Button.MouseButton1Click:Connect(function()
        self:PlaySound()
        self:Tween(Button,{BackgroundColor3 = self.Settings.ThemeColor},0.2)
        task.wait(0.2)
        self:Tween(Button,{BackgroundColor3 = Color3.fromRGB(30,30,30)},0.2)
        callback()
    end)
end

--// Toggle
function UILib:AddToggle(tab, text, callback)
    local Toggle = Instance.new("TextButton", tab)
    Toggle.Size = UDim2.new(0,200,0,35)
    Toggle.Text = text.." : OFF"
    Toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Toggle.TextColor3 = Color3.new(1,1,1)
    
    local state = false
    
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.Text = text.." : "..(state and "ON" or "OFF")
        self:PlaySound()
        callback(state)
    end)
end

--// Slider (简化版)
function UILib:AddSlider(tab, text, min, max, callback)
    local Slider = Instance.new("TextButton", tab)
    Slider.Size = UDim2.new(0,200,0,35)
    Slider.Text = text.." : "..min
    Slider.BackgroundColor3 = Color3.fromRGB(30,30,30)
    
    local value = min
    Slider.MouseButton1Click:Connect(function()
        value = math.clamp(value + 1, min, max)
        Slider.Text = text.." : "..value
        callback(value)
    end)
end

--// Theme
function UILib:SetTheme(color)
    self.Settings.ThemeColor = color
end

--// Transparency
function UILib:SetTransparency(value)
    self.Settings.Transparency = value
    self.Main.BackgroundTransparency = value
end

--// Config
function UILib:SaveConfig(name)
    writefile(name..".json", HttpService:JSONEncode(self.Config))
end

function UILib:LoadConfig(name)
    if isfile(name..".json") then
        self.Config = HttpService:JSONDecode(readfile(name..".json"))
    end
end

return UILib
