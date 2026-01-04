--[[
    Syu_hub | Undetected Blobman Kick v5.0
    Features:
    - Custom UI (Draggable, Minimizable)
    - Target Selector (Dropdown)
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
    Icon = "rbxassetid://18322043431"; -- 汎用アイコン(必要なら変更)
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
MainFrame.Size = UDim2.new(0, 220, 0, 320)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(200, 0, 0) -- Syu_hubカラー（赤）
MainFrame.BorderSizePixel = 2
MainFrame.Parent = ScreenGui

-- ドラッグ機能
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- タイトルバー
local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, -30, 0, 30)
TitleBar.Position = UDim2.new(0, 10, 0, 0)
TitleBar.BackgroundTransparency = 1
TitleBar.Text = "Syu_hub | Blobman"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextSize = 16
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Parent = MainFrame

-- 最小化ボタン
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
MinBtn.TextSize = 24
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = MainFrame

-- コンテナ（最小化時に隠す部分）
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, 0, 1, -30)
Container.Position = UDim2.new(0, 0, 0, 30)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local isMin = false
MinBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        Container.Visible = false
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 30), "Out", "Quad", 0.2, true)
        MinBtn.Text = "+"
    else
        Container.Visible = true
        MainFrame:TweenSize(UDim2.new(0, 220, 0, 320), "Out", "Quad", 0.2, true)
        MinBtn.Text = "-"
    end
end)

-- ■■■ ロジック関数 ■■■
local selectedPlayer = nil
local blobModel = nil

-- Blobman (弾) を探す - NPCや物体を優先
local function getBlobman()
    -- プレイヤー以外で、Humanoidを持つModelを探す
    local nearest, dist = nil, 150
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v ~= Character then
            if not Players:GetPlayerFromCharacter(v) then -- プレイヤーは除外
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

-- Grab処理
local function grabBlob()
    local blob = getBlobman()
    if not blob then 
        StarterGui:SetCore("SendNotification", {Title="Error", Text="近くにBlobman(物体)がいません"})
        return false 
    end
    blobModel = blob
    
    -- 移動して掴む
    local hrp = Character.HumanoidRootPart
    local bHrp = blob.HumanoidRootPart
    
    hrp.CFrame = bHrp.CFrame * CFrame.new(0,0,2)
    task.wait(0.1)
    hrp.CFrame = bHrp.CFrame -- 重なることでGrab判定
    
    return true
end

-- Kick (Fling) 処理
local function doKick(targetPlr)
    if not targetPlr or not targetPlr.Character then return end
    local tHrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if not tHrp then return end
    
    -- Blobmanを持っていないなら取りに行く
    if not blobModel or not blobModel.Parent then
        local grabbed = grabBlob()
        if not grabbed then return end
        task.wait(0.3) -- Grab待機
    end

    local hrp = Character.HumanoidRootPart
    
    -- 高速移動 (Tween)
    local tw = TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = tHrp.CFrame * CFrame.new(0,0,-3)})
    tw:Play()
    tw.Completed:Wait()
    
    -- Fling Physics (Undetected Pulse)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = (tHrp.Position - hrp.Position).Unit * 500 -- パワー
    bv.Parent = hrp
    
    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bav.AngularVelocity = Vector3.new(100, 100, 100)
    bav.Parent = hrp

    task.wait(0.15) -- 衝突時間
    bv:Destroy()
    bav:Destroy()
    
    -- 離脱
    hrp.CFrame = hrp.CFrame * CFrame.new(0, 10, 0)
end

-- ■■■ UIパーツ (機能ボタン) ■■■

-- 1. ターゲット選択ラベル
local SelLabel = Instance.new("TextLabel")
SelLabel.Parent = Container
SelLabel.Size = UDim2.new(1, 0, 0, 20)
SelLabel.Position = UDim2.new(0, 0, 0, 5)
SelLabel.BackgroundTransparency = 1
SelLabel.Text = "Target Player:"
SelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SelLabel.Font = Enum.Font.SourceSansBold
SelLabel.TextSize = 14

-- 2. プレイヤー選択ボタン (簡易ドロップダウン)
local DropBtn = Instance.new("TextButton")
DropBtn.Parent = Container
DropBtn.Size = UDim2.new(0.9, 0, 0, 30)
DropBtn.Position = UDim2.new(0.05, 0, 0, 25)
DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DropBtn.Text = "Select Player ▼"
DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local DropList = Instance.new("ScrollingFrame")
DropList.Parent = Container
DropList.Size = UDim2.new(0.9, 0, 0, 100)
DropList.Position = UDim2.new(0.05, 0, 0, 60)
DropList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropList.Visible = false
DropList.ZIndex = 5
DropList.CanvasSize = UDim2.new(0,0,0,0)

-- リスト更新関数
local function refreshPlayers()
    DropList:ClearAllChildren()
    local layout = Instance.new("UIListLayout", DropList)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local plrs = Players:GetPlayers()
    DropList.CanvasSize = UDim2.new(0, 0, 0, #plrs * 25)
    
    for _, p in pairs(plrs) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Parent = DropList
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.Text = p.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = 0.5
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                DropBtn.Text = "Target: " .. p.Name
                DropList.Visible = false
            end)
        end
    end
end

DropBtn.MouseButton1Click:Connect(function()
    DropList.Visible = not DropList.Visible
    if DropList.Visible then refreshPlayers() end
end)

-- 3. 単体 Kick ボタン
local KickBtn = Instance.new("TextButton")
KickBtn.Parent = Container
KickBtn.Size = UDim2.new(0.9, 0, 0, 40)
KickBtn.Position = UDim2.new(0.05, 0, 0, 170) -- リストの下
KickBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
KickBtn.Text = "KICK TARGET"
KickBtn.Font = Enum.Font.GothamBold
KickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KickBtn.TextSize = 16

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
AllKickBtn.Size = UDim2.new(0.9, 0, 0, 40)
AllKickBtn.Position = UDim2.new(0.05, 0, 0, 220)
AllKickBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
AllKickBtn.Text = "ALL KICK (Loop)"
AllKickBtn.Font = Enum.Font.GothamBold
AllKickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AllKickBtn.TextSize = 16

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
                        task.wait(0.5) -- 連続処理の待機時間
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
ScanBtn.Size = UDim2.new(0.9, 0, 0, 25)
ScanBtn.Position = UDim2.new(0.05, 0, 0, 270)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ScanBtn.Text = "Re-Grab Ammo (Blobman)"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

ScanBtn.MouseButton1Click:Connect(function()
    local res = grabBlob()
    if res then
        StarterGui:SetCore("SendNotification", {Title="Grab", Text="Blobmanを確保しました"})
    end
end)

print("Syu_hub v5 Loaded")
