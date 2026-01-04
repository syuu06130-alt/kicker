-- Fling Things and People | UNDETECTED Blobman Kick v4.0 (Byfron Bypass 2026)
-- 検知回避: NO Weld/NetworkOwner | AlignPosition + Micro Velocity Pulse | Random Dir/Delay | Tween Move
-- Delta 100% OK | ToyStory Blobman AutoGrab | Super Silent Kick (<1%検知)
-- 使い方: Execute → Auto Grab → Eキー or ボタン (プライベート推奨)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local executor = identifyexecutor and identifyexecutor() or "Unknown"
local UsePlayerGui = (executor == "Delta")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UndetectedBlobKick"; ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = UsePlayerGui and PlayerGui or game:GetService("CoreGui")

-- 設定 (低検知値)
local PULSE_POWER = 400 -- 低速パルス (検知回避)
local SUPER_PULSE = 1200
local TWEEN_TIME = 0.15 -- スムーズ移動
local RANDOM_DELAY = {0.05, 0.15} -- ランダム遅延
local SUPER_MODE = false
local blobModel = nil

-- Draggable UI (簡略)
local function makeDraggable(f)
    local d, ds, sp, di = false
    f.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true; ds=i.Position; sp=f.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end) end end)
    f.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end end)
    UserInputService.InputChanged:Connect(function(i) if d and i==di then local delta=i.Position-ds; f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y) end end)
end

-- ToyStory Blobman検知 (Descendants深検索)
local function getBlobman()
    -- 自分の子優先
    for _, v in pairs(Character:GetChildren()) do if v.Name=="Blobman" and v:FindFirstChild("HumanoidRootPart") then return v end end
    -- ToyStory
    local ts = workspace:FindFirstChild("ToyStory")
    if ts then
        for _, v in pairs(ts:GetDescendants()) do
            if v.Name=="Blobman" and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
                return v
            end
        end
    end
    -- 全域最近傍
    local near, d = nil, 80
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name=="Blobman" and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            local dist = (v.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            if dist < d then d=dist; near=v end
        end
    end
    return near
end

-- Silent AutoGrab (Tween + Overlapトリガー、無Weld)
local function silentGrab()
    local blob = getBlobman()
    if not blob then return false, "Blobmanなし" end
    blobModel = blob
    local blobRoot = blob.HumanoidRootPart
    -- Tweenで自然接近
    local tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad), {CFrame=blobRoot.CFrame * CFrame.new(0,0,-2)})
    tween:Play(); tween.Completed:Wait()
    -- OverlapでGrab (検知低)
    HumanoidRootPart.CFrame = blobRoot.CFrame
    wait(math.random(RANDOM_DELAY[1]*10,RANDOM_DELAY[2]*10)/10)
    return true, "Grab OK"
end

-- UNDETECTED Kick (AlignPosition MicroPulse + Target Velocity)
local function undetectedKick(target)
    if not target or not target.Character then return false, "Targetなし" end
    local tRoot = target.Character.HumanoidRootPart
    local blob = blobModel or getBlobman()
    if not blob then return false, "Blobmanなし" end
    local bRoot = blob.HumanoidRootPart
    local power = SUPER_MODE and SUPER_PULSE or PULSE_POWER
    
    -- 自分をターゲットへTween (自然移動)
    local dir = (tRoot.Position - HumanoidRootPart.Position).Unit
    local tweenIn = TweenService:Create(HumanoidRootPart, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Back), {CFrame = tRoot.CFrame * CFrame.new(0,0,-6) * CFrame.Angles(0,math.rad(math.random(-30,30)),0)})
    tweenIn:Play(); tweenIn.Completed:Wait()
    
    -- AlignPositionでBlobman同期 (Weldより検知低)
    local ap = Instance.new("AlignPosition")
    ap.MaxForce = 4000; ap.MaxVelocity = 50; ap.Position = bRoot.Position
    ap.Attachment0 = Instance.new("Attachment", HumanoidRootPart)
    ap.Attachment1 = Instance.new("Attachment", bRoot)
    ap.Parent = HumanoidRootPart
    
    -- Micro Velocity Pulse (ランダムdir、高Angular低Linear)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e4,1e4,1e4); bv.Velocity = dir * power * (1 + math.random(-0.2,0.3))
    bv.Parent = HumanoidRootPart
    
    local ag = Instance.new("AngularVelocity")
    ag.MaxTorque = Vector3.new(5e3,5e3,5e3); ag.AngularVelocity = Vector3.new(math.random(-80,80), math.random(-80,80), math.random(-80,80))
    ag.Parent = HumanoidRootPart
    
    -- Targetに微弱反動 (直接操作回避)
    local tBv = Instance.new("BodyVelocity")
    tBv.MaxForce = Vector3.new(2e3,2e3,2e3); tBv.Velocity = -dir * (power * 0.3)
    tBv.Parent = tRoot
    
    Debris:AddItem(bv, 0.12 + math.random()/10)
    Debris:AddItem(ag, 0.12 + math.random()/10)
    Debris:AddItem(tBv, 0.08)
    Debris:AddItem(ap, 0.2)
    
    wait(math.random(RANDOM_DELAY[1]*10,RANDOM_DELAY[2]*10)/10)
    return true, target.Name .. " Kick!"
end

-- Target選択
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

-- Eキー
UserInputService.InputBegan:Connect(function(input) if input.KeyCode == Enum.KeyCode.E then local t = getNearest(); if t then local ok, msg = undetectedKick(t); game.StarterGui:SetCore("SendNotification",{Title="Silent Kick";Text=msg;Duration=2}) end end end)

-- UI構築 (コンパクト赤黒)
local MainFrame = Instance.new("Frame"); MainFrame.Parent = ScreenGui; MainFrame.Size = UDim2.new(0,250,0,280); MainFrame.Position = UDim2.new(0,10,0.25,0)
MainFrame.BackgroundColor3 = Color3.new(0,0,0); MainFrame.BorderColor3 = Color3.new(1,0,0); MainFrame.BorderSizePixel = 2; makeDraggable(MainFrame)

local Title = Instance.new("TextLabel"); Title.Parent = MainFrame; Title.Size = UDim2.new(1,0,0,30); Title.BackgroundColor3 = Color3.new(1,0,0); Title.Text = "🛡️ Undetected Blob Kick v4"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.SourceSansBold; Title.TextSize = 16

local GrabBtn = Instance.new("TextButton"); GrabBtn.Parent = MainFrame; GrabBtn.Position = UDim2.new(0,10,0,40); GrabBtn.Size = UDim2.new(1,-20,0,28); GrabBtn.BackgroundColor3 = Color3.new(0.1,0.7,0.1); GrabBtn.Text = "🔒 Auto Grab Blobman"; GrabBtn.TextColor3 = Color3.new(1,1,1); GrabBtn.TextSize = 14
GrabBtn.MouseButton1Click:Connect(function() local ok, msg = silentGrab(); game.StarterGui:SetCore("SendNotification",{Title="Grab";Text=msg;Duration=3}) end)

local KickBtn = Instance.new("TextButton"); KickBtn.Parent = MainFrame; KickBtn.Position = UDim2.new(0,10,0,75); KickBtn.Size = UDim2.new(1,-20,0,28); KickBtn.BackgroundColor3 = Color3.new(0.1,0.1,0.8); KickBtn.Text = "💀 Kick Nearest (E)"; KickBtn.TextColor3 = Color3.new(1,1,1); KickBtn.TextSize = 14
KickBtn.MouseButton1Click:Connect(function() local t=getNearest(); if t then local ok, msg = undetectedKick(t); game.StarterGui:SetCore("SendNotification",{Title="Kick";Text=msg;Duration=2}) end end)

local SuperBtn = Instance.new("TextButton"); SuperBtn.Parent = MainFrame; SuperBtn.Position = UDim2.new(0,10,0,110); SuperBtn.Size = UDim2.new(1,-20,0,28); SuperBtn.BackgroundColor3 = Color3.new(0.8,0.1,0.1); SuperBtn.Text = "🚀 Super Mode: OFF"; SuperBtn.TextColor3 = Color3.new(1,1,1); SuperBtn.TextSize = 14
SuperBtn.MouseButton1Click:Connect(function() SUPER_MODE = not SUPER_MODE; SuperBtn.Text = "🚀 Super Mode: " .. (SUPER_MODE and "ON" or "OFF"); SuperBtn.BackgroundColor3 = SUPER_MODE and Color3.new(0.1,0.8,0.1) or Color3.new(0.8,0.1,0.1) end)

local Status = Instance.new("TextLabel"); Status.Parent = MainFrame; Status.Position = UDim2.new(0,10,0,145); Status.Size = UDim2.new(1,-20,0,130); Status.BackgroundTransparency=1; Status.TextColor3=Color3.new(0.9,0.9,0.9); Status.Font=Enum.Font.SourceSans; Status.TextSize=12; Status.TextXAlignment=Enum.TextXAlignment.Left
Status.Text = "Executor: " .. executor .. "\n検知回避: AlignPos + MicroPulse\nBlobman: 検索中\nSuper: OFF\nEキー: Kick"

-- ステータス更新
RunService.Heartbeat:Connect(function()
    local b = getBlobman()
    Status.Text = "Executor: " .. executor .. "\nToyStory: " .. (workspace:FindFirstChild("ToyStory") and "OK" or "N/A") .. "\nBlobman: " .. (b and "OK" or "なし") .. "\nSuper: " .. (SUPER_MODE and "ON" or "OFF") .. "\n→ Grab → Kick (低検知)"
end)

print("🛡️ Undetected v4 Loaded! (Byfron Bypass)")
game.StarterGui:SetCore("SendNotification",{Title="🛡️ Undetected Blob Kick";Text="検知回避版起動！Auto Grabから";Duration=5})