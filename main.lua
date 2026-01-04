-- Fling Things and People | UNDETECTED Blobman Kick v4.1 (Fix)
-- 修正点: 名前が"Blobman"じゃなくても、近くにあるNPC(プレイヤー以外の人型)を自動認識するように変更

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local executor = identifyexecutor and identifyexecutor() or "Unknown"
local UsePlayerGui = (executor == "Delta")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UndetectedBlobKickFix"; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = UsePlayerGui and PlayerGui or game:GetService("CoreGui")

-- 設定
local PULSE_POWER = 400
local SUPER_PULSE = 1200
local TWEEN_TIME = 0.15
local RANDOM_DELAY = {0.05, 0.15}
local SUPER_MODE = false
local blobModel = nil

-- UIドラッグ関数
local function makeDraggable(f)
    local d, ds, sp, di = false
    f.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true; ds=i.Position; sp=f.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end) end end)
    f.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end end)
    UserInputService.InputChanged:Connect(function(i) if d and i==di then local delta=i.Position-ds; f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y) end end)
end

-- ★★★ 修正箇所: 強力な検索ロジック ★★★
local function getBlobman()
    -- 既に確保済みの場合は生存確認して返す
    if blobModel and blobModel.Parent and blobModel:FindFirstChild("HumanoidRootPart") then return blobModel end

    local nearest, dist = nil, 100 -- 半径100スタッド以内を探す

    for _, v in pairs(workspace:GetDescendants()) do
        -- 条件: Modelであり、HumanoidとRootPartを持ち、かつプレイヤーではない
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            if not Players:GetPlayerFromCharacter(v) then -- プレイヤーキャラを除外
                -- 名前チェックを緩和 (Blobman, Dummy, Characterなどを含める)
                -- 自分のキャラ以外で、かつ距離が近いもの
                if v ~= Character then
                    local d = (v.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

-- Silent AutoGrab
local function silentGrab()
    local blob = getBlobman()
    if not blob then return false, "近くにNPCが見つかりません" end
    blobModel = blob
    local blobRoot = blob.HumanoidRootPart
    
    -- Tween移動
    local tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad), {CFrame=blobRoot.CFrame * CFrame.new(0,0,-2)})
    tween:Play(); tween.Completed:Wait()
    
    -- 重なる
    HumanoidRootPart.CFrame = blobRoot.CFrame
    wait(math.random(RANDOM_DELAY[1]*10,RANDOM_DELAY[2]*10)/10)
    return true, "Grab: " .. blob.Name
end

-- Kick関数
local function undetectedKick(target)
    if not target or not target.Character then return false, "Targetなし" end
    local tRoot = target.Character.HumanoidRootPart
    local blob = blobModel or getBlobman()
    if not blob then return false, "Blobman(NPC)なし" end
    local bRoot = blob.HumanoidRootPart
    local power = SUPER_MODE and SUPER_PULSE or PULSE_POWER
    
    local dir = (tRoot.Position - HumanoidRootPart.Position).Unit
    local tweenIn = TweenService:Create(HumanoidRootPart, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Back), {CFrame = tRoot.CFrame * CFrame.new(0,0,-6)})
    tweenIn:Play(); tweenIn.Completed:Wait()
    
    local ap = Instance.new("AlignPosition")
    ap.MaxForce = 4000; ap.MaxVelocity = 50; ap.Position = bRoot.Position
    ap.Attachment0 = Instance.new("Attachment", HumanoidRootPart)
    ap.Attachment1 = Instance.new("Attachment", bRoot)
    ap.Parent = HumanoidRootPart
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4,1e4,1e4); bv.Velocity = dir * power * 1.2
    bv.Parent = HumanoidRootPart
    
    Debris:AddItem(bv, 0.15)
    Debris:AddItem(ap, 0.2)
    
    return true, target.Name .. " Kick!"
end

local function getNearest()
    local n, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            if d < dist then dist=d; n=p end
        end
    end
    return n
end

-- UIセットアップ
local MainFrame = Instance.new("Frame"); MainFrame.Parent = ScreenGui; MainFrame.Size = UDim2.new(0,250,0,180); MainFrame.Position = UDim2.new(0,10,0.3,0)
MainFrame.BackgroundColor3 = Color3.new(0.1,0.1,0.1); makeDraggable(MainFrame)

local GrabBtn = Instance.new("TextButton"); GrabBtn.Parent = MainFrame; GrabBtn.Size = UDim2.new(1,-10,0,40); GrabBtn.Position = UDim2.new(0,5,0,5); GrabBtn.Text = "AUTO GRAB (ANY NPC)"; GrabBtn.BackgroundColor3 = Color3.new(0,0.5,0)
GrabBtn.MouseButton1Click:Connect(function() local ok, msg = silentGrab(); print(msg) end)

local KickBtn = Instance.new("TextButton"); KickBtn.Parent = MainFrame; KickBtn.Size = UDim2.new(1,-10,0,40); KickBtn.Position = UDim2.new(0,5,0,50); KickBtn.Text = "KICK NEAREST"; KickBtn.BackgroundColor3 = Color3.new(0,0,0.8)
KickBtn.MouseButton1Click:Connect(function() local t=getNearest(); if t then undetectedKick(t) end end)

-- Eキー
UserInputService.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.E then local t = getNearest(); if t then undetectedKick(t) end end end)

game.StarterGui:SetCore("SendNotification",{Title="Fix Loaded";Text="NPC自動検索モード起動";Duration=5})
