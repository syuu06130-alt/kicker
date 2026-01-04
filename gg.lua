--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Library: Kavo UI Library (Delta Executor 完全対応・軽量・安定)
    UIのみKavoに変更、その他の機能は一切変更なし
]]

-- PlaceId限定実行（あのさがち専用）
local TARGET_PLACE_ID = 6961824067
if game.PlaceId ~= TARGET_PLACE_ID then
    warn("このスクリプトは Fling Things and People (PlaceId: 6961824067) でしか動きません！")
    return
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Syu_hub | Blobman Kick v6", "DarkTheme")

-- ■■■ Services ■■■
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ■■■ Variables ■■■
local TargetPlayer = nil
local IsLoopKicking = false
local IsAutoGrabbing = false
local SelectedAmmo = nil
local OriginalPosition = nil

-- ■■■ Utility Functions ■■■

-- 通知機能（Kavo対応）
function SendNotif(title, content, duration)
    duration = duration or 5
    Library:Notify({
        Title = title,
        Text = content,
        Duration = duration
    })
end

-- プレイヤーリストの取得
function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- Blobman (Ammo) を探す
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

-- Blobmanをスポーンさせる
function SpawnBlobman()
    local args = {
        [1] = "Blobman"
    }
    
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

-- 物理的にくっつけて攻撃する処理（完全そのまま）
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

-- ■■■ UI Construction (Kavo UI) ■■■

local MainTab = Window:NewTab("Main", 4483345998)

local TargetSection = MainTab:NewSection("Target Selector")

-- プレイヤー選択ドロップダウン
local PlayerDropdown = TargetSection:NewDropdown({
    Name = "Select Target Player",
    Options = GetPlayerNames(),
    Callback = function(Value)
        TargetPlayer = Value
        SendNotif("Selected", "Target: " .. Value)
    end
})

-- リフレッシュボタン
TargetSection:NewButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Update(GetPlayerNames())
        SendNotif("Refreshed", "Player list updated.")
    end
})

local ActionSection = MainTab:NewSection("Actions")

-- 単発Kickボタン
ActionSection:NewButton({
    Name = "Kick Target (Hit & Run)",
    Callback = function()
        if TargetPlayer then
            SendNotif("Kicking", "Attacking " .. TargetPlayer)
            TeleportAndAttack(TargetPlayer)
        else
            SendNotif("Error", "プレイヤーを選択してください")
        end
    end
})

-- ループKickトグル
ActionSection:NewToggle({
    Name = "Loop Kick Target",
    Default = false,
    Callback = function(Value)
        IsLoopKicking = Value
        if Value and TargetPlayer then
            SendNotif("Loop Check", "Loop started for " .. TargetPlayer)
            task.spawn(function()
                while IsLoopKicking and TargetPlayer do
                    TeleportAndAttack(TargetPlayer)
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- 全員Kickボタン（トグル式に統一）
ActionSection:NewButton({
    Name = "Kick ALL Loop (Toggle)",
    Callback = function()
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
    end
})

local MiscSection = MainTab:NewSection("Misc / Settings")

MiscSection:NewButton({
    Name = "Force Spawn Blobman",
    Callback = function()
        SpawnBlobman()
    end
})

-- 初期化完了通知
SendNotif("Syu_hub Loaded", "Version 6.0 | Kavo UI Edition\nDelta完全対応・Ready to kick.", 8)