

local Players = game:GetService("Players")
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local ByteNetReliable
pcall(function()
    ByteNetReliable = ReplicatedStorage.ByteNetReliable
end)

local zombiesFolder
pcall(function()
    zombiesFolder = workspace.Entities.Zombie
end)

local char, hrp
pcall(function()
    char = player.Character or player.CharacterAdded:Wait()
    hrp = char.HumanoidRootPart
end)

local noclipTouchedParts = {}
local AutoClearToggle = {Value = true}
local AutoAttackToggle = {Value = true}
local AutoSwapToggle = {Value = true}
local AutoCollectToggle = {Value = true}
local AutoSkillsToggle = {Value = true}
local UsePerkToggle = {Value = true}
local BringMobsToggle = {Value = true}
local AutoReplayToggle = {Value = true}
local AutoJoinMapToggle = {Value = false}
local offset = Vector3.new(1, 6, 0)

local function getconnect(v2)
    local events = { "Activated", "MouseButton1Down", "MouseButton1Click", "MouseButton1Up" }
    for _, event in next, events do
        for _, connection in next, getconnections(v2[event]) do
            connection.Function()
        end
    end
end

player.CharacterAdded:Connect(function(newChar)
    pcall(function()
        char = newChar
        hrp = char.HumanoidRootPart
        table.clear(noclipTouchedParts)
    end)
end)

local function enableNoclip(character)
    pcall(function()
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                noclipTouchedParts[part] = true
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip(character)
    pcall(function()
        for part in pairs(noclipTouchedParts) do
            if part and part.Parent then
                part.CanCollide = true
            end
        end
        table.clear(noclipTouchedParts)
        if hrp then
            local bv = hrp:FindFirstChild("Lock")
            if bv then bv:Destroy() end
        end
    end)
end

local function moveToTarget(targetHRP, offset)
    pcall(function()
        if not (hrp and hrp.Parent) then return end
        if not (targetHRP and targetHRP.Parent) then return end
        offset = offset or Vector3.new(0,5,0)
        local speed = 100
        local bv = hrp:FindFirstChild("Lock")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "Lock"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0,0,0)
            bv.Parent = hrp
        end
        repeat
            if not (targetHRP and targetHRP.Parent) then break end
            local targetPos = targetHRP.Position + offset
            local dir = targetPos - hrp.Position
            if dir.Magnitude > 0.5 then
                bv.Velocity = dir.Unit * speed
            else
                bv.Velocity = Vector3.zero
            end
            enableNoclip(char)
            RunService.Heartbeat:Wait()
        until not (targetHRP and targetHRP.Parent) or (hrp.Position - targetHRP.Position - offset).Magnitude <= 0.5
        bv.Velocity = Vector3.zero
    end)
end

local function collectAllDrops()
    pcall(function()
        local DropItemsFolder = workspace.DropItems
        if hrp and DropItemsFolder then
            for _, item in ipairs(DropItemsFolder:GetChildren()) do
                local targetPos
                if item:IsA("Model") and item.PrimaryPart then
                    targetPos = item.PrimaryPart.Position
                elseif item:IsA("BasePart") then
                    targetPos = item.Position
                end
                if targetPos then
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function killAllZombiesAfterRadio()
    pcall(function()
        pcall(function()
            require(workspace.Entities)
        end)
        
        while true do
            local allZombies = workspace:FindFirstChild("Entities") 
                                and workspace.Entities:FindFirstChild("Zombie") 
                                and workspace.Entities.Zombie:GetChildren() or {}
            
            if #allZombies == 0 then break end
            
            for _, zombie in ipairs(allZombies) do
                if zombie:FindFirstChild("Humanoid") and zombie.Humanoid.Health > 0 then
                    if zombie:FindFirstChild("HumanoidRootPart") and hrp then
                        moveToTarget(zombie.HumanoidRootPart, Vector3.new(0,5,0))
                        task.wait(0.3)
                    end
                end
            end
            task.wait(0.5)
        end
        
        collectAllDrops()
        task.wait(1)
    end)
end

local Library
pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/noggik/allsaylin/refs/heads/main/uifree.lua"))()
end)

if not Library then return end

local Window
pcall(function()
    Window = Library:CreateWindow({
        Title = 'Hunty Zombies',
        Author = 'By Xin',
        Icon = 'zap',
        Theme = 'Dark',
        Size = UDim2.new(0, 530, 0, 400),
        Keybind = Enum.KeyCode.LeftControl,
        CloseUIButton = {
            Enabled = true,
            Text = 'Close UI'
        }
    })
end)

if not Window then return end

local MainTab, SkillTab, MiscTab
pcall(function()
    MainTab = Window:Tab({Title = 'Main', Icon = 'star'})
    SkillTab = Window:Tab({Title = 'Skills', Icon = 'zap'})
    MiscTab = Window:Tab({Title = 'Misc', Icon = 'settings'})
    Window:SelectTab(1)
end)

if MainTab then
    MainTab:Section({Title = 'Auto Functions'})

    MainTab:Toggle({
        Title = "Auto Clear Wave",
        Default = true,
        Callback = function(state)
            AutoClearToggle.Value = state
            if state then
                task.spawn(function()
                    enableNoclip(char)
                    while AutoClearToggle.Value do
                        local targetZombie = nil
                        if zombiesFolder then
                            for _, z in ipairs(zombiesFolder:GetChildren()) do
                                local zHRP = z:FindFirstChild("HumanoidRootPart")
                                if zHRP and zHRP.Position.Y > -20 then
                                    targetZombie = zHRP
                                    break
                                end
                            end
                        end
                        
                        if targetZombie and targetZombie.Parent then
                            moveToTarget(targetZombie, Vector3.new(0,8,0))
                            task.wait(0.1)
                        else
                            local handled = false
                            pcall(function()
                                local bossRoom = workspace:FindFirstChild("Sewers")
                                if bossRoom and bossRoom:FindFirstChild("Rooms") then
                                    bossRoom = bossRoom.Rooms:FindFirstChild("BossRoom")
                                    if bossRoom and bossRoom:FindFirstChild("generator") then
                                        local gen = bossRoom.generator:FindFirstChild("gen")
                                        if gen then
                                            local pom = gen:FindFirstChild("pom")
                                            if pom and pom:IsA("ProximityPrompt") and pom.Enabled then
                                                moveToTarget(gen, Vector3.new(0,0,0))
                                                task.wait(0.5)
                                                fireproximityprompt(pom)
                                                task.wait(1)
                                                handled = true
                                            end
                                        end
                                    end
                                end
                            end)
                            
                            pcall(function()
                                local school = workspace:FindFirstChild("School")
                                if school and school:FindFirstChild("Rooms") then
                                    local rooftop = school.Rooms:FindFirstChild("RooftopBoss")
                                    if rooftop and rooftop:FindFirstChild("RadioObjective") then
                                        local radioPrompt = rooftop.RadioObjective:FindFirstChildOfClass("ProximityPrompt")
                                        if radioPrompt and radioPrompt.Enabled then
                                            moveToTarget(rooftop.RadioObjective, Vector3.new(0,0,0))
                                            task.wait(0.5)
                                            fireproximityprompt(radioPrompt)
                                            task.wait(10)
                                            
                                            killAllZombiesAfterRadio()
                                            
                                            local heliPrompt = rooftop:FindFirstChild("HeliObjective")
                                            if heliPrompt then
                                                heliPrompt = heliPrompt:FindFirstChildOfClass("ProximityPrompt")
                                                if heliPrompt and heliPrompt.Enabled then
                                                    moveToTarget(rooftop.HeliObjective, Vector3.new(0,0,0))
                                                    task.wait(0.5)
                                                    fireproximityprompt(heliPrompt)
                                                end
                                            end
                                            handled = true
                                        end
                                    end
                                end
                            end)
                            
                            if not handled then
                                task.wait(1)
                            end
                        end
                    end
                    disableNoclip(char)
                end)
            else
                disableNoclip(char)
            end
        end
    })

    MainTab:Toggle({
        Title = "Auto Attack",
        Default = true,
        Callback = function(state)
            AutoAttackToggle.Value = state
            if state then
                task.spawn(function()
                    while AutoAttackToggle.Value do
                        pcall(function()
                            VirtualUser:Button1Down(Vector2.new(958, 466))
                        end)
                        task.wait(1)
                    end
                end)
            end
        end
    })

    MainTab:Toggle({
        Title = "Auto Swap Weapons",
        Default = true,
        Callback = function(state)
            AutoSwapToggle.Value = state
            if state then
                task.spawn(function()
                    local keys = { Enum.KeyCode.One, Enum.KeyCode.Two }
                    local current = 1
                    while AutoSwapToggle.Value do
                        pcall(function()
                            local key = keys[current]
                            VirtualInputManager:SendKeyEvent(true, key, false, game)
                            VirtualInputManager:SendKeyEvent(false, key, false, game)
                            current = current == 1 and 2 or 1
                        end)
                        task.wait(2)
                    end
                end)
            end
        end
    })

    MainTab:Toggle({
        Title = "Auto Collect",
        Default = true,
        Callback = function(state)
            AutoCollectToggle.Value = state
            if state then
                task.spawn(function()
                    while AutoCollectToggle.Value do
                        collectAllDrops()
                        task.wait(0.3)
                    end
                end)
            end
        end
    })

    MainTab:Section({Title = 'Map Settings'})

    MainTab:Dropdown({
        Title = "เลือกแมพ",
        Values = {"School", "Sewers"},
        Value = selectedMap,
        Callback = function(option)
            selectedMap = option
        end
    })

    MainTab:Dropdown({
        Title = "เลือกโหมด",
        Values = {"Normal", "Hard", "Nightmare"},
        Value = selectedMode,
        Callback = function(option)
            selectedMode = option
        end
    })

    MainTab:Toggle({
        Title = "Auto Join Map",
        Default = true,
        Callback = function(state)
            AutoJoinMapToggle.Value = state
            if state then
                task.spawn(function()
                    pcall(function()
                        local matchPart = workspace:FindFirstChild("Match")
                        if matchPart then
                            matchPart = matchPart:FindFirstChild("Part")
                            if matchPart and matchPart:FindFirstChild("MatchBoard") then
                                local infoLabel = matchPart.MatchBoard:FindFirstChild("InfoLabel")
                                if infoLabel and infoLabel.Text == "Start Here" then
                                    hrp.CFrame = matchPart.CFrame + Vector3.new(0, 5, 0)
                                    task.wait(1)
                                    
                                    local playerSelect = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.options.playerselect.F.l
                                    local textLabel = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.options.playerselect.F.Shape.Fill.TextLabel
                                    
                                    while textLabel.Text ~= "1" do
                                        getconnect(playerSelect)
                                        task.wait(0.1)
                                    end
                                    
                                    task.wait(1)
                                    local chooseMapBtn = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.options.buttons.choosemap
                                    getconnect(chooseMapBtn)
                                    task.wait(1)
                                    
                                    local mapButtons = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.maps:GetChildren()
                                    for _, mapBtn in pairs(mapButtons) do
                                        if mapBtn:IsA("GuiObject") and mapBtn.Name == "mapbutton" and mapBtn.TextLabel.Text == selectedMap then
                                            getconnect(mapBtn)
                                            break
                                        end
                                    end
                                    task.wait(1)
                                    
                                    local chooseDiffBtn = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.options.buttons.choosediffs
                                    getconnect(chooseDiffBtn)
                                    task.wait(1)
                                    
                                    local diffButtons = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.modes:GetChildren()
                                    for _, diffBtn in pairs(diffButtons) do
                                        if diffBtn:IsA("GuiObject") and diffBtn.Name == "difbutton" and diffBtn.TextLabel.Text == selectedMode then
                                            getconnect(diffBtn)
                                            break
                                        end
                                    end
                                    task.wait(1)
                                    
                                    local startBtn = player.PlayerGui.GUI.StartPlaceRedo.Content.iContent.Button
                                    getconnect(startBtn)
                                end
                            end
                        end
                    end)
                end)
            end
        end
    })
end

if SkillTab then
    SkillTab:Section({Title = 'Skill Management'})

    SkillTab:Toggle({
        Title = "Auto Skills",
        Default = true,
        Callback = function(state)
            AutoSkillsToggle.Value = state
            if state then
                task.spawn(function()
                    local keys = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.G }
                    while AutoSkillsToggle.Value do
                        pcall(function()
                            for _, key in ipairs(keys) do
                                VirtualInputManager:SendKeyEvent(true, key, false, game)
                                VirtualInputManager:SendKeyEvent(false, key, false, game)
                            end
                        end)
                        RunService.Heartbeat:Wait()
                    end
                end)
            end
        end
    })

    SkillTab:Toggle({
        Title = "Use Perk",
        Default = true,
        Callback = function(state)
            UsePerkToggle.Value = state
            if state then
                task.spawn(function()
                    while UsePerkToggle.Value do
                        pcall(function()
                            if ByteNetReliable then
                                local args = { buffer.fromstring("\f") }
                                ByteNetReliable:FireServer(unpack(args))
                            end
                        end)
                        RunService.Heartbeat:Wait()
                    end
                end)
            end
        end
    })
end

if MiscTab then
    MiscTab:Section({Title = 'Miscellaneous'})

    MiscTab:Toggle({
        Title = "Bring Mobs",
        Default = true,
        Callback = function(state)
            BringMobsToggle.Value = state
            if state then
                task.spawn(function()
                    while BringMobsToggle.Value do
                        pcall(function()
                            local sewers = workspace:FindFirstChild("Sewers")
                            if sewers and sewers:FindFirstChild("Doors") then
                                for _, door in ipairs(sewers.Doors:GetChildren()) do
                                    if ByteNetReliable then
                                        local args = { buffer.fromstring("\a\001"), {door} }
                                        ByteNetReliable:FireServer(unpack(args))
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end)
                        
                        pcall(function()
                            local school = workspace:FindFirstChild("School")
                            if school and school:FindFirstChild("Doors") then
                                for _, door in ipairs(school.Doors:GetChildren()) do
                                    if ByteNetReliable then
                                        local args = { buffer.fromstring("\a\001"), {door} }
                                        ByteNetReliable:FireServer(unpack(args))
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end
        end
    })

    MiscTab:Toggle({
        Title = "Auto Replay",
        Default = true,
        Callback = function(state)
            AutoReplayToggle.Value = state
            if state then
                task.spawn(function()
                    while AutoReplayToggle.Value do
                        pcall(function()
                            local voteReplay = ReplicatedStorage.external.Packets.voteReplay
                            if voteReplay then
                                voteReplay:FireServer()
                            end
                        end)
                        task.wait(0.5)
                    end
                end)
            end
        end
    })
end
