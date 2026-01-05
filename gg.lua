--[[
    Syu_hub v6.0 | Blobman Kicker & Auto Grab
    Target: Fling Things and People
    Library: Linoria Library (Stable, Modern, Delta Compatible)
]]

-- Linoria Library のロード
local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()

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

function SendNotif(title, content)
    Library:Notify(string.format("[Syu_hub] %s: %s", title, content), 5)
end

function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

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

local Window = Library:CreateWindow({
    Title = 'Syu_hub | Blobman Kick v6',
    Center = true,
    AutoShow = true,
})

local MainTab = Window:AddTab('Main')

local TargetGroup = MainTab:AddLeftGroupbox('Target Selector')

local PlayerDropdown = TargetGroup:AddDropdown('TargetPlayer', {
    Values = GetPlayerNames(),
    Default = '',
    Text = 'Select Target Player',
    Callback = function(Value)
        TargetPlayer = Value
        SendNotif("Selected", "Target: " .. Value)
    end
})

TargetGroup:AddButton('Refresh Player List', function()
    PlayerDropdown:SetValues(GetPlayerNames())
    PlayerDropdown:SetValue('')
    SendNotif("Refreshed", "Player list updated.")
end)

local ActionGroup = MainTab:AddRightGroupbox('Actions')

ActionGroup:AddButton('Kick Target (Hit & Run)', function()
    if TargetPlayer then
        SendNotif("Kicking", "Attacking " .. TargetPlayer)
        TeleportAndAttack(TargetPlayer)
    else
        SendNotif("Error", "プレイヤーを選択してください")
    end
end)

ActionGroup:AddToggle('LoopKick', {
    Text = 'Loop Kick Target',
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

ActionGroup:AddButton('Kick ALL Loop (Toggle)', function()
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

local MiscGroup = MainTab:AddLeftGroupbox('Misc / Settings')

MiscGroup:AddButton('Force Spawn Blobman', function()
    SpawnBlobman()
end)

-- オプション機能（コンフィグ保存やテーマ変更）
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('SyuHub')
SaveManager:SetFolder('SyuHub')
SaveManager:BuildConfigSection(MainTab:AddRightTabbox())
ThemeManager:ApplyToTab(MainTab)

Library:Notify('Syu_hub Loaded | Version 6.0 (Linoria UI)\nReady to kick.', 8)