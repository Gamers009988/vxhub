
-- Lua | FullCodeScanner.client.lua | Roblox Studio

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- SETTINGS
local WORD_LIMIT = 3
local enabled = false
local busy = false
local collected_words = {}
local latest_message = ""

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
gui.Name = "AnnouncementCodeScanner"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(340, 300)
frame.Position = UDim2.new(0, 20, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "ANNOUNCEMENT SNIPER"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- ON/OFF BUTTON
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 38)
toggle.Position = UDim2.fromOffset(10, 45)
toggle.BackgroundColor3 = Color3.fromRGB(155, 40, 40)
toggle.Text = "SNIPER: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Parent = frame

local function make_corner(object)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = object
end

make_corner(toggle)

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

make_corner(latest)

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

make_corner(log)

-- LOGGING
local history = {}

local function add_log(message)
    table.insert(history, message)

    while #history > 7 do
        table.remove(history, 1)
    end

    log.Text = table.concat(history, "\n")
end

-- TOGGLE
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

-- PROCESS ANNOUNCEMENT
local function process_message(message)
    if not enabled or busy then
        return
    end

    message = tostring(message)

    if message == "" then
        return
    end

    latest_message = message
    latest.Text = message

    add_log("[MESSAGE FOUND] " .. message)

    for word in message:gmatch("%S+") do
        table.insert(collected_words, word)

        if #collected_words >= WORD_LIMIT then
            busy = true

            local code = table.concat(collected_words, " ", 1, WORD_LIMIT)
            table.clear(collected_words)

            add_log("[CODE READY] " .. code)

            local redeem, confirm = find_codes_ui()

            if not redeem or not confirm then
                status.Text = "Codes UI not found"
                add_log("[ERROR] CodeRedeem/Confirm missing")
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

-- ROBLOX CHAT LISTENER
TextChatService.MessageReceived:Connect(function(message)
    if enabled then
        process_message(message.Text)
    end
end)

-- INITIAL CHECK
task.spawn(function()
    while gui.Parent do
        if enabled then
            local redeem, confirm = find_codes_ui()

            if not redeem or not confirm then
                status.Text = "Waiting for Codes UI..."
            end
        end

        task.wait(2)
    end
end)

add_log("[SYSTEM] Scanner initialized")
add_log("[SYSTEM] Waiting for activation")
