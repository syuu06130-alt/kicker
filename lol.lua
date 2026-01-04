-- Fling Things and People | Blobman Kick Script (Custom Made)
-- 使い方: 
-- 1. Roblox Exploit (Synapse, Krnlなど)で実行
-- 2. まずゲーム内でBlobmanをGrab/Spawn (ハブ推奨)
-- 3. GUIでターゲット選択してKICKボタン or キーEで自動kick
-- 注意: BANリスク高め、プライベートサーバー推奨

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- 設定
local KICK_SPEED = 500  -- キック速度 (高くすると強力)
local KICK_POWER = 10000  -- AssemblyLinearVelocity
local KEYBIND = Enum.KeyCode.E  -- キックキー

-- Blobman検索 (ゲーム内のBlobmanを探す、自分のもの優先)
local function findBlobman()
  for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name == "Blobman" and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
      if obj.HumanoidRootPart.Parent == Character then  -- 自分のBlobman優先
        return obj
      end
    end
  end
  -- なければ近くのBlobman
  for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name == "Blobman" and obj:FindFirstChild("HumanoidRootPart") then
      return obj
    end
  end
  return nil
end

-- ターゲットプレイヤー選択 (最近傍 or GUIで)
local targetPlayer = nil
local function findNearestTarget()
  local nearest, dist = nil, math.huge
  for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
      local d = (plr.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
      if d < dist then
        dist = d
        nearest = plr
      end
    end
  end
  return nearest
end

-- Blobman Kick関数
local function kickWithBlobman(target)
  if not target or not target.Character then return end
  local targetRoot = target.Character.HumanoidRootPart
  
  local blobman = findBlobman()
  if not blobman then
    game.StarterGui:SetCore("SendNotification", {
      Title = "Blobman Kick";
      Text = "Blobmanが見つかりません！まずGrabしてください。";
      Duration = 3;
    })
    return
  end
  
  local blobRoot = blobman.HumanoidRootPart
  
  -- Blobmanを自分にWeld (安定)
  local weld = Instance.new("WeldConstraint")
  weld.Part0 = HumanoidRootPart
  weld.Part1 = blobRoot
  weld.Parent = HumanoidRootPart
  
  -- ターゲット方向に高速テレポート + Velocity
  local direction = (targetRoot.Position - HumanoidRootPart.Position).Unit
  HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -5)  -- 後ろから接近
  
  local bv = Instance.new("BodyVelocity")
  bv.MaxForce = Vector3.new(4000, 4000, 4000)
  bv.Velocity = direction * KICK_SPEED
  bv.Parent = HumanoidRootPart
  
  -- 追加Fling Power (Angular + Linear)
  local ag = Instance.new("AngularVelocity")
  ag.MaxTorque = Vector3.new(4000, 4000, 4000)
  ag.AngularVelocity = Vector3.new(math.random(-50,50), math.random(-50,50), math.random(-50,50))
  ag.Parent = HumanoidRootPart
  
  local ba = Instance.new("BodyAngularVelocity")  -- Legacyサポート
  ba.MaxTorque = Vector3.new(4000,4000,4000)
  ba.AngularVelocity = Vector3.new(math.random(-100,100),0,math.random(-100,100))
  ba.Parent = HumanoidRootPart
  
  -- クリーンアップ
  game:GetService("Debris"):AddItem(bv, 0.3)
  game:GetService("Debris"):AddItem(ag, 0.3)
  game:GetService("Debris"):AddItem(ba, 0.3)
  wait(0.1)
  weld:Destroy()
  
  game.StarterGui:SetCore("SendNotification", {
    Title = "Blobman Kick";
    Text = target.Name .. " をキックしました！";
    Duration = 2;
  })
end

-- キー入力
UserInputService.InputBegan:Connect(function(input, gp)
  if gp then return end
  if input.KeyCode == KEYBIND then
    local target = findNearestTarget()
    if target then
      kickWithBlobman(target)
    else
      game.StarterGui:SetCore("SendNotification", {
        Title = "Blobman Kick";
        Text = "ターゲットが見つかりません";
        Duration = 2;
      })
    end
  end
end)

-- シンプルGUI (オプション: ターゲットリスト)
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.BorderColor3 = Color3.new(1,0,0)
Frame.Position = UDim2.new(0,10,0.3,0)
Frame.Size = UDim2.new(0,200,0,300)
ScreenGui.Parent = game.CoreGui

local Title = Instance.new("TextLabel")
Title.Parent = Frame
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundColor3 = Color3.new(1,0,0)
Title.Text = "Blobman Kick v1.0"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold

local KickBtn = Instance.new("TextButton")
KickBtn.Parent = Frame
KickBtn.Position = UDim2.new(0,10,0,50)
KickBtn.Size = UDim2.new(1,-20,0,30)
KickBtn.Text = "Kick Nearest (E)"
KickBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
KickBtn.TextColor3 = Color3.new(1,1,1)
KickBtn.MouseButton1Click:Connect(function()
  kickWithBlobman(findNearestTarget())
end)

print("Blobman Kick Loaded! キー: E | ボタンで最近傍キック | Blobman持って使用")