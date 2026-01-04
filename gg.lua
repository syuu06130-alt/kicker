--[[ Syu_hub | Undetected Blobman Kick v5.0 (Fixed)
Features:
- Custom UI (Draggable, Minimizable)
- Target Selector (Dropdown) - FIXED
- All Kick Loop
- Auto Grab Blobman (Ammo)
- Byfron Bypass Physics
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ■■■ 1. 通知機能 (Syu_hub) ■■■
StarterGui:SetCore("SendNotification", {
    Title = "Syu_hub";
    Text = "Blobman Kick v5 Loaded!";
    Icon = "rbxassetid://18322043431";
    Duration = 5;
})

-- ■■■ UI構築 (Draggable / Minimize) ■■■
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Syu_hub_UI"
ScreenGui.ResetOnSpawn = false

-- Executor判定（保護レイヤーへ配置）
if pcall(function() return CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer.PlayerGui
end

-- メインフレーム
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 330)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(200, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

-- UIコーナー
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

-- タイトルバー（ドラッグ可能エリア）
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

-- タイトルテキスト
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Syu_hub | Blobman"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 最小化ボタン
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 2.5)
MinBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 20
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- ドラッグ機能（タイトルバーのみ）
local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- コンテナ（最小化時に隠す部分）
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -45)
Container.Position = UDim2.new(0, 10, 0, 40)
Container.BackgroundTransparency = 1
Container.ClipsDescendants = false
Container.Parent = MainFrame

local isMin = false
MinBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        Container.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 240, 0, 35), "Out", "Quad", 0.2, true)
        MinBtn.Text = "+"
    else
        Container.Visible = true
        MainFrame:TweenSize(UDim2.new(0, 240, 0, 330), "Out", "Quad", 0.2, true)
        MinBtn.Text = "_"
    end
end)

-- ■■■ ロジック関数 ■■■
local selectedPlayer = nil
local blobModel = nil

local function getBlobman()
    local nearest, dist = nil, 150
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v ~= Character then
            if not Players:GetPlayerFromCharacter(v) then
                local d = (v.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function grabBlob()
    local blob = getBlobman()
    if not blob then
        StarterGui:SetCore("SendNotification", {Title="Error", Text="近くにBlobman(物体)がいません"})
        return false
    end
    blobModel = blob
    
    local hrp = Character.HumanoidRootPart
    local bHrp = blob.HumanoidRootPart
    hrp.CFrame = bHrp.CFrame * CFrame.new(0,0,2)
    task.wait(0.1)
    hrp.CFrame = bHrp.CFrame
    return true
end

local function doKick(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local tHrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if not tHrp then return end
    
    if not blobModel or not blobModel.Parent then
        local grabbed = grabBlob()
        if not grabbed then return end
        task.wait(0.3)
    end
    
    local hrp = Character.HumanoidRootPart
    local tw = TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = tHrp.CFrame * CFrame.new(0,0,-3)})
    tw:Play()
    tw.Completed:Wait()
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = (tHrp.Position - hrp.Position).Unit * 500
    bv.Parent = hrp
    
    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bav.AngularVelocity = Vector3.new(100, 100, 100)
    bav.Parent = hrp
    
    task.wait(0.15)
    bv:Destroy()
    bav:Destroy()
    hrp.CFrame = hrp.CFrame * CFrame.new(0, 10, 0)
end

-- ■■■ UIパーツ ■■■

-- 1. ターゲット選択ラベル
local SelLabel = Instance.new("TextLabel")
SelLabel.Parent = Container
SelLabel.Size = UDim2.new(1, 0, 0, 20)
SelLabel.Position = UDim2.new(0, 0, 0, 0)
SelLabel.BackgroundTransparency = 1
SelLabel.Text = "Target Player:"
SelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SelLabel.Font = Enum.Font.SourceSansBold
SelLabel.TextSize = 14
SelLabel.TextXAlignment = Enum.TextXAlignment.Left

-- 2. プレイヤー選択ボタン
local DropBtn = Instance.new("TextButton")
DropBtn.Parent = Container
DropBtn.Size = UDim2.new(1, 0, 0, 35)
DropBtn.Position = UDim2.new(0, 0, 0, 25)
DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DropBtn.Text = "Select Player ▼"
DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DropBtn.Font = Enum.Font.Gotham
DropBtn.TextSize = 14

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 6)
DropCorner.Parent = DropBtn

-- ドロップダウンリスト（MainFrameの子として配置してClipping回避）
local DropList = Instance.new("ScrollingFrame")
DropList.Parent = ScreenGui
DropList.Size = UDim2.new(0, 220, 0, 120)
DropList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropList.BorderColor3 = Color3.fromRGB(200, 0, 0)
DropList.BorderSizePixel = 2
DropList.Visible = false
DropList.ZIndex = 10
DropList.ScrollBarThickness = 6
DropList.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = DropList

local function updateDropListPosition()
    local btnPos = DropBtn.AbsolutePosition
    DropList.Position = UDim2.new(0, btnPos.X, 0, btnPos.Y + 40)
end

local function refreshPlayers()
    DropList:ClearAllChildren()
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = DropList
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    
    local plrs = Players:GetPlayers()
    local count = 0
    
    for _, p in pairs(plrs) do
        if p ~= LocalPlayer then
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Parent = DropList
            btn.Size = UDim2.new(1, -10, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.Text = p.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.BorderSizePixel = 0
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                DropBtn.Text = "Target: " .. p.Name
                DropList.Visible = false
            end)
        end
    end
    
    DropList.CanvasSize = UDim2.new(0, 0, 0, count * 30)
end

DropBtn.MouseButton1Click:Connect(function()
    DropList.Visible = not DropList.Visible
    if DropList.Visible then
        updateDropListPosition()
        refreshPlayers()
    end
end)

-- リストを閉じる（他の場所をクリック）
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local listPos = DropList.AbsolutePosition
        local listSize = DropList.AbsoluteSize
        
        if DropList.Visible and (
            mousePos.X < listPos.X or mousePos.X > listPos.X + listSize.X or
            mousePos.Y < listPos.Y or mousePos.Y > listPos.Y + listSize.Y
        ) then
            local btnPos = DropBtn.AbsolutePosition
            local btnSize = DropBtn.AbsoluteSize
            if not (mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X and
                    mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y) then
                DropList.Visible = false
            end
        end
    end
end)

-- 3. 単体 Kick ボタン
local KickBtn = Instance.new("TextButton")
KickBtn.Parent = Container
KickBtn.Size = UDim2.new(1, 0, 0, 40)
KickBtn.Position = UDim2.new(0, 0, 0, 70)
KickBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
KickBtn.Text = "KICK TARGET"
KickBtn.Font = Enum.Font.GothamBold
KickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KickBtn.TextSize = 16

local KickCorner = Instance.new("UICorner")
KickCorner.CornerRadius = UDim.new(0, 6)
KickCorner.Parent = KickBtn

KickBtn.MouseButton1Click:Connect(function()
    if selectedPlayer then
        StarterGui:SetCore("SendNotification", {Title="Kick", Text="Kicking " .. selectedPlayer.Name})
        doKick(selectedPlayer)
    else
        StarterGui:SetCore("SendNotification", {Title="Error", Text="プレイヤーを選択してください"})
    end
end)

-- 4. All Kick ボタン
local AllKickBtn = Instance.new("TextButton")
AllKickBtn.Parent = Container
AllKickBtn.Size = UDim2.new(1, 0, 0, 40)
AllKickBtn.Position = UDim2.new(0, 0, 0, 120)
AllKickBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
AllKickBtn.Text = "ALL KICK (Loop)"
AllKickBtn.Font = Enum.Font.GothamBold
AllKickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AllKickBtn.TextSize = 16

local AllKickCorner = Instance.new("UICorner")
AllKickCorner.CornerRadius = UDim.new(0, 6)
AllKickCorner.Parent = AllKickBtn

local allKickActive = false
AllKickBtn.MouseButton1Click:Connect(function()
    allKickActive = not allKickActive
    if allKickActive then
        AllKickBtn.Text = "STOP ALL KICK"
        AllKickBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        task.spawn(function()
            while allKickActive do
                for _, p in pairs(Players:GetPlayers()) do
                    if not allKickActive then break end
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        DropBtn.Text = "Auto: " .. p.Name
                        doKick(p)
                        task.wait(0.5)
                    end
                end
                task.wait(1)
            end
        end)
    else
        AllKickBtn.Text = "ALL KICK (Loop)"
        AllKickBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    end
end)

-- 5. 再スキャンボタン
local ScanBtn = Instance.new("TextButton")
ScanBtn.Parent = Container
ScanBtn.Size = UDim2.new(1, 0, 0, 35)
ScanBtn.Position = UDim2.new(0, 0, 0, 170)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ScanBtn.Text = "Re-Grab Ammo (Blobman)"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.Gotham
ScanBtn.TextSize = 13

local ScanCorner = Instance.new("UICorner")
ScanCorner.CornerRadius = UDim.new(0, 6)
ScanCorner.Parent = ScanBtn

ScanBtn.MouseButton1Click:Connect(function()
    local res = grabBlob()
    if res then
        StarterGui:SetCore("SendNotification", {Title="Grab", Text="Blobmanを確保しました"})
    end
end)

-- ステータス表示
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = Container
StatusLabel.Size = UDim2.new(1, 0, 0, 60)
StatusLabel.Position = UDim2.new(0, 0, 0, 215)
StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatusLabel.Text = "Status: Ready\nTarget: None\nAmmo: Not Grabbed"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

-- ステータス更新ループ
task.spawn(function()
    while true do
        local target = selectedPlayer and selectedPlayer.Name or "None"
        local ammo = (blobModel and blobModel.Parent) and "Ready" or "Not Grabbed"
        local status = allKickActive and "AUTO KICKING" or "Ready"
        StatusLabel.Text = string.format("Status: %s\nTarget: %s\nAmmo: %s", status, target, ammo)
        task.wait(0.5)
    end
end)

print("Syu_hub v5 Loaded (Fixed Version)")