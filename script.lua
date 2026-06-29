--[[
    LogZ-UI Library
    Author: log_quick
    Version: 1.0.0
    A complete Script Hub UI Library for Roblox Executors
--]]

-- ============================================================
-- SERVICES & GLOBALS
-- ============================================================

local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera

-- ============================================================
-- LIBRARY ROOT
-- ============================================================

local LogZ = {}
LogZ.__index = LogZ

-- ============================================================
-- EXECUTOR COMPAT
-- ============================================================

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function hasFunc(name)
    return type(_G[name]) == "function" or type(getfenv()[name]) == "function"
end

local execEnv = {}
execEnv.protect_gui   = syn and syn.protect_gui   or (protectgui)   or nil
execEnv.gethui        = gethui        or nil
execEnv.writefile     = writefile     or nil
execEnv.readfile      = readfile      or nil
execEnv.isfile        = isfile        or nil
execEnv.makefolder    = makefolder    or nil
execEnv.delfile       = delfile       or nil
execEnv.listfiles     = listfiles     or nil
execEnv.setclipboard  = setclipboard  or nil
execEnv.identifyexecutor = identifyexecutor or (function() return "Unknown" end)

-- ============================================================
-- THEME COLOR SYSTEM
-- ============================================================

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    return Color3.new(r, g, b)
end

local function color3ToHex(color)
    return string.format("%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function darkenColor(color, amount)
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.max(0, v - amount))
end

local ThemeColors = {
    Background        = hexToColor3("#0C0F1A"),
    NavBackground     = hexToColor3("#080B14"),
    ControlBackground = hexToColor3("#12162B"),
    ControlStroke     = hexToColor3("#1E2340"),
    Accent            = hexToColor3("#00D4FF"),
    AccentDark        = hexToColor3("#009BBF"),
    Text              = hexToColor3("#E8ECF4"),
    TextSecondary     = hexToColor3("#6B7A99"),
    TextDisabled      = hexToColor3("#3A4260"),
    ToggleOn          = hexToColor3("#00D4FF"),
    ToggleOff         = hexToColor3("#2A2F45"),
    SliderFill        = hexToColor3("#00D4FF"),
    SliderTrack       = hexToColor3("#1E2340"),
    InputBackground   = hexToColor3("#0E1225"),
    NotifyBackground  = hexToColor3("#141830"),
    DangerColor       = hexToColor3("#FF4757"),
    SuccessColor      = hexToColor3("#2ED573"),
    WarningColor      = hexToColor3("#FFA502"),
}

local ThemeBindings = {}  -- {instance, property, token}

local function BindTheme(instance, property, token)
    if ThemeColors[token] then
        instance[property] = ThemeColors[token]
        table.insert(ThemeBindings, {instance, property, token})
    end
end

local animationsEnabled = true

local function Tween(instance, props, duration, style, direction)
    if not animationsEnabled then
        for k, v in pairs(props) do
            instance[k] = v
        end
        return
    end
    duration  = duration  or 0.3
    style     = style     or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

local function ApplyTheme()
    for _, binding in ipairs(ThemeBindings) do
        local inst, prop, token = binding[1], binding[2], binding[3]
        if ThemeColors[token] and inst and inst.Parent then
            Tween(inst, {[prop] = ThemeColors[token]}, 0.3)
        end
    end
end

-- ============================================================
-- UTILITY: CREATE
-- ============================================================

local function Create(className, props, children)
    local instance = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            if type(value) == "table" and value.__type == "ThemeToken" then
                BindTheme(instance, key, value.token)
            else
                instance[key] = value
            end
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    if props and props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function Token(tokenName)
    return {__type = "ThemeToken", token = tokenName}
end

-- ============================================================
-- MOBILE DETECTION
-- ============================================================

local isMobile = false
local function CheckMobile()
    local vp = Camera.ViewportSize
    isMobile = UserInputService.TouchEnabled and vp.X < 700
end
CheckMobile()

-- ============================================================
-- SCREEN GUI SETUP
-- ============================================================

local screenGui

local function CreateScreenGui()
    -- Remove existing
    local existing = CoreGui:FindFirstChild("LogZ-UI")
    if existing then existing:Destroy() end

    screenGui = Create("ScreenGui", {
        Name             = "LogZ-UI",
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
    })

    if execEnv.protect_gui then
        pcall(execEnv.protect_gui, screenGui)
        screenGui.Parent = CoreGui
    elseif execEnv.gethui then
        screenGui.Parent = execEnv.gethui()
    else
        pcall(function()
            screenGui.Parent = CoreGui
        end)
        if not screenGui.Parent then
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    return screenGui
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================

local NotifyContainer
local notifyQueue = {}
local activeNotifications = 0
local MAX_NOTIFICATIONS = 5
local notifyPosition = "TopRight" -- TopRight, TopLeft, BottomRight, TopCenter

local function SetupNotifyContainer(parent, pos)
    if NotifyContainer then NotifyContainer:Destroy() end
    pos = pos or notifyPosition

    local anchorPoint, position
    if pos == "TopRight" then
        anchorPoint = Vector2.new(1, 0)
        position    = UDim2.new(1, -10, 0, 10)
    elseif pos == "TopLeft" then
        anchorPoint = Vector2.new(0, 0)
        position    = UDim2.new(0, 10, 0, 10)
    elseif pos == "BottomRight" then
        anchorPoint = Vector2.new(1, 1)
        position    = UDim2.new(1, -10, 1, -10)
    elseif pos == "TopCenter" then
        anchorPoint = Vector2.new(0.5, 0)
        position    = UDim2.new(0.5, 0, 0, 10)
    end

    NotifyContainer = Create("Frame", {
        Name            = "NotifyContainer",
        BackgroundTransparency = 1,
        AnchorPoint     = anchorPoint,
        Position        = position,
        Size            = UDim2.new(0, 300, 1, -20),
        ZIndex          = 100,
        Parent          = parent,
    }, {
        Create("UIListLayout", {
            SortOrder       = Enum.SortOrder.LayoutOrder,
            VerticalAlignment= (pos == "BottomRight") and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
            Padding         = UDim.new(0, 6),
        }),
    })
end

local function ShowNotification(config, parent)
    config = config or {}
    local title    = config.Title    or "Notification"
    local content  = config.Content  or ""
    local nType    = config.Type     or "Info"
    local duration = config.Duration or 4
    local icon     = config.Icon

    -- Queue if maxed
    if activeNotifications >= MAX_NOTIFICATIONS then
        table.insert(notifyQueue, {config = config, parent = parent})
        return
    end
    activeNotifications = activeNotifications + 1

    local accentColor
    if nType == "Success" then
        accentColor = ThemeColors.SuccessColor
    elseif nType == "Warning" then
        accentColor = ThemeColors.WarningColor
    elseif nType == "Error" then
        accentColor = ThemeColors.DangerColor
    else
        accentColor = ThemeColors.Accent
    end

    local notifyFrame = Create("Frame", {
        Name             = "Notification",
        BackgroundColor3 = ThemeColors.NotifyBackground,
        Size             = UDim2.new(1, 0, 0, 70),
        ClipsDescendants = true,
        ZIndex           = 101,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {
            Color       = ThemeColors.ControlStroke,
            Thickness   = 1,
            Transparency= 0.5,
        }),
    })

    -- Left accent bar
    local accentBar = Create("Frame", {
        Name             = "AccentBar",
        BackgroundColor3 = accentColor,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(0, 3, 1, 0),
        ZIndex           = 102,
        Parent           = notifyFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
    })

    -- Close button
    local closeBtn = Create("TextButton", {
        Name             = "CloseBtn",
        BackgroundTransparency = 1,
        Position         = UDim2.new(1, -20, 0, 4),
        Size             = UDim2.new(0, 16, 0, 16),
        Text             = "×",
        TextColor3       = ThemeColors.TextSecondary,
        TextSize         = 14,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 103,
        Parent           = notifyFrame,
    })

    -- Title
    local titleLabel = Create("TextLabel", {
        Name             = "Title",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 8),
        Size             = UDim2.new(1, -34, 0, 18),
        Text             = title,
        TextColor3       = ThemeColors.Text,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 102,
        Parent           = notifyFrame,
    })

    -- Content
    local contentLabel = Create("TextLabel", {
        Name             = "Content",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 14, 0, 28),
        Size             = UDim2.new(1, -20, 0, 28),
        Text             = content,
        TextColor3       = ThemeColors.TextSecondary,
        TextSize         = 12,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 102,
        Parent           = notifyFrame,
    })

    -- Progress bar
    local progressBg = Create("Frame", {
        Name             = "ProgressBg",
        BackgroundColor3 = ThemeColors.ControlStroke,
        Position         = UDim2.new(0, 3, 1, -4),
        Size             = UDim2.new(1, -6, 0, 2),
        ZIndex           = 102,
        Parent           = notifyFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 1)}),
    })

    local progressFill = Create("Frame", {
        Name             = "ProgressFill",
        BackgroundColor3 = accentColor,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 103,
        Parent           = progressBg,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 1)}),
    })

    notifyFrame.Parent = NotifyContainer

    -- Slide in animation
    local offX = 0
    if notifyPosition == "TopRight" or notifyPosition == "BottomRight" then
        notifyFrame.Position = UDim2.new(0, 320, 0, 0)
    elseif notifyPosition == "TopLeft" then
        notifyFrame.Position = UDim2.new(0, -320, 0, 0)
    elseif notifyPosition == "TopCenter" then
        notifyFrame.Position = UDim2.new(0, 0, 0, -80)
    end
    notifyFrame.BackgroundTransparency = 1
    Tween(notifyFrame, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0,
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Progress bar tween
    Tween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        local slideOut
        if notifyPosition == "TopRight" or notifyPosition == "BottomRight" then
            slideOut = UDim2.new(0, 320, 0, 0)
        elseif notifyPosition == "TopLeft" then
            slideOut = UDim2.new(0, -320, 0, 0)
        else
            slideOut = UDim2.new(0, 0, 0, -80)
        end
        Tween(notifyFrame, {
            Position = slideOut,
            BackgroundTransparency = 1,
        }, 0.3)
        task.delay(0.35, function()
            notifyFrame:Destroy()
            activeNotifications = activeNotifications - 1
            -- Process queue
            if #notifyQueue > 0 then
                local next = table.remove(notifyQueue, 1)
                ShowNotification(next.config, next.parent)
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    task.delay(duration, dismiss)
end

-- ============================================================
-- DIALOG SYSTEM
-- ============================================================

local function ShowDialog(config, parent)
    config = config or {}
    local title   = config.Title   or "Dialog"
    local content = config.Content or ""
    local buttons = config.Buttons or {
        {Text = "Confirm", Primary = true, Callback = nil},
        {Text = "Cancel",  Callback = nil},
    }

    -- Overlay
    local overlay = Create("Frame", {
        Name             = "DialogOverlay",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 200,
        Parent           = parent,
    })

    local dialogFrame = Create("Frame", {
        Name             = "DialogFrame",
        BackgroundColor3 = ThemeColors.ControlBackground,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(0, 340, 0, 160),
        ZIndex           = 201,
        Parent           = overlay,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
        Create("UIStroke", {
            Color     = ThemeColors.ControlStroke,
            Thickness = 1,
        }),
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 16, 0, 16),
        Size       = UDim2.new(1, -32, 0, 22),
        Text       = title,
        TextColor3 = ThemeColors.Text,
        TextSize   = 15,
        Font       = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 202,
        Parent     = dialogFrame,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 16, 0, 44),
        Size       = UDim2.new(1, -32, 0, 60),
        Text       = content,
        TextColor3 = ThemeColors.TextSecondary,
        TextSize   = 13,
        Font       = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped= true,
        ZIndex     = 202,
        Parent     = dialogFrame,
    })

    local btnWidth   = (300 - (8 * (#buttons - 1))) / #buttons
    local btnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 1, -48),
        Size     = UDim2.new(1, -32, 0, 36),
        ZIndex   = 202,
        Parent   = dialogFrame,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding       = UDim.new(0, 8),
        }),
    })

    local function closeDialog()
        overlay:Destroy()
    end

    for i, btnConfig in ipairs(buttons) do
        local bgColor, txtColor
        if btnConfig.Primary then
            bgColor  = ThemeColors.Accent
            txtColor = Color3.new(1, 1, 1)
        elseif btnConfig.Danger then
            bgColor  = ThemeColors.DangerColor
            txtColor = Color3.new(1, 1, 1)
        else
            bgColor  = ThemeColors.InputBackground
            txtColor = ThemeColors.Text
        end

        local btn = Create("TextButton", {
            BackgroundColor3 = bgColor,
            Size     = UDim2.new(1/#buttons, i == #buttons and 0 or -4, 1, 0),
            Text     = btnConfig.Text or "OK",
            TextColor3 = txtColor,
            TextSize = 13,
            Font     = Enum.Font.GothamBold,
            ZIndex   = 203,
            Parent   = btnContainer,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        })

        btn.MouseButton1Click:Connect(function()
            closeDialog()
            if btnConfig.Callback then
                btnConfig.Callback()
            end
        end)
    end

    -- Animate in
    dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 20)
    dialogFrame.BackgroundTransparency = 1
    Tween(dialogFrame, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ============================================================
-- HSV COLOR PICKER (Shared)
-- ============================================================

-- HSV Disc AssetId (using Roblox's color wheel asset)
local HSV_DISC_ASSET = "rbxassetid://4155801252"

local function CreateHSVPicker(parent, initialColor, onChange, zIndex)
    zIndex = zIndex or 10

    local h, s, v = Color3.toHSV(initialColor or Color3.new(1, 0, 0))
    local pickerFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Size   = UDim2.new(1, 0, 0, 160),
        ZIndex = zIndex,
        Parent = parent,
    })

    -- HSV Disc
    local discSize  = 120
    local discFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size     = UDim2.new(0, discSize, 0, discSize),
        ZIndex   = zIndex,
        Parent   = pickerFrame,
    })

    local discImage = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size   = UDim2.new(1, 0, 1, 0),
        Image  = HSV_DISC_ASSET,
        ZIndex = zIndex,
        Parent = discFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0.5, 0)}),
    })

    -- Disc indicator
    local discIndicator = Create("Frame", {
        Name             = "Indicator",
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Size             = UDim2.new(0, 10, 0, 10),
        ZIndex           = zIndex + 1,
        Parent           = discFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0.5, 0)}),
        Create("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1}),
    })

    -- Value bar
    local barX    = discSize + 8
    local barW    = 18
    local barH    = discSize

    local valueBar = Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, barX, 0, 0),
        Size     = UDim2.new(0, barW, 0, barH),
        ZIndex   = zIndex,
        Parent   = pickerFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        Create("UIGradient", {
            Color     = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
            }),
            Rotation = 90,
        }),
    })
    local valueGradient = valueBar:FindFirstChildOfClass("UIGradient")

    local valueIndicator = Create("Frame", {
        Name             = "ValueIndicator",
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0, 0),
        Size             = UDim2.new(1, 4, 0, 4),
        ZIndex           = zIndex + 1,
        Parent           = valueBar,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
        Create("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1}),
    })

    -- Preview and inputs row
    local infoRow = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, discSize + 6),
        Size     = UDim2.new(1, 0, 0, 28),
        ZIndex   = zIndex,
        Parent   = pickerFrame,
    })

    local colorPreview = Create("Frame", {
        BackgroundColor3 = initialColor or Color3.new(1, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Size     = UDim2.new(0, 24, 0, 24),
        ZIndex   = zIndex,
        Parent   = infoRow,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        Create("UIStroke", {
            Color     = ThemeColors.ControlStroke,
            Thickness = 1,
        }),
    })

    local function makeInput(placeholder, xPos, w)
        local frame = Create("Frame", {
            BackgroundColor3 = ThemeColors.InputBackground,
            Position = UDim2.new(0, xPos, 0, 0),
            Size     = UDim2.new(0, w, 0, 24),
            ZIndex   = zIndex,
            Parent   = infoRow,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Create("UIStroke", {
                Color     = ThemeColors.ControlStroke,
                Thickness = 1,
            }),
        })
        local box = Create("TextBox", {
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, -4, 1, 0),
            Position   = UDim2.new(0, 4, 0, 0),
            Text       = placeholder,
            TextColor3 = ThemeColors.Text,
            TextSize   = 11,
            Font       = Enum.Font.Code,
            PlaceholderText = placeholder,
            ZIndex     = zIndex + 1,
            Parent     = frame,
        })
        return frame, box
    end

    local hexFrame, hexBox = makeInput("RRGGBB", 30, 72)
    local rFrame, rBox     = makeInput("R", 108, 34)
    local gFrame, gBox     = makeInput("G", 146, 34)
    local bFrame, bBox     = makeInput("B", 184, 34)

    -- Internal update function
    local function updateIndicators()
        local radius = discSize / 2
        local angle  = math.rad(h * 360)
        local dist   = s * radius
        local cx     = radius + math.cos(angle) * dist
        local cy     = radius - math.sin(angle) * dist
        discIndicator.Position = UDim2.new(0, cx, 0, cy)

        valueIndicator.Position = UDim2.new(0.5, 0, 1 - v, 0)

        -- Update gradient
        valueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        })

        local currentColor = Color3.fromHSV(h, s, v)
        colorPreview.BackgroundColor3 = currentColor

        -- Update inputs
        hexBox.Text = color3ToHex(currentColor)
        local r = math.floor(currentColor.R * 255 + 0.5)
        local g = math.floor(currentColor.G * 255 + 0.5)
        local b = math.floor(currentColor.B * 255 + 0.5)
        rBox.Text = tostring(r)
        gBox.Text = tostring(g)
        bBox.Text = tostring(b)

        if onChange then
            onChange(currentColor)
        end
    end

    -- Disc drag
    local draggingDisc = false
    discImage.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingDisc = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingDisc = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingDisc and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local absPos  = discImage.AbsolutePosition
            local absSize = discImage.AbsoluteSize
            local cx      = absPos.X + absSize.X / 2
            local cy      = absPos.Y + absSize.Y / 2
            local dx      = input.Position.X - cx
            local dy      = input.Position.Y - cy
            local radius  = absSize.X / 2
            local dist    = math.sqrt(dx*dx + dy*dy)
            h = (math.atan2(-dy, dx) / (2 * math.pi)) % 1
            s = math.clamp(dist / radius, 0, 1)
            updateIndicators()
        end
    end)

    -- Value bar drag
    local draggingBar = false
    valueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingBar and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local absPos  = valueBar.AbsolutePosition
            local absSize = valueBar.AbsoluteSize
            local dy      = input.Position.Y - absPos.Y
            v = 1 - math.clamp(dy / absSize.Y, 0, 1)
            updateIndicators()
        end
    end)

    -- Hex input
    hexBox.FocusLost:Connect(function()
        local hex = hexBox.Text:gsub("#", "")
        if #hex == 6 then
            local ok, col = pcall(hexToColor3, hex)
            if ok then
                h, s, v = Color3.toHSV(col)
                updateIndicators()
            end
        end
    end)

    local function tryRGB()
        local r = tonumber(rBox.Text)
        local g = tonumber(gBox.Text)
        local b = tonumber(bBox.Text)
        if r and g and b then
            r = math.clamp(r, 0, 255) / 255
            g = math.clamp(g, 0, 255) / 255
            b = math.clamp(b, 0, 255) / 255
            h, s, v = Color3.toHSV(Color3.new(r, g, b))
            updateIndicators()
        end
    end
    rBox.FocusLost:Connect(tryRGB)
    gBox.FocusLost:Connect(tryRGB)
    bBox.FocusLost:Connect(tryRGB)

    -- Initialize
    updateIndicators()

    local api = {}
    function api:SetColor(color)
        h, s, v = Color3.toHSV(color)
        updateIndicators()
    end
    function api:GetColor()
        return Color3.fromHSV(h, s, v)
    end
    function api:GetFrame()
        return pickerFrame
    end

    return api
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================

local function ShowLoadingScreen(parent, onComplete)
    local loadFrame = Create("Frame", {
        Name             = "LoadingScreen",
        BackgroundColor3 = ThemeColors.Background,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 500,
        Parent           = parent,
    })

    local logoLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position    = UDim2.new(0.5, 0, 0.5, -20),
        Size        = UDim2.new(0, 200, 0, 40),
        Text        = "LogZ-UI",
        TextColor3  = ThemeColors.Accent,
        TextSize    = 28,
        Font        = Enum.Font.GothamBlack,
        ZIndex      = 501,
        Parent      = loadFrame,
    })

    local subLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position    = UDim2.new(0.5, 0, 0.5, 10),
        Size        = UDim2.new(0, 200, 0, 20),
        Text        = "by log_quick",
        TextColor3  = ThemeColors.TextSecondary,
        TextSize    = 13,
        Font        = Enum.Font.Gotham,
        ZIndex      = 501,
        Parent      = loadFrame,
    })

    -- Progress bar
    local barBg = Create("Frame", {
        BackgroundColor3 = ThemeColors.ControlStroke,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 40),
        Size             = UDim2.new(0, 200, 0, 3),
        ZIndex           = 501,
        Parent           = loadFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
    })

    local barFill = Create("Frame", {
        BackgroundColor3 = ThemeColors.Accent,
        Size             = UDim2.new(0, 0, 1, 0),
        ZIndex           = 502,
        Parent           = barBg,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
    })

    -- Animate progress
    Tween(barFill, {Size = UDim2.new(1, 0, 1, 0)}, 1.2, Enum.EasingStyle.Quad)
    logoLabel.TextTransparency = 1
    subLabel.TextTransparency  = 1
    Tween(logoLabel, {TextTransparency = 0}, 0.6)
    task.delay(0.3, function()
        Tween(subLabel, {TextTransparency = 0}, 0.6)
    end)

    task.delay(1.4, function()
        Tween(loadFrame, {BackgroundTransparency = 1}, 0.4)
        Tween(logoLabel, {TextTransparency = 1}, 0.4)
        Tween(subLabel,  {TextTransparency = 1}, 0.4)
        task.delay(0.45, function()
            loadFrame:Destroy()
            if onComplete then onComplete() end
        end)
    end)
end

-- ============================================================
-- WINDOW CREATION
-- ============================================================

function LogZ.CreateWindow(config)
    config = config or {}

    local titleDefault    = config.Title      or "LogZ-UI"
    local subTitleDefault = config.SubTitle   or "by log_quick"
    local logoIdDefault   = config.LogoId     or "rbxassetid://7733960981"
    local windowSize      = config.Size       or UDim2.new(0, 650, 0, 450)
    local accentColor     = config.AccentColor
    local toggleKey       = config.ToggleKey  or Enum.KeyCode.RightControl
    local saveConfigEnabled = config.SaveConfig or false
    local configFolder    = config.ConfigFolder or "LogZ_Configs"
    local showLoading     = config.LoadingScreen ~= false

    -- Apply accent override
    if accentColor then
        ThemeColors.Accent    = accentColor
        ThemeColors.AccentDark= darkenColor(accentColor, 0.2)
        ThemeColors.ToggleOn  = accentColor
        ThemeColors.SliderFill= accentColor
    end

    -- Window object
    local Window = {
        Flags       = {},
        _controls   = {},
        _connections= {},
        _tabs       = {},
        _configFolder = configFolder,
        _saveConfig   = saveConfigEnabled,
        _currentTitle = titleDefault,
        _currentSub   = subTitleDefault,
        _currentLogo  = logoIdDefault,
        _defaultTitle = titleDefault,
        _defaultSub   = subTitleDefault,
        _defaultLogo  = logoIdDefault,
        _titleAlignment = "Left",
        _showLogo     = true,
        _autoSaveEnabled = false,
        _autoSaveDebounce= nil,
        _activeTab    = nil,
        _minimized    = false,
        _visible      = true,
        _settingsTab  = nil,
        _navIndicator = nil,
        _uiScale      = 1.0,
        _notifyPos    = "TopRight",
    }

    -- Setup folder
    if saveConfigEnabled and execEnv.makefolder then
        pcall(execEnv.makefolder, configFolder)
    end

    -- Create ScreenGui
    local sg = CreateScreenGui()

    -- UIScale
    local uiScaleInst = Create("UIScale", {
        Scale  = 1,
        Parent = sg,
    })

    -- Main container
    local mainFrame = Create("Frame", {
        Name             = "MainFrame",
        BackgroundColor3 = ThemeColors.Background,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = windowSize,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = sg,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
        Create("UIStroke", {
            Color     = ThemeColors.ControlStroke,
            Thickness = 1,
        }),
    })
    BindTheme(mainFrame, "BackgroundColor3", "Background")

    -- Setup notify container
    SetupNotifyContainer(sg, "TopRight")

    ---- TITLE BAR ----
    local titleBar = Create("Frame", {
        Name             = "TitleBar",
        BackgroundColor3 = ThemeColors.NavBackground,
        Size             = UDim2.new(1, 0, 0, 35),
        ZIndex           = 5,
        Parent           = mainFrame,
    })
    BindTheme(titleBar, "BackgroundColor3", "NavBackground")

    -- Logo
    local logoImage = Create("ImageLabel", {
        Name             = "Logo",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 10, 0.5, -10),
        Size             = UDim2.new(0, 20, 0, 20),
        Image            = logoIdDefault,
        ZIndex           = 6,
        Parent           = titleBar,
    })

    -- Title text
    local titleLabel = Create("TextLabel", {
        Name             = "TitleLabel",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 36, 0, 0),
        Size             = UDim2.new(0, 200, 1, 0),
        Text             = titleDefault,
        TextColor3       = ThemeColors.Text,
        TextSize         = 14,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 6,
        Parent           = titleBar,
    })
    BindTheme(titleLabel, "TextColor3", "Text")

    -- SubTitle text
    local subTitleLabel = Create("TextLabel", {
        Name             = "SubTitleLabel",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 36, 0, 0),
        Size             = UDim2.new(0, 300, 1, 0),
        Text             = "",
        TextColor3       = ThemeColors.TextSecondary,
        TextSize         = 12,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 6,
        Parent           = titleBar,
        Visible          = false,
    })
    BindTheme(subTitleLabel, "TextColor3", "TextSecondary")

    -- Right buttons container
    local rightBtns = Create("Frame", {
        Name             = "RightButtons",
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.new(0, 90, 0, 25),
        ZIndex           = 6,
        Parent           = titleBar,
    }, {
        Create("UIListLayout", {
            FillDirection     = Enum.FillDirection.Horizontal,
            HorizontalAlignment= Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding           = UDim.new(0, 4),
        }),
    })

    local function MakeTitleBtn(text, color)
        local btn = Create("TextButton", {
            BackgroundColor3 = ThemeColors.ControlBackground,
            Size             = UDim2.new(0, 25, 0, 25),
            Text             = text,
            TextColor3       = color or ThemeColors.TextSecondary,
            TextSize         = 14,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 7,
            Parent           = rightBtns,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        })
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = ThemeColors.ControlStroke}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = ThemeColors.ControlBackground}, 0.15)
        end)
        return btn
    end

    local minimizeBtn = MakeTitleBtn("─")
    local collapseBtn = MakeTitleBtn("▾")
    local closeBtn    = MakeTitleBtn("✕", ThemeColors.DangerColor)

    -- Mobile hamburger (hidden on PC)
    local hamburgerBtn = Create("TextButton", {
        Name             = "HamburgerBtn",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 8, 0.5, -10),
        Size             = UDim2.new(0, 20, 0, 20),
        Text             = "☰",
        TextColor3       = ThemeColors.Text,
        TextSize         = 16,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 7,
        Visible          = isMobile,
        Parent           = titleBar,
    })

    ---- UPDATE TITLE BAR LAYOUT ----
    local function UpdateTitleLayout()
        local showLogo = Window._showLogo
        local alignment = Window._titleAlignment
        local logoOffset = showLogo and 36 or 10
        logoImage.Visible = showLogo

        if alignment == "Center" then
            titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            titleLabel.Position    = UDim2.new(0.5, 0, 0.5, 0)
            subTitleLabel.Visible  = false
        else
            titleLabel.AnchorPoint = Vector2.new(0, 0.5)
            titleLabel.Position    = UDim2.new(0, logoOffset, 0.5, 0)
            -- Compute title width to position subtitle
            local titleText = titleLabel.Text
            local titleWidth = TextService:GetTextSize(
                titleText, 14, Enum.Font.GothamBold, Vector2.new(400, 35)
            ).X

            if Window._currentSub ~= "" then
                subTitleLabel.Visible  = true
                subTitleLabel.Position = UDim2.new(0, logoOffset + titleWidth + 6, 0.5, 0)
                subTitleLabel.Size     = UDim2.new(0, 250, 1, 0)
            else
                subTitleLabel.Visible = false
            end
        end
    end

    ---- LEFT NAV ----
    local NAV_WIDTH = 180

    local navFrame = Create("Frame", {
        Name             = "NavFrame",
        BackgroundColor3 = ThemeColors.NavBackground,
        Position         = UDim2.new(0, 0, 0, 35),
        Size             = UDim2.new(0, NAV_WIDTH, 1, -35),
        ZIndex           = 4,
        Parent           = mainFrame,
    })
    BindTheme(navFrame, "BackgroundColor3", "NavBackground")

    -- Nav scrolling area (middle)
    local navScroll = Create("ScrollingFrame", {
        Name             = "NavScroll",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(1, 0, 1, -44),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ZIndex           = 4,
        Parent           = navFrame,
    })

    local navList = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 2),
        Parent    = navScroll,
    })
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
        Parent        = navScroll,
    })

    navList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        navScroll.CanvasSize = UDim2.new(0, 0, 0, navList.AbsoluteContentSize.Y + 12)
    end)

    -- Tab active indicator (sliding bar)
    local tabIndicator = Create("Frame", {
        Name             = "TabIndicator",
        BackgroundColor3 = ThemeColors.Accent,
        Position         = UDim2.new(0, 0, 0, 10),
        Size             = UDim2.new(0, 3, 0, 20),
        ZIndex           = 6,
        Parent           = navFrame,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
    })
    BindTheme(tabIndicator, "BackgroundColor3", "Accent")
    Window._navIndicator = tabIndicator

    -- Settings button at bottom
    local settingsBtn = Create("TextButton", {
        Name             = "SettingsBtn",
        BackgroundTransparency = 1,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 44),
        Text             = "",
        ZIndex           = 5,
        Parent           = navFrame,
    })

    Create("Frame", {
        BackgroundColor3 = ThemeColors.ControlStroke,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 8, 0, 0),
        Size     = UDim2.new(1, -16, 0, 1),
        ZIndex   = 5,
        Parent   = settingsBtn,
    })

    local settingsBtnContent = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 4),
        Size     = UDim2.new(1, 0, 1, -4),
        ZIndex   = 5,
        Parent   = settingsBtn,
    })

    Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0.5, -9),
        Size     = UDim2.new(0, 18, 0, 18),
        Image    = "rbxassetid://7734053495",
        ImageColor3 = ThemeColors.TextSecondary,
        ZIndex   = 6,
        Parent   = settingsBtnContent,
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 38, 0, 0),
        Size       = UDim2.new(1, -46, 1, 0),
        Text       = "设置",
        TextColor3 = ThemeColors.TextSecondary,
        TextSize   = 13,
        Font       = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 6,
        Parent     = settingsBtnContent,
    })

    ---- CONTENT AREA ----
    local contentFrame = Create("Frame", {
        Name             = "ContentFrame",
        BackgroundColor3 = ThemeColors.Background,
        Position         = UDim2.new(0, NAV_WIDTH, 0, 35),
        Size             = UDim2.new(1, -NAV_WIDTH, 1, -35),
        ZIndex           = 3,
        Parent           = mainFrame,
    })
    BindTheme(contentFrame, "BackgroundColor3", "Background")

    -- Page title row
    local pageTitleRow = Create("Frame", {
        Name             = "PageTitleRow",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 30),
        ZIndex           = 4,
        Parent           = contentFrame,
    })

    local pageTitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position   = UDim2.new(0, 16, 0, 0),
        Size       = UDim2.new(0.6, 0, 1, 0),
        Text       = "",
        TextColor3 = ThemeColors.Text,
        TextSize   = 15,
        Font       = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 4,
        Parent     = pageTitleRow,
    })
    BindTheme(pageTitleLabel, "TextColor3", "Text")

    -- Search box
    local searchFrame = Create("Frame", {
        BackgroundColor3 = ThemeColors.InputBackground,
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -12, 0.5, 0),
        Size             = UDim2.new(0, 130, 0, 22),
        ZIndex           = 4,
        Parent           = pageTitleRow,
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
        Create("UIStroke", {
            Color     = ThemeColors.ControlStroke,
            Thickness = 1,
        }),
    })
    BindTheme(searchFrame, "BackgroundColor3", "InputBackground")

    local searchBox = Create("TextBox", {
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 8, 0, 0),
        Size           = UDim2.new(1, -8, 1, 0),
        Text           = "",
        PlaceholderText= "Search...",
        TextColor3     = ThemeColors.Text,
        PlaceholderColor3 = ThemeColors.TextSecondary,
        TextSize       = 12,
        Font           = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 5,
        Parent         = searchFrame,
    })
    BindTheme(searchBox, "TextColor3", "Text")

    -- Main scroll
    local mainScroll = Create("ScrollingFrame", {
        Name             = "MainScroll",
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 30),
        Size             = UDim2.new(1, 0, 1, -30),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ThemeColors.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex           = 3,
        Parent           = contentFrame,
    })
    BindTheme(mainScroll, "ScrollBarImageColor3", "Accent")

    local scrollLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = mainScroll,
    })
    Create("UIPadding", {
        PaddingTop    = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 14),
        Parent        = mainScroll,
    })

    scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        mainScroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
    end)

    ---- DRAGGING (PC) ----
    local dragging = false
    local dragStartPos
    local frameStartPos

    local function ClampToScreen(pos)
        local vp  = Camera.ViewportSize
        local sz  = mainFrame.AbsoluteSize
        local minX = sz.X * 0.5
        local minY = sz.Y * 0.5
        local maxX = vp.X - sz.X * 0.5
        local maxY = vp.Y - sz.Y * 0.5
        return UDim2.new(0,
            math.clamp(pos.X, minX, maxX),
            0,
            math.clamp(pos.Y, minY, maxY)
        )
    end

    if not isMobile then
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging      = true
                dragStartPos  = input.Position
                frameStartPos = mainFrame.Position
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        local dragConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStartPos
                local newX  = frameStartPos.X.Offset + delta.X
                local newY  = frameStartPos.Y.Offset + delta.Y
                local clamped = ClampToScreen(Vector2.new(newX + Camera.ViewportSize.X * 0.5,
                                                          newY + Camera.ViewportSize.Y * 0.5))
                mainFrame.Position = clamped
            end
        end)
        table.insert(Window._connections, dragConn)
    end

    ---- MINIMIZE / CLOSE BUTTONS ----
    minimizeBtn.MouseButton1Click:Connect(function()
        Window._minimized = not Window._minimized
        if Window._minimized then
            Tween(mainFrame, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 35)}, 0.3)
        else
            Tween(mainFrame, {Size = windowSize}, 0.3)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        if Window._settings and Window._settings.closeConfirm then
            ShowDialog({
                Title   = "确认关闭",
                Content = "确定要关闭 LogZ-UI 吗？",
                Buttons = {
                    {Text = "关闭", Primary = true, Danger = true, Callback = function()
                        mainFrame.Visible = false
                    end},
                    {Text = "取消"},
                }
            }, sg)
        else
            mainFrame.Visible = false
        end
    end)

    collapseBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    ---- TOGGLE KEY ----
    local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    table.insert(Window._connections, keyConn)

    ---- SETTINGS REFERENCE ----
    Window._settings = {
        closeConfirm = false,
        animations   = true,
        notifyPos    = "TopRight",
    }

    ---- SECTION BUILDER ----
    local function BuildSection(parent, sectionConfig)
        sectionConfig = sectionConfig or {}
        local sectionName     = sectionConfig.Name     or "Section"
        local collapsible     = sectionConfig.Collapsible ~= false
        local defaultCollapsed= sectionConfig.Collapsed or false

        local sectionFrame = Create("Frame", {
            Name             = "Section_" .. sectionName,
            BackgroundColor3 = ThemeColors.ControlBackground,
            Size             = UDim2.new(1, 0, 0, 36),
            ClipsDescendants = true,
            ZIndex           = 4,
            Parent           = parent,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {
                Color     = ThemeColors.ControlStroke,
                Thickness = 1,
            }),
        })
        BindTheme(sectionFrame, "BackgroundColor3", "ControlBackground")

        -- Header
        local headerBtn = Create("TextButton", {
            Name             = "Header",
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 32),
            Text             = "",
            ZIndex           = 5,
            Parent           = sectionFrame,
        })

        local headerTitle = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position   = UDim2.new(0, 12, 0, 0),
            Size       = UDim2.new(1, -40, 1, 0),
            Text       = sectionName,
            TextColor3 = ThemeColors.Text,
            TextSize   = 13,
            Font       = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 5,
            Parent     = headerBtn,
        })
        BindTheme(headerTitle, "TextColor3", "Text")

        -- Arrow
        local arrow = Create("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position    = UDim2.new(1, -10, 0.5, 0),
            Size        = UDim2.new(0, 16, 0, 16),
            Text        = "▾",
            TextColor3  = ThemeColors.TextSecondary,
            TextSize    = 12,
            Font        = Enum.Font.GothamBold,
            ZIndex      = 5,
            Parent      = headerBtn,
        })
        BindTheme(arrow, "TextColor3", "TextSecondary")

        -- Content container
        local contentHolder = Create("Frame", {
            Name             = "ContentHolder",
            BackgroundTransparency = 1,
            Position         = UDim2.new(0, 0, 0, 34),
            Size             = UDim2.new(1, 0, 0, 0),
            ZIndex           = 4,
            Parent           = sectionFrame,
        })

        local contentList = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 2),
            Parent    = contentHolder,
        })
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
            Parent        = contentHolder,
        })

        local totalHeight = 0
        local collapsed   = defaultCollapsed

        local function UpdateSectionHeight()
            local contentH = contentList.AbsoluteContentSize.Y + 16
            totalHeight    = 36 + contentH
            if not collapsed then
                Tween(sectionFrame, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.25)
                contentHolder.Size = UDim2.new(1, 0, 0, contentH)
            end
        end

        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSectionHeight)

        if collapsible then
            headerBtn.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                if collapsed then
                    Tween(arrow, {Rotation = -90}, 0.25)
                    Tween(sectionFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.25)
                else
                    Tween(arrow, {Rotation = 0}, 0.25)
                    local contentH = contentList.AbsoluteContentSize.Y + 16
                    Tween(sectionFrame, {Size = UDim2.new(1, 0, 0, 36 + contentH)}, 0.25)
                end
            end)
        end

        -- Section API
        local Section    = {_parent = contentHolder, _window = Window}
        Section.__index  = Section

        -- ============================================================
        -- CONTROL: TOGGLE
        -- ============================================================
        function Section:AddToggle(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Toggle"
            local flag     = cfg.Flag
            local default  = cfg.Default  or false
            local callback = cfg.Callback
            local disabled = cfg.Disabled or false

            local value = default

            if flag then
                Window.Flags[flag] = value
            end

            local row = Create("Frame", {
                Name             = "Toggle_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 36),
                ZIndex           = 6,
                Parent           = contentHolder,
            })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(1, -56, 1, 0),
                Text       = name,
                TextColor3 = disabled and ThemeColors.TextDisabled or ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = row,
            })

            -- Track (capsule)
            local track = Create("Frame", {
                BackgroundColor3 = value and ThemeColors.ToggleOn or ThemeColors.ToggleOff,
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, 0, 0.5, 0),
                Size             = UDim2.new(0, 40, 0, 22),
                ZIndex           = 7,
                Parent           = row,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 11)}),
            })

            -- Handle (knob)
            local handle = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = value
                    and UDim2.new(0, 20, 0.5, 0)
                    or  UDim2.new(0, 2, 0.5, 0),
                Size             = UDim2.new(0, 18, 0, 18),
                ZIndex           = 8,
                Parent           = track,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0.5, 0)}),
            })

            local api = {Value = value}

            local function SetValue(v, silent)
                value    = v
                api.Value= v
                if flag then Window.Flags[flag] = v end
                Tween(track, {
                    BackgroundColor3 = v and ThemeColors.ToggleOn or ThemeColors.ToggleOff
                }, 0.2)
                Tween(handle, {
                    Position = v and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                }, 0.2)
                if not silent and callback then
                    task.spawn(callback, v)
                end
                if not silent and Window._autoSaveEnabled then
                    Window:_AutoSave()
                end
                if api._onChange then api._onChange(v) end
            end

            if not disabled then
                row.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        SetValue(not value)
                    end
                end)
            end

            function api:Set(v)    SetValue(v, false) end
            function api:Get()     return value end
            function api:OnChanged(fn) self._onChange = fn end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: SLIDER
        -- ============================================================
        function Section:AddSlider(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Slider"
            local min      = cfg.Min      or 0
            local max      = cfg.Max      or 100
            local default  = cfg.Default  or min
            local step     = cfg.Step     or 1
            local suffix   = cfg.Suffix   or ""
            local flag     = cfg.Flag
            local callback = cfg.Callback
            local disabled = cfg.Disabled or false

            local value = math.clamp(default, min, max)
            if flag then Window.Flags[flag] = value end

            local container = Create("Frame", {
                Name             = "Slider_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 52),
                ZIndex           = 6,
                Parent           = contentHolder,
            })

            -- Label row
            local labelRow = Create("Frame", {
                BackgroundTransparency = 1,
                Size     = UDim2.new(1, 0, 0, 20),
                ZIndex   = 6,
                Parent   = container,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(0.7, 0, 1, 0),
                Text       = name,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = labelRow,
            })
            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint= Vector2.new(1, 0),
                Position   = UDim2.new(1, 0, 0, 0),
                Size       = UDim2.new(0.3, 0, 1, 0),
                Text       = tostring(value) .. suffix,
                TextColor3 = ThemeColors.Accent,
                TextSize   = 13,
                Font       = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex     = 6,
                Parent     = labelRow,
            })
            BindTheme(valueLabel, "TextColor3", "Accent")

            -- Track
            local trackBg = Create("Frame", {
                BackgroundColor3 = ThemeColors.SliderTrack,
                Position = UDim2.new(0, 0, 0, 26),
                Size     = UDim2.new(1, 0, 0, 4),
                ZIndex   = 6,
                Parent   = container,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
            })
            BindTheme(trackBg, "BackgroundColor3", "SliderTrack")

            local fillBar = Create("Frame", {
                BackgroundColor3 = ThemeColors.SliderFill,
                Size     = UDim2.new((value - min) / (max - min), 0, 1, 0),
                ZIndex   = 7,
                Parent   = trackBg,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
            })
            BindTheme(fillBar, "BackgroundColor3", "SliderFill")

            local handleSize = isMobile and 24 or 14
            local sliderHandle = Create("Frame", {
                BackgroundColor3 = ThemeColors.Accent,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                Size             = UDim2.new(0, handleSize, 0, handleSize),
                ZIndex           = 8,
                Parent           = trackBg,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0.5, 0)}),
            })
            BindTheme(sliderHandle, "BackgroundColor3", "Accent")

            -- Mobile value bubble
            local valueBubble
            if isMobile then
                valueBubble = Create("Frame", {
                    BackgroundColor3 = ThemeColors.Accent,
                    AnchorPoint      = Vector2.new(0.5, 1),
                    Position         = UDim2.new(0.5, 0, 0, -8),
                    Size             = UDim2.new(0, 40, 0, 20),
                    ZIndex           = 10,
                    Visible          = false,
                    Parent           = sliderHandle,
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size       = UDim2.new(1, 0, 1, 0),
                        Text       = tostring(value),
                        TextColor3 = Color3.new(1,1,1),
                        TextSize   = 11,
                        Font       = Enum.Font.GothamBold,
                        ZIndex     = 11,
                    }),
                })
            end

            local api = {Value = value}
            local draggingSlider = false

            local function SnapToStep(v)
                if step == 0 then return v end
                local snapped = min + math.round((v - min) / step) * step
                return math.clamp(snapped, min, max)
            end

            local function SetSliderValue(v, silent)
                v        = SnapToStep(v)
                value    = v
                api.Value= v
                if flag then Window.Flags[flag] = v end
                local ratio = (v - min) / (max - min)
                fillBar.Size           = UDim2.new(ratio, 0, 1, 0)
                sliderHandle.Position  = UDim2.new(ratio, 0, 0.5, 0)
                valueLabel.Text        = tostring(v) .. suffix
                if valueBubble then
                    local bubbleLbl = valueBubble:FindFirstChildOfClass("TextLabel")
                    if bubbleLbl then bubbleLbl.Text = tostring(v) end
                end
                if not silent and callback then
                    task.spawn(callback, v)
                end
                if not silent and Window._autoSaveEnabled then
                    Window:_AutoSave()
                end
                if api._onChange then api._onChange(v) end
            end

            local function HandleInput(inputPos)
                local abs     = trackBg.AbsolutePosition
                local size    = trackBg.AbsoluteSize
                local ratio   = math.clamp((inputPos.X - abs.X) / size.X, 0, 1)
                local newVal  = min + ratio * (max - min)
                SetSliderValue(newVal)
            end

            trackBg.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1
                or  input.UserInputType == Enum.UserInputType.Touch)
                and not disabled then
                    draggingSlider = true
                    if valueBubble then valueBubble.Visible = true end
                    HandleInput(input.Position)
                end
            end)

            local sliderMove = UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and
                   (input.UserInputType == Enum.UserInputType.MouseMovement
                 or input.UserInputType == Enum.UserInputType.Touch) then
                    HandleInput(input.Position)
                end
            end)
            local sliderEnd = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                    if valueBubble then valueBubble.Visible = false end
                end
            end)
            table.insert(Window._connections, sliderMove)
            table.insert(Window._connections, sliderEnd)

            function api:Set(v)    SetSliderValue(v, false) end
            function api:Get()     return value end
            function api:OnChanged(fn) self._onChange = fn end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: DROPDOWN
        -- ============================================================
        function Section:AddDropdown(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Dropdown"
            local items    = cfg.Items    or {}
            local default  = cfg.Default
            local multi    = cfg.Multi    or false
            local flag     = cfg.Flag
            local callback = cfg.Callback
            local canSearch= cfg.Searchable or false

            local selected = multi and {} or default
            if flag then Window.Flags[flag] = selected end

            local container = Create("Frame", {
                Name             = "Dropdown_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = false,
                ZIndex           = 10,
                Parent           = contentHolder,
            })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 8),
                Size       = UDim2.new(0.5, 0, 0, 20),
                Text       = name,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 10,
                Parent     = container,
            })

            local dropBtn = Create("Frame", {
                BackgroundColor3 = ThemeColors.InputBackground,
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, 0, 0, 4),
                Size             = UDim2.new(0, 160, 0, 28),
                ZIndex           = 10,
                Parent           = container,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color     = ThemeColors.ControlStroke,
                    Thickness = 1,
                }),
            })
            BindTheme(dropBtn, "BackgroundColor3", "InputBackground")

            local function GetDisplayText()
                if multi then
                    if #selected == 0 then return "Select..." end
                    return table.concat(selected, ", ")
                else
                    return selected or "Select..."
                end
            end

            local selectedLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 8, 0, 0),
                Size       = UDim2.new(1, -24, 1, 0),
                Text       = GetDisplayText(),
                TextColor3 = ThemeColors.Text,
                TextSize   = 12,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate   = Enum.TextTruncate.AtEnd,
                ZIndex     = 11,
                Parent     = dropBtn,
            })
            BindTheme(selectedLabel, "TextColor3", "Text")

            local arrowLbl = Create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position    = UDim2.new(1, -6, 0.5, 0),
                Size        = UDim2.new(0, 14, 0, 14),
                Text        = "▾",
                TextColor3  = ThemeColors.TextSecondary,
                TextSize    = 11,
                Font        = Enum.Font.GothamBold,
                ZIndex      = 11,
                Parent      = dropBtn,
            })

            local isOpen = false
            local dropPanel

            local api = {Value = selected}

            local function CloseDropdown()
                if not isOpen then return end
                isOpen = false
                Tween(arrowLbl, {Rotation = 0}, 0.2)
                if dropPanel then
                    Tween(dropPanel, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                    task.delay(0.25, function()
                        if dropPanel then dropPanel:Destroy() dropPanel = nil end
                        container.Size = UDim2.new(1, 0, 0, 36)
                        container.ClipsDescendants = false
                    end)
                end
            end

            local function OpenDropdown()
                if isOpen then CloseDropdown() return end

                if isMobile then
                    -- Bottom sheet implementation
                    local overlay = Create("Frame", {
                        BackgroundColor3 = Color3.new(0,0,0),
                        BackgroundTransparency = 0.5,
                        Size   = UDim2.new(1, 0, 1, 0),
                        ZIndex = 50,
                        Parent = sg,
                    })
                    local sheet = Create("Frame", {
                        BackgroundColor3 = ThemeColors.ControlBackground,
                        AnchorPoint      = Vector2.new(0.5, 1),
                        Position         = UDim2.new(0.5, 0, 1, 0),
                        Size             = UDim2.new(1, 0, 0.5, 0),
                        ZIndex           = 51,
                        Parent           = overlay,
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 16)}),
                    })
                    local dragBar = Create("Frame", {
                        BackgroundColor3 = ThemeColors.TextSecondary,
                        AnchorPoint      = Vector2.new(0.5, 0),
                        Position         = UDim2.new(0.5, 0, 0, 8),
                        Size             = UDim2.new(0, 36, 0, 4),
                        ZIndex           = 52,
                        Parent           = sheet,
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
                    })
                    local sheetScroll = Create("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 20),
                        Size     = UDim2.new(1, 0, 1, -20),
                        CanvasSize = UDim2.new(0,0,0,0),
                        ScrollBarThickness = 3,
                        ZIndex   = 52,
                        Parent   = sheet,
                    })
                    local sheetList = Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding   = UDim.new(0, 2),
                        Parent    = sheetScroll,
                    })
                    sheetList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        sheetScroll.CanvasSize = UDim2.new(0,0,0,sheetList.AbsoluteContentSize.Y)
                    end)
                    Tween(sheet, {Position = UDim2.new(0.5, 0, 1, 0)}, 0)
                    Tween(sheet, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Back)

                    for _, item in ipairs(items) do
                        local itemBtn = Create("TextButton", {
                            BackgroundTransparency = 1,
                            Size       = UDim2.new(1, 0, 0, 44),
                            Text       = item,
                            TextColor3 = ThemeColors.Text,
                            TextSize   = 14,
                            Font       = Enum.Font.Gotham,
                            ZIndex     = 53,
                            Parent     = sheetScroll,
                        })
                        itemBtn.MouseButton1Click:Connect(function()
                            if not multi then
                                selected = item
                            else
                                local found = false
                                for i, v in ipairs(selected) do
                                    if v == item then
                                        table.remove(selected, i)
                                        found = true
                                        break
                                    end
                                end
                                if not found then table.insert(selected, item) end
                            end
                            api.Value = selected
                            if flag then Window.Flags[flag] = selected end
                            selectedLabel.Text = GetDisplayText()
                            if callback then task.spawn(callback, selected) end
                            if not multi then
                                Tween(overlay, {BackgroundTransparency = 1}, 0.2)
                                Tween(sheet, {Position = UDim2.new(0.5, 0, 1, 0)}, 0.25)
                                task.delay(0.3, function() overlay:Destroy() end)
                            end
                        end)
                    end
                    overlay.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            Tween(overlay, {BackgroundTransparency = 1}, 0.2)
                            Tween(sheet, {Position = UDim2.new(0.5, 0, 1, 0)}, 0.25)
                            task.delay(0.3, function() overlay:Destroy() end)
                        end
                    end)
                    return
                end

                isOpen = true
                Tween(arrowLbl, {Rotation = 180}, 0.2)

                local maxItems    = math.min(#items, 5)
                local panelHeight = maxItems * 30 + (canSearch and 30 or 0) + 4

                container.ClipsDescendants = false
                container.Size = UDim2.new(1, 0, 0, 36 + panelHeight + 4)

                dropPanel = Create("Frame", {
                    BackgroundColor3 = ThemeColors.InputBackground,
                    Position         = UDim2.new(0, 0, 0, 38),
                    Size             = UDim2.new(1, 0, 0, panelHeight),
                    ClipsDescendants = true,
                    ZIndex           = 15,
                    Parent           = container,
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                    Create("UIStroke", {
                        Color     = ThemeColors.ControlStroke,
                        Thickness = 1,
                    }),
                })
                BindTheme(dropPanel, "BackgroundColor3", "InputBackground")

                local yOff = 0
                if canSearch then
                    local searchInp = Create("TextBox", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 8, 0, 2),
                        Size           = UDim2.new(1, -16, 0, 26),
                        PlaceholderText= "Search...",
                        Text           = "",
                        TextColor3     = ThemeColors.Text,
                        TextSize       = 12,
                        Font           = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex         = 16,
                        Parent         = dropPanel,
                    })
                    yOff = 30
                end

                local itemScroll = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Position     = UDim2.new(0, 0, 0, yOff),
                    Size         = UDim2.new(1, 0, 1, -yOff),
                    CanvasSize   = UDim2.new(0,0,0,#items * 30),
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = ThemeColors.Accent,
                    ZIndex       = 16,
                    Parent       = dropPanel,
                })

                local itemListLayout = Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent    = itemScroll,
                })

                for _, item in ipairs(items) do
                    local isSelected = (not multi and selected == item)
                        or (multi and (function()
                            for _, v in ipairs(selected) do
                                if v == item then return true end
                            end
                            return false
                        end)())

                    local itemBtn = Create("TextButton", {
                        BackgroundColor3 = isSelected and ThemeColors.Accent or Color3.new(0,0,0),
                        BackgroundTransparency = isSelected and 0.85 or 1,
                        Size       = UDim2.new(1, 0, 0, 30),
                        Text       = "",
                        ZIndex     = 16,
                        Parent     = itemScroll,
                    })

                    if multi then
                        Create("Frame", {
                            BackgroundColor3 = isSelected and ThemeColors.Accent or Color3.new(0,0,0),
                            BackgroundTransparency = isSelected and 0 or 0.7,
                            Position = UDim2.new(0, 6, 0.5, -7),
                            Size     = UDim2.new(0, 14, 0, 14),
                            ZIndex   = 17,
                            Parent   = itemBtn,
                        }, {
                            Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                            Create("UIStroke", {
                                Color     = ThemeColors.Accent,
                                Thickness = 1,
                            }),
                        })
                    end

                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position   = UDim2.new(0, multi and 26 or 10, 0, 0),
                        Size       = UDim2.new(1, -(multi and 28 or 12), 1, 0),
                        Text       = item,
                        TextColor3 = ThemeColors.Text,
                        TextSize   = 12,
                        Font       = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex     = 17,
                        Parent     = itemBtn,
                    })

                    itemBtn.MouseEnter:Connect(function()
                        Tween(itemBtn, {BackgroundTransparency = 0.8}, 0.15)
                        itemBtn.BackgroundColor3 = ThemeColors.Accent
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        local sel = (not multi and selected == item)
                            or (multi and (function()
                                for _, v in ipairs(selected) do
                                    if v == item then return true end
                                end
                                return false
                            end)())
                        Tween(itemBtn, {BackgroundTransparency = sel and 0.85 or 1}, 0.15)
                    end)

                    itemBtn.MouseButton1Click:Connect(function()
                        if not multi then
                            selected = item
                            CloseDropdown()
                        else
                            local found = false
                            for i, v in ipairs(selected) do
                                if v == item then
                                    table.remove(selected, i)
                                    found = true
                                    break
                                end
                            end
                            if not found then table.insert(selected, item) end
                        end
                        api.Value = selected
                        if flag then Window.Flags[flag] = selected end
                        selectedLabel.Text = GetDisplayText()
                        if callback then task.spawn(callback, selected) end
                        if Window._autoSaveEnabled then Window:_AutoSave() end
                        if api._onChange then api._onChange(selected) end
                    end)
                end
            end

            local dropClickConn = Create("TextButton", {
                BackgroundTransparency = 1,
                Size   = UDim2.new(1, 0, 1, 0),
                Text   = "",
                ZIndex = 12,
                Parent = dropBtn,
            }).MouseButton1Click:Connect(OpenDropdown)

            -- Close on outside click
            local outsideConn = UserInputService.InputBegan:Connect(function(input)
                if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch) then
                    task.defer(function()
                        if isOpen then CloseDropdown() end
                    end)
                end
            end)
            table.insert(Window._connections, outsideConn)

            function api:Set(v)
                selected = v
                self.Value = v
                if flag then Window.Flags[flag] = v end
                selectedLabel.Text = GetDisplayText()
            end
            function api:Get() return selected end
            function api:Refresh(newItems)
                items = newItems
                if isOpen then CloseDropdown() end
            end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: INPUT
        -- ============================================================
        function Section:AddInput(cfg)
            cfg = cfg or {}
            local name        = cfg.Name        or "Input"
            local placeholder = cfg.Placeholder or "Enter value..."
            local default     = cfg.Default     or ""
            local flag        = cfg.Flag
            local callback    = cfg.Callback
            local clearOnFocus= cfg.ClearOnFocus or false

            local value = default
            if flag then Window.Flags[flag] = value end

            local container = Create("Frame", {
                Name             = "Input_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 52),
                ZIndex           = 6,
                Parent           = contentHolder,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 4),
                Size       = UDim2.new(1, 0, 0, 18),
                Text       = name,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = container,
            })

            local inputStroke = Instance.new("UIStroke")
            inputStroke.Color     = ThemeColors.ControlStroke
            inputStroke.Thickness = 1

            local inputFrame = Create("Frame", {
                BackgroundColor3 = ThemeColors.InputBackground,
                Position         = UDim2.new(0, 0, 0, 26),
                Size             = UDim2.new(1, 0, 0, 22),
                ZIndex           = 6,
                Parent           = container,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
            })
            BindTheme(inputFrame, "BackgroundColor3", "InputBackground")
            inputStroke.Parent = inputFrame

            local textBox = Create("TextBox", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, 8, 0, 0),
                Size           = UDim2.new(1, -16, 1, 0),
                Text           = default,
                PlaceholderText= placeholder,
                TextColor3     = ThemeColors.Text,
                PlaceholderColor3 = ThemeColors.TextSecondary,
                TextSize       = 12,
                Font           = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = clearOnFocus,
                ZIndex         = 7,
                Parent         = inputFrame,
            })
            BindTheme(textBox, "TextColor3", "Text")

            textBox.Focused:Connect(function()
                Tween(inputStroke, {Color = ThemeColors.Accent}, 0.2)
            end)
            textBox.FocusLost:Connect(function(enterPressed)
                Tween(inputStroke, {Color = ThemeColors.ControlStroke}, 0.2)
                value = textBox.Text
                if flag then Window.Flags[flag] = value end
                if callback then task.spawn(callback, value, enterPressed) end
                if Window._autoSaveEnabled then Window:_AutoSave() end
            end)

            local api = {Value = value}
            function api:Set(v)
                value = v
                textBox.Text = v
                if flag then Window.Flags[flag] = v end
            end
            function api:Get() return textBox.Text end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: KEYBIND
        -- ============================================================
        function Section:AddKeybind(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Keybind"
            local default  = cfg.Default  or Enum.KeyCode.Unknown
            local flag     = cfg.Flag
            local callback = cfg.Callback

            local currentKey = default
            local isListening= false
            local heldState  = false

            if flag then Window.Flags[flag] = currentKey end

            local container = Create("Frame", {
                Name             = "Keybind_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 36),
                ZIndex           = 6,
                Parent           = contentHolder,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(1, -80, 1, 0),
                Text       = name,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = container,
            })

            local keyBtn = Create("TextButton", {
                BackgroundColor3 = ThemeColors.InputBackground,
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, 0, 0.5, 0),
                Size             = UDim2.new(0, 70, 0, 24),
                Text             = currentKey.Name,
                TextColor3       = ThemeColors.Accent,
                TextSize         = 12,
                Font             = Enum.Font.GothamBold,
                ZIndex           = 7,
                Parent           = container,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color     = ThemeColors.ControlStroke,
                    Thickness = 1,
                }),
            })
            BindTheme(keyBtn, "TextColor3", "Accent")
            BindTheme(keyBtn, "BackgroundColor3", "InputBackground")

            local blinkConn
            local function StartListening()
                isListening   = true
                keyBtn.Text   = "..."
                keyBtn.TextColor3 = ThemeColors.WarningColor
                local blink = true
                blinkConn = task.spawn(function()
                    while isListening do
                        keyBtn.TextTransparency = blink and 0 or 0.5
                        blink = not blink
                        task.wait(0.4)
                    end
                end)
            end

            local function StopListening(key)
                isListening = false
                keyBtn.TextTransparency = 0
                if key and key ~= Enum.KeyCode.Escape then
                    currentKey = key
                    if flag then Window.Flags[flag] = key end
                end
                keyBtn.Text      = currentKey.Name
                keyBtn.TextColor3= ThemeColors.Accent
            end

            keyBtn.MouseButton1Click:Connect(function()
                if isListening then
                    StopListening(nil)
                else
                    StartListening()
                end
            end)

            local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if isListening then
                    StopListening(input.KeyCode)
                elseif input.KeyCode == currentKey then
                    heldState = true
                    if callback then task.spawn(callback, true) end
                end
            end)
            local keyEndConn = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == currentKey then
                    heldState = false
                    if callback then task.spawn(callback, false) end
                end
            end)
            table.insert(Window._connections, keyConn)
            table.insert(Window._connections, keyEndConn)

            local api = {Value = currentKey}
            function api:Set(key)
                currentKey = key
                keyBtn.Text = key.Name
                if flag then Window.Flags[flag] = key end
            end
            function api:Get() return currentKey end
            function api:GetState() return heldState end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: COLOR PICKER
        -- ============================================================
        function Section:AddColorPicker(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Color"
            local default  = cfg.Default  or Color3.fromHex("#FF0000")
            local flag     = cfg.Flag
            local callback = cfg.Callback

            local currentColor = default
            if flag then Window.Flags[flag] = currentColor end

            local container = Create("Frame", {
                Name             = "ColorPicker_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = true,
                ZIndex           = 6,
                Parent           = contentHolder,
            })

            local headerRow = Create("Frame", {
                BackgroundTransparency = 1,
                Size     = UDim2.new(1, 0, 0, 36),
                ZIndex   = 6,
                Parent   = container,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(1, -40, 1, 0),
                Text       = name,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = headerRow,
            })

            local colorPreviewBtn = Create("TextButton", {
                BackgroundColor3 = currentColor,
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, 0, 0.5, 0),
                Size             = UDim2.new(0, 28, 0, 28),
                Text             = "",
                ZIndex           = 7,
                Parent           = headerRow,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
                Create("UIStroke", {
                    Color     = ThemeColors.ControlStroke,
                    Thickness = 1,
                }),
            })

            local isOpen     = false
            local pickerArea = Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 38),
                Size     = UDim2.new(1, 0, 0, 170),
                ZIndex   = 6,
                Parent   = container,
            })

            local pickerApi = CreateHSVPicker(pickerArea, currentColor, function(col)
                currentColor              = col
                colorPreviewBtn.BackgroundColor3 = col
                if flag then Window.Flags[flag] = col end
                if callback then task.spawn(callback, col) end
                if Window._autoSaveEnabled then Window:_AutoSave() end
            end, 7)

            colorPreviewBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    Tween(container, {Size = UDim2.new(1, 0, 0, 36 + 170 + 8)}, 0.25)
                else
                    Tween(container, {Size = UDim2.new(1, 0, 0, 36)}, 0.25)
                end
            end)

            local api = {Value = currentColor}
            function api:Set(col)
                currentColor = col
                colorPreviewBtn.BackgroundColor3 = col
                pickerApi:SetColor(col)
                if flag then Window.Flags[flag] = col end
            end
            function api:Get() return currentColor end

            table.insert(Window._controls, api)
            return api
        end

        -- ============================================================
        -- CONTROL: BUTTON
        -- ============================================================
        function Section:AddButton(cfg)
            cfg = cfg or {}
            local name          = cfg.Name     or "Button"
            local text          = cfg.Text     or name
            local style         = cfg.Style    or "Primary"
            local doubleConfirm = cfg.DoubleConfirm or false
            local callback      = cfg.Callback

            local bgColor, txtColor
            if style == "Primary" then
                bgColor  = ThemeColors.Accent
                txtColor = Color3.new(1, 1, 1)
            elseif style == "Secondary" then
                bgColor  = ThemeColors.ControlBackground
                txtColor = ThemeColors.Accent
            elseif style == "Danger" then
                bgColor  = ThemeColors.DangerColor
                txtColor = Color3.new(1, 1, 1)
            else
                bgColor  = ThemeColors.Accent
                txtColor = Color3.new(1, 1, 1)
            end

            local container = Create("Frame", {
                Name             = "Button_" .. name,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 34),
                ZIndex           = 6,
                Parent           = contentHolder,
            })
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(0.4, 0, 1, 0),
                Text       = name ~= text and name or "",
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = container,
            })

            local btn = Create("TextButton", {
                BackgroundColor3 = bgColor,
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, 0, 0.5, 0),
                Size             = UDim2.new(0.55, 0, 0, 28),
                Text             = text,
                TextColor3       = txtColor,
                TextSize         = 13,
                Font             = Enum.Font.GothamBold,
                ZIndex           = 7,
                Parent           = container,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            })

            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = darkenColor(bgColor, 0.1)}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = bgColor}, 0.15)
            end)

            local confirming = false
            local confirmTimer

            btn.MouseButton1Click:Connect(function()
                if doubleConfirm then
                    if not confirming then
                        confirming = true
                        local origText = btn.Text
                        btn.Text = "确认？"
                        btn.BackgroundColor3 = ThemeColors.WarningColor
                        confirmTimer = task.delay(2, function()
                            confirming = false
                            btn.Text = origText
                            btn.BackgroundColor3 = bgColor
                        end)
                    else
                        confirming = false
                        btn.Text = text
                        btn.BackgroundColor3 = bgColor
                        if callback then task.spawn(callback) end
                    end
                else
                    if callback then task.spawn(callback) end
                end
            end)

            local api = {}
            function api:SetText(t)
                text     = t
                btn.Text = t
            end
            function api:SetEnabled(enabled)
                btn.Active = enabled
                btn.BackgroundTransparency = enabled and 0 or 0.5
            end

            return api
        end

        -- ============================================================
        -- CONTROL: LABEL
        -- ============================================================
        function Section:AddLabel(cfg)
            cfg = cfg or {}
            local text     = cfg.Text  or "Label"
            local color    = cfg.Color or ThemeColors.Text
            local richText = cfg.RichText or false

            local lbl = Create("TextLabel", {
                Name             = "Label",
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 28),
                Text             = text,
                TextColor3       = color,
                TextSize         = 13,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                RichText         = richText,
                TextWrapped      = true,
                ZIndex           = 6,
                Parent           = contentHolder,
            })

            local api = {}
            function api:SetText(t)
                lbl.Text = t
            end
            function api:SetColor(c)
                lbl.TextColor3 = c
            end
            return api
        end

        -- ============================================================
        -- CONTROL: PARAGRAPH
        -- ============================================================
        function Section:AddParagraph(cfg)
            cfg = cfg or {}
            local title   = cfg.Title   or ""
            local content = cfg.Content or ""

            local container = Create("Frame", {
                Name             = "Paragraph",
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 50),
                ZIndex           = 6,
                Parent           = contentHolder,
            })

            local titleLbl = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 0),
                Size       = UDim2.new(1, 0, 0, 20),
                Text       = title,
                TextColor3 = ThemeColors.Text,
                TextSize   = 13,
                Font       = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex     = 6,
                Parent     = container,
            })

            local contentLbl = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position   = UDim2.new(0, 0, 0, 22),
                Size       = UDim2.new(1, 0, 0, 40),
                Text       = content,
                TextColor3 = ThemeColors.TextSecondary,
                TextSize   = 12,
                Font       = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped= true,
                ZIndex     = 6,
                Parent     = container,
            })

            -- Auto height
            local function UpdateHeight()
                local ts = TextService:GetTextSize(
                    content, 12, Enum.Font.Gotham,
                    Vector2.new(container.AbsoluteSize.X, 1000)
                )
                contentLbl.Size = UDim2.new(1, 0, 0, ts.Y)
                container.Size  = UDim2.new(1, 0, 0, 22 + ts.Y + 4)
            end
            task.defer(UpdateHeight)

            local api = {}
            function api:SetTitle(t)
                titleLbl.Text = t
            end
            function api:SetContent(c)
                content = c
                contentLbl.Text = c
                task.defer(UpdateHeight)
            end
            return api
        end

        return Section
    end

    -- ============================================================
    -- SETTINGS TAB BUILDER
    -- ============================================================

    local function BuildSettingsTab(contentFrame, pageTitleLabel, mainScroll, scrollLayout)
        pageTitleLabel.Text = "设置"

        -- Clear existing content
        for _, child in ipairs(mainScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        ---- SECTION: 配置档 ----
        local configSec = BuildSection(mainScroll, {Name = "配置档"})

        local configList = {}
        if saveConfigEnabled and execEnv.listfiles then
            local ok, files = pcall(execEnv.listfiles, configFolder)
            if ok and files then
                for _, f in ipairs(files) do
                    local name = f:match("([^/\\]+)%.json$")
                    if name then table.insert(configList, name) end
                end
            end
        end

        local selectedConfig = configList[1] or nil
        local configDropdown = configSec:AddDropdown({
            Name    = "配置文件",
            Items   = configList,
            Default = selectedConfig,
            Callback= function(v) selectedConfig = v end,
        })

        -- Buttons row
        local btnRow = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 34),
            ZIndex = 6,
            Parent = configSec._parent,
        }, {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding       = UDim.new(0, 6),
            }),
        })

        local function MakeSmallBtn(text, color, cb)
            local btn = Create("TextButton", {
                BackgroundColor3 = color or ThemeColors.ControlBackground,
                Size     = UDim2.new(0, 70, 0, 28),
                Text     = text,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 12,
                Font     = Enum.Font.GothamBold,
                ZIndex   = 7,
                Parent   = btnRow,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
            })
            btn.MouseButton1Click:Connect(function()
                if cb then cb() end
            end)
            return btn
        end

        -- New config inline input
        local newNameFrame = Create("Frame", {
            BackgroundColor3 = ThemeColors.InputBackground,
            Size     = UDim2.new(1, 0, 0, 28),
            ZIndex   = 6,
            Visible  = false,
            Parent   = configSec._parent,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
            Create("UIStroke", {Color = ThemeColors.ControlStroke, Thickness = 1}),
        })
        local newNameBox = Create("TextBox", {
            BackgroundTransparency = 1,
            Position   = UDim2.new(0, 8, 0, 0),
            Size       = UDim2.new(1, -70, 1, 0),
            PlaceholderText = "配置名称...",
            Text       = "",
            TextColor3 = ThemeColors.Text,
            TextSize   = 12,
            Font       = Enum.Font.Gotham,
            ZIndex     = 7,
            Parent     = newNameFrame,
        })
        local newNameConfirm = Create("TextButton", {
            BackgroundColor3 = ThemeColors.Accent,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -4, 0.5, 0),
            Size             = UDim2.new(0, 56, 0, 22),
            Text             = "确认",
            TextColor3       = Color3.new(1,1,1),
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 7,
            Parent           = newNameFrame,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        })

        newNameConfirm.MouseButton1Click:Connect(function()
            local cname = newNameBox.Text:gsub("%s+", "")
            if cname ~= "" then
                Window:SaveConfig(cname)
                newNameFrame.Visible = false
                newNameBox.Text = ""
                -- Refresh dropdown
                local newList = Window:GetConfigs()
                configDropdown:Refresh(newList)
                selectedConfig = cname
                configDropdown:Set(cname)
            end
        end)

        MakeSmallBtn("新建", ThemeColors.Accent, function()
            newNameFrame.Visible = not newNameFrame.Visible
        end)
        MakeSmallBtn("保存", ThemeColors.SuccessColor, function()
            if selectedConfig then
                Window:SaveConfig(selectedConfig)
                ShowNotification({Title="已保存", Content="配置 "..selectedConfig.." 已保存", Type="Success"}, sg)
            end
        end)
        MakeSmallBtn("删除", ThemeColors.DangerColor, function()
            if selectedConfig then
                ShowDialog({
                    Title   = "确认删除",
                    Content = "确定要删除配置 "" .. selectedConfig .. "" 吗？",
                    Buttons = {
                        {Text="删除", Danger=true, Callback=function()
                            Window:DeleteConfig(selectedConfig)
                            selectedConfig = nil
                            local newList = Window:GetConfigs()
                            configDropdown:Refresh(newList)
                        end},
                        {Text="取消"},
                    }
                }, sg)
            end
        end)

        configSec:AddToggle({
            Name    = "自动保存",
            Default = Window._autoSaveEnabled,
            Callback= function(v)
                Window._autoSaveEnabled = v
            end,
        })

        ---- SECTION: 外观 ----
        local appearSec = BuildSection(mainScroll, {Name = "外观"})

        -- Global accent color (HSV)
        appearSec:AddLabel({Text = "全局色调", TextColor3 = ThemeColors.TextSecondary})
        local accentPickerFrame = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 170),
            ZIndex = 6,
            Parent = appearSec._parent,
        })
        local accentPicker = CreateHSVPicker(accentPickerFrame, ThemeColors.Accent, function(col)
            ThemeColors.Accent    = col
            ThemeColors.AccentDark= darkenColor(col, 0.2)
            ThemeColors.ToggleOn  = col
            ThemeColors.SliderFill= col
            ApplyTheme()
        end, 7)

        -- Background color
        appearSec:AddLabel({Text = "背景色调", TextColor3 = ThemeColors.TextSecondary})
        local bgPickerFrame = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 170),
            ZIndex = 6,
            Parent = appearSec._parent,
        })
        local bgPicker = CreateHSVPicker(bgPickerFrame, ThemeColors.Background, function(col)
            local h, s, v = Color3.toHSV(col)
            ThemeColors.Background        = col
            ThemeColors.NavBackground     = Color3.fromHSV(h, s, math.max(0, v - 0.05))
            ThemeColors.ControlBackground = Color3.fromHSV(h, s, math.max(0, v + 0.04))
            ApplyTheme()
        end, 7)

        -- Single token override
        local tokenNames = {}
        for k in pairs(ThemeColors) do table.insert(tokenNames, k) end
        table.sort(tokenNames)

        local overriddenTokens = {}
        local selectedToken    = tokenNames[1]
        local singleOverrideVisible = false

        local tokenDropdown = appearSec:AddDropdown({
            Name    = "单项覆盖",
            Items   = tokenNames,
            Default = selectedToken,
            Callback= function(v) selectedToken = v end,
        })

        local singlePickerFrame = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 0),
            ClipsDescendants = true,
            ZIndex = 6,
            Parent = appearSec._parent,
        })
        local singlePickerInner = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 170),
            ZIndex = 6,
            Parent = singlePickerFrame,
        })
        local singlePicker = CreateHSVPicker(singlePickerInner,
            ThemeColors[tokenNames[1]] or Color3.new(1,1,1),
            function(col)
                if selectedToken then
                    ThemeColors[selectedToken] = col
                    overriddenTokens[selectedToken] = true
                    ApplyTheme()
                end
            end, 7)

        local overrideRow = Create("Frame", {
            BackgroundTransparency = 1,
            Size   = UDim2.new(1, 0, 0, 28),
            ZIndex = 6,
            Parent = appearSec._parent,
        })
        local showOverrideBtn = Create("TextButton", {
            BackgroundColor3 = ThemeColors.Accent,
            Size     = UDim2.new(0, 90, 0, 24),
            Text     = "选择颜色",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font     = Enum.Font.GothamBold,
            ZIndex   = 7,
            Parent   = overrideRow,
        }, {Create("UICorner", {CornerRadius = UDim.new(0, 4)})})

        local resetOverrideBtn = Create("TextButton", {
            BackgroundColor3 = ThemeColors.DangerColor,
            Position = UDim2.new(0, 98, 0, 0),
            Size     = UDim2.new(0, 60, 0, 24),
            Text     = "重置",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 12,
            Font     = Enum.Font.GothamBold,
            ZIndex   = 7,
            Parent   = overrideRow,
        }, {Create("UICorner", {CornerRadius = UDim.new(0, 4)})})

        showOverrideBtn.MouseButton1Click:Connect(function()
            singleOverrideVisible = not singleOverrideVisible
            if selectedToken and ThemeColors[selectedToken] then
                singlePicker:SetColor(ThemeColors[selectedToken])
            end
            Tween(singlePickerFrame,
                {Size = UDim2.new(1, 0, 0, singleOverrideVisible and 175 or 0)},
                0.25)
        end)
        resetOverrideBtn.MouseButton1Click:Connect(function()
            if selectedToken then
                overriddenTokens[selectedToken] = false
            end
        end)

        -- UI Scale
        appearSec:AddSlider({
            Name    = "界面缩放",
            Min     = 0.8,
            Max     = 1.3,
            Default = Window._uiScale,
            Step    = 0.05,
            Callback= function(v)
                Window._uiScale = v
                uiScaleInst.Scale = v
            end,
        })

        ---- SECTION: 行为 ----
        local behaviorSec = BuildSection(mainScroll, {Name = "行为"})

        behaviorSec:AddKeybind({
            Name    = "开关键",
            Default = toggleKey,
            Callback= function(state)
                -- toggle handled by Window
            end,
        })

        behaviorSec:AddToggle({
            Name    = "动画",
            Default = animationsEnabled,
            Callback= function(v)
                animationsEnabled = v
            end,
        })

        behaviorSec:AddToggle({
            Name    = "关闭确认",
            Default = Window._settings.closeConfirm,
            Callback= function(v)
                Window._settings.closeConfirm = v
            end,
        })

        behaviorSec:AddDropdown({
            Name  = "通知位置",
            Items = {"右上", "左上", "右下", "顶部居中"},
            Default = "右上",
            Callback= function(v)
                local map = {["右上"]="TopRight",["左上"]="TopLeft",["右下"]="BottomRight",["顶部居中"]="TopCenter"}
                notifyPosition = map[v] or "TopRight"
                SetupNotifyContainer(sg, notifyPosition)
            end,
        })

        ---- SECTION: 关于 ----
        local aboutSec = BuildSection(mainScroll, {Name = "关于"})

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 0, 30),
            Text       = "LogZ-UI",
            TextColor3 = ThemeColors.Accent,
            TextSize   = 16,
            Font       = Enum.Font.GothamBlack,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 6,
            Parent     = aboutSec._parent,
        })
        BindTheme(Create("TextLabel", {
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 0, 22),
            Text       = "by log_quick",
            TextColor3 = ThemeColors.TextSecondary,
            TextSize   = 13,
            Font       = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 6,
            Parent     = aboutSec._parent,
        }), "TextColor3", "TextSecondary")
        BindTheme(Create("TextLabel", {
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 0, 20),
            Text       = "v1.0.0",
            TextColor3 = ThemeColors.TextSecondary,
            TextSize   = 12,
            Font       = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 6,
            Parent     = aboutSec._parent,
        }), "TextColor3", "TextSecondary")

        aboutSec:AddButton({
            Name  = "调试信息",
            Text  = "复制调试信息",
            Style = "Secondary",
            Callback= function()
                local vp   = Camera.ViewportSize
                local exid = execEnv.identifyexecutor and execEnv.identifyexecutor() or "Unknown"
                local info = string.format(
                    "LogZ-UI v1.0.0\nExecutor: %s\nResolution: %dx%d\nPlaceId: %s",
                    exid,
                    math.floor(vp.X), math.floor(vp.Y),
                    tostring(game.PlaceId)
                )
                if execEnv.setclipboard then
                    pcall(execEnv.setclipboard, info)
                    ShowNotification({Title="已复制", Content="调试信息已复制到剪贴板", Type="Success"}, sg)
                end
            end,
        })
    end

    -- ============================================================
    -- TAB SYSTEM
    -- ============================================================

    local function SwitchToTab(tab)
        -- Clear content
        for _, child in ipairs(mainScroll:GetChildren()) do
            if child:IsA("Frame") and child.Name:sub(1, 8) == "Section_" then
                child:Destroy()
            end
        end

        Window._activeTab = tab
        pageTitleLabel.Text = tab.Name

        -- Rebuild sections into mainScroll
        for _, section in ipairs(tab._sections) do
            section._frame.Parent = mainScroll
        end

        -- Update nav button appearances
        for _, t in ipairs(Window._tabs) do
            if t._navBtn then
                local isActive = (t == tab)
                Tween(t._navBtn, {
                    BackgroundColor3 = isActive
                        and Color3.fromRGB(
                            math.floor(ThemeColors.Accent.R * 255 * 0.12),
                            math.floor(ThemeColors.Accent.G * 255 * 0.12),
                            math.floor(ThemeColors.Accent.B * 255 * 0.12))
                        or Color3.new(0, 0, 0),
                    BackgroundTransparency = isActive and 0 or 1,
                }, 0.2)
                if t._navText then
                    Tween(t._navText, {
                        TextColor3 = isActive and ThemeColors.Accent or ThemeColors.TextSecondary
                    }, 0.2)
                end
                if t._navIcon then
                    Tween(t._navIcon, {
                        ImageColor3 = isActive and ThemeColors.Accent or ThemeColors.TextSecondary
                    }, 0.2)
                end
            end
        end

        -- Move indicator
        if tab._navBtn then
            local absPos = tab._navBtn.AbsolutePosition
            local navAbs = navFrame.AbsolutePosition
            local relY   = absPos.Y - navAbs.Y + tab._navBtn.AbsoluteSize.Y / 2 - 10
            Tween(tabIndicator, {Position = UDim2.new(0, 0, 0, relY)}, 0.25)
        end
    end

    function Window:AddTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local tabIcon = config.Icon or "rbxassetid://7734053495"

        local tab = {
            Name      = tabName,
            _sections = {},
            _navBtn   = nil,
            _navText  = nil,
            _navIcon  = nil,
            _window   = self,
        }

        -- Nav button
        local navBtn = Create("TextButton", {
            Name             = "TabBtn_" .. tabName,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 38),
            Text             = "",
            ZIndex           = 5,
            Parent           = navScroll,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        })
        tab._navBtn = navBtn

        local navIcon = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Position   = UDim2.new(0, 10, 0.5, -9),
            Size       = UDim2.new(0, 18, 0, 18),
            Image      = tabIcon,
            ImageColor3= ThemeColors.TextSecondary,
            ZIndex     = 6,
            Parent     = navBtn,
        })
        tab._navIcon = navIcon

        local navText = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position   = UDim2.new(0, 34, 0, 0),
            Size       = UDim2.new(1, -42, 1, 0),
            Text       = tabName,
            TextColor3 = ThemeColors.TextSecondary,
            TextSize   = 13,
            Font       = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 6,
            Parent     = navBtn,
        })
        tab._navText = navText

        navBtn.MouseButton1Click:Connect(function()
            SwitchToTab(tab)
        end)
        navBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= tab then
                Tween(navBtn, {BackgroundTransparency = 0.95}, 0.15)
                navBtn.BackgroundColor3 = ThemeColors.Accent
            end
        end)
        navBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= tab then
                Tween(navBtn, {BackgroundTransparency = 1}, 0.15)
            end
        end)

        table.insert(Window._tabs, tab)

        -- Switch to first tab
        if #Window._tabs == 1 then
            SwitchToTab(tab)
        end

        -- Tab API
        function tab:AddSection(sectionConfig)
            local section = BuildSection(nil, sectionConfig)
            -- Create the actual frame, parent will be set on switch
            local secFrame = Create("Frame", {
                Name             = "Section_" .. (sectionConfig and sectionConfig.Name or "Section"),
                BackgroundColor3 = ThemeColors.ControlBackground,
                Size             = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = true,
                ZIndex           = 4,
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {
                    Color     = ThemeColors.ControlStroke,
                    Thickness = 1,
                }),
            })
            BindTheme(secFrame, "BackgroundColor3", "ControlBackground")

            -- Re-build proper section tied to a persistent frame
            local realSection = BuildSection(
                Window._activeTab == tab and mainScroll or nil,
                sectionConfig
            )
            realSection._tabRef = tab
            table.insert(tab._sections, realSection)

            if Window._activeTab == tab then
                -- Already visible, section was built into mainScroll
            end

            return realSection
        end

        return tab
    end

    -- Settings tab (built lazily on click)
    settingsBtn.MouseButton1Click:Connect(function()
        -- Clear all existing sections from scroll
        for _, child in ipairs(mainScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        -- Deselect tabs
        for _, t in ipairs(Window._tabs) do
            if t._navBtn then
                Tween(t._navBtn, {BackgroundTransparency = 1}, 0.2)
                if t._navText then Tween(t._navText, {TextColor3 = ThemeColors.TextSecondary}, 0.2) end
                if t._navIcon then Tween(t._navIcon, {ImageColor3 = ThemeColors.TextSecondary}, 0.2) end
            end
        end
        Window._activeTab = nil
        BuildSettingsTab(contentFrame, pageTitleLabel, mainScroll, scrollLayout)
    end)

    -- ============================================================
    -- WINDOW API METHODS
    -- ============================================================

    function Window:AddDivider()
        local div = Create("Frame", {
            Name             = "Divider",
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -12, 0, 17),
            ZIndex           = 4,
            Parent           = navScroll,
        })
        Create("Frame", {
            BackgroundColor3 = ThemeColors.ControlStroke,
            BackgroundTransparency = 0.5,
            AnchorPoint = Vector2.new(0, 0.5),
            Position    = UDim2.new(0, 0, 0.5, 0),
            Size        = UDim2.new(1, 0, 0, 1),
            ZIndex      = 4,
            Parent      = div,
        })
    end

    -- ---- SetTitle ----
    function Window:SetTitle(config)
        config = config or {}

        local newTitle     = config.Title
        local newSubTitle  = config.SubTitle
        local newLogoId    = config.LogoId
        local newShowLogo  = config.ShowLogo
        local newAlignment = config.Alignment

        -- Fade out
        Tween(titleLabel,    {TextTransparency = 1}, 0.15)
        Tween(subTitleLabel, {TextTransparency = 1}, 0.15)
        Tween(logoImage,     {ImageTransparency = 1}, 0.15)

        task.delay(0.18, function()
            if newTitle    ~= nil then
                self._currentTitle = newTitle
                titleLabel.Text    = newTitle
            end
            if newSubTitle ~= nil then
                self._currentSub   = newSubTitle
                subTitleLabel.Text = newSubTitle
            end
            if newLogoId   ~= nil then
                self._currentLogo  = newLogoId
                logoImage.Image    = newLogoId
            end
            if newShowLogo  ~= nil then
                self._showLogo = newShowLogo
            end
            if newAlignment ~= nil then
                self._titleAlignment = newAlignment
            end

            UpdateTitleLayout()

            -- Fade in
            Tween(titleLabel,    {TextTransparency = 0}, 0.2)
            Tween(subTitleLabel, {TextTransparency = 0}, 0.2)
            Tween(logoImage,     {ImageTransparency = 0}, 0.2)
        end)
    end

    -- ---- ResetTitle ----
    function Window:ResetTitle()
        self:SetTitle({
            Title     = self._defaultTitle,
            SubTitle  = self._defaultSub,
            LogoId    = self._defaultLogo,
            ShowLogo  = true,
            Alignment = "Left",
        })
    end

    -- ---- Notify ----
    function Window:Notify(config)
        ShowNotification(config, sg)
    end

    -- ---- Dialog ----
    function Window:Dialog(config)
        ShowDialog(config, sg)
    end

    -- ---- SetTheme ----
    function Window:SetTheme(themeTable)
        for k, v in pairs(themeTable) do
            if ThemeColors[k] ~= nil then
                ThemeColors[k] = v
            end
        end
        ApplyTheme()
    end

    -- ---- Config persistence ----
    function Window:_AutoSave()
        if self._autoSaveDebounce then
            task.cancel(self._autoSaveDebounce)
        end
        self._autoSaveDebounce = task.delay(2, function()
            local configs = self:GetConfigs()
            if #configs > 0 then
                self:SaveConfig(configs[1])
            end
        end)
    end

    function Window:SaveConfig(name)
        if not execEnv.writefile or not execEnv.makefolder then return end
        pcall(execEnv.makefolder, self._configFolder)
        local data = {}
        for flag, val in pairs(self.Flags) do
            if type(val) == "boolean" or type(val) == "number"
            or type(val) == "string"  or type(val) == "table" then
                data[flag] = val
            elseif type(val) == "userdata" then
                -- Color3
                if typeof(val) == "Color3" then
                    data[flag] = {__type="Color3", r=val.R, g=val.G, b=val.B}
                elseif typeof(val) == "EnumItem" then
                    data[flag] = {__type="EnumItem", name=val.Name, enum=tostring(val.EnumType)}
                end
            end
        end
        local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
        if ok then
            pcall(execEnv.writefile, self._configFolder .. "/" .. name .. ".json", json)
        end
    end

    function Window:LoadConfig(name)
        if not execEnv.readfile then return end
        local path = self._configFolder .. "/" .. name .. ".json"
        local ok1, content = pcall(execEnv.readfile, path)
        if not ok1 then return end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
        if not ok2 or type(data) ~= "table" then return end

        for flag, val in pairs(data) do
            self.Flags[flag] = val
            -- Find and update control
            for _, ctrl in ipairs(self._controls) do
                if ctrl._flag == flag then
                    if ctrl.Set then ctrl:Set(val) end
                end
            end
        end
    end

    function Window:GetConfigs()
        if not execEnv.listfiles then return {} end
        local ok, files = pcall(execEnv.listfiles, self._configFolder)
        if not ok or not files then return {} end
        local result = {}
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(result, name) end
        end
        return result
    end

    function Window:DeleteConfig(name)
        if not execEnv.delfile then return end
        pcall(execEnv.delfile, self._configFolder .. "/" .. name .. ".json")
    end

    function Window:Destroy()
        for _, conn in ipairs(self._connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        if sg then sg:Destroy() end
    end

    -- ============================================================
    -- MOBILE ADAPTATIONS
    -- ============================================================

    if isMobile then
        -- Full screen with margin
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.Position    = UDim2.new(0.5, 0, 0.5, 0)
        mainFrame.Size        = UDim2.new(1, -20, 1, -20)

        -- Remove corner radius
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child:IsA("UICorner") then child.CornerRadius = UDim.new(0,0) end
        end

        -- Nav hidden by default
        navFrame.Visible = false

        -- Hamburger opens nav
        local navOverlay = Create("Frame", {
            BackgroundColor3 = Color3.new(0,0,0),
            BackgroundTransparency = 0.5,
            Size   = UDim2.new(1, 0, 1, 0),
            ZIndex = 20,
            Visible= false,
            Parent = mainFrame,
        })

        local function OpenMobileNav()
            navFrame.Visible = true
            navFrame.Size    = UDim2.new(0, 0, 1, -35)
            navFrame.ZIndex  = 25
            navOverlay.Visible = true
            local navW = math.min(Camera.ViewportSize.X * 0.65, 280)
            Tween(navFrame, {Size = UDim2.new(0, navW, 1, -35)}, 0.3, Enum.EasingStyle.Back)
        end

        local function CloseMobileNav()
            Tween(navFrame, {Size = UDim2.new(0, 0, 1, -35)}, 0.25)
            task.delay(0.3, function()
                navFrame.Visible   = false
                navOverlay.Visible = false
            end)
        end

        hamburgerBtn.MouseButton1Click:Connect(OpenMobileNav)
        navOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                CloseMobileNav()
            end
        end)

        -- Content area adjust
        contentFrame.Position = UDim2.new(0, 0, 0, 35)
        contentFrame.Size     = UDim2.new(1, 0, 1, -35)

        -- FAB toggle button
        local fabBtn = Create("TextButton", {
            Name             = "FAB",
            BackgroundColor3 = ThemeColors.Accent,
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.new(1, -36, 1, -80),
            Size             = UDim2.new(0, 50, 0, 50),
            Text             = "☰",
            TextColor3       = Color3.new(1,1,1),
            TextSize         = 20,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 200,
            Parent           = sg,
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0.5, 0)}),
        })
        BindTheme(fabBtn, "BackgroundColor3", "Accent")

        -- FAB drag to edge snap
        local fabDragging = false
        local fabDragStart
        local fabStartPos
        fabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                fabDragging  = true
                fabDragStart = input.Position
                fabStartPos  = fabBtn.Position
            end
        end)
        local fabMoveConn = UserInputService.InputChanged:Connect(function(input)
            if fabDragging and (input.UserInputType == Enum.UserInputType.TouchMovement
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - fabDragStart
                fabBtn.Position = UDim2.new(0,
                    fabStartPos.X.Offset + delta.X,
                    0,
                    fabStartPos.Y.Offset + delta.Y
                )
            end
        end)
        local fabEndConn = UserInputService.InputEnded:Connect(function(input)
            if fabDragging then
                fabDragging = false
                -- Snap to nearest edge
                local vp   = Camera.ViewportSize
                local posX = fabBtn.AbsolutePosition.X + 25
                if posX < vp.X / 2 then
                    Tween(fabBtn, {Position = UDim2.new(0, 36, 0, fabBtn.AbsolutePosition.Y + 25)}, 0.3)
                else
                    Tween(fabBtn, {Position = UDim2.new(0, vp.X - 36, 0, fabBtn.AbsolutePosition.Y + 25)}, 0.3)
                end
            end
        end)
        table.insert(Window._connections, fabMoveConn)
        table.insert(Window._connections, fabEndConn)

        fabBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
        end)
    end

    -- ============================================================
    -- INITIAL TITLE SETUP
    -- ============================================================

    -- Set subtitle text and position
    titleLabel.Text    = titleDefault
    subTitleLabel.Text = subTitleDefault
    Window._showLogo   = true
    UpdateTitleLayout()

    -- ============================================================
    -- LOADING SCREEN
    -- ============================================================

    if showLoading then
        ShowLoadingScreen(sg, function() end)
    end

    return Window
end

-- ============================================================
-- EXAMPLE USAGE (as comments)
-- ============================================================

--[[
local LogZ = loadstring(game:HttpGet("..."))()

local Window = LogZ.CreateWindow({
    Title        = "My Script Hub",
    SubTitle     = "v2.0",
    AccentColor  = Color3.fromHex("#FF6B6B"),
    SaveConfig   = true,
    ConfigFolder = "MyHub_Configs",
})

-- Customize top bar
Window:SetTitle({ Title = "Combat Mode", SubTitle = "Active" })

-- Reset to defaults
Window:ResetTitle()

local MainTab = Window:AddTab({ Name = "Main", Icon = "rbxassetid://7733960981" })
local CombatSection = MainTab:AddSection({ Name = "Combat Settings" })

CombatSection:AddToggle({
    Name     = "Kill Aura",
    Flag     = "KillAura",
    Default  = false,
    Callback = function(v) print("Kill Aura:", v) end,
})

CombatSection:AddSlider({
    Name     = "Range",
    Min      = 1,
    Max      = 50,
    Default  = 15,
    Step     = 1,
    Suffix   = " studs",
    Flag     = "KillAuraRange",
    Callback = function(v) print("Range:", v) end,
})

CombatSection:AddDropdown({
    Name     = "Target",
    Items    = {"Nearest", "Random", "Weakest"},
    Default  = "Nearest",
    Flag     = "AuraTarget",
    Callback = function(v) print("Target:", v) end,
})

CombatSection:AddColorPicker({
    Name     = "Aura Color",
    Default  = Color3.fromRGB(255, 0, 0),
    Flag     = "AuraColor",
    Callback = function(c) print("Color:", c) end,
})

CombatSection:AddKeybind({
    Name     = "Toggle Key",
    Default  = Enum.KeyCode.F,
    Flag     = "AuraKey",
    Callback = function(held) print("Held:", held) end,
})

CombatSection:AddButton({
    Name     = "Destroy All",
    Text     = "Execute",
    Style    = "Danger",
    DoubleConfirm = true,
    Callback = function() print("Executed!") end,
})

CombatSection:AddInput({
    Name        = "Walk Speed",
    Placeholder = "Enter speed...",
    Default     = "16",
    Flag        = "WalkSpeed",
    Callback    = function(v, enter) print("Speed:", v) end,
})

CombatSection:AddLabel({ Text = "Powered by LogZ-UI" })

CombatSection:AddParagraph({
    Title   = "Instructions",
    Content = "Enable Kill Aura to automatically attack enemies within range.",
})

Window:Notify({
    Title    = "Welcome",
    Content  = "Script loaded successfully!",
    Type     = "Success",
    Duration = 5,
})

Window:AddDivider()
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "rbxassetid://7734053495" })
]]

return LogZ
