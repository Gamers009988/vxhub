
--==================================================
-- CHILL HUB 2.2
-- FULL ROBLOX STUDIO LOCAL SCRIPT
-- StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local C = {
	accent = Color3.fromRGB(145, 85, 255),
	background = Color3.fromRGB(13, 13, 19),
	panel = Color3.fromRGB(23, 23, 33),
	element = Color3.fromRGB(34, 34, 47),
	text = Color3.fromRGB(245, 245, 250),
	muted = Color3.fromRGB(150, 150, 170),
	green = Color3.fromRGB(70, 230, 130),
	red = Color3.fromRGB(255, 75, 90),
	yellow = Color3.fromRGB(255, 200, 65),
	blue = Color3.fromRGB(90, 200, 255),
}

local SETTINGS = {
	player_esp = true,
	name_esp = true,
	brainrot_esp = false,
	base_esp = false,
	distance_esp = true,
	sneak_steal = false,
	auto_grab = false,
	visual_desync = false,
	fullbright = false,
	speed_enabled = false,
	jump_enabled = false,
	sneak_offset = 2,
}

--==================================================
-- CLEANUP
--==================================================

local old = playerGui:FindFirstChild("ChillHub")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ChillHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local esp_folder = Instance.new("Folder")
esp_folder.Name = "ChillHubESP"
esp_folder.Parent = gui

local function make(class, props, parent)
	local obj = Instance.new(class)

	for k, v in pairs(props or {}) do
		obj[k] = v
	end

	obj.Parent = parent
	return obj
end

local function round(obj, radius)
	make("UICorner", {
		CornerRadius = UDim.new(0, radius or 8)
	}, obj)
end

local function label(parent, text, size, color, height)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size or 12,
		TextColor3 = color or C.text,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, height or 24),
	}, parent)
end

local function tween(obj, props)
	TweenService:Create(
		obj,
		TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		props
	):Play()
end

--==================================================
-- MAIN WINDOW
--==================================================

local main = make("Frame", {
	Name = "Main",
	Size = UDim2.fromOffset(730, 490),
	Position = UDim2.new(0.5, -365, 0.5, -245),
	BackgroundColor3 = C.background,
	BorderSizePixel = 0,
}, gui)

round(main, 12)

make("UIStroke", {
	Color = C.accent,
	Thickness = 1.2,
}, main)

local top = make("Frame", {
	Size = UDim2.new(1, 0, 0, 55),
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
}, main)

round(top, 12)

local logo = make("Frame", {
	Position = UDim2.fromOffset(15, 12),
	Size = UDim2.fromOffset(31, 31),
	BackgroundColor3 = C.accent,
}, top)

round(logo, 8)

local logoText = label(logo, "C", 18)
logoText.TextXAlignment = Enum.TextXAlignment.Center

local title = label(top, "CHILL HUB", 16)
title.Position = UDim2.fromOffset(56, 5)

local subtitle = label(top, "STEAL A BRAINROT EDITION", 9, C.muted)
subtitle.Position = UDim2.fromOffset(57, 29)

local close = make("TextButton", {
	Size = UDim2.fromOffset(32, 30),
	Position = UDim2.new(1, -43, 0, 12),
	BackgroundColor3 = C.element,
	Text = "×",
	TextColor3 = C.red,
	TextSize = 22,
	Font = Enum.Font.Gotham,
}, top)

round(close, 7)

close.Activated:Connect(function()
	gui.Enabled = false
end)

--==================================================
-- DRAG WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

--==================================================
-- SIDEBAR
--==================================================

local sidebar = make("Frame", {
	Position = UDim2.fromOffset(0, 55),
	Size = UDim2.new(0, 165, 1, -55),
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
}, main)

make("UIPadding", {
	PaddingTop = UDim.new(0, 14),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
}, sidebar)

make("UIListLayout", {
	Padding = UDim.new(0, 8),
}, sidebar)

local content = make("Frame", {
	Position = UDim2.fromOffset(165, 55),
	Size = UDim2.new(1, -165, 1, -55),
	BackgroundTransparency = 1,
}, main)

local pages = {}
local tabs = {}

local function newPage(name)
	local page = make("ScrollingFrame", {
		Name = name,
		Position = UDim2.fromOffset(15, 15),
		Size = UDim2.new(1, -30, 1, -30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
	}, content)

	make("UIListLayout", {
		Padding = UDim.new(0, 11),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	pages[name] = page
	return page
end

local function switchPage(name)
	for n, page in pairs(pages) do
		page.Visible = n == name
	end

	for n, button in pairs(tabs) do
		button.BackgroundColor3 = n == name and C.accent or C.element
	end
end

local function tab(name, icon)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 39),
		BackgroundColor3 = C.element,
		Text = "   " .. icon .. "     " .. name,
		TextColor3 = C.text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
	}, sidebar)

	round(button, 7)

	tabs[name] = button
	local page = newPage(name)

	button.Activated:Connect(function()
		switchPage(name)
	end)

	return page
end

--==================================================
-- UI COMPONENTS
--==================================================

local function section(parent, name, description)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 57),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	}, parent)

	round(frame, 8)

	local heading = label(frame, name, 13)
	heading.Position = UDim2.fromOffset(12, 5)

	if description then
		local desc = label(frame, description, 10, C.muted)
		desc.Position = UDim2.fromOffset(12, 29)
	end

	return frame
end

local function container(parent, height)
	local frame = make("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = C.panel,
		BorderSizePixel = 0,
	}, parent)

	round(frame, 8)

	make("UIPadding", {
		PaddingLeft = UDim.new(0, 13),
		PaddingRight = UDim.new(0, 13),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}, frame)

	make("UIListLayout", {
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)

	return frame
end

local function toggle(parent, name, key, callback)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 29),
		BackgroundTransparency = 1,
	}, parent)

	local txt = label(row, name, 12)
	txt.Size = UDim2.new(1, -60, 1, 0)

	local button = make("TextButton", {
		Size = UDim2.fromOffset(42, 22),
		Position = UDim2.new(1, -42, 0.5, -11),
		BackgroundColor3 = SETTINGS[key] and C.accent or C.element,
		Text = "",
		AutoButtonColor = false,
	}, row)

	round(button, 15)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = SETTINGS[key] and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3),
		BackgroundColor3 = C.text,
	}, button)

	round(knob, 10)

	local function set(value)
		SETTINGS[key] = value

		tween(button, {
			BackgroundColor3 = value and C.accent or C.element
		})

		tween(knob, {
			Position = value and UDim2.new(1, -19, 0, 3) or UDim2.fromOffset(3, 3)
		})

		if callback then
			callback(value)
		end
	end

	button.Activated:Connect(function()
		set(not SETTINGS[key])
	end)

	return set
end

local function action(parent, name, callback)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.element,
		Text = name,
		TextColor3 = C.text,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = false,
	}, parent)

	round(button, 7)

	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = C.accent})
	end)

	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = C.element})
	end)

	button.Activated:Connect(callback)

	return button
end

local function slider(parent, name, minimum, maximum, default, callback)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
	}, parent)

	local value = default

	label(row, name, 12).Size = UDim2.new(1, -45, 0, 20)

	local valueText = label(row, tostring(value), 11, C.accent)
	valueText.Position = UDim2.new(1, -40, 0, 0)
	valueText.Size = UDim2.fromOffset(40, 20)
	valueText.TextXAlignment = Enum.TextXAlignment.Right

	local bar = make("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = C.element,
	}, row)

	round(bar, 5)

	local fill = make("Frame", {
		Size = UDim2.new((value-minimum)/(maximum-minimum), 0, 1, 0),
		BackgroundColor3 = C.accent,
	}, bar)

	round(fill, 5)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.new((value-minimum)/(maximum-minimum), -6, .5, -6),
		BackgroundColor3 = C.text,
	}, bar)

	round(knob, 10)

	local function set(v)
		value = math.clamp(math.round(v), minimum, maximum)
		local a = (value-minimum)/(maximum-minimum)

		valueText.Text = tostring(value)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, -6, .5, -6)

		if callback then
			callback(value)
		end
	end

	local active = false

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			active = true

			set(minimum + math.clamp(
				(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,
				0, 1
				)*(maximum-minimum))
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if active and input.UserInputType == Enum.UserInputType.MouseMovement then
			local a = math.clamp(
				(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,
				0, 1
			)

			set(minimum+a*(maximum-minimum))
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			active = false
		end
	end)
end

--==================================================
-- PLAYER ESP
-- EVERY PLAYER INCLUDING YOU
--==================================================

local player_highlights = {}
local player_name_tags = {}

local ESP_BLUE = C.blue

local function removePlayerESP(character)
	if player_highlights[character] then
		player_highlights[character]:Destroy()
		player_highlights[character] = nil
	end

	if player_name_tags[character] then
		player_name_tags[character]:Destroy()
		player_name_tags[character] = nil
	end
end

local function createPlayerESP(targetPlayer, character)
	if not character then return end

	-- FULL BODY HIGHLIGHT
	if not player_highlights[character] then
		local highlight = Instance.new("Highlight")

		highlight.Name = "ChillHubPlayerESP"
		highlight.Adornee = character

		highlight.FillColor = ESP_BLUE
		highlight.OutlineColor = ESP_BLUE

		highlight.FillTransparency = 0.35
		highlight.OutlineTransparency = 0

		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = esp_folder

		player_highlights[character] = highlight
	end

	-- NAME ABOVE HEAD
	if SETTINGS.name_esp and not player_name_tags[character] then
		local head = character:FindFirstChild("Head")

		if head then
			local billboard = Instance.new("BillboardGui")

			billboard.Name = "ChillHubNameESP"
			billboard.Adornee = head
			billboard.Size = UDim2.fromOffset(220, 35)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = 1000
			billboard.Parent = esp_folder

			local name = Instance.new("TextLabel")

			name.Size = UDim2.fromScale(1, 1)
			name.BackgroundTransparency = 1

			name.Text = targetPlayer.DisplayName ..
				" (@" .. targetPlayer.Name .. ")"

			name.TextColor3 = ESP_BLUE
			name.TextStrokeColor3 = Color3.new(0, 0, 0)
			name.TextStrokeTransparency = 0.1
			name.TextSize = 13
			name.Font = Enum.Font.GothamBold

			name.Parent = billboard

			player_name_tags[character] = billboard
		end
	elseif not SETTINGS.name_esp then
		if player_name_tags[character] then
			player_name_tags[character]:Destroy()
			player_name_tags[character] = nil
		end
	end
end

local function updatePlayerESP()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		local character = targetPlayer.Character

		if SETTINGS.player_esp and character then
			createPlayerESP(targetPlayer, character)
		elseif character then
			removePlayerESP(character)
		end
	end

	for character in pairs(player_highlights) do
		if not character.Parent then
			removePlayerESP(character)
		end
	end
end

--==================================================
-- BRAINROT ESP
--==================================================

local brainrot_highlights = {}

local function updateBrainrotESP()
	local folder = workspace:FindFirstChild("Brainrots")
		or workspace:FindFirstChild("Brainrot")
		or workspace:FindFirstChild("BrainrotModels")

	if not folder then return end

	for _, object in ipairs(folder:GetChildren()) do
		if SETTINGS.brainrot_esp and object:IsA("Model") then
			if not brainrot_highlights[object] then
				local h = Instance.new("Highlight")

				h.Adornee = object
				h.FillColor = C.yellow
				h.OutlineColor = C.yellow
				h.FillTransparency = 0.55
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = esp_folder

				brainrot_highlights[object] = h
			end
		elseif brainrot_highlights[object] then
			brainrot_highlights[object]:Destroy()
			brainrot_highlights[object] = nil
		end
	end

	for object, h in pairs(brainrot_highlights) do
		if not object.Parent then
			h:Destroy()
			brainrot_highlights[object] = nil
		end
	end
end

--==================================================
-- BASE ESP
--==================================================

local base_highlights = {}

local function updateBaseESP()
	local folder = workspace:FindFirstChild("Bases")
	if not folder then return end

	for _, base in ipairs(folder:GetChildren()) do
		if SETTINGS.base_esp and base:IsA("Model") then
			local unlocked = base:GetAttribute("Unlocked") == true
			local color = unlocked and C.green or C.red

			if not base_highlights[base] then
				local h = Instance.new("Highlight")

				h.Adornee = base
				h.FillColor = color
				h.OutlineColor = color
				h.FillTransparency = 0.8
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = esp_folder

				base_highlights[base] = h
			else
				base_highlights[base].FillColor = color
				base_highlights[base].OutlineColor = color
			end
		elseif base_highlights[base] then
			base_highlights[base]:Destroy()
			base_highlights[base] = nil
		end
	end

	for base, h in pairs(base_highlights) do
		if not base.Parent then
			h:Destroy()
			base_highlights[base] = nil
		end
	end
end

--==================================================
-- BRAINROTS PAGE
--==================================================

local brainrotPage = tab("Brainrots", "◆")

section(
	brainrotPage,
	"Brainrot Controls",
	"Controls for your own game's systems."
)

local brainrotBox = container(brainrotPage, 155)

toggle(brainrotBox, "Auto Grab", "auto_grab", function(v)
	print("Auto Grab:", v)
end)

toggle(brainrotBox, "Sneak Steal", "sneak_steal", function(v)
	print("Sneak Steal:", v)
end)

action(brainrotBox, "Grab Nearest Brainrot", function()
	print("Connect this to your own server-authorized grab system.")
end)

local sneakBox = container(brainrotPage, 75)

label(sneakBox, "SNEAK STEAL OFFSET", 12, C.accent)

slider(sneakBox, "Vertical Offset", 0, 5, 2, function(v)
	SETTINGS.sneak_offset = v
end)

--==================================================
-- VISUALS PAGE
--==================================================

local visualPage = tab("Visuals", "◈")

section(
	visualPage,
	"ESP Settings",
	"Light-blue player highlights and name tags."
)

local visualBox = container(visualPage, 200)

toggle(visualBox, "Player ESP - Light Blue", "player_esp")
toggle(visualBox, "Player Names", "name_esp")
toggle(visualBox, "Brainrot ESP", "brainrot_esp")
toggle(visualBox, "Base ESP", "base_esp")

--==================================================
-- BASES PAGE
--==================================================

local basePage = tab("Bases", "▣")

section(
	basePage,
	"Base Information",
	"Reads attributes from your own game."
)

local baseBox = container(basePage, 120)

label(baseBox, "BASE STATUS", 12, C.accent)

local baseStatus = label(
	baseBox,
	"Waiting for workspace.Bases...",
	11,
	C.muted
)

baseStatus.Size = UDim2.new(1, 0, 0, 25)

local function getBaseStatus()
	local folder = workspace:FindFirstChild("Bases")

	if not folder then
		baseStatus.Text = "No Bases folder found."
		return
	end

	local lines = {}

	for _, base in ipairs(folder:GetChildren()) do
		local unlocked = base:GetAttribute("Unlocked") == true
		local unlockTime = base:GetAttribute("UnlockTime")

		if unlocked then
			table.insert(lines, base.Name .. " — UNLOCKED")

		elseif typeof(unlockTime) == "number" then
			local remaining = math.max(
				0,
				unlockTime - workspace:GetServerTimeNow()
			)

			table.insert(
				lines,
				base.Name .. " — " ..
					string.format(
						"%02d:%02d",
						math.floor(remaining / 60),
						math.floor(remaining % 60)
					)
			)
		else
			table.insert(lines, base.Name .. " — LOCKED")
		end
	end

	baseStatus.Text = table.concat(lines, "\n")
end

--==================================================
-- PLAYER PAGE
--==================================================

local playerPage = tab("Player", "◉")

section(
	playerPage,
	"Player Settings",
	"Movement settings for your own game."
)

local playerBox = container(playerPage, 180)

local walkSpeed = 16
local jumpPower = 50

slider(playerBox, "Walk Speed", 8, 100, 16, function(v)
	walkSpeed = v
end)

slider(playerBox, "Jump Power", 20, 150, 50, function(v)
	jumpPower = v
end)

toggle(playerBox, "Enable Speed", "speed_enabled")
toggle(playerBox, "Enable Jump", "jump_enabled")

--==================================================
-- DESYNC PAGE
--==================================================

local desyncPage = tab("Desync", "◉")

section(
	desyncPage,
	"Position Marker",
	"Local-only position marker demonstration."
)

local desyncBox = container(desyncPage, 100)

local marker

local function clearMarker()
	if marker then
		marker:Destroy()
		marker = nil
	end
end

toggle(desyncBox, "Enable Position Marker", "visual_desync", function(v)
	clearMarker()

	if not v then return end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then return end

	marker = Instance.new("Part")

	marker.Name = "LocalPositionMarker"
	marker.Size = Vector3.new(3, 0.15, 3)
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = C.accent
	marker.Transparency = 0.35
	marker.Position = root.Position - Vector3.new(0, 3, 0)
	marker.Parent = workspace

	print("Position marker enabled.")
end)

action(desyncBox, "Clear Position Marker", clearMarker)

--==================================================
-- SETTINGS PAGE
--==================================================

local settingsPage = tab("Settings", "⚙")

section(settingsPage, "Settings", "Customize Chill Hub.")

local settingsBox = container(settingsPage, 70)

local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldAmbient = Lighting.Ambient
local oldOutdoorAmbient = Lighting.OutdoorAmbient

toggle(settingsBox, "Fullbright", "fullbright", function(v)
	if v then
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
	else
		Lighting.Brightness = oldBrightness
		Lighting.ClockTime = oldClockTime
		Lighting.Ambient = oldAmbient
		Lighting.OutdoorAmbient = oldOutdoorAmbient
	end
end)

--==================================================
-- MAIN UPDATE LOOP
--==================================================

local updateTimer = 0

RunService.Heartbeat:Connect(function(dt)
	updateTimer += dt

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		if SETTINGS.speed_enabled then
			humanoid.WalkSpeed = walkSpeed
		end

		if SETTINGS.jump_enabled then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = jumpPower
		end
	end

	if updateTimer >= 0.25 then
		updateTimer = 0

		updatePlayerESP()
		updateBrainrotESP()
		updateBaseESP()
		getBaseStatus()
	end
end)

