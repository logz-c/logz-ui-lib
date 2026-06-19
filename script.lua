--[[
    VapeUI Library - Complete Roblox UI Library
    Vape-style, Cross-platform (PC + Mobile)
    Mounts to CoreGui
    Full OOP Metatable Architecture
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local Utility = {}

function Utility.Create(className, properties, children)
    local instance = Instance.new(className)
    if properties then
        for prop, value in pairs(properties) do
            if prop ~= "Parent" then
                pcall(function()
                    instance[prop] = value
                end)
            end
        end
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    return instance
end

function Utility.Tween(instance, tweenInfo, properties, callback)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    if callback then
        tween.Completed:Connect(callback)
    end
    return tween
end

function Utility.Ripple(button, position)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        Parent = button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, position.X - button.AbsolutePosition.X, 0, position.Y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 5,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple,
    })
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    Utility.Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1,
    }, function()
        ripple:Destroy()
    end)
end

function Utility.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utility.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Utility.ClampPosition(pos, size, viewportSize)
    local insetTop = GuiService:GetGuiInset().Y
    local maxX = viewportSize.X - size.X
    local maxY = viewportSize.Y - size.Y - insetTop
    local clampedX = math.clamp(pos.X, 0, math.max(0, maxX))
    local clampedY = math.clamp(pos.Y, 0, math.max(0, maxY))
    return UDim2.new(0, clampedX, 0, clampedY)
end

function Utility.GetViewportSize()
    return Camera.ViewportSize
end

function Utility.IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utility.Color3ToTable(color)
    return {R = color.R, G = color.G, B = color.B}
end

function Utility.TableToColor3(tbl)
    return Color3.new(tbl.R or 0, tbl.G or 0, tbl.B or 0)
end

function Utility.EnumToString(enumItem)
    return tostring(enumItem)
end

function Utility.StringToKeyCode(str)
    local success, result = pcall(function()
        return Enum.KeyCode[str]
    end)
    if success then return result end
    return Enum.KeyCode.RightShift
end

-- ============================================================
-- SOUND ENGINE
-- ============================================================
local SoundEngine = {}
SoundEngine.__index = SoundEngine

function SoundEngine.new()
    local self = setmetatable({}, SoundEngine)
    self.Enabled = true
    self.Volume = 0.5
    self.Sounds = {}
    self._container = Utility.Create("Folder", {
        Name = "VapeUI_Sounds",
        Parent = CoreGui,
    })
    self:_preload()
    return self
end

function SoundEngine:_preload()
    self.Sounds.Click = self:_createSound("rbxassetid://6895079853", 0.3)
    self.Sounds.Slide = self:_createSound("rbxassetid://421058925", 0.2)
    self.Sounds.Toggle = self:_createSound("rbxassetid://6895079853", 0.25)
    self.Sounds.Open = self:_createSound("rbxassetid://6895079853", 0.35)
    self.Sounds.Close = self:_createSound("rbxassetid://6895079853", 0.3)
    self.Sounds.Notify = self:_createSound("rbxassetid://6895079853", 0.4)
    self.Sounds.Welcome = self:_createSound("rbxassetid://6895079853", 0.5)
end

function SoundEngine:_createSound(id, volume)
    local sound = Utility.Create("Sound", {
        SoundId = id,
        Volume = volume * self.Volume,
        Parent = self._container,
    })
    return sound
end

function SoundEngine:Play(soundName)
    if not self.Enabled then return end
    local sound = self.Sounds[soundName]
    if sound then
        local clone = sound:Clone()
        clone.Volume = sound.Volume * (self.Volume / 0.5)
        clone.Parent = self._container
        clone:Play()
        clone.Ended:Connect(function()
            clone:Destroy()
        end)
    end
end

function SoundEngine:SetVolume(vol)
    self.Volume = math.clamp(vol, 0, 1)
end

function SoundEngine:SetEnabled(enabled)
    self.Enabled = enabled
end

function SoundEngine:Destroy()
    self._container:Destroy()
end

-- ============================================================
-- COLOR ENGINE
-- ============================================================
local ColorEngine = {}
ColorEngine.__index = ColorEngine

function ColorEngine.new()
    local self = setmetatable({}, ColorEngine)
    self.Mode = "Static"
    self.PrimaryColor = Color3.fromRGB(81, 137, 253)
    self.SecondaryColor = Color3.fromRGB(180, 80, 255)
    self.Speed = 1
    self.BreathAmplitude = 0.5
    self.GradientRotation = 0
    self.CurrentColor = self.PrimaryColor
    self.CurrentSecondary = self.SecondaryColor
    self._connections = {}
    self._listeners = {}
    self._running = true
    self:_startEngine()
    return self
end

function ColorEngine:_startEngine()
    task.spawn(function()
        while self._running do
            self:_update()
            task.wait(1 / 60)
        end
    end)
end

function ColorEngine:_update()
    local t = tick()
    if self.Mode == "Static" then
        self.CurrentColor = self.PrimaryColor
        self.CurrentSecondary = self.SecondaryColor
    elseif self.Mode == "Breathing" then
        local breath = (math.sin(t * self.Speed * 2) + 1) / 2
        local factor = 1 - (self.BreathAmplitude * (1 - breath))
        local h, s, v = self.PrimaryColor:ToHSV()
        self.CurrentColor = Color3.fromHSV(h, s, v * factor)
        local h2, s2, v2 = self.SecondaryColor:ToHSV()
        self.CurrentSecondary = Color3.fromHSV(h2, s2, v2 * factor)
    elseif self.Mode == "Rainbow" then
        local hue = (t * self.Speed * 0.1) % 1
        self.CurrentColor = Color3.fromHSV(hue, 0.8, 1)
        self.CurrentSecondary = Color3.fromHSV((hue + 0.3) % 1, 0.8, 1)
    elseif self.Mode == "Gradient" then
        local factor = (math.sin(t * self.Speed) + 1) / 2
        self.CurrentColor = self.PrimaryColor:Lerp(self.SecondaryColor, factor)
        self.CurrentSecondary = self.SecondaryColor:Lerp(self.PrimaryColor, factor)
    elseif self.Mode == "Rainbow-Wave" then
        local hue = (t * self.Speed * 0.08) % 1
        self.CurrentColor = Color3.fromHSV(hue, 0.9, 1)
        self.CurrentSecondary = Color3.fromHSV((hue + 0.5) % 1, 0.9, 1)
    end
    for _, listener in ipairs(self._listeners) do
        pcall(listener, self.CurrentColor, self.CurrentSecondary)
    end
end

function ColorEngine:OnColorChanged(callback)
    table.insert(self._listeners, callback)
end

function ColorEngine:SetMode(mode)
    self.Mode = mode
end

function ColorEngine:SetPrimary(color)
    self.PrimaryColor = color
end

function ColorEngine:SetSecondary(color)
    self.SecondaryColor = color
end

function ColorEngine:SetSpeed(speed)
    self.Speed = math.clamp(speed, 0.1, 5)
end

function ColorEngine:SetBreathAmplitude(amp)
    self.BreathAmplitude = math.clamp(amp, 0, 1)
end

function ColorEngine:SetGradientRotation(rot)
    self.GradientRotation = rot
end

function ColorEngine:Destroy()
    self._running = false
    self._listeners = {}
end

-- ============================================================
-- CONFIG MANAGER
-- ============================================================
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(libraryName)
    local self = setmetatable({}, ConfigManager)
    self.LibraryName = libraryName or "VapeUI"
    self.FolderName = self.LibraryName .. "_Configs"
    self.Flags = {}
    self.AutoSave = false
    self.CurrentProfile = "default"
    self:_ensureFolder()
    return self
end

function ConfigManager:_ensureFolder()
    pcall(function()
        if not isfolder(self.FolderName) then
            makefolder(self.FolderName)
        end
    end)
end

function ConfigManager:SetFlag(flag, value)
    self.Flags[flag] = value
    if self.AutoSave then
        self:Save(self.CurrentProfile)
    end
end

function ConfigManager:GetFlag(flag, default)
    if self.Flags[flag] ~= nil then
        return self.Flags[flag]
    end
    return default
end

function ConfigManager:Save(profileName)
    profileName = profileName or self.CurrentProfile
    local data = {}
    for flag, value in pairs(self.Flags) do
        if type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
            data[flag] = value
        elseif typeof(value) == "Color3" then
            data[flag] = {_type = "Color3", R = value.R, G = value.G, B = value.B}
        elseif typeof(value) == "EnumItem" then
            data[flag] = {_type = "EnumItem", Value = tostring(value)}
        elseif type(value) == "table" then
            data[flag] = value
        end
    end
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if success then
        pcall(function()
            writefile(self.FolderName .. "/" .. profileName .. ".json", encoded)
        end)
    end
end

function ConfigManager:Load(profileName)
    profileName = profileName or self.CurrentProfile
    local success, content = pcall(function()
        return readfile(self.FolderName .. "/" .. profileName .. ".json")
    end)
    if success and content then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if decodeSuccess and data then
            for flag, value in pairs(data) do
                if type(value) == "table" and value._type then
                    if value._type == "Color3" then
                        self.Flags[flag] = Color3.new(value.R, value.G, value.B)
                    elseif value._type == "EnumItem" then
                        self.Flags[flag] = value.Value
                    end
                else
                    self.Flags[flag] = value
                end
            end
            return true
        end
    end
    return false
end

function ConfigManager:GetProfileList()
    local profiles = {}
    pcall(function()
        local files = listfiles(self.FolderName)
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(profiles, name)
            end
        end
    end)
    return profiles
end

function ConfigManager:Delete(profileName)
    pcall(function()
        delfile(self.FolderName .. "/" .. profileName .. ".json")
    end)
end

-- ============================================================
-- DRAG HANDLER (Cross-platform: Mouse + Touch)
-- ============================================================
local DragHandler = {}
DragHandler.__index = DragHandler

function DragHandler.new(frame, handle, magneticSnap, onPositionChanged)
    local self = setmetatable({}, DragHandler)
    self.Frame = frame
    self.Handle = handle or frame
    self.MagneticSnap = magneticSnap or false
    self.SnapThreshold = 20
    self.OnPositionChanged = onPositionChanged
    self._dragging = false
    self._dragStart = nil
    self._startPos = nil
    self._connections = {}
    self:_setup()
    return self
end

function DragHandler:_setup()
    local function inputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._dragStart = Vector2.new(input.Position.X, input.Position.Y)
            self._startPos = self.Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self._dragging = false
                end
            end)
        end
    end

    local function inputChanged(input)
        if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - self._dragStart
            local newPos = UDim2.new(
                self._startPos.X.Scale, self._startPos.X.Offset + delta.X,
                self._startPos.Y.Scale, self._startPos.Y.Offset + delta.Y
            )
            local viewportSize = Utility.GetViewportSize()
            local frameSize = self.Frame.AbsoluteSize
            local clampedX = math.clamp(newPos.X.Offset, 0, viewportSize.X - frameSize.X)
            local clampedY = math.clamp(newPos.Y.Offset, 0, viewportSize.Y - frameSize.Y)
            if self.MagneticSnap then
                if clampedX < self.SnapThreshold then clampedX = 0 end
                if clampedY < self.SnapThreshold then clampedY = 0 end
                if clampedX > viewportSize.X - frameSize.X - self.SnapThreshold then
                    clampedX = viewportSize.X - frameSize.X
                end
                if clampedY > viewportSize.Y - frameSize.Y - self.SnapThreshold then
                    clampedY = viewportSize.Y - frameSize.Y
                end
            end
            local finalPos = UDim2.new(0, clampedX, 0, clampedY)
            self.Frame.Position = finalPos
            if self.OnPositionChanged then
                self.OnPositionChanged(finalPos)
            end
        end
    end

    table.insert(self._connections, self.Handle.InputBegan:Connect(inputBegan))
    table.insert(self._connections, UserInputService.InputChanged:Connect(inputChanged))
end

function DragHandler:SetMagneticSnap(enabled)
    self.MagneticSnap = enabled
end

function DragHandler:Destroy()
    for _, conn in ipairs(self._connections) do
        conn:Disconnect()
    end
    self._connections = {}
end

-- ============================================================
-- PARTICLE BACKGROUND ENGINE
-- ============================================================
local ParticleEngine = {}
ParticleEngine.__index = ParticleEngine

function ParticleEngine.new(parent, colorEngine)
    local self = setmetatable({}, ParticleEngine)
    self.Parent = parent
    self.ColorEngine = colorEngine
    self.Enabled = false
    self._running = false
    self._particles = {}
    self._canvas = nil
    self._lines = {}
    return self
end

function ParticleEngine:Start()
    if self._running then return end
    self.Enabled = true
    self._running = true
    self._canvas = Utility.Create("Frame", {
        Name = "ParticleCanvas",
        Parent = self.Parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        ZIndex = 0,
    })
    for i = 1, 30 do
        local size = math.random(2, 5)
        local particle = Utility.Create("Frame", {
            Name = "Particle_" .. i,
            Parent = self._canvas,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.6,
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(0, math.random(0, 300), 0, math.random(0, 400)),
            BorderSizePixel = 0,
            ZIndex = 1,
        })
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = particle,
        })
        table.insert(self._particles, {
            Instance = particle,
            VX = (math.random() - 0.5) * 0.5,
            VY = (math.random() - 0.5) * 0.5,
            Size = size,
        })
    end
    task.spawn(function()
        while self._running do
            self:_update()
            task.wait(1 / 30)
        end
    end)
end

function ParticleEngine:_update()
    if not self._canvas or not self._canvas.Parent then
        self._running = false
        return
    end
    local canvasSize = self._canvas.AbsoluteSize
    local accent = self.ColorEngine.CurrentColor
    for _, line in ipairs(self._lines) do
        if line and line.Parent then
            line:Destroy()
        end
    end
    self._lines = {}
    for _, p in ipairs(self._particles) do
        local inst = p.Instance
        if not inst or not inst.Parent then continue end
        local currentX = inst.Position.X.Offset + p.VX
        local currentY = inst.Position.Y.Offset + p.VY
        if currentX < 0 or currentX > canvasSize.X then p.VX = -p.VX end
        if currentY < 0 or currentY > canvasSize.Y then p.VY = -p.VY end
        currentX = math.clamp(currentX, 0, canvasSize.X)
        currentY = math.clamp(currentY, 0, canvasSize.Y)
        inst.Position = UDim2.new(0, currentX, 0, currentY)
        inst.BackgroundColor3 = accent
    end
    for i = 1, #self._particles do
        for j = i + 1, #self._particles do
            local p1 = self._particles[i]
            local p2 = self._particles[j]
            if not p1.Instance or not p1.Instance.Parent then continue end
            if not p2.Instance or not p2.Instance.Parent then continue end
            local x1 = p1.Instance.Position.X.Offset
            local y1 = p1.Instance.Position.Y.Offset
            local x2 = p2.Instance.Position.X.Offset
            local y2 = p2.Instance.Position.Y.Offset
            local dist = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
            if dist < 100 then
                local angle = math.atan2(y2 - y1, x2 - x1)
                local line = Utility.Create("Frame", {
                    Name = "Line",
                    Parent = self._canvas,
                    BackgroundColor3 = accent,
                    BackgroundTransparency = 0.7 + (dist / 100) * 0.3,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, dist, 0, 1),
                    Position = UDim2.new(0, x1, 0, y1),
                    Rotation = math.deg(angle),
                    AnchorPoint = Vector2.new(0, 0.5),
                    ZIndex = 0,
                })
                table.insert(self._lines, line)
            end
        end
    end
end

function ParticleEngine:Stop()
    self._running = false
    self.Enabled = false
    for _, line in ipairs(self._lines) do
        if line and line.Parent then line:Destroy() end
    end
    self._lines = {}
    for _, p in ipairs(self._particles) do
        if p.Instance and p.Instance.Parent then
            p.Instance:Destroy()
        end
    end
    self._particles = {}
    if self._canvas and self._canvas.Parent then
        self._canvas:Destroy()
    end
    self._canvas = nil
end

function ParticleEngine:Destroy()
    self:Stop()
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(screenGui, colorEngine, soundEngine)
    local self = setmetatable({}, NotificationSystem)
    self.ScreenGui = screenGui
    self.ColorEngine = colorEngine
    self.SoundEngine = soundEngine
    self.DefaultDuration = 4
    self.Enabled = true
    self._container = Utility.Create("Frame", {
        Name = "NotificationContainer",
        Parent = screenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        ZIndex = 100,
    })
    Utility.Create("UIListLayout", {
        Parent = self._container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 6),
    })
    Utility.Create("UIPadding", {
        Parent = self._container,
        PaddingBottom = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 5),
    })
    return self
end

function NotificationSystem:Push(options)
    if not self.Enabled then return end
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local notifType = options.Type or "Info"
    local duration = options.Time or self.DefaultDuration
    self.SoundEngine:Play("Notify")
    local typeColors = {
        Info = Color3.fromRGB(81, 137, 253),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(255, 82, 82),
    }
    local accentColor = typeColors[notifType] or self.ColorEngine.CurrentColor
    local notifFrame = Utility.Create("Frame", {
        Name = "Notification",
        Parent = self._container,
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        Size = UDim2.new(1, 0, 0, 70),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = notifFrame,
    })
    Utility.Create("UIStroke", {
        Parent = notifFrame,
        Color = accentColor,
        Thickness = 1,
        Transparency = 0.5,
    })
    local accentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
    })
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local contentLabel = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = notifFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -20, 0, 32),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(180, 180, 190),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local progressBar = Utility.Create("Frame", {
        Name = "ProgressBar",
        Parent = notifFrame,
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
    })
    Utility.Tween(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
    })
    Utility.Tween(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2),
    })
    task.delay(duration, function()
        Utility.Tween(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        }, function()
            notifFrame:Destroy()
        end)
    end)
end

function NotificationSystem:SetDuration(dur)
    self.DefaultDuration = math.clamp(dur, 1, 30)
end

function NotificationSystem:SetEnabled(enabled)
    self.Enabled = enabled
end

function NotificationSystem:Destroy()
    if self._container then
        self._container:Destroy()
    end
end

-- ============================================================
-- ARRAYLIST HUD
-- ============================================================
local ArrayListHUD = {}
ArrayListHUD.__index = ArrayListHUD

function ArrayListHUD.new(screenGui, colorEngine)
    local self = setmetatable({}, ArrayListHUD)
    self.ScreenGui = screenGui
    self.ColorEngine = colorEngine
    self.Enabled = false
    self._modules = {}
    self._container = Utility.Create("Frame", {
        Name = "ArrayList",
        Parent = screenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(1, -205, 0, 0),
        ZIndex = 90,
        Visible = false,
    })
    Utility.Create("UIListLayout", {
        Parent = self._container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 1),
    })
    Utility.Create("UIPadding", {
        Parent = self._container,
        PaddingTop = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })
    return self
end

function ArrayListHUD:SetEnabled(enabled)
    self.Enabled = enabled
    self._container.Visible = enabled
end

function ArrayListHUD:AddModule(name)
    if self._modules[name] then return end
    local label = Utility.Create("TextLabel", {
        Name = name,
        Parent = self._container,
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BackgroundTransparency = 0.3,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = " " .. name .. " ",
        TextColor3 = self.ColorEngine.CurrentColor,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        BorderSizePixel = 0,
    })
    self._modules[name] = label
    self:_updateColors()
end

function ArrayListHUD:RemoveModule(name)
    if self._modules[name] then
        self._modules[name]:Destroy()
        self._modules[name] = nil
    end
end

function ArrayListHUD:_updateColors()
    local accent = self.ColorEngine.CurrentColor
    for _, label in pairs(self._modules) do
        if label and label.Parent then
            label.TextColor3 = accent
        end
    end
end

function ArrayListHUD:Destroy()
    self._container:Destroy()
end

-- ============================================================
-- WATERMARK HUD
-- ============================================================
local WatermarkHUD = {}
WatermarkHUD.__index = WatermarkHUD

function WatermarkHUD.new(screenGui, colorEngine)
    local self = setmetatable({}, WatermarkHUD)
    self.ScreenGui = screenGui
    self.ColorEngine = colorEngine
    self.Enabled = false
    self._frame = Utility.Create("Frame", {
        Name = "Watermark",
        Parent = screenGui,
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BackgroundTransparency = 0.15,
        Size = UDim2.new(0, 280, 0, 24),
        Position = UDim2.new(0, 8, 0, 8),
        BorderSizePixel = 0,
        ZIndex = 90,
        Visible = false,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = self._frame,
    })
    Utility.Create("UIStroke", {
        Parent = self._frame,
        Color = colorEngine.CurrentColor,
        Thickness = 1,
        Transparency = 0.5,
    })
    self._label = Utility.Create("TextLabel", {
        Name = "WatermarkText",
        Parent = self._frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "VapeUI | Loading...",
        TextColor3 = Color3.fromRGB(220, 220, 230),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self._startTime = tick()
    task.spawn(function()
        while self._frame and self._frame.Parent do
            self:_update()
            task.wait(0.5)
        end
    end)
    return self
end

function WatermarkHUD:_update()
    if not self.Enabled then return end
    local elapsed = tick() - self._startTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = "N/A"
    pcall(function()
        local stats = game:GetService("Stats")
        ping = tostring(math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())) .. "ms"
    end)
    self._label.Text = string.format("VapeUI | %s | FPS: %d | Ping: %s | Time: %02d:%02d",
        LocalPlayer.Name, fps, ping, minutes, seconds)
    local stroke = self._frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = self.ColorEngine.CurrentColor
    end
end

function WatermarkHUD:SetEnabled(enabled)
    self.Enabled = enabled
    self._frame.Visible = enabled
end

function WatermarkHUD:GetElapsedTime()
    local elapsed = tick() - self._startTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

function WatermarkHUD:Destroy()
    self._frame:Destroy()
end

-- ============================================================
-- MAIN LIBRARY CLASS
-- ============================================================
local Library = {}
Library.__index = Library

function Library.new()
    local self = setmetatable({}, Library)
    self.Name = "VapeUI"
    self.Categories = {}
    self.Flags = {}
    self.FlagCallbacks = {}
    self.Windows = {}
    self._initialized = false
    self._visible = true
    self._toggleKey = Enum.KeyCode.RightShift
    self._animSpeed = 0.25
    self._globalTransparency = 0
    self._globalScale = 1
    self._connections = {}
    self._threads = {}
    self._screenGui = nil
    self._colorEngine = nil
    self._soundEngine = nil
    self._configManager = nil
    self._notificationSystem = nil
    self._particleEngine = nil
    self._arrayList = nil
    self._watermark = nil
    self._mobileButton = nil
    self._mobileButtonEnabled = true
    self._magneticSnap = true
    self._keybindActiveWhenHidden = true
    self._destroyed = false
    self._startTime = tick()
    return self
end

function Library:Init(settings)
    if self._initialized then return self end
    settings = settings or {}
    self.Name = settings.Name or "VapeUI"
    self._toggleKey = settings.ToggleKey or Enum.KeyCode.RightShift
    self._animSpeed = settings.AnimationSpeed or 0.25
    self._screenGui = Utility.Create("ScreenGui", {
        Name = self.Name .. "_ScreenGui",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    self._uiScale = Utility.Create("UIScale", {
        Scale = self._globalScale,
        Parent = self._screenGui,
    })
    self._colorEngine = ColorEngine.new()
    self._soundEngine = SoundEngine.new()
    self._configManager = ConfigManager.new(self.Name)
    self._notificationSystem = NotificationSystem.new(self._screenGui, self._colorEngine, self._soundEngine)
    self._arrayList = ArrayListHUD.new(self._screenGui, self._colorEngine)
    self._watermark = WatermarkHUD.new(self._screenGui, self._colorEngine)
    self:_setupToggleKey()
    self:_setupMobileButton()
    self:_createSettingsCategory()
    self._initialized = true
    return self
end

function Library:_setupToggleKey()
    local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self._destroyed then return end
        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
    end)
    table.insert(self._connections, conn)
end

function Library:_setupMobileButton()
    if not Utility.IsMobile() then return end
    self._mobileButton = Utility.Create("ImageButton", {
        Name = "MobileToggle",
        Parent = self._screenGui,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.2,
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(0, 10, 0.5, -22),
        Image = "rbxassetid://7072718726",
        ImageColor3 = self._colorEngine.CurrentColor,
        ImageTransparency = 0.1,
        ZIndex = 200,
        BorderSizePixel = 0,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self._mobileButton,
    })
    Utility.Create("UIStroke", {
        Parent = self._mobileButton,
        Color = self._colorEngine.CurrentColor,
        Thickness = 2,
        Transparency = 0.3,
    })
    DragHandler.new(self._mobileButton, self._mobileButton, false)
    self._mobileButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    self._colorEngine:OnColorChanged(function(primary)
        if self._mobileButton and self._mobileButton.Parent then
            self._mobileButton.ImageColor3 = primary
            local stroke = self._mobileButton:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = primary end
        end
    end)
end

function Library:Toggle()
    self._visible = not self._visible
    self._soundEngine:Play(self._visible and "Open" or "Close")
    for _, window in ipairs(self.Windows) do
        if window._frame then
            if self._visible then
                window._frame.Visible = window._wasVisible ~= false
                Utility.Tween(window._frame, TweenInfo.new(self._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.02 + self._globalTransparency,
                })
            else
                window._wasVisible = window._frame.Visible
                Utility.Tween(window._frame, TweenInfo.new(self._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    BackgroundTransparency = 1,
                }, function()
                    if not self._visible then
                        window._frame.Visible = false
                    end
                end)
            end
        end
    end
    if self._notificationSystem then
        self._notificationSystem._container.Visible = self._visible
    end
end

function Library:SetFlag(flag, value)
    self.Flags[flag] = value
    if self._configManager then
        self._configManager:SetFlag(flag, value)
    end
    if self.FlagCallbacks[flag] then
        for _, cb in ipairs(self.FlagCallbacks[flag]) do
            pcall(cb, value)
        end
    end
end

function Library:GetFlag(flag, default)
    if self.Flags[flag] ~= nil then
        return self.Flags[flag]
    end
    return default
end

function Library:OnFlagChanged(flag, callback)
    if not self.FlagCallbacks[flag] then
        self.FlagCallbacks[flag] = {}
    end
    table.insert(self.FlagCallbacks[flag], callback)
end

-- ============================================================
-- WINDOW / CATEGORY CLASS
-- ============================================================
local Category = {}
Category.__index = Category

function Library:CreateCategory(options)
    options = options or {}
    local category = setmetatable({}, Category)
    category.Name = options.Name or "Category"
    category.Icon = options.Icon or ""
    category.Library = self
    category.Modules = {}
    category._collapsed = true
    category._hidden = true
    category._wasVisible = false
    local viewportSize = Utility.GetViewportSize()
    local windowWidth = 220
    local windowHeight = 32
    local windowIndex = #self.Windows
    local startX = math.clamp(80 + windowIndex * (windowWidth + 15), 0, viewportSize.X - windowWidth)
    local startY = math.clamp(100, 0, viewportSize.Y - 100)
    category._frame = Utility.Create("Frame", {
        Name = "Window_" .. category.Name,
        Parent = self._screenGui,
        BackgroundColor3 = Color3.fromRGB(22, 22, 32),
        BackgroundTransparency = 0.02,
        Size = UDim2.new(0, windowWidth, 0, windowHeight),
        Position = UDim2.new(0, startX, 0, startY),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = false,
        ZIndex = 10,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = category._frame,
    })
    category._stroke = Utility.Create("UIStroke", {
        Parent = category._frame,
        Color = self._colorEngine.CurrentColor,
        Thickness = 1.5,
        Transparency = 0.3,
    })
    local header = Utility.Create("Frame", {
        Name = "Header",
        Parent = category._frame,
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        Size = UDim2.new(1, 0, 0, 32),
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = header,
    })
    local bottomCover = Utility.Create("Frame", {
        Name = "BottomCover",
        Parent = header,
        BackgroundColor3 = Color3.fromRGB(28, 28, 42),
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    if category.Icon ~= "" then
        Utility.Create("ImageLabel", {
            Name = "Icon",
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = category.Icon,
            ImageColor3 = self._colorEngine.CurrentColor,
            ZIndex = 13,
        })
    end
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, category.Icon ~= "" and 28 or 10, 0, 0),
        Size = UDim2.new(1, category.Icon ~= "" and -58 or -40, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = category.Name,
        TextColor3 = Color3.fromRGB(230, 230, 240),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    })
    local collapseBtn = Utility.Create("TextButton", {
        Name = "CollapseButton",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "+",
        TextColor3 = Color3.fromRGB(180, 180, 190),
        TextSize = 16,
        ZIndex = 13,
    })
    category._contentContainer = Utility.Create("ScrollingFrame", {
        Name = "Content",
        Parent = category._frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self._colorEngine.CurrentColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 11,
        ScrollingEnabled = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    local contentLayout = Utility.Create("UIListLayout", {
        Parent = category._contentContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    Utility.Create("UIPadding", {
        Parent = category._contentContainer,
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    })
    DragHandler.new(category._frame, header, self._magneticSnap)
    collapseBtn.MouseButton1Click:Connect(function()
        self._soundEngine:Play("Click")
        category:ToggleCollapse()
    end)
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not category._collapsed then
            category:_updateSize()
        end
    end)
    self._colorEngine:OnColorChanged(function(primary)
        if category._stroke and category._stroke.Parent then
            category._stroke.Color = primary
        end
        if category._contentContainer and category._contentContainer.Parent then
            category._contentContainer.ScrollBarImageColor3 = primary
        end
        local icon = header:FindFirstChild("Icon")
        if icon then
            icon.ImageColor3 = primary
        end
    end)
    table.insert(self.Windows, category)
    table.insert(self.Categories, category)
    return category
end

function Category:ToggleCollapse()
    self._collapsed = not self._collapsed
    local collapseBtn = self._frame:FindFirstChild("Header"):FindFirstChild("CollapseButton")
    if self._collapsed then
        collapseBtn.Text = "+"
        Utility.Tween(self._contentContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0),
        })
        Utility.Tween(self._frame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, self._frame.Size.X.Offset, 0, 32),
        })
    else
        collapseBtn.Text = "-"
        self:_updateSize()
    end
end

function Category:_updateSize()
    local contentHeight = self._contentContainer:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y + 8
    local maxHeight = math.min(contentHeight, 400)
    Utility.Tween(self._contentContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, maxHeight),
    })
    Utility.Tween(self._frame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, self._frame.Size.X.Offset, 0, 32 + maxHeight),
    })
end

function Category:Show()
    self._hidden = false
    self._frame.Visible = true
    self._wasVisible = true
    local viewportSize = Utility.GetViewportSize()
    local frameSize = self._frame.AbsoluteSize
    local pos = self._frame.Position
    self._frame.Position = Utility.ClampPosition(
        Vector2.new(pos.X.Offset, pos.Y.Offset),
        frameSize,
        viewportSize
    )
end

function Category:Hide()
    self._hidden = true
    self._frame.Visible = false
    self._wasVisible = false
end

-- ============================================================
-- MODULE CLASS
-- ============================================================
local Module = {}
Module.__index = Module

function Category:CreateModule(options)
    options = options or {}
    local module = setmetatable({}, Module)
    module.Name = options.Name or "Module"
    module.Info = options.Info or ""
    module.Enabled = options.Default or false
    module.Bind = options.Bind or nil
    module.Category = self
    module.Library = self.Library
    module.SubComponents = {}
    module._expanded = false
    module._order = #self.Modules
    local moduleFrame = Utility.Create("Frame", {
        Name = "Module_" .. module.Name,
        Parent = self._contentContainer,
        BackgroundColor3 = Color3.fromRGB(32, 32, 48),
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 28),
        BorderSizePixel = 0,
        LayoutOrder = module._order,
        ClipsDescendants = true,
        ZIndex = 12,
    })
    module._frame = moduleFrame
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = moduleFrame,
    })
    local toggleIndicator = Utility.Create("Frame", {
        Name = "ToggleIndicator",
        Parent = moduleFrame,
        BackgroundColor3 = module.Enabled and self.Library._colorEngine.CurrentColor or Color3.fromRGB(60, 60, 75),
        Size = UDim2.new(0, 4, 0, 18),
        Position = UDim2.new(0, 4, 0, 5),
        BorderSizePixel = 0,
        ZIndex = 14,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 2),
        Parent = toggleIndicator,
    })
    local nameLabel = Utility.Create("TextButton", {
        Name = "NameButton",
        Parent = moduleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -50, 0, 28),
        Font = Enum.Font.GothamSemibold,
        Text = module.Name,
        TextColor3 = module.Enabled and Color3.fromRGB(230, 230, 240) or Color3.fromRGB(150, 150, 165),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local expandBtn = Utility.Create("TextButton", {
        Name = "ExpandButton",
        Parent = moduleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0, 4),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "▶",
        TextColor3 = Color3.fromRGB(120, 120, 135),
        TextSize = 10,
        ZIndex = 14,
    })
    module._subContainer = Utility.Create("Frame", {
        Name = "SubComponents",
        Parent = moduleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = 12,
    })
    local subLayout = Utility.Create("UIListLayout", {
        Parent = module._subContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    Utility.Create("UIPadding", {
        Parent = module._subContainer,
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 4),
    })
    nameLabel.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Toggle")
        module.Enabled = not module.Enabled
        module:_updateVisual()
        if module.Enabled then
            self.Library._arrayList:AddModule(module.Name)
        else
            self.Library._arrayList:RemoveModule(module.Name)
        end
    end)
    nameLabel.MouseEnter:Connect(function()
        Utility.Tween(moduleFrame, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(38, 38, 56),
        })
    end)
    nameLabel.MouseLeave:Connect(function()
        Utility.Tween(moduleFrame, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(32, 32, 48),
        })
    end)
    expandBtn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        module:ToggleExpand()
    end)
    subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if module._expanded then
            module:_updateExpandSize()
        end
    end)
    self.Library._colorEngine:OnColorChanged(function(primary)
        if module.Enabled and toggleIndicator and toggleIndicator.Parent then
            toggleIndicator.BackgroundColor3 = primary
        end
    end)
    if module.Bind then
        local bindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == module.Bind then
                module.Enabled = not module.Enabled
                module:_updateVisual()
            end
        end)
        table.insert(self.Library._connections, bindConn)
    end
    table.insert(self.Modules, module)
    return module
end

function Module:_updateVisual()
    local indicator = self._frame:FindFirstChild("ToggleIndicator")
    local nameBtn = self._frame:FindFirstChild("NameButton")
    if self.Enabled then
        Utility.Tween(indicator, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Library._colorEngine.CurrentColor,
        })
        Utility.Tween(nameBtn, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(230, 230, 240),
        })
    else
        Utility.Tween(indicator, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 75),
        })
        Utility.Tween(nameBtn, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(150, 150, 165),
        })
    end
end

function Module:ToggleExpand()
    self._expanded = not self._expanded
    local expandBtn = self._frame:FindFirstChild("ExpandButton")
    if self._expanded then
        expandBtn.Text = "▼"
        self:_updateExpandSize()
    else
        expandBtn.Text = "▶"
        Utility.Tween(self._subContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
            Size = UDim2.new(1, 0, 0, 0),
        })
        Utility.Tween(self._frame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
            Size = UDim2.new(1, 0, 0, 28),
        })
    end
    task.delay(self.Library._animSpeed + 0.05, function()
        self.Category:_updateSize()
    end)
end

function Module:_updateExpandSize()
    local subHeight = self._subContainer:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y + 10
    Utility.Tween(self._subContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, 0, 0, subHeight),
    })
    Utility.Tween(self._frame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, 0, 0, 28 + subHeight),
    })
end

-- ============================================================
-- SUB-COMPONENT: TOGGLE
-- ============================================================
function Module:CreateToggle(options)
    options = options or {}
    local name = options.Name or "Toggle"
    local default = options.Default or false
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local value = default
    self.Library:SetFlag(flag, value)
    local toggleFrame = Utility.Create("Frame", {
        Name = "Toggle_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 26),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = toggleFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local toggleBg = Utility.Create("Frame", {
        Name = "ToggleBg",
        Parent = toggleFrame,
        BackgroundColor3 = value and self.Library._colorEngine.CurrentColor or Color3.fromRGB(50, 50, 65),
        Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(1, -40, 0.5, -8),
        BorderSizePixel = 0,
        ZIndex = 14,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleBg,
    })
    local toggleCircle = Utility.Create("Frame", {
        Name = "Circle",
        Parent = toggleBg,
        BackgroundColor3 = Color3.fromRGB(240, 240, 250),
        Size = UDim2.new(0, 12, 0, 12),
        Position = value and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleCircle,
    })
    local btn = Utility.Create("TextButton", {
        Name = "HitArea",
        Parent = toggleFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 16,
    })
    local function updateToggle()
        if value then
            Utility.Tween(toggleBg, TweenInfo.new(0.2), {
                BackgroundColor3 = self.Library._colorEngine.CurrentColor,
            })
            Utility.Tween(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Position = UDim2.new(1, -14, 0.5, -6),
            })
        else
            Utility.Tween(toggleBg, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 65),
            })
            Utility.Tween(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Position = UDim2.new(0, 2, 0.5, -6),
            })
        end
    end

    btn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        value = not value
        self.Library:SetFlag(flag, value)
        updateToggle()
        pcall(callback, value)
    end)
    btn.MouseEnter:Connect(function()
        Utility.Tween(toggleFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    btn.MouseLeave:Connect(function()
        Utility.Tween(toggleFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    self.Library._colorEngine:OnColorChanged(function(primary)
        if value and toggleBg and toggleBg.Parent then
            toggleBg.BackgroundColor3 = primary
        end
    end)

    local component = {
        Type = "Toggle",
        Flag = flag,
        Frame = toggleFrame,
        SetValue = function(_, newVal)
            value = newVal
            self.Library:SetFlag(flag, value)
            updateToggle()
            pcall(callback, value)
        end,
        GetValue = function()
            return value
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: SLIDER
-- ============================================================
function Module:CreateSlider(options)
    options = options or {}
    local name = options.Name or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local precise = options.Precise or false
    local unit = options.Unit or ""
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local value = math.clamp(default, min, max)
    self.Library:SetFlag(flag, value)
    local sliderFrame = Utility.Create("Frame", {
        Name = "Slider_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 38),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = sliderFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(0.6, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local valueLabel = Utility.Create("TextLabel", {
        Name = "Value",
        Parent = sliderFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.6, 0, 0, 2),
        Size = UDim2.new(0.4, -8, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = (precise and string.format("%.2f", value) or tostring(math.floor(value))) .. unit,
        TextColor3 = self.Library._colorEngine.CurrentColor,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 14,
    })
    local sliderBg = Utility.Create("Frame", {
        Name = "SliderBg",
        Parent = sliderFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        Size = UDim2.new(1, -16, 0, 8),
        Position = UDim2.new(0, 8, 0, 24),
        BorderSizePixel = 0,
        ZIndex = 14,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderBg,
    })
    local fillPercent = (value - min) / (max - min)
    local sliderFill = Utility.Create("Frame", {
        Name = "Fill",
        Parent = sliderBg,
        BackgroundColor3 = self.Library._colorEngine.CurrentColor,
        Size = UDim2.new(math.clamp(fillPercent, 0, 1), 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderFill,
    })
    local sliderKnob = Utility.Create("Frame", {
        Name = "Knob",
        Parent = sliderBg,
        BackgroundColor3 = Color3.fromRGB(240, 240, 250),
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(math.clamp(fillPercent, 0, 1), -7, 0.5, -7),
        BorderSizePixel = 0,
        ZIndex = 16,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderKnob,
    })
    local sliding = false
    local function updateSlider(inputPos)
        local bgPos = sliderBg.AbsolutePosition.X
        local bgSize = sliderBg.AbsoluteSize.X
        local relativeX = math.clamp((inputPos - bgPos) / bgSize, 0, 1)
        value = min + (max - min) * relativeX
        if not precise then
            value = math.floor(value + 0.5)
        else
            value = math.floor(value * 100 + 0.5) / 100
        end
        value = math.clamp(value, min, max)
        local percent = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -7, 0.5, -7)
        valueLabel.Text = (precise and string.format("%.2f", value) or tostring(math.floor(value))) .. unit
        self.Library:SetFlag(flag, value)
        pcall(callback, value)
    end

    local sliderBtn = Utility.Create("TextButton", {
        Name = "HitArea",
        Parent = sliderBg,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 10),
        Position = UDim2.new(0, 0, 0, -5),
        Text = "",
        ZIndex = 17,
    })
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            self.Library._soundEngine:Play("Slide")
            updateSlider(input.Position.X)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    local slideConn = UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    table.insert(self.Library._connections, slideConn)

    sliderFrame.MouseEnter:Connect(function()
        Utility.Tween(sliderFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    sliderFrame.MouseLeave:Connect(function()
        Utility.Tween(sliderFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    self.Library._colorEngine:OnColorChanged(function(primary)
        if sliderFill and sliderFill.Parent then
            sliderFill.BackgroundColor3 = primary
        end
        if valueLabel and valueLabel.Parent then
            valueLabel.TextColor3 = primary
        end
    end)

    local component = {
        Type = "Slider",
        Flag = flag,
        Frame = sliderFrame,
        SetValue = function(_, newVal)
            value = math.clamp(newVal, min, max)
            local percent = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderKnob.Position = UDim2.new(percent, -7, 0.5, -7)
            valueLabel.Text = (precise and string.format("%.2f", value) or tostring(math.floor(value))) .. unit
            self.Library:SetFlag(flag, value)
            pcall(callback, value)
        end,
        GetValue = function()
            return value
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: DROPDOWN
-- ============================================================
function Module:CreateDropdown(options)
    options = options or {}
    local name = options.Name or "Dropdown"
    local optionsList = options.Options or {}
    local default = options.Default or (optionsList[1] or "None")
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local selected = default
    local isOpen = false
    self.Library:SetFlag(flag, selected)
    local dropdownFrame = Utility.Create("Frame", {
        Name = "Dropdown_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ClipsDescendants = true,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = dropdownFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = dropdownFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(1, -16, 0, 16),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local selectedBtn = Utility.Create("TextButton", {
        Name = "SelectedButton",
        Parent = dropdownFrame,
        BackgroundColor3 = Color3.fromRGB(36, 36, 50),
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = "  " .. tostring(selected) .. "  ▼",
        TextColor3 = Color3.fromRGB(210, 210, 220),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = selectedBtn,
    })
    local optionsContainer = Utility.Create("Frame", {
        Name = "Options",
        Parent = dropdownFrame,
        BackgroundColor3 = Color3.fromRGB(30, 30, 44),
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 16,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = optionsContainer,
    })
    local optionsLayout = Utility.Create("UIListLayout", {
        Parent = optionsContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    })
    local function createOption(optionText, index)
        local optBtn = Utility.Create("TextButton", {
            Name = "Option_" .. optionText,
            Parent = optionsContainer,
            BackgroundColor3 = Color3.fromRGB(36, 36, 50),
            BackgroundTransparency = 0.2,
            Size = UDim2.new(1, 0, 0, 22),
            Font = Enum.Font.Gotham,
            Text = "  " .. optionText,
            TextColor3 = optionText == selected and self.Library._colorEngine.CurrentColor or Color3.fromRGB(180, 180, 190),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            LayoutOrder = index,
            ZIndex = 17,
        })
        optBtn.MouseEnter:Connect(function()
            Utility.Tween(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(44, 44, 60)})
        end)
        optBtn.MouseLeave:Connect(function()
            Utility.Tween(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(36, 36, 50)})
        end)
        optBtn.MouseButton1Click:Connect(function()
            self.Library._soundEngine:Play("Click")
            selected = optionText
            selectedBtn.Text = "  " .. tostring(selected) .. "  ▼"
            self.Library:SetFlag(flag, selected)
            pcall(callback, selected)
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = Color3.fromRGB(180, 180, 190)
                end
            end
            optBtn.TextColor3 = self.Library._colorEngine.CurrentColor
            isOpen = false
            selectedBtn.Text = "  " .. tostring(selected) .. "  ▼"
            local targetSize = 42
            Utility.Tween(optionsContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, -16, 0, 0),
            })
            Utility.Tween(dropdownFrame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, targetSize),
            })
            task.delay(self.Library._animSpeed + 0.05, function()
                if self._expanded then self:_updateExpandSize() end
                self.Category:_updateSize()
            end)
        end)
        return optBtn
    end

    for i, opt in ipairs(optionsList) do
        createOption(opt, i)
    end

    selectedBtn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        isOpen = not isOpen
        if isOpen then
            selectedBtn.Text = "  " .. tostring(selected) .. "  ▲"
            local optHeight = #optionsList * 23
            Utility.Tween(optionsContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, -16, 0, optHeight),
            })
            Utility.Tween(dropdownFrame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, 42 + optHeight + 4),
            })
        else
            selectedBtn.Text = "  " .. tostring(selected) .. "  ▼"
            Utility.Tween(optionsContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, -16, 0, 0),
            })
            Utility.Tween(dropdownFrame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, 42),
            })
        end
        task.delay(self.Library._animSpeed + 0.05, function()
            if self._expanded then self:_updateExpandSize() end
            self.Category:_updateSize()
        end)
    end)

    dropdownFrame.MouseEnter:Connect(function()
        Utility.Tween(dropdownFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    dropdownFrame.MouseLeave:Connect(function()
        Utility.Tween(dropdownFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    local component = {
        Type = "Dropdown",
        Flag = flag,
        Frame = dropdownFrame,
        SetValue = function(_, newVal)
            selected = newVal
            selectedBtn.Text = "  " .. tostring(selected) .. "  ▼"
            self.Library:SetFlag(flag, selected)
            pcall(callback, selected)
        end,
        GetValue = function()
            return selected
        end,
        Refresh = function(_, newOptions)
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            optionsList = newOptions
            for i, opt in ipairs(optionsList) do
                createOption(opt, i)
            end
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: COLOR PICKER
-- ============================================================
function Module:CreateColorPicker(options)
    options = options or {}
    local name = options.Name or "Color"
    local default = options.Default or Color3.fromRGB(255, 255, 255)
    local alphaEnabled = options.Alpha or false
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local currentColor = default
    local currentAlpha = 1
    local isOpen = false
    local currentH, currentS, currentV = default:ToHSV()
    self.Library:SetFlag(flag, default)
    local cpFrame = Utility.Create("Frame", {
        Name = "ColorPicker_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 26),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ClipsDescendants = true,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = cpFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = cpFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 3),
        Size = UDim2.new(1, -50, 0, 20),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local colorPreview = Utility.Create("Frame", {
        Name = "Preview",
        Parent = cpFrame,
        BackgroundColor3 = currentColor,
        Size = UDim2.new(0, 20, 0, 14),
        Position = UDim2.new(1, -34, 0, 6),
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorPreview,
    })
    Utility.Create("UIStroke", {
        Parent = colorPreview,
        Color = Color3.fromRGB(60, 60, 75),
        Thickness = 1,
    })
    local previewBtn = Utility.Create("TextButton", {
        Name = "PreviewBtn",
        Parent = cpFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Text = "",
        ZIndex = 16,
    })
    local pickerContainer = Utility.Create("Frame", {
        Name = "PickerContainer",
        Parent = cpFrame,
        BackgroundColor3 = Color3.fromRGB(20, 20, 32),
        Position = UDim2.new(0, 4, 0, 28),
        Size = UDim2.new(1, -8, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 16,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = pickerContainer,
    })
    local svBox = Utility.Create("ImageLabel", {
        Name = "SVBox",
        Parent = pickerContainer,
        BackgroundColor3 = Color3.fromHSV(currentH, 1, 1),
        Size = UDim2.new(1, -30, 0, 100),
        Position = UDim2.new(0, 4, 0, 4),
        BorderSizePixel = 0,
        Image = "rbxassetid://4155801252",
        ZIndex = 17,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = svBox,
    })
    local svCursor = Utility.Create("Frame", {
        Name = "Cursor",
        Parent = svBox,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(currentS, -5, 1 - currentV, -5),
        BorderSizePixel = 0,
        ZIndex = 18,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = svCursor,
    })
    Utility.Create("UIStroke", {
        Parent = svCursor,
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1.5,
    })
    local hueBar = Utility.Create("Frame", {
        Name = "HueBar",
        Parent = pickerContainer,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0, 16, 0, 100),
        Position = UDim2.new(1, -22, 0, 4),
        BorderSizePixel = 0,
        ZIndex = 17,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = hueBar,
    })
    local hueGradient = Utility.Create("UIGradient", {
        Parent = hueBar,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
    })
    local hueCursor = Utility.Create("Frame", {
        Name = "HueCursor",
        Parent = hueBar,
        BackgroundColor3 = Color3.fromRGB(240, 240, 250),
        Size = UDim2.new(1, 4, 0, 4),
        Position = UDim2.new(0, -2, currentH, -2),
        BorderSizePixel = 0,
        ZIndex = 18,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 2),
        Parent = hueCursor,
    })
    local alphaBar = nil
    local alphaCursor = nil
    local pickerHeight = 112
    if alphaEnabled then
        pickerHeight = 130
        alphaBar = Utility.Create("Frame", {
            Name = "AlphaBar",
            Parent = pickerContainer,
            BackgroundColor3 = currentColor,
            Size = UDim2.new(1, -8, 0, 12),
            Position = UDim2.new(0, 4, 0, 108),
            BorderSizePixel = 0,
            ZIndex = 17,
        })
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 3),
            Parent = alphaBar,
        })
        Utility.Create("UIGradient", {
            Parent = alphaBar,
            Color = ColorSequence.new(currentColor, Color3.fromRGB(0, 0, 0)),
            Transparency = NumberSequence.new(0, 1),
        })
        alphaCursor = Utility.Create("Frame", {
            Name = "AlphaCursor",
            Parent = alphaBar,
            BackgroundColor3 = Color3.fromRGB(240, 240, 250),
            Size = UDim2.new(0, 4, 1, 4),
            Position = UDim2.new(1 - currentAlpha, -2, 0, -2),
            BorderSizePixel = 0,
            ZIndex = 18,
        })
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 2),
            Parent = alphaCursor,
        })
    end

    local function updateColor()
        currentColor = Color3.fromHSV(currentH, currentS, currentV)
        colorPreview.BackgroundColor3 = currentColor
        svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
        svCursor.Position = UDim2.new(currentS, -5, 1 - currentV, -5)
        hueCursor.Position = UDim2.new(0, -2, currentH, -2)
        self.Library:SetFlag(flag, currentColor)
        pcall(callback, currentColor, currentAlpha)
    end

    local svDragging = false
    local svBtn = Utility.Create("TextButton", {
        Name = "SVHitArea",
        Parent = svBox,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 19,
    })
    svBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
        end
    end)
    svBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)
    local svConn = UserInputService.InputChanged:Connect(function(input)
        if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relX = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
            local relY = math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
            currentS = relX
            currentV = 1 - relY
            updateColor()
        end
    end)
    table.insert(self.Library._connections, svConn)

    local hueDragging = false
    local hueBtn = Utility.Create("TextButton", {
        Name = "HueHitArea",
        Parent = hueBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 6, 1, 0),
        Position = UDim2.new(0, -3, 0, 0),
        Text = "",
        ZIndex = 19,
    })
    hueBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
        end
    end)
    hueBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)
    local hueConn = UserInputService.InputChanged:Connect(function(input)
        if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relY = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
            currentH = relY
            updateColor()
        end
    end)
    table.insert(self.Library._connections, hueConn)

    if alphaEnabled and alphaBar then
        local alphaDragging = false
        local alphaBtn = Utility.Create("TextButton", {
            Name = "AlphaHitArea",
            Parent = alphaBar,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 6),
            Position = UDim2.new(0, 0, 0, -3),
            Text = "",
            ZIndex = 19,
        })
        alphaBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                alphaDragging = true
            end
        end)
        alphaBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                alphaDragging = false
            end
        end)
        local alphaConn = UserInputService.InputChanged:Connect(function(input)
            if alphaDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relX = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                currentAlpha = 1 - relX
                if alphaCursor then
                    alphaCursor.Position = UDim2.new(relX, -2, 0, -2)
                end
                pcall(callback, currentColor, currentAlpha)
            end
        end)
        table.insert(self.Library._connections, alphaConn)
    end

    previewBtn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        isOpen = not isOpen
        if isOpen then
            Utility.Tween(pickerContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, -8, 0, pickerHeight),
            })
            Utility.Tween(cpFrame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, 26 + pickerHeight + 6),
            })
        else
            Utility.Tween(pickerContainer, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, -8, 0, 0),
            })
            Utility.Tween(cpFrame, TweenInfo.new(self.Library._animSpeed, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, 26),
            })
        end
        task.delay(self.Library._animSpeed + 0.05, function()
            if self._expanded then self:_updateExpandSize() end
            self.Category:_updateSize()
        end)
    end)

    cpFrame.MouseEnter:Connect(function()
        Utility.Tween(cpFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    cpFrame.MouseLeave:Connect(function()
        Utility.Tween(cpFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    local component = {
        Type = "ColorPicker",
        Flag = flag,
        Frame = cpFrame,
        SetValue = function(_, newColor, newAlpha)
            currentColor = newColor
            currentH, currentS, currentV = newColor:ToHSV()
            if newAlpha then currentAlpha = newAlpha end
            updateColor()
        end,
        GetValue = function()
            return currentColor, currentAlpha
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: KEYBIND
-- ============================================================
function Module:CreateKeybind(options)
    options = options or {}
    local name = options.Name or "Keybind"
    local default = options.Default or Enum.KeyCode.Unknown
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local currentBind = default
    local listening = false
    self.Library:SetFlag(flag, tostring(currentBind))
    local kbFrame = Utility.Create("Frame", {
        Name = "Keybind_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 26),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = kbFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = kbFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local bindDisplayName = currentBind == Enum.KeyCode.Unknown and "None" or currentBind.Name
    local bindBtn = Utility.Create("TextButton", {
        Name = "BindButton",
        Parent = kbFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 56),
        Size = UDim2.new(0.35, -8, 0, 18),
        Position = UDim2.new(0.65, 0, 0.5, -9),
        Font = Enum.Font.GothamSemibold,
        Text = "[" .. bindDisplayName .. "]",
        TextColor3 = self.Library._colorEngine.CurrentColor,
        TextSize = 11,
        TextScaled = false,
        BorderSizePixel = 0,
        ZIndex = 15,
        AutoButtonColor = false,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = bindBtn,
    })

    bindBtn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        listening = true
        bindBtn.Text = "[...]"
        bindBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
    end)

    local kbConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    currentBind = Enum.KeyCode.Unknown
                    bindBtn.Text = "[None]"
                else
                    currentBind = input.KeyCode
                    bindBtn.Text = "[" .. currentBind.Name .. "]"
                end
                bindBtn.TextColor3 = self.Library._colorEngine.CurrentColor
                listening = false
                self.Library:SetFlag(flag, tostring(currentBind))
                pcall(callback, currentBind)
            end
        else
            if not gameProcessed and input.KeyCode == currentBind and currentBind ~= Enum.KeyCode.Unknown then
                pcall(callback, currentBind)
            end
        end
    end)
    table.insert(self.Library._connections, kbConn)

    kbFrame.MouseEnter:Connect(function()
        Utility.Tween(kbFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    kbFrame.MouseLeave:Connect(function()
        Utility.Tween(kbFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    self.Library._colorEngine:OnColorChanged(function(primary)
        if not listening and bindBtn and bindBtn.Parent then
            bindBtn.TextColor3 = primary
        end
    end)

    local component = {
        Type = "Keybind",
        Flag = flag,
        Frame = kbFrame,
        SetValue = function(_, newBind)
            currentBind = newBind
            local displayName = currentBind == Enum.KeyCode.Unknown and "None" or currentBind.Name
            bindBtn.Text = "[" .. displayName .. "]"
            self.Library:SetFlag(flag, tostring(currentBind))
        end,
        GetValue = function()
            return currentBind
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: TEXTBOX
-- ============================================================
function Module:CreateTextBox(options)
    options = options or {}
    local name = options.Name or "TextBox"
    local placeholder = options.Placeholder or "Enter text..."
    local clearOnFocus = options.ClearOnFocus
    if clearOnFocus == nil then clearOnFocus = true end
    local flag = options.Flag or (self.Name .. "_" .. name)
    local callback = options.Callback or function() end
    local value = ""
    self.Library:SetFlag(flag, value)
    local tbFrame = Utility.Create("Frame", {
        Name = "TextBox_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = tbFrame,
    })
    local label = Utility.Create("TextLabel", {
        Name = "Label",
        Parent = tbFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(1, -16, 0, 16),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local textBox = Utility.Create("TextBox", {
        Name = "Input",
        Parent = tbFrame,
        BackgroundColor3 = Color3.fromRGB(36, 36, 50),
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = Color3.fromRGB(100, 100, 115),
        TextColor3 = Color3.fromRGB(220, 220, 230),
        TextSize = 11,
        ClearTextOnFocus = clearOnFocus,
        BorderSizePixel = 0,
        ZIndex = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = textBox,
    })
    Utility.Create("UIPadding", {
        Parent = textBox,
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    })

    textBox.FocusLost:Connect(function(enterPressed)
        value = textBox.Text
        self.Library:SetFlag(flag, value)
        if enterPressed then
            self.Library._soundEngine:Play("Click")
        end
        pcall(callback, value, enterPressed)
    end)
    textBox.Focused:Connect(function()
        Utility.Tween(textBox, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(42, 42, 58),
        })
    end)
    textBox.FocusLost:Connect(function()
        Utility.Tween(textBox, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(36, 36, 50),
        })
    end)

    tbFrame.MouseEnter:Connect(function()
        Utility.Tween(tbFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(32, 32, 46)})
    end)
    tbFrame.MouseLeave:Connect(function()
        Utility.Tween(tbFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)})
    end)

    local component = {
        Type = "TextBox",
        Flag = flag,
        Frame = tbFrame,
        SetValue = function(_, newVal)
            value = newVal
            textBox.Text = newVal
            self.Library:SetFlag(flag, value)
        end,
        GetValue = function()
            return value
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: BUTTON
-- ============================================================
function Module:CreateButton(options)
    options = options or {}
    local name = options.Name or "Button"
    local interact = options.Interact or "Execute"
    local callback = options.Callback or function() end

    local btnFrame = Utility.Create("Frame", {
        Name = "Button_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 28),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = btnFrame,
    })
    local btn = Utility.Create("TextButton", {
        Name = "ActionButton",
        Parent = btnFrame,
        BackgroundColor3 = self.Library._colorEngine.CurrentColor,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, -16, 0, 22),
        Position = UDim2.new(0, 8, 0.5, -11),
        Font = Enum.Font.GothamSemibold,
        Text = name .. " [" .. interact .. "]",
        TextColor3 = Color3.fromRGB(220, 220, 230),
        TextSize = 11,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = btn,
    })

    btn.MouseButton1Click:Connect(function()
        self.Library._soundEngine:Play("Click")
        Utility.Tween(btn, TweenInfo.new(0.08), {
            Size = UDim2.new(1, -20, 0, 20),
        }, function()
            Utility.Tween(btn, TweenInfo.new(0.08), {
                Size = UDim2.new(1, -16, 0, 22),
            })
        end)
        Utility.Ripple(btn, Vector2.new(btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2))
        pcall(callback)
    end)
    btn.MouseEnter:Connect(function()
        Utility.Tween(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.5,
        })
    end)
    btn.MouseLeave:Connect(function()
        Utility.Tween(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.7,
        })
    end)

    self.Library._colorEngine:OnColorChanged(function(primary)
        if btn and btn.Parent then
            btn.BackgroundColor3 = primary
        end
    end)

    local component = {
        Type = "Button",
        Frame = btnFrame,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: LABEL
-- ============================================================
function Module:CreateLabel(options)
    options = options or {}
    local name = options.Name or "Label"
    local color = options.Color or Color3.fromRGB(180, 180, 195)

    local labelFrame = Utility.Create("Frame", {
        Name = "Label_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 0, 20),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = labelFrame,
    })
    local labelText = Utility.Create("TextLabel", {
        Name = "Text",
        Parent = labelFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = color,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })

    local component = {
        Type = "Label",
        Frame = labelFrame,
        SetText = function(_, newText)
            labelText.Text = newText
        end,
        SetColor = function(_, newColor)
            labelText.TextColor3 = newColor
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: PARAGRAPH
-- ============================================================
function Module:CreateParagraph(options)
    options = options or {}
    local name = options.Name or "Title"
    local content = options.Content or "Content text here."

    local pFrame = Utility.Create("Frame", {
        Name = "Paragraph_" .. name,
        Parent = self._subContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 38),
        Size = UDim2.new(1, 0, 0, 50),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = pFrame,
    })
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = pFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 4),
        Size = UDim2.new(1, -16, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    local contentLabel = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = pFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 20),
        Size = UDim2.new(1, -16, 0, 26),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(150, 150, 165),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 14,
    })

    local component = {
        Type = "Paragraph",
        Frame = pFrame,
        SetContent = function(_, newTitle, newContent)
            if newTitle then titleLabel.Text = newTitle end
            if newContent then contentLabel.Text = newContent end
        end,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SUB-COMPONENT: SECTION
-- ============================================================
function Module:CreateSection(options)
    options = options or {}
    local name = options.Name or "Section"

    local sectionFrame = Utility.Create("Frame", {
        Name = "Section_" .. name,
        Parent = self._subContainer,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        BorderSizePixel = 0,
        LayoutOrder = #self.SubComponents,
        ZIndex = 13,
    })
    local leftLine = Utility.Create("Frame", {
        Name = "LeftLine",
        Parent = sectionFrame,
        BackgroundColor3 = Color3.fromRGB(60, 60, 80),
        Size = UDim2.new(0.2, 0, 0, 1),
        Position = UDim2.new(0, 4, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 14,
    })
    local sectionLabel = Utility.Create("TextLabel", {
        Name = "SectionText",
        Parent = sectionFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.22, 0, 0, 0),
        Size = UDim2.new(0.56, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(130, 130, 150),
        TextSize = 10,
        ZIndex = 14,
    })
    local rightLine = Utility.Create("Frame", {
        Name = "RightLine",
        Parent = sectionFrame,
        BackgroundColor3 = Color3.fromRGB(60, 60, 80),
        Size = UDim2.new(0.2, 0, 0, 1),
        Position = UDim2.new(0.8, -4, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 14,
    })

    local component = {
        Type = "Section",
        Frame = sectionFrame,
    }
    table.insert(self.SubComponents, component)
    return component
end

-- ============================================================
-- SETTINGS CATEGORY (Built-in)
-- ============================================================
function Library:_createSettingsCategory()
    local settings = self:CreateCategory({
        Name = "Settings",
        Icon = "rbxassetid://7072706620",
    })
    settings._frame.Visible = true
    settings._hidden = false
    settings._wasVisible = true
    local viewportSize = Utility.GetViewportSize()
    settings._frame.Position = UDim2.new(0.5, -110, 0.5, -200)
    settings._frame.Size = UDim2.new(0, 240, 0, 32)
    -- =========================
    -- Visuals Module
    -- =========================
    local visualsModule = settings:CreateModule({
        Name = "Visuals",
        Info = "Visual settings for UI",
    })
    visualsModule:CreateDropdown({
        Name = "Color Mode",
        Options = {"Static", "Breathing", "Rainbow", "Gradient", "Rainbow-Wave"},
        Default = "Static",
        Flag = "Settings_ColorMode",
        Callback = function(mode)
            self._colorEngine:SetMode(mode)
        end,
    })
    visualsModule:CreateColorPicker({
        Name = "Primary Color",
        Default = Color3.fromRGB(81, 137, 253),
        Flag = "Settings_PrimaryColor",
        Callback = function(color)
            self._colorEngine:SetPrimary(color)
        end,
    })
    visualsModule:CreateColorPicker({
        Name = "Secondary Color",
        Default = Color3.fromRGB(180, 80, 255),
        Flag = "Settings_SecondaryColor",
        Callback = function(color)
            self._colorEngine:SetSecondary(color)
        end,
    })
    visualsModule:CreateSlider({
        Name = "Color Speed",
        Min = 0.1,
        Max = 5,
        Default = 1,
        Precise = true,
        Flag = "Settings_ColorSpeed",
        Callback = function(val)
            self._colorEngine:SetSpeed(val)
        end,
    })
    visualsModule:CreateSlider({
        Name = "Breath Amplitude",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Precise = true,
        Flag = "Settings_BreathAmplitude",
        Callback = function(val)
            self._colorEngine:SetBreathAmplitude(val)
        end,
    })
    visualsModule:CreateSlider({
        Name = "Gradient Rotation",
        Min = 0,
        Max = 360,
        Default = 0,
        Flag = "Settings_GradientRotation",
        Callback = function(val)
            self._colorEngine:SetGradientRotation(val)
        end,
    })
    visualsModule:CreateToggle({
        Name = "Background Particles",
        Default = false,
        Flag = "Settings_BackgroundParticles",
        Callback = function(enabled)
            if enabled then
                if not self._particleEngine then
                    self._particleEngine = ParticleEngine.new(settings._frame, self._colorEngine)
                end
                self._particleEngine:Start()
            else
                if self._particleEngine then
                    self._particleEngine:Stop()
                end
            end
        end,
    })
    visualsModule:CreateSlider({
        Name = "UI Transparency",
        Min = 0,
        Max = 0.9,
        Default = 0,
        Precise = true,
        Flag = "Settings_UITransparency",
        Callback = function(val)
            self._globalTransparency = val
            for _, window in ipairs(self.Windows) do
                if window._frame and window._frame.Visible then
                    window._frame.BackgroundTransparency = 0.02 + val
                end
            end
        end,
    })
    visualsModule:CreateSlider({
        Name = "UI Scale",
        Min = 0.5,
        Max = 1.5,
        Default = 1,
        Precise = true,
        Flag = "Settings_UIScale",
        Callback = function(val)
            self._globalScale = val
            if self._uiScale then
                self._uiScale.Scale = val
            end
        end,
    })

    -- =========================
    -- Behavior Module
    -- =========================
    local behaviorModule = settings:CreateModule({
        Name = "Behavior",
        Info = "Interaction & behavior settings",
    })
    behaviorModule:CreateKeybind({
        Name = "Toggle Key",
        Default = Enum.KeyCode.RightShift,
        Flag = "Settings_ToggleKey",
        Callback = function(key)
            self._toggleKey = key
        end,
    })
    behaviorModule:CreateToggle({
        Name = "Mobile Float Button",
        Default = true,
        Flag = "Settings_MobileButton",
        Callback = function(enabled)
            self._mobileButtonEnabled = enabled
            if self._mobileButton then
                self._mobileButton.Visible = enabled
            end
        end,
    })
    behaviorModule:CreateToggle({
        Name = "Binds Active When Hidden",
        Default = true,
        Flag = "Settings_BindsActiveHidden",
        Callback = function(enabled)
            self._keybindActiveWhenHidden = enabled
        end,
    })
    behaviorModule:CreateToggle({
        Name = "Window Magnetic Snap",
        Default = true,
        Flag = "Settings_MagneticSnap",
        Callback = function(enabled)
            self._magneticSnap = enabled
        end,
    })
    behaviorModule:CreateSlider({
        Name = "Animation Speed",
        Min = 0.05,
        Max = 1,
        Default = 0.25,
        Precise = true,
        Unit = "s",
        Flag = "Settings_AnimSpeed",
        Callback = function(val)
            self._animSpeed = val
        end,
    })

    -- =========================
    -- HUD & Notifications Module
    -- =========================
    local hudModule = settings:CreateModule({
        Name = "HUD & Notifications",
        Info = "HUD overlay settings",
    })
    hudModule:CreateToggle({
        Name = "ArrayList",
        Default = false,
        Flag = "Settings_ArrayList",
        Callback = function(enabled)
            self._arrayList:SetEnabled(enabled)
        end,
    })
    hudModule:CreateToggle({
        Name = "Performance Watermark",
        Default = false,
        Flag = "Settings_Watermark",
        Callback = function(enabled)
            self._watermark:SetEnabled(enabled)
        end,
    })
    hudModule:CreateToggle({
        Name = "Popup Notifications",
        Default = true,
        Flag = "Settings_Notifications",
        Callback = function(enabled)
            self._notificationSystem:SetEnabled(enabled)
        end,
    })
    hudModule:CreateSlider({
        Name = "Notification Duration",
        Min = 1,
        Max = 15,
        Default = 4,
        Unit = "s",
        Flag = "Settings_NotifDuration",
        Callback = function(val)
            self._notificationSystem:SetDuration(val)
        end,
    })

    -- =========================
    -- Audio Module
    -- =========================
    local audioModule = settings:CreateModule({
        Name = "Audio",
        Info = "Sound settings",
    })
    audioModule:CreateToggle({
        Name = "UI Sounds",
        Default = true,
        Flag = "Settings_SoundsEnabled",
        Callback = function(enabled)
            self._soundEngine:SetEnabled(enabled)
        end,
    })
    audioModule:CreateSlider({
        Name = "Volume",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Precise = true,
        Flag = "Settings_Volume",
        Callback = function(val)
            self._soundEngine:SetVolume(val)
        end,
    })

    -- =========================
    -- System Module
    -- =========================
    local systemModule = settings:CreateModule({
        Name = "System",
        Info = "Config & system controls",
    })
    systemModule:CreateTextBox({
        Name = "Config Profile",
        Placeholder = "default",
        ClearOnFocus = true,
        Flag = "Settings_ConfigProfile",
        Callback = function(text, enter)
            if enter and text ~= "" then
                self._configManager.CurrentProfile = text
                self:CreateNotification({
                    Title = "Config",
                    Content = "Profile set to: " .. text,
                    Type = "Info",
                    Time = 3,
                })
            end
        end,
    })
    systemModule:CreateToggle({
        Name = "Auto Save",
        Default = false,
        Flag = "Settings_AutoSave",
        Callback = function(enabled)
            self._configManager.AutoSave = enabled
        end,
    })
    systemModule:CreateButton({
        Name = "Save Config",
        Interact = "Save",
        Callback = function()
            self._configManager:Save()
            self:CreateNotification({
                Title = "Config",
                Content = "Configuration saved: " .. self._configManager.CurrentProfile,
                Type = "Success",
                Time = 3,
            })
        end,
    })
    systemModule:CreateButton({
        Name = "Load Config",
        Interact = "Load",
        Callback = function()
            local success = self._configManager:Load()
            if success then
                self:CreateNotification({
                    Title = "Config",
                    Content = "Configuration loaded: " .. self._configManager.CurrentProfile,
                    Type = "Success",
                    Time = 3,
                })
            else
                self:CreateNotification({
                    Title = "Config",
                    Content = "Failed to load configuration.",
                    Type = "Error",
                    Time = 3,
                })
            end
        end,
    })
    self._runtimeLabel = systemModule:CreateLabel({
        Name = "Runtime: 00:00",
        Color = Color3.fromRGB(140, 140, 160),
    })
    task.spawn(function()
        while not self._destroyed do
            if self._runtimeLabel then
                local elapsed = tick() - self._startTime
                local mins = math.floor(elapsed / 60)
                local secs = math.floor(elapsed % 60)
                self._runtimeLabel:SetText(nil, string.format("Runtime: %02d:%02d", mins, secs))
            end
            task.wait(1)
        end
    end)
    systemModule:CreateButton({
        Name = "Self-Destruct",
        Interact = "DESTROY",
        Callback = function()
            self:Destroy()
        end,
    })

    self._settingsCategory = settings
end

-- ============================================================
-- WELCOME SCREEN
-- ============================================================
function Library:SpawnWelcome(options)
    options = options or {}
    local title = options.Title or "Welcome"
    local content = options.Content or "VapeUI has been loaded successfully."
    local delayTime = options.Delay or 4

    self._soundEngine:Play("Welcome")

    local welcomeFrame = Utility.Create("Frame", {
        Name = "WelcomeScreen",
        Parent = self._screenGui,
        BackgroundColor3 = Color3.fromRGB(18, 18, 28),
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 340, 0, 160),
        Position = UDim2.new(0.5, -170, 0.5, -80),
        BorderSizePixel = 0,
        ZIndex = 500,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = welcomeFrame,
    })
    local welcomeStroke = Utility.Create("UIStroke", {
        Parent = welcomeFrame,
        Color = self._colorEngine.CurrentColor,
        Thickness = 2,
        Transparency = 0.2,
    })
    local accentTop = Utility.Create("Frame", {
        Name = "AccentTop",
        Parent = welcomeFrame,
        BackgroundColor3 = self._colorEngine.CurrentColor,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 501,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = accentTop,
    })
    local userId = LocalPlayer.UserId
    local thumbnailUrl = ""
    pcall(function()
        thumbnailUrl = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    local avatarImage = Utility.Create("ImageLabel", {
        Name = "Avatar",
        Parent = welcomeFrame,
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        Position = UDim2.new(0, 20, 0, 25),
        Size = UDim2.new(0, 60, 0, 60),
        Image = thumbnailUrl,
        ZIndex = 502,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = avatarImage,
    })
    Utility.Create("UIStroke", {
        Parent = avatarImage,
        Color = self._colorEngine.CurrentColor,
        Thickness = 2,
    })
    local welcomeTitle = Utility.Create("TextLabel", {
        Name = "Title",
        Parent = welcomeFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 95, 0, 25),
        Size = UDim2.new(1, -110, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Color3.fromRGB(240, 240, 250),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
    })
    local welcomeUser = Utility.Create("TextLabel", {
        Name = "Username",
        Parent = welcomeFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 95, 0, 50),
        Size = UDim2.new(1, -110, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = "Player: " .. LocalPlayer.Name,
        TextColor3 = self._colorEngine.CurrentColor,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
    })
    local welcomeContent = Utility.Create("TextLabel", {
        Name = "Content",
        Parent = welcomeFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 95, 0, 72),
        Size = UDim2.new(1, -110, 0, 30),
        Font = Enum.Font.Gotham,
        Text = content,
        TextColor3 = Color3.fromRGB(170, 170, 185),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 502,
    })
    local progressBarBg = Utility.Create("Frame", {
        Name = "ProgressBg",
        Parent = welcomeFrame,
        BackgroundColor3 = Color3.fromRGB(35, 35, 50),
        Size = UDim2.new(1, -40, 0, 4),
        Position = UDim2.new(0, 20, 1, -22),
        BorderSizePixel = 0,
        ZIndex = 502,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressBarBg,
    })
    local progressBarFill = Utility.Create("Frame", {
        Name = "ProgressFill",
        Parent = progressBarBg,
        BackgroundColor3 = self._colorEngine.CurrentColor,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 503,
    })
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = progressBarFill,
    })

    welcomeFrame.BackgroundTransparency = 1
    for _, child in ipairs(welcomeFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
        elseif child:IsA("ImageLabel") then
            child.ImageTransparency = 1
        elseif child:IsA("Frame") and child.Name ~= "ProgressBg" and child.Name ~= "ProgressFill" then
            child.BackgroundTransparency = 1
        end
    end
    Utility.Tween(welcomeFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05,
    })
    task.delay(0.1, function()
        for _, child in ipairs(welcomeFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                Utility.Tween(child, TweenInfo.new(0.4), {TextTransparency = 0})
            elseif child:IsA("ImageLabel") then
                Utility.Tween(child, TweenInfo.new(0.4), {ImageTransparency = 0})
            end
        end
        Utility.Tween(accentTop, TweenInfo.new(0.3), {BackgroundTransparency = 0})
    end)
    Utility.Tween(progressBarFill, TweenInfo.new(delayTime, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0),
    })
    task.delay(delayTime, function()
        Utility.Tween(welcomeFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -170, 0.5, -60),
        })
        for _, child in ipairs(welcomeFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                Utility.Tween(child, TweenInfo.new(0.3), {TextTransparency = 1})
            elseif child:IsA("ImageLabel") then
                Utility.Tween(child, TweenInfo.new(0.3), {ImageTransparency = 1})
            elseif child:IsA("Frame") then
                Utility.Tween(child, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            end
        end
        task.delay(0.55, function()
            welcomeFrame:Destroy()
        end)
    end)
end

-- ============================================================
-- NOTIFICATION SHORTCUT
-- ============================================================
function Library:CreateNotification(options)
    if self._notificationSystem then
        self._notificationSystem:Push(options)
    end
end

-- ============================================================
-- DESTROY (Self-Destruct)
-- ============================================================
function Library:Destroy()
    self._destroyed = true
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    if self._colorEngine then
        self._colorEngine:Destroy()
    end
    if self._soundEngine then
        self._soundEngine:Destroy()
    end
    if self._notificationSystem then
        self._notificationSystem:Destroy()
    end
    if self._particleEngine then
        self._particleEngine:Destroy()
    end
    if self._arrayList then
        self._arrayList:Destroy()
    end
    if self._watermark then
        self._watermark:Destroy()
    end
    if self._screenGui then
        self._screenGui:Destroy()
    end
    setmetatable(self, nil)
end

-- ============================================================
-- RETURN MODULE
-- ============================================================
return Library

--[[
==============================================================
USAGE EXAMPLE (paste below the library or in separate script):
==============================================================

local Library = (loadstring or require)(...)  -- however you load it
local VapeUI = Library.new()
VapeUI:Init({
    Name = "VapeUI",
    ToggleKey = Enum.KeyCode.RightShift,
    AnimationSpeed = 0.25,
})

VapeUI:SpawnWelcome({
    Title = "Welcome to VapeUI",
    Content = "Your premium script UI has loaded.",
    Delay = 4,
})

-- Create a category
local Combat = VapeUI:CreateCategory({
    Name = "Combat",
    Icon = "rbxassetid://7072706620",
})
Combat:Show()

-- Create a module
local KillAura = Combat:CreateModule({
    Name = "Kill Aura",
    Info = "Attacks nearby players",
    Default = false,
})

-- Add sub-components to the module
KillAura:CreateToggle({
    Name = "Enabled",
    Default = false,
    Flag = "KillAura_Enabled",
    Callback = function(value)
        print("Kill Aura:", value)
    end,
})

KillAura:CreateSlider({
    Name = "Range",
    Min = 1,
    Max = 20,
    Default = 5,
    Unit = " studs",
    Flag = "KillAura_Range",
    Callback = function(value)
        print("Range:", value)
    end,
})

KillAura:CreateDropdown({
    Name = "Target Mode",
    Options = {"Closest", "Lowest HP", "Random"},
    Default = "Closest",
    Flag = "KillAura_TargetMode",
    Callback = function(value)
        print("Target:", value)
    end,
})

KillAura:CreateColorPicker({
    Name = "Highlight Color",
    Default = Color3.fromRGB(255, 0, 0),
    Alpha = true,
    Flag = "KillAura_Color",
    Callback = function(color, alpha)
        print("Color:", color, "Alpha:", alpha)
    end,
})

KillAura:CreateKeybind({
    Name = "Toggle Bind",
    Default = Enum.KeyCode.R,
    Flag = "KillAura_Bind",
    Callback = function(key)
        print("Keybind:", key)
    end,
})

KillAura:CreateTextBox({
    Name = "Target Name",
    Placeholder = "Player name...",
    Flag = "KillAura_TargetName",
    Callback = function(text, enter)
        print("Target:", text, "Enter:", enter)
    end,
})

KillAura:CreateButton({
    Name = "Reset Targets",
    Interact = "Reset",
    Callback = function()
        print("Targets reset!")
    end,
})

KillAura:CreateLabel({
    Name = "Status: Idle",
    Color = Color3.fromRGB(180, 180, 200),
})

KillAura:CreateParagraph({
    Name = "Info",
    Content = "Kill Aura automatically attacks nearby entities within range.",
})

KillAura:CreateSection({
    Name = "Advanced Options",
})

KillAura:CreateToggle({
    Name = "Multi-Target",
    Default = false,
    Flag = "KillAura_MultiTarget",
    Callback = function(value)
        print("Multi:", value)
    end,
})

-- Notification test
VapeUI:CreateNotification({
    Title = "Loaded!",
    Content = "All modules initialized.",
    Type = "Success",
    Time = 4,
})
]]
