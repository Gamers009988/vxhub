
-- Lua | AnnouncementScanner.client.lua | Roblox Studio

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local enabled = false
local busy = false
local collected_words = {}
local history = {}

local WORD_LIMIT = 3

-- FIND CODES UI
local function find_codes_ui()
    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("Frame") and object.Name == "Codes" then
            local redeem = object:FindFirstChild("CodeRedeem", true)
            local confirm = object:FindFirstChild("Confirm", true)

            if redeem and redeem:IsA("TextBox")
                and confirm and confirm:IsA("GuiButton") then
                return redeem, confirm
            end
        end
    end

    return nil, nil
end

-- MAIN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AnnouncementScanner"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(340, 300)
frame.Position = UDim2.new(0, 20, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- TITLE / DRAG HANDLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "ANNOUNCEMENT SNIPER"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- DRAGGING
local dragging = false
local drag_start
local start_position

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        drag_start = input.Position
        start_position = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - drag_start

        frame.Position = UDim2.new(
            start_position.X.Scale,
            start_position.X.Offset + delta.X,
            start_position.Y.Scale,
            start_position.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- TOGGLE BUTTON
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 38)
toggle.Position = UDim2.fromOffset(10, 45)
toggle.BackgroundColor3 = Color3.fromRGB(155, 40, 40)
toggle.Text = "SNIPER: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Parent = frame

local function corner_object(object)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = object
end

corner_object(toggle)

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.fromOffset(10, 88)
status.BackgroundTransparency = 1
status.Text = "Status: Disabled"
status.TextColor3 = Color3.fromRGB(180, 180, 180)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

-- LATEST MESSAGE
local latest = Instance.new("TextLabel")
latest.Size = UDim2.new(1, -20, 0, 65)
latest.Position = UDim2.fromOffset(10, 115)
latest.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
latest.TextColor3 = Color3.fromRGB(100, 255, 150)
latest.Text = "Waiting for announcement..."
latest.TextWrapped = true
latest.Font = Enum.Font.Code
latest.TextSize = 13
latest.Parent = frame

corner_object(latest)

-- ACTIVITY LOG
local log = Instance.new("TextLabel")
log.Size = UDim2.new(1, -20, 0, 105)
log.Position = UDim2.fromOffset(10, 190)
log.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
log.TextColor3 = Color3.fromRGB(220, 220, 220)
log.Text = "[SYSTEM] Ready"
log.TextWrapped = true
log.TextXAlignment = Enum.TextXAlignment.Left
log.TextYAlignment = Enum.TextYAlignment.Top
log.Font = Enum.Font.Code
log.TextSize = 12
log.Parent = frame

corner_object(log)

-- LOGGING
local function add_log(message)
    table.insert(history, message)

    while #history > 7 do
        table.remove(history, 1)
    end

    log.Text = table.concat(history, "\n")
end

-- SCANNER ON/OFF
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled

    if enabled then
        toggle.Text = "SNIPER: ON"
        toggle.BackgroundColor3 = Color3.fromRGB(35, 145, 65)
        status.Text = "Status: Listening"
        add_log("[SNIPER] ON")
    else
        toggle.Text = "SNIPER: OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(155, 40, 40)
        status.Text = "Status: Disabled"
        table.clear(collected_words)
        add_log("[SNIPER] OFF")
    end
end)

-- ANNOUNCEMENT PROCESSING
local function process_message(message)
    if not enabled or busy then
        return
    end

    message = tostring(message)

    if message == "" then
        return
    end

    latest.Text = message
    add_log("[MESSAGE FOUND] " .. message)

    for word in message:gmatch("%S+") do
        table.insert(collected_words, word)

        if #collected_words >= WORD_LIMIT then
            busy = true

            local code = table.concat(
                collected_words, " ", 1, WORD_LIMIT
            )

            table.clear(collected_words)

            add_log("[CODE READY] " .. code)

            local redeem, confirm = find_codes_ui()

            if not redeem or not confirm then
                status.Text = "Codes UI not found"
                add_log("[ERROR] UI missing")
                busy = false
                return
            end

            redeem.Text = code
            status.Text = "Three words entered"

            task.wait(0.2)

            if enabled and confirm.Parent then
                confirm:Activate()
                add_log("[CONFIRM] Activated")
            end

            task.wait(0.5)
            busy = false
            return
        end
    end

    status.Text = "Collecting: "
        .. #collected_words .. "/" .. WORD_LIMIT
end

TextChatService.MessageReceived:Connect(function(message)
    if enabled then
        process_message(message.Text)
    end
end)

-- K TO HIDE / SHOW
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.K then
        frame.Visible = not frame.Visible
    end
end)

add_log("[SYSTEM] Scanner initialized")
add_log("[SYSTEM] Press K to hide/show")
