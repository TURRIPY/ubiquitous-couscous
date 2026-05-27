local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- HTTP request wrapper (exploit compatibility)
local custom_request = (((syn and syn.request) or (http and http.request)) or request) or http_request
local set_clipboard = setclipboard or (syn and syn.setclipboard) or writeclipboard

local function performRequest(url, method, body)
    if not custom_request then return false, "No HTTP support" end
    local options = {
        Url = url,
        Method = method,
        Headers = { ["Content-Type"] = "application/json" }
    }
    if body then options.Body = body end
    local success, result = pcall(function() return custom_request(options) end)
    if success and result and result.StatusCode == 200 then
        return true, result.Body
    else
        return false, "Error"
    end
end

-- Config & Themes
local SERVER_URL      = "https://server-h6ur.onrender.com"
local PUBLISH_URL     = SERVER_URL .. "/send"
local HISTORY_URL     = SERVER_URL .. "/history?serverId=" .. game.JobId
local HEARTBEAT_URL   = SERVER_URL .. "/heartbeat"
local ONLINE_URL      = SERVER_URL .. "/online?serverId="  .. game.JobId
local STATUS_URL      = SERVER_URL .. "/status?serverId="  .. game.JobId

local seenMessages    = {}
local userColors      = {}
local currentNickname = LocalPlayer.Name

-- Theme persistence
local SETTINGS_FILE = "chitchat_settings.json"
local function loadSavedTheme()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)
    if ok and data and data.theme then return data.theme end
    return "dark"
end
local function saveTheme(themeName)
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode({ theme = themeName }))
    end)
end
local savedThemeName = (readfile and writefile) and loadSavedTheme() or "dark"

-- Flood protection
local lastSendTime = 0
local SEND_COOLDOWN = 1.0

local Themes = {
    dark = {
        MainBg       = Color3.fromRGB(20,  20,  24),
        MyBubble     = Color3.fromRGB(35,  75,  140),
        OtherBubble  = Color3.fromRGB(40,  40,  48),
        TextBg       = Color3.fromRGB(35,  35,  43),
        HintBg       = Color3.fromRGB(28,  28,  34),
        SystemBubble = Color3.fromRGB(45,  45,  50),
        ErrorBubble  = Color3.fromRGB(60,  25,  25),
        ScrollBar    = Color3.fromRGB(80,  80,  90),
        IdText       = Color3.fromRGB(100, 100, 110),
    },
    aqua = {
        MainBg       = Color3.fromRGB(15,  28,  33),
        MyBubble     = Color3.fromRGB(0,   134, 139),
        OtherBubble  = Color3.fromRGB(22,  50,  56),
        TextBg       = Color3.fromRGB(25,  45,  50),
        HintBg       = Color3.fromRGB(20,  35,  40),
        SystemBubble = Color3.fromRGB(18,  42,  48),
        ErrorBubble  = Color3.fromRGB(50,  20,  20),
        ScrollBar    = Color3.fromRGB(0,   100, 110),
        IdText       = Color3.fromRGB(60,  140, 145),
    },
    sakura = {
        MainBg       = Color3.fromRGB(28,  20,  24),
        MyBubble     = Color3.fromRGB(160, 70,  110),
        OtherBubble  = Color3.fromRGB(55,  35,  45),
        TextBg       = Color3.fromRGB(43,  32,  38),
        HintBg       = Color3.fromRGB(36,  25,  30),
        SystemBubble = Color3.fromRGB(50,  38,  44),
        ErrorBubble  = Color3.fromRGB(65,  22,  30),
        ScrollBar    = Color3.fromRGB(140, 60,  90),
        IdText       = Color3.fromRGB(160, 90,  120),
    },
    green = {
        MainBg       = Color3.fromRGB(15,  24,  18),
        MyBubble     = Color3.fromRGB(30,  120, 60),
        OtherBubble  = Color3.fromRGB(25,  45,  30),
        TextBg       = Color3.fromRGB(22,  38,  26),
        HintBg       = Color3.fromRGB(18,  30,  20),
        SystemBubble = Color3.fromRGB(20,  40,  25),
        ErrorBubble  = Color3.fromRGB(55,  20,  20),
        ScrollBar    = Color3.fromRGB(40,  110, 60),
        IdText       = Color3.fromRGB(70,  140, 85),
    },
    midnight = {
        MainBg       = Color3.fromRGB(10,  10,  20),
        MyBubble     = Color3.fromRGB(60,  40,  160),
        OtherBubble  = Color3.fromRGB(28,  28,  50),
        TextBg       = Color3.fromRGB(20,  20,  38),
        HintBg       = Color3.fromRGB(15,  15,  30),
        SystemBubble = Color3.fromRGB(30,  30,  55),
        ErrorBubble  = Color3.fromRGB(60,  20,  30),
        ScrollBar    = Color3.fromRGB(70,  50,  150),
        IdText       = Color3.fromRGB(100, 85,  180),
    },
    sunset = {
        MainBg       = Color3.fromRGB(28,  18,  14),
        MyBubble     = Color3.fromRGB(190, 80,  30),
        OtherBubble  = Color3.fromRGB(50,  30,  22),
        TextBg       = Color3.fromRGB(42,  28,  20),
        HintBg       = Color3.fromRGB(34,  22,  16),
        SystemBubble = Color3.fromRGB(48,  32,  22),
        ErrorBubble  = Color3.fromRGB(65,  18,  18),
        ScrollBar    = Color3.fromRGB(160, 70,  30),
        IdText       = Color3.fromRGB(180, 110, 60),
    },
    slate = {
        MainBg       = Color3.fromRGB(22,  26,  30),
        MyBubble     = Color3.fromRGB(50,  100, 140),
        OtherBubble  = Color3.fromRGB(38,  44,  52),
        TextBg       = Color3.fromRGB(32,  38,  44),
        HintBg       = Color3.fromRGB(26,  30,  36),
        SystemBubble = Color3.fromRGB(40,  46,  54),
        ErrorBubble  = Color3.fromRGB(60,  22,  22),
        ScrollBar    = Color3.fromRGB(70,  100, 130),
        IdText       = Color3.fromRGB(100, 130, 155),
    },
}
local activeTheme = Themes[savedThemeName] or Themes.dark

local CommandHints = {
    { cmd = "/clear",           desc = "Clear local chat",                        fill = "/clear" },
    { cmd = "/nick ",           desc = "Change nickname (/nick reset to revert)", fill = "/nick " },
    { cmd = "/online",          desc = "Show online users in chat",               fill = "/online" },
    { cmd = "/status",          desc = "Server statistics",                       fill = "/status" },
    { cmd = "/theme dark",      desc = "Dark theme",                              fill = "/theme dark" },
    { cmd = "/theme aqua",      desc = "Aqua theme",                              fill = "/theme aqua" },
    { cmd = "/theme sakura",    desc = "Sakura theme",                            fill = "/theme sakura" },
    { cmd = "/theme green",     desc = "Green theme",                             fill = "/theme green" },
    { cmd = "/theme midnight",  desc = "Midnight theme",                          fill = "/theme midnight" },
    { cmd = "/theme sunset",    desc = "Sunset theme",                            fill = "/theme sunset" },
    { cmd = "/theme slate",     desc = "Slate theme",                             fill = "/theme slate" },
}

local function getNameColor(username)
    if userColors[username] then return userColors[username] end
    local colors = {
        "rgb(255,105,105)", "rgb(105,255,105)", "rgb(110,160,255)",
        "rgb(255,205,110)", "rgb(210,110,255)", "rgb(110,255,255)"
    }
    math.randomseed(os.time() + #username)
    userColors[username] = colors[math.random(1, #colors)]
    return userColors[username]
end

local myToken = tostring(os.clock())
_G.ChitChatToken = myToken
local function isAlive() return _G.ChitChatToken == myToken end

if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Comandlet") then
    LocalPlayer.PlayerGui.RobloxRenderChat:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Comandlet"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main window (CanvasGroup for unified transparency)
local MainFrame = Instance.new("CanvasGroup")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 280)
MainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
MainFrame.BackgroundColor3 = activeTheme.MainBg
MainFrame.BackgroundTransparency = 0.2
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Server ID + Ping
local IdLabel = Instance.new("TextLabel")
IdLabel.Name = "JobIdInChat"
IdLabel.Size = UDim2.new(0.7, 0, 0, 20)
IdLabel.Position = UDim2.new(0, 10, 0, 5)
IdLabel.BackgroundTransparency = 1
IdLabel.TextColor3 = activeTheme.IdText
IdLabel.Font = Enum.Font.Code
IdLabel.TextSize = 10
IdLabel.Text = "Server ID: " .. game.JobId
IdLabel.TextXAlignment = Enum.TextXAlignment.Left
IdLabel.TextTruncate = Enum.TextTruncate.AtEnd
IdLabel.Parent = MainFrame

local PingLabel = Instance.new("TextLabel")
PingLabel.Name = "PingLabel"
PingLabel.Size = UDim2.new(0.3, -10, 0, 20)
PingLabel.Position = UDim2.new(0.7, 0, 0, 5)
PingLabel.BackgroundTransparency = 1
PingLabel.TextColor3 = activeTheme.IdText
PingLabel.Font = Enum.Font.Code
PingLabel.TextSize = 10
PingLabel.Text = "ping: —"
PingLabel.TextXAlignment = Enum.TextXAlignment.Right
PingLabel.TextTruncate = Enum.TextTruncate.AtEnd
PingLabel.Parent = MainFrame

-- Chat log
local ChatLog = Instance.new("ScrollingFrame")
ChatLog.Size = UDim2.new(1, -20, 1, -80)
ChatLog.Position = UDim2.new(0, 10, 0, 30)
ChatLog.BackgroundTransparency = 1
ChatLog.BorderSizePixel = 0
ChatLog.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatLog.ScrollBarThickness = 4
ChatLog.ScrollBarImageColor3 = activeTheme.ScrollBar
ChatLog.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ChatLog

-- Input field
local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 0, 36)
TextBox.Position = UDim2.new(0, 10, 1, -45)
TextBox.BackgroundColor3 = activeTheme.TextBg
TextBox.BackgroundTransparency = 0
TextBox.BorderSizePixel = 0
TextBox.TextColor3 = Color3.fromRGB(245, 245, 245)
TextBox.TextSize = 14
TextBox.Font = Enum.Font.SourceSans
TextBox.Text = ""
TextBox.PlaceholderText = "Type a message..."
TextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 135)
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.ClearTextOnFocus = false
TextBox.Parent = MainFrame

local Pad = Instance.new("UIPadding")
Pad.PaddingLeft = UDim.new(0, 12)
Pad.PaddingRight = UDim.new(0, 12)
Pad.Parent = TextBox

local TBCorner = Instance.new("UICorner")
TBCorner.CornerRadius = UDim.new(0, 8)
TBCorner.Parent = TextBox

-- Command hints panel
local HintFrame = Instance.new("ScrollingFrame")
HintFrame.Size = UDim2.new(1, -20, 0, 0)
HintFrame.Position = UDim2.new(0, 10, 1, -50)
HintFrame.AnchorPoint = Vector2.new(0, 1)
HintFrame.BackgroundColor3 = activeTheme.HintBg
HintFrame.BackgroundTransparency = 0.1
HintFrame.ClipsDescendants = true
HintFrame.Visible = false
HintFrame.ScrollBarThickness = 3
HintFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 165)
HintFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
HintFrame.ScrollingDirection = Enum.ScrollingDirection.Y
HintFrame.Parent = MainFrame

local HintCorner = Instance.new("UICorner")
HintCorner.CornerRadius = UDim.new(0, 8)
HintCorner.Parent = HintFrame

local HintListLayout = Instance.new("UIListLayout")
HintListLayout.Padding = UDim.new(0, 2)
HintListLayout.Parent = HintFrame

local HintPadding = Instance.new("UIPadding")
HintPadding.PaddingLeft   = UDim.new(0, 8)
HintPadding.PaddingRight  = UDim.new(0, 8)
HintPadding.PaddingTop    = UDim.new(0, 6)
HintPadding.PaddingBottom = UDim.new(0, 6)
HintPadding.Parent = HintFrame

-- Resize handle (bottom-right corner)
local MIN_W, MIN_H = 240, 200
local MAX_W, MAX_H = 700, 600

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Name = "ResizeHandle"
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.BorderSizePixel = 0
ResizeHandle.Text = ""
ResizeHandle.ZIndex = 10
ResizeHandle.Parent = MainFrame

local ResizeIcon = Instance.new("TextLabel")
ResizeIcon.Size = UDim2.new(1, 0, 1, 0)
ResizeIcon.BackgroundTransparency = 1
ResizeIcon.Text = "･"
ResizeIcon.TextColor3 = Color3.fromRGB(100, 100, 115)
ResizeIcon.TextSize = 14
ResizeIcon.Font = Enum.Font.SourceSans
ResizeIcon.ZIndex = 11
ResizeIcon.Parent = ResizeHandle

local resizing = false
local resizeStart, startSize

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = MainFrame.AbsoluteSize
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newW = math.clamp(startSize.X + delta.X, MIN_W, MAX_W)
        local newH = math.clamp(startSize.Y + delta.Y, MIN_H, MAX_H)
        MainFrame.Size = UDim2.new(0, newW, 0, newH)
    end
end)

-- Toggle button (bottom-left, draggable)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0, 12, 1, -56)
ToggleBtn.AnchorPoint = Vector2.new(0, 1)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.15
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "*"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.ZIndex = 100
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local tbDragging, tbDragInput, tbDragStart, tbStartPos = false, nil, nil, nil

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tbDragging = true
        tbDragStart = input.Position
        tbStartPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then tbDragging = false end
        end)
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        tbDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == tbDragInput and tbDragging then
        local delta = input.Position - tbDragStart
        ToggleBtn.Position = UDim2.new(tbStartPos.X.Scale, tbStartPos.X.Offset + delta.X, tbStartPos.Y.Scale, tbStartPos.Y.Offset + delta.Y)
    end
end)

-- Main window drag
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local dragSpeed = 0.10

MainFrame.InputBegan:Connect(function(input)
    if resizing then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and not resizing then
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(MainFrame, TweenInfo.new(dragSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end
end)

-- Toggle visibility (Ctrl or button)
local chatVisible = true

local function toggleChat()
    chatVisible = not chatVisible
    MainFrame.Visible = chatVisible
    ToggleBtn.BackgroundTransparency = chatVisible and 0.15 or 0.55
end

ToggleBtn.MouseButton1Click:Connect(function()
    if tbDragging then return end
    toggleChat()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        toggleChat()
    end
end)

-- Auto-fade after 5s of inactivity
local lastActivity = os.time()
local isHovered    = false
local isFaded      = false

local function setFaded(fade)
    if isFaded == fade then return end
    isFaded = fade
    local t = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if fade then
        TweenService:Create(MainFrame, t, {BackgroundTransparency = 0.92}):Play()
        TweenService:Create(TextBox,   t, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(IdLabel,   t, {TextTransparency = 1}):Play()
        TweenService:Create(PingLabel, t, {TextTransparency = 1}):Play()
        TweenService:Create(ChatLog,   t, {ScrollBarImageTransparency = 1}):Play()
        for _, row in ipairs(ChatLog:GetChildren()) do
            if row:IsA("Frame") then
                for _, bubble in ipairs(row:GetChildren()) do
                    if bubble:IsA("TextButton") and bubble.Name ~= "OtherBubble" then
                        TweenService:Create(bubble, t, {BackgroundTransparency = 0.85}):Play()
                        local lbl = bubble:FindFirstChildWhichIsA("TextLabel")
                        if lbl then TweenService:Create(lbl, t, {TextTransparency = 0.75}):Play() end
                    end
                end
            end
        end
    else
        TweenService:Create(MainFrame, t, {BackgroundTransparency = 0.2}):Play()
        TweenService:Create(TextBox,   t, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        TweenService:Create(IdLabel,   t, {TextTransparency = 0}):Play()
        TweenService:Create(PingLabel, t, {TextTransparency = 0}):Play()
        TweenService:Create(ChatLog,   t, {ScrollBarImageTransparency = 0}):Play()
        for _, row in ipairs(ChatLog:GetChildren()) do
            if row:IsA("Frame") then
                for _, bubble in ipairs(row:GetChildren()) do
                    if bubble:IsA("TextButton") and bubble.Name ~= "OtherBubble" then
                        TweenService:Create(bubble, t, {BackgroundTransparency = 0}):Play()
                        local lbl = bubble:FindFirstChildWhichIsA("TextLabel")
                        if lbl then TweenService:Create(lbl, t, {TextTransparency = 0}):Play() end
                    end
                end
            end
        end
    end
end

local function wakeUp()
    lastActivity = os.time()
    setFaded(false)
end

MainFrame.MouseEnter:Connect(function() isHovered = true;  wakeUp() end)
MainFrame.MouseLeave:Connect(function() isHovered = false; lastActivity = os.time() end)
TextBox.Focused:Connect(wakeUp)

coroutine.wrap(function()
    while isAlive() do
        task.wait(1)
        if not isHovered and not TextBox:IsFocused() and (os.time() - lastActivity) >= 5 then
            setFaded(true)
        end
    end
end)()

-- Speech bubble above player head
local ChatService = game:GetService("Chat")

local function showSpeechBubble(playerName, text)
    local targetPlayer
    if playerName == currentNickname then
        targetPlayer = LocalPlayer
    else
        targetPlayer = Players:FindFirstChild(playerName)
    end
    if not targetPlayer then return end

    local character = targetPlayer.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    pcall(function()
        ChatService:Chat(head, text, Enum.ChatColor.White)
    end)
end

-- Append message bubble to chat log
local function appendMessage(sender, text, isError)
    if not text or text == "" then return end
    wakeUp()

    local RowFrame = Instance.new("Frame")
    RowFrame.BackgroundTransparency = 1
    RowFrame.Size = UDim2.new(1, 0, 0, 0)
    RowFrame.AutomaticSize = Enum.AutomaticSize.Y

    local Bubble = Instance.new("TextButton")
    Bubble.Text = ""
    Bubble.BorderSizePixel = 0
    Bubble.AutomaticSize = Enum.AutomaticSize.XY
    Bubble.Parent = RowFrame

    local BubbleCorner = Instance.new("UICorner")
    BubbleCorner.CornerRadius = UDim.new(0, 8)
    BubbleCorner.Parent = Bubble

    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MinSize = Vector2.new(40, 28)
    SizeConstraint.MaxSize = Vector2.new(240, 9999)
    SizeConstraint.Parent = Bubble

    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Size = UDim2.new(0, 0, 0, 0)
    ContentLabel.AutomaticSize = Enum.AutomaticSize.XY
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Font = Enum.Font.SourceSans
    ContentLabel.TextSize = 15
    ContentLabel.TextWrapped = true
    ContentLabel.RichText = true
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.Parent = Bubble

    local TextPad = Instance.new("UIPadding")
    TextPad.PaddingLeft   = UDim.new(0, 10)
    TextPad.PaddingRight  = UDim.new(0, 10)
    TextPad.PaddingTop    = UDim.new(0, 6)
    TextPad.PaddingBottom = UDim.new(0, 6)
    TextPad.Parent = ContentLabel

    local foundLink = text:match("(https?://%S+)")
    local processedText = text
    if foundLink then
        processedText = text:gsub(foundLink, "<font color='rgb(100,180,255)'><u>" .. foundLink .. "</u></font>")
        Bubble.MouseButton1Click:Connect(function()
            if set_clipboard then set_clipboard(foundLink) end
        end)
    end

    if isError then
        Bubble.Name = "ErrorBubble"
        Bubble.BackgroundColor3 = activeTheme.ErrorBubble
        ContentLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        ContentLabel.Text = "[ERROR] " .. processedText
        Bubble.Position = UDim2.new(0, 5, 0, 0)
    elseif sender == "SYSTEM" then
        Bubble.Name = "SystemBubble"
        Bubble.BackgroundColor3 = activeTheme.SystemBubble
        ContentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ContentLabel.Text = "[SYSTEM] " .. processedText
        Bubble.Position = UDim2.new(0, 5, 0, 0)
    else
        if sender == currentNickname or sender == LocalPlayer.Name then
            Bubble.Name = "MyOwnBubble"
            Bubble.BackgroundColor3 = activeTheme.MyBubble
            Bubble.AnchorPoint = Vector2.new(1, 0)
            Bubble.Position = UDim2.new(1, -5, 0, 0)
            ContentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ContentLabel.Text = processedText
        else
            Bubble.Name = "OtherBubble"
            Bubble.BackgroundColor3 = activeTheme.OtherBubble
            Bubble.AnchorPoint = Vector2.new(0, 0)
            Bubble.Position = UDim2.new(0, 5, 0, 0)
            local colorString = getNameColor(sender)
            ContentLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
            ContentLabel.Text = "<font color='" .. colorString .. "'><b>" .. sender .. ":</b></font> " .. processedText
        end
    end

    local isAtBottom = (ChatLog.CanvasSize.Y.Offset == 0)
        or ((ChatLog.CanvasPosition.Y + ChatLog.AbsoluteWindowSize.Y) >= (ChatLog.CanvasSize.Y.Offset - 40))
    local isMine = (sender == currentNickname or sender == LocalPlayer.Name)

    RowFrame.Parent = ChatLog

    task.defer(function()
        local newHeight = UIListLayout.AbsoluteContentSize.Y + 10
        ChatLog.CanvasSize = UDim2.new(0, 0, 0, newHeight)
        if isAtBottom or isMine then
            ChatLog.CanvasPosition = Vector2.new(0, newHeight)
        end
    end)
end

-- Command hints logic
local function updateCommandHints(text)
    for _, child in ipairs(HintFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if not text:match("^/") then
        HintFrame.Visible = false
        return
    end

    local cleanText = text:lower()
    local addedCount = 0

    for _, item in ipairs(CommandHints) do
        local match = cleanText == "/"
            or item.cmd:sub(1, #cleanText) == cleanText
            or (cleanText:sub(1, 6) == "/theme" and item.cmd:sub(1, 6) == "/theme")

        if match then
            addedCount = addedCount + 1
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 22)
            Button.BackgroundTransparency = 1
            Button.Font = Enum.Font.SourceSans
            Button.TextSize = 13
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.RichText = true
            Button.TextColor3 = Color3.fromRGB(180, 180, 190)
            Button.Text = "<font color='rgb(255,255,255)'><b>" .. item.cmd .. "</b></font>  —  " .. item.desc
            Button.Parent = HintFrame

            Button.MouseButton1Click:Connect(function()
                TextBox.Text = item.fill
                HintFrame.Visible = false
                TextBox:CaptureFocus()
            end)
        end
    end

    if addedCount > 0 then
        HintFrame.Visible = true
        local itemHeight  = (addedCount * 22) + 12  -- full content height
        -- Max height: from ChatLog top to TextBox
        local maxHeight   = MainFrame.AbsoluteSize.Y - 80 - 30  -- 80 = TextBox zone, 30 = top bar
        local clampedH    = math.clamp(itemHeight, 0, math.max(maxHeight, 40))
        HintFrame.CanvasSize = UDim2.new(0, 0, 0, itemHeight)
        TweenService:Create(HintFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, -20, 0, clampedH)}):Play()
    else
        HintFrame.Visible = false
    end
end

TextBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateCommandHints(TextBox.Text)
end)

TextBox.FocusLost:Connect(function()
    task.wait(0.2)
    if not TextBox:IsFocused() then
        HintFrame.Visible = false
    end
end)

-- Send logic
local function applyTheme(theme, themeName)
    activeTheme = theme
    if themeName then saveTheme(themeName) end
    local t = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(MainFrame,  t, {BackgroundColor3 = activeTheme.MainBg}):Play()
    TweenService:Create(TextBox,    t, {BackgroundColor3 = activeTheme.TextBg}):Play()
    TweenService:Create(HintFrame,  t, {BackgroundColor3 = activeTheme.HintBg}):Play()
    TweenService:Create(IdLabel,    t, {TextColor3 = activeTheme.IdText}):Play()
    TweenService:Create(PingLabel,  t, {TextColor3 = activeTheme.IdText}):Play()
    ChatLog.ScrollBarImageColor3 = activeTheme.ScrollBar
    for _, row in ipairs(ChatLog:GetChildren()) do
        if row:IsA("Frame") then
            local myB    = row:FindFirstChild("MyOwnBubble")
            local otherB = row:FindFirstChild("OtherBubble")
            local sysB   = row:FindFirstChild("SystemBubble")
            local errB   = row:FindFirstChild("ErrorBubble")
            if myB    then TweenService:Create(myB,    t, {BackgroundColor3 = activeTheme.MyBubble}):Play() end
            if otherB then TweenService:Create(otherB, t, {BackgroundColor3 = activeTheme.OtherBubble}):Play() end
            if sysB   then TweenService:Create(sysB,   t, {BackgroundColor3 = activeTheme.SystemBubble}):Play() end
            if errB   then TweenService:Create(errB,   t, {BackgroundColor3 = activeTheme.ErrorBubble}):Play() end
        end
    end
end

TextBox.FocusLost:Connect(function(enterPressed)
    if not (enterPressed and TextBox.Text ~= "") then return end
    local currentText = TextBox.Text
    TextBox.Text = ""
    HintFrame.Visible = false

    -- /clear
    if currentText:lower() == "/clear" then
        for _, child in ipairs(ChatLog:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        ChatLog.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    -- /nick
    if currentText:lower():sub(1, 5) == "/nick" then
        local newNick = currentText:sub(7)
        if newNick and newNick ~= "" then
            currentNickname = (newNick:lower() == "reset") and LocalPlayer.Name or newNick
        end
        return
    end

    -- /theme
    if currentText:lower():sub(1, 6) == "/theme" then
        local themeName = currentText:sub(8):lower():gsub("%s+", "")
        if Themes[themeName] then
            applyTheme(Themes[themeName], themeName)
        else
            appendMessage("SYSTEM", "Theme not found. Available: dark, aqua, sakura, green, midnight, sunset, slate", true)
        end
        return
    end

    -- /online
    if currentText:lower() == "/online" then
        coroutine.wrap(function()
            local ok, body = performRequest(ONLINE_URL, "GET", nil)
            if ok then
                local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
                if ok2 and data then
                    local names = table.concat(data.users, ", ")
                    appendMessage("SYSTEM", "Online (" .. data.count .. "): " .. (names ~= "" and names or "nobody"))
                else
                    appendMessage("SYSTEM", "Failed to parse response", true)
                end
            else
                appendMessage("SYSTEM", "Request error: /online", true)
            end
        end)()
        return
    end

    -- /status
    if currentText:lower() == "/status" then
        coroutine.wrap(function()
            local ok, body = performRequest(STATUS_URL, "GET", nil)
            if ok then
                local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
                if ok2 and data then
                    local uptimeStr = data.uptimeSeconds and (math.floor(data.uptimeSeconds / 60) .. "m " .. (data.uptimeSeconds % 60) .. "s") or "n/a"
                    appendMessage("SYSTEM",
                        "Online: " .. data.onlineCount ..
                        " | Messages: " .. data.messageCount ..
                        " | Uptime: " .. uptimeStr ..
                        " | Servers: " .. (data.totalServers or "n/a")
                    )
                else
                    appendMessage("SYSTEM", "Failed to parse response", true)
                end
            else
                appendMessage("SYSTEM", "Request error: /status", true)
            end
        end)()
        return
    end

    -- Send message
    local now = os.clock()
    if now - lastSendTime < SEND_COOLDOWN then
        appendMessage("SYSTEM", "Please wait before sending another message.", true)
        return
    end
    lastSendTime = now

    local payload = { user = currentNickname, msg = currentText, serverId = game.JobId }
    coroutine.wrap(function()
        local jsonPayload = HttpService:JSONEncode(payload)
        local success, _ = performRequest(PUBLISH_URL, "POST", jsonPayload)
        if not success then
            appendMessage("SYSTEM", "Failed to send message", true)
        end
    end)()
end)

-- Receive loop
coroutine.wrap(function()
    appendMessage("SYSTEM", "Connecting to chat...")
    local connected       = false
    local suppressBubbles = true

    while isAlive() do
        local success, responseText = performRequest(HISTORY_URL, "GET", nil)
        if success then
            if not connected then
                connected = true
                appendMessage("SYSTEM", "Connected! Use \x27/\x27 for commands.")
                suppressBubbles = true  -- suppress bubbles on each (re)connect
            end

            if responseText and responseText ~= "" then
                local ok2, historyData = pcall(function() return HttpService:JSONDecode(responseText) end)
                if ok2 and type(historyData) == "table" then
                    for _, item in ipairs(historyData) do
                        if item.id and item.user and item.msg then
                            if not seenMessages[item.id] then
                                seenMessages[item.id] = true
                                appendMessage(item.user, item.msg)
                                if not suppressBubbles then
                                    showSpeechBubble(item.user, item.msg)
                                end
                            end
                        end
                    end
                    suppressBubbles = false
                end
            end
            task.wait(0.5)
        else
            if not connected then
                task.wait(4)
            else
                connected = false
                appendMessage("SYSTEM", "Connection lost. Reconnecting...", true)
                task.wait(2)
            end
        end
    end
end)()

-- Heartbeat
coroutine.wrap(function()
    while isAlive() do
        local payload = HttpService:JSONEncode({ user = currentNickname, serverId = game.JobId })
        performRequest(HEARTBEAT_URL, "POST", payload)
        task.wait(8)
    end
end)()

-- Ping measurement
coroutine.wrap(function()
    while isAlive() do
        local t0 = os.clock()
        local ok, _ = performRequest(SERVER_URL .. "/", "GET", nil)
        if ok then
            local ms = math.floor((os.clock() - t0) * 1000)
            PingLabel.RichText = false
            PingLabel.Text = ms .. "ms"
        else
            PingLabel.RichText = false
            PingLabel.Text = "ping: ✗"
        end
        task.wait(10)
    end
end)()
