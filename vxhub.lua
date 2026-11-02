-- LEMONADE_UI_SCALE_CONVERTER (managed by Lemonade, do not edit or remove)
-- Pixel (Offset) values in Lemonade UIs are authored for a 1920x1080 screen.
-- This multiplies every pixel value under the ScreenGuis this script sees by
-- the fit of that reference inside the current viewport, so phones and
-- tablets show the desktop layout scaled down instead of desktop-sized pixels.
-- Scale fractions already follow the screen and stay as they are.
local lemonadeUiScale_REFERENCE = Vector2.new(1920, 1080)
local lemonadeUiScale_ATTRIBUTE_PREFIX = "LemonadeUiScale_"
local lemonadeUiScale_ROBLOX_SCREEN_GUIS = {
	TouchGui = true,
	ProximityPrompts = true,
	Chat = true,
	BubbleChat = true,
	Freecam = true,
}
local lemonadeUiScale_PIXEL_PROPERTIES = {
	GuiObject = { "Size", "Position" },
	TextLabel = { "TextSize" },
	TextButton = { "TextSize" },
	TextBox = { "TextSize" },
	ImageLabel = { "TileSize" },
	ImageButton = { "TileSize" },
	ScrollingFrame = { "CanvasSize", "ScrollBarThickness" },
	UIStroke = { "Thickness" },
	UICorner = { "CornerRadius" },
	UIPadding = { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" },
	UIListLayout = { "Padding" },
	UIPageLayout = { "Padding" },
	UITableLayout = { "Padding" },
	UIGridLayout = { "CellSize", "CellPadding" },
	UISizeConstraint = { "MinSize", "MaxSize" },
	UITextSizeConstraint = { "MinTextSize", "MaxTextSize" },
}

local function lemonadeUiScale_factor(viewport: Vector2): number
	return math.min(viewport.X / lemonadeUiScale_REFERENCE.X, viewport.Y / lemonadeUiScale_REFERENCE.Y)
end

local function lemonadeUiScale_scaleValue(value: any, factor: number): any
	local kind = typeof(value)
	if kind == "UDim" then
		return UDim.new(value.Scale, math.round(value.Offset * factor))
	end
	if kind == "UDim2" then
		return UDim2.new(value.X.Scale, math.round(value.X.Offset * factor), value.Y.Scale, math.round(value.Y.Offset * factor))
	end
	return value * factor
end

local function lemonadeUiScale_apply(instance: Instance, factor: number)
	local target = instance :: any
	for className, properties in lemonadeUiScale_PIXEL_PROPERTIES do
		if not instance:IsA(className) then
			continue
		end
		for _, property in properties do
			local attribute = lemonadeUiScale_ATTRIBUTE_PREFIX .. property
			local authored = instance:GetAttribute(attribute)
			if authored == nil then
				authored = target[property]
				if lemonadeUiScale_scaleValue(authored, 2) == authored then
					continue
				end
				instance:SetAttribute(attribute, authored)
			end
			target[property] = lemonadeUiScale_scaleValue(authored, factor)
		end
	end
end

local function lemonadeUiScale_hasOwnScale(screenGui: ScreenGui): boolean
	for _, descendant in screenGui:GetDescendants() do
		if descendant:IsA("UIScale") and not descendant.Parent:IsA("GuiButton") then
			return true
		end
	end
	return false
end

local function lemonadeUiScale_convert(screenGui: ScreenGui, factor: number)
	if lemonadeUiScale_hasOwnScale(screenGui) then
		return
	end
	for _, descendant in screenGui:GetDescendants() do
		lemonadeUiScale_apply(descendant, factor)
	end
end

local lemonadeUiScale_RunService = game:GetService("RunService")
if lemonadeUiScale_RunService:IsRunning() and lemonadeUiScale_RunService:IsClient() then
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local camera = workspace.CurrentCamera
	local managed = setmetatable({}, { __mode = "k" })
	local function currentFactor(): number
		return lemonadeUiScale_factor(camera.ViewportSize)
	end
	playerGui.ChildAdded:Connect(function(child)
		if not child:IsA("ScreenGui") then return end
		task.defer(function()
			lemonadeUiScale_RunService.RenderStepped:Wait()
			if lemonadeUiScale_hasOwnScale(child) then return end
			managed[child] = true
			lemonadeUiScale_convert(child, currentFactor())
			child.DescendantAdded:Connect(function(descendant)
				task.defer(function()
					if descendant:IsDescendantOf(child) then lemonadeUiScale_apply(descendant, currentFactor()) end
				end)
			end)
		end)
	end)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		for screenGui in managed do lemonadeUiScale_convert(screenGui, currentFactor()) end
	end)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local THEME = {
	LightBlue = Color3.fromRGB(140, 207, 255),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(16, 24, 32),
	DarkBlue = Color3.fromRGB(23, 70, 107),
	SoftBlue = Color3.fromRGB(229, 244, 255),
	Muted = Color3.fromRGB(112, 132, 150),
	SideTab = Color3.fromRGB(28, 43, 58),
	SideTabHover = Color3.fromRGB(42, 60, 78),
	HeaderBtn = Color3.fromRGB(34, 48, 62),
	HeaderBtnHover = Color3.fromRGB(50, 68, 86),
	OptHover = Color3.fromRGB(240, 248, 255),
}

local ICON = {
	user = "rbxassetid://99097554161865",
	eye = "rbxassetid://6523858394",
	close = "rbxassetid://109798318511632",
	chevron = "rbxassetid://13360801719",
	check = "rbxassetid://128850290702187",
}

local WIN_W, WIN_H = 600, 420
local HEADER_H = 54
local SIDEBAR_W = 134
local ROW_H = 44
local TI_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_DROP = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_OPEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_CLOSE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function create(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function tween(inst, ti, props)
	local t = TweenService:Create(inst, ti, props)
	t:Play()
	return t
end

local function corner(inst, r)
	create("UICorner", { CornerRadius = UDim.new(0, r) }, inst)
end

local function stroke(inst, color, thickness, transparency)
	return create("UIStroke", { Color = color, Thickness = thickness, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
end

local function hoverBrighten(btn, base, hovered)
	btn.MouseEnter:Connect(function() tween(btn, TI_FAST, { BackgroundColor3 = hovered }) end)
	btn.MouseLeave:Connect(function() tween(btn, TI_FAST, { BackgroundColor3 = base }) end)
end

local featureDefs = {
	Player = {
		{ id = "Speed", options = {
			{ name = "Normal Speed", number = true, default = 24 },
			{ name = "Stealing Speed", number = true, default = 32 },
		}},
		{ id = "Fly", options = { { name = "Fly Speed", number = true, default = 50 } } },
	},
	Visuals = {
		{ id = "ESP", options = { { name = "Players" }, { name = "Brainrots" }, { name = "Highest Income Brainrot" } } },
		{ id = "Base X-Ray", options = { { name = "All Bases" }, { name = "My Base" } }, slider = { label = "Transparency", default = 0.5 } },
	},
}

local state = { open = false, activeTab = "Player", features = {} }
local featureChanged = Instance.new("BindableEvent")
for _, defs in pairs(featureDefs) do
	for _, def in ipairs(defs) do
		local f = { enabled = false, expanded = false, options = {} }
		if def.slider then f.sliderValue = def.slider.default end
		for _, opt in ipairs(def.options) do f.options[opt.name] = { selected = false, value = opt.default } end
		state.features[def.id] = f
	end
end

local gui = create("ScreenGui", { Name = "VXHubGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local window = create("CanvasGroup", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundColor3 = THEME.White, BorderSizePixel = 0, Visible = false }, gui)
corner(window, 14)
stroke(window, THEME.Black, 2, 0.35)
local winScale = create("UIScale", { Scale = 1 }, window)

local header = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundColor3 = THEME.Black, BorderSizePixel = 0, ZIndex = 2 }, window)
corner(header, 14)
local dragHandle = create("TextButton", { Name = "DragHandle", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -104, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = true, ZIndex = 2 }, header)
create("Frame", { BackgroundColor3 = THEME.Black, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), ZIndex = 2 }, header)
local logo = create("Frame", { Name = "Logo", Position = UDim2.new(0, 12, 0, 10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = THEME.LightBlue, BorderSizePixel = 0, ZIndex = 3 }, header)
corner(logo, 10)
create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "VX", TextSize = 15, TextColor3 = THEME.Black, ZIndex = 4 }, logo)
create("TextLabel", { Name = "Title", Position = UDim2.new(0, 56, 0, 9), Size = UDim2.new(0, 220, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "VX HUB", TextSize = 18, TextColor3 = THEME.White, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, header)
create("TextLabel", { Name = "Subtitle", Position = UDim2.new(0, 56, 0, 30), Size = UDim2.new(0, 220, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "STEAL A BRAINROT", TextSize = 10, TextColor3 = THEME.LightBlue, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, header)
create("TextLabel", { Name = "Version", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -52, 0.5, 0), Size = UDim2.new(0, 60, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "v1.0.0", TextSize = 12, TextColor3 = Color3.fromRGB(150, 168, 182), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 }, header)
local closeBtn = create("TextButton", { Name = "CloseButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = THEME.HeaderBtn, Text = "", AutoButtonColor = false, ZIndex = 3 }, header)
corner(closeBtn, 8)
stroke(closeBtn, THEME.DarkBlue, 1, 0.4)
create("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Image = ICON.close, ZIndex = 4 }, closeBtn)
hoverBrighten(closeBtn, THEME.HeaderBtn, THEME.HeaderBtnHover)

local body = create("Frame", { Name = "Body", Position = UDim2.new(0, 0, 0, HEADER_H), Size = UDim2.new(1, 0, 1, -HEADER_H), BackgroundTransparency = 1 }, window)
local sidebar = create("Frame", { Name = "Sidebar", Size = UDim2.new(0, SIDEBAR_W, 1, 0), BackgroundColor3 = THEME.Black, BorderSizePixel = 0 }, body)
corner(sidebar, 14)
create("Frame", { BackgroundColor3 = THEME.Black, BorderSizePixel = 0, Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0) }, sidebar)

local dragStart, windowStart, dragInput
local function updateWindowDrag(input)
	local delta = input.Position - dragStart
	local viewport = workspace.CurrentCamera.ViewportSize
	local halfWidth, halfHeight = window.AbsoluteSize.X * 0.5, window.AbsoluteSize.Y * 0.5
	local minX, maxX = halfWidth - viewport.X * 0.5, viewport.X * 0.5 - halfWidth
	local minY, maxY = halfHeight - viewport.Y * 0.5, viewport.Y * 0.5 - halfHeight
	local x = minX <= maxX and math.clamp(windowStart.X.Offset + delta.X, minX, maxX) or 0
	local y = minY <= maxY and math.clamp(windowStart.Y.Offset + delta.Y, minY, maxY) or 0
	window.Position = UDim2.new(0.5, x, 0.5, y)
end
dragHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragStart, windowStart, dragInput = input.Position, window.Position, input
	end
end)
dragHandle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then updateWindowDrag(input) end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart, dragInput = nil, nil end
end)
create("Frame", { BackgroundColor3 = THEME.Black, BackgroundTransparency = 0.88, BorderSizePixel = 0, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 3 }, sidebar)
create("TextLabel", { Name = "SidebarLabel", Position = UDim2.new(0, 0, 0, 12), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "MENU", TextSize = 10, TextColor3 = THEME.LightBlue }, sidebar)
local tabList = create("Frame", { Name = "TabList", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, 120) }, sidebar)
create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, tabList)

local tabs, pages, built = {}, {}, {}
local setTab
local function makeTab(id, text, icon, order)
	local btn = create("TextButton", { Name = "Tab_" .. id, Size = UDim2.new(0, SIDEBAR_W - 20, 0, 46), BackgroundColor3 = THEME.SideTab, Text = "", AutoButtonColor = false, LayoutOrder = order }, tabList)
	corner(btn, 10)
	local st = stroke(btn, THEME.Black, 1, 0.85)
	local iconLabel = create("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), Size = UDim2.fromOffset(20, 20), Image = icon }, btn)
	local label = create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(1, -44, 1, 0), Font = Enum.Font.GothamBold, Text = text, TextSize = 14, TextColor3 = THEME.LightBlue, TextXAlignment = Enum.TextXAlignment.Left }, btn)
	tabs[id] = { button = btn, icon = iconLabel, label = label, stroke = st }
	btn.Activated:Connect(function() setTab(id) end)
	btn.MouseEnter:Connect(function() if state.activeTab ~= id then tween(btn, TI_FAST, { BackgroundColor3 = THEME.SideTabHover }) end end)
	btn.MouseLeave:Connect(function() if state.activeTab ~= id then tween(btn, TI_FAST, { BackgroundColor3 = THEME.SideTab }) end end)
end
makeTab("Player", "Player", ICON.user, 1)
makeTab("Visuals", "Visuals", ICON.eye, 2)

local content = create("Frame", { Name = "Content", Position = UDim2.new(0, SIDEBAR_W, 0, 0), Size = UDim2.new(1, -SIDEBAR_W, 1, 0), BackgroundColor3 = Color3.fromRGB(235, 243, 250), BorderSizePixel = 0 }, body)
local function makePage(name)
	local sf = create("ScrollingFrame", { Name = "Page_" .. name, Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.LightBlue, Visible = false }, content)
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	pages[name] = sf
	return sf
end
makePage("Player")
makePage("Visuals")

local refreshFeature
local function panelContentHeight(entry)
	local h, count = 16, 0
	for _, child in ipairs(entry.ordered) do
		if child.Visible then h += child.Size.Y.Offset + (count > 0 and 5 or 0); count += 1 end
	end
	return h
end
local function applyDropdown(entry, instant)
	local open = entry.f.expanded
	local ph = open and panelContentHeight(entry) or 0
	local ti = instant and TweenInfo.new(0) or TI_DROP
	if open then
		if not entry.panel.Visible then entry.panel.Size = UDim2.new(1, -20, 0, 0); entry.panel.Visible = true end
		tween(entry.panel, ti, { Size = UDim2.new(1, -20, 0, ph) })
	else
		local t = tween(entry.panel, ti, { Size = UDim2.new(1, -20, 0, 0) })
		t.Completed:Once(function() if not entry.f.expanded then entry.panel.Visible = false end end)
	end
	tween(entry.container, ti, { Size = UDim2.new(1, 0, 0, ROW_H + 4 + ph) })
	tween(entry.arrow, ti, { Rotation = open and 180 or 0 })
end

local function buildFeature(sf, def, order)
	local f = state.features[def.id]
	local container = create("Frame", { Name = "Feature_" .. def.id, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, LayoutOrder = order }, sf)
	local row = create("Frame", { Name = "Row", Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = THEME.White, BorderSizePixel = 0 }, container)
	corner(row, 10)
	stroke(row, THEME.Black, 1, 0.8)
	local checkbox = create("TextButton", { Name = "Checkbox", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = THEME.White, Text = "", AutoButtonColor = false }, row)
	corner(checkbox, 6)
	stroke(checkbox, THEME.DarkBlue, 2, 0.15)
	local cbFill = create("Frame", { Name = "Fill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 0), BackgroundColor3 = THEME.LightBlue, BorderSizePixel = 0, ZIndex = 2 }, checkbox)
	corner(cbFill, 4)
	local cbCheck = create("ImageLabel", { Name = "Check", BackgroundTransparency = 1, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Image = ICON.check, ZIndex = 3 }, checkbox)
	create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -110, 1, 0), Font = Enum.Font.GothamBold, Text = def.id, TextSize = 15, TextColor3 = THEME.Black, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local arrowBtn = create("TextButton", { Name = "ArrowButton", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = THEME.SoftBlue, Text = "", AutoButtonColor = false }, row)
	corner(arrowBtn, 8)
	local arrow = create("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Image = ICON.chevron, ImageColor3 = THEME.DarkBlue }, arrowBtn)
	hoverBrighten(arrowBtn, THEME.SoftBlue, Color3.fromRGB(214, 236, 252))
	local panel = create("Frame", { Name = "Dropdown", Position = UDim2.new(0, 10, 0, ROW_H + 4), Size = UDim2.new(1, -20, 0, 0), BackgroundColor3 = THEME.SoftBlue, BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, container)
	corner(panel, 10)
	stroke(panel, THEME.LightBlue, 1, 0.3)
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, panel)
	create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	local entry = { def = def, f = f, container = container, panel = panel, checkbox = checkbox, cbFill = cbFill, cbCheck = cbCheck, arrow = arrow, options = {}, ordered = {} }
	for i, optDef in ipairs(def.options) do
		local optState = f.options[optDef.name]
		local optBtn = create("TextButton", { Name = "Opt_" .. optDef.name, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = THEME.White, Text = "", AutoButtonColor = false, LayoutOrder = i * 10 }, panel)
		corner(optBtn, 8)
		stroke(optBtn, THEME.Black, 1, 0.85)
		create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.GothamBold, Text = optDef.name, TextSize = 13, TextColor3 = THEME.Black, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, optBtn)
		local optCheck = create("ImageLabel", { Name = "Check", BackgroundTransparency = 1, Visible = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), Image = ICON.check }, optBtn)
		hoverBrighten(optBtn, THEME.White, THEME.OptHover)
		local o = { btn = optBtn, check = optCheck }
		entry.options[optDef.name] = o
		table.insert(entry.ordered, optBtn)
		if optDef.number then
			local numRow = create("Frame", { Name = "Num_" .. optDef.name, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = THEME.White, BorderSizePixel = 0, Visible = false, LayoutOrder = i * 10 + 1 }, panel)
			corner(numRow, 8)
			stroke(numRow, THEME.Black, 1, 0.85)
			local box = create("TextBox", { Name = "Value", BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0), Font = Enum.Font.GothamBold, Text = tostring(optState.value), PlaceholderText = optDef.name .. " value", PlaceholderColor3 = THEME.Muted, TextColor3 = THEME.Black, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false }, numRow)
			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if n then
					n = math.clamp(math.floor(n + 0.5), 1, 500)
					optState.value = n
					box.Text = tostring(n)
					featureChanged:Fire(def.id)
				else box.Text = tostring(optState.value) end
			end)
			o.numRow = numRow
			table.insert(entry.ordered, numRow)
		end
		optBtn.Activated:Connect(function()
			optState.selected = not optState.selected
			refreshFeature(entry)
			featureChanged:Fire(def.id)
		end)
	end
	if def.slider then
		local sRow = create("Frame", { Name = "Slider", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 100 }, panel)
		create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(0.6, 0, 0, 16), Font = Enum.Font.GothamBold, Text = def.slider.label, TextSize = 12, TextColor3 = THEME.DarkBlue, TextXAlignment = Enum.TextXAlignment.Left }, sRow)
		local pct = create("TextLabel", { Name = "Percent", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 0), Size = UDim2.new(0.4, 0, 0, 16), Font = Enum.Font.GothamBold, Text = "50%", TextSize = 12, TextColor3 = THEME.DarkBlue, TextXAlignment = Enum.TextXAlignment.Right }, sRow)
		local track = create("Frame", { Name = "Track", Position = UDim2.new(0, 2, 0, 30), Size = UDim2.new(1, -4, 0, 6), BackgroundColor3 = THEME.White, BorderSizePixel = 0 }, sRow)
		corner(track, 3)
		stroke(track, THEME.Black, 1, 0.8)
		local fill = create("Frame", { Name = "Fill", Size = UDim2.new(f.sliderValue, 0, 1, 0), BackgroundColor3 = THEME.LightBlue, BorderSizePixel = 0 }, track)
		corner(fill, 3)
		local knob = create("TextButton", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(f.sliderValue, 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = THEME.DarkBlue, Text = "", AutoButtonColor = false, ZIndex = 5 }, track)
		corner(knob, 8)
		stroke(knob, THEME.White, 2, 0)
		local function setSlider(v)
			v = math.clamp(v, 0, 1)
			f.sliderValue = v
			pct.Text = math.floor(v * 100 + 0.5) .. "%"
			fill.Size = UDim2.new(v, 0, 1, 0)
			knob.Position = UDim2.new(v, 0, 0.5, 0)
			featureChanged:Fire(def.id)
		end
		local dragging = false
		local function fromX(x) setSlider((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)) end
		local function began(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; fromX(input.Position.X) end
		end
		track.InputBegan:Connect(began)
		knob.InputBegan:Connect(began)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end)
		table.insert(entry.ordered, sRow)
		setSlider(def.slider.default)
	end
	arrowBtn.Activated:Connect(function() f.expanded = not f.expanded; applyDropdown(entry) end)
	checkbox.Activated:Connect(function() f.enabled = not f.enabled; refreshFeature(entry); featureChanged:Fire(def.id) end)
	built[def.id] = entry
end

refreshFeature = function(entry, instant)
	local f = entry.f
	local target = f.enabled and UDim2.new(1, -8, 1, -8) or UDim2.fromScale(0, 0)
	tween(entry.cbFill, instant and TweenInfo.new(0) or TI_FAST, { Size = target })
	tween(entry.checkbox, instant and TweenInfo.new(0) or TI_FAST, { BackgroundColor3 = f.enabled and THEME.LightBlue or THEME.White })
	entry.cbCheck.Visible = f.enabled
	for name, o in pairs(entry.options) do
		local sel = f.options[name].selected
		tween(o.btn, instant and TweenInfo.new(0) or TI_FAST, { BackgroundColor3 = sel and THEME.LightBlue or THEME.White })
		o.check.Visible = sel
		if o.numRow then o.numRow.Visible = sel end
	end
	applyDropdown(entry, instant)
end

setTab = function(id)
	state.activeTab = id
	for tid, tab in pairs(tabs) do
		local active = tid == id
		tween(tab.button, TI_FAST, { BackgroundColor3 = active and THEME.LightBlue or THEME.SideTab })
		tab.label.TextColor3 = active and THEME.White or THEME.LightBlue
		tab.icon.ImageColor3 = active and THEME.White or THEME.LightBlue
		tab.stroke.Color = active and THEME.LightBlue or THEME.Black
		tab.stroke.Transparency = active and 0 or 0.85
		tab.stroke.Thickness = active and 2 or 1
	end
	pages.Player.Visible = id == "Player"
	pages.Visuals.Visible = id == "Visuals"
end

for _, def in ipairs(featureDefs.Player) do buildFeature(pages.Player, def, def.id == "Speed" and 1 or 2) end
for _, def in ipairs(featureDefs.Visuals) do buildFeature(pages.Visuals, def, def.id == "ESP" and 1 or 2) end

local floatBtn = create("TextButton", { Name = "FloatingButton", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = THEME.Black, Text = "", AutoButtonColor = false, Visible = false }, gui)
corner(floatBtn, 24)
stroke(floatBtn, THEME.LightBlue, 2, 0.2)
create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "VX", TextSize = 16, TextColor3 = THEME.LightBlue, ZIndex = 3 }, floatBtn)
hoverBrighten(floatBtn, THEME.Black, Color3.fromRGB(40, 56, 72))

local setOpen
local function setOpenInner(open)
	if state.open == open then return end
	state.open = open
	floatBtn.Visible = not open
	if open then
		window.Visible = true
		window.GroupTransparency = 1
		winScale.Scale = 0.88
		tween(winScale, TI_OPEN, { Scale = 1 })
		tween(window, TI_FAST, { GroupTransparency = 0 })
	else
		tween(winScale, TI_CLOSE, { Scale = 0.88 })
		local t = tween(window, TI_CLOSE, { GroupTransparency = 1 })
		t.Completed:Once(function() if not state.open then window.Visible = false end end)
	end
end
setOpen = function(open) setOpenInner(open) end
closeBtn.Activated:Connect(function() setOpen(false) end)
floatBtn.Activated:Connect(function() setOpen(true) end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.V then setOpen(not state.open) end
end)

local function selectedOption(featureId, optionName)
	local feature = state.features[featureId]
	local option = feature and feature.options[optionName]
	return option and option.selected == true
end

local savedWalkSpeed = 16
local currentHumanoid
local activeVelocity, activeAttachment
local originalAutoRotate
local function stopFlight()
	if activeVelocity then activeVelocity:Destroy(); activeVelocity = nil end
	if activeAttachment then activeAttachment:Destroy(); activeAttachment = nil end
	if currentHumanoid then
		currentHumanoid.AutoRotate = originalAutoRotate ~= nil and originalAutoRotate or true
		currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	originalAutoRotate = nil
end

local function setHumanoid(character)
	stopFlight()
	currentHumanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	savedWalkSpeed = currentHumanoid.WalkSpeed
	if state.features.Speed.enabled then
		local speed = state.features.Speed
		if selectedOption("Speed", "Stealing Speed") then savedWalkSpeed = speed.options["Stealing Speed"].value
		elseif selectedOption("Speed", "Normal Speed") then savedWalkSpeed = speed.options["Normal Speed"].value end
	end
	currentHumanoid.WalkSpeed = savedWalkSpeed
	if state.features.Fly.enabled then
		local feature = state.features.Fly
		local speed = feature.options["Fly Speed"].value
		originalAutoRotate = currentHumanoid.AutoRotate
		currentHumanoid.AutoRotate = false
		local attachment = Instance.new("Attachment")
		attachment.Name = "VXHubFlightAttachment"
		attachment.Parent = root
		activeAttachment = attachment
		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "VXHubFlightVelocity"
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		velocity.VectorVelocity = Vector3.zero
		velocity.MaxForce = 100000
		velocity.Parent = root
		activeVelocity = velocity
	end
end

local function applySpeed()
	if not currentHumanoid then return end
	local feature = state.features.Speed
	if feature.enabled then
		if selectedOption("Speed", "Stealing Speed") then currentHumanoid.WalkSpeed = feature.options["Stealing Speed"].value
		elseif selectedOption("Speed", "Normal Speed") then currentHumanoid.WalkSpeed = feature.options["Normal Speed"].value
		else currentHumanoid.WalkSpeed = savedWalkSpeed end
	else
		currentHumanoid.WalkSpeed = savedWalkSpeed
	end
end

local function applyFlight()
	if not currentHumanoid or not currentHumanoid.Parent then return end
	local character = currentHumanoid.Parent
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	stopFlight()
	if not state.features.Fly.enabled then return end
	originalAutoRotate = currentHumanoid.AutoRotate
	currentHumanoid.AutoRotate = false
	local attachment = Instance.new("Attachment")
	attachment.Name = "VXHubFlightAttachment"
	attachment.Parent = root
	activeAttachment = attachment
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "VXHubFlightVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity = Vector3.zero
	velocity.MaxForce = 100000
	velocity.Parent = root
	activeVelocity = velocity
end

local function applyPlayerFeatures()
	applySpeed()
	if currentHumanoid then applyFlight() end
end

local espHighlights = {}
local xrayOriginals = {}
local function clearHighlights()
	for object, highlight in pairs(espHighlights) do
		if highlight then highlight:Destroy() end
		espHighlights[object] = nil
	end
end
local function collectParts(object)
	local parts = {}
	if object:IsA("BasePart") then table.insert(parts, object) end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") then table.insert(parts, descendant) end
	end
	return parts
end
local function applyXray()
	for part, original in pairs(xrayOriginals) do
		if part.Parent then part.LocalTransparencyModifier = original end
		xrayOriginals[part] = nil
	end
	local feature = state.features["Base X-Ray"]
	if not feature.enabled then return end
	local allBases = selectedOption("Base X-Ray", "All Bases")
	local myBase = selectedOption("Base X-Ray", "My Base")
	if not allBases and not myBase then return end
	local targetTransparency = feature.sliderValue
	for _, model in ipairs(CollectionService:GetTagged("Base")) do
		local owner = model:GetAttribute("OwnerUserId")
		if allBases or (myBase and owner == player.UserId) then
			for _, part in ipairs(collectParts(model)) do
				xrayOriginals[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = targetTransparency
			end
		end
	end
end

local function getIncome(object)
	local value = object:GetAttribute("IncomePerSecond")
	if type(value) == "number" then return value end
	local model = object:FindFirstAncestorOfClass("Model")
	if model then
		value = model:GetAttribute("IncomePerSecond")
		if type(value) == "number" then return value end
	end
	return 0
end

local function applyEsp()
	clearHighlights()
	local feature = state.features.ESP
	if not feature.enabled then return end
	local showPlayers = selectedOption("ESP", "Players")
	local showBrainrots = selectedOption("ESP", "Brainrots")
	local highestOnly = selectedOption("ESP", "Highest Income Brainrot")
	if showPlayers then
		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			if targetPlayer.Character then
				local highlight = Instance.new("Highlight")
				highlight.Name = targetPlayer == player and "VXHubSelfPlayerESP" or "VXHubPlayerESP"
				highlight.Adornee = targetPlayer.Character
				highlight.FillColor = THEME.LightBlue
				highlight.OutlineColor = THEME.LightBlue
				highlight.FillTransparency = 0.72
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = gui
				espHighlights[targetPlayer.Character] = highlight
			end
		end
	end
	local brainrots = CollectionService:GetTagged("Brainrot")
	local highest = nil
	if highestOnly then
		for _, object in ipairs(brainrots) do
			if not highest or getIncome(object) > getIncome(highest) then highest = object end
		end
	end
	for _, object in ipairs(brainrots) do
		if (showBrainrots or highestOnly and object == highest) and object:IsDescendantOf(workspace) then
			local highlight = Instance.new("Highlight")
			highlight.Name = "VXHubBrainrotESP"
			highlight.Adornee = object
			highlight.FillColor = object == highest and Color3.fromRGB(255, 207, 89) or THEME.LightBlue
			highlight.OutlineColor = THEME.White
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = gui
			espHighlights[object] = highlight
		end
	end
end

local function applyVisuals()
	applyEsp()
	applyXray()
end

featureChanged.Event:Connect(function(featureId)
	if featureId == "Speed" or featureId == "Fly" then applyPlayerFeatures() end
	if featureId == "ESP" or featureId == "Base X-Ray" then applyVisuals() end
end)

RunService.RenderStepped:Connect(function()
	if not activeVelocity or not currentHumanoid then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local feature = state.features.Fly
	local speed = math.clamp(feature.options["Fly Speed"].value, 1, 150)
	local direction = Vector3.zero
	local movement = currentHumanoid.MoveDirection
	if movement.Magnitude > 0 then direction += movement end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then direction -= Vector3.yAxis end
	if direction.Magnitude > 1 then direction = direction.Unit end
	activeVelocity.VectorVelocity = direction * speed
end)

Players.LocalPlayer.CharacterAdded:Connect(function(character)
	task.defer(function()
		setHumanoid(character)
		applyPlayerFeatures()
		applyVisuals()
	end)
end)
if player.Character then task.spawn(setHumanoid, player.Character) end

Players.PlayerAdded:Connect(function() task.defer(applyEsp) end)
Players.PlayerRemoving:Connect(function() task.defer(applyEsp) end)
CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(function() task.defer(applyEsp) end)
CollectionService:GetInstanceRemovedSignal("Brainrot"):Connect(function() task.defer(applyEsp) end)
CollectionService:GetInstanceAddedSignal("Base"):Connect(function() task.defer(applyXray) end)
CollectionService:GetInstanceRemovedSignal("Base"):Connect(function() task.defer(applyXray) end)

setTab(state.activeTab)
for _, entry in pairs(built) do refreshFeature(entry, true) end
setOpen(true)
print("[VXHub] loaded — client-only Speed, Fly, ESP and Base X-Ray ready")
