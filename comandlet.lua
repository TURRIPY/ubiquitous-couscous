local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local channelPart = workspace:FindFirstChild("RoundTimerPart") -- Замени на нужную деталь

-- GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.Position = UDim2.new(0.7, 0, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local ChatLog = Instance.new("ScrollingFrame", Frame)
ChatLog.Size = UDim2.new(1, 0, 0.8, 0)

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, 0, 0.2, 0)
TextBox.Position = UDim2.new(0, 0, 0.8, 0)

local buffer = {} -- Буфер для сборки строки

local function addMessage(text)
    local label = Instance.new("TextLabel", ChatLog)
    label.Text = text
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, #ChatLog:GetChildren() * 20)
    label.Parent = ChatLog
end

-- Отправка целой строки
TextBox.FocusLost:Connect(function(enter)
    if enter and TextBox.Text ~= "" then
        local senderId = LocalPlayer.UserId % 100 -- Короткий ID для передачи
        for i = 1, #TextBox.Text do
            local charCode = string.byte(string.sub(TextBox.Text, i, i))
            -- X: код буквы, Y: ID отправителя, Z: номер буквы
            channelPart.Position = Vector3.new(charCode, senderId, i)
            task.wait(0.05) 
        end
        channelPart.Position = Vector3.new(0, 0, 0) -- Сброс
        TextBox.Text = ""
    end
end)

-- Прием и сборка сообщения
channelPart:GetPropertyChangedSignal("Position"):Connect(function()
    local pos = channelPart.Position
    local charCode = pos.X
    local senderId = pos.Y
    local index = pos.Z
    
    if charCode > 0 then
        if not buffer[senderId] then buffer[senderId] = "" end
        buffer[senderId] = buffer[senderId] .. string.char(charCode)
        
        -- Если это был конец (допустим, мы шлем 10 знаков или по таймеру)
        -- Для теста выводим сразу:
        addMessage("Игрок " .. senderId .. ": " .. string.char(charCode))
    end
end)
