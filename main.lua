local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local executor = identifyexecutor and identifyexecutor() or "Unknown"
local UsePlayerGui = (executor == "Delta")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ForwardTPTool"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = UsePlayerGui and LocalPlayer.PlayerGui or game:GetService("CoreGui")

-- 設定
local TP_DISTANCE = 10  -- 前方に10スタッド
local TP_TIME = 0.01    -- ほぼ瞬間移動

-- UIドラッグ関数
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- 前方10スタッドTP関数
local function teleportForward()
    if not HumanoidRootPart then return end
    local forwardPos = HumanoidRootPart.Position + (HumanoidRootPart.CFrame.LookVector * TP_DISTANCE)
    local tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(TP_TIME, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(forwardPos) * HumanoidRootPart.CFrame.Rotation}
    )
    tween:Play()
    tween.Completed:Wait()
end

-- UI作成
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0, 10, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Parent = ScreenGui
makeDraggable(MainFrame)

-- タイトルバー
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Forward TP (10 studs)"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.Parent = TitleBar

-- 最小化ボタン
local minimized = false
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 220, 0, 35) or UDim2.new(0, 220, 0, 120)
    MinimizeBtn.Text = minimized and "+" or "−"
end)

-- ×ボタン（上部固定 / 戻す トグル）
local docked = false
local originalPos = MainFrame.Position
local DockBtn = Instance.new("TextButton")
DockBtn.Size = UDim2.new(0, 35, 0, 35)
DockBtn.Position = UDim2.new(1, -35, 0, 0)
DockBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
DockBtn.Text = "×"
DockBtn.TextColor3 = Color3.new(1, 1, 1)
DockBtn.Font = Enum.Font.GothamBold
DockBtn.Parent = TitleBar

DockBtn.MouseButton1Click:Connect(function()
    docked = not docked
    if docked then
        -- 上部に固定（画面上端にピッタリ）
        MainFrame.Position = UDim2.new(0, MainFrame.Position.X.Offset, 0, 0)
    else
        -- 元の位置に戻す
        MainFrame.Position = originalPos
    end
end)

-- TP実行ボタン
local TPButton = Instance.new("TextButton")
TPButton.Size = UDim2.new(1, -20, 0, 50)
TPButton.Position = UDim2.new(0, 10, 0, 50)
TPButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
TPButton.Text = "前方に10スタッド移動"
TPButton.TextColor3 = Color3.new(1, 1, 1)
TPButton.Font = Enum.Font.GothamBold
TPButton.TextSize = 16
TPButton.Parent = MainFrame

TPButton.MouseButton1Click:Connect(teleportForward)

-- 通知
game.StarterGui:SetCore("SendNotification", {
    Title = "Forward TP Tool";
    Text = "ロード完了！ボタンで前方10スタッド移動";
    Duration = 5;
})
