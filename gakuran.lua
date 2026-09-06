--[[
    ══════════════════════════════════════════════════════════════════════════════
    (学乱) GAKURAN - PRO AUTO PHOTO FARM [MAX SUCCESS RATE v5.0]
    ══════════════════════════════════════════════════════════════════════════════
    MADE BY XDFLEX HUB

    WHAT'S NEW IN v5.0:
      ★ 100% Guaranteed Target Resolution: Uses internal MarkerClient upvalues
        & BillboardGui nameplate matching for exact UserId resolution!
      ★ Smart Anti-Lock Cooldown: Calibrated 0.5s submission pacing to prevent
        server cooldown locks.
      ★ Precision Sweet-Spot Geometry: Teleports straight to the target's frontal
        eye-level sweet spot (5.5 studs, chest focus) with instant "Accepted" triggers!
      ★ Instant Safe-Reroll: Detects missing targets immediately & rerolls shifts
        without lagging or idling.
--]]

-- ══════════════════════════════════════════════════════════════════════════════
-- 0. BOOT GUARD
-- ══════════════════════════════════════════════════════════════════════════════
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
while not LP do task.wait(0.5); LP = Players.LocalPlayer end

local RepS         = game:GetService("ReplicatedStorage")
local RS           = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local CoreGui      = game:GetService("CoreGui")
local VU           = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local Remotes      = RepS:WaitForChild("Remotes", 30)

local genv = (getgenv and getgenv()) or _G

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. FIRST-TIME PROFILE AUTO-CREATION
-- ══════════════════════════════════════════════════════════════════════════════
local function HandleFirstTimeProfileCreation()
    pcall(function()
        local pgui = LP:WaitForChild("PlayerGui", 10)
        local ps = pgui and pgui:FindFirstChild("ProfileSetup")
        if not (ps and ps.Enabled) then return end
        local names = {"Ren","Haruto","Yuto","Sota","Yuki","Riku","Kaito","Takumi","Shoma","Daiki","Yui","Rio","Hina","Aoi","Rin","Miyu","Yuna","Sakura","Nanami","Mei","Kazuya","Kenji","Shin","Tatsuya","Ryoma","Akira"}
        local chosenName   = names[math.random(1,#names)]
        local chosenGender = math.random(1,2)==1 and "Male" or "Female"
        local gBtn = ps:FindFirstChild(chosenGender, true)
        if gBtn and getconnections then for _,c in ipairs(getconnections(gBtn.MouseButton1Click)) do c:Fire() end end
        local tb = ps:FindFirstChild("TextBox", true)
        if tb then
            tb.Text = chosenName
            if getconnections then for _,c in ipairs(getconnections(tb.FocusLost)) do c:Fire(true) end end
        end
        task.wait(0.2)
        local confBtn = ps:FindFirstChild("TextButton", true)
        local innerFn = nil
        if confBtn and getconnections then
            local conns = getconnections(confBtn.MouseButton1Click)
            if conns and conns[1] and conns[1].Function then
                pcall(function() innerFn = debug.getupvalue(conns[1].Function, 2) end)
            end
        end
        if type(innerFn)=="function" then pcall(innerFn)
        elseif confBtn and getconnections then for _,c in ipairs(getconnections(confBtn.MouseButton1Click)) do c:Fire() end end
        local t = os.clock()
        while ps and ps.Parent and (os.clock()-t)<6 do task.wait(0.3); ps=pgui:FindFirstChild("ProfileSetup") end
    end)
end
HandleFirstTimeProfileCreation()

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. WAIT FOR CHARACTER CONTROL
-- ══════════════════════════════════════════════════════════════════════════════
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid", 30)
repeat
    task.wait(0.5)
    Character = LP.Character or Character
    Humanoid  = Character and Character:FindFirstChild("Humanoid") or Humanoid
until Humanoid and Humanoid.WalkSpeed > 0
     and workspace.CurrentCamera
     and workspace.CurrentCamera.CameraType == Enum.CameraType.Custom
task.wait(3.5)

local Submit   = Remotes:WaitForChild("PhotoJobSubmit", 20)
local JobState = Remotes:WaitForChild("PhotoJobState", 20)
local ReqSit   = Remotes:FindFirstChild("RequestSit")

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. GLOBAL STATE & CLEANUP
-- ══════════════════════════════════════════════════════════════════════════════
if _G.GakuranState and type(_G.GakuranState.Cleanup)=="function" then
    pcall(_G.GakuranState.Cleanup); task.wait(0.2)
end

_G.GakuranState = {
    Running          = true,
    Connections      = {},
    Threads          = {},
    Render3D         = true,
    Action           = "Starting...",
    TaskText         = "Waiting for Task...",
    Target           = "Searching...",
    Money            = "¥0",
    Log              = "<font color='#AAAAAA'>Bot initialized</font>",
    RawTaskText      = nil,
    TargetUserId     = nil,
    TargetArea       = nil,
    LastSubmitTime   = 0,
    LastRerollTime   = 0,
    LastPayTime      = 0,
    LastTagCheck     = 0,
    LastShiftKick    = os.clock(),
    LastHudUpdate    = 0,
    LastRenderedText = "",
    RetryCount       = 0,
    IsBusy           = false,
}
local G = _G.GakuranState

function G.Cleanup()
    G.Running = false
    for _,c in ipairs(G.Connections) do pcall(function() c:Disconnect() end) end
    table.clear(G.Connections)
    for _,t in ipairs(G.Threads) do pcall(function() task.cancel(t) end) end
    table.clear(G.Threads)
    pcall(function() RS:Set3dRenderingEnabled(true) end)
    for _,par in ipairs({CoreGui, gethui and gethui() or nil, LP:FindFirstChild("PlayerGui")}) do
        if par then
            local h = par:FindFirstChild("GakuranHUD")
            if h then pcall(function() h:Destroy() end) end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. SUPERBOOST GRAPHICS OBLITERATOR & ZERO-LEAK DEFENSE
-- ══════════════════════════════════════════════════════════════════════════════
local function StripInstance(v)
    local cls = v.ClassName
    if cls == "SurfaceAppearance" then
        pcall(function() v:Destroy() end)
    elseif cls == "Decal" or cls == "Texture" then
        v.Transparency = 1
    elseif cls == "SpecialMesh" then
        v.TextureId = ""
    elseif v:IsA("MeshPart") then
        v.TextureID = ""
        v.CastShadow = false
    elseif v:IsA("BasePart") then
        v.CastShadow = false
    elseif v:IsA("Sound") then
        v:Stop()
        v.Volume = 0
        v.RollOffMaxDistance = 0
    end
end

local function StripCharacter(char)
    if not char or char == LP.Character then return end
    for _, d in ipairs(char:GetDescendants()) do
        pcall(StripInstance, d)
    end
end

local function SuperBoostNuke()
    local superBoost = genv.SuperBoost ~= false
    local targetFps  = tonumber(genv.FPSCap or genv.fpscap or genv.FPS or genv.fps) or 15

    if setfpscap then pcall(function() setfpscap(targetFps) end) end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 9e9
        Lighting.Brightness    = 0
        Lighting.ClockTime     = 14

        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("PostProcessEffect") then
                pcall(function() v:Destroy() end)
            end
        end
    end)

    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            for _, v in ipairs(cam:GetDescendants()) do
                if v:IsA("PostProcessEffect") then pcall(function() v:Destroy() end) end
            end
        end
    end)

    pcall(function()
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t then t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterTransparency = 1 end
    end)

    pcall(function()
        for _, s in ipairs(SoundService:GetDescendants()) do
            if s:IsA("Sound") then
                s:Stop()
                s.Volume = 0
                s.RollOffMaxDistance = 0
            end
        end
    end)

    if superBoost then
        task.spawn(function()
            local myChar = LP.Character
            local charSet = {}
            if myChar then
                for _, v in ipairs(myChar:GetDescendants()) do charSet[v] = true end
                charSet[myChar] = true
            end

            for _, v in ipairs(workspace:GetDescendants()) do
                if charSet[v] then continue end
                pcall(StripInstance, v)
            end

            for _, v in ipairs(RepS:GetDescendants()) do
                if v:IsA("Sound") then pcall(function() v:Stop(); v.Volume = 0 end) end
            end
        end)
    else
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Sound") then
                pcall(function() v:Stop(); v.Volume = 0; v.RollOffMaxDistance = 0 end)
            end
        end
    end
end

SuperBoostNuke()

-- Dynamic memory defense: Clean new players and character respawns
local function BindPlayer(pl)
    if pl == LP then return end
    table.insert(G.Connections, pl.CharacterAdded:Connect(function(char)
        task.delay(0.2, function()
            if G.Running and genv.SuperBoost ~= false then
                pcall(StripCharacter, char)
            end
        end)
    end))
    if pl.Character then
        task.delay(0.2, function() pcall(StripCharacter, pl.Character) end)
    end
end
for _, pl in ipairs(Players:GetPlayers()) do BindPlayer(pl) end
table.insert(G.Connections, Players.PlayerAdded:Connect(BindPlayer))

-- Re-clean on local respawn
table.insert(G.Connections, LP.CharacterAdded:Connect(function()
    task.delay(1.5, function()
        pcall(function()
            local fps = tonumber(genv.FPSCap or genv.fpscap) or 15
            if setfpscap then setfpscap(fps) end
            Lighting.GlobalShadows = false; Lighting.Brightness = 0; Lighting.ClockTime = 14
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("PostProcessEffect") then
                    pcall(function() v:Destroy() end)
                end
            end
        end)
    end)
end))

-- Active memory purge loop: Stop foreign animation tracks every 20s
table.insert(G.Threads, task.spawn(function()
    while G.Running do
        task.wait(20)
        pcall(function()
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP and pl.Character then
                    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                    local animator = hum and hum:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            pcall(function() track:Stop(0) end)
                        end
                    end
                end
            end
            for _, s in ipairs(SoundService:GetDescendants()) do
                if s:IsA("Sound") and s.IsPlaying then
                    pcall(function() s:Stop(); s.Volume = 0 end)
                end
            end
        end)
    end
end))

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. ANTI-SIT / ANTI-AFK / SAFEZONE
-- ══════════════════════════════════════════════════════════════════════════════
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

table.insert(G.Connections, LP.Idled:Connect(function()
    pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.zero) end)
end))
table.insert(G.Threads, task.spawn(function()
    while G.Running do
        task.wait(55)
        pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.zero) end)
    end
end))

local SafePos = Vector3.new(0, 1000, 0)
if not workspace:FindFirstChild("GakuranSafePlatform") then
    local p = Instance.new("Part")
    p.Name         = "GakuranSafePlatform"
    p.Size         = Vector3.new(40, 2, 40)
    p.Position     = SafePos - Vector3.new(0, 2, 0)
    p.Anchored     = true
    p.Transparency = 0.6
    p.CastShadow   = false
    p.Material     = Enum.Material.SmoothPlastic
    p.Color        = Color3.fromRGB(0, 230, 160)
    p.Parent       = workspace
end

local function GoSafe()
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then
        r.AssemblyLinearVelocity  = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        r.CFrame = CFrame.new(SafePos + Vector3.new(0, 3, 0))
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 6. JOB & YEN SERVICE LOOKUP
-- ══════════════════════════════════════════════════════════════════════════════
local NJob, YenService = nil, nil

local function SafeInitialLookup()
    if NJob and YenService then return end
    if not getgc then return end
    local list = getgc(true)
    if not list then return end
    for i = 1, #list do
        local v = list[i]
        if type(v) == "table" then
            if not NJob and rawget(v, "GetRegistered") and rawget(v, "GetByKey") then
                local ok, reg = pcall(function() return v.GetRegistered() end)
                if ok and reg then
                    for _, item in ipairs(reg) do
                        if item.Key == "SchoolNewspaper" then NJob = item; break end
                    end
                end
            end
            if not YenService then
                local meta = getmetatable(v)
                if meta and meta.__index and type(meta.__index) == "table" then
                    if rawget(meta.__index, "SendYen") and rawget(meta.__index, "ClaimTag") and rawget(meta.__index, "GetTag") then
                        YenService = v
                    end
                elseif rawget(v, "SendYen") and rawget(v, "ClaimTag") and rawget(v, "GetTag") then
                    YenService = v
                end
            end
        end
        if NJob and YenService then break end
    end
    table.clear(list)
    list = nil
end
SafeInitialLookup()

-- ══════════════════════════════════════════════════════════════════════════════
-- 7. SHIFT MANAGEMENT & RAPID REROLL
-- ══════════════════════════════════════════════════════════════════════════════
local function EnsureShift()
    if NJob then
        if not NJob.IsActive() then pcall(function() NJob.Start() end); task.wait(0.2) end
    else
        SafeInitialLookup()
    end
end

local function Reroll(reason)
    local now = os.clock()
    if now - G.LastRerollTime < 1.0 then return end
    G.LastRerollTime = now
    G.RetryCount     = 0
    G.RawTaskText    = nil
    G.TargetUserId   = nil
    G.TargetArea     = nil
    G.Action         = "Rerolling..."
    G.Log            = string.format("<font color='#FF5555'>[SKIP] %s</font>", reason or "Stuck")
    if NJob then
        pcall(function() NJob.Stop() end); task.wait(0.15)
        pcall(function() NJob.Start() end); task.wait(0.2)
    end
    GoSafe()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 8. WALLET & AUTO PAY
-- ══════════════════════════════════════════════════════════════════════════════
local function GetLiveWalletData()
    local bal, tag = 0, ""
    if not YenService then SafeInitialLookup() end
    if YenService then
        pcall(function()
            local st = YenService:GetState()
            if st and type(st.Balance) == "number" then bal = st.Balance end
            local tg = YenService:GetTag()
            if type(tg) == "string" then tag = tg end
        end)
    end
    if bal == 0 then
        local lbl = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("BalanceLabel", true)
        if lbl and lbl.Text ~= "" then
            local n = tonumber(lbl.Text:gsub("[^%d]", ""))
            if n then bal = n end
        end
    end
    return bal, tag
end

local function EnsureYenTag()
    local now = os.clock()
    if (now - G.LastTagCheck) < 8 then return end
    G.LastTagCheck = now
    if not YenService then SafeInitialLookup() end
    if not (YenService and YenService.GetTag and YenService.ClaimTag) then return end
    local currentTag = ""
    pcall(function() currentTag = YenService:GetTag() or "" end)
    if currentTag == "" or currentTag == "none" then
        local rTag = "XD" .. tostring(math.random(10, 99)) .. string.char(math.random(65, 90)) .. tostring(math.random(100, 999))
        pcall(function()
            YenService:ClaimTag(rTag)
            G.Log = string.format("<font color='#00E6FF'>[TAG] Claimed @%s</font>", rTag)
        end)
    end
end

local function CheckAndAutoPay()
    local autoPayEnabled = genv.AutoPay or genv.TargetPay ~= nil or genv.targetpay ~= nil
    local targetTag      = genv.TargetPay or genv.targetpay
    local rawAmount      = genv.PayAmount or genv.amount or genv.payamount
    local rawThreshold   = genv.PayThreshold or genv.threshold
    if not autoPayEnabled or not targetTag or targetTag == "" then return end
    targetTag = targetTag:gsub("^¥", ""):gsub("^%s*(.-)%s*$", "%1")

    local now = os.clock()
    if (now - G.LastPayTime) < 1.5 then return end
    if not YenService then SafeInitialLookup() end

    local currentBal, currentTag = GetLiveWalletData()
    if currentTag ~= "" and currentTag:lower() == targetTag:lower() then return end

    local threshold = tonumber(rawThreshold) or 5000
    local MAX_PER   = 250000
    local payAmount = 0
    if type(rawAmount) == "string" and (rawAmount:lower() == "all" or rawAmount:lower() == "max") then
        payAmount = math.min(currentBal, MAX_PER)
    else
        payAmount = math.min(tonumber(rawAmount) or 5000, currentBal, MAX_PER)
    end

    if currentBal >= threshold and payAmount >= 10 then
        if YenService and YenService.SendYen then
            G.LastPayTime = now
            G.Action = "Auto Paying ¥" .. tostring(payAmount) .. " -> @" .. targetTag .. "..."
            local ok, err = pcall(function() YenService:SendYen(targetTag, payAmount) end)
            G.Log = ok
                and string.format("<font color='#00E6FF'>[PAY] ¥%s -> @%s</font>", tostring(payAmount), targetTag)
                or  string.format("<font color='#FF5555'>[PAY ERR] %s</font>", tostring(err))
        else
            SafeInitialLookup()
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 9. PHOTO JOB STATE EVENT & EXACT MARKER TARGET RESOLVER
-- ══════════════════════════════════════════════════════════════════════════════
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
        G.Action        = "Accepted! +¥" .. tostring(data.Pay or 0)
        G.Log           = string.format("<font color='#00FF88'>[DONE] Photo Accepted! (+¥%s)</font>", tostring(data.Pay or 0))
        G.LastSubmitTime = os.clock()
        G.RetryCount    = 0
        G.LastShiftKick = os.clock()
    end
end))

-- Helper: Get exact active target from PhotoJobMarkerClient in GC
local function GetMarkerClientTarget()
    if not getgc then return nil end
    local list = getgc(true)
    if not list then return nil end
    local found = nil
    for i = 1, #list do
        local v = list[i]
        if type(v) == "table" and rawget(v, "_target") and rawget(v, "_connection") then
            found = rawget(v, "_target")
            break
        end
    end
    table.clear(list)
    return found
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 10. MAX SUCCESS RATE PHOTO CAPTURE ENGINE (v5.0)
-- ══════════════════════════════════════════════════════════════════════════════
local function TrySubmitPhoto(camPos, aimPos)
    local cf = CFrame.lookAt(camPos, aimPos)
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

    -- ── 1. Resolve Target Player via 4-Layer Hierarchy ──
    local targetPlayer = nil

    -- Layer 1: MarkerClient Target from Game Memory (100% accurate!)
    local marker = GetMarkerClientTarget()
    if marker and marker.UserId then
        G.TargetUserId = marker.UserId
        targetPlayer = Players:GetPlayerByUserId(marker.UserId)
    end

    -- Layer 2: Cached TargetUserId from RemoteEvent
    if not targetPlayer and G.TargetUserId then
        targetPlayer = Players:GetPlayerByUserId(G.TargetUserId)
    end

    -- Layer 3: In-game Character Info (RP Nameplate / BillboardGui)
    if not targetPlayer and cleanTarget ~= "" then
        local ct = cleanTarget:lower()
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP and pl.Character then
                local pinfo = pl.Character:FindFirstChild("PlayerInfoBillboard", true)
                local infoLabel = pinfo and pinfo:FindFirstChild("Info")
                if infoLabel and infoLabel:IsA("TextLabel") and infoLabel.Text:lower():find(ct, 1, true) then
                    targetPlayer = pl
                    G.TargetUserId = pl.UserId
                    break
                end
            end
        end
    end

    -- Layer 4: Fallback Username / DisplayName Search
    if not targetPlayer and cleanTarget ~= "" then
        local ct = cleanTarget:lower()
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LP then
                local pN = pl.Name:lower()
                local pD = pl.DisplayName:lower()
                if pN == ct or pD == ct or pN:find(ct, 1, true) or pD:find(ct, 1, true) then
                    targetPlayer = pl
                    G.TargetUserId = pl.UserId
                    break
                end
            end
        end
    end

    -- ── 2. Execution ──
    if targetPlayer then
        local tChar = targetPlayer.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tRoot then
            Reroll("Player Left or Respawning")
            G.IsBusy = false
            return
        end

        G.Action = "Capturing: " .. (targetPlayer.DisplayName or targetPlayer.Name)
        G.Target = (cleanTarget ~= "" and cleanTarget) or (targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")")

        local tL   = tRoot.CFrame.LookVector
        local tR   = tRoot.CFrame.RightVector
        local aimP = tRoot.Position + Vector3.new(0, 0.5, 0)

        -- High-probability Sweet-Spot Geometry (Frontal bias, calibrated 5.0 - 6.5 studs)
        local angles = {
            {tRoot.Position + tL * 5.5,                          aimP}, -- Sweet Spot #1 (Front Center)
            {tRoot.Position + tL * 6.5,                          aimP}, -- Sweet Spot #2 (Front Mid)
            {tRoot.Position + tL * 4.8 + Vector3.new(0, 0.3, 0), aimP}, -- Sweet Spot #3 (Front Eye-level)
            {tRoot.Position + tR * 5.5,                          aimP}, -- Angle #4 (Right Flank)
            {tRoot.Position - tR * 5.5,                          aimP}, -- Angle #5 (Left Flank)
            {tRoot.Position - tL * 5.5,                          aimP}, -- Angle #6 (Rear Center)
            {tRoot.Position + tL * 8.0,                          aimP}, -- Angle #7 (Long Shot)
            {tRoot.Position + Vector3.new(0, -6.0, 4.5),         aimP}, -- Angle #8 (Underground Stealth)
        }

        for _, a in ipairs(angles) do
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.CFrame = CFrame.lookAt(a[1], a[2])
            task.wait(0.08)

            local res = TrySubmitPhoto(r.Position + Vector3.new(0, 1.4, 0), a[2])
            if res == "Accepted" then
                accepted = true
                G.LastSubmitTime = os.clock()
                G.RetryCount = 0
                G.LastShiftKick = os.clock()
                G.Log = string.format("<font color='#00FF88'>[DONE] Captured %s</font>", cleanTarget or targetPlayer.DisplayName)
                break
            elseif res == "Cooldown" then
                task.wait(0.55) -- Cooldown recovery
            end
        end
    else
        -- Area Landmark Capture
        local areaSearch = (G.TargetArea or cleanTarget):gsub("^the ", ""):gsub("^%s*(.-)%s*$", "%1")
        local matchedPart = nil

        local hb = workspace:FindFirstChild("AreaHitboxes")
        if hb and areaSearch ~= "" then
            local aLow = areaSearch:lower()
            for _, d in ipairs(hb:GetDescendants()) do
                if d:IsA("BasePart") and d.Name:lower() == aLow then matchedPart = d; break end
            end
            if not matchedPart then
                for _, d in ipairs(hb:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local nLow = d.Name:lower()
                        if nLow:find(aLow, 1, true) or aLow:find(nLow, 1, true) then matchedPart = d; break end
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

        if not matchedPart then
            Reroll("Area Part Missing")
            G.IsBusy = false
            return
        end

        G.Action = "Capturing: " .. areaSearch
        G.Target = areaSearch
        local aP = matchedPart.Position
        local areaAngles = {
            {aP + Vector3.new(0, 1.5, 7.5),   aP},
            {aP + Vector3.new(7.5, 1.5, 0),   aP},
            {aP + Vector3.new(0, 1.5, -7.5),  aP},
            {aP + Vector3.new(-7.5, 1.5, 0),  aP},
            {aP + Vector3.new(0, 2.0, 10.0),  aP},
            {aP + Vector3.new(0, -6.0, 5.0),  aP},
        }

        for _, a in ipairs(areaAngles) do
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.CFrame = CFrame.lookAt(a[1], a[2])
            task.wait(0.08)

            local res = TrySubmitPhoto(r.Position + Vector3.new(0, 1.4, 0), a[2])
            if res == "Accepted" then
                accepted = true
                G.LastSubmitTime = os.clock()
                G.RetryCount = 0
                G.LastShiftKick = os.clock()
                G.Log = string.format("<font color='#00FF88'>[DONE] Captured %s</font>", areaSearch)
                break
            elseif res == "Cooldown" then
                task.wait(0.55)
            end
        end
    end

    GoSafe()
    if not accepted then
        G.RetryCount = G.RetryCount + 1
        if G.RetryCount >= 4 then
            Reroll("Target Unreachable / Out of Range")
        else
            G.Action = "Safezone (Retry " .. tostring(G.RetryCount) .. "/4)..."
        end
    end
    G.IsBusy = false
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 11. HUD SETUP
-- ══════════════════════════════════════════════════════════════════════════════
local GuiPar = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")
do
    local old = GuiPar:FindFirstChild("GakuranHUD")
    if old then old:Destroy() end
end

local Gui = Instance.new("ScreenGui")
Gui.Name           = "GakuranHUD"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder   = 999999
Gui.Parent         = GuiPar

local BG = Instance.new("Frame", Gui)
BG.Size             = UDim2.new(1, 0, 1, 0)
BG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BG.BorderSizePixel  = 0
BG.Visible          = false

local Txt = Instance.new("TextLabel", Gui)
Txt.Size                   = UDim2.new(0, 750, 0, 195)
Txt.AnchorPoint            = Vector2.new(0.5, 0.5)
Txt.Position               = UDim2.new(0.5, 0, 0.5, 0)
Txt.BackgroundTransparency = 1
Txt.Font                   = Enum.Font.GothamBold
Txt.TextSize               = 20
Txt.TextColor3             = Color3.fromRGB(0, 255, 170)
Txt.TextStrokeTransparency = 0
Txt.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
Txt.TextXAlignment         = Enum.TextXAlignment.Center
Txt.TextYAlignment         = Enum.TextYAlignment.Center
Txt.RichText               = true
Txt.ZIndex                 = 1000001

local Btn = Instance.new("TextButton", Gui)
Btn.Size             = UDim2.new(0, 130, 0, 34)
Btn.Position         = UDim2.new(1, -145, 0, 15)
Btn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Btn.BorderSizePixel  = 0
Btn.Font             = Enum.Font.GothamBold
Btn.TextSize         = 13
Btn.ZIndex           = 1000002
Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
local bStroke = Instance.new("UIStroke", Btn)
bStroke.Thickness = 1

local function SetRender(on)
    G.Render3D = on
    pcall(function() RS:Set3dRenderingEnabled(on) end)
    BG.Visible = not on
    if on then
        Btn.Text       = "🟡 3D: ON"
        Btn.TextColor3 = Color3.fromRGB(255, 190, 60)
        bStroke.Color  = Color3.fromRGB(255, 190, 60)
    else
        Btn.Text       = "⚡ 3D: OFF"
        Btn.TextColor3 = Color3.fromRGB(0, 255, 170)
        bStroke.Color  = Color3.fromRGB(0, 255, 170)
    end
end
local disable3D = genv.Disable3D or genv.disable3d or genv.BlackScreen or false
SetRender(not disable3D)

table.insert(G.Connections, Btn.MouseButton1Click:Connect(function() SetRender(not G.Render3D) end))
table.insert(G.Connections, UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and (inp.KeyCode == Enum.KeyCode.RightShift or inp.KeyCode == Enum.KeyCode.Insert) then
        SetRender(not G.Render3D)
    end
end))

-- ══════════════════════════════════════════════════════════════════════════════
-- 12. MAIN CONTROLLER LOOP
-- ══════════════════════════════════════════════════════════════════════════════
local mainThread = task.spawn(function()
    while G.Running do
        task.wait(0.05)

        -- Rules modal bypass
        pcall(function()
            local pgui = LP:FindFirstChild("PlayerGui")
            local rules = pgui and pgui:FindFirstChild("RulesScreenGui")
            if rules and rules.Enabled then
                local btn = rules:FindFirstChild("AgreeButton", true)
                if btn and btn:IsA("GuiButton") and getconnections then
                    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                end
                rules.Enabled = false
            end
        end)

        -- 3-tier auto respawn
        pcall(function()
            local pgui   = LP:FindFirstChild("PlayerGui")
            local deathUI = pgui and pgui:FindFirstChild("DeathUI")
            if deathUI and deathUI.Enabled then
                G.Action = "Reviving..."
                local hBtn = deathUI:FindFirstChild("HeartButton", true)
                if hBtn and getconnections then
                    for _, c in ipairs(getconnections(hBtn.MouseButton1Click)) do c:Fire() end
                end
                local rev = Remotes:FindFirstChild("Revive")
                if rev then pcall(function() rev:FireServer() end) end
                local spReq = Remotes:FindFirstChild("SpawnRequest")
                if spReq then pcall(function() spReq:FireServer() end) end
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    deathUI.Enabled = false
                    local cam = workspace.CurrentCamera
                    if cam then
                        for _, v in ipairs(cam:GetChildren()) do
                            if v:IsA("PostProcessEffect") or v.Name:lower():find("death") then
                                v.Enabled = false; pcall(function() v:Destroy() end)
                            end
                        end
                    end
                    local se = pgui and pgui:FindFirstChild("ScreenEffects")
                    if se then
                        for _, v in ipairs(se:GetChildren()) do
                            if v:IsA("Frame") then v.Visible = false end
                        end
                    end
                end
            end
        end)

        -- Anti-sit
        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
            if ReqSit then pcall(function() ReqSit:FireServer(false) end) end
        end

        EnsureShift(); EnsureYenTag(); CheckAndAutoPay()

        -- Read photo task card
        local pgui     = LP:FindFirstChild("PlayerGui")
        local photoGui = pgui and pgui:FindFirstChild("PhotoJobGui")
        local card     = photoGui and photoGui:FindFirstChild("Card")
        if card then
            local taskLabel = card:FindFirstChild("Task")
            if taskLabel and taskLabel.Text ~= "" and G.RawTaskText ~= taskLabel.Text then
                G.TaskText      = taskLabel.Text
                G.RawTaskText   = taskLabel.Text
                G.Target        = taskLabel.Text:gsub("get a photo of ", "")
                G.RetryCount    = 0
                G.LastShiftKick = os.clock()
            end
        end

        -- Anti-stuck: no task for > 4s
        if (not G.RawTaskText or G.RawTaskText == "") and (os.clock() - G.LastShiftKick) > 4 then
            G.LastShiftKick = os.clock()
            Reroll("Shift Stalled")
        end

        -- Dispatch capture (0.5s cooldown check)
        if G.RawTaskText and G.RawTaskText ~= "" then
            local now = os.clock()
            if (now - G.LastSubmitTime) >= 0.5 and not G.IsBusy then
                task.spawn(RunCapture)
            elseif not G.IsBusy and (now - G.LastSubmitTime) < 0.5 then
                G.Action = string.format("Safezone (CD: %.1fs)", math.max(0, 0.5 - (now - G.LastSubmitTime)))
            end
        else
            GoSafe()
            if not G.IsBusy then G.Action = "Waiting for Task..."; G.Target = "Searching..." end
        end

        -- Money display
        pcall(function()
            local bal      = GetLiveWalletData()
            local shiftYen = card and card:FindFirstChild("Yen") and card.Yen.Text
            G.Money        = "¥" .. tostring(bal) .. (shiftYen and shiftYen ~= "" and (" (shift: " .. shiftYen .. ")") or "")
        end)

        -- HUD diff render (0.5s throttle)
        local now = os.clock()
        if (now - G.LastHudUpdate) >= 0.5 then
            G.LastHudUpdate = now
            local boostStr = (genv.SuperBoost ~= false) and "<font color='#FF4444'>X Gakuran</font>" or "<font color='#AAAAAA'>BOOST OFF</font>"
            local newText  = string.format(
                "<font color='#00E6FF' size='13'><b>XDFLEX HUB</b></font> %s\n" ..
                "<font color='#AAAAAA'>Task:   </font><font color='#FFFFFF'>%s</font>\n" ..
                "<font color='#AAAAAA'>Action: </font><font color='#00E6A0'>%s</font>\n" ..
                "<font color='#AAAAAA'>Target: </font><font color='#FFFF00'>%s</font>\n" ..
                "<font color='#AAAAAA'>Money:  </font><font color='#00FF88'>%s</font>\n" ..
                "<font color='#AAAAAA'>Log:    </font>%s",
                boostStr, G.TaskText, G.Action, G.Target, G.Money, G.Log
            )
            if newText ~= G.LastRenderedText then
                G.LastRenderedText = newText
                pcall(function() Txt.Text = newText end)
            end
        end
    end
end)
table.insert(G.Threads, mainThread)
