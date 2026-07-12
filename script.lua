--!strict
-- ZenithUI.lua
-- Minimal + Advanced Roblox UI Library (Legit in-experience UI)
-- Single-file, theme, transparency, config import/export, crisp sounds (replace ids),
-- advanced tweens, notifications, keybind toggles, etc.

local ZenithUI = {}
ZenithUI.__index = ZenithUI

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--// ---------- Utilities ----------
type Dict = {[string]: any}

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function deepCopy(t: any): any
	if typeof(t) ~= "table" then return t end
	local out = {}
	for k,v in pairs(t) do
		out[k] = deepCopy(v)
	end
	return out
end

local function safeCall(fn, ...)
	if typeof(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[ZenithUI] callback error:", err)
	end
end

local function Create(className: string, props: Dict?, children: {Instance}?)
	local inst = Instance.new(className)
	if props then
		for k,v in pairs(props) do
			(inst :: any)[k] = v
		end
	end
	if children then
		for _,child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

local function addCorner(parent: Instance, radius: number)
	return Create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = parent})
end

local function addStroke(parent: Instance, color: Color3, transparency: number, thickness: number)
	return Create("UIStroke", {
		Color = color,
		Transparency = transparency,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
end

local function addPadding(parent: Instance, p: number)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0,p),
		PaddingRight = UDim.new(0,p),
		PaddingTop = UDim.new(0,p),
		PaddingBottom = UDim.new(0,p),
		Parent = parent
	})
end

local function addListLayout(parent: Instance, padding: number, fillDir: Enum.FillDirection, align: Enum.HorizontalAlignment?, vAlign: Enum.VerticalAlignment?)
	local ll = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, padding),
		FillDirection = fillDir,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		Parent = parent
	})
	return ll
end

local function tween(inst: Instance, info: TweenInfo, goal: Dict)
	local tw = TweenService:Create(inst, info, goal)
	tw:Play()
	return tw
end

local function isMobile(): boolean
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

--// ---------- Signal (lightweight) ----------
local Signal = {}
Signal.__index = Signal
function Signal.new()
	return setmetatable({_binds = {}}, Signal)
end
function Signal:Connect(fn)
	table.insert(self._binds, fn)
	return {
		Disconnect = function()
			local idx = table.find(self._binds, fn)
			if idx then table.remove(self._binds, idx) end
		end
	}
end
function Signal:Fire(...)
	for _,fn in ipairs(self._binds) do
		safeCall(fn, ...)
	end
end

--// ---------- Maid ----------
local Maid = {}
Maid.__index = Maid
function Maid.new()
	return setmetatable({_tasks = {}}, Maid)
end
function Maid:Give(task)
	table.insert(self._tasks, task)
	return task
end
function Maid:Cleanup()
	for i = #self._tasks, 1, -1 do
		local t = self._tasks[i]
		self._tasks[i] = nil
		if typeof(t) == "RBXScriptConnection" then
			t:Disconnect()
		elseif typeof(t) == "Instance" then
			t:Destroy()
		elseif typeof(t) == "table" and typeof(t.Destroy) == "function" then
			pcall(function() t:Destroy() end)
		elseif typeof(t) == "function" then
			pcall(t)
		end
	end
end

--// ---------- Theme helpers ----------
local function lighten(c: Color3, amt: number): Color3
	return Color3.new(
		math.clamp(c.R + amt, 0, 1),
		math.clamp(c.G + amt, 0, 1),
		math.clamp(c.B + amt, 0, 1)
	)
end

local function darken(c: Color3, amt: number): Color3
	return Color3.new(
		math.clamp(c.R - amt, 0, 1),
		math.clamp(c.G - amt, 0, 1),
		math.clamp(c.B - amt, 0, 1)
	)
end

--// ---------- Defaults ----------
local DEFAULTS = {
	Name = "Zenith UI",
	Accent = Color3.fromRGB(120, 170, 255),
	Background = Color3.fromRGB(18, 18, 20),
	Surface = Color3.fromRGB(24, 24, 28),
	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(170, 170, 180),
	Stroke = Color3.fromRGB(60, 60, 70),

	Transparency = 0.06, -- applied as BackgroundTransparency-ish, smaller = more solid
	Blur = false,
	ToggleKey = Enum.KeyCode.RightShift,

	Sounds = {
		Click = "rbxassetid://6895079853",  -- replace with your crisp click
		Hover = "rbxassetid://9118823101",  -- replace
		Notify = "rbxassetid://9118826044"  -- replace
	}
}

--// ---------- Main constructor ----------
function ZenithUI.new(options: Dict?)
	local self = setmetatable({}, ZenithUI)

	self.Options = deepCopy(DEFAULTS)
	if options then
		for k,v in pairs(options) do
			if typeof(v) == "table" and typeof(self.Options[k]) == "table" then
				for kk,vv in pairs(v) do
					self.Options[k][kk] = vv
				end
			else
				self.Options[k] = v
			end
		end
	end

	self.Theme = {
		Accent = self.Options.Accent,
		Background = self.Options.Background,
		Surface = self.Options.Surface,
		Text = self.Options.Text,
		SubText = self.Options.SubText,
		Stroke = self.Options.Stroke
	}

	self.Flags = {}      :: Dict
	self.Controls = {}   :: Dict  -- flag -> control object with SetValue/GetValue
	self.Windows = {}    :: {any}

	self._maid = Maid.new()
	self._notifs = {}
	self._notifQueue = {}
	self._notifBusy = false

	-- pre-create sound objects (parent later)
	self._sounds = {}
	for name, id in pairs(self.Options.Sounds) do
		local s = Create("Sound", {
			Name = "ZenithSound_"..name,
			SoundId = id,
			Volume = 0.55
		})
		self._sounds[name] = s
	end

	return self
end

function ZenithUI:_playSound(name: string)
	local s = self._sounds[name]
	if not s then return end
	-- parent to SoundService or PlayerGui later; safe fallback
	if not s.Parent then
		local sg = self._screenGui
		s.Parent = sg or game:GetService("SoundService")
	end
	s:Play()
end

--// ---------- Config ----------
function ZenithUI:GetFlag(flag: string)
	return self.Flags[flag]
end

function ZenithUI:SetFlag(flag: string, value: any)
	self.Flags[flag] = value
	local ctrl = self.Controls[flag]
	if ctrl and typeof(ctrl.SetValue) == "function" then
		ctrl:SetValue(value, true)
	end
end

function ZenithUI:ExportConfig(): string
	local payload = {
		Version = 1,
		Flags = self.Flags,
		Theme = {
			Accent = {self.Theme.Accent.R, self.Theme.Accent.G, self.Theme.Accent.B},
			Transparency = self.Options.Transparency
		}
	}
	return HttpService:JSONEncode(payload)
end

function ZenithUI:ImportConfig(json: string)
	local ok, payload = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or typeof(payload) ~= "table" then
		self:Notify({Title="Config", Content="Import failed: invalid JSON", Type="Error", Duration=3})
		return
	end

	if payload.Theme and payload.Theme.Accent then
		local a = payload.Theme.Accent
		if typeof(a) == "table" and #a >= 3 then
			self:SetThemeColor(Color3.new(a[1], a[2], a[3]))
		end
	end
	if payload.Theme and typeof(payload.Theme.Transparency) == "number" then
		self:SetTransparency(payload.Theme.Transparency)
	end

	if payload.Flags then
		for flag, val in pairs(payload.Flags) do
			self:SetFlag(flag, val)
		end
	end

	self:Notify({Title="Config", Content="Imported successfully", Type="Success", Duration=2.5})
end

--// ---------- Global appearance ----------
function ZenithUI:SetThemeColor(color: Color3)
	self.Theme.Accent = color
	for _,w in ipairs(self.Windows) do
		if w and typeof(w._applyTheme) == "function" then
			w:_applyTheme()
		end
	end
end

function ZenithUI:SetTransparency(alpha01: number)
	self.Options.Transparency = clamp01(alpha01)
	for _,w in ipairs(self.Windows) do
		if w and typeof(w._applyTransparency) == "function" then
			w:_applyTransparency()
		end
	end
end

--// ---------- Notification system ----------
local NOTIF_COLORS = {
	Info = Color3.fromRGB(120,170,255),
	Success = Color3.fromRGB(120, 255, 170),
	Warn = Color3.fromRGB(255, 210, 120),
	Error = Color3.fromRGB(255, 120, 140)
}

function ZenithUI:_ensureNotifLayer()
	if self._notifLayer then return end
	if not self._screenGui then return end

	local layer = Create("Frame", {
		Name = "Zenith_Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		Parent = self._screenGui,
		ZIndex = 50
	})

	local container = Create("Frame", {
		Name = "Container",
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-16,0,16),
		Size = UDim2.new(0, 340, 1, -32),
		BackgroundTransparency = 1,
		Parent = layer
	})

	addListLayout(container, 10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)

	self._notifLayer = layer
	self._notifContainer = container
end

function ZenithUI:Notify(opt: Dict)
	-- opt: Title, Content, Type, Duration
	opt = opt or {}
	local item = {
		Title = tostring(opt.Title or "Notification"),
		Content = tostring(opt.Content or ""),
		Type = tostring(opt.Type or "Info"),
		Duration = tonumber(opt.Duration or 3.5) or 3.5
	}
	table.insert(self._notifQueue, item)
	self:_drainNotifQueue()
end

function ZenithUI:_drainNotifQueue()
	if self._notifBusy then return end
	self._notifBusy = true

	task.spawn(function()
		while #self._notifQueue > 0 do
			local item = table.remove(self._notifQueue, 1)
			self:_showNotif(item)
			task.wait(0.18)
		end
		self._notifBusy = false
	end)
end

function ZenithUI:_showNotif(item: Dict)
	self:_ensureNotifLayer()
	if not self._notifContainer then return end

	self:_playSound("Notify")

	local accent = NOTIF_COLORS[item.Type] or self.Theme.Accent

	local root = Create("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = self.Options.Transparency,
		Parent = self._notifContainer,
		ZIndex = 60
	})
	addCorner(root, 10)
	addStroke(root, darken(self.Theme.Stroke, 0.05), 0.35, 1)

	local pad = addPadding(root, 12)
	pad.PaddingBottom = UDim.new(0, 10)

	local header = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,20),
		Parent = root,
		ZIndex = 61
	})

	local dot = Create("Frame", {
		Size = UDim2.fromOffset(10,10),
		AnchorPoint = Vector2.new(0,0.5),
		Position = UDim2.new(0,0,0.5,0),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0,
		Parent = header,
		ZIndex = 62
	})
	addCorner(dot, 99)

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = item.Title,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = self.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Parent = header,
		ZIndex = 62
	})

	local close = Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "×",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = self.Theme.SubText,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,0,0,0),
		Size = UDim2.fromOffset(28,20),
		Parent = header,
		ZIndex = 62
	})

	local body = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = item.Content,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = self.Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1,0,0,0),
		Parent = root,
		ZIndex = 61
	})

	local barBG = Create("Frame", {
		BackgroundColor3 = darken(self.Theme.Surface, 0.05),
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1,0,0,4),
		Parent = root,
		ZIndex = 61
	})
	addCorner(barBG, 99)

	local bar = Create("Frame", {
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1,0,1,0),
		Parent = barBG,
		ZIndex = 62
	})
	addCorner(bar, 99)

	-- appear animation
	root.ClipsDescendants = true
	root.Size = UDim2.new(1,0,0,0)
	root.BackgroundTransparency = 1

	tween(root, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = self.Options.Transparency
	})

	local targetHeight = math.max(74, body.TextBounds.Y + 56)
	tween(root, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(1,0,0,targetHeight)
	})

	-- progress
	local duration = math.max(1, item.Duration)
	local prog = tween(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0,0,1,0)
	})

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		if prog then pcall(function() prog:Cancel() end) end

		tween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1
		})
		tween(root, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1,0,0,0)
		})
		task.delay(0.22, function()
			if root then root:Destroy() end
		end)
	end

	close.MouseButton1Click:Connect(dismiss)
	task.delay(duration, dismiss)
end

--// ---------- Window / Tab / Section / Controls ----------
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

-- control object shape:
-- { Flag, SetValue(value, silent), GetValue() }

local function makeText(parent: Instance, text: string, size: number, bold: boolean, color: Color3)
	return Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
		TextSize = size,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,size+8),
		Parent = parent
	})
end

function ZenithUI:CreateWindow(options: Dict)
	options = options or {}

	local window = setmetatable({}, Window)
	window.UI = self
	window.Title = tostring(options.Title or self.Options.Name)
	window.Subtitle = tostring(options.Subtitle or "UI Library")
	window.Size = options.Size or UDim2.fromOffset(640, 420)

	window.Tabs = {}
	window.ActiveTab = nil
	window._maid = Maid.new()
	window._registry = { -- instances that should react to theme/transparency
		Surfaces = {},
		Strokes = {},
		Accent = {},
		Text = {},
		SubText = {}
	}

	-- ScreenGui
	if not self._screenGui then
		local sg = Create("ScreenGui", {
			Name = "ZenithUI",
			ResetOnSpawn = false,
			IgnoreGuiInset = true
		})
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
		self._screenGui = sg

		-- parent sounds
		for _,s in pairs(self._sounds) do
			s.Parent = sg
		end
	end

	-- Root
	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = window.Size,
		BackgroundColor3 = self.Theme.Background,
		BackgroundTransparency = self.Options.Transparency,
		Parent = self._screenGui,
		ZIndex = 10
	})
	addCorner(root, 14)
	local stroke = addStroke(root, self.Theme.Stroke, 0.35, 1)

	table.insert(window._registry.Surfaces, root)
	table.insert(window._registry.Strokes, stroke)

	-- Shadow (simple)
	local shadow = Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217", -- soft shadow (common)
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10,10,118,118),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.fromScale(0.5,0.5),
		Size = UDim2.new(1, 50, 1, 50),
		ZIndex = 9,
		Parent = root
	})

	-- Top bar
	local top = Create("Frame", {
		Name = "Top",
		Size = UDim2.new(1,0,0,52),
		BackgroundTransparency = 1,
		Parent = root,
		ZIndex = 11
	})
	addPadding(top, 14)

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = window.Title,
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextColor3 = self.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,22),
		Parent = top,
		ZIndex = 12
	})
	table.insert(window._registry.Text, title)

	local sub = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = window.Subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0,0,0,24),
		Size = UDim2.new(1,0,0,18),
		Parent = top,
		ZIndex = 12
	})
	table.insert(window._registry.SubText, sub)

	local divider = Create("Frame", {
		Name = "Divider",
		BackgroundColor3 = darken(self.Theme.Stroke, 0.05),
		BackgroundTransparency = 0.65,
		Position = UDim2.new(0,0,0,52),
		Size = UDim2.new(1,0,0,1),
		Parent = root,
		ZIndex = 11
	})

	-- Body
	local body = Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0,0,0,53),
		Size = UDim2.new(1,0,1,-53),
		Parent = root,
		ZIndex = 11
	})

	-- Left tab column
	local tabCol = Create("Frame", {
		Name = "Tabs",
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = self.Options.Transparency,
		Size = UDim2.new(0, 172, 1, 0),
		Parent = body,
		ZIndex = 11
	})
	addPadding(tabCol, 10)
	addCorner(tabCol, 0) -- flush
	local tabStroke = addStroke(tabCol, darken(self.Theme.Stroke, 0.05), 0.55, 1)

	table.insert(window._registry.Surfaces, tabCol)
	table.insert(window._registry.Strokes, tabStroke)

	local tabList = Create("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Parent = tabCol
	})
	addListLayout(tabList, 8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	-- Right content
	local content = Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 172, 0, 0),
		Size = UDim2.new(1, -172, 1, 0),
		Parent = body,
		ZIndex = 11
	})
	addPadding(content, 14)

	local pages = Create("Folder", {Name="Pages", Parent = content})

	-- Dragging
	do
		local dragging = false
		local dragStart: Vector2? = nil
		local startPos: UDim2? = nil

		local function inputBegan(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end

		local function inputEnded(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end

		local function inputChanged(input: InputObject)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not dragStart or not startPos then return end
			local delta = input.Position - dragStart
			root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end

		top.InputBegan:Connect(inputBegan)
		top.InputEnded:Connect(inputEnded)
		UIS.InputChanged:Connect(inputChanged)
	end

	-- Toggle visibility key
	window.Visible = true
	local function setVisible(on: boolean)
		window.Visible = on
		root.Visible = on
		if on then
			tween(root, TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = window.Size})
			root.BackgroundTransparency = 1
			tween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = self.Options.Transparency})
		end
	end

	window._maid:Give(UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == self.Options.ToggleKey then
			setVisible(not window.Visible)
			self:_playSound("Click")
		end
	end))

	-- Store refs
	window.Root = root
	window.TabColumn = tabList
	window.Pages = pages

	function window:_applyTheme()
		root.BackgroundColor3 = self.UI.Theme.Background
		tabCol.BackgroundColor3 = self.UI.Theme.Surface
		divider.BackgroundColor3 = darken(self.UI.Theme.Stroke, 0.05)

		for _,inst in ipairs(self._registry.Surfaces) do
			if inst and inst:IsA("GuiObject") then
				inst.BackgroundColor3 = (inst == root) and self.UI.Theme.Background or self.UI.Theme.Surface
			end
		end
		for _,st in ipairs(self._registry.Strokes) do
			if st and st:IsA("UIStroke") then
				st.Color = self.UI.Theme.Stroke
			end
		end
		for _,tinst in ipairs(self._registry.Text) do
			if tinst and tinst:IsA("TextLabel") then
				tinst.TextColor3 = self.UI.Theme.Text
			end
		end
		for _,tinst in ipairs(self._registry.SubText) do
			if tinst and tinst:IsA("TextLabel") then
				tinst.TextColor3 = self.UI.Theme.SubText
			end
		end
		for _,ainst in ipairs(self._registry.Accent) do
			if ainst and ainst:IsA("GuiObject") then
				ainst.BackgroundColor3 = self.UI.Theme.Accent
			end
		end
	end

	function window:_applyTransparency()
		local tval = self.UI.Options.Transparency
		root.BackgroundTransparency = tval
		tabCol.BackgroundTransparency = tval
	end

	-- Settings tab built-in
	window:_buildSettingsTab()

	table.insert(self.Windows, window)
	return window
end

--// Window: settings tab
function Window:_buildSettingsTab()
	local ui = self.UI
	local settings = self:AddTab("Settings")

	local secUI = settings:AddSection("UI")
	secUI:AddSlider({
		Text = "Transparency",
		Min = 0,
		Max = 0.6,
		Default = ui.Options.Transparency,
		Step = 0.01,
		Flag = "__ui_transparency",
		Callback = function(v)
			ui:SetTransparency(v)
		end
	})

	secUI:AddColorPicker({
		Text = "Theme Accent",
		Default = ui.Theme.Accent,
		Flag = "__ui_accent",
		Callback = function(c)
			ui:SetThemeColor(c)
		end
	})

	local secCfg = settings:AddSection("Config")
	secCfg:AddLabel("Export / Import JSON (store it anywhere you like).")

	local exportBox = secCfg:AddTextbox({
		Text = "Config JSON",
		Placeholder = "Press Export to generate JSON...",
		Default = "",
		Flag = "__ui_config_box",
		MultiLine = true,
		Callback = function(_) end
	})

	secCfg:AddButton({
		Text = "Export",
		Callback = function()
			local json = ui:ExportConfig()
			exportBox:SetValue(json, true)
			ui:Notify({Title="Config", Content="Exported to text box", Type="Info", Duration=2.2})
		end
	})

	secCfg:AddButton({
		Text = "Import",
		Callback = function()
			local json = exportBox:GetValue()
			ui:ImportConfig(json)
		end
	})

	secCfg:AddDivider()
	secCfg:AddLabel("Tip: You can bind your own persistence (DataStore/server) using Export/Import.")
end

--// Window: AddTab
function Window:AddTab(name: string, iconId: string?)
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.UI = self.UI
	tab.Name = name
	tab.IconId = iconId
	tab.Sections = {}
	tab._maid = Maid.new()

	-- Tab button
	local btn = Create("TextButton", {
		Name = "TabButton_"..name,
		BackgroundColor3 = tab.UI.Theme.Surface,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,36),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabColumn,
		ZIndex = 12
	})
	addCorner(btn, 10)

	local icon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = iconId or "",
		ImageTransparency = iconId and 0 or 1,
		Size = UDim2.fromOffset(18,18),
		Position = UDim2.new(0,10,0.5,-9),
		Parent = btn,
		ZIndex = 13
	})

	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = tab.UI.Theme.SubText,
		Position = UDim2.new(0, iconId and 34 or 12, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Parent = btn,
		ZIndex = 13
	})

	local accentBar = Create("Frame", {
		BackgroundColor3 = tab.UI.Theme.Accent,
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 3, 0, 16),
		AnchorPoint = Vector2.new(0,0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Parent = btn,
		Visible = false,
		ZIndex = 14
	})
	addCorner(accentBar, 99)

	-- Page
	local page = Create("ScrollingFrame", {
		Name = "TabPage_"..name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		CanvasSize = UDim2.fromOffset(0,0),
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.25,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = self.Pages,
		ZIndex = 11
	})

	local content = Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = page
	})
	addListLayout(content, 12, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	-- Auto canvas sizing
	local ll = content:FindFirstChildOfClass("UIListLayout")
	if ll then
		ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0,0,0, ll.AbsoluteContentSize.Y + 8)
		end)
	end

	tab.Button = btn
	tab.Label = label
	tab.AccentBar = accentBar
	tab.Page = page
	tab.Container = content

	-- register for theme updates
	table.insert(self._registry.SubText, label)
	table.insert(self._registry.Accent, accentBar)

	local function setActive()
		-- deactivate others
		for _,t in ipairs(self.Tabs) do
			t.Page.Visible = false
			t.AccentBar.Visible = false
			t.Label.TextColor3 = self.UI.Theme.SubText
			t.Button.BackgroundTransparency = 1
		end
		self.ActiveTab = tab
		tab.Page.Visible = true
		tab.AccentBar.Visible = true

		self.UI:_playSound("Click")
		tween(tab.Button, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.85
		})
		tab.Button.BackgroundColor3 = self.UI.Theme.Surface
		tab.Label.TextColor3 = self.UI.Theme.Text

		-- subtle page animation
		tab.Page.Position = UDim2.new(0, 10, 0, 0)
		tween(tab.Page, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0,0,0,0)
		})
	end

	btn.MouseEnter:Connect(function()
		self.UI:_playSound("Hover")
		if self.ActiveTab ~= tab then
			tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.92
			})
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			})
		end
	end)

	btn.MouseButton1Click:Connect(setActive)

	table.insert(self.Tabs, tab)

	-- auto select first tab
	if #self.Tabs == 1 then
		setActive()
	end

	return tab
end

--// Tab: AddSection
function Tab:AddSection(title: string)
	local section = setmetatable({}, Section)
	section.Tab = self
	section.Window = self.Window
	section.UI = self.UI
	section.Title = title
	section._maid = Maid.new()

	local root = Create("Frame", {
		Name = "Section_"..title,
		BackgroundColor3 = self.UI.Theme.Surface,
		BackgroundTransparency = self.UI.Options.Transparency,
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.Container,
		ZIndex = 12
	})
	addCorner(root, 12)
	local st = addStroke(root, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)
	addPadding(root, 12)

	table.insert(self.Window._registry.Surfaces, root)
	table.insert(self.Window._registry.Strokes, st)

	local header = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,20),
		Parent = root,
		ZIndex = 13
	})
	table.insert(self.Window._registry.Text, header)

	local list = Create("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
		ZIndex = 13
	})
	addListLayout(list, 10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

	section.Root = root
	section.List = list

	table.insert(self.Sections, section)
	return section
end

--// ---------- Controls builders ----------
local function makeRow(section: any, height: number)
	local row = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,height),
		Parent = section.List
	})
	return row
end

local function makeButtonBase(ui: any, parent: Instance, text: string)
	local btn = Create("TextButton", {
		BackgroundColor3 = ui.Theme.Background,
		BackgroundTransparency = ui.Options.Transparency,
		Size = UDim2.new(1,0,0,36),
		Text = "",
		AutoButtonColor = false,
		Parent = parent
	})
	addCorner(btn, 10)
	local st = addStroke(btn, darken(ui.Theme.Stroke, 0.05), 0.55, 1)

	local lbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = ui.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0,12,0,0),
		Size = UDim2.new(1,-24,1,0),
		Parent = btn
	})

	return btn, lbl, st
end

-- Label / paragraph / divider
function Section:AddLabel(text: string)
	local t = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(text),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = self.UI.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1,0,0,0),
		Parent = self.List
	})
	table.insert(self.Window._registry.SubText, t)
	return t
end

function Section:AddParagraph(title: string, body: string)
	local wrap = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.List
	})

	local t = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(title),
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,20),
		Parent = wrap
	})
	local b = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(body),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = self.UI.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0,0,0,22),
		Size = UDim2.new(1,0,0,0),
		Parent = wrap
	})
	table.insert(self.Window._registry.Text, t)
	table.insert(self.Window._registry.SubText, b)
	return wrap
end

function Section:AddDivider()
	local d = Create("Frame", {
		BackgroundColor3 = darken(self.UI.Theme.Stroke, 0.05),
		BackgroundTransparency = 0.65,
		Size = UDim2.new(1,0,0,1),
		Parent = self.List
	})
	return d
end

-- Button
function Section:AddButton(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Button")
	local cb = opt.Callback

	local btn, lbl, st = makeButtonBase(self.UI, self.List, text)
	table.insert(self.Window._registry.Strokes, st)
	table.insert(self.Window._registry.Text, lbl)

	btn.MouseEnter:Connect(function()
		self.UI:_playSound("Hover")
		tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = math.max(0, self.UI.Options.Transparency - 0.06)
		})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = self.UI.Options.Transparency
		})
	end)

	btn.MouseButton1Down:Connect(function()
		self.UI:_playSound("Click")
		tween(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1,0,0,34)
		})
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1,0,0,36)
		})
	end)

	btn.MouseButton1Click:Connect(function()
		safeCall(cb)
	end)

	return {
		Instance = btn
	}
end

-- Toggle
function Section:AddToggle(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Toggle")
	local flag = tostring(opt.Flag or ("toggle_"..text))
	local default = (opt.Default == true)
	local cb = opt.Callback

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or default

	local row = makeRow(self, 40)
	local btn = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Text = "",
		AutoButtonColor = false,
		Parent = row
	})

	local name = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0,0,0,0),
		Size = UDim2.new(1,-90,1,0),
		Parent = row
	})

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,0,0.5,0),
		Size = UDim2.fromOffset(56, 24),
		BackgroundColor3 = darken(self.UI.Theme.Background, 0.02),
		BackgroundTransparency = self.UI.Options.Transparency,
		Parent = row
	})
	addCorner(track, 99)
	local st = addStroke(track, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)

	local knob = Create("Frame", {
		Size = UDim2.fromOffset(18,18),
		Position = UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = self.UI.Theme.SubText,
		Parent = track
	})
	addCorner(knob, 99)

	local function apply(v: boolean, instant: boolean?)
		local on = v == true
		self.UI.Flags[flag] = on
		local tinfo = TweenInfo.new(instant and 0 or 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		tween(knob, tinfo, {
			Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
			BackgroundColor3 = on and self.UI.Theme.Accent or self.UI.Theme.SubText
		})
		tween(track, tinfo, {
			BackgroundColor3 = on and darken(self.UI.Theme.Accent, 0.55) or darken(self.UI.Theme.Background, 0.02)
		})
		safeCall(cb, on)
	end

	btn.MouseEnter:Connect(function() self.UI:_playSound("Hover") end)
	btn.MouseButton1Click:Connect(function()
		self.UI:_playSound("Click")
		apply(not self.UI.Flags[flag], false)
	end)

	table.insert(self.Window._registry.Text, name)
	table.insert(self.Window._registry.Strokes, st)

	local control = {}
	function control:SetValue(v, silent)
		self.UI.Flags[flag] = v == true
		apply(self.UI.Flags[flag], true)
		if silent then return end
	end
	function control:GetValue()
		return self.UI.Flags[flag]
	end
	control.Flag = flag

	self.UI.Controls[flag] = control
	apply(self.UI.Flags[flag], true)

	return control
end

-- Slider
function Section:AddSlider(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Slider")
	local flag = tostring(opt.Flag or ("slider_"..text))
	local min = tonumber(opt.Min or 0) or 0
	local max = tonumber(opt.Max or 100) or 100
	local step = tonumber(opt.Step or 1) or 1
	local default = tonumber(opt.Default or min) or min
	local cb = opt.Callback

	local function snap(x: number): number
		local v = math.clamp(x, min, max)
		local s = step
		if s > 0 then
			v = math.floor((v - min)/s + 0.5) * s + min
		end
		return math.clamp(v, min, max)
	end

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or snap(default)

	local root = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,50),
		Parent = self.List
	})

	local name = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,-70,0,18),
		Parent = root
	})
	table.insert(self.Window._registry.Text, name)

	local valueLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(self.UI.Flags[flag]),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self.UI.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,0,0,0),
		Size = UDim2.new(0,60,0,18),
		Parent = root
	})
	table.insert(self.Window._registry.SubText, valueLbl)

	local track = Create("Frame", {
		BackgroundColor3 = darken(self.UI.Theme.Background, 0.02),
		BackgroundTransparency = self.UI.Options.Transparency,
		Position = UDim2.new(0,0,0,26),
		Size = UDim2.new(1,0,0,16),
		Parent = root
	})
	addCorner(track, 99)
	local st = addStroke(track, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)
	table.insert(self.Window._registry.Strokes, st)

	local fill = Create("Frame", {
		BackgroundColor3 = self.UI.Theme.Accent,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(0,0,1,0),
		Parent = track
	})
	addCorner(fill, 99)
	table.insert(self.Window._registry.Accent, fill)

	local knob = Create("Frame", {
		Size = UDim2.fromOffset(14,14),
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(0,0,0.5,0),
		BackgroundColor3 = lighten(self.UI.Theme.Text, -0.15),
		Parent = track
	})
	addCorner(knob, 99)

	local dragging = false

	local function setFromAlpha(a: number, silent: boolean?)
		local v = snap(lerp(min, max, a))
		self.UI.Flags[flag] = v
		valueLbl.Text = tostring(v)

		local aa = (v - min) / (max - min)
		aa = clamp01(aa)

		tween(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(aa,0,1,0)})
		tween(knob, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(aa,0,0.5,0)})

		if not silent then
			safeCall(cb, v)
		end
	end

	local function setFromX(x: number, silent: boolean?)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setFromAlpha(rel, silent)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			self.UI:_playSound("Click")
			setFromX(input.Position.X, false)
		end
	end)
	track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			setFromX(input.Position.X, true)
		end
	end)

	local control = {}
	function control:SetValue(v, silent)
		local vv = snap(tonumber(v) or min)
		local aa = (vv - min) / (max - min)
		setFromAlpha(aa, silent == true)
	end
	function control:GetValue()
		return self.UI.Flags[flag]
	end
	control.Flag = flag
	self.UI.Controls[flag] = control

	-- init
	control:SetValue(self.UI.Flags[flag], true)
	return control
end

-- Dropdown (single select)
function Section:AddDropdown(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Dropdown")
	local flag = tostring(opt.Flag or ("dropdown_"..text))
	local items = opt.Items or {}
	local default = opt.Default
	local cb = opt.Callback

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or default

	local root = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,36),
		Parent = self.List
	})

	local btn, lbl, st = makeButtonBase(self.UI, root, text)
	btn.Size = UDim2.new(1,0,1,0)
	table.insert(self.Window._registry.Text, lbl)
	table.insert(self.Window._registry.Strokes, st)

	local valueLbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(self.UI.Flags[flag] or "None"),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = self.UI.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-28,0,0),
		Size = UDim2.new(0,170,1,0),
		Parent = btn
	})
	table.insert(self.Window._registry.SubText, valueLbl)

	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "▾",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = self.UI.Theme.SubText,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-10,0,0),
		Size = UDim2.new(0,18,1,0),
		Parent = btn
	})
	table.insert(self.Window._registry.SubText, arrow)

	local open = false
	local listFrame = Create("Frame", {
		BackgroundColor3 = self.UI.Theme.Background,
		BackgroundTransparency = self.UI.Options.Transparency,
		Position = UDim2.new(0,0,1,8),
		Size = UDim2.new(1,0,0,0),
		ClipsDescendants = true,
		Visible = false,
		Parent = root
	})
	addCorner(listFrame, 10)
	local lstStroke = addStroke(listFrame, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)
	table.insert(self.Window._registry.Surfaces, listFrame)
	table.insert(self.Window._registry.Strokes, lstStroke)

	addPadding(listFrame, 8)
	local holder = Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=listFrame})
	addListLayout(holder, 6, Enum.FillDirection.Vertical)

	local function rebuild()
		holder:ClearAllChildren()
		addListLayout(holder, 6, Enum.FillDirection.Vertical)

		for _,it in ipairs(items) do
			local b = Create("TextButton", {
				BackgroundColor3 = self.UI.Theme.Surface,
				BackgroundTransparency = self.UI.Options.Transparency,
				Size = UDim2.new(1,0,0,30),
				Text = "",
				AutoButtonColor = false,
				Parent = holder
			})
			addCorner(b, 9)
			addStroke(b, darken(self.UI.Theme.Stroke, 0.05), 0.6, 1)

			local t = Create("TextLabel", {
				BackgroundTransparency = 1,
				Text = tostring(it),
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = self.UI.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0,10,0,0),
				Size = UDim2.new(1,-20,1,0),
				Parent = b
			})

			b.MouseEnter:Connect(function()
				self.UI:_playSound("Hover")
				tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = math.max(0, self.UI.Options.Transparency - 0.05)})
			end)
			b.MouseLeave:Connect(function()
				tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = self.UI.Options.Transparency})
			end)

			b.MouseButton1Click:Connect(function()
				self.UI:_playSound("Click")
				self.UI.Flags[flag] = it
				valueLbl.Text = tostring(it)
				safeCall(cb, it)
				open = false
				listFrame.Visible = true
				tween(listFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1,0,0,0)})
				task.delay(0.17, function() listFrame.Visible = false end)
				arrow.Text = "▾"
			end)
		end
	end

	rebuild()

	local function setOpen(on: boolean)
		open = on
		listFrame.Visible = true
		arrow.Text = on and "▴" or "▾"
		if on then
			-- compute height
			local n = #items
			local h = math.min(220, 8 + n * 36)
			listFrame.Size = UDim2.new(1,0,0,0)
			tween(listFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,h)})
		else
			tween(listFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1,0,0,0)})
			task.delay(0.17, function() if not open then listFrame.Visible = false end end)
		end
	end

	btn.MouseButton1Click:Connect(function()
		self.UI:_playSound("Click")
		setOpen(not open)
	end)

	local control = {}
	function control:SetValue(v, silent)
		self.UI.Flags[flag] = v
		valueLbl.Text = tostring(v or "None")
		if not silent then safeCall(cb, v) end
	end
	function control:GetValue()
		return self.UI.Flags[flag]
	end
	function control:SetItems(newItems: {any})
		items = newItems or {}
		rebuild()
	end
	control.Flag = flag
	self.UI.Controls[flag] = control

	control:SetValue(self.UI.Flags[flag], true)
	return control
end

-- Textbox
function Section:AddTextbox(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Textbox")
	local flag = tostring(opt.Flag or ("textbox_"..text))
	local placeholder = tostring(opt.Placeholder or "")
	local default = tostring(opt.Default or "")
	local multiLine = opt.MultiLine == true
	local cb = opt.Callback

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or default

	local wrap = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0, multiLine and 90 or 58),
		Parent = self.List
	})

	local name = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,18),
		Parent = wrap
	})
	table.insert(self.Window._registry.Text, name)

	local box = Create("TextBox", {
		BackgroundColor3 = self.UI.Theme.Background,
		BackgroundTransparency = self.UI.Options.Transparency,
		Text = tostring(self.UI.Flags[flag] or ""),
		PlaceholderText = placeholder,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		PlaceholderColor3 = self.UI.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClearTextOnFocus = false,
		MultiLine = multiLine,
		Position = UDim2.new(0,0,0,26),
		Size = UDim2.new(1,0,1,-26),
		Parent = wrap
	})
	addCorner(box, 10)
	local st = addStroke(box, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)

	table.insert(self.Window._registry.Surfaces, box)
	table.insert(self.Window._registry.Strokes, st)

	box.Focused:Connect(function()
		self.UI:_playSound("Click")
		tween(st, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.15,
			Color = self.UI.Theme.Accent
		})
	end)
	box.FocusLost:Connect(function()
		tween(st, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.55,
			Color = darken(self.UI.Theme.Stroke, 0.05)
		})
		self.UI.Flags[flag] = box.Text
		safeCall(cb, box.Text)
	end)

	local control = {}
	function control:SetValue(v, silent)
		local s = tostring(v or "")
		self.UI.Flags[flag] = s
		box.Text = s
		if not silent then safeCall(cb, s) end
	end
	function control:GetValue()
		return self.UI.Flags[flag]
	end
	control.Flag = flag
	self.UI.Controls[flag] = control
	return control
end

-- Keybind
function Section:AddKeybind(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Keybind")
	local flag = tostring(opt.Flag or ("keybind_"..text))
	local defaultKey = opt.Default or Enum.KeyCode.F
	local cb = opt.Callback

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or defaultKey.Name

	local row = makeRow(self, 40)
	local name = Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = self.UI.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,-130,1,0),
		Parent = row
	})
	table.insert(self.Window._registry.Text, name)

	local bindBtn = Create("TextButton", {
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,0,0.5,0),
		Size = UDim2.fromOffset(110, 30),
		BackgroundColor3 = self.UI.Theme.Background,
		BackgroundTransparency = self.UI.Options.Transparency,
		Text = tostring(self.UI.Flags[flag]),
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = self.UI.Theme.Text,
		AutoButtonColor = false,
		Parent = row
	})
	addCorner(bindBtn, 10)
	local st = addStroke(bindBtn, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)
	table.insert(self.Window._registry.Surfaces, bindBtn)
	table.insert(self.Window._registry.Strokes, st)

	local listening = false
	bindBtn.MouseButton1Click:Connect(function()
		self.UI:_playSound("Click")
		listening = true
		bindBtn.Text = "Press key..."
		tween(st, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = self.UI.Theme.Accent, Transparency = 0.15})
	end)

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if listening then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				self.UI.Flags[flag] = input.KeyCode.Name
				bindBtn.Text = input.KeyCode.Name
				tween(st, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = darken(self.UI.Theme.Stroke, 0.05), Transparency = 0.55})
				safeCall(cb, input.KeyCode)
			end
		else
			-- fire bind
			local current = self.UI.Flags[flag]
			if current and input.KeyCode.Name == current then
				safeCall(cb, input.KeyCode)
			end
		end
	end)

	local control = {}
	function control:SetValue(v, silent)
		local key = v
		if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
			key = v.Name
		end
		self.UI.Flags[flag] = tostring(key)
		bindBtn.Text = tostring(key)
		if not silent then safeCall(cb, v) end
	end
	function control:GetValue()
		return self.UI.Flags[flag]
	end
	control.Flag = flag
	self.UI.Controls[flag] = control
	return control
end

-- ColorPicker (simple, with palette + HSV slider-ish)
function Section:AddColorPicker(opt: Dict)
	opt = opt or {}
	local text = tostring(opt.Text or "Color")
	local flag = tostring(opt.Flag or ("color_"..text))
	local default = opt.Default or self.UI.Theme.Accent
	local cb = opt.Callback

	self.UI.Flags[flag] = self.UI.Flags[flag] ~= nil and self.UI.Flags[flag] or {default.R, default.G, default.B}

	local root = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,36),
		Parent = self.List
	})

	local btn, lbl, st = makeButtonBase(self.UI, root, text)
	btn.Size = UDim2.new(1,0,1,0)
	table.insert(self.Window._registry.Text, lbl)
	table.insert(self.Window._registry.Strokes, st)

	local swatch = Create("Frame", {
		AnchorPoint = Vector2.new(1,0.5),
		Position = UDim2.new(1,-10,0.5,0),
		Size = UDim2.fromOffset(22,22),
		BackgroundColor3 = default,
		Parent = btn
	})
	addCorner(swatch, 8)
	addStroke(swatch, darken(self.UI.Theme.Stroke, 0.05), 0.4, 1)

	local open = false
	local panel = Create("Frame", {
		BackgroundColor3 = self.UI.Theme.Background,
		BackgroundTransparency = self.UI.Options.Transparency,
		Position = UDim2.new(0,0,1,8),
		Size = UDim2.new(1,0,0,0),
		Visible = false,
		ClipsDescendants = true,
		Parent = root
	})
	addCorner(panel, 12)
	addStroke(panel, darken(self.UI.Theme.Stroke, 0.05), 0.55, 1)
	addPadding(panel, 10)

	local palette = {
		Color3.fromRGB(255,120,140),
		Color3.fromRGB(255,180,120),
		Color3.fromRGB(255,240,120),
		Color3.fromRGB(140,255,170),
		Color3.fromRGB(120,170,255),
		Color3.fromRGB(160,120,255),
		Color3.fromRGB(255,255,255),
		Color3.fromRGB(180,180,190),
		Color3.fromRGB(40,40,45)
	}

	local grid = Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,72), Parent=panel})
	local gl = Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(46, 30),
		CellPadding = UDim2.fromOffset(8,8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid
	})

	local function currentColor(): Color3
		local v = self.UI.Flags[flag]
		if typeof(v) == "table" and #v >= 3 then
			return Color3.new(v[1], v[2], v[3])
		end
		return default
	end

	local function setColor(c: Color3, silent: boolean?)
		self.UI.Flags[flag] = {c.R, c.G, c.B}
		swatch.BackgroundColor3 = c
		if not silent then safeCall(cb, c) end
	end

	for _,c in ipairs(palette) do
		local cell = Create("TextButton", {
			BackgroundColor3 = c,
			BackgroundTransparency = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = grid
		})
		addCorner(cell, 10)
		addStroke(cell, darken(self.UI.Theme.Stroke, 0.05), 0.45, 1)
		cell.MouseButton1Click:Connect(function()
			self.UI:_playSound("Click")
			setColor(c, false)
		end)
	end

	local function setOpen(on: boolean)
		open = on
		panel.Visible = true
		if on then
			panel.Size = UDim2.new(1,0,0,0)
			tween(panel, TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,112)})
		else
			tween(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1,0,0,0)})
			task.delay(0.17, function() if not open then panel.Visible = false end end)
		end
	end

	btn.MouseButton1Click:Connect(function()
		self.UI:_playSound("Click")
		setOpen(not open)
	end)

	local control = {}
	function control:SetValue(v, silent)
		local c = v
		if typeof(v) == "table" and #v >= 3 then
			c = Color3.new(v[1], v[2], v[3])
		end
		if typeof(c) == "Color3" then
			setColor(c, silent == true)
		end
	end
	function control:GetValue()
		return currentColor()
	end
	control.Flag = flag
	self.UI.Controls[flag] = control

	control:SetValue(currentColor(), true)
	return control
end

return ZenithUI
