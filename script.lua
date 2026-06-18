-- Vape-Inspired UI Library for Roblox Luau
-- Fully modular, cross-platform, with dynamic theming and built-in settings

local Library = {}
Library.__index = Library

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- Global State
local GlobalSettings = {
	AccentColor = Color3.fromHex("#00D2FF"),
	ColorMode = "Static",
	ColorSpeed = 1,
	UITransparency = 0,
	ToggleKeybind = Enum.KeyCode.RightShift,
	HiddenKeybinds = false,
	PerformanceWatermark = false,
	ArrayListEnabled = false,
	MobileButtonEnabled = true,
	Categories = {},
	ActiveModules = {},
	ConfigFolder = "VapeUIConfigs"
}

local ColorUpdateThread = nil
local UptimeStart = tick()
local ScreenGui = nil
local MobileToggleButton = nil

-- Utility Functions
local function CreateInstance(className, properties)
	local instance = Instance.new(className)
	for prop, value in pairs(properties) do
		if prop ~= "Parent" then
			instance[prop] = value
		end
	end
	if properties.Parent then
		instance.Parent = properties.Parent
	end
	return instance
end

local function GetCurrentAccentColor()
	if GlobalSettings.ColorMode == "Static" then
		return GlobalSettings.AccentColor
	elseif GlobalSettings.ColorMode == "Breathing" then
		local breath = (math.sin(tick() * GlobalSettings.ColorSpeed) + 1) / 2
		local h, s, v = GlobalSettings.AccentColor:ToHSV()
		return Color3.fromHSV(h, s, 0.5 + (v * 0.5 * breath))
	elseif GlobalSettings.ColorMode == "Rainbow" then
		local hue = (tick() * GlobalSettings.ColorSpeed * 0.1) % 1
		return Color3.fromHSV(hue, 1, 1)
	elseif GlobalSettings.ColorMode == "Gradient" then
		local hue = (tick() * GlobalSettings.ColorSpeed * 0.1) % 1
		return Color3.fromHSV(hue, 0.8, 1)
	end
	return GlobalSettings.AccentColor
end

local function UpdateAllAccents()
	if not ScreenGui then return end
	local currentColor = GetCurrentAccentColor()
	
	for _, category in pairs(GlobalSettings.Categories) do
		if category.TitleBar and category.TitleBar:FindFirstChild("Accent") then
			category.TitleBar.Accent.BackgroundColor3 = currentColor
		end
		if category.Border then
			category.Border.Color = currentColor
		end
		
		if category.Modules then
			for _, module in pairs(category.Modules) do
				if module.AccentElements then
					for _, element in pairs(module.AccentElements) do
						if element:IsA("Frame") or element:IsA("TextButton") then
							element.BackgroundColor3 = currentColor
						elseif element:IsA("UIStroke") then
							element.Color = currentColor
						elseif element:IsA("TextLabel") or element:IsA("TextBox") then
							element.TextColor3 = currentColor
						end
					end
				end
			end
		end
	end
	
	if MobileToggleButton then
		MobileToggleButton.BackgroundColor3 = currentColor
	end
end

local function StartColorUpdateLoop()
	if ColorUpdateThread then
		task.cancel(ColorUpdateThread)
	end
	
	ColorUpdateThread = task.spawn(function()
		while ScreenGui and ScreenGui.Parent do
			UpdateAllAccents()
			task.wait(1/60)
		end
	end)
end

local function MakeDraggable(frame, dragHandle)
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	
	local function update(input)
		local delta = input.Position - dragStart
		local newPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		
		TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = newPosition
		}):Play()
	end
	
	dragHandle.InputBegan:Connect(function(input)
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
	
	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end)
end

local function SaveConfig(configName)
	local config = {
		Settings = {
			AccentColor = {GlobalSettings.AccentColor.R, GlobalSettings.AccentColor.G, GlobalSettings.AccentColor.B},
			ColorMode = GlobalSettings.ColorMode,
			ColorSpeed = GlobalSettings.ColorSpeed,
			UITransparency = GlobalSettings.UITransparency,
			ToggleKeybind = GlobalSettings.ToggleKeybind.Name,
			HiddenKeybinds = GlobalSettings.HiddenKeybinds,
			PerformanceWatermark = GlobalSettings.PerformanceWatermark,
			ArrayListEnabled = GlobalSettings.ArrayListEnabled,
			MobileButtonEnabled = GlobalSettings.MobileButtonEnabled
		},
		Modules = {}
	}
	
	for _, category in pairs(GlobalSettings.Categories) do
		if category.Modules then
			for moduleName, module in pairs(category.Modules) do
				config.Modules[moduleName] = {
					Enabled = module.Enabled or false,
					Keybind = module.Keybind and module.Keybind.Name or "None",
					Settings = module.SavedSettings or {}
				}
			end
		end
	end
	
	local success, err = pcall(function()
		if not isfolder(GlobalSettings.ConfigFolder) then
			makefolder(GlobalSettings.ConfigFolder)
		end
		writefile(GlobalSettings.ConfigFolder .. "/" .. configName .. ".json", HttpService:JSONEncode(config))
	end)
	
	return success
end

local function LoadConfig(configName)
	local success, result = pcall(function()
		local data = readfile(GlobalSettings.ConfigFolder .. "/" .. configName .. ".json")
		return HttpService:JSONDecode(data)
	end)
	
	if success and result then
		if result.Settings then
			local settings = result.Settings
			if settings.AccentColor then
				GlobalSettings.AccentColor = Color3.new(settings.AccentColor[1], settings.AccentColor[2], settings.AccentColor[3])
			end
			GlobalSettings.ColorMode = settings.ColorMode or "Static"
			GlobalSettings.ColorSpeed = settings.ColorSpeed or 1
			GlobalSettings.UITransparency = settings.UITransparency or 0
			if settings.ToggleKeybind then
				GlobalSettings.ToggleKeybind = Enum.KeyCode[settings.ToggleKeybind] or Enum.KeyCode.RightShift
			end
			GlobalSettings.HiddenKeybinds = settings.HiddenKeybinds or false
			GlobalSettings.PerformanceWatermark = settings.PerformanceWatermark or false
			GlobalSettings.ArrayListEnabled = settings.ArrayListEnabled or false
			GlobalSettings.MobileButtonEnabled = settings.MobileButtonEnabled or true
		end
		
		if result.Modules then
			for moduleName, moduleData in pairs(result.Modules) do
				for _, category in pairs(GlobalSettings.Categories) do
					if category.Modules and category.Modules[moduleName] then
						local module = category.Modules[moduleName]
						if moduleData.Enabled and module.Toggle then
							pcall(function() module:Toggle() end)
						end
						if moduleData.Keybind and moduleData.Keybind ~= "None" then
							module.Keybind = Enum.KeyCode[moduleData.Keybind]
						end
						if moduleData.Settings then
							module.SavedSettings = moduleData.Settings
						end
					end
				end
			end
		end
		
		return true
	end
	
	return false
end

local function GetConfigList()
	local configs = {}
	local success = pcall(function()
		if isfolder(GlobalSettings.ConfigFolder) then
			for _, file in pairs(listfiles(GlobalSettings.ConfigFolder)) do
				local name = file:match("([^/\\]+)%.json$")
				if name then
					table.insert(configs, name)
				end
			end
		end
	end)
	return configs
end

-- Category Object
local Category = {}
Category.__index = Category

function Category.new(info)
	local self = setmetatable({}, Category)
	
	self.Name = info.Name or "Category"
	self.Position = info.Position or UDim2.new(0, 100, 0, 100)
	self.Modules = {}
	self.Collapsed = false
	self.AccentElements = {}
	
	self.Frame = CreateInstance("Frame", {
		Name = self.Name,
		Position = self.Position,
		Size = UDim2.new(0, 200, 0, 30),
		BackgroundColor3 = Color3.fromHex("#101010"),
		BorderSizePixel = 0,
		Parent = ScreenGui
	})
	
	self.Border = CreateInstance("UIStroke", {
		Color = GetCurrentAccentColor(),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = self.Frame
	})
	table.insert(self.AccentElements, self.Border)
	
	self.TitleBar = CreateInstance("TextButton", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromHex("#0A0A0A"),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = self.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		Parent = self.Frame
	})
	
	self.Accent = CreateInstance("Frame", {
		Name = "Accent",
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = GetCurrentAccentColor(),
		BorderSizePixel = 0,
		Parent = self.TitleBar
	})
	table.insert(self.AccentElements, self.Accent)
	
	self.ContentFrame = CreateInstance("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 1, -30),
		BackgroundTransparency = 1,
		Parent = self.Frame
	})
	
	self.ListLayout = CreateInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = self.ContentFrame
	})
	
	MakeDraggable(self.Frame, self.TitleBar)
	
	self.TitleBar.MouseButton1Click:Connect(function()
		self:ToggleCollapse()
	end)
	
	self.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not self.Collapsed then
			self.Frame.Size = UDim2.new(0, 200, 0, 30 + self.ListLayout.AbsoluteContentSize.Y)
		end
	end)
	
	table.insert(GlobalSettings.Categories, self)
	
	return self
end

function Category:ToggleCollapse()
	self.Collapsed = not self.Collapsed
	
	if self.Collapsed then
		TweenService:Create(self.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 200, 0, 30)
		}):Play()
		self.ContentFrame.Visible = false
	else
		self.ContentFrame.Visible = true
		TweenService:Create(self.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 200, 0, 30 + self.ListLayout.AbsoluteContentSize.Y)
		}):Play()
	end
end

function Category:CreateModule(info)
	local module = {
		Name = info.Name or "Module",
		Description = info.Description or "",
		Enabled = false,
		Keybind = info.Keybind or nil,
		Callback = info.Callback or function() end,
		AccentElements = {},
		SavedSettings = {},
		Components = {},
		Expanded = false
	}
	
	module.Frame = CreateInstance("Frame", {
		Name = module.Name,
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundColor3 = Color3.fromHex("#0F0F0F"),
		BorderSizePixel = 0,
		Parent = self.ContentFrame
	})
	
	module.Border = CreateInstance("UIStroke", {
		Color = Color3.fromHex("#1A1A1A"),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = module.Frame
	})
	
	module.Button = CreateInstance("TextButton", {
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = module.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = module.Frame
	})
	
	CreateInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		Parent = module.Button
	})
	
	module.Indicator = CreateInstance("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = GetCurrentAccentColor(),
		BorderSizePixel = 0,
		Visible = false,
		Parent = module.Frame
	})
	table.insert(module.AccentElements, module.Indicator)
	
	module.ComponentContainer = CreateInstance("Frame", {
		Name = "Components",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundColor3 = Color3.fromHex("#0A0A0A"),
		BorderSizePixel = 0,
		Visible = false,
		Parent = module.Frame
	})
	
	module.ComponentList = CreateInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = module.ComponentContainer
	})
	
	module.Toggle = function()
		module.Enabled = not module.Enabled
		module.Indicator.Visible = module.Enabled
		
		if module.Enabled then
			module.Button.TextColor3 = GetCurrentAccentColor()
			table.insert(module.AccentElements, module.Button)
			table.insert(GlobalSettings.ActiveModules, module)
		else
			module.Button.TextColor3 = Color3.new(1, 1, 1)
			for i, elem in pairs(module.AccentElements) do
				if elem == module.Button then
					table.remove(module.AccentElements, i)
					break
				end
			end
			for i, mod in pairs(GlobalSettings.ActiveModules) do
				if mod == module then
					table.remove(GlobalSettings.ActiveModules, i)
					break
				end
			end
		end
		
		pcall(module.Callback, module.Enabled)
	end
	
	module.Button.MouseButton1Click:Connect(function()
		module.Toggle()
	end)
	
	module.Button.MouseButton2Click:Connect(function()
		module.Expanded = not module.Expanded
		
		if module.Expanded and #module.Components > 0 then
			module.ComponentContainer.Visible = true
			local contentHeight = module.ComponentList.AbsoluteContentSize.Y
			
			TweenService:Create(module.ComponentContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 0, contentHeight)
			}):Play()
			
			TweenService:Create(module.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 0, 35 + contentHeight)
			}):Play()
		else
			TweenService:Create(module.ComponentContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 0, 0)
			}):Play()
			
			TweenService:Create(module.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 0, 35)
			}):Play()
			
			task.delay(0.2, function()
				module.ComponentContainer.Visible = false
			end)
		end
	end)
	
	module.ComponentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if module.Expanded then
			local contentHeight = module.ComponentList.AbsoluteContentSize.Y
			module.ComponentContainer.Size = UDim2.new(1, 0, 0, contentHeight)
			module.Frame.Size = UDim2.new(1, 0, 0, 35 + contentHeight)
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed and not GlobalSettings.HiddenKeybinds then return end
		if not ScreenGui.Enabled and not GlobalSettings.HiddenKeybinds then return end
		
		if module.Keybind and input.KeyCode == module.Keybind then
			module.Toggle()
		end
	end)
	
	module.CreateSlider = function(sliderInfo)
		local slider = {
			Name = sliderInfo.Name or "Slider",
			Min = sliderInfo.Min or 0,
			Max = sliderInfo.Max or 100,
			Default = sliderInfo.Default or 50,
			Precise = sliderInfo.Precise or false,
			Callback = sliderInfo.Callback or function() end,
			Value = sliderInfo.Default or 50
		}
		
		slider.Frame = CreateInstance("Frame", {
			Name = slider.Name,
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		slider.Label = CreateInstance("TextLabel", {
			Size = UDim2.new(1, -10, 0, 15),
			Position = UDim2.new(0, 5, 0, 3),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = slider.Name .. ": " .. tostring(slider.Value),
			TextColor3 = Color3.new(0.8, 0.8, 0.8),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = slider.Frame
		})
		
		slider.Track = CreateInstance("Frame", {
			Size = UDim2.new(1, -10, 0, 4),
			Position = UDim2.new(0, 5, 0, 25),
			BackgroundColor3 = Color3.fromHex("#1A1A1A"),
			BorderSizePixel = 0,
			Parent = slider.Frame
		})
		
		slider.Fill = CreateInstance("Frame", {
			Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0),
			BackgroundColor3 = GetCurrentAccentColor(),
			BorderSizePixel = 0,
			Parent = slider.Track
		})
		table.insert(module.AccentElements, slider.Fill)
		
		slider.Grabber = CreateInstance("Frame", {
			Size = UDim2.new(0, 8, 0, 12),
			Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -4, 0.5, -6),
			BackgroundColor3 = GetCurrentAccentColor(),
			BorderSizePixel = 0,
			Parent = slider.Track
		})
		table.insert(module.AccentElements, slider.Grabber)
		
		local dragging = false
		
		local function update(input)
			local relativeX = math.clamp((input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X, 0, 1)
			local value = slider.Min + (relativeX * (slider.Max - slider.Min))
			
			if not slider.Precise then
				value = math.floor(value + 0.5)
			else
				value = math.floor(value * 100) / 100
			end
			
			slider.Value = value
			slider.Label.Text = slider.Name .. ": " .. tostring(slider.Value)
			
			TweenService:Create(slider.Fill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				Size = UDim2.new(relativeX, 0, 1, 0)
			}):Play()
			
			TweenService:Create(slider.Grabber, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				Position = UDim2.new(relativeX, -4, 0.5, -6)
			}):Play()
			
			module.SavedSettings[slider.Name] = slider.Value
			pcall(slider.Callback, slider.Value)
		end
		
		slider.Track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input)
			end
		end)
		
		slider.Track.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end)
		
		table.insert(module.Components, slider)
		return slider
	end
	
	module.CreateColorPicker = function(pickerInfo)
		local picker = {
			Name = pickerInfo.Name or "Color",
			Default = pickerInfo.Default or Color3.new(1, 1, 1),
			Callback = pickerInfo.Callback or function() end,
			Value = pickerInfo.Default or Color3.new(1, 1, 1),
			Expanded = false
		}
		
		picker.Frame = CreateInstance("Frame", {
			Name = picker.Name,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		picker.Button = CreateInstance("TextButton", {
			Size = UDim2.new(1, -35, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = picker.Name,
			TextColor3 = Color3.new(0.8, 0.8, 0.8),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = picker.Frame
		})
		
		picker.Preview = CreateInstance("Frame", {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(1, -25, 0.5, -10),
			BackgroundColor3 = picker.Value,
			BorderSizePixel = 0,
			Parent = picker.Frame
		})
		
		CreateInstance("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 1,
			Parent = picker.Preview
		})
		
		picker.ExpandedFrame = CreateInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 30),
			BackgroundColor3 = Color3.fromHex("#0A0A0A"),
			BorderSizePixel = 0,
			Visible = false,
			Parent = picker.Frame
		})
		
		picker.Saturation = CreateInstance("ImageButton", {
			Size = UDim2.new(1, -10, 0, 100),
			Position = UDim2.new(0, 5, 0, 5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Image = "rbxassetid://4155801252",
			Parent = picker.ExpandedFrame
		})
		
		picker.Hue = CreateInstance("ImageButton", {
			Size = UDim2.new(1, -10, 0, 15),
			Position = UDim2.new(0, 5, 0, 110),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Image = "rbxassetid://4155838169",
			Parent = picker.ExpandedFrame
		})
		
		local h, s, v = picker.Value:ToHSV()
		
		local function updateColor()
			picker.Value = Color3.fromHSV(h, s, v)
			picker.Preview.BackgroundColor3 = picker.Value
			picker.Saturation.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			module.SavedSettings[picker.Name] = {picker.Value.R, picker.Value.G, picker.Value.B}
			pcall(picker.Callback, picker.Value)
		end
		
		local satDragging = false
		local hueDragging = false
		
		picker.Saturation.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				satDragging = true
			end
		end)
		
		picker.Saturation.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				satDragging = false
			end
		end)
		
		picker.Hue.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hueDragging = true
			end
		end)
		
		picker.Hue.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hueDragging = false
			end
		end)
		
		UserInputService.InputChanged:Connect(function(input)
			if satDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relX = math.clamp((input.Position.X - picker.Saturation.AbsolutePosition.X) / picker.Saturation.AbsoluteSize.X, 0, 1)
				local relY = math.clamp((input.Position.Y - picker.Saturation.AbsolutePosition.Y) / picker.Saturation.AbsoluteSize.Y, 0, 1)
				s = relX
				v = 1 - relY
				updateColor()
			elseif hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relX = math.clamp((input.Position.X - picker.Hue.AbsolutePosition.X) / picker.Hue.AbsoluteSize.X, 0, 1)
				h = relX
				updateColor()
			end
		end)
		
		picker.Button.MouseButton1Click:Connect(function()
			picker.Expanded = not picker.Expanded
			
			if picker.Expanded then
				picker.ExpandedFrame.Visible = true
				TweenService:Create(picker.ExpandedFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 130)
				}):Play()
				TweenService:Create(picker.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 160)
				}):Play()
			else
				TweenService:Create(picker.ExpandedFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 0)
				}):Play()
				TweenService:Create(picker.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 30)
				}):Play()
				task.delay(0.2, function()
					picker.ExpandedFrame.Visible = false
				end)
			end
		end)
		
		table.insert(module.Components, picker)
		return picker
	end
	
	module.CreateDropdown = function(dropdownInfo)
		local dropdown = {
			Name = dropdownInfo.Name or "Dropdown",
			Options = dropdownInfo.Options or {},
			Default = dropdownInfo.Default or (dropdownInfo.Options and dropdownInfo.Options[1]) or "None",
			Callback = dropdownInfo.Callback or function() end,
			Value = dropdownInfo.Default or (dropdownInfo.Options and dropdownInfo.Options[1]) or "None",
			Expanded = false
		}
		
		dropdown.Frame = CreateInstance("Frame", {
			Name = dropdown.Name,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		dropdown.Button = CreateInstance("TextButton", {
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = dropdown.Name .. ": " .. dropdown.Value,
			TextColor3 = Color3.new(0.8, 0.8, 0.8),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dropdown.Frame
		})
		
		dropdown.OptionsFrame = CreateInstance("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 30),
			BackgroundColor3 = Color3.fromHex("#0A0A0A"),
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			Visible = false,
			Parent = dropdown.Frame
		})
		
		dropdown.OptionsList = CreateInstance("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			Parent = dropdown.OptionsFrame
		})
		
		for _, option in ipairs(dropdown.Options) do
			local optionButton = CreateInstance("TextButton", {
				Size = UDim2.new(1, 0, 0, 25),
				BackgroundColor3 = Color3.fromHex("#0F0F0F"),
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				Text = option,
				TextColor3 = Color3.new(0.8, 0.8, 0.8),
				TextSize = 11,
				Parent = dropdown.OptionsFrame
			})
			
			optionButton.MouseButton1Click:Connect(function()
				dropdown.Value = option
				dropdown.Button.Text = dropdown.Name .. ": " .. dropdown.Value
				module.SavedSettings[dropdown.Name] = dropdown.Value
				pcall(dropdown.Callback, dropdown.Value)
				
				dropdown.Expanded = false
				TweenService:Create(dropdown.OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 0)
				}):Play()
				TweenService:Create(dropdown.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 30)
				}):Play()
				task.delay(0.2, function()
					dropdown.OptionsFrame.Visible = false
				end)
			end)
		end
		
		dropdown.OptionsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			dropdown.OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, dropdown.OptionsList.AbsoluteContentSize.Y)
		end)
		
		dropdown.Button.MouseButton1Click:Connect(function()
			dropdown.Expanded = not dropdown.Expanded
			
			if dropdown.Expanded then
				dropdown.OptionsFrame.Visible = true
				local height = math.min(dropdown.OptionsList.AbsoluteContentSize.Y, 100)
				TweenService:Create(dropdown.OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, height)
				}):Play()
				TweenService:Create(dropdown.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 30 + height)
				}):Play()
			else
				TweenService:Create(dropdown.OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 0)
				}):Play()
				TweenService:Create(dropdown.Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, 30)
				}):Play()
				task.delay(0.2, function()
					dropdown.OptionsFrame.Visible = false
				end)
			end
		end)
		
		table.insert(module.Components, dropdown)
		return dropdown
	end
	
	module.CreateToggle = function(toggleInfo)
		local toggle = {
			Name = toggleInfo.Name or "Toggle",
			Default = toggleInfo.Default or false,
			Callback = toggleInfo.Callback or function() end,
			Value = toggleInfo.Default or false
		}
		
		toggle.Frame = CreateInstance("Frame", {
			Name = toggle.Name,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		toggle.Button = CreateInstance("TextButton", {
			Size = UDim2.new(1, -35, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = toggle.Name,
			TextColor3 = Color3.new(0.8, 0.8, 0.8),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = toggle.Frame
		})
		
		toggle.Checkbox = CreateInstance("Frame", {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(1, -25, 0.5, -10),
			BackgroundColor3 = Color3.fromHex("#1A1A1A"),
			BorderSizePixel = 0,
			Parent = toggle.Frame
		})
		
		CreateInstance("UIStroke", {
			Color = GetCurrentAccentColor(),
			Thickness = 1,
			Parent = toggle.Checkbox
		})
		
		toggle.Checkmark = CreateInstance("Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(0.5, -6, 0.5, -6),
			BackgroundColor3 = GetCurrentAccentColor(),
			BorderSizePixel = 0,
			Visible = toggle.Value,
			Parent = toggle.Checkbox
		})
		table.insert(module.AccentElements, toggle.Checkmark)
		
		local function updateToggle()
			toggle.Checkmark.Visible = toggle.Value
			module.SavedSettings[toggle.Name] = toggle.Value
			pcall(toggle.Callback, toggle.Value)
		end
		
		toggle.Button.MouseButton1Click:Connect(function()
			toggle.Value = not toggle.Value
			updateToggle()
		end)
		
		if toggle.Value then
			updateToggle()
		end
		
		table.insert(module.Components, toggle)
		return toggle
	end
	
	module.CreateTextBox = function(textboxInfo)
		local textbox = {
			Name = textboxInfo.Name or "TextBox",
			Default = textboxInfo.Default or "",
			Placeholder = textboxInfo.Placeholder or "Enter text...",
			Callback = textboxInfo.Callback or function() end,
			Value = textboxInfo.Default or ""
		}
		
		textbox.Frame = CreateInstance("Frame", {
			Name = textbox.Name,
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		textbox.Label = CreateInstance("TextLabel", {
			Size = UDim2.new(1, -10, 0, 15),
			Position = UDim2.new(0, 5, 0, 3),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = textbox.Name,
			TextColor3 = Color3.new(0.8, 0.8, 0.8),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = textbox.Frame
		})
		
		textbox.Input = CreateInstance("TextBox", {
			Size = UDim2.new(1, -10, 0, 25),
			Position = UDim2.new(0, 5, 0, 20),
			BackgroundColor3 = Color3.fromHex("#1A1A1A"),
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			PlaceholderText = textbox.Placeholder,
			Text = textbox.Value,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			ClearTextOnFocus = false,
			Parent = textbox.Frame
		})
		
		CreateInstance("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			Parent = textbox.Input
		})
		
		CreateInstance("UIStroke", {
			Color = GetCurrentAccentColor(),
			Thickness = 1,
			Parent = textbox.Input
		})
		
		textbox.Input.FocusLost:Connect(function(enterPressed)
			textbox.Value = textbox.Input.Text
			module.SavedSettings[textbox.Name] = textbox.Value
			pcall(textbox.Callback, textbox.Value, enterPressed)
		end)
		
		table.insert(module.Components, textbox)
		return textbox
	end
	
	module.CreateButton = function(buttonInfo)
		local button = {
			Name = buttonInfo.Name or "Button",
			Callback = buttonInfo.Callback or function() end
		}
		
		button.Frame = CreateInstance("Frame", {
			Name = button.Name,
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		button.Button = CreateInstance("TextButton", {
			Size = UDim2.new(1, -10, 0, 25),
			Position = UDim2.new(0, 5, 0, 5),
			BackgroundColor3 = Color3.fromHex("#1A1A1A"),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = button.Name,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 12,
			Parent = button.Frame
		})
		
		local stroke = CreateInstance("UIStroke", {
			Color = GetCurrentAccentColor(),
			Thickness = 1,
			Parent = button.Button
		})
		table.insert(module.AccentElements, stroke)
		
		button.Button.MouseButton1Click:Connect(function()
			TweenService:Create(button.Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				BackgroundColor3 = GetCurrentAccentColor()
			}):Play()
			
			task.delay(0.1, function()
				TweenService:Create(button.Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
					BackgroundColor3 = Color3.fromHex("#1A1A1A")
				}):Play()
			end)
			
			pcall(button.Callback)
		end)
		
		table.insert(module.Components, button)
		return button
	end
	
	module.CreateLabel = function(labelInfo)
		local label = {
			Name = labelInfo.Name or "Label",
			Text = labelInfo.Text or "Label Text",
			Value = labelInfo.Text or "Label Text"
		}
		
		label.Frame = CreateInstance("Frame", {
			Name = label.Name,
			Size = UDim2.new(1, 0, 0, 25),
			BackgroundColor3 = Color3.fromHex("#0D0D0D"),
			BorderSizePixel = 0,
			Parent = module.ComponentContainer
		})
		
		label.Label = CreateInstance("TextLabel", {
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = label.Text,
			TextColor3 = Color3.new(0.7, 0.7, 0.7),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = label.Frame
		})
		
		label.SetText = function(newText)
			label.Value = newText
			label.Label.Text = newText
		end
		
		table.insert(module.Components, label)
		return label
	end
	
	self.Modules[module.Name] = module
	return module
end

-- Library Initialization
function Library:Init(settings)
	settings = settings or {}
	
	ScreenGui = CreateInstance("ScreenGui", {
		Name = "VapeUI_" .. HttpService:GenerateGUID(false),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = CoreGui
	})
	
	local function createMobileToggle()
		if not UserInputService.TouchEnabled then return end
		
		MobileToggleButton = CreateInstance("TextButton", {
			Name = "MobileToggle",
			Size = UDim2.new(0, 50, 0, 50),
			Position = UDim2.new(1, -60, 0.5, -25),
			BackgroundColor3 = GetCurrentAccentColor(),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = "V",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 24,
			Parent = ScreenGui
		})
		
		CreateInstance("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = MobileToggleButton
		})
		
		MakeDraggable(MobileToggleButton, MobileToggleButton)
		
		MobileToggleButton.MouseButton1Click:Connect(function()
			ScreenGui.Enabled = not ScreenGui.Enabled
			MobileToggleButton.Visible = true
			
			for _, category in pairs(GlobalSettings.Categories) do
				category.Frame.Visible = ScreenGui.Enabled
			end
		end)
	end
	
	createMobileToggle()
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == GlobalSettings.ToggleKeybind then
			ScreenGui.Enabled = not ScreenGui.Enabled
			
			if MobileToggleButton then
				MobileToggleButton.Visible = true
			end
		end
	end)
	
	StartColorUpdateLoop()
	
	local settingsCategory = self:CreateCategory({
		Name = "Settings",
		Position = UDim2.new(0, 10, 0, 10)
	})
	
	local appearanceModule = settingsCategory:CreateModule({
		Name = "Appearance",
		Description = "Customize UI appearance"
	})
	
	local colorModeDropdown = appearanceModule.CreateDropdown({
		Name = "Color Mode",
		Options = {"Static", "Breathing", "Rainbow", "Gradient"},
		Default = GlobalSettings.ColorMode,
		Callback = function(value)
			GlobalSettings.ColorMode = value
		end
	})
	
	local colorSpeedSlider = appearanceModule.CreateSlider({
		Name = "Color Speed",
		Min = 0.1,
		Max = 5,
		Default = GlobalSettings.ColorSpeed,
		Precise = true,
		Callback = function(value)
			GlobalSettings.ColorSpeed = value
		end
	})
	
	local accentColorPicker = appearanceModule.CreateColorPicker({
		Name = "Accent Color",
		Default = GlobalSettings.AccentColor,
		Callback = function(color)
			GlobalSettings.AccentColor = color
		end
	})
	
	local transparencySlider = appearanceModule.CreateSlider({
		Name = "UI Transparency",
		Min = 0,
		Max = 1,
		Default = GlobalSettings.UITransparency,
		Precise = true,
		Callback = function(value)
			GlobalSettings.UITransparency = value
			for _, category in pairs(GlobalSettings.Categories) do
				category.Frame.BackgroundTransparency = value * 0.5
			end
		end
	})
	
	local mobileButtonToggle = appearanceModule.CreateToggle({
		Name = "Mobile Button",
		Default = GlobalSettings.MobileButtonEnabled,
		Callback = function(enabled)
			GlobalSettings.MobileButtonEnabled = enabled
			if MobileToggleButton then
				MobileToggleButton.Visible = enabled
			end
		end
	})
	
	local interactionModule = settingsCategory:CreateModule({
		Name = "Interaction & HUD",
		Description = "Control interactions and overlays"
	})
	
	local keybindButton = interactionModule.CreateButton({
		Name = "Toggle Keybind: " .. GlobalSettings.ToggleKeybind.Name,
		Callback = function()
		end
	})
	
	local hiddenKeybindsToggle = interactionModule.CreateToggle({
		Name = "Hidden Keybinds",
		Default = GlobalSettings.HiddenKeybinds,
		Callback = function(enabled)
			GlobalSettings.HiddenKeybinds = enabled
		end
	})
	
	local watermarkToggle = interactionModule.CreateToggle({
		Name = "Performance Watermark",
		Default = GlobalSettings.PerformanceWatermark,
		Callback = function(enabled)
			GlobalSettings.PerformanceWatermark = enabled
		end
	})
	
	local arraylistToggle = interactionModule.CreateToggle({
		Name = "Active Modules ArrayList",
		Default = GlobalSettings.ArrayListEnabled,
		Callback = function(enabled)
			GlobalSettings.ArrayListEnabled = enabled
		end
	})
	
	local configModule = settingsCategory:CreateModule({
		Name = "Configuration",
		Description = "Save and load configurations"
	})
	
	local configNameBox = configModule.CreateTextBox({
		Name = "Config Name",
		Default = "default",
		Placeholder = "Enter config name...",
		Callback = function(value)
		end
	})
	
	local configList = configModule.CreateDropdown({
		Name = "Select Config",
		Options = GetConfigList(),
		Default = "None",
		Callback = function(value)
		end
	})
	
	local saveButton = configModule.CreateButton({
		Name = "Save Config",
		Callback = function()
			if configNameBox.Value and configNameBox.Value ~= "" then
				local success = SaveConfig(configNameBox.Value)
				if success then
					configList.Options = GetConfigList()
				end
			end
		end
	})
	
	local loadButton = configModule.CreateButton({
		Name = "Load Config",
		Callback = function()
			if configList.Value and configList.Value ~= "None" then
				LoadConfig(configList.Value)
			end
		end
	})
	
	local utilitiesModule = settingsCategory:CreateModule({
		Name = "Utilities",
		Description = "Utility functions"
	})
	
	local destructButton = utilitiesModule.CreateButton({
		Name = "Self Destruct",
		Callback = function()
			if ColorUpdateThread then
				task.cancel(ColorUpdateThread)
			end
			ScreenGui:Destroy()
		end
	})
	
	local uptimeLabel = utilitiesModule.CreateLabel({
		Name = "Uptime",
		Text = "Uptime: 00:00:00"
	})
	
	task.spawn(function()
		while ScreenGui and ScreenGui.Parent do
			local elapsed = tick() - UptimeStart
			local hours = math.floor(elapsed / 3600)
			local minutes = math.floor((elapsed % 3600) / 60)
			local seconds = math.floor(elapsed % 60)
			uptimeLabel.SetText(string.format("Uptime: %02d:%02d:%02d", hours, minutes, seconds))
			task.wait(1)
		end
	end)
	
	return self
end

function Library:CreateCategory(info)
	return Category.new(info)
end

return Library:Init()
