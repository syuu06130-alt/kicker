-- Fling Things and People | Delta-Compatible Blobman Kick Hub v2.0
-- Delta Executor 完全対応: PlayerGui使用 + identifyexecutor検知
-- 使い方: 
-- 1. Delta Executorで実行
-- 2. ゲーム内でBlobmanをGrab (推奨: 近くのBlobman自動検知)
-- 3. GUIでターゲット選択 or Eキー/ボタンでKick!
-- 新機能: Draggable UI, Super Strength Toggle, Kick All

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Executor検知 (Delta対応)
local executor = identifyexecutor and identifyexecutor() or "Unknown"
local UsePlayerGui = (executor == "Delta")

-- 設定
local KICK_SPEED = 800
local KICK_POWER = 20000
local SUPER_STRENGTH = false
local KEYBIND = Enum.KeyCode.E

-- Draggable関数 (Delta UI改善)
local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local UIS = UserInputService

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

    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Blobman検索 (自分の優先 + 自動Spawn代替)
local function findBlobman()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "Blobman" and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
            if obj:FindFirstChild("HumanoidRootPart").Parent == Character then
                return obj
            end
        end
    end
    -- 代替: 近くのBlobman
    local nearest, dist = nil, math.huge
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "Blobman" and obj:FindFirstChild("HumanoidRootPart") then
            local d = (obj.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            if d < dist and d < 50 then
                dist = d
                nearest = obj
            end
        end
    end
    return nearest
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

-- Kick関数 (Blobman強化版)
local function kickTarget(target)
    if not target or not target.Character then return end
    local targetRoot = target.Character.HumanoidRootPart
    local blobman = findBlobman()
    
    if not blobman then
        game.StarterGui:SetCore("SendNotification", {Title="Delta Blobman Kick"; Text="Blobmanなし！Grabしてね"; Duration=3})
        return
    end
    
    local blobRoot = blobman.HumanoidRootPart
    local weld = Instance.new("WeldConstraint", HumanoidRootPart)
    weld.Part0 = HumanoidRootPart
    weld.Part1 = blobRoot
    
    local dir = (targetRoot.Position - HumanoidRootPart.Position).Unit
    HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0,0,-8)
    
    if SUPER_STRENGTH then
        KICK_SPEED = 1500; KICK_POWER = 50000  -- Superモード
    end
    
    local bv = Instance.new("BodyVelocity", HumanoidRootPart)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = dir * KICK_SPEED
    
    local ag = Instance.new("AngularVelocity", HumanoidRootPart)
    ag.MaxTorque = Vector3.new(1e5,1e5,1e5)
    ag.AngularVelocity = Vector3.new(math.random(-100,100), math.random(-100,100), math.random(-100,100))
    
    Debris:AddItem(bv, 0.5)
    Debris:AddItem(ag, 0.5)
    wait(0.2)
    weld:Destroy()
    
    game.StarterGui:SetCore("SendNotification", {Title="Delta Blobman Kick"; Text=target.Name.."をキック！"; Duration=2})
end

-- Super Strength Toggle (投げ強化)
local function toggleSuper()
    SUPER_STRENGTH = not SUPER_STRENGTH
    game.StarterGui:SetCore("SendNotification", {Title="Super Strength"; Text=SUPER_STRENGTH and "ON (強力！)" or "OFF"; Duration=2})
end

-- Kick All (スパム注意)
local function kickAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            spawn(function() kickTarget(plr) end)
        end
    end
end

-- キーE
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == KEYBIND then
        kickTarget(findNearestTarget())
    end
end)

-- Delta対応ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaBlobmanKick"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = UsePlayerGui and PlayerGui or game:GetService("CoreGui")

-- Main Frame (Draggable + 赤黒テーマ)
local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.BorderColor3 = Color3.new(1,0,0)
Frame.BorderSizePixel = 3
Frame.Position = UDim2.new(0, 10, 0.3, 0)
Frame.Size = UDim2.new(0, 220, 0, 280)
makeDraggable(Frame)

-- タイトル
local Title = Instance.new("TextLabel")
Title.Parent = Frame
Title.BackgroundColor3 = Color3.new(1,0,0)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1,0,0,35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Delta Blobman Kick v2.0"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 18

-- Kick Nearest
local KickNearest = Instance.new("TextButton")
KickNearest.Parent = Frame
KickNearest.Position = UDim2.new(0,10,0,50)
KickNearest.Size = UDim2.new(1,-20,0,30)
KickNearest.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
KickNearest.BorderColor3 = Color3.new(1,0,0)
KickNearest.BorderSizePixel = 2
KickNearest.Font = Enum.Font.SourceSans
KickNearest.Text = "Kick Nearest (Eキー)"
KickNearest.TextColor3 = Color3.new(1,1,1)
KickNearest.TextSize = 14
KickNearest.MouseButton1Click:Connect(function()
    kickTarget(findNearestTarget())
end)

-- Super Strength
local SuperBtn = Instance.new("TextButton")
SuperBtn.Parent = Frame
SuperBtn.Position = UDim2.new(0,10,0,90)
SuperBtn.Size = UDim2.new(1,-20,0,30)
SuperBtn.BackgroundColor3 = Color3.new(0.8,0.2,0.2)
SuperBtn.BorderColor3 = Color3.new(1,0,0)
SuperBtn.BorderSizePixel = 2
SuperBtn.Font = Enum.Font.SourceSans
SuperBtn.Text = "Super Strength: OFF"
SuperBtn.TextColor3 = Color3.new(1,1,1)
SuperBtn.TextSize = 14
SuperBtn.MouseButton1Click:Connect(function()
    toggleSuper()
    SuperBtn.Text = "Super Strength: "..(SUPER_STRENGTH and "ON" or "OFF")
    SuperBtn.BackgroundColor3 = SUPER_STRENGTH and Color3.new(0.2,0.8,0.2) or Color3.new(0.8,0.2,0.2)
end)

-- Kick All (危険)
local KickAll = Instance.new("TextButton")
KickAll.Parent = Frame
KickAll.Position = UDim2.new(0,10,0,130)
KickAll.Size = UDim2.new(1,-20,0,30)
KickAll.BackgroundColor3 = Color3.new(0.5,0,0)
KickAll.BorderColor3 = Color3.new(1,0,0)
KickAll.BorderSizePixel = 2
KickAll.Font = Enum.Font.SourceSans
KickAll.Text = "Kick All (スパム注意!)"
KickAll.TextColor3 = Color3.new(1,1,1)
KickAll.TextSize = 14
KickAll.MouseButton1Click:Connect(kickAll)

-- ステータス
local Status = Instance.new("TextLabel")
Status.Parent = Frame
Status.Position = UDim2.new(0,10,0,170)
Status.Size = UDim2.new(1,-20,0,40)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.SourceSans
Status.Text = "Executor: "..executor.."\nBlobman: 検索中...\nキー: E"
Status.TextColor3 = Color3.new(0.8,0.8,0.8)
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left

-- 更新ループ
RunService.Heartbeat:Connect(function()
    local blob = findBlobman()
    Status.Text = "Executor: "..executor.."\nBlobman: "..(blob and "OK" or "なし").."\nキー: E | Super: "..(SUPER_STRENGTH and "ON" or "OFF")
end)

print("Delta Blobman Kick Hub Loaded! (PlayerGui: "..tostring(UsePlayerGui)..")")
game.StarterGui:SetCore("SendNotification", {Title="Delta Hub"; Text="Blobman Kick Ready! Eキー or GUI"; Duration=5})
