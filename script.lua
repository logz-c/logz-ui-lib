--[[
    UI Library Name: Log_quick UI Hub
    Author: Log_quick
    Description: Advanced, Mobile-friendly, Feature-rich UI Library for Roblox Injectors.
]]

local LogQuickUI = {}

-- [[ Services ]] --
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- [[ Environment Setup ]] --
local ParentGui = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(CoreGui)) or CoreGui
local ExecutorName = (identifyexecutor and identifyexecutor()) or "Unknown Executor"

-- [[ Mobile Detection & Scaling ]] --
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local ScaleMultiplier = isMobile and 1.3 or 1.0 -- 手机端放大UI
local FontSize = {
    Title = 18 * ScaleMultiplier,
    Subtitle = 14 * ScaleMultiplier,
    Normal = 14 * ScaleMultiplier,
    Small = 12 * ScaleMultiplier
}

-- [[ Sounds ]] --
local Sounds = {
    Hover = "rbxassetid://6895079638",
    Click = "rbxassetid://6895079853",
    Notify = "rbxassetid://2865227271",
    Error = "rbxassetid://6895080073"
}

local function PlaySound(soundType)
    local sound = Instance.new("Sound")
    sound.SoundId = Sounds[soundType] or Sounds.Click
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    game.Debris:AddItem(sound, 2)
end

-- [[ Utility: Create Instance ]] --
local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        if type(k) == "number" then
            v.Parent = inst
        else
            inst[k] = v
        end
    end
    return inst
end

-- [[ Utility: Tweening ]] --
local function Tween(instance, properties, duration)
    duration = duration or 0.2
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- [[ Utility: Draggable & Clamping ]] --
local function MakeDraggable(topbar, frame)
    local dragging, dragInput, dragStart, startPos
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            -- UI不会超出屏幕计算
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            
            local maxX = Camera.ViewportSize.X - frame.AbsoluteSize.X
            local maxY = Camera.ViewportSize.Y - frame.AbsoluteSize.Y
            
            newX = math.clamp(newX, 0, maxX)
            newY = math.clamp(newY, 0, maxY)
            
            Tween(frame, {Position = UDim2.new(0, newX, 0, newY)}, 0.1)
        end
    end)
end

-- [[ Theme & Config System ]] --
LogQuickUI.Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Secondary = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(85, 170, 255),
    Text = Color3.fromRGB(255, 255, 255),
    DarkText = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(40, 40, 45)
}

LogQuickUI.Config = {
    Transparency = 0,
    RainbowBorder = false,
    ScriptAuthor = "Unknown"
}

-- [[ ScreenGui Setup ]] --
local ScreenGui = Create("ScreenGui", {
    Name = "LogQuick_Hub",
    Parent = ParentGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false
})

-- [[ Floating Status (FPS/Ping) ]] --
local StatusUI = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 120, 0, 40),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = LogQuickUI.Theme.Background,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Visible = true,
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
    Create("TextLabel", {
        Name = "Display",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "FPS: 0 | Ping: 0ms",
        TextColor3 = LogQuickUI.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = FontSize.Small
    })
})
MakeDraggable(StatusUI, StatusUI)

RunService.RenderStepped:Connect(function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = "0"
    pcall(function() ping = string.split(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), " ")[1] end)
    StatusUI.Display.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms"
end)

function LogQuickUI:SetStatusVisible(state)
    StatusUI.Visible = state
end

-- [[ Watermark System ]] --
local WatermarkFrame = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 200, 0, 30),
    Position = UDim2.new(0.5, -100, 0, 10),
    BackgroundColor3 = LogQuickUI.Theme.Background,
    BackgroundTransparency = 0.2,
    Visible = false,
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
    Create("UIStroke", {Color = LogQuickUI.Theme.Accent, Thickness = 1}),
    Create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Log_quick Hub",
        TextColor3 = LogQuickUI.Theme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = FontSize.Small
    })
})
function LogQuickUI:SetWatermark(text, visible)
    WatermarkFrame.Text.Text = text
    WatermarkFrame.Visible = visible
end

-- [[ Notification System ]] --
local NotifContainer = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 250, 1, -20),
    Position = UDim2.new(1, -260, 0, 10),
    BackgroundTransparency = 1,
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10)
    })
})

function LogQuickUI:Notify(title, text, duration)
    PlaySound("Notify")
    duration = duration or 3
    local Notif = Create("Frame", {
        Parent = NotifContainer,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = LogQuickUI.Theme.Background,
        BackgroundTransparency = 1,
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {Color = LogQuickUI.Theme.Accent, Thickness = 1}),
        Create("TextLabel", {
            Name = "Title",
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = LogQuickUI.Theme.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = FontSize.Normal,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1
        }),
        Create("TextLabel", {
            Name = "Desc",
            Position = UDim2.new(0, 10, 0, 25),
            Size = UDim2.new(1, -20, 0, 30),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = LogQuickUI.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = FontSize.Small,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            TextTransparency = 1
        })
    })
    
    Tween(Notif, {BackgroundTransparency = 0.1}, 0.3)
    Tween(Notif.Title, {TextTransparency = 0}, 0.3)
    Tween(Notif.Desc, {TextTransparency = 0}, 0.3)
    
    task.spawn(function()
        task.wait(duration)
        Tween(Notif, {BackgroundTransparency = 1}, 0.3)
        Tween(Notif.Title, {TextTransparency = 1}, 0.3)
        local t = Tween(Notif.Desc, {TextTransparency = 1}, 0.3)
        t.Completed:Wait()
        Notif:Destroy()
    end)
end

-- [[ Key System ]] --
function LogQuickUI:CreateKeySystem(expectedKey, title, callback)
    local KeyOverlay = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.3,
        Active = true
    })
    local KeyBox = Create("Frame", {
        Parent = KeyOverlay,
        Size = UDim2.new(0, 300, 0, 150),
        Position = UDim2.new(0.5, -150, 0.5, -75),
        BackgroundColor3 = LogQuickUI.Theme.Background,
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = LogQuickUI.Theme.Accent, Thickness = 2}),
        Create("TextLabel", {
            Text = title or "Key System",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            TextColor3 = LogQuickUI.Theme.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = FontSize.Title
        }),
        Create("TextBox", {
            Name = "Input",
            Size = UDim2.new(0.9, 0, 0, 35),
            Position = UDim2.new(0.05, 0, 0, 50),
            BackgroundColor3 = LogQuickUI.Theme.Secondary,
            TextColor3 = LogQuickUI.Theme.Text,
            PlaceholderText = "Enter Key Here...",
            Text = "",
            Font = Enum.Font.Gotham,
            TextSize = FontSize.Normal,
            Create("UICorner", {CornerRadius = UDim.new(0, 4)})
        })
    })
    
    local Submit = Create("TextButton", {
        Parent = KeyBox,
        Size = UDim2.new(0.9, 0, 0, 35),
        Position = UDim2.new(0.05, 0, 0, 95),
        BackgroundColor3 = LogQuickUI.Theme.Accent,
        Text = "Submit",
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold,
        TextSize = FontSize.Normal,
        Create("UICorner", {CornerRadius = UDim.new(0, 4)})
    })
    
    Submit.MouseButton1Click:Connect(function()
        PlaySound("Click")
        if KeyBox.Input.Text == expectedKey then
            LogQuickUI:Notify("Success", "Key Accepted!", 3)
            Tween(KeyOverlay, {BackgroundTransparency = 1}, 0.5)
            Tween(KeyBox, {BackgroundTransparency = 1}, 0.5).Completed:Wait()
            KeyOverlay:Destroy()
            callback(true)
        else
            PlaySound("Error")
            KeyBox.Input.Text = ""
            KeyBox.Input.PlaceholderText = "Incorrect Key!"
        end
    end)
end

-- [[ Main Window Creation ]] --
function LogQuickUI:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "Log_quick Hub"
    local Subtitle = options.Subtitle or "Premium Injector UI"
    local DefaultSize = isMobile and UDim2.new(0, 500, 0, 300) or UDim2.new(0, 600, 0, 400)
    
    LogQuickUI.Config.ScriptAuthor = options.Author or "Unknown"

    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        Size = DefaultSize,
        Position = UDim2.new(0.5, -DefaultSize.X.Offset/2, 0.5, -DefaultSize.Y.Offset/2),
        BackgroundColor3 = LogQuickUI.Theme.Background,
        ClipsDescendants = true,
        Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })
    
    local MainStroke = Create("UIStroke", {
        Parent = MainFrame,
        Color = LogQuickUI.Theme.Accent,
        Thickness = 2
    })

    -- Rainbow Border Logic
    RunService.RenderStepped:Connect(function()
        if LogQuickUI.Config.RainbowBorder then
            local hue = tick() % 5 / 5
            MainStroke.Color = Color3.fromHSV(hue, 1, 1)
        elseif MainStroke.Color ~= LogQuickUI.Theme.Accent then
            MainStroke.Color = LogQuickUI.Theme.Accent
        end
        MainFrame.BackgroundTransparency = LogQuickUI.Config.Transparency
    end)

    -- Topbar
    local Topbar = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    })
    MakeDraggable(Topbar, MainFrame)
    
    Create("TextLabel", {
        Parent = Topbar,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = Title .. " | <font color='rgb(150,150,150)'>" .. Subtitle .. "</font>",
        RichText = true,
        TextColor3 = LogQuickUI.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = FontSize.Title,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Background Image Support
    local BgImage = Create("ImageLabel", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 0,
        BackgroundTransparency = 1,
        ImageTransparency = 0.8,
        Visible = false
    })

    -- Content Area
    local TabContainer = Create("ScrollingFrame", {
        Parent = MainFrame,
        Size = UDim2.new(0, 130, 1, -50),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Create("UIListLayout", {Padding = UDim.new(0, 5)})
    })

    local PageContainer = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -150, 1, -50),
        Position = UDim2.new(0, 140, 0, 40),
        BackgroundTransparency = 1
    })

    -- Loading Animation
    MainFrame.Size = UDim2.new(0,0,0,0)
    Tween(MainFrame, {Size = DefaultSize}, 0.8)
    LogQuickUI:Notify("Welcome!", "Injected via " .. ExecutorName, 4)

    local Window = {
        CurrentTab = nil,
        Tabs = {}
    }

    -- Set Background API
    function Window:SetBackground(imageId, transparency)
        BgImage.Image = "rbxassetid://" .. imageId
        BgImage.ImageTransparency = transparency or 0.8
        BgImage.Visible = true
    end

    -- Tab System
    function Window:CreateTab(tabName, iconId)
        local TabBtn = Create("TextButton", {
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = LogQuickUI.Theme.Secondary,
            Text = "  " .. tabName,
            TextColor3 = LogQuickUI.Theme.DarkText,
            Font = Enum.Font.GothamSemibold,
            TextSize = FontSize.Normal,
            TextXAlignment = Enum.TextXAlignment.Left,
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        local Page = Create("ScrollingFrame", {
            Parent = PageContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            Visible = false,
            Create("UIListLayout", {Padding = UDim.new(0, 10)})
        })

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                Tween(t.Btn, {TextColor3 = LogQuickUI.Theme.DarkText, BackgroundColor3 = LogQuickUI.Theme.Secondary}, 0.2)
            end
            Page.Visible = true
            Tween(TabBtn, {TextColor3 = LogQuickUI.Theme.Accent, BackgroundColor3 = LogQuickUI.Theme.Background}, 0.2)
        end)

        local Tab = {Page = Page, Btn = TabBtn}
        table.insert(Window.Tabs, Tab)
        
        if #Window.Tabs == 1 then
            Page.Visible = true
            TabBtn.TextColor3 = LogQuickUI.Theme.Accent
        end

        -- Section System (Sub-partitions)
        function Tab:CreateSection(secName)
            local SecFrame = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 30), -- Auto-expands
                BackgroundColor3 = LogQuickUI.Theme.Background,
                BackgroundTransparency = 0.5,
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {Color = LogQuickUI.Theme.Border, Thickness = 1})
            })
            
            Create("TextLabel", {
                Parent = SecFrame,
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = secName,
                TextColor3 = LogQuickUI.Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = FontSize.Normal,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local SecLayout = Create("UIListLayout", {
                Parent = SecFrame,
                Padding = UDim.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            -- Add padding top
            Create("Frame", {Parent = SecFrame, Size = UDim2.new(1,0,0,25), BackgroundTransparency=1})

            SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SecFrame.Size = UDim2.new(1, -10, 0, SecLayout.AbsoluteContentSize.Y + 10)
                Page.CanvasSize = UDim2.new(0, 0, 0, Page.UIListLayout.AbsoluteContentSize.Y + 20)
            end)

            local Elements = {}

            -- [[ UI Elements ]] --

            -- Label
            function Elements:AddLabel(text)
                Create("TextLabel", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            end

            -- Button
            function Elements:AddButton(text, callback)
                local Btn = Create("TextButton", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = FontSize.Normal,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("UIStroke", {Color = LogQuickUI.Theme.Border, Thickness = 1})
                })
                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = LogQuickUI.Theme.Border}, 0.2); PlaySound("Hover") end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = LogQuickUI.Theme.Secondary}, 0.2) end)
                Btn.MouseButton1Click:Connect(function() PlaySound("Click"); callback() end)
            end

            -- Toggle
            function Elements:AddToggle(text, default, callback)
                local state = default or false
                local TglFrame = Create("TextButton", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    Text = "",
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                Create("TextLabel", {
                    Parent = TglFrame,
                    Size = UDim2.new(0.8, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Indicator = Create("Frame", {
                    Parent = TglFrame,
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = state and LogQuickUI.Theme.Accent or LogQuickUI.Theme.Border,
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                local Circle = Create("Frame", {
                    Parent = Indicator,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })

                local function fire()
                    state = not state
                    Tween(Indicator, {BackgroundColor3 = state and LogQuickUI.Theme.Accent or LogQuickUI.Theme.Border}, 0.2)
                    Tween(Circle, {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}, 0.2)
                    callback(state)
                end
                TglFrame.MouseButton1Click:Connect(function() PlaySound("Click"); fire() end)
                if state then callback(state) end
            end

            -- Slider
            function Elements:AddSlider(text, min, max, default, callback)
                local SldFrame = Create("Frame", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 50),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                Create("TextLabel", {
                    Parent = SldFrame,
                    Size = UDim2.new(1, -10, 0, 20),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ValueTxt = Create("TextLabel", {
                    Parent = SldFrame,
                    Size = UDim2.new(1, -10, 0, 20),
                    Position = UDim2.new(0, 0, 0, 5),
                    BackgroundTransparency = 1,
                    Text = tostring(default),
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                local Bar = Create("TextButton", {
                    Parent = SldFrame,
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Border,
                    Text = "",
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                local Fill = Create("Frame", {
                    Parent = Bar,
                    Size = UDim2.new((default-min)/(max-min), 0, 1, 0),
                    BackgroundColor3 = LogQuickUI.Theme.Accent,
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })

                local dragging = false
                local function update(input)
                    local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + ((max - min) * pos))
                    Tween(Fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1)
                    ValueTxt.Text = tostring(val)
                    callback(val)
                end
                Bar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; update(i)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        update(i)
                    end
                end)
            end

            -- Dropdown
            function Elements:AddDropdown(text, list, callback)
                local DropFrame = Create("Frame", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    ClipsDescendants = true,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                local TopBtn = Create("TextButton", {
                    Parent = DropFrame,
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundTransparency = 1,
                    Text = ""
                })
                local Title = Create("TextLabel", {
                    Parent = DropFrame,
                    Size = UDim2.new(1, -30, 0, 35),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text .. " : None",
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Scroll = Create("ScrollingFrame", {
                    Parent = DropFrame,
                    Size = UDim2.new(1, 0, 1, -35),
                    Position = UDim2.new(0, 0, 0, 35),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    Create("UIListLayout", {Padding = UDim.new(0,2)})
                })

                local open = false
                TopBtn.MouseButton1Click:Connect(function()
                    PlaySound("Click")
                    open = not open
                    local h = open and math.min(#list * 25 + 40, 150) or 35
                    Tween(DropFrame, {Size = UDim2.new(0.95, 0, 0, h)}, 0.2)
                end)

                local function buildList()
                    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    for _, item in pairs(list) do
                        local btn = Create("TextButton", {
                            Parent = Scroll,
                            Size = UDim2.new(1, 0, 0, 25),
                            BackgroundColor3 = LogQuickUI.Theme.Background,
                            Text = item,
                            TextColor3 = LogQuickUI.Theme.DarkText,
                            Font = Enum.Font.Gotham,
                            TextSize = FontSize.Small
                        })
                        btn.MouseButton1Click:Connect(function()
                            PlaySound("Click")
                            Title.Text = text .. " : " .. item
                            open = false
                            Tween(DropFrame, {Size = UDim2.new(0.95, 0, 0, 35)}, 0.2)
                            callback(item)
                        end)
                    end
                    Scroll.CanvasSize = UDim2.new(0,0,0,#list*25)
                end
                buildList()
                
                -- API to refresh dropdown (e.g. for players)
                return {
                    Refresh = function(newList)
                        list = newList
                        buildList()
                    end
                }
            end

            -- Input (Textbox)
            function Elements:AddInput(text, callback)
                local InpFrame = Create("Frame", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                Create("TextLabel", {
                    Parent = InpFrame,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Box = Create("TextBox", {
                    Parent = InpFrame,
                    Size = UDim2.new(0.4, 0, 0.7, 0),
                    Position = UDim2.new(0.55, 0, 0.15, 0),
                    BackgroundColor3 = LogQuickUI.Theme.Background,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Text = "",
                    PlaceholderText = "Input...",
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Small,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                Box.FocusLost:Connect(function() callback(Box.Text) end)
            end

            -- Basic Keybind
            function Elements:AddKeybind(text, defaultKey, callback)
                local key = defaultKey
                local BindFrame = Create("Frame", {
                    Parent = SecFrame,
                    Size = UDim2.new(0.95, 0, 0, 35),
                    BackgroundColor3 = LogQuickUI.Theme.Secondary,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                Create("TextLabel", {
                    Parent = BindFrame,
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = LogQuickUI.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = FontSize.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local Btn = Create("TextButton", {
                    Parent = BindFrame,
                    Size = UDim2.new(0.3, 0, 0.7, 0),
                    Position = UDim2.new(0.65, 0, 0.15, 0),
                    BackgroundColor3 = LogQuickUI.Theme.Background,
                    Text = key.Name,
                    TextColor3 = LogQuickUI.Theme.Accent,
                    Font = Enum.Font.GothamBold,
                    TextSize = FontSize.Small,
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                
                local waiting = false
                Btn.MouseButton1Click:Connect(function()
                    waiting = true
                    Btn.Text = "..."
                end)
                UserInputService.InputBegan:Connect(function(i, p)
                    if not p and waiting and i.UserInputType == Enum.UserInputType.Keyboard then
                        key = i.KeyCode
                        Btn.Text = key.Name
                        waiting = false
                    elseif not p and not waiting and i.KeyCode == key then
                        callback()
                    end
                end)
            end

            return Elements
        end

        return Tab
    end

    -- [[ Built-in UI Settings Tab ]] --
    local SettingsTab = Window:CreateTab("UI Settings", "rbxassetid://1234567") -- Placeholder icon id
    local UIConf = SettingsTab:CreateSection("Customization")
    
    UIConf:AddLabel("UI Author: Log_quick")
    UIConf:AddLabel("Script Author: " .. LogQuickUI.Config.ScriptAuthor)
    
    UIConf:AddToggle("Rainbow Border", false, function(state)
        LogQuickUI.Config.RainbowBorder = state
    end)
    
    UIConf:AddSlider("UI Transparency", 0, 100, 0, function(val)
        LogQuickUI.Config.Transparency = val / 100
        MainFrame.BackgroundTransparency = LogQuickUI.Config.Transparency
    end)

    -- Simple Color Preset Dropdown (Full HSV is complex for single file, using preset + hex approach)
    UIConf:AddDropdown("Theme Color", {"Blue", "Red", "Green", "Purple", "White"}, function(sel)
        local colors = {
            Blue = Color3.fromRGB(85, 170, 255),
            Red = Color3.fromRGB(255, 85, 85),
            Green = Color3.fromRGB(85, 255, 127),
            Purple = Color3.fromRGB(170, 85, 255),
            White = Color3.fromRGB(255, 255, 255)
        }
        LogQuickUI.Theme.Accent = colors[sel]
    end)

    local UtilConf = SettingsTab:CreateSection("Utilities")
    UtilConf:AddToggle("Floating Stats (FPS/Ping)", true, function(state)
        LogQuickUI:SetStatusVisible(state)
    end)

    return Window
end

return LogQuickUI

--[[ 
=========================================
      HOW TO USE EXAMPLE (Developer)
=========================================

local Library = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL_HERE"))()
-- 或者如果你是单文件测试，直接： local Library = LogQuickUI

-- 1. Key System (可选)
Library:CreateKeySystem("1234", "Premium Script Key", function(success)
    if success then
        -- 2. Create Window
        local Window = Library:CreateWindow({
            Title = "My Epic Hub",
            Subtitle = "V1.0",
            Author = "YourName"
        })
        
        -- Window:SetBackground("12345678", 0.5) -- 自定义背景API
        Library:SetWatermark("My Epic Hub | FPS: Stable", true)

        -- 3. Create Tabs & Sections
        local MainTab = Window:CreateTab("Main Features")
        local CombatSec = MainTab:CreateSection("Combat")
        
        -- 4. Add Elements
        CombatSec:AddButton("Kill All", function()
            Library:Notify("Action", "Killed everyone!", 2)
        end)
        
        CombatSec:AddToggle("Aimbot", false, function(state)
            print("Aimbot:", state)
        end)
        
        CombatSec:AddSlider("FOV", 10, 120, 70, function(val)
            game.Workspace.CurrentCamera.FieldOfView = val
        end)

        -- 5. Player Selector Example
        local playersList = {}
        for _,v in pairs(game.Players:GetPlayers()) do table.insert(playersList, v.Name) end
        
        local pDrop = CombatSec:AddDropdown("Select Player", playersList, function(target)
            print("Selected:", target)
        end)
        
        game.Players.PlayerAdded:Connect(function(p)
            table.insert(playersList, p.Name)
            pDrop.Refresh(playersList)
        end)
    end
end)
]]
