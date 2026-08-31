--[[
    ══════════════════════════════════════════════════════════════════════════════
    (学乱) GAKURAN - PRO AUTO PHOTO QUEST & YEN FARM [TURBO SPEED & AIR FREEZE]
    ══════════════════════════════════════════════════════════════════════════════
    MADE BY XDFLEX HUB
    
    Configuration (Set in getgenv() before or with loadstring):
    -----------------------------------------------------------------------------
    getgenv().Disable3D    = true                  -- Disable 3D Rendering (Black Screen / Max FPS / No Crash)
    getgenv().AutoPay      = true                  -- Enable / Disable Auto Pay
    getgenv().TargetPay    = "XDFLEX67"            -- Target Yen Tag (without ¥)
    getgenv().PayThreshold = 5000                  -- Min balance before auto sending (e.g. 5000)
    getgenv().PayAmount    = "all"                 -- Amount to send: e.g. 5000 or "all" to send everything!
    -----------------------------------------------------------------------------
--]]

-- 0. SMART LOAD & INITIALIZATION GUARD
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
while not LP do
    task.wait(0.5)
    LP = Players.LocalPlayer
end

local RepS = game:GetService("ReplicatedStorage")
local Remotes = RepS:WaitForChild("Remotes", 30)

-- First-Time Profile Creation Auto-Handler (100% Automated Confirmation)
local function HandleFirstTimeProfileCreation()
    pcall(function()
        local pgui = LP:WaitForChild("PlayerGui", 10)
        local profileSetup = pgui and pgui:FindFirstChild("ProfileSetup")
        if profileSetup and profileSetup.Enabled then
            local randomNames = {
                "Ren", "Haruto", "Yuto", "Sota", "Yuki", "Riku", "Kaito", "Takumi", "Shoma", "Daiki",
                "Yui", "Rio", "Hina", "Aoi", "Rin", "Miyu", "Yuna", "Sakura", "Nanami", "Mei",
                "Kazuya", "Kenji", "Shin", "Tatsuya", "Ryoma", "Akira", "Kazuma", "Hayato", "Koki"
            }
            local chosenName = randomNames[math.random(1, #randomNames)]
            local chosenGender = (math.random(1, 2) == 1) and "Male" or "Female"

            -- 1. Click Gender Button in UI to set internal state upvalue (Gender)
            local genderBtn = profileSetup:FindFirstChild(chosenGender, true)
            if genderBtn and getconnections then
                for _, c in ipairs(getconnections(genderBtn.MouseButton1Click)) do c:Fire() end
                for _, c in ipairs(getconnections(genderBtn.Activated)) do c:Fire() end
            end

            -- 2. Fill Name into TextBox
            local textBox = profileSetup:FindFirstChild("TextBox", true)
            if textBox then
                textBox.Text = chosenName
                if getconnections then
                    for _, c in ipairs(getconnections(textBox.FocusLost)) do c:Fire(true) end
                end
            end

            task.wait(0.2)

            -- 3. Execute ProfileServiceClient's exact internal Confirm function
            local confirmBtn = profileSetup:FindFirstChild("TextButton", true)
            local innerSubmitFn = nil
            if confirmBtn and getconnections then
                local conns = getconnections(confirmBtn.MouseButton1Click)
                if conns and conns[1] and conns[1].Function then
                    pcall(function()
                        innerSubmitFn = debug.getupvalue(conns[1].Function, 2)
                    end)
                end
            end

            if innerSubmitFn and type(innerSubmitFn) == "function" then
                pcall(innerSubmitFn)
            else
                if confirmBtn and getconnections then
                    for _, c in ipairs(getconnections(confirmBtn.MouseButton1Click)) do c:Fire() end
                    for _, c in ipairs(getconnections(confirmBtn.Activated)) do c:Fire() end
                end
            end

            -- 4. Wait until Character and Game fully load and ProfileSetup is closed
            local startWait = os.clock()
            while profileSetup and profileSetup.Parent and (os.clock() - startWait) < 6 do
                task.wait(0.3)
                profileSetup = pgui:FindFirstChild("ProfileSetup")
            end
        end
    end)
end
HandleFirstTimeProfileCreation()

-- 1. รอ Character, Humanoid และ RootPart ให้โหลดสมบูรณ์
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 30)
local Root = Character:WaitForChild("HumanoidRootPart", 30)

-- 2. รอจนกว่าระบบเกมจะปล่อยการควบคุม (WalkSpeed > 0 และ CameraType == Custom)
repeat 
    task.wait(0.5) 
    Character = LP.Character or Character
    Humanoid = Character and Character:FindFirstChild("Humanoid") or Humanoid
until Humanoid and Humanoid.WalkSpeed > 0 and workspace.CurrentCamera and workspace.CurrentCamera.CameraType == Enum.CameraType.Custom

-- 3. หน่วงเซฟตี้กันเหนียวเพื่อให้เกมโหลด Remotes & Environment เสร็จ 100%
task.wait(4.5)

local Submit = Remotes:WaitForChild("PhotoJobSubmit", 20)
local JobState = Remotes:WaitForChild("PhotoJobState", 20)
local ReqSit = Remotes:FindFirstChild("RequestSit")

-- 1. CLEANUP PREVIOUS RUN (STRICT ZERO-LEAK CLEANUP)
if _G.GakuranState and type(_G.GakuranState.Cleanup) == "function" then
    pcall(_G.GakuranState.Cleanup)
    task.wait(0.2)
end

_G.GakuranState = {
    Running        = true,
    Connections    = {},
    Threads        = {},
    Render3D       = true,
    Action         = "Starting...",
    TaskText       = "Waiting for Task...",
    Target         = "Searching...",
    Money          = "¥0",
    Log            = "<font color='#AAAAAA'>Bot initialized</font>",
    ShiftEarned    = 0,
    RawTaskText    = nil,
    TargetUserId   = nil,
    TargetArea     = nil,
    LastSubmitTime = 0,
    LastRerollTime = 0,
    LastPayTime    = 0,
    LastTagCheck   = 0,
    LastShiftKick  = os.clock(),
    LastGCCollect  = os.clock(),
    LastHudUpdate  = 0,
    LastRenderedText = "",
    RetryCount     = 0,
    IsBusy         = false,
}
local G = _G.GakuranState

function G.Cleanup()
    G.Running = false
    for _, c in ipairs(G.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(G.Connections)
    for _, t in ipairs(G.Threads) do pcall(function() task.cancel(t) end) end
    table.clear(G.Threads)
    pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(true) end)
    for _, par in ipairs({
        game:GetService("CoreGui"),
        gethui and gethui() or nil,
        LP:FindFirstChild("PlayerGui")
    }) do
        if par then
            local h = par:FindFirstChild("GakuranHUD")
            if h then pcall(function() h:Destroy() end) end
        end
    end
    pcall(function() collectgarbage("collect") end)
end

-- 2. ULTRA-LOW MEMORY OPTIMIZER & 15 FPS CAP (CLOUD PHONE / PC BULLETPROOF)
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui  = game:GetService("CoreGui")
local VU       = game:GetService("VirtualUser")

pcall(function()
    if setfpscap then 
        setfpscap(15)
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostProcessEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
            v.Enabled = false
        end
    end
end)

-- 3. ZERO-LEAK PERMANENT ANTI-SIT
local function ForceUnsit(c)
    if not c then return end
    local hum = c:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.Sit = false
    if ReqSit then pcall(function() ReqSit:FireServer(false) end) end
end
if LP.Character then ForceUnsit(LP.Character) end
table.insert(G.Connections, LP.CharacterAdded:Connect(ForceUnsit))

-- 4. DUAL LAYER ANTI-AFK
table.insert(G.Connections, LP.Idled:Connect(function()
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.zero)
    end)
end))

local afkThread = task.spawn(function()
    while G.Running do
        task.wait(60)
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.zero)
        end)
    end
end)
table.insert(G.Threads, afkThread)

-- 5. SKY SAFEZONE
local SafePos = Vector3.new(0, 1000, 0)
if not workspace:FindFirstChild("GakuranSafePlatform") then
    local p = Instance.new("Part")
    p.Name = "GakuranSafePlatform"
    p.Size = Vector3.new(40, 2, 40)
    p.Position = SafePos - Vector3.new(0, 2, 0)
    p.Anchored = true
    p.Transparency = 0.6
    p.Material = Enum.Material.SmoothPlastic
    p.Color = Color3.fromRGB(0, 230, 160)
    p.Parent = workspace
end

local function GoSafe()
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        r.CFrame = CFrame.new(SafePos + Vector3.new(0, 2, 0))
    end
end

-- 6. STANDALONE NEWSPAPER JOB & YEN SERVICE LOOKUP
local NJob = nil
local YenService = nil

local function SafeInitialLookup()
    if NJob and YenService then return end
    if not getgc then return end

    task.spawn(function()
        pcall(function()
            local list = getgc(true)
            if not list then return end
            for i = 1, #list do
                local v = list[i]
                if type(v) == "table" then
                    if not NJob and rawget(v, "GetRegistered") and rawget(v, "GetByKey") then
                        for _, item in ipairs(v.GetRegistered()) do
                            if item.Key == "SchoolNewspaper" then NJob = item; break end
                        end
                    end
                    if not YenService and rawget(v, "_yenAppSubmitSend") then
                        local uvs = getupvalues(v._yenAppSubmitSend)
                        if uvs and type(uvs[2]) == "table" then
                            YenService = uvs[2]
                        end
                    end
                end
                if NJob and YenService then break end
            end
            table.clear(list)
            list = nil
            collectgarbage("collect")
        end)
    end)
end
SafeInitialLookup()

local function EnsureShift()
    if NJob then
        if not NJob.IsActive() then
            pcall(function() NJob.Start() end)
            task.wait(0.2)
        end
    end
end

local function Reroll(reason)
    local now = os.clock()
    if now - G.LastRerollTime < 1.0 then return end
    G.LastRerollTime = now
    G.Action = "Rerolling..."
    G.Log = string.format("<font color='#FF5555'>[SKIP] %s</font>", reason or "Stuck / Missing")
    G.RetryCount = 0
    G.RawTaskText = nil
    if NJob then
        pcall(function() NJob.Stop() end)
        task.wait(0.15)
        pcall(function() NJob.Start() end)
        task.wait(0.2)
    end
    GoSafe()
end

-- Live Wallet & Tag Resolver Function
local function GetLiveWalletData()
    local bal = 0
    local tag = ""

    if YenService and YenService.GetState then
        local ok, st = pcall(function() return YenService:GetState() end)
        if ok and st then
            if type(st.Balance) == "number" then bal = st.Balance end
            if type(st.Tag) == "string" then tag = st.Tag end
        end
    end

    if bal == 0 then
        local pgui = LP:FindFirstChild("PlayerGui")
        local balLabel = pgui and pgui:FindFirstChild("BalanceLabel", true)
        if balLabel and balLabel.Text ~= "" then
            local num = tonumber(balLabel.Text:gsub("[^%d]", ""))
            if num then bal = num end
        end
    end

    return bal, tag
end

-- AUTO CLAIM YEN TAG (IF ACCOUNT DOES NOT HAVE A TAG YET)
local function EnsureYenTag()
    local now = os.clock()
    if (now - G.LastTagCheck) < 10 then return end
    G.LastTagCheck = now

    if not YenService or not YenService.GetTag or not YenService.ClaimTag then return end

    local currentTag = ""
    pcall(function() currentTag = YenService:GetTag() or "" end)

    if currentTag == "" or currentTag == nil or currentTag == "none" then
        local randomTag = "XD" .. tostring(math.random(10, 99)) .. string.char(math.random(65, 90)) .. tostring(math.random(100, 999))
        pcall(function()
            YenService:ClaimTag(randomTag)
            G.Log = string.format("<font color='#00E6FF'>[TAG] Claimed @%s</font>", randomTag)
        end)
    end
end

-- AUTO PAY
local function CheckAndAutoPay()
    local genv = (getgenv and getgenv()) or _G
    local autoPayEnabled = genv.AutoPay or genv.targetpay ~= nil or genv.TargetPay ~= nil
    local targetTag = genv.TargetPay or genv.targetpay
    local rawPayAmount = genv.PayAmount or genv.amount or genv.payamount
    local rawThreshold = genv.PayThreshold or genv.threshold

    if not autoPayEnabled or not targetTag or targetTag == "" then return end
    targetTag = targetTag:gsub("^¥", ""):gsub("^%s*(.-)%s*$", "%1")

    local now = os.clock()
    if (now - G.LastPayTime) < 5 then return end

    local currentBal, currentTag = GetLiveWalletData()

    if currentTag ~= "" and currentTag:lower() == targetTag:lower() then
        return
    end

    -- Determine threshold
    local threshold = 5000
    if rawThreshold then
        threshold = tonumber(rawThreshold) or 5000
    elseif type(rawPayAmount) == "number" then
        threshold = rawPayAmount
    end

    -- Determine pay amount ('all', 'max', or fixed number)
    local payAmount = 0
    local isAll = false
    if type(rawPayAmount) == "string" and (rawPayAmount:lower() == "all" or rawPayAmount:lower() == "max") then
        isAll = true
        payAmount = currentBal
    else
        payAmount = tonumber(rawPayAmount or 5000) or 5000
        if payAmount > currentBal then
            payAmount = currentBal
        end
    end

    if currentBal >= threshold and payAmount >= 10 then
        G.LastPayTime = now
        G.Action = "Auto Paying ¥" .. tostring(payAmount) .. " to @" .. targetTag .. "..."
        G.Log = string.format("<font color='#00E6FF'>[PAY] Sent ¥%s to @%s</font>", tostring(payAmount), targetTag)
        pcall(function()
            if YenService and YenService.SendYen then
                YenService:SendYen(targetTag, payAmount)
            end
        end)
    end
end

-- 7. PHOTOJOBSTATE EVENT
table.insert(G.Connections, JobState.OnClientEvent:Connect(function(data)
    if type(data) ~= "table" then return end
    if data.Kind == "Task" then
        G.RawTaskText  = data.Text or ""
        G.TaskText     = data.Text or "get a photo"
        G.TargetUserId = data.TargetUserId or nil
        G.TargetArea   = data.Area or nil
        G.Target       = data.Label or data.Area or (data.Text and data.Text:gsub("get a photo of ", "")) or "Unknown"
        G.RetryCount   = 0
        G.Action       = "New Task!"
        G.LastShiftKick = os.clock()
    elseif data.Kind == "Paid" then
        G.Action       = "Accepted! +" .. "¥" .. tostring(data.Pay or 0)
        G.Log          = string.format("<font color='#00FF88'>[DONE] Photo Accepted! (+¥%s)</font>", tostring(data.Pay or 0))
        G.LastSubmitTime = os.clock()
        G.RetryCount   = 0
        G.LastShiftKick = os.clock()
    end
end))

-- 8. GUI SETUP — MADE BY XDFLEX HUB
local GuiPar = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")
do
    local old = GuiPar:FindFirstChild("GakuranHUD")
    if old then old:Destroy() end
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "GakuranHUD"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999999
Gui.Parent = GuiPar

local BG = Instance.new("Frame", Gui)
BG.Size = UDim2.new(1, 0, 1, 0)
BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BG.BorderSizePixel = 0
BG.Visible = false

local Txt = Instance.new("TextLabel", Gui)
Txt.Size = UDim2.new(0, 750, 0, 190)
Txt.AnchorPoint = Vector2.new(0.5, 0.5)
Txt.Position = UDim2.new(0.5, 0, 0.5, 0)
Txt.BackgroundTransparency = 1
Txt.Font = Enum.Font.GothamBold
Txt.TextSize = 21
Txt.TextColor3 = Color3.fromRGB(0, 255, 170)
Txt.TextStrokeTransparency = 0
Txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Txt.TextXAlignment = Enum.TextXAlignment.Center
Txt.TextYAlignment = Enum.TextYAlignment.Center
Txt.RichText = true
Txt.ZIndex = 1000001

local Btn = Instance.new("TextButton", Gui)
Btn.Size = UDim2.new(0, 130, 0, 34)
Btn.Position = UDim2.new(1, -145, 0, 15)
Btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Btn.BorderSizePixel = 0
Btn.Font = Enum.Font.GothamBold
Btn.TextSize = 13
Btn.ZIndex = 1000002
Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
local bStroke = Instance.new("UIStroke", Btn)
bStroke.Thickness = 1

local function SetRender(on)
    G.Render3D = on
    pcall(function() RS:Set3dRenderingEnabled(on) end)
    BG.Visible = not on
    if on then
        Btn.Text = "👁️ 3D: ON"
        Btn.TextColor3 = Color3.fromRGB(255, 190, 60)
        bStroke.Color = Color3.fromRGB(255, 190, 60)
    else
        Btn.Text = "👁️ 3D: OFF"
        Btn.TextColor3 = Color3.fromRGB(0, 255, 170)
        bStroke.Color = Color3.fromRGB(0, 255, 170)
    end
end

local genv = (getgenv and getgenv()) or _G
local disable3DConfig = genv.Disable3D or genv.disable3d or genv.Disable_3D or genv.BlackScreen or false
SetRender(not disable3DConfig)

table.insert(G.Connections, Btn.MouseButton1Click:Connect(function() SetRender(not G.Render3D) end))
table.insert(G.Connections, UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and (inp.KeyCode == Enum.KeyCode.RightShift or inp.KeyCode == Enum.KeyCode.Insert) then
        SetRender(not G.Render3D)
    end
end))

-- 9. TURBO PRECISION ENGINE & AIR-FREEZE SNAPSHOT
local function TrySubmitPhoto(cameraPosition, aimTargetPosition)
    local cf = CFrame.lookAt(cameraPosition, aimTargetPosition)
    local ok, res = pcall(function() return Submit:InvokeServer("Submit", cf) end)
    return ok and res or nil
end

local function RunCapture()
    if G.IsBusy or not G.RawTaskText or G.RawTaskText == "" then return end
    G.IsBusy = true
    local c = LP.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then G.IsBusy = false; return end
    local accepted = false

    local cleanTarget = G.RawTaskText:gsub("get a photo of ", ""):gsub("^the ", ""):gsub("^%s*(.-)%s*$", "%1")

    -- 1. RESOLVE PLAYER TARGET
    local targetPlayer = nil
    if G.TargetUserId then
        targetPlayer = Players:GetPlayerByUserId(G.TargetUserId)
    end
    if not targetPlayer then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then
                local pName = pl.Name:lower()
                local pDisplay = pl.DisplayName:lower()
                local ct = cleanTarget:lower()
                if pName == ct or pDisplay == ct or pName:find(ct, 1, true) or pDisplay:find(ct, 1, true) then
                    targetPlayer = pl
                    break
                end
            end
        end
    end

    if targetPlayer then
        local tChar = targetPlayer.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

        if tRoot then
            G.Action = "Capturing: " .. (targetPlayer.DisplayName or targetPlayer.Name)
            G.Target = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"

            local targetLook = tRoot.CFrame.LookVector
            local targetRight = tRoot.CFrame.RightVector
            local aimPos = tRoot.Position + Vector3.new(0, 0.5, 0)

            local playerTestAngles = {
                {pos = tRoot.Position + targetLook * 6.0, aim = aimPos},                          -- 1. Front (6.0 studs)
                {pos = tRoot.Position + targetLook * 5.0 + Vector3.new(0, 0.2, 0), aim = aimPos}, -- 2. Close Front
                {pos = tRoot.Position + targetRight * 5.5, aim = aimPos},                         -- 3. Right
                {pos = tRoot.Position - targetRight * 5.5, aim = aimPos},                         -- 4. Left
                {pos = tRoot.Position - targetLook * 5.5, aim = aimPos},                          -- 5. Rear
                {pos = tRoot.Position + targetLook * 7.5, aim = aimPos},                          -- 6. Long shot
                {pos = tRoot.Position + Vector3.new(0, -6.0, 4.5), aim = aimPos},                 -- 7. Look Up
                {pos = tRoot.Position + Vector3.new(0, -10.0, 4.0), aim = aimPos}                 -- 8. Ground Look Up
            }

            for _, test in ipairs(playerTestAngles) do
                -- Velocity Zero Freeze in Air
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
                r.CFrame = CFrame.lookAt(test.pos, test.aim)
                task.wait(0.08)

                local camPos = r.Position + Vector3.new(0, 1.4, 0)
                local res = TrySubmitPhoto(camPos, test.aim)

                if res == "Accepted" then
                    accepted = true
                    G.LastSubmitTime = os.clock()
                    G.RetryCount = 0
                    G.LastShiftKick = os.clock()
                    G.Log = string.format("<font color='#00FF88'>[DONE] Captured %s</font>", targetPlayer.DisplayName or targetPlayer.Name)
                    break
                elseif res == "Cooldown" then
                    task.wait(1.0)
                    break
                end
            end
        else
            Reroll("Player Left / Character Missing")
            G.IsBusy = false
            return
        end

    -- 2. RESOLVE AREA TARGET
    else
        local areaSearch = G.TargetArea or cleanTarget
        areaSearch = areaSearch:gsub("^the ", ""):gsub("^%s*(.-)%s*$", "%1")
        local hb = workspace:FindFirstChild("AreaHitboxes")
        local matchedPart = nil

        if hb and areaSearch ~= "" then
            local aLow = areaSearch:lower()
            for _, d in ipairs(hb:GetDescendants()) do
                if d:IsA("BasePart") then
                    local nLow = d.Name:lower()
                    if nLow == aLow then
                        matchedPart = d
                        break
                    end
                end
            end
            if not matchedPart then
                for _, d in ipairs(hb:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local nLow = d.Name:lower()
                        if nLow:find(aLow, 1, true) or aLow:find(nLow, 1, true) then
                            matchedPart = d
                            break
                        end
                    end
                end
            end
        end

        if not matchedPart and areaSearch ~= "" then
            local aLow = areaSearch:lower()
            for _, d in ipairs(workspace:GetChildren()) do
                if d:IsA("BasePart") or d:IsA("Model") then
                    local nLow = d.Name:lower()
                    if nLow == aLow or nLow:find(aLow, 1, true) or aLow:find(nLow, 1, true) then
                        matchedPart = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
                        if matchedPart then break end
                    end
                end
            end
        end

        if matchedPart then
            G.Action = "Capturing: " .. areaSearch
            G.Target = areaSearch

            local areaPos = matchedPart.Position

            local areaAngles = {
                {pos = areaPos + Vector3.new(0, 1.5, 9.0), aim = areaPos},
                {pos = areaPos + Vector3.new(9.0, 1.5, 0), aim = areaPos},
                {pos = areaPos + Vector3.new(0, 1.5, -9.0), aim = areaPos},
                {pos = areaPos + Vector3.new(-9.0, 1.5, 0), aim = areaPos},
                {pos = areaPos + Vector3.new(0, 2.0, 12.0), aim = areaPos},
                {pos = areaPos + Vector3.new(0, -6.0, 6.0), aim = areaPos},
                {pos = areaPos + Vector3.new(0, -11.0, 5.0), aim = areaPos}
            }

            for _, test in ipairs(areaAngles) do
                -- Velocity Zero Freeze in Air
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
                r.CFrame = CFrame.lookAt(test.pos, test.aim)
                task.wait(0.08)

                local camPos = r.Position + Vector3.new(0, 1.4, 0)
                local res = TrySubmitPhoto(camPos, test.aim)

                if res == "Accepted" then
                    accepted = true
                    G.LastSubmitTime = os.clock()
                    G.RetryCount = 0
                    G.LastShiftKick = os.clock()
                    G.Log = string.format("<font color='#00FF88'>[DONE] Captured %s</font>", areaSearch)
                    break
                elseif res == "Cooldown" then
                    task.wait(1.0)
                    break
                end
            end
        else
            Reroll("Area Part Missing")
            G.IsBusy = false
            return
        end
    end

    GoSafe()

    if not accepted then
        G.RetryCount = G.RetryCount + 1
        if G.RetryCount >= 5 then
            Reroll("Target Stuck After 5 Tries")
        else
            G.Action = "Safezone (Retrying " .. tostring(G.RetryCount) .. "/5)..."
        end
    end

    G.IsBusy = false
end

-- 10. MAIN CONTROLLER LOOP (TURBO 0.05S DISPATCH)
local mainThread = task.spawn(function()
    while G.Running do
        task.wait(0.05)

        -- Ingame Rules Modal Bypass
        pcall(function()
            local pgui = LP:FindFirstChild("PlayerGui")
            local rules = pgui and pgui:FindFirstChild("RulesScreenGui")
            if rules and rules.Enabled then
                local btn = rules:FindFirstChild("AgreeButton", true)
                if btn and btn:IsA("GuiButton") and getconnections then
                    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                    for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                end
                rules.Enabled = false
            end
        end)

        -- Instant Anti-Sit Enforcement
        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
            if ReqSit then pcall(function() ReqSit:FireServer(false) end) end
        end

        EnsureShift()
        EnsureYenTag()
        CheckAndAutoPay()

        -- Instant Task Detection from Ingame Card (Top Right Assignment)
        local pgui = LP:FindFirstChild("PlayerGui")
        local photoGui = pgui and pgui:FindFirstChild("PhotoJobGui")
        local card = photoGui and photoGui:FindFirstChild("Card")

        if card then
            local taskLabel = card:FindFirstChild("Task")
            if taskLabel and taskLabel.Text ~= "" then
                if G.TaskText ~= taskLabel.Text or not G.RawTaskText or G.RawTaskText ~= taskLabel.Text then
                    G.TaskText = taskLabel.Text
                    G.RawTaskText = taskLabel.Text
                    G.Target = taskLabel.Text:gsub("get a photo of ", "")
                    G.RetryCount = 0
                    G.LastShiftKick = os.clock()
                end
            end
        end

        -- Anti-Stuck Auto Kick: If stuck in "Waiting for Task..." for >4 seconds, force restart shift!
        if (not G.RawTaskText or G.RawTaskText == "") and (os.clock() - G.LastShiftKick) > 4 then
            G.LastShiftKick = os.clock()
            Reroll("Shift Stalled (No Task Assigned)")
        end

        -- Live Money Tracking
        pcall(function()
            local currentBal = GetLiveWalletData()
            local shiftYen = card and card:FindFirstChild("Yen") and card.Yen.Text

            if currentBal > 0 then
                if shiftYen and shiftYen ~= "¥0" and shiftYen ~= "" then
                    G.Money = "¥" .. tostring(currentBal) .. " (shift: " .. shiftYen .. ")"
                else
                    G.Money = "¥" .. tostring(currentBal)
                end
            elseif shiftYen and shiftYen ~= "" then
                G.Money = "Shift: " .. shiftYen
            end
        end)

        -- Fast Dispatch Controller (Turbo Cooldown 1.0s)
        if G.RawTaskText and G.RawTaskText ~= "" then
            local now = os.clock()
            if (now - G.LastSubmitTime) >= 1.0 and not G.IsBusy then
                task.spawn(RunCapture)
            elseif not G.IsBusy and (now - G.LastSubmitTime) < 1.0 then
                local cd = math.max(0, 1.0 - (now - G.LastSubmitTime))
                G.Action = string.format("Safezone (CD: %.1fs)", cd)
            end
        else
            GoSafe()
            if not G.IsBusy then
                G.Action = "Waiting for Task..."
                G.Target = "Searching..."
            end
        end

        -- Active Garbage Collector Cycle every 20 seconds
        local now = os.clock()
        if (now - G.LastGCCollect) > 20 then
            G.LastGCCollect = now
            pcall(function() collectgarbage("collect") end)
        end

        -- Diff-Based HUD Update
        if (now - G.LastHudUpdate) >= 0.5 then
            G.LastHudUpdate = now
            local newText = string.format(
                "<font color='#00E6FF' size='14'><b>MADE BY XDFLEX HUB</b></font>\n" ..
                "<font color='#AAAAAA'>Task:   </font> <font color='#FFFFFF'>%s</font>\n" ..
                "<font color='#AAAAAA'>Action: </font> <font color='#00E6A0'>%s</font>\n" ..
                "<font color='#AAAAAA'>Target: </font> <font color='#FFFF00'>%s</font>\n" ..
                "<font color='#AAAAAA'>Money:  </font> <font color='#00FF88'>%s</font>\n" ..
                "<font color='#AAAAAA'>Log:    </font> %s",
                G.TaskText,
                G.Action,
                G.Target,
                G.Money,
                G.Log
            )
            if newText ~= G.LastRenderedText then
                G.LastRenderedText = newText
                pcall(function() Txt.Text = newText end)
            end
        end
    end
end)
table.insert(G.Threads, mainThread)
