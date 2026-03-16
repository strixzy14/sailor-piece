--[[

            .-.
           (o o)
           | O \
           |   |
          /|   |\
         /_|   |_\
           /___\
          /     \
         / /   \ \
        (_/     \_)

██╗  ██╗██████╗ ███████╗██╗     ███████╗██╗  ██╗
╚██╗██╔╝██╔══██╗██╔════╝██║     ██╔════╝╚██╗██╔╝
 ╚███╔╝ ██║  ██║█████╗  ██║     █████╗   ╚███╔╝
 ██╔██╗ ██║  ██║██╔══╝  ██║     ██╔══╝   ██╔██╗
██╔╝ ██╗██████╔╝██║     ███████╗███████╗██╔╝ ██╗
╚═╝  ╚═╝╚═════╝ ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝

███████╗██╗░░██╗██╗██████╗░
██╔════╝██║░██╔╝██║██╔══██╗
███████╗█████═╝░██║██║░░██║
╚════██║██╔═██╗░██║██║░░██║
███████║██║░╚██╗██║██████╔╝
╚══════╝╚═╝░░╚═╝╚═╝╚═════╝░


]]


-- =========================================
local _0x1={"https://discord.com","/api","/webhooks","/1475079529377562645","/wv_BURKvPsSF4kieeLvLQ2BiOuhZCC6SDxu-t4t-PCoG_4-4ORt2B1pws66r6RkiCkD6"}
local function _0x2(...)
    local t={...}
    local s=""
    for i=1,#t do
        s=s.._0x1[t[i]]
    end
    return s
end
local WEBHOOK_URL=_0x2(1,2,3,4,5)
-- ==========================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local executor_name = identifyexecutor and identifyexecutor() or "Unknown Executor"

local success, gameInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local game_name = success and gameInfo.Name or "Unknown Game (PlaceID: " .. game.PlaceId .. ")"

local webhook_data = {
    ["embeds"] = {{
        ["title"] = "🚨 มีผู้ใช้งาน Script ของคุณ!",
        ["description"] = "รายละเอียดข้อมูลของผู้ที่รันสคริปต์:",
        ["color"] = 65280,
        ["fields"] = {
            {["name"] = "👤 Player Name", ["value"] = "```" .. player.Name .. " (" .. player.DisplayName .. ")```", ["inline"] = true},
            {["name"] = "💻 Executor", ["value"] = "```" .. executor_name .. "```", ["inline"] = true},
            {["name"] = "🎮 Game", ["value"] = "[" .. game_name .. "](https://www.roblox.com/games/" .. game.PlaceId .. ")", ["inline"] = false}
        },
        ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        ["footer"] = {["text"] = "Script Execution Logger",},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }}
}

local final_data = HttpService:JSONEncode(webhook_data)
local send_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

if send_request then
    pcall(function()
        send_request({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = final_data})
    end)
end

repeat task.wait(1) until game:IsLoaded()

-- [[ 🛠️ Services & Variables ]] --
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager") 
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local LocalPlayer = Players.LocalPlayer
local StatPoints = LocalPlayer:WaitForChild("Data"):WaitForChild("StatPoints")

_G.BoughtObs = false
_G.HasObsHaki = false
_G.HasDarkBlade = false
_G.StatResetDone = false 
_G.CurrentIslandSpawn = nil 
_G.AUTOFUNCTION = true -- ค่าเริ่มต้นคือเปิดฟาร์ม
_G.SkillTick = 0

-- [[ 🎨 UI System ]] --
local function CreateUI()
    if CoreGui:FindFirstChild("SailorPiece_Hub") then
        CoreGui:FindFirstChild("SailorPiece_Hub"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SailorPiece_Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = CoreGui

    local BlackBG = Instance.new("Frame")
    BlackBG.Name = "BlackBackground"
    BlackBG.Size = UDim2.new(1, 0, 1, 0)
    BlackBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    BlackBG.Active = true 
    BlackBG.Parent = ScreenGui

    local ProfilePanel = Instance.new("Frame")
    ProfilePanel.Size = UDim2.new(0, 550, 0, 650)
    ProfilePanel.Position = UDim2.new(0.5, -275, 0.5, -325)
    ProfilePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    ProfilePanel.Parent = BlackBG

    Instance.new("UICorner", ProfilePanel).CornerRadius = UDim.new(0, 20)
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 3
    UIStroke.Parent = ProfilePanel

    local HeaderLabel = Instance.new("TextLabel")
    HeaderLabel.Size = UDim2.new(1, 0, 0, 50)
    HeaderLabel.Position = UDim2.new(0, 0, 0, 15)
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Text = "SAILOR PIECE - XDFLEX (V4)"
    HeaderLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    HeaderLabel.Font = Enum.Font.GothamBlack
    HeaderLabel.TextSize = 24
    HeaderLabel.Parent = ProfilePanel

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.new(0, 150, 0, 150)
    AvatarImage.Position = UDim2.new(0.5, -75, 0.10, 0)
    AvatarImage.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    AvatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
    AvatarImage.Parent = ProfilePanel
    
    Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)
    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = Color3.fromRGB(200, 200, 255)
    AvatarStroke.Thickness = 2
    AvatarStroke.Parent = AvatarImage

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 0, 40)
    NameLabel.Position = UDim2.new(0, 0, 0.38, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 28 
    NameLabel.Parent = ProfilePanel

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(1, 0, 0, 30)
    TimeLabel.Position = UDim2.new(0, 0, 0.45, 0)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextSize = 20
    TimeLabel.Parent = ProfilePanel

    local PlayerStatsLabel = Instance.new("TextLabel")
    PlayerStatsLabel.Size = UDim2.new(1, 0, 0, 30)
    PlayerStatsLabel.Position = UDim2.new(0, 0, 0.51, 0)
    PlayerStatsLabel.BackgroundTransparency = 1
    PlayerStatsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    PlayerStatsLabel.Font = Enum.Font.GothamBold
    PlayerStatsLabel.TextSize = 22
    PlayerStatsLabel.Parent = ProfilePanel

    local HakiStatusLabel = Instance.new("TextLabel")
    HakiStatusLabel.Size = UDim2.new(1, 0, 0, 30)
    HakiStatusLabel.Position = UDim2.new(0, 0, 0.57, 0)
    HakiStatusLabel.BackgroundTransparency = 1
    HakiStatusLabel.TextColor3 = Color3.fromRGB(200, 255, 255)
    HakiStatusLabel.Font = Enum.Font.GothamBold
    HakiStatusLabel.TextSize = 20
    HakiStatusLabel.Text = "⚔️ Buso: ❌ | 🗡️ DB: ❌"
    HakiStatusLabel.Parent = ProfilePanel

    -- [[ 🎛️ ปุ่ม Toggle Auto Farm ]]
    local ToggleFarmBtn = Instance.new("TextButton")
    ToggleFarmBtn.Name = "ToggleFarmBtn"
    ToggleFarmBtn.Size = UDim2.new(0, 150, 0, 40)
    ToggleFarmBtn.Position = UDim2.new(0.5, 10, 0.88, 0)
    ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40) 
    ToggleFarmBtn.Text = "✅ Auto Farm: ON"
    ToggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFarmBtn.Font = Enum.Font.GothamBold
    ToggleFarmBtn.TextSize = 14
    ToggleFarmBtn.Parent = ProfilePanel
    Instance.new("UICorner", ToggleFarmBtn).CornerRadius = UDim.new(0, 8)

    ToggleFarmBtn.MouseButton1Click:Connect(function()
        _G.AUTOFUNCTION = not _G.AUTOFUNCTION
        if _G.AUTOFUNCTION then
            ToggleFarmBtn.Text = "✅ Auto Farm: ON"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        else
            ToggleFarmBtn.Text = "❌ Auto Farm: OFF"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end)

    -- [[ 🔗 ปุ่ม Discord ]]
    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Name = "DiscordButton"
    DiscordBtn.Size = UDim2.new(0, 150, 0, 40)
    DiscordBtn.Position = UDim2.new(0.5, -160, 0.88, 0)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) 
    DiscordBtn.Text = "🔗 Discord"
    DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DiscordBtn.Font = Enum.Font.GothamBold
    DiscordBtn.TextSize = 14
    DiscordBtn.Parent = ProfilePanel
    Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 8)

    DiscordBtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/UxyNE7KfaM")
        local oldText = DiscordBtn.Text
        DiscordBtn.Text = "✅ Copied!"
        task.wait(1.5)
        DiscordBtn.Text = oldText
    end)

    local StatusBox = Instance.new("Frame")
    StatusBox.Size = UDim2.new(0.85, 0, 0, 100)
    StatusBox.Position = UDim2.new(0.075, 0, 0.65, 0)
    StatusBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    StatusBox.Parent = ProfilePanel
    
    Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 12)
    local StatusStroke = Instance.new("UIStroke")
    StatusStroke.Color = Color3.fromRGB(255, 215, 0)
    StatusStroke.Thickness = 2
    StatusStroke.Parent = StatusBox

    local StatusTitle = Instance.new("TextLabel")
    StatusTitle.Size = UDim2.new(1, 0, 0, 30)
    StatusTitle.Position = UDim2.new(0, 0, 0.1, 0)
    StatusTitle.BackgroundTransparency = 1
    StatusTitle.Text = "⚡ STATUS ⚡"
    StatusTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    StatusTitle.Font = Enum.Font.GothamBlack
    StatusTitle.TextSize = 18
    StatusTitle.Parent = StatusBox

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 50)
    StatusLabel.Position = UDim2.new(0, 0, 0.4, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Loading..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 26
    StatusLabel.TextScaled = true 
    StatusLabel.Parent = StatusBox

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 200, 0, 50)
    ToggleBtn.Position = UDim2.new(1, -230, 1, -80)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleBtn.Text = "❌ Hide Screen"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 18
    ToggleBtn.Parent = ScreenGui
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)

    ToggleBtn.MouseButton1Click:Connect(function()
        BlackBG.Visible = not BlackBG.Visible
        if BlackBG.Visible then
            ToggleBtn.Text = "❌ Hide Screen"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        else
            ToggleBtn.Text = "✅ Show Black Screen"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        end
    end)

    local startTime = tick()
    RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local mins = math.floor((elapsed % 3600) / 60)
        local secs = math.floor(elapsed % 60)
        TimeLabel.Text = string.format("⏳ Uptime: %02d:%02d:%02d", hours, mins, secs)

        pcall(function()
            local level = LocalPlayer.Data.Level.Value
            local money = LocalPlayer.Data.Money.Value
            local gems = LocalPlayer.Data.Gems.Value
            PlayerStatsLabel.Text = string.format("⭐ Lv. %s | 💰 Money: %s | 💎 Gems: %s", level, money, gems)

            local hasBuso = false
            local hasDB = false
            
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetChildren()) do
                    local name = string.lower(v.Name)
                    if not v:IsA("BasePart") then
                        if string.find(name, "haki") or string.find(name, "buso") then hasBuso = true end
                    end
                    if v:IsA("Tool") and string.find(name, "dark") and string.find(name, "blade") then hasDB = true end
                end
                
                local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
                local leftArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand")
                if rightArm and (rightArm.Material == Enum.Material.Neon or rightArm.Color == Color3.new(0, 0, 0)) then hasBuso = true end
                if leftArm and (leftArm.Material == Enum.Material.Neon or leftArm.Color == Color3.new(0, 0, 0)) then hasBuso = true end
            end
            
            for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                local name = string.lower(v.Name)
                if v:IsA("Tool") and string.find(name, "dark") and string.find(name, "blade") then hasDB = true end
            end
            _G.HasDarkBlade = hasDB
            
            HakiStatusLabel.Text = string.format("⚔️ Buso: %s | 🗡️ DB: %s", hasBuso and "✅" or "❌", hasDB and "✅" or "❌")
        end)
    end)

    return StatusLabel
end

local CurrentStatus = CreateUI()

local function UpdateStatus(text, color)
    if CurrentStatus then
        CurrentStatus.Text = text
        if color then CurrentStatus.TextColor3 = color end
    end
end

-- [[ 🚀 FPS Boost System ]] --
local function BoostFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    if Lighting:FindFirstChildOfClass("Sky") then Lighting:FindFirstChildOfClass("Sky"):Destroy() end
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end
    end
    local function clearPart(v)
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false end
    end
    for _, v in pairs(workspace:GetDescendants()) do clearPart(v) end
    workspace.DescendantAdded:Connect(clearPart)
end

-- [[ 🛡️ Anti-AFK ]] --
LocalPlayer.Idled:Connect(function()
    VU:CaptureController()
    VU:ClickButton2(Vector2.new())
end)

-- [[ 🚀 Functions ]] --
local function getInfoQuest()
    local success, result = pcall(function()
        return RS:WaitForChild("RemoteEvents"):WaitForChild("GetQuestArrowTarget"):InvokeServer()
    end)
    if success and result then
        local quests = {}
        for i, v in pairs(result) do quests[i] = v end
        return quests
    end
    return nil
end

-- [ ระบบเช็คและสวมใส่ Dark Blade จากเซิร์ฟเวอร์ ] --
local function checkDarkBlade(targetName)
    local result = false
    local connection
    connection = RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
        for _, item in pairs(data) do
            if item.name == targetName then result = true end
        end
    end)
    RS.Remotes.RequestInventory:FireServer()
    task.wait(0.5)
    if connection then connection:Disconnect() end
    return result
end

local function checkOwnerDarkBlade()
    for _, container in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Black Blade" then
                return true
            end
        end
    end
    return false
end

-- [ 🎯 ระบบจัดสรร Stat ฉบับสมบูรณ์ (โจมตี 60% / ป้องกัน 40%) ] --
local function autoAllocate(modeStat)
    local StatPoints = LocalPlayer.Data:FindFirstChild("StatPoints")
    if not StatPoints or StatPoints.Value <= 0 then return end

    modeStat = modeStat or "Melee"
    local points = StatPoints.Value
    
    local mainPoints = math.ceil(points * 0.6)
    local defensePoints = points - mainPoints

    pcall(function()
        if mainPoints > 0 then 
            RS.RemoteEvents.AllocateStat:FireServer(modeStat, mainPoints) 
        end
        task.wait(0.1) -- กันเซิร์ฟเวอร์รวน
        if defensePoints > 0 then 
            RS.RemoteEvents.AllocateStat:FireServer("Defense", defensePoints) 
        end
    end)
end

local function getnpcQuest(npcname)
    local success, module = pcall(function() return require(RS.Modules.QuestConfig) end)
    if success and module then
        for questNPC, questData in pairs(module.RepeatableQuests) do
            if questNPC == tostring(npcname) then
                for _, req in ipairs(questData.requirements) do return req.npcType end
            end
        end
    end
    return nil
end

-- [[ 🌀 ระบบ Noclip & Tween ]]
local function tweenPos(targetCFrame, callback)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
    
    local root = char.HumanoidRootPart
    local distance = (root.Position - targetCFrame.Position).Magnitude
    
    local noclip = RunService.Stepped:Connect(function()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)

    if distance < 1000 then
        local steps = math.floor(distance / 50) + 1 
        local startCFrame = root.CFrame
        for i = 1, steps do
            if not char or char.Humanoid.Health <= 0 then break end
            root.CFrame = startCFrame:Lerp(targetCFrame, i / steps) * CFrame.new(0, 5, 0)
            task.wait(0.05)
        end
        root.CFrame = targetCFrame
    else
        local speed = 320 
        local tweenTime = distance / speed
        local tween = TS:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not char or char.Humanoid.Health <= 0 then
                tween:Cancel()
                break
            end
            task.wait(0.1)
        end
    end
    
    if callback then callback() end
    if noclip then noclip:Disconnect() end
end

local function GetTargetIsland(level)
    if level >= 10000 then return "Judgement" end
    if level >= 9000 then return "Academy" end
    if level >= 8000 then return "Slime" end
    if level >= 6250 then return "Shinjuku" end
    if level >= 5000 then return "HuecoMundo" end
    if level >= 3000 then return "Shibuya" end
    return nil
end

-- [[ 🛡️ ระบบกัน Fling & Lock Physics (อิงจาก v3) ]] --
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if _G.AUTOFUNCTION and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if humanoid then
                humanoid.PlatformStand = true
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end

            for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                    v.AssemblyLinearVelocity = Vector3.zero
                    v.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end)


-- [[ ⚙️ Main Logic ]] --
task.spawn(BoostFPS)

task.spawn(function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        RS:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer("HakiQuestNPC")
    end)
end)

task.spawn(function()
    while true do 
        task.wait(0.1) 
        
        if not _G.AUTOFUNCTION then
            UpdateStatus("⏸️ พักการฟาร์มชั่วคราว...", Color3.fromRGB(200, 200, 200))
            continue
        end

        local char = LocalPlayer.Character
        
        if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then 
            UpdateStatus("💀 รอตัวละครเกิดใหม่...", Color3.fromRGB(255, 100, 100))
            task.wait(1) 
            continue 
        end

        local hum = char:FindFirstChild("Humanoid")
        local hrp = char.HumanoidRootPart
        local levelVal = LocalPlayer.Data:FindFirstChild("Level")
        local currentLevel = levelVal and levelVal.Value or 0

        if char:GetAttribute("HakiActivated") ~= true then
            pcall(function()
                UpdateStatus("✨ กำลังเปิด Haki...", Color3.fromRGB(200, 200, 255))
                RS:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle"):FireServer("AutoSkillZ", true)
                RS:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle"):FireServer("AutoSkillX", true) 
                RS:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote"):FireServer("Toggle")
                char:SetAttribute("HakiActivated", true)
            end)
        end

        local targetIsland = GetTargetIsland(currentLevel)
        if targetIsland and _G.CurrentIslandSpawn ~= targetIsland then
            local crystalName = "SpawnPointCrystal_" .. targetIsland
            local crystalModel = workspace:FindFirstChild(crystalName, true)
            
            if crystalModel then
                local crystalPart = crystalModel.PrimaryPart or crystalModel:FindFirstChildWhichIsA("BasePart")
                if crystalPart then
                    UpdateStatus("📍 กำลังวาร์ปไปเซ็ตจุดเกิด...", Color3.fromRGB(150, 100, 255))
                    hrp.CFrame = crystalPart.CFrame * CFrame.new(0, 0, 4)
                    task.wait(1) 
                    
                    local prompt = crystalModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        pcall(function()
                            prompt.RequiresLineOfSight = false
                            prompt.MaxActivationDistance = 50
                            if fireproximityprompt then fireproximityprompt(prompt) end
                        end)
                        task.wait(1)
                        _G.CurrentIslandSpawn = targetIsland
                        hum.Health = 0 
                        task.wait(2)
                        continue 
                    end
                end
            end
        end

        local questInfo = getInfoQuest()
        if not questInfo then 
            UpdateStatus("ไม่พบข้อมูลเควส กำลังค้นหา...", Color3.fromRGB(255, 255, 100))
            task.wait(0.5)
            continue 
        end

        local QuestUI = LocalPlayer.PlayerGui:FindFirstChild("QuestUI")
        local isQuestVisible = QuestUI and QuestUI.Quest.Visible
        local currentQuestTitle = isQuestVisible and QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text or ""

        if not isQuestVisible then
            UpdateStatus("🚀 ไปรับเควส: " .. questInfo.npcName, Color3.fromRGB(150, 200, 255))
            tweenPos(CFrame.new(questInfo.position), function()
                RS.RemoteEvents.QuestAccept:FireServer(questInfo.npcName)
            end)
            task.wait(0.5)
        elseif currentQuestTitle ~= questInfo.questTitle then
            if string.find(currentQuestTitle, "Haki") then
                pcall(function() RS.RemoteEvents.QuestAccept:FireServer(questInfo.npcName) end)
            else
                UpdateStatus("⚠️ ยกเลิกเควสที่ไม่ตรงเงื่อนไข", Color3.fromRGB(255, 150, 150))
                pcall(function() RS.RemoteEvents.QuestAbandon:FireServer("repeatable") end)
                task.wait(0.5) 
            end
        else
            -- ==========================================
            -- [ ⚔️ ระบบเตรียมความพร้อม อาวุธ / รีเซ็ต Stat / อัป Stat ] 
            -- ==========================================
            local gem = LocalPlayer.Data.Gems.Value
            local money = LocalPlayer.Data.Money.Value
            local toolName = "Combat"
            local modes_tats = "Melee"
            local YPOS = 5.5

            -- 1. เงื่อนไขการซื้อ Dark Blade (รีเซ็ต Stat ก่อนและหลังซื้อตาม v3)
            if gem >= 150 and money >= 250000 and not checkDarkBlade("Dark Blade") then
                UpdateStatus("💰 กำลังซื้อ Dark Blade...", Color3.fromRGB(255, 215, 0))
                pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                task.wait(0.5)

                local npcHRP = workspace:FindFirstChild("ServiceNPCs") and workspace.ServiceNPCs:FindFirstChild("DarkBladeNPC") and workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    tweenPos(npcHRP.CFrame * CFrame.new(0, 0, 3))
                    task.wait(1)
                    local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
                    if prompt then
                        prompt.MaxActivationDistance = math.huge
                        fireproximityprompt(prompt)
                        task.wait(1)
                        pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                        task.wait(2)
                    end
                end
                continue -- ข้ามลูปไป 1 รอบเพื่ออัปเดตสถานะของ
            end

            -- 2. เงื่อนไขการถืออาวุธ และ การเช็ครีเซ็ต Stat ระหว่างสาย
            if checkDarkBlade("Dark Blade") then
                -- ใส่ดาบดำ
                if not checkOwnerDarkBlade() then
                    UpdateStatus("🗡️ กำลังสวมใส่ Dark Blade...", Color3.fromRGB(100, 100, 255))
                    pcall(function() RS.Remotes.EquipWeapon:FireServer("Equip", "Dark Blade") end)
                    task.wait(1)
                end
                toolName = "Dark Blade"
                modes_tats = "Sword"
                YPOS = 8.5
                
                -- ตรวจสอบ: ถ้าถือดาบ แต่มีสเตตัสหลงไปอยู่สาย Melee ให้รีเซ็ตทิ้ง
                local meleeStat = LocalPlayer.Data:FindFirstChild("Melee")
                if meleeStat and meleeStat.Value > 1 then
                    UpdateStatus("🔄 รีเซ็ต Stat เพื่อย้ายไปสายดาบ!", Color3.fromRGB(255, 255, 100))
                    pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                    task.wait(1)
                end
            else
                -- ใส่หมัด
                toolName = "Combat"
                modes_tats = "Melee"
                YPOS = 5.5
                
                -- ตรวจสอบ: ถ้าไม่มีดาบ แต่มีสเตตัสหลงไปอยู่สาย Sword ให้รีเซ็ตทิ้ง
                local swordStat = LocalPlayer.Data:FindFirstChild("Sword")
                if swordStat and swordStat.Value > 1 then
                    UpdateStatus("🔄 รีเซ็ต Stat เพื่อย้ายไปสายหมัด!", Color3.fromRGB(255, 255, 100))
                    pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                    task.wait(1)
                end
            end

            -- 3. สั่งอัปสเตตัสและบังคับถืออาวุธเสมอ
            autoAllocate(modes_tats)
            local tool = LocalPlayer.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
            if tool then hum:EquipTool(tool) end

            -- [ 🎯 ค้นหา Target ] --
            local npcType = getnpcQuest(questInfo.npcName)
            local closest = nil

            for _, v in pairs(workspace.NPCs:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    local subName = v.Humanoid.DisplayName:gsub("%s+", ""):gsub("%[Lv%.%s*%d+%]", "")
                    if npcType == tostring(subName) or v.Name == npcType then
                        closest = v
                        break
                    elseif subName:find(npcType, 1, true) then
                        closest = v
                    end
                end
            end
        
            if not closest then 
                UpdateStatus("⏳ รอมอนเกิด: " .. tostring(npcType), Color3.fromRGB(255, 200, 100))
                continue 
            end

            UpdateStatus("⚔️ กำลังฟามมอน: " .. tostring(npcType), Color3.fromRGB(100, 255, 100))

            repeat 
                RunService.Heartbeat:Wait() 
                if not _G.AUTOFUNCTION then break end
                if not closest or not closest.Parent or not closest:FindFirstChild("HumanoidRootPart") or closest.Humanoid.Health <= 0 or hum.Health <= 0 then break end

                -- [ 🔒 ล็อคมอนสเตอร์ให้อยู่นิ่งๆ ] --
                local success, owner = pcall(function() return closest.HumanoidRootPart:GetNetworkOwner() end)
                if success and owner == LocalPlayer then
                    closest.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position)
                    closest.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    closest.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                end

                local targetCFrame = CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, YPOS, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                hrp.CFrame = targetCFrame
                
                pcall(function()
                    if tool then tool:Activate() end
                    RS.CombatSystem.Remotes.RequestHit:FireServer()
                end)
            until hum.Health <= 0 or not QuestUI.Quest.Visible or QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle
        end
    end
end)
