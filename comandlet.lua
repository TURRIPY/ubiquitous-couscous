local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ВЫБОР ОБЪЕКТА: Замени 'Baseplate' на имя любой детали в Workspace, которая есть у всех
local channelPart = workspace:WaitForChild("RoundTimerPart") 

-- GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0.7, 0, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

local ChatLog = Instance.new("ScrollingFrame", Frame)
ChatLog.Size = UDim2.new(1, 0, 0.8, 0)
ChatLog.BackgroundTransparency = 1

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, 0, 0.2, 0)
TextBox.Position = UDim2.new(0, 0, 0.8, 0)
TextBox.PlaceholderText = "Введите сообщение..."

-- Логика
local lastPos = channelPart.Position.X

local function addMessage(text)
    local label = Instance.new("TextLabel", ChatLog)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, #ChatLog:GetChildren() * 20)
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
end

-- Отправка (превращаем каждый символ в движение детали)
TextBox.FocusLost:Connect(function(enter)
    if enter and TextBox.Text ~= "" then
        for i = 1, #TextBox.Text do
            local charCode = string.byte(string.sub(TextBox.Text, i, i))
            channelPart.Position = Vector3.new(charCode, 0, 0)
            task.wait(0.1) -- Задержка для синхронизации
        end
        channelPart.Position = Vector3.new(0, 0, 0) -- Сброс
        TextBox.Text = ""
    end
end)

-- Прием
channelPart:GetPropertyChangedSignal("Position"):Connect(function()
    local val = channelPart.Position.X
    if val > 0 then
        local char = string.char(val)
        addMessage("Друг: " .. char)
    end
end)
