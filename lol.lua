-- Fling Things and People | Delta-Compatible Blobman Kick Hub v3.0 (ToyStory FIXED)
-- 修正: workspace.ToyStory内のBlobman対応！ GetDescendants()で確実検知
-- + Auto Grabボタン (CFrameテレポートで自動Grab)
-- 使い方: 
-- 1. Deltaで実行 → UI左上表示
-- 2. "Auto Grab Blobman"押す → 自動Grab
-- 3. Eキー or "Kick Nearest"でキック！
-- Super Strength ONで超強力

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Executor検知 (Delta)
local executor = identifyexecutor and identifyexecutor() or "Unknown"
local UsePlayerGui = (executor == "Delta")

-- 設定
local KICK_SPEED = 800
local KICK_POWER = 20000
local SUPER_STRENGTH = false
local KEYBIND = Enum.KeyCode.E
local blobman = nil  -- グローバル保持

-- Draggable (前回と同じ)
local function makeDraggable(frame)
    local dragging, dragStart, startPos, dragInput = false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 修正: ToyStory対応 Blobman検索 (優先: 自分の > ToyStory内 > 近く)
local function findBlobman()
    -- 1. 自分のCharacterの子 (Grab済み)
    for _, obj in pairs(Character:GetChildren()) do
        if obj.Name == "Blobman" and obj:FindFirstChild("HumanoidRootPart") then
            return obj
        end
    end
    -- 2. workspace.ToyStory内 (メイン!)
    local toyStory = workspace:FindFirstChild("ToyStory")
    if toyStory then
        for _, obj in pairs(toyStory:GetDescendants()) do
            if obj.Name == "Blobman" and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                return obj
            end
        end
    end
    -- 3. workspace全域 fallback (近くの)
    local nearest, dist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Blobman" and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local root = obj.HumanoidRootPart
            local d = (root.Position - HumanoidRootPart.Position).Magnitude
            if d < dist and d < 100 then
                dist = d; nearest = obj
            end
        end
    end
    return nearest
end

-- Auto Grab (CFrameテレポートでゲームGrabトリガー)
local function autoGrabBlobman()
    blobman = findBlobman()
    if not blobman then
        game.StarterGui:SetCore("SendNotification", {Title="Blobman Grab"; Text="Blobmanが見つかりません (ToyStory確認)"; Duration=3})
        return false
    end
    local blobRoot = blobman.HumanoidRootPart
    HumanoidRootPart.CFrame = blobRoot.CFrame * CFrame.new(0, 0, -3)  -- 近づく
    wait(0.1)
    HumanoidRootPart.CFrame = blobRoot.CFrame  -- 重なるでGrab
    game.StarterGui:SetCore("SendNotification", {Title="Blobman Grab"; Text="Grab成功！今キック可能"; Duration=2})
    return true
end

-- Nearest Target
local function findNearestTarget()
    local nearest, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d; nearest = plr end
        end
    end
    return nearest
end

-- Kick (Blobman強化 + NetworkOwner)
local function kickTarget(target)
    if not target or not target.Character then return end
    local targetRoot = target.Character.HumanoidRootPart
    blobman = findBlobman() or blobman
    
    if not blobman then
        game.StarterGui:SetCore("SendNotification", {Title="Blobman Kick"; Text="Blobmanなし！Auto Grab押して"; Duration=3})
        return
    end
    
    local blobRoot = blobman.HumanoidRootPart
    -- Weld自分に (安定)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = HumanoidRootPart; weld.Part1 = blobRoot; weld.Parent = HumanoidRootPart
    
    -- NetworkOwner自分に (強力制御)
    pcall(function() blobRoot:SetNetworkOwner(LocalPlayer) end)
    pcall(function() targetRoot:SetNetworkOwner(LocalPlayer) end)
    
    local dir = (targetRoot.Position - HumanoidRootPart.Position).Unit
    HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0,0,-10)
    
    if SUPER_STRENGTH then KICK_SPEED = 2000; KICK_POWER = 100000 end
    
    -- Velocity + Angular (超強力)
    local bv = Instance.new("BodyVelocity", HumanoidRootPart)
    bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.Velocity = dir * KICK_SPEED
    
    local ag = Instance.new("AngularVelocity", HumanoidRootPart)
    ag.MaxTorque = Vector3.new(1e6,1e6,1e6)
    ag.AngularVelocity = Vector3.new(math.random(-200,200), math.random(-200,200), math.random(-200,200))
    
    Debris:AddItem(bv, 0.6); Debris:AddItem(ag, 0.6)
    wait(0.3); weld:Destroy()
    
    game.StarterGui:SetCore("SendNotification", {Title="Blobman Kick"; Text=target.Name.."超キック！"; Duration=2})
end

-- Toggle Super
local function toggleSuper()
    SUPER_STRENGTH = not SUPER_STRENGTH
end

-- Kick All
local function kickAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then spawn(function() kickTarget(plr) end) end
    end
end

-- Eキー
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == KEYBIND then kickTarget(findNearestTarget()) end
end)

-- UI (Delta PlayerGui)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBlobmanKickV3"; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = UsePlayerGui and PlayerGui or game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui; Frame.BackgroundColor3 = Color3.new(0,0,0); Frame.BorderColor3 = Color3.new(1,0,0)
Frame.BorderSizePixel = 3; Frame.Position = UDim2.new(0,10,0.25,0); Frame.Size = UDim2.new(0,240,0,320)
makeDraggable(Frame)

-- タイトル
local Title = Instance.new("TextLabel"); Title.Parent = Frame; Title.BackgroundColor3 = Color3.new(1,0,0); Title.Size = UDim2.new(1,0,0,35)
Title.Font = Enum.Font.SourceSansBold; Title.Text = "Blobman Kick v3.0 (ToyStory FIX)"; Title.TextColor3 = Color3.new(1,1,1); Title.TextSize = 16

-- Auto Grab
local GrabBtn = Instance.new("TextButton"); GrabBtn.Parent = Frame; GrabBtn.Position = UDim2.new(0,10,0,45); GrabBtn.Size = UDim2.new(1,-20,0,32)
GrabBtn.BackgroundColor3 = Color3.new(0.2,0.8,0.2); GrabBtn.Text = "🚀 Auto Grab Blobman"; GrabBtn.TextColor3 = Color3.new(1,1,1); GrabBtn.Font = Enum.Font.SourceSansBold; GrabBtn.TextSize = 14
GrabBtn.MouseButton1Click:Connect(autoGrabBlobman)

-- Kick Nearest
local KickNearest = Instance.new("TextButton"); KickNearest.Parent = Frame; KickNearest.Position = UDim2.new(0,10,0,85); KickNearest.Size = UDim2.new(1,-20,0,32)
KickNearest.BackgroundColor3 = Color3.new(0.2,0.2,0.8); KickNearest.Text = "💥 Kick Nearest (E)"; KickNearest.TextColor3 = Color3.new(1,1,1); KickNearest.TextSize = 14
KickNearest.MouseButton1Click:Connect(function() kickTarget(findNearestTarget()) end)

-- Super
local SuperBtn = Instance.new("TextButton"); SuperBtn.Parent = Frame; SuperBtn.Position = UDim2.new(0,10,0,125); SuperBtn.Size = UDim2.new(1,-20,0,32)
SuperBtn.BackgroundColor3 = Color3.new(0.8,0.2,0.2); SuperBtn.Text = "⚡ Super Strength: OFF"; SuperBtn.TextColor3 = Color3.new(1,1,1); SuperBtn.TextSize = 14
SuperBtn.MouseButton1Click:Connect(function()
    toggleSuper(); SuperBtn.Text = "⚡ Super Strength: "..(SUPER_STRENGTH and "ON 🔥" or "OFF"); SuperBtn.BackgroundColor3 = SUPER_STRENGTH and Color3.new(0.2,0.8,0.2) or Color3.new(0.8,0.2,0.2)
end)

-- Kick All
local KickAll = Instance.new("TextButton"); KickAll.Parent = Frame; KickAll.Position = UDim2.new(0,10,0,165); KickAll.Size = UDim2.new(1,-20,0,32)
KickAll.BackgroundColor3 = Color3.new(0.8,0,0); KickAll.Text = "🌪️ Kick All (危険)"; KickAll.TextColor3 = Color3.new(1,1,1); KickAll.TextSize = 14
KickAll.MouseButton1Click:Connect(kickAll)

-- ステータス
local Status = Instance.new("TextLabel"); Status.Parent = Frame; Status.Position = UDim2.new(0,10,0,205); Status.Size = UDim2.new(1,-20,0,110)
Status.BackgroundTransparency = 1; Status.Font = Enum.Font.SourceSans; Status.TextColor3 = Color3.new(0.9,0.9,0.9); Status.TextSize = 12; Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Text = "Executor: "..executor.."\nBlobman: 検索中...\nToyStory: 確認中\nキー: E\nGrab → Kick !"

-- リアルタイム更新
RunService.Heartbeat:Connect(function()
    local b = findBlobman(); local ts = workspace:FindFirstChild("ToyStory")
    Status.Text = "Executor: "..executor.."\nToyStory: "..(ts and "OK" or "なし").."\nBlobman: "..(b and "OK" or "なし").."\nSuper: "..(SUPER_STRENGTH and "ON" or "OFF").."\nキー: E"
end)

print("v3.0 ToyStory Blobman FIX Loaded!")
game.StarterGui:SetCore("SendNotification", {Title="Blobman Kick v3"; Text="ToyStory対応！Auto Grabで即使用"; Duration=5})