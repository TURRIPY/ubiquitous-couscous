local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Создаем папку-канал, если её нет
local channel = ReplicatedStorage:FindFirstChild("ChatChannel") or Instance.new("Folder", ReplicatedStorage)
channel.Name = "ChatChannel"

-- Создание GUI
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "PrivateChatGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.Position = UDim2.new(0.8, 0, 0.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local ChatLog = Instance.new("ScrollingFrame", Frame)
ChatLog.Size = UDim2.new(1, 0, 0.8, 0)
ChatLog.CanvasSize = UDim2.new(0, 0, 2, 0)

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, 0, 0.2, 0)
TextBox.Position = UDim2.new(0, 0, 0.8, 0)
TextBox.PlaceholderText = "Напиши сообщение..."
TextBox.Text = ""

-- Функция добавления сообщения в GUI
local function addMessage(text)
    local msgLabel = Instance.new("TextLabel", ChatLog)
    msgLabel.Size = UDim2.new(1, 0, 0, 20)
    msgLabel.Position = UDim2.new(0, 0, 0, #ChatLog:GetChildren() * 20)
    msgLabel.Text = text
    msgLabel.TextColor3 = Color3.new(1, 1, 1)
    msgLabel.BackgroundTransparency = 1
end

-- Отправка
TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and TextBox.Text ~= "" then
        local msg = LocalPlayer.Name .. ": " .. TextBox.Text
        
        -- Записываем в ReplicatedStorage (обновляем общий объект)
        local msgObj = Instance.new("StringValue", channel)
        msgObj.Name = "MSG_" .. tick() -- Уникальное имя по времени
        msgObj.Value = msg
        
        TextBox.Text = ""
    end
end)

-- Прием
channel.ChildAdded:Connect(function(child)
    if child:IsA("StringValue") then
        addMessage(child.Value)
        -- Удаляем старые сообщения через время, чтобы не засорять память
        task.delay(10, function() child:Destroy() end)
    end
end)
