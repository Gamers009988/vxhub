
-- Luau, LocalItemManager.client.lua
-- Runtime: Roblox LocalScript, StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local OWNER_ID = 4616869387

if LocalPlayer.UserId ~= OWNER_ID then
    warn("[ITEM MANAGER] Owner verification failed")
    return
end

local player_gui = LocalPlayer:WaitForChild("PlayerGui")

-- GUI

local gui = Instance.new("ScreenGui")
gui.Name = "LocalItemManager"
gui.ResetOnSpawn = false
gui.Parent = player_gui

local function create(class, props, parent)
    local object = Instance.new(class)

    for key, value in pairs(props) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local main = create("Frame", {
    Size = UDim2.fromOffset(680, 480),
    Position = UDim2.new(0.5, -340, 0.5, -240),
    BackgroundColor3 = Color3.fromRGB(22, 23, 29),
    BorderSizePixel = 0
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 10)
}, main)

create("TextLabel", {
    Size = UDim2.new(1, -60, 0, 45),
    Position = UDim2.fromOffset(15, 5),
    BackgroundTransparency = 1,
    Text = "LOCAL ITEM MANAGER",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left
}, main)

local close = create("TextButton", {
    Position = UDim2.new(1, -42, 0, 10),
    Size = UDim2.fromOffset(30, 30),
    Text = "X",
    BackgroundColor3 = Color3.fromRGB(160, 45, 45),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14
}, main)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local status = create("TextLabel", {
    Position = UDim2.fromOffset(15, 48),
    Size = UDim2.new(1, -30, 0, 25),
    BackgroundTransparency = 1,
    Text = "OWNER VERIFIED | " .. OWNER_ID,
    TextColor3 = Color3.fromRGB(90, 190, 130),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, main)

-- ITEM LIST

local item_panel = create("ScrollingFrame", {
    Position = UDim2.fromOffset(15, 90),
    Size = UDim2.fromOffset(420, 340),
    BackgroundColor3 = Color3.fromRGB(30, 31, 39),
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new()
}, main)

create("UICorner", {
    CornerRadius = UDim.new(0, 7)
}, item_panel)

local layout = create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, item_panel)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    item_panel.CanvasSize = UDim2.fromOffset(
        0,
        layout.AbsoluteContentSize.Y + 10
    )
end)

-- DETAILS PANEL

local details = create("Frame", {
    Position = UDim2.fromOffset(450, 90),
    Size = UDim2.fromOffset(215, 340),
    BackgroundColor3 = Color3.fromRGB(30, 31, 39),
    BorderSizePixel = 0
}, main)

create("UICorner", {
    CornerRadius = UDim.new(0, 7)
}, details)

local selected_label = create("TextLabel", {
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.new(1, -20, 0, 65),
    BackgroundTransparency = 1,
    Text = "NO ITEM SELECTED",
    TextColor3 = Color3.new(1, 1, 1),
    TextWrapped = true,
    Font = Enum.Font.GothamBold,
    TextSize = 14
}, details)

local function make_button(text, y, color)
    return create("TextButton", {
        Position = UDim2.fromOffset(10, y),
        Size = UDim2.new(1, -20, 0, 38),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12
    }, details)
end

local scan_button = make_button(
    "SCAN AGAIN", 90, Color3.fromRGB(45, 110, 180)
)

local inspect_button = make_button(
    "INSPECT ITEM", 140, Color3.fromRGB(65, 80, 110)
)

local give_button = make_button(
    "GIVE TO MYSELF", 190, Color3.fromRGB(40, 145, 90)
)

local selected_tool = nil

-- RECURSIVE SCANNER

local function scan()
    for _, child in ipairs(item_panel:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    selected_tool = nil
    selected_label.Text = "NO ITEM SELECTED"

    local locations = {
        workspace,
        ReplicatedStorage,
        StarterPack,
        StarterGui,
        LocalPlayer:WaitForChild("Backpack")
    }

    if LocalPlayer.Character then
        table.insert(locations, LocalPlayer.Character)
    end

    local found = {}

    for _, location in ipairs(locations) do
        for _, object in ipairs(location:GetDescendants()) do
            if object:IsA("Tool") then
                found[object] = true
            end
        end
    end

    -- ServerStorage visibility diagnostic.
    -- Its contents normally cannot replicate to LocalScripts.

    local server_storage = game:GetService("ServerStorage")

    local accessible, server_objects = pcall(function()
        return server_storage:GetDescendants()
    end)

    if accessible then
        for _, object in ipairs(server_objects) do
            if object:IsA("Tool") then
                found[object] = true
            end
        end
    end

    local sorted = {}

    for tool in pairs(found) do
        table.insert(sorted, tool)
    end

    table.sort(sorted, function(a, b)
        return a:GetFullName():lower() < b:GetFullName():lower()
    end)

    for index, tool in ipairs(sorted) do
        local button = create("TextButton", {
            Name = "Item_" .. index,
            LayoutOrder = index,
            Size = UDim2.new(1, -10, 0, 46),
            BackgroundColor3 = Color3.fromRGB(43, 45, 55),
            Text = "  " .. tool.Name .. "\n  " .. tool:GetFullName(),
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        }, item_panel)

        create("UICorner", {
            CornerRadius = UDim.new(0, 5)
        }, button)

        button.MouseButton1Click:Connect(function()
            selected_tool = tool
            selected_label.Text =
                "SELECTED ITEM\n" .. tool.Name

            status.Text = "SELECTED: " .. tool.Name
        end)
    end

    status.Text = "SCAN COMPLETE | " .. #sorted .. " TOOLS FOUND"

    print("--------------------------------")
    print("[ITEM MANAGER] SCAN COMPLETE")
    print("[ITEM MANAGER] Tools found:", #sorted)
    print("[ITEM MANAGER] ServerStorage accessible:", accessible)
    print("--------------------------------")
end

-- INSPECT

inspect_button.MouseButton1Click:Connect(function()
    if not selected_tool or not selected_tool.Parent then
        status.Text = "SELECT AN ITEM FIRST"
        return
    end

    print("[ITEM MANAGER] ITEM:", selected_tool.Name)
    print("[ITEM MANAGER] PATH:", selected_tool:GetFullName())

    status.Text = "INSPECTED: " .. selected_tool.Name
end)

-- GIVE TO SELF
-- Only makes a local copy of an accessible Tool.

give_button.MouseButton1Click:Connect(function()
    if not selected_tool or not selected_tool.Parent then
        status.Text = "SELECT AN ITEM FIRST"
        return
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if not backpack then
        status.Text = "BACKPACK NOT FOUND"
        return
    end

    if selected_tool:IsDescendantOf(backpack) then
        status.Text = "ALREADY IN BACKPACK"
        return
    end

    local character = LocalPlayer.Character

    if character and selected_tool:IsDescendantOf(character) then
        status.Text = "ALREADY EQUIPPED"
        return
    end

    local success, result = pcall(function()
        local clone = selected_tool:Clone()
        clone.Parent = backpack
    end)

    if success then
        status.Text = "LOCAL COPY CREATED"
        print("[ITEM MANAGER] Local copy:", selected_tool.Name)
    else
        status.Text = "COPY FAILED: " .. tostring(result)
    end
end)

-- INITIAL SCAN

scan()

print("[ITEM MANAGER] Initialized")
print("[ITEM MANAGER] Owner:", LocalPlayer.UserId)
