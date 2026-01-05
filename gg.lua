--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Library: Fluid UI (Delta Fully Compatible, Modern & Stable)
]]

-- Fluid UI のロード（Deltaで完璧に動作する最新版）
local Fluid = loadstring(game:HttpGet("https://raw.githubusercontent.com/sewnn/FluidUI/main/Fluid.lua"))()

-- ウィンドウ作成
local Window = Fluid:CreateWindow({
    Title = "Syu_hub | Blobman Kick v6",
    Size = UDim2.fromOffset(600, 400),
    Position = UDim2.fromOffset(100, 100),
    Theme = "Dark" -- 好みで "Light" にも変更可
})

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayer = nil
local IsLoopKicking = false
local OriginalPosition = nil

-- ■■■ Utility Functions ■■■

-- 通知（FluidのNotify使用）
function SendNotif(title, content)
    Fluid:Notify({
        Title = title,
        Content = content,
        Duration = 5
    })
end

-- プレイヤーリスト取得
function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- Blobmanを探す（変更なし）
function FindBlobman()
    local nearest, dist = nil, 500
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v.Name == "Blobman" or v.Name == "Ragdoll") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(v) then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and v.HumanoidRootPart then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
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

-- Blobmanスポーン（変更なし）
function SpawnBlobman()
    local args = { [1] = "Blobman" }
    local spawned = false
    local remotes = {
        ReplicatedStorage:FindFirstChild("SpawnItem"),
        ReplicatedStorage:FindFirstChild("CreateItem"),
        Workspace:FindFirstChild("SpawnEvents")
    }

    for _, remote in pairs(remotes) do
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
            spawned = true
        end
    end
    
    if spawned then
        SendNotif("System", "Blobmanのスポーンを試みました")
    else
        SendNotif("Warning", "自動スポーンに失敗しました。手動で出してください。")
    end
end

-- 攻撃処理（完全変更なし）
function TeleportAndAttack(targetName)
    local target = Players:FindFirstChild(targetName)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

    local myHrp = char.HumanoidRootPart
    local targetHrp = target.Character.HumanoidRootPart

    if not OriginalPosition then
        OriginalPosition = myHrp.CFrame
    end

    local ammo = FindBlobman()
    if not ammo then
        SpawnBlobman()
        task.wait(0.2)
        ammo = FindBlobman()
        if not ammo then return end
    end

    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        for i = 1, 5 do
            ammo.HumanoidRootPart.CFrame = myHrp.CFrame * CFrame.new(0, 0, -2)
            ammo.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            RunService.RenderStepped:Wait()
        end
    end

    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1) 
    task.wait(0.01) 
    
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bv.AngularVelocity = Vector3.new(500, 500, 500)
    bv.Parent = myHrp
    
    if ammo and ammo:FindFirstChild("HumanoidRootPart") then
        ammo.HumanoidRootPart.CFrame = targetHrp.CFrame
        ammo.HumanoidRootPart.Velocity = (targetHrp.Position - myHrp.Position).Unit * 1000
    end

    task.wait(0.05)
    bv:Destroy()

    myHrp.CFrame = OriginalPosition
    myHrp.Velocity = Vector3.new(0,0,0)
    OriginalPosition = nil
end

-- ■■■ UI Construction ■■■

local MainTab = Window:AddTab("Main")

-- Target Selector
local TargetGroup = MainTab:AddGroup("Target Selector", "Left")

local PlayerDropdown = TargetGroup:AddDropdown("TargetPlayer", {
    Text = "Select Target Player",
    Items = GetPlayerNames(),
    Callback = function(value)
        TargetPlayer = value
        SendNotif("Selected", "Target: " .. value)
    end
})

TargetGroup:AddButton("Refresh Player List", function()
    PlayerDropdown:Update(GetPlayerNames())
    SendNotif("Refreshed", "Player list updated.")
end)

-- Actions
local ActionGroup = MainTab:AddGroup("Actions", "Right")

ActionGroup:AddButton("Kick Target (Hit & Run)", function()
    if TargetPlayer then
        SendNotif("Kicking", "Attacking " .. TargetPlayer)
        TeleportAndAttack(TargetPlayer)
    else
        SendNotif("Error", "プレイヤーを選択してください")
    end
end)

ActionGroup:AddToggle("Loop Kick Target", false, function(state)
    IsLoopKicking = state
    if state and TargetPlayer then
        SendNotif("Loop Start", "Loop started for " .. TargetPlayer)
        task.spawn(function()
            while IsLoopKicking and TargetPlayer do
                TeleportAndAttack(TargetPlayer)
                task.wait(0.1)
            end
        end)
    end
end)

ActionGroup:AddButton("Kick ALL Loop (Toggle)", function()
    IsLoopKicking = not IsLoopKicking
    if IsLoopKicking then
        SendNotif("ALL KICK", "Starting massacre...")
        task.spawn(function()
            while IsLoopKicking do
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and IsLoopKicking then
                        TeleportAndAttack(p.Name)
                        task.wait(0.2)
                    end
                end
                task.wait()
            end
        end)
    else
        SendNotif("Stopped", "All Kick Stopped.")
    end
end)

-- Misc
local MiscGroup = MainTab:AddGroup("Misc / Settings", "Left")

MiscGroup:AddButton("Force Spawn Blobman", function()
    SpawnBlobman()
end)

-- ロード完了通知
SendNotif("Syu_hub Loaded", "Version 6.0 | Fluid UI\nDelta完全対応 - Ready to kick!")