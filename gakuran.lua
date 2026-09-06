--[[
    (학乱) GAKURAN - PRO AUTO PHOTO FARM [SUPERBOOST] v4.0
    MADE BY XDFLEX HUB

    CONFIG:
      getgenv().FPSCap       = 15           -- FPS cap (15 cloudphone / 30 / 60)
      getgenv().Disable3D    = true         -- Black screen / max perf
      getgenv().SuperBoost   = true         -- Nuke all textures/surfaces/sounds (default true)
      getgenv().AutoPay      = true
      getgenv().TargetPay    = "XDFLEX67"
      getgenv().PayThreshold = 5000
      getgenv().PayAmount    = "all"
--]]

-- 0. BOOT
repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
while not LP do task.wait(0.5); LP = Players.LocalPlayer end

local RepS    = game:GetService("ReplicatedStorage")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui  = game:GetService("CoreGui")
local VU       = game:GetService("VirtualUser")
local Remotes  = RepS:WaitForChild("Remotes", 30)

local genv = (getgenv and getgenv()) or _G

-- 1. FIRST-TIME PROFILE
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

-- 2. WAIT FOR CHARACTER CONTROL
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:WaitForChild("Humanoid", 30)
repeat
    task.wait(0.5)
    Character = LP.Character or Character
    Humanoid  = Character and Character:FindFirstChild("Humanoid") or Humanoid
until Humanoid and Humanoid.WalkSpeed > 0
     and workspace.CurrentCamera
     and workspace.CurrentCamera.CameraType == Enum.CameraType.Custom
task.wait(4.5)

local Submit   = Remotes:WaitForChild("PhotoJobSubmit", 20)
local JobState = Remotes:WaitForChild("PhotoJobState", 20)
local ReqSit   = Remotes:FindFirstChild("RequestSit")

-- 3. GLOBAL STATE
if _G.GakuranState and type(_G.GakuranState.Cleanup)=="function" then
    pcall(_G.GakuranState.Cleanup); task.wait(0.2)
end

_G.GakuranState = {
    Running=true, Connections={}, Threads={}, Render3D=true,
    Action="Starting...", TaskText="Waiting for Task...", Target="Searching...", Money="¥0",
    Log="<font color='#AAAAAA'>Bot initialized</font>",
    RawTaskText=nil, TargetUserId=nil, TargetArea=nil,
    LastSubmitTime=0, LastRerollTime=0, LastPayTime=0, LastTagCheck=0,
    LastShiftKick=os.clock(), LastGCCollect=os.clock(), LastHudUpdate=0, LastRenderedText="",
    RetryCount=0, IsBusy=false,
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
    pcall(function() collectgarbage("collect") end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. SUPERBOOST OBLITERATOR
--    ระดับดินน้ำมัน — kills 8742 SurfaceAppearance, clears 18438 MeshPart textures,
--    silences all sounds, nukes every lighting effect. Leaves only collision geometry.
-- ══════════════════════════════════════════════════════════════════════════════
local function SuperBoostNuke()
    local superBoost = genv.SuperBoost ~= false  -- default: true
    local targetFps  = tonumber(genv.FPSCap or genv.fpscap or genv.FPS or genv.fps) or 15

    -- FPS cap
    if setfpscap then pcall(function() setfpscap(targetFps) end) end

    -- Render quality floor
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

    -- Lighting: lock to noon, no shadows
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 9e9
        Lighting.Brightness    = 0
        Lighting.ClockTime     = 14
        -- Nuke every Sky/Atmosphere/PostProcess (there are 5 copies of each in this game)
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("PostProcessEffect") then
                pcall(function() v:Destroy() end)
            end
        end
    end)

    -- Camera post-process
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            for _, v in ipairs(cam:GetDescendants()) do
                if v:IsA("PostProcessEffect") then pcall(function() v:Destroy() end) end
            end
        end
    end)

    -- Terrain water
    pcall(function()
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t then t.WaterWaveSize=0; t.WaterWaveSpeed=0; t.WaterTransparency=1 end
    end)

    if superBoost then
        -- Deep scan via task.spawn to not block main thread for 18k+ objects
        task.spawn(function()
            local myChar = LP.Character
            local charSet = {}
            if myChar then
                for _, v in ipairs(myChar:GetDescendants()) do charSet[v] = true end
                charSet[myChar] = true
            end

            for _, v in ipairs(workspace:GetDescendants()) do
                if charSet[v] then continue end
                pcall(function()
                    local cls = v.ClassName
                    if cls == "SurfaceAppearance" then
                        -- SurfaceAppearance = single biggest GPU killer (8742 of them!)
                        v:Destroy()
                    elseif cls == "Decal" or cls == "Texture" then
                        v.Transparency = 1
                    elseif cls == "SpecialMesh" then
                        v.TextureId = ""
                    elseif v:IsA("MeshPart") then
                        v.TextureID  = ""
                        v.CastShadow = false
                    elseif v:IsA("BasePart") then
                        v.CastShadow = false
                    elseif v:IsA("Sound") then
                        v:Stop(); v.Volume=0; v.RollOffMaxDistance=0
                    end
                end)
            end

            -- Silence sounds in RepS
            for _, v in ipairs(RepS:GetDescendants()) do
                if v:IsA("Sound") then pcall(function() v:Stop(); v.Volume=0 end) end
            end

            collectgarbage("collect")
        end)
    else
        -- Standard: just silence sounds
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Sound") then
                pcall(function() v:Stop(); v.Volume=0; v.RollOffMaxDistance=0 end)
            end
        end
    end
end

SuperBoostNuke()

-- Lighter re-run on respawn
table.insert(G.Connections, LP.CharacterAdded:Connect(function()
    task.delay(1.5, function()
        pcall(function()
            local fps = tonumber(genv.FPSCap or genv.fpscap) or 15
            if setfpscap then setfpscap(fps) end
            Lighting.GlobalShadows=false; Lighting.Brightness=0; Lighting.ClockTime=14
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("PostProcessEffect") then
                    pcall(function() v:Destroy() end)
                end
            end
        end)
    end)
end))

-- Aggressive GC every 12s
table.insert(G.Threads, task.spawn(function()
    while G.Running do task.wait(12); pcall(function() collectgarbage("collect") end) end
end))

-- 5. ANTI-SIT / ANTI-AFK / SAFEZONE
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
    while G.Running do task.wait(55); pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.zero) end) end
end))

local SafePos = Vector3.new(0, 1000, 0)
if not workspace:FindFirstChild("GakuranSafePlatform") then
    local p = Instance.new("Part")
    p.Name="GakuranSafePlatform"; p.Size=Vector3.new(40,2,40)
    p.Position=SafePos-Vector3.new(0,2,0); p.Anchored=true
    p.Transparency=0.6; p.CastShadow=false
    p.Material=Enum.Material.SmoothPlastic; p.Color=Color3.fromRGB(0,230,160)
    p.Parent=workspace
end
local function GoSafe()
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then
        r.AssemblyLinearVelocity=Vector3.zero
        r.AssemblyAngularVelocity=Vector3.zero
        r.CFrame=CFrame.new(SafePos+Vector3.new(0,3,0))
    end
end

-- 6. JOB & YEN SERVICE LOOKUP
local NJob, YenService = nil, nil

local function SafeInitialLookup()
    if not getgc then return end
    local list = getgc(true); if not list then return end
    for i=1,#list do
        local v = list[i]
        if type(v)=="table" then
            if not NJob and rawget(v,"GetRegistered") and rawget(v,"GetByKey") then
                local ok,reg = pcall(function() return v.GetRegistered() end)
                if ok and reg then
                    for _,item in ipairs(reg) do
                        if item.Key=="SchoolNewspaper" then NJob=item; break end
                    end
                end
            end
            if not YenService then
                local meta = getmetatable(v)
                if meta and meta.__index and type(meta.__index)=="table" then
                    if rawget(meta.__index,"SendYen") and rawget(meta.__index,"ClaimTag") and rawget(meta.__index,"GetTag") then YenService=v end
                elseif rawget(v,"SendYen") and rawget(v,"ClaimTag") and rawget(v,"GetTag") then YenService=v end
            end
        end
        if NJob and YenService then break end
    end
    table.clear(list); list=nil
end
SafeInitialLookup()

-- 7. SHIFT MANAGEMENT
local function EnsureShift()
    if NJob then
        if not NJob.IsActive() then pcall(function() NJob.Start() end); task.wait(0.2) end
    else
        SafeInitialLookup()
    end
end

local function Reroll(reason)
    local now = os.clock()
    if now-G.LastRerollTime < 1.0 then return end
    G.LastRerollTime=now; G.RetryCount=0; G.RawTaskText=nil
    G.Action="Rerolling..."
    G.Log=string.format("<font color='#FF5555'>[SKIP] %s</font>", reason or "Stuck")
    if NJob then
        pcall(function() NJob.Stop() end); task.wait(0.15)
        pcall(function() NJob.Start() end); task.wait(0.2)
    end
    GoSafe()
end

-- 8. WALLET & AUTO PAY
local function GetLiveWalletData()
    local bal,tag = 0,""
    if not YenService then SafeInitialLookup() end
    if YenService then
        pcall(function()
            local st = YenService:GetState()
            if st and type(st.Balance)=="number" then bal=st.Balance end
            local tg = YenService:GetTag(); if type(tg)=="string" then tag=tg end
        end)
    end
    if bal==0 then
        local lbl = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("BalanceLabel",true)
        if lbl and lbl.Text~="" then local n=tonumber(lbl.Text:gsub("[^%d]","")); if n then bal=n end end
    end
    return bal, tag
end

local function EnsureYenTag()
    local now = os.clock()
    if (now-G.LastTagCheck)<8 then return end
    G.LastTagCheck=now
    if not YenService then SafeInitialLookup() end
    if not (YenService and YenService.GetTag and YenService.ClaimTag) then return end
    local currentTag=""
    pcall(function() currentTag=YenService:GetTag() or "" end)
    if currentTag=="" or currentTag=="none" then
        local rTag="XD"..tostring(math.random(10,99))..string.char(math.random(65,90))..tostring(math.random(100,999))
        pcall(function() YenService:ClaimTag(rTag); G.Log=string.format("<font color='#00E6FF'>[TAG] Claimed @%s</font>",rTag) end)
    end
end

local function CheckAndAutoPay()
    local autoPayEnabled = genv.AutoPay or genv.TargetPay~=nil or genv.targetpay~=nil
    local targetTag = genv.TargetPay or genv.targetpay
    local rawAmount = genv.PayAmount or genv.amount or genv.payamount
    local rawThreshold = genv.PayThreshold or genv.threshold
    if not autoPayEnabled or not targetTag or targetTag=="" then return end
    targetTag = targetTag:gsub("^¥",""):gsub("^%s*(.-)%s*$","%1")
    local now = os.clock()
    if (now-G.LastPayTime)<1.5 then return end
    if not YenService then SafeInitialLookup() end
    local currentBal,currentTag = GetLiveWalletData()
    if currentTag~="" and currentTag:lower()==targetTag:lower() then return end
    local threshold = tonumber(rawThreshold) or 5000
    local MAX_PER = 250000
    local payAmount = 0
    if type(rawAmount)=="string" and (rawAmount:lower()=="all" or rawAmount:lower()=="max") then
        payAmount = math.min(currentBal, MAX_PER)
    else
        payAmount = math.min(tonumber(rawAmount) or 5000, currentBal, MAX_PER)
    end
    if currentBal>=threshold and payAmount>=10 then
        if YenService and YenService.SendYen then
            G.LastPayTime=now
            G.Action="Auto Paying ¥"..tostring(payAmount).." -> @"..targetTag.."..."
            local ok,err = pcall(function() YenService:SendYen(targetTag,payAmount) end)
            G.Log = ok
                and string.format("<font color='#00E6FF'>[PAY] ¥%s -> @%s</font>",tostring(payAmount),targetTag)
                or  string.format("<font color='#FF5555'>[PAY ERR] %s</font>",tostring(err))
        else SafeInitialLookup() end
    end
end

-- 9. PHOTO JOB STATE EVENT
table.insert(G.Connections, JobState.OnClientEvent:Connect(function(data)
    if type(data)~="table" then return end
    if data.Kind=="Task" then
        G.RawTaskText=data.Text or ""; G.TaskText=data.Text or "get a photo"
        G.TargetUserId=data.TargetUserId; G.TargetArea=data.Area
        G.Target=data.Label or data.Area or (data.Text and data.Text:gsub("get a photo of ","")) or "Unknown"
        G.RetryCount=0; G.Action="New Task!"; G.LastShiftKick=os.clock()
    elseif data.Kind=="Paid" then
        G.Action="Accepted! +¥"..tostring(data.Pay or 0)
        G.Log=string.format("<font color='#00FF88'>[DONE] Photo Accepted! (+¥%s)</font>",tostring(data.Pay or 0))
        G.LastSubmitTime=os.clock(); G.RetryCount=0; G.LastShiftKick=os.clock()
    end
end))

-- 10. TURBO PRECISION PHOTO ENGINE
local function TrySubmitPhoto(camPos, aimPos)
    local cf = CFrame.lookAt(camPos, aimPos)
    local ok, res = pcall(function() return Submit:InvokeServer("Submit", cf) end)
    return ok and res or nil
end

local function RunCapture()
    if G.IsBusy or not G.RawTaskText or G.RawTaskText=="" then return end
    G.IsBusy=true
    local c = LP.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then G.IsBusy=false; return end
    local accepted=false
    local cleanTarget = G.RawTaskText:gsub("get a photo of ",""):gsub("^the ",""):gsub("^%s*(.-)%s*$","%1")

    local targetPlayer = nil
    if G.TargetUserId then targetPlayer=Players:GetPlayerByUserId(G.TargetUserId) end
    if not targetPlayer then
        local ct=cleanTarget:lower()
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=LP then
                local pN=pl.Name:lower(); local pD=pl.DisplayName:lower()
                if pN==ct or pD==ct or pN:find(ct,1,true) or pD:find(ct,1,true) then targetPlayer=pl; break end
            end
        end
    end

    if targetPlayer then
        local tChar=targetPlayer.Character; local tRoot=tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tRoot then Reroll("Player Left"); G.IsBusy=false; return end
        G.Action="Capturing: "..(targetPlayer.DisplayName or targetPlayer.Name)
        G.Target=targetPlayer.DisplayName.." (@"..targetPlayer.Name..")"
        local tL=tRoot.CFrame.LookVector; local tR=tRoot.CFrame.RightVector
        local aimP=tRoot.Position+Vector3.new(0,0.5,0)
        local angles={
            {tRoot.Position+tL*6.0, aimP},
            {tRoot.Position+tL*5.0+Vector3.new(0,0.2,0), aimP},
            {tRoot.Position+tR*5.5, aimP},
            {tRoot.Position-tR*5.5, aimP},
            {tRoot.Position-tL*5.5, aimP},
            {tRoot.Position+tL*7.5, aimP},
            {tRoot.Position+Vector3.new(0,-6.0,4.5), aimP},
            {tRoot.Position+Vector3.new(0,-10.0,4.0), aimP},
        }
        for _,a in ipairs(angles) do
            r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
            r.CFrame=CFrame.lookAt(a[1],a[2]); task.wait(0.06)
            local res=TrySubmitPhoto(r.Position+Vector3.new(0,1.4,0),a[2])
            if res=="Accepted" then
                accepted=true; G.LastSubmitTime=os.clock(); G.RetryCount=0; G.LastShiftKick=os.clock()
                G.Log=string.format("<font color='#00FF88'>[DONE] Captured %s</font>",targetPlayer.DisplayName or targetPlayer.Name); break
            elseif res=="Cooldown" then task.wait(0.8); break end
        end
    else
        local areaSearch=(G.TargetArea or cleanTarget):gsub("^the ",""):gsub("^%s*(.-)%s*$","%1")
        local matchedPart=nil
        local hb=workspace:FindFirstChild("AreaHitboxes")
        if hb and areaSearch~="" then
            local aLow=areaSearch:lower()
            for _,d in ipairs(hb:GetDescendants()) do if d:IsA("BasePart") and d.Name:lower()==aLow then matchedPart=d; break end end
            if not matchedPart then
                for _,d in ipairs(hb:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local nLow=d.Name:lower()
                        if nLow:find(aLow,1,true) or aLow:find(nLow,1,true) then matchedPart=d; break end
                    end
                end
            end
        end
        if not matchedPart and areaSearch~="" then
            local aLow=areaSearch:lower()
            for _,d in ipairs(workspace:GetChildren()) do
                if d:IsA("BasePart") or d:IsA("Model") then
                    local nLow=d.Name:lower()
                    if nLow==aLow or nLow:find(aLow,1,true) or aLow:find(nLow,1,true) then
                        matchedPart=d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
                        if matchedPart then break end end end end
        end
        if not matchedPart then Reroll("Area Part Missing"); G.IsBusy=false; return end
        G.Action="Capturing: "..areaSearch; G.Target=areaSearch
        local aP=matchedPart.Position
        local areaAngles={
            {aP+Vector3.new(0,1.5,9.0),aP}, {aP+Vector3.new(9.0,1.5,0),aP},
            {aP+Vector3.new(0,1.5,-9.0),aP}, {aP+Vector3.new(-9.0,1.5,0),aP},
            {aP+Vector3.new(0,2.0,12.0),aP}, {aP+Vector3.new(0,-6.0,6.0),aP},
            {aP+Vector3.new(0,-11.0,5.0),aP},
        }
        for _,a in ipairs(areaAngles) do
            r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
            r.CFrame=CFrame.lookAt(a[1],a[2]); task.wait(0.06)
            local res=TrySubmitPhoto(r.Position+Vector3.new(0,1.4,0),a[2])
            if res=="Accepted" then
                accepted=true; G.LastSubmitTime=os.clock(); G.RetryCount=0; G.LastShiftKick=os.clock()
                G.Log=string.format("<font color='#00FF88'>[DONE] Captured %s</font>",areaSearch); break
            elseif res=="Cooldown" then task.wait(0.8); break end
        end
    end

    GoSafe()
    if not accepted then
        G.RetryCount=G.RetryCount+1
        if G.RetryCount>=5 then Reroll("Target Stuck After 5 Tries")
        else G.Action="Safezone (Retry "..tostring(G.RetryCount).."/5)..." end
    end
    G.IsBusy=false
end

-- 11. HUD
local GuiPar=(gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")
do local old=GuiPar:FindFirstChild("GakuranHUD"); if old then old:Destroy() end end

local Gui=Instance.new("ScreenGui"); Gui.Name="GakuranHUD"; Gui.ResetOnSpawn=false
Gui.IgnoreGuiInset=true; Gui.DisplayOrder=999999; Gui.Parent=GuiPar

local BG=Instance.new("Frame",Gui); BG.Size=UDim2.new(1,0,1,0)
BG.BackgroundColor3=Color3.fromRGB(0,0,0); BG.BorderSizePixel=0; BG.Visible=false

local Txt=Instance.new("TextLabel",Gui); Txt.Size=UDim2.new(0,750,0,195)
Txt.AnchorPoint=Vector2.new(0.5,0.5); Txt.Position=UDim2.new(0.5,0,0.5,0)
Txt.BackgroundTransparency=1; Txt.Font=Enum.Font.GothamBold; Txt.TextSize=20
Txt.TextColor3=Color3.fromRGB(0,255,170); Txt.TextStrokeTransparency=0
Txt.TextStrokeColor3=Color3.fromRGB(0,0,0); Txt.TextXAlignment=Enum.TextXAlignment.Center
Txt.TextYAlignment=Enum.TextYAlignment.Center; Txt.RichText=true; Txt.ZIndex=1000001

local Btn=Instance.new("TextButton",Gui); Btn.Size=UDim2.new(0,130,0,34)
Btn.Position=UDim2.new(1,-145,0,15); Btn.BackgroundColor3=Color3.fromRGB(15,15,20)
Btn.BorderSizePixel=0; Btn.Font=Enum.Font.GothamBold; Btn.TextSize=13; Btn.ZIndex=1000002
Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,6)
local bStroke=Instance.new("UIStroke",Btn); bStroke.Thickness=1

local function SetRender(on)
    G.Render3D=on; pcall(function() RS:Set3dRenderingEnabled(on) end); BG.Visible=not on
    if on then Btn.Text="🟡 3D: ON"; Btn.TextColor3=Color3.fromRGB(255,190,60); bStroke.Color=Color3.fromRGB(255,190,60)
    else Btn.Text="⚡ 3D: OFF"; Btn.TextColor3=Color3.fromRGB(0,255,170); bStroke.Color=Color3.fromRGB(0,255,170) end
end
local disable3D = genv.Disable3D or genv.disable3d or genv.BlackScreen or false
SetRender(not disable3D)
table.insert(G.Connections,Btn.MouseButton1Click:Connect(function() SetRender(not G.Render3D) end))
table.insert(G.Connections,UIS.InputBegan:Connect(function(inp,gpe)
    if not gpe and (inp.KeyCode==Enum.KeyCode.RightShift or inp.KeyCode==Enum.KeyCode.Insert) then SetRender(not G.Render3D) end
end))

-- 12. MAIN CONTROLLER LOOP
local mainThread = task.spawn(function()
    while G.Running do
        task.wait(0.05)

        -- Rules modal bypass
        pcall(function()
            local pgui=LP:FindFirstChild("PlayerGui"); local rules=pgui and pgui:FindFirstChild("RulesScreenGui")
            if rules and rules.Enabled then
                local btn=rules:FindFirstChild("AgreeButton",true)
                if btn and btn:IsA("GuiButton") and getconnections then
                    for _,c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                end
                rules.Enabled=false
            end
        end)

        -- 3-tier auto respawn
        pcall(function()
            local pgui=LP:FindFirstChild("PlayerGui"); local deathUI=pgui and pgui:FindFirstChild("DeathUI")
            if deathUI and deathUI.Enabled then
                G.Action="Reviving..."
                local hBtn=deathUI:FindFirstChild("HeartButton",true)
                if hBtn and getconnections then for _,c in ipairs(getconnections(hBtn.MouseButton1Click)) do c:Fire() end end
                local rev=Remotes:FindFirstChild("Revive"); if rev then pcall(function() rev:FireServer() end) end
                local spReq=Remotes:FindFirstChild("SpawnRequest"); if spReq then pcall(function() spReq:FireServer() end) end
                local hum=LP.Character and LP.Character:FindFirstChild("Humanoid")
                if hum and hum.Health>0 then
                    deathUI.Enabled=false
                    local cam=workspace.CurrentCamera
                    if cam then for _,v in ipairs(cam:GetChildren()) do if v:IsA("PostProcessEffect") or v.Name:lower():find("death") then v.Enabled=false; pcall(function() v:Destroy() end) end end end
                    local se=pgui and pgui:FindFirstChild("ScreenEffects")
                    if se then for _,v in ipairs(se:GetChildren()) do if v:IsA("Frame") then v.Visible=false end end end
                end
            end
        end)

        -- Anti-sit
        local hum=LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum and hum.Sit then
            hum.Sit=false; hum:ChangeState(Enum.HumanoidStateType.Running)
            if ReqSit then pcall(function() ReqSit:FireServer(false) end) end
        end

        EnsureShift(); EnsureYenTag(); CheckAndAutoPay()

        -- Read photo task card
        local pgui=LP:FindFirstChild("PlayerGui")
        local photoGui=pgui and pgui:FindFirstChild("PhotoJobGui")
        local card=photoGui and photoGui:FindFirstChild("Card")
        if card then
            local taskLabel=card:FindFirstChild("Task")
            if taskLabel and taskLabel.Text~="" and G.RawTaskText~=taskLabel.Text then
                G.TaskText=taskLabel.Text; G.RawTaskText=taskLabel.Text
                G.Target=taskLabel.Text:gsub("get a photo of ",""); G.RetryCount=0; G.LastShiftKick=os.clock()
            end
        end

        -- Anti-stuck: no task for > 4s
        if (not G.RawTaskText or G.RawTaskText=="") and (os.clock()-G.LastShiftKick)>4 then
            G.LastShiftKick=os.clock(); Reroll("Shift Stalled")
        end

        -- Dispatch capture (0.8s cooldown — faster than old 1.0s)
        if G.RawTaskText and G.RawTaskText~="" then
            local now=os.clock()
            if (now-G.LastSubmitTime)>=0.8 and not G.IsBusy then
                task.spawn(RunCapture)
            elseif not G.IsBusy and (now-G.LastSubmitTime)<0.8 then
                G.Action=string.format("Safezone (CD: %.1fs)", math.max(0,0.8-(now-G.LastSubmitTime)))
            end
        else
            GoSafe()
            if not G.IsBusy then G.Action="Waiting for Task..."; G.Target="Searching..." end
        end

        -- Money display
        pcall(function()
            local bal=GetLiveWalletData()
            local shiftYen=card and card:FindFirstChild("Yen") and card.Yen.Text
            G.Money="¥"..tostring(bal)..(shiftYen and shiftYen~="" and (" (shift: "..shiftYen..")") or "")
        end)

        -- HUD diff render (0.5s throttle)
        local now=os.clock()
        if (now-G.LastHudUpdate)>=0.5 then
            G.LastHudUpdate=now
            local boostStr = (genv.SuperBoost~=false) and "<font color='#FF4444'>SUPERBOOST</font>" or "<font color='#AAAAAA'>BOOST OFF</font>"
            local newText=string.format(
                "<font color='#00E6FF' size='13'><b>MAKE BY XDFLEX HUB</b></font> %s\n"..
                "<font color='#AAAAAA'>Task:   </font><font color='#FFFFFF'>%s</font>\n"..
                "<font color='#AAAAAA'>Action: </font><font color='#00E6A0'>%s</font>\n"..
                "<font color='#AAAAAA'>Target: </font><font color='#FFFF00'>%s</font>\n"..
                "<font color='#AAAAAA'>Money:  </font><font color='#00FF88'>%s</font>\n"..
                "<font color='#AAAAAA'>Log:    </font>%s",
                boostStr, G.TaskText, G.Action, G.Target, G.Money, G.Log)
            if newText~=G.LastRenderedText then
                G.LastRenderedText=newText
                pcall(function() Txt.Text=newText end)
            end
        end
    end
end)
table.insert(G.Threads, mainThread)
