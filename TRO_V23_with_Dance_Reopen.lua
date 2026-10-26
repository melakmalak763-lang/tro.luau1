-- ============================================================
-- TRO | COSMIC BLACK GUI - V23 (FULL 20 PRESETS + Resize)
-- كل الميزات + 20 أمر ادمن كامل + مقبض تحجيم
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local VU = game:GetService("VirtualUser")
local Chat = game:GetService("Chat")

local player = Players.LocalPlayer
if not player then return end
print("[TRO V23] Loading...")

local guiParent
pcall(function() if typeof(gethui) == "function" then local h = gethui() if h then guiParent = h end end end)
if not guiParent then pcall(function() guiParent = game:GetService("CoreGui") end) end
if not guiParent then guiParent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui") end
if not guiParent then return end

for _, n in ipairs({"TRO_CosmicGUI", "TRO_ToggleIcon", "TRO_AntiChain", "TRODodgeGui"}) do
    local o = guiParent:FindFirstChild(n)
    if o then pcall(function() o:Destroy() end) end
end

-- 🎨 Colors (رمادي فقط)
local C_BLACK      = Color3.fromRGB(0, 0, 0)
local C_BTN_IDLE   = Color3.fromRGB(15, 15, 18)
local C_BTN_ACTIVE = Color3.fromRGB(38, 38, 46)
local C_TEXT       = Color3.fromRGB(220, 220, 228)
local C_TEXT_DIM   = Color3.fromRGB(150, 150, 160)
local C_STROKE     = Color3.fromRGB(60, 60, 70)
local C_STROKE_HI  = Color3.fromRGB(130, 130, 145)

-- Helpers
local function bindClick(btn, cb, lbl)
    if not btn then return end
    local d = false
    local function fire()
        if d then return end
        d = true
        task.delay(0.25, function() d = false end)
        local ok, err = pcall(cb)
        if not ok then warn("[TRO-ERR]", lbl or "?", err) end
    end
    pcall(function() btn.Activated:Connect(fire) end)
    pcall(function() btn.MouseButton1Click:Connect(fire) end)
    pcall(function()
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then fire() end
        end)
    end)
end

local function notify(t, x, dur)
    pcall(function() SG:SetCore("SendNotification", {Title = t, Text = x, Duration = dur or 4}) end)
end

local function getChar()
    local c = player.Character
    if not c then return nil, nil, nil end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function mkBtn(parent, text, size, pos, cb, isActive)
    local b = Instance.new("TextButton", parent)
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = isActive and C_BTN_ACTIVE or C_BTN_IDLE
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = C_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.TextWrapped = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", b).Color = isActive and C_STROKE_HI or C_STROKE
    if cb then bindClick(b, cb, text) end
    return b
end

-- Remotes
local FoundRemotes = {}
local function scanRemotes()
    FoundRemotes = {}
    pcall(function()
        for _, item in ipairs(RS:GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                local n = item.Name:lower()
                if n:find("command") or n:find("cmd") or n:find("admin") or n:find("chat") or n:find("say") then
                    table.insert(FoundRemotes, item)
                end
            end
        end
        local d = RS:FindFirstChild("DefaultChatSystemChatEvents")
        if d then
            local smr = d:FindFirstChild("SayMessageRequest")
            if smr then table.insert(FoundRemotes, smr) end
        end
    end)
end
scanRemotes()

local function sendHDAdmin(cmd)
    task.defer(function()
        pcall(function()
            local hd = RS:FindFirstChild("HDAdminHDClient")
            if hd then
                local sig = hd:FindFirstChild("Signals")
                if sig then
                    local rcm = sig:FindFirstChild("RequestCommandModification")
                    if rcm then
                        if rcm:IsA("RemoteFunction") then rcm:InvokeServer(cmd)
                        else rcm:FireServer(cmd) end
                    end
                end
            end
        end)
    end)
end

local function sendChatText(text)
    pcall(function()
        local tcs = game:GetService("TextChatService")
        local ch = tcs:FindFirstChild("TextChannels")
        local channel = ch and (ch:FindFirstChild("RBXGeneral") or ch:GetChildren()[1])
        if channel and channel:IsA("TextChannel") then channel:SendAsync(text) end
    end)
    pcall(function()
        local e = RS:FindFirstChild("DefaultChatSystemChatEvents")
        local rq = e and e:FindFirstChild("SayMessageRequest")
        if rq and rq:IsA("RemoteEvent") then rq:FireServer(text, "All") end
    end)
end

-- ========== Anti-Chain ==========
local AC = {
    enabled = true,
    blockedSit = 0, blockedPS = 0, blockedCF = 0, blockedW = 0,
    defending = false, lastReset = 0, lastUncuff = 0,
    baselineCF = nil, logs = {},
}

local function acLog(msg)
    table.insert(AC.logs, os.date("%H:%M:%S") .. " | " .. msg)
    while #AC.logs > 12 do table.remove(AC.logs, 1) end
end

local function acGetBatman()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local b = p.Character:FindFirstChild("Batman")
            if b then local r = b:FindFirstChild("RemoteEvent") if r then table.insert(list, r) end end
        end
        local bp = p:FindFirstChild("Backpack")
        if bp then
            local b = bp:FindFirstChild("Batman")
            if b then local r = b:FindFirstChild("RemoteEvent") if r then table.insert(list, r) end end
        end
    end
    return list
end

local function acUncuff()
    local now = tick()
    if now - AC.lastUncuff < 0.2 then return 0 end
    AC.lastUncuff = now
    local remotes = acGetBatman()
    for _, r in ipairs(remotes) do pcall(function() r:FireServer("UnCuff") end) end
    return #remotes
end

local function acReset(reason)
    local now = tick()
    if now - AC.lastReset < 1.0 then return end
    AC.lastReset = now
    acLog("💀 إعادة: " .. reason)
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then pcall(function() h.Health = 0 end) end
    pcall(function() c:BreakJoints() end)
end

local function acLock(reason)
    if AC.defending then return end
    AC.defending = true
    local c = player.Character
    if not c then AC.defending = false return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then AC.defending = false return end
    local saved = AC.baselineCF or hrp.CFrame
    AC.baselineCF = saved
    acLog("🔒 " .. reason)
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("AlignPosition") or d:IsA("AlignOrientation") or
           d:IsA("BodyPosition") or d:IsA("BodyGyro") or d:IsA("BodyVelocity") then
            pcall(function() d:Destroy() end)
        end
    end
    pcall(acUncuff)
    task.spawn(function()
        local endT = tick() + 1.0
        while tick() < endT and AC.enabled do
            local cc = player.Character
            if cc then
                local hh = cc:FindFirstChild("HumanoidRootPart")
                if hh then
                    pcall(function()
                        hh.CFrame = saved
                        hh.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
                local h = cc:FindFirstChildOfClass("Humanoid")
                if h then
                    pcall(function()
                        if h.Sit then h.Sit = false end
                        if h.PlatformStand then h.PlatformStand = false end
                    end)
                end
            end
            pcall(acUncuff)
            RunService.RenderStepped:Wait()
        end
        AC.defending = false
    end)
end

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if AC.enabled and not AC.defending then
            local c = player.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if h and hrp and h.Health > 0 then
                    if h.Sit then acLock("Sit") end
                    if h.PlatformStand then acLock("PS") end
                end
            end
        end
        task.wait(0.1)
    end
end)

workspace.DescendantAdded:Connect(function(inst)
    if not AC.enabled then return end
    local c = player.Character
    if not c then return end
    if inst:IsA("Weld") or inst:IsA("WeldConstraint") then
        local p0, p1 = inst.Part0, inst.Part1
        if p0 and p1 then
            local a = p0:IsDescendantOf(c) and not p1:IsDescendantOf(c)
            local b = p1:IsDescendantOf(c) and not p0:IsDescendantOf(c)
            if a or b then
                pcall(function() inst:Destroy() end)
                AC.blockedW = AC.blockedW + 1
                if not AC.defending then acLock("Weld") end
            end
        end
    end
end)

-- ========== Dodge ==========
local Dg = {auto = false, dodging = false, count = 0, logs = {}}

local function dgLog(msg)
    table.insert(Dg.logs, os.date("%H:%M:%S") .. " | " .. msg)
    while #Dg.logs > 8 do table.remove(Dg.logs, 1) end
end

local function dgDo()
    if Dg.dodging then return end
    local c, h, r = getChar()
    if not c or not h or not r or h.Health <= 0 then return end
    Dg.dodging = true
    Dg.count = Dg.count + 1
    local dir = ((Dg.count - 1) % 3) + 1
    local origCF = r.CFrame
    local soundId, emoteId
    if dir == 1 then soundId = "rbxassetid://132521221880216" emoteId = 90488938832099
    elseif dir == 2 then soundId = "rbxassetid://81857580097150" emoteId = 88170433716621
    else soundId = "rbxassetid://129561737395908" emoteId = 137710349373014 end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = soundId s.Volume = 1 s.Parent = r s:Play()
        task.delay(1, function() if s and s.Parent then s:Destroy() end end)
    end)
    pcall(function() h:PlayEmoteAndGetAnimTrackById(emoteId) end)
    task.spawn(function()
        local target
        if dir == 1 then target = origCF * CFrame.new(-6, 0, 0)
        elseif dir == 2 then target = origCF * CFrame.new(6, 0, 0)
        else target = origCF * CFrame.new(0, -0.6, 0) end
        pcall(function() r.CFrame = target end)
    end)
    task.delay(0.2, function() Dg.dodging = false end)
    dgLog("⚡ #" .. Dg.count)
end

UIS.InputBegan:Connect(function(input, gp)
    if gp or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Q then dgDo() end
end)

-- ========== Anti-AFK ==========
local AFK = {enabled = false, conns = {}, startCF = nil, startY = nil, moveT = 0, clickT = 0}

local function afkStop()
    for _, c in ipairs(AFK.conns) do pcall(function() c:Disconnect() end) end
    AFK.conns = {}
end

local function afkStart()
    afkStop()
    AFK.enabled = true
    AFK.moveT = 0
    AFK.clickT = 0
    local c, h, r = getChar()
    if r then AFK.startCF = r.CFrame AFK.startY = r.Position.Y end
    pcall(function()
        table.insert(AFK.conns, player.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end))
    end)
    table.insert(AFK.conns, RunService.Heartbeat:Connect(function(dt)
        if not AFK.enabled then return end
        local cc, hh, rr = getChar()
        if not rr or not hh or not AFK.startCF then return end
        if math.abs(rr.Position.Y - AFK.startY) > 10 then
            pcall(function() rr.CFrame = AFK.startCF end)
        end
        AFK.moveT = AFK.moveT + dt
        if AFK.moveT >= 1.2 then
            AFK.moveT = 0
            local a = math.random() * math.pi * 2
            local d = math.random(20, 60)
            pcall(function() hh:MoveTo(Vector3.new(AFK.startCF.X + math.cos(a)*d, AFK.startY, AFK.startCF.Z + math.sin(a)*d)) end)
        end
        AFK.clickT = AFK.clickT + dt
        if AFK.clickT >= 0.5 then
            AFK.clickT = 0
            pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
        end
    end))
end

player.CharacterAdded:Connect(function()
    AC.baselineCF = nil
    AC.defending = false
    task.wait(1)
    if AFK.enabled then afkStart() end
end)

-- ============================================================
-- 📢 Spam Presets (20 كامل)
-- ============================================================
local spamPresets = {
    {key="Mod",          name="مشرف"},
    {key="Mod2",         name="مشرف 2"},
    {key="CopyMod3",     name="نسخ مشرف"},
    {key="Admin",        name="ادمن"},
    {key="Admin2",       name="ادمن 2"},
    {key="Head",         name="هيد"},
    {key="Head2",        name="هيد 2"},
    {key="Mystery",      name="غامض"},
    {key="Mystery2",     name="غامض 2"},
    {key="CopyMystery3", name="نسخ غامض"},
    {key="Insult1",      name="اهانة 1"},
    {key="Insult2",      name="اهانة 2"},
    {key="Insult3",      name="اهانة 3"},
    {key="Insult4",      name="اهانة 4"},
    {key="Map1",         name="ماب 1"},
    {key="Map2",         name="ماب 2"},
    {key="Map3",         name="ماب 3"},
    {key="CopyInsult1",  name="نسخ اهانة 1"},
    {key="CopyInsult2",  name="نسخ اهانة 2"},
    {key="CopyInsult3",  name="نسخ اهانة 3"},
}

local function genPreset(ft, key)
    local cmds = {}
    local function addMulti(base, times)
        for i = 1, times do
            for _, c in ipairs(base) do
                table.insert(cmds, c)
            end
        end
    end

    if key == "Mod" then
        addMulti({"re "..ft, "res "..ft, "nv "..ft, "r6 "..ft, "logs "..ft}, 10)
    elseif key == "Mod2" then
        addMulti({"re "..ft, "worm "..ft, "nv "..ft, "kill "..ft, "logs "..ft, "clogs "..ft, "nv "..ft, "jc "..ft}, 10)
    elseif key == "CopyMod3" then
        addMulti({"re "..ft, "res "..ft, "nv "..ft}, 10)
    elseif key == "Admin" then
        addMulti({"re "..ft, "nv "..ft, "alert "..ft, "logs "..ft, "worm "..ft, "jc "..ft, "nv "..ft, "re "..ft, "res "..ft, "re "..ft, "res "..ft, "nv "..ft}, 6)
    elseif key == "Admin2" then
        addMulti({"alert "..ft, "ice "..ft, "nv "..ft, "kill "..ft, "jc "..ft, "worm "..ft, "jc "..ft, "fling "..ft, "nv "..ft, "res "..ft, "re "..ft}, 6)
    elseif key == "Head" then
        addMulti({"res "..ft, "explode "..ft, "re "..ft, "nv "..ft, "loopkill "..ft, "jc "..ft, "re "..ft, "explode "..ft}, 8)
    elseif key == "Head2" then
        addMulti({"res "..ft, "explode "..ft, "nv "..ft, "loopkill "..ft, "jc "..ft, "alert "..ft, "re "..ft, "explode "..ft, "nv "..ft, "res "..ft, "explode "..ft}, 8)
    elseif key == "Mystery" then
        addMulti({"re "..ft, "explode "..ft, "res "..ft, "explode "..ft, "r6 "..ft, "explode "..ft, "jc "..ft, "r15 "..ft, "explode "..ft, "nv "..ft, "loopwarp "..ft}, 5)
    elseif key == "Mystery2" then
        addMulti({"res "..ft, "explode "..ft, "re "..ft, "explode "..ft, "loopkill "..ft, "loopfling "..ft, "loopwarp "..ft, "jc "..ft, "nv "..ft, "re explode "..ft, "res "..ft, "explode "..ft, "re "..ft, "explode "..ft}, 5)
    elseif key == "CopyMystery3" then
        addMulti({"re "..ft, "explode "..ft, "blur "..ft, "loopwarp "..ft, "jc "..ft, "nv "..ft, "loopkill "..ft, "r6 "..ft, "explode "..ft, "r15 "..ft, "explode "..ft}, 5)
    elseif key == "Insult1" then
        for _, c in ipairs({
            "tp "..ft,
            "char "..ft.." fz_jn26",
            "ref "..ft,
            "worm "..ft,
            "buffify "..ft,
            "fat "..ft,
            "titlepk "..ft.." اه يعور 🥺"
        }) do table.insert(cmds, c) end
    elseif key == "Insult2" then
        for _, c in ipairs({
            "worm "..ft,
            "worm "..ft,
            "buffify "..ft,
            "fat "..ft,
            "re "..ft,
            "re "..ft,
            "re "..ft,
            "re "..ft,
            "res "..ft,
            "res "..ft,
            "res "..ft,
            "nv "..ft,
            "kill "..ft,
            "kill "..ft,
            "kill "..ft,
            "kill "..ft,
            "kill "..ft,
            "re "..ft,
            "re "..ft,
            "re "..ft,
            "re "..ft,
            "re "..ft,
            "worm "..ft
        }) do table.insert(cmds, c) end
    elseif key == "Insult3" then
        for _, c in ipairs({
            "char "..ft.." fz_jn26",
            "ref "..ft,
            "re "..ft,
            "tp "..ft,
            "phase "..ft,
            "nv "..ft,
            "logs "..ft,
            "cmdbar "..ft,
            "re "..ft,
            "kill "..ft,
            "worm "..ft,
            "buffify "..ft,
            "fat "..ft,
            "dog "..ft,
            "dog "..ft,
            "fly "..ft,
            "titlepk "..ft.." اه اه 😭يعور 😭"
        }) do table.insert(cmds, c) end
    elseif key == "Insult4" then
        for _, c in ipairs({
            "tp "..ft,
            "ref "..ft,
            "dog "..ft,
            "phase "..ft,
            "buffify "..ft,
            "titlepk "..ft.." اه كثي 🥵"
        }) do table.insert(cmds, c) end
    elseif key == "Map1" then
        addMulti({
            "crash "..ft,
            "nv "..ft,
            "explode "..ft,
            "r6 "..ft,
            "explode "..ft,
            "r15 "..ft,
            "explode "..ft,
            "loopwarp "..ft,
            "re "..ft,
            "res "..ft,
            "logs "..ft,
            "crash "..ft,
            "explode "..ft,
            "res "..ft,
            "r6 "..ft,
            "explode "..ft
        }, 4)
    elseif key == "Map2" then
        addMulti({
            "crash "..ft,
            "re "..ft,
            "explode "..ft,
            "jc "..ft,
            "r6 "..ft,
            "explode "..ft,
            "res "..ft,
            "explode "..ft,
            "r15 "..ft,
            "explode "..ft,
            "nv "..ft,
            "loopkill "..ft,
            "loopwarp "..ft,
            "re "..ft,
            "explode "..ft
        }, 4)
    elseif key == "Map3" then
        addMulti({
            "re "..ft,
            "explode "..ft,
            "logs "..ft,
            "kill "..ft,
            "re "..ft,
            "logs "..ft,
            "clogs "..ft,
            "fling "..ft,
            "ice "..ft,
            "explode "..ft,
            "re "..ft,
            "kill "..ft,
            "nv "..ft,
            "logs "..ft,
            "explode "..ft,
            "re "..ft,
            "explode "..ft,
            "logs "..ft,
            "kill "..ft,
            "re "..ft,
            "logs "..ft,
            "clogs "..ft,
            "fling "..ft,
            "ice "..ft,
            "explode "..ft,
            "re "..ft,
            "kill "..ft,
            "nv "..ft,
            "logs "..ft,
            "explode "..ft
        }, 3)
    elseif key == "CopyInsult1" then
        for _, c in ipairs({
            "tp "..ft,
            "char "..ft.." lalarobloxlais",
            "ref "..ft,
            "phase "..ft,
            "dog "..ft,
            "sit "..ft,
            "worm "..ft,
            "titlepk "..ft.." كثي اه🥺"
        }) do table.insert(cmds, c) end
    elseif key == "CopyInsult2" then
        for _, c in ipairs({
            "tp "..ft,
            "dog "..ft,
            "char "..ft.." fz_jn26",
            "ref "..ft,
            "phase "..ft,
            "worm "..ft,
            "dog "..ft,
            "sit "..ft,
            "titlepk "..ft.." اه اه 🥺🥵"
        }) do table.insert(cmds, c) end
    elseif key == "CopyInsult3" then
        for _, c in ipairs({
            "tp "..ft,
            "worm "..ft,
            "buffify "..ft,
            "fat "..ft,
            "dwarf "..ft,
            "titlepk "..ft.." اه تيزي 🥵🥺"
        }) do table.insert(cmds, c) end
    end
    return cmds
end

-- ============================================================
-- 🎨 GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "TRO_CosmicGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local root = Instance.new("Frame", gui)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local cam = workspace.CurrentCamera
if not cam then
    cam = workspace:WaitForChild("Camera", 5)
end
local vp = cam and cam.ViewportSize or Vector2.new(900, 650)
root.Size = UDim2.fromOffset(math.clamp(vp.X * 0.9, 340, 900), math.clamp(vp.Y * 0.78, 280, 650))
root.BackgroundColor3 = C_BLACK
root.BorderSizePixel = 0
root.ClipsDescendants = true
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 22)
local rtS = Instance.new("UIStroke", root)
rtS.Color = Color3.fromRGB(52, 52, 58)
rtS.Thickness = 1.5
rtS.Transparency = 0.15
local rtG = Instance.new("UIGradient", root)
rtG.Rotation = 90
rtG.Color = ColorSequence.new(Color3.fromRGB(3,3,5), Color3.fromRGB(8,8,10))

-- Stars
local starLayer = Instance.new("Frame", root)
starLayer.BackgroundTransparency = 1
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.ZIndex = 1
local rng = Random.new()
local starData = {}
for i = 1, 90 do
    local s = Instance.new("Frame", starLayer)
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    local sz = (i % 11 == 0) and 3 or rng:NextInteger(1, 2)
    s.Size = UDim2.fromOffset(sz, sz)
    s.Position = UDim2.fromScale(rng:NextNumber(0.015, 0.985), rng:NextNumber(0.04, 0.69))
    s.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
    s.BackgroundTransparency = rng:NextNumber(0.05, 0.55)
    s.BorderSizePixel = 0
    s.ZIndex = 1
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
    table.insert(starData, {dot = s, base = s.BackgroundTransparency, phase = rng:NextNumber(0, math.pi * 2), speed = rng:NextNumber(0.5, 1.8)})
end

-- Orb
local orb = Instance.new("Frame", root)
orb.AnchorPoint = Vector2.new(0.5, 0.5)
orb.Position = UDim2.new(0.5, 0, 0.61, 0)
orb.Size = UDim2.fromScale(0.29, 0.43)
orb.BackgroundColor3 = C_BLACK
orb.BorderSizePixel = 0
orb.ZIndex = 5
Instance.new("UIAspectRatioConstraint", orb).AspectRatio = 1
Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
local orbS = Instance.new("UIStroke", orb)
orbS.Color = Color3.fromRGB(205, 205, 215)
orbS.Thickness = 1.4
orbS.Transparency = 0.12

-- Waves
local waveLayer = Instance.new("Frame", root)
waveLayer.BackgroundTransparency = 1
waveLayer.Size = UDim2.fromScale(1, 0.57)
waveLayer.Position = UDim2.fromScale(0, 0.48)
waveLayer.ClipsDescendants = true
waveLayer.ZIndex = 3
local waveData = {}
local waveColors = {Color3.fromRGB(245,245,250), Color3.fromRGB(155,155,168), Color3.fromRGB(75,75,88), Color3.fromRGB(205,205,215), Color3.fromRGB(105,105,118)}
for i = 1, 5 do
    local b = Instance.new("Frame", waveLayer)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = UDim2.new(0.5, 0, 0.25 + i * 0.12, 0)
    b.Size = UDim2.new(1.45, 0, 0, 2 + (i % 2))
    b.Rotation = (i % 2 == 0) and -2 or 2
    b.BackgroundColor3 = waveColors[i]
    b.BackgroundTransparency = 0.18 + i * 0.12
    b.BorderSizePixel = 0
    b.ZIndex = 3
    local g = Instance.new("UIGradient", b)
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(0.22, 0.25),
        NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(0.78, 0.2),
        NumberSequenceKeypoint.new(1, 0.95),
    })
    table.insert(waveData, b)
end

-- Sidebar
local SIDEBAR_W = 180
local mainUI = Instance.new("Frame", root)
mainUI.BackgroundTransparency = 1
mainUI.Position = UDim2.new(0, 16, 0, 66)
mainUI.Size = UDim2.new(1, -32, 1, -132)
mainUI.ZIndex = 20

local side = Instance.new("Frame", mainUI)
side.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
side.BackgroundColor3 = Color3.fromRGB(3, 3, 5)
side.BackgroundTransparency = 0.12
side.BorderSizePixel = 0
side.ZIndex = 20
Instance.new("UICorner", side).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", side).Color = Color3.fromRGB(52, 52, 58)

local sideLbl = Instance.new("TextLabel", side)
sideLbl.BackgroundTransparency = 1
sideLbl.Position = UDim2.new(0, 14, 0, 12)
sideLbl.Size = UDim2.new(1, -28, 0, 22)
sideLbl.Font = Enum.Font.GothamBold
sideLbl.Text = "TRO MENU"
sideLbl.TextSize = 11
sideLbl.TextColor3 = Color3.fromRGB(155, 155, 165)
sideLbl.TextXAlignment = Enum.TextXAlignment.Left

local function mkTab(text, y, isAct)
    local b = Instance.new("TextButton", side)
    b.Position = UDim2.new(0, 8, 0, y)
    b.Size = UDim2.new(1, -16, 0, 36)
    b.BackgroundColor3 = isAct and C_BTN_ACTIVE or Color3.fromRGB(10, 10, 12)
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextColor3 = isAct and C_TEXT or C_TEXT_DIM
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(40, 40, 48)
    return b
end

local mainTab = mkTab("الرئيسية", 43, true)
local playerTab = mkTab("اللاعب", 87, false)
local spamTab = mkTab("سبام", 131, false)
local targetTab = mkTab("استهداف", 175, false)
local antisTab = mkTab("مضادات", 219, false)
local protectionsTab = mkTab("حمايات", 263, false)
local toolsTab = mkTab("أدوات", 307, false)

local content = Instance.new("Frame", mainUI)
content.Position = UDim2.new(0, SIDEBAR_W + 12, 0, 0)
content.Size = UDim2.new(1, -(SIDEBAR_W + 12), 1, 0)
content.BackgroundColor3 = Color3.fromRGB(2, 2, 3)
content.BackgroundTransparency = 0.6
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.ZIndex = 20
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", content).Color = Color3.fromRGB(52, 52, 58)

local sectionTitle = Instance.new("TextLabel", content)
sectionTitle.BackgroundTransparency = 1
sectionTitle.Position = UDim2.new(0, 14, 0, 10)
sectionTitle.Size = UDim2.new(1, -28, 0, 24)
sectionTitle.Font = Enum.Font.GothamBold
sectionTitle.Text = "القسم الرئيسي"
sectionTitle.TextSize = 15
sectionTitle.TextColor3 = C_TEXT
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.ZIndex = 21

local function mkPage(cs)
    local p = Instance.new("ScrollingFrame", content)
    p.Position = UDim2.new(0, 12, 0, 42)
    p.Size = UDim2.new(1, -24, 1, -54)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    p.CanvasSize = UDim2.new(0, 0, 0, cs or 600)
    p.Visible = false
    p.ZIndex = 21
    return p
end

local pageMain = mkPage(500)
pageMain.Visible = true
local pagePlayer = mkPage(800)
local pageSpam = mkPage(500)
local pageTarget = mkPage(750)
local pageAntis = mkPage(700)
local pageProtections = mkPage(250)
local pageTools = mkPage(320)

local function setTab(name)
    pageMain.Visible = (name == "main")
    pagePlayer.Visible = (name == "player")
    pageSpam.Visible = (name == "spam")
    pageTarget.Visible = (name == "target")
    pageAntis.Visible = (name == "antis")
    pageProtections.Visible = (name == "protections")
    pageTools.Visible = (name == "tools")
    local titles = {main="القسم الرئيسي", player="اللاعب", spam="سبام", target="استهداف", antis="مضادات", protections="حمايات", tools="أدوات"}
    sectionTitle.Text = titles[name] or "القسم"
    local aBg = C_BTN_ACTIVE
    local iBg = Color3.fromRGB(10, 10, 12)
    local aTc = C_TEXT
    local iTc = C_TEXT_DIM
    mainTab.BackgroundColor3 = (name == "main") and aBg or iBg
    mainTab.TextColor3 = (name == "main") and aTc or iTc
    playerTab.BackgroundColor3 = (name == "player") and aBg or iBg
    playerTab.TextColor3 = (name == "player") and aTc or iTc
    spamTab.BackgroundColor3 = (name == "spam") and aBg or iBg
    spamTab.TextColor3 = (name == "spam") and aTc or iTc
    targetTab.BackgroundColor3 = (name == "target") and aBg or iBg
    targetTab.TextColor3 = (name == "target") and aTc or iTc
    antisTab.BackgroundColor3 = (name == "antis") and aBg or iBg
    antisTab.TextColor3 = (name == "antis") and aTc or iTc
    protectionsTab.BackgroundColor3 = (name == "protections") and aBg or iBg
    protectionsTab.TextColor3 = (name == "protections") and aTc or iTc
    toolsTab.BackgroundColor3 = (name == "tools") and aBg or iBg
    toolsTab.TextColor3 = (name == "tools") and aTc or iTc
end

bindClick(mainTab, function() setTab("main") end, "M")
bindClick(playerTab, function() setTab("player") end, "P")
bindClick(spamTab, function() setTab("spam") end, "S")
bindClick(targetTab, function() setTab("target") end, "T")
bindClick(antisTab, function() setTab("antis") end, "A")
bindClick(protectionsTab, function() setTab("protections") end, "H")
bindClick(toolsTab, function() setTab("tools") end, "Tools")

-- ========== MAIN PAGE ==========
local profile = Instance.new("Frame", pageMain)
profile.Size = UDim2.new(1, 0, 0, 200)
profile.BackgroundColor3 = Color3.fromRGB(9, 9, 11)
profile.BackgroundTransparency = 0.35
profile.BorderSizePixel = 0
Instance.new("UICorner", profile).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", profile).Color = Color3.fromRGB(48, 48, 55)

local av = Instance.new("ImageLabel", profile)
av.AnchorPoint = Vector2.new(0, 0.5)
av.Position = UDim2.new(0, 30, 0, 100)
av.Size = UDim2.fromOffset(150, 150)
av.BackgroundColor3 = Color3.fromRGB(16, 16, 19)
av.BorderSizePixel = 0
Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", av).Color = Color3.fromRGB(110, 110, 122)
Instance.new("UIStroke", av).Thickness = 2
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    if ok and img then av.Image = img end
end)

local wl = Instance.new("TextLabel", profile)
wl.BackgroundTransparency = 1
wl.AnchorPoint = Vector2.new(0, 0.5)
wl.Position = UDim2.new(0, 200, 0, 50)
wl.Size = UDim2.new(1, -220, 0, 30)
wl.Font = Enum.Font.GothamBold
wl.Text = "نورت سكربت"
wl.TextSize = 20
wl.TextColor3 = Color3.fromRGB(220, 220, 228)
wl.TextXAlignment = Enum.TextXAlignment.Left

local nl = Instance.new("TextLabel", profile)
nl.BackgroundTransparency = 1
nl.AnchorPoint = Vector2.new(0, 0.5)
nl.Position = UDim2.new(0, 200, 0, 95)
nl.Size = UDim2.new(1, -220, 0, 32)
nl.Font = Enum.Font.GothamBold
nl.Text = player.DisplayName
nl.TextSize = 22
nl.TextColor3 = Color3.fromRGB(238, 238, 244)
nl.TextXAlignment = Enum.TextXAlignment.Left

local ul = Instance.new("TextLabel", profile)
ul.BackgroundTransparency = 1
ul.AnchorPoint = Vector2.new(0, 0.5)
ul.Position = UDim2.new(0, 200, 0, 135)
ul.Size = UDim2.new(1, -220, 0, 24)
ul.Font = Enum.Font.Gotham
ul.Text = "@" .. player.Name
ul.TextSize = 14
ul.TextColor3 = Color3.fromRGB(155, 155, 165)
ul.TextXAlignment = Enum.TextXAlignment.Left

local dsBtn = mkBtn(pageMain, "سيرفر الديسكورد  •  discord.gg/M7sUZHHu8", UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 210), function()
    pcall(function() if setclipboard then setclipboard("https://discord.gg/M7sUZHHu8") end end)
    dsBtn.Text = "✓ تم نسخ الرابط"
    task.delay(2, function()
        if dsBtn and dsBtn.Parent then
            dsBtn.Text = "سيرفر الديسكورد  •  discord.gg/M7sUZHHu8"
        end
    end)
end)

-- ========== PLAYER PAGE ==========
local PY = 0
local function pSec(txt)
    local l = Instance.new("TextLabel", pagePlayer)
    l.Position = UDim2.fromOffset(0, PY)
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(200, 200, 215)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    PY = PY + 26
end

local function pBtn(txt, cb)
    local b = mkBtn(pagePlayer, txt, UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, PY), cb)
    PY = PY + 44
    return b
end

pSec("⚡ السرعة")
pBtn("سرعة 16 (طبيعي)", function() local _, h = getChar() if h then h.WalkSpeed = 16 end end)
pBtn("سرعة 100", function() local _, h = getChar() if h then h.WalkSpeed = 100 end end)
pBtn("سرعة 200", function() local _, h = getChar() if h then h.WalkSpeed = 200 end end)
pBtn("سرعة 500", function() local _, h = getChar() if h then h.WalkSpeed = 500 end end)

pSec("🦘 القفز")
pBtn("قفز 50", function() local _, h = getChar() if h then h.UseJumpPower = true h.JumpPower = 50 end end)
pBtn("قفز 200", function() local _, h = getChar() if h then h.UseJumpPower = true h.JumpPower = 200 end end)
pBtn("قفز 500", function() local _, h = getChar() if h then h.UseJumpPower = true h.JumpPower = 500 end end)

pSec("🌀 أدوات")
local noclipOn = false
local noclipBtn
noclipBtn = pBtn("🌀 Noclip: OFF", function()
    noclipOn = not noclipOn
    noclipBtn.Text = "🌀 Noclip: " .. (noclipOn and "ON" or "OFF")
    noclipBtn.BackgroundColor3 = noclipOn and C_BTN_ACTIVE or C_BTN_IDLE
end)

RunService.Stepped:Connect(function()
    if not noclipOn then return end
    local c = player.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
    end
end)

local invisOn = false
local invisBtn
invisBtn = pBtn("👻 الاختفاء: OFF", function()
    invisOn = not invisOn
    invisBtn.Text = "👻 الاختفاء: " .. (invisOn and "ON" or "OFF")
    invisBtn.BackgroundColor3 = invisOn and C_BTN_ACTIVE or C_BTN_IDLE
end)

RunService.Stepped:Connect(function()
    local c = player.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.LocalTransparencyModifier = invisOn and 1 or 0 end)
        end
    end
end)

pSec("✈️ الطيران")
local flyOn = false
local flyVel = nil
local flyConn = nil
local flyBtn
flyBtn = pBtn("✈️ الطيران: OFF", function()
    if flyOn then
        flyOn = false
        if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
        if flyVel then pcall(function() flyVel:Destroy() end) flyVel = nil end
        local _, h = getChar()
        if h then h.PlatformStand = false end
        flyBtn.Text = "✈️ الطيران: OFF"
        flyBtn.BackgroundColor3 = C_BTN_IDLE
    else
        local _, h, r = getChar()
        if not r or not h then return end
        flyOn = true
        h.PlatformStand = true
        flyVel = Instance.new("BodyVelocity")
        flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyVel.Velocity = Vector3.zero
        flyVel.Parent = r
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyOn then return end
            local _, _, rr = getChar()
            if not rr then return end
            local cam2 = workspace.CurrentCamera
            local mv = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam2.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam2.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam2.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam2.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.yAxis end
            if mv.Magnitude > 0 then mv = mv.Unit end
            flyVel.Velocity = mv * 50
        end)
        flyBtn.Text = "✈️ الطيران: ON"
        flyBtn.BackgroundColor3 = C_BTN_ACTIVE
    end
end)

pSec("📍 الشيك بوينت")
local savedCF = nil
pBtn("💾 حفظ الموقع", function() local _, _, r = getChar() if r then savedCF = r.CFrame end end)
pBtn("↗️ العودة", function() local _, _, r = getChar() if r and savedCF then r.CFrame = savedCF end end)
pBtn("🔄 إعادة الشخصية", function() local _, h = getChar() if h then h.Health = 0 end end)

-- ========== SPAM PAGE ==========
local Spam = {
    activeKey = "Mod",
    selected = {},
    isFullName = false,
    delay = 2,
    chatting = false,
    hiding = false,
    chatThread = nil,
    hiddenThread = nil,
}

local spamHeader = Instance.new("TextLabel", pageSpam)
spamHeader.Size = UDim2.new(1, 0, 0, 24)
spamHeader.BackgroundTransparency = 1
spamHeader.Text = "📢 سبام D7R V8 - 20 Preset"
spamHeader.TextColor3 = C_TEXT
spamHeader.Font = Enum.Font.GothamBold
spamHeader.TextSize = 13
spamHeader.TextXAlignment = Enum.TextXAlignment.Left

local tabsBar = Instance.new("ScrollingFrame", pageSpam)
tabsBar.Position = UDim2.fromOffset(0, 30)
tabsBar.Size = UDim2.new(1, 0, 0, 130)
tabsBar.BackgroundColor3 = C_BLACK
tabsBar.BackgroundTransparency = 0.4
tabsBar.BorderSizePixel = 0
tabsBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabsBar.ScrollBarThickness = 3
Instance.new("UICorner", tabsBar).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tabsBar).Color = C_STROKE

local tabsGrid = Instance.new("UIGridLayout", tabsBar)
tabsGrid.CellSize = UDim2.new(0, 82, 0, 28)
tabsGrid.CellPadding = UDim2.new(0, 4, 0, 4)
local tabsPadding = Instance.new("UIPadding")
tabsPadding.PaddingTop = UDim.new(0, 6)
tabsPadding.PaddingLeft = UDim.new(0, 6)
tabsPadding.Parent = tabsBar
tabsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tabsBar.CanvasSize = UDim2.new(0, 0, 0, tabsGrid.AbsoluteContentSize.Y + 12)
end)

local spamTabBtns = {}
local function renderSpamTabs()
    for _, b in ipairs(spamTabBtns) do pcall(function() b:Destroy() end) end
    spamTabBtns = {}
    for _, p in ipairs(spamPresets) do
        local isAct = (Spam.activeKey == p.key)
        local b = Instance.new("TextButton", tabsBar)
        b.BackgroundColor3 = isAct and C_BTN_ACTIVE or C_BTN_IDLE
        b.Text = p.name
        b.TextColor3 = isAct and C_TEXT or C_TEXT_DIM
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", b).Color = isAct and C_STROKE_HI or C_STROKE
        local key = p.key
        bindClick(b, function()
            Spam.activeKey = key
            renderSpamTabs()
            updateSpamTarget()
        end, key)
        table.insert(spamTabBtns, b)
    end
end

local chatBox = Instance.new("TextBox", pageSpam)
chatBox.Position = UDim2.fromOffset(0, 170)
chatBox.Size = UDim2.new(0.49, -4, 0, 80)
chatBox.BackgroundColor3 = C_BLACK
chatBox.BackgroundTransparency = 0.4
chatBox.BorderSizePixel = 0
chatBox.Text = ""
chatBox.PlaceholderText = "💬 شات عادي..."
chatBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
chatBox.TextColor3 = C_TEXT
chatBox.Font = Enum.Font.Gotham
chatBox.TextSize = 10
chatBox.TextWrapped = true
chatBox.TextXAlignment = Enum.TextXAlignment.Left
chatBox.TextYAlignment = Enum.TextYAlignment.Top
chatBox.MultiLine = true
chatBox.ClearTextOnFocus = false
Instance.new("UICorner", chatBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", chatBox).Color = C_STROKE

local hiddenBox = Instance.new("TextBox", pageSpam)
hiddenBox.Position = UDim2.new(0.51, 0, 0, 170)
hiddenBox.Size = UDim2.new(0.49, -4, 0, 80)
hiddenBox.BackgroundColor3 = C_BLACK
hiddenBox.BackgroundTransparency = 0.4
hiddenBox.BorderSizePixel = 0
hiddenBox.Text = ""
hiddenBox.PlaceholderText = "🕵️ شات مخفي..."
hiddenBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
hiddenBox.TextColor3 = C_TEXT
hiddenBox.Font = Enum.Font.Gotham
hiddenBox.TextSize = 10
hiddenBox.TextWrapped = true
hiddenBox.TextXAlignment = Enum.TextXAlignment.Left
hiddenBox.TextYAlignment = Enum.TextYAlignment.Top
hiddenBox.MultiLine = true
hiddenBox.ClearTextOnFocus = false
Instance.new("UICorner", hiddenBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", hiddenBox).Color = C_STROKE

local targetLbl = Instance.new("TextLabel", pageSpam)
targetLbl.Position = UDim2.fromOffset(0, 256)
targetLbl.Size = UDim2.new(1, 0, 0, 20)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "🎯 الهدف: لا يوجد"
targetLbl.TextColor3 = C_TEXT
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 11
targetLbl.TextXAlignment = Enum.TextXAlignment.Left

local playerScroll = Instance.new("ScrollingFrame", pageSpam)
playerScroll.Position = UDim2.fromOffset(0, 280)
playerScroll.Size = UDim2.new(1, 0, 0, 38)
playerScroll.BackgroundColor3 = C_BLACK
playerScroll.BackgroundTransparency = 0.4
playerScroll.BorderSizePixel = 0
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.ScrollBarThickness = 2
Instance.new("UICorner", playerScroll).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", playerScroll).Color = C_STROKE
local playerLayout = Instance.new("UIListLayout", playerScroll)
playerLayout.FillDirection = Enum.FillDirection.Horizontal
playerLayout.Padding = UDim.new(0, 5)
playerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
Instance.new("UIPadding", playerScroll).PaddingLeft = UDim.new(0, 6)

local optsRow = Instance.new("Frame", pageSpam)
optsRow.Position = UDim2.fromOffset(0, 324)
optsRow.Size = UDim2.new(1, 0, 0, 32)
optsRow.BackgroundTransparency = 1

local speedBox = Instance.new("TextBox", optsRow)
speedBox.Size = UDim2.new(0.32, -4, 1, 0)
speedBox.BackgroundColor3 = C_BTN_IDLE
speedBox.BorderSizePixel = 0
speedBox.Text = "2"
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 11
speedBox.TextColor3 = C_TEXT
speedBox.ClearTextOnFocus = false
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", speedBox).Color = C_STROKE

local prefixBox = Instance.new("TextBox", optsRow)
prefixBox.Position = UDim2.new(0.34, 0, 0, 0)
prefixBox.Size = UDim2.new(0.32, -4, 1, 0)
prefixBox.BackgroundColor3 = C_BTN_IDLE
prefixBox.BorderSizePixel = 0
prefixBox.Text = ";"
prefixBox.Font = Enum.Font.GothamBold
prefixBox.TextSize = 11
prefixBox.TextColor3 = C_TEXT
prefixBox.ClearTextOnFocus = false
Instance.new("UICorner", prefixBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", prefixBox).Color = C_STROKE

local nameToggleBtn = Instance.new("TextButton", optsRow)
nameToggleBtn.Position = UDim2.new(0.68, 0, 0, 0)
nameToggleBtn.Size = UDim2.new(0.32, -4, 1, 0)
nameToggleBtn.BackgroundColor3 = C_BTN_IDLE
nameToggleBtn.Text = "✂️ حرفين"
nameToggleBtn.TextColor3 = C_TEXT_DIM
nameToggleBtn.Font = Enum.Font.GothamBold
nameToggleBtn.TextSize = 10
nameToggleBtn.AutoButtonColor = false
Instance.new("UICorner", nameToggleBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", nameToggleBtn).Color = C_STROKE

local sendChatBtn = mkBtn(pageSpam, "⚡ إرسال شات", UDim2.new(0.49, -4, 0, 42), UDim2.fromOffset(0, 364))
local sendHiddenBtn = mkBtn(pageSpam, "🕵️ إرسال مخفي", UDim2.new(0.49, -4, 0, 42), UDim2.new(0.51, 0, 0, 364))

local function buildTargets()
    if #Spam.selected == 0 then return "" end
    local t = {}
    for _, name in ipairs(Spam.selected) do
        table.insert(t, Spam.isFullName and name or string.sub(name, 1, 2))
    end
    return table.concat(t, ",")
end

local function updateSpamTarget()
    local ft = buildTargets()
    if ft == "" then
        targetLbl.Text = "🎯 الهدف: لا يوجد"
        chatBox.Text = ""
        hiddenBox.Text = ""
        return
    end
    targetLbl.Text = "🎯 الهدف: " .. ft
    local p = (prefixBox.Text == "" or not prefixBox.Text) and ";" or prefixBox.Text
    local cmds = genPreset(ft, Spam.activeKey)
    for i, c in ipairs(cmds) do cmds[i] = p .. c end
    local result = table.concat(cmds, " ")
    chatBox.Text = result
    hiddenBox.Text = result
end

local spamPlayerBtns = {}
local function updateSpamList()
    local active = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        active[plr.Name] = true
        if not spamPlayerBtns[plr.Name] then
            local b = Instance.new("TextButton", playerScroll)
            b.Size = UDim2.fromOffset(78, 24)
            b.BackgroundColor3 = C_BTN_IDLE
            b.Text = plr.Name
            b.TextColor3 = C_TEXT_DIM
            b.Font = Enum.Font.GothamBold
            b.TextSize = 9
            b.AutoButtonColor = false
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
            local s = Instance.new("UIStroke", b)
            s.Color = C_STROKE
            local pName = plr.Name
            b.MouseButton1Click:Connect(function()
                local i = table.find(Spam.selected, pName)
                if i then
                    table.remove(Spam.selected, i)
                    b.BackgroundColor3 = C_BTN_IDLE
                    b.TextColor3 = C_TEXT_DIM
                    s.Color = C_STROKE
                else
                    table.insert(Spam.selected, pName)
                    b.BackgroundColor3 = C_BTN_ACTIVE
                    b.TextColor3 = C_TEXT
                    s.Color = C_STROKE_HI
                end
                updateSpamTarget()
            end)
            spamPlayerBtns[plr.Name] = b
        end
    end
    for pName, b in pairs(spamPlayerBtns) do
        if not active[pName] then
            local i = table.find(Spam.selected, pName)
            if i then table.remove(Spam.selected, i) end
            b:Destroy()
            spamPlayerBtns[pName] = nil
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, playerLayout.AbsoluteContentSize.X + 16, 0, 0)
    updateSpamTarget()
end

local function sendChatMsg(str)
    task.defer(function()
        pcall(function()
            if player.Character and player.Character:FindFirstChild("Head") then
                Chat:Chat(player.Character.Head, str, Enum.ChatColor.White)
            end
        end)
        for _, remote in ipairs(FoundRemotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(str)
                    remote:FireServer(str, "All")
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(str)
                end
            end)
        end
    end)
end

bindClick(sendChatBtn, function()
    if Spam.chatting then
        Spam.chatting = false
        if Spam.chatThread then pcall(function() task.cancel(Spam.chatThread) end) Spam.chatThread = nil end
        sendChatBtn.Text = "⚡ إرسال شات"
        sendChatBtn.BackgroundColor3 = C_BTN_IDLE
        return
    end
    if chatBox.Text == "" then notify("TRO", "⚠ اكتب نص!") return end
    scanRemotes()
    Spam.chatting = true
    sendChatBtn.Text = "🛑 إيقاف"
    sendChatBtn.BackgroundColor3 = C_BTN_ACTIVE
    Spam.chatThread = task.spawn(function()
        while Spam.chatting do
            local msg = chatBox.Text
            if msg ~= "" then sendChatMsg(msg) end
            task.wait(Spam.delay <= 0 and 0 or Spam.delay)
        end
    end)
end, "SendChat")

bindClick(sendHiddenBtn, function()
    if Spam.hiding then
        Spam.hiding = false
        if Spam.hiddenThread then pcall(function() task.cancel(Spam.hiddenThread) end) Spam.hiddenThread = nil end
        sendHiddenBtn.Text = "🕵️ إرسال مخفي"
        sendHiddenBtn.BackgroundColor3 = C_BTN_IDLE
        return
    end
    if hiddenBox.Text == "" then notify("TRO", "⚠ اكتب نص!") return end
    Spam.hiding = true
    sendHiddenBtn.Text = "🛑 إيقاف"
    sendHiddenBtn.BackgroundColor3 = C_BTN_ACTIVE
    Spam.hiddenThread = task.spawn(function()
        while Spam.hiding do
            local msg = hiddenBox.Text
            if msg ~= "" then sendHDAdmin(msg) end
            task.wait(Spam.delay <= 0 and 0 or Spam.delay)
        end
    end)
end, "SendHidden")

prefixBox:GetPropertyChangedSignal("Text"):Connect(updateSpamTarget)
speedBox.FocusLost:Connect(function()
    local v = tonumber(speedBox.Text)
    if v and v >= 0 then Spam.delay = v else speedBox.Text = tostring(Spam.delay) end
end)
bindClick(nameToggleBtn, function()
    Spam.isFullName = not Spam.isFullName
    nameToggleBtn.Text = Spam.isFullName and "📛 كامل" or "✂️ حرفين"
    nameToggleBtn.TextColor3 = Spam.isFullName and C_TEXT or C_TEXT_DIM
    updateSpamTarget()
end, "NameToggle")

renderSpamTabs()
tabsBar.CanvasSize = UDim2.new(0, 0, 0, tabsGrid.AbsoluteContentSize.Y + 12)
updateSpamList()
Players.PlayerAdded:Connect(updateSpamList)
Players.PlayerRemoving:Connect(updateSpamList)

-- ========== TARGET PAGE ==========
local CurrentTarget = nil

local tgtInp = Instance.new("TextBox", pageTarget)
tgtInp.Position = UDim2.fromOffset(0, 0)
tgtInp.Size = UDim2.new(1, -70, 0, 36)
tgtInp.BackgroundColor3 = C_BLACK
tgtInp.BackgroundTransparency = 0.4
tgtInp.BorderSizePixel = 0
tgtInp.PlaceholderText = "اسم اللاعب..."
tgtInp.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
tgtInp.Text = ""
tgtInp.TextColor3 = C_TEXT
tgtInp.Font = Enum.Font.Gotham
tgtInp.TextSize = 12
tgtInp.ClearTextOnFocus = false
Instance.new("UICorner", tgtInp).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", tgtInp).Color = C_STROKE

local tgtSelectBtn = mkBtn(pageTarget, "🎯 اختيار", UDim2.fromOffset(64, 36), UDim2.new(1, -64, 0, 0))

local tgtCard = Instance.new("Frame", pageTarget)
tgtCard.Position = UDim2.fromOffset(0, 46)
tgtCard.Size = UDim2.new(1, 0, 0, 100)
tgtCard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
tgtCard.BackgroundTransparency = 0.2
tgtCard.BorderSizePixel = 0
Instance.new("UICorner", tgtCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tgtCard).Color = C_STROKE

local tgtAvatar = Instance.new("ImageLabel", tgtCard)
tgtAvatar.Position = UDim2.fromOffset(10, 10)
tgtAvatar.Size = UDim2.fromOffset(80, 80)
tgtAvatar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
tgtAvatar.BorderSizePixel = 0
tgtAvatar.Image = "rbxassetid://10818605405"
Instance.new("UICorner", tgtAvatar).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tgtAvatar).Color = C_STROKE_HI
Instance.new("UIStroke", tgtAvatar).Thickness = 1.5

local tgtNameLbl = Instance.new("TextLabel", tgtCard)
tgtNameLbl.Position = UDim2.fromOffset(100, 14)
tgtNameLbl.Size = UDim2.new(1, -110, 0, 22)
tgtNameLbl.BackgroundTransparency = 1
tgtNameLbl.Text = "لم يتم تحديد هدف"
tgtNameLbl.TextColor3 = C_TEXT
tgtNameLbl.Font = Enum.Font.GothamBold
tgtNameLbl.TextSize = 14
tgtNameLbl.TextXAlignment = Enum.TextXAlignment.Left

local tgtDisplayLbl = Instance.new("TextLabel", tgtCard)
tgtDisplayLbl.Position = UDim2.fromOffset(100, 38)
tgtDisplayLbl.Size = UDim2.new(1, -110, 0, 18)
tgtDisplayLbl.BackgroundTransparency = 1
tgtDisplayLbl.Text = "@---"
tgtDisplayLbl.TextColor3 = C_TEXT_DIM
tgtDisplayLbl.Font = Enum.Font.Gotham
tgtDisplayLbl.TextSize = 11
tgtDisplayLbl.TextXAlignment = Enum.TextXAlignment.Left

local tgtIdLbl = Instance.new("TextLabel", tgtCard)
tgtIdLbl.Position = UDim2.fromOffset(100, 58)
tgtIdLbl.Size = UDim2.new(1, -110, 0, 16)
tgtIdLbl.BackgroundTransparency = 1
tgtIdLbl.Text = "ID: ---"
tgtIdLbl.TextColor3 = C_TEXT_DIM
tgtIdLbl.Font = Enum.Font.Code
tgtIdLbl.TextSize = 10
tgtIdLbl.TextXAlignment = Enum.TextXAlignment.Left

local tgtAgeLbl = Instance.new("TextLabel", tgtCard)
tgtAgeLbl.Position = UDim2.fromOffset(100, 74)
tgtAgeLbl.Size = UDim2.new(1, -110, 0, 16)
tgtAgeLbl.BackgroundTransparency = 1
tgtAgeLbl.Text = "--- يوم"
tgtAgeLbl.TextColor3 = C_TEXT_DIM
tgtAgeLbl.Font = Enum.Font.Code
tgtAgeLbl.TextSize = 10
tgtAgeLbl.TextXAlignment = Enum.TextXAlignment.Left

local function updateTarget(plr)
    if not plr then
        tgtInp.Text = ""
        tgtAvatar.Image = "rbxassetid://10818605405"
        tgtNameLbl.Text = "لم يتم تحديد هدف"
        tgtDisplayLbl.Text = "@---"
        tgtIdLbl.Text = "ID: ---"
        tgtAgeLbl.Text = "--- يوم"
        CurrentTarget = nil
        return
    end
    CurrentTarget = plr
    tgtInp.Text = plr.Name
    tgtNameLbl.Text = plr.Name
    tgtDisplayLbl.Text = "@" .. plr.DisplayName
    tgtIdLbl.Text = "ID: " .. plr.UserId
    tgtAgeLbl.Text = plr.AccountAge .. " يوم"
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if ok and img then tgtAvatar.Image = img end
    end)
end

bindClick(tgtSelectBtn, function()
    local q = tgtInp.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return end
    local lq = string.lower(q)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if string.find(string.lower(p.Name), lq, 1, true) or string.find(string.lower(p.DisplayName), lq, 1, true) then
                updateTarget(p)
                return
            end
        end
    end
    notify("Target", "❌ غير موجود")
end, "SelTgt")

local tgtHolder = Instance.new("Frame", pageTarget)
tgtHolder.Position = UDim2.fromOffset(0, 156)
tgtHolder.Size = UDim2.new(1, 0, 0, 320)
tgtHolder.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
tgtHolder.BackgroundTransparency = 0.2
tgtHolder.BorderSizePixel = 0
Instance.new("UICorner", tgtHolder).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tgtHolder).Color = C_STROKE

local tgtHolderTitle = Instance.new("TextLabel", tgtHolder)
tgtHolderTitle.Position = UDim2.new(0, 10, 0, 6)
tgtHolderTitle.Size = UDim2.new(1, -20, 0, 22)
tgtHolderTitle.BackgroundTransparency = 1
tgtHolderTitle.Text = "⚔️ أوامر الاستهداف"
tgtHolderTitle.TextColor3 = C_TEXT
tgtHolderTitle.Font = Enum.Font.GothamBold
tgtHolderTitle.TextSize = 12
tgtHolderTitle.TextXAlignment = Enum.TextXAlignment.Left

local function tgtAnim(id, spd, tp)
    pcall(function()
        local c, h = getChar()
        if not h then return end
        for _, t in pairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://" .. tostring(id)
        local animator = h:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = h
        end
        local tr = animator:LoadAnimation(a)
        tr.Priority = Enum.AnimationPriority.Action
        tr.Looped = false
        tr:Play()
        if tp then tr.TimePosition = tp end
        if spd then tr:AdjustSpeed(spd) end
    end)
end

local function tgtAct(text, col, row, cb)
    local b = Instance.new("TextButton", tgtHolder)
    b.Position = UDim2.new(0.02 + col * 0.49, 0, 0, 34 + row * 46)
    b.Size = UDim2.new(0.47, 0, 0, 40)
    b.BackgroundColor3 = C_BTN_IDLE
    b.Text = text
    b.TextColor3 = C_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextWrapped = true
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", b).Color = C_STROKE
    bindClick(b, function()
        if not CurrentTarget then
            notify("Target", "❌ حدد ضحية أولاً!")
            return
        end
        cb()
    end, text)
    return b
end

tgtAct("🚀 فلنق", 0, 0, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
    if not tr then return end
    pcall(function()
        r.CFrame = tr.CFrame * CFrame.new(0, 2, 0)
        r.AssemblyLinearVelocity = Vector3.new(9e8, 9e8, 9e8)
    end)
    notify("Target", "🚀 فلنق")
end)

tgtAct("👁️ مشاهدة", 1, 0, function()
    local tc = CurrentTarget.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    if th then workspace.CurrentCamera.CameraSubject = th notify("Target", "👁️") end
end)

tgtAct("💥 بانق", 0, 1, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local to = tc and (tc:FindFirstChild("Torso") or tc:FindFirstChild("UpperTorso"))
    if not to then return end
    pcall(function() h.Sit = true r.CFrame = to.CFrame * CFrame.new(0, 0, 1) end)
    notify("Target", "💥 بانق")
end)

tgtAct("🪑 جلوس راس", 1, 1, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local th = tc and tc:FindFirstChild("Head")
    if not th then return end
    pcall(function() h.Sit = true r.CFrame = th.CFrame * CFrame.new(0, 2, 0) end)
    notify("Target", "🪑")
end)

tgtAct("💨 تمص", 0, 2, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local to = tc and (tc:FindFirstChild("Torso") or tc:FindFirstChild("UpperTorso"))
    if not to then return end
    pcall(function() h.Sit = true r.CFrame = to.CFrame * CFrame.new(0, -2.4, 0) * CFrame.Angles(0, math.rad(180), 0) end)
    notify("Target", "💨")
end)

tgtAct("🎯 يمص", 1, 2, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local th = tc and tc:FindFirstChild("Head")
    if not th then return end
    pcall(function() h.Sit = true r.CFrame = th.CFrame * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, math.rad(180), 0) end)
    notify("Target", "🎯")
end)

tgtAct("🎒 حقيبة", 0, 3, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
    if not tr then return end
    pcall(function() h.Sit = true r.CFrame = tr.CFrame * CFrame.new(0, 0, 1.2) * CFrame.Angles(0, -3, 0) end)
    notify("Target", "🎒")
end)

tgtAct("💢 سوها", 1, 3, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
    if not tr then return end
    pcall(function()
        h.Sit = true
        r.CFrame = tr.CFrame * CFrame.new(0, 1, -3) * CFrame.Angles(0, math.pi, 0)
        if h.RigType == Enum.HumanoidRigType.R15 then tgtAnim("698251653", 0.4, 0.6)
        else tgtAnim("72042024", 1, 0.675) end
    end)
    notify("Target", "💢")
end)

tgtAct("🔄 بانق عكسي", 0, 4, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local to = tc and (tc:FindFirstChild("Torso") or tc:FindFirstChild("UpperTorso"))
    if not to then return end
    pcall(function() h.Sit = true r.CFrame = to.CFrame * CFrame.new(0, -0.75, -2) * CFrame.Angles(math.rad(270), 0, 0) end)
    notify("Target", "🔄")
end)

tgtAct("👋 ضرب مؤخرة", 1, 4, function()
    local _, h, r = getChar()
    if not r or not h then return end
    local tc = CurrentTarget.Character
    local to = tc and (tc:FindFirstChild("Torso") or tc:FindFirstChild("UpperTorso"))
    if not to then return end
    pcall(function() h.Sit = true r.CFrame = to.CFrame * CFrame.new(-2, -0.2, 1.7) end)
    if h.RigType == Enum.HumanoidRigType.R15 then tgtAnim("16302986", 1, 16) end
    notify("Target", "👋")
end)

tgtAct("👂 سماع", 0, 5, function()
    local _, _, r = getChar()
    if not r then return end
    local tc = CurrentTarget.Character
    local th = tc and tc:FindFirstChild("Head")
    if not th then return end
    pcall(function() r.CFrame = th.CFrame * CFrame.new(0, -20, 0) * CFrame.Angles(math.rad(180), 0, 0) end)
    notify("Target", "👂")
end)

tgtAct("🔁 تقليد كلام", 1, 5, function()
    if not CurrentTarget then return end
    pcall(function()
        local conn = game:GetService("TextChatService").MessageReceived:Connect(function(msg)
            if CurrentTarget and msg.TextSource and msg.TextSource.UserId == CurrentTarget.UserId then
                sendChatText(msg.Text)
            end
        end)
        task.delay(30, function() pcall(function() conn:Disconnect() end) end)
    end)
    notify("Target", "🔁 30s")
end)

local tgtTpBtn = mkBtn(pageTarget, "✈️ تنقل إلى الهدف", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 482), function()
    if not CurrentTarget then notify("Target", "❌") return end
    local _, _, r = getChar()
    local tc = CurrentTarget.Character
    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
    if r and tr then pcall(function() r.CFrame = tr.CFrame end) notify("Target", "✅") end
end)

local tgtToolBtn = mkBtn(pageTarget, "🎯 أضف أداة اختيار للـ Backpack", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 528), function()
    pcall(function()
        local bp = player:FindFirstChild("Backpack")
        if not bp then return end
        local old = bp:FindFirstChild("ClickTargetTRO")
        if old then old:Destroy() end
        local tool = Instance.new("Tool")
        tool.Name = "ClickTargetTRO"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local m = player:GetMouse()
            local tgt = m.Target
            if tgt and tgt.Parent then
                local plr
                if tgt.Parent:IsA("Model") then plr = Players:GetPlayerFromCharacter(tgt.Parent)
                elseif tgt.Parent:IsA("Accessory") then plr = Players:GetPlayerFromCharacter(tgt.Parent.Parent) end
                if plr and plr ~= player then updateTarget(plr) end
            end
        end)
        tool.Parent = bp
        notify("Target", "✅ تمت الإضافة")
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    if CurrentTarget == p then updateTarget(nil) end
end)


-- ========== TRO ANTI LAUNCHER ==========
local troAntiLoaded = false
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
local function launchTROAnti()
    if troAntiLoaded then
        local existing = playerGui:FindFirstChild("TRO_StarryProtection")
        if existing then
            existing.Enabled = true
            local mainFrame = existing:FindFirstChildWhichIsA("Frame")
            if mainFrame then mainFrame.Visible = true end
            local icon = playerGui:FindFirstChild("TRO_StarryIcon")
            if icon then icon.Enabled = true end
            notify("TRO ANTI", "تم إظهار نافذة الحماية الموجودة")
            return
        end
    end
    troAntiLoaded = true
    local ok, err = pcall(function()
        -- ============================================================
        -- ✦ TRO ANTI — BLACK EDITION + FLOATING ICON
        -- ============================================================
        local Players          = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui       = game:GetService("StarterGui")
        local Workspace        = game:GetService("Workspace")
        local Lighting         = game:GetService("Lighting")
        local RunService       = game:GetService("RunService")
        local TweenService     = game:GetService("TweenService")
        local UserInputService = game:GetService("UserInputService")
        local HttpService      = game:GetService("HttpService")
        
        local player    = Players.LocalPlayer
        playerGui = playerGui or player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
        local camera    = workspace.CurrentCamera or workspace:WaitForChild("Camera")
        
        -- ═══════════════════════════════════════════════════════════
        -- 🔗 Whitelist
        -- ═══════════════════════════════════════════════════════════
        local WL = {}
        pcall(function()
            if not game.HttpGet then return end
            local res = game:HttpGet("https://pastefy.app/reYtYXHy/raw")
            if not res then return end
            local ok, decoded = pcall(function() return HttpService:JSONDecode(res) end)
            if ok and type(decoded) == "table" then
                for _, cmd in ipairs(decoded) do WL[string.lower(tostring(cmd))] = true end
            else
                for line in string.gmatch(res, "[^\r\n]+") do
                    local t = string.match(line, "^%s*(.-)%s*$")
                    if t and t ~= "" then WL[string.lower(t)] = true end
                end
            end
        end)
        local function isWhitelisted(n)
            if not n then return false end
            local l = string.lower(n)
            if WL[l] then return true end
            local fw = string.match(l, "^([^%s]+)")
            return fw and WL[fw] or false
        end
        
        -- تنظيف
        for _, n in ipairs({"TRO_StarryProtection", "TRO_StarryIcon"}) do
            local old = playerGui:FindFirstChild(n)
            if old then old:Destroy() end
        end
        
        local hiddenChar = "\226\128\140"
        local function hasHiddenChar(n) return n and string.find(n, hiddenChar, 1, true) ~= nil end
        local function notify(t, x) pcall(function() StarterGui:SetCore("SendNotification", {Title = t, Text = x, Duration = 3}) end) end
        
        -- ═══════════════════════════════════════════════════════════
        -- 🗂️ State + Cache
        -- ═══════════════════════════════════════════════════════════
        local states = {NV=false, Alerts=false, CmdBlock=false, ECC=false, Nuke=false, Rename=false, Error=false, Warp=false, Blur=false}
        local connections, hiddenObj, renamedObj, disabledScripts, disabledConns = {}, {}, {}, {}, {}
        
        local HD = {client=nil, signals=nil, assets=nil, last=0}
        local function refreshHD()
            local now = os.clock()
            if now - HD.last < 3 and HD.client then return end
            HD.client = ReplicatedStorage:FindFirstChild("HDAdminHDClient")
            if HD.client then
                HD.signals = HD.client:FindFirstChild("Signals")
                HD.assets  = HD.client:FindFirstChild("Assets")
            end
            HD.last = now
        end
        
        local function L(s) return type(s) == "string" and string.lower(s) or "" end
        local NVNames = {"hdadminnightvision","nightvision","night vision","nightvisiontool","nv","night_vision","hd_nv","adminnv","hdadminnv","template5"}
        local RRNames = {["CreateLog"]=true, ["NightVision"]=true, ["CustomTopBar"]=true, ["ExecuteClientCommand"]=true, ["Nickname"]=true, ["SilentAdmin"]=true, ["SAdmin"]=true}
        
        local function isNV(n) if not n or isWhitelisted(n) then return false end local l=L(n) for _,p in ipairs(NVNames) do if string.find(l,p,1,true) then return true end end return false end
        local function isAlert(n) if not n or isWhitelisted(n) then return false end return string.find(L(n),"createalert",1,true)~=nil end
        local function isWarp(n) if not n or isWhitelisted(n) then return false end return string.find(L(n),"warp",1,true)~=nil end
        local function isError(n) if not n or isWhitelisted(n) then return false end return string.find(L(n),"error",1,true)~=nil end
        local function isECC(n) if not n or isWhitelisted(n) then return false end return string.find(n,"ExecuteClientCommand",1,true)~=nil or string.find(n,"ClientCommand",1,true)~=nil end
        
        -- ═══════════════════════════════════════════════════════════
        -- 🎬 Helpers
        -- ═══════════════════════════════════════════════════════════
        local function hideObj(obj)
            if not obj or isWhitelisted(obj.Name) then return end
            pcall(function()
                if obj:IsA("Tool") or obj:IsA("ScreenGui") or obj:IsA("Folder") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    if not hiddenObj[obj] then hiddenObj[obj] = obj.Parent end
                    obj.Parent = nil
                elseif not hasHiddenChar(obj.Name) then
                    if not renamedObj[obj] then renamedObj[obj] = obj.Name end
                    obj.Name = obj.Name .. hiddenChar
                end
            end)
        end
        
        local function disableScript(obj)
            if not obj or isWhitelisted(obj.Name) then return end
            pcall(function()
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    if not disabledScripts[obj] then disabledScripts[obj] = obj.Enabled end
                    obj.Enabled = false
                end
            end)
        end
        
        -- ═══════════════════════════════════════════════════════════
        -- 🛑 Block Commands
        -- ═══════════════════════════════════════════════════════════
        local blockedCmds = {
            "crash","hardcrash","blind","trip","punish","fart","drug","screen",
            "ice","jail","logs","clogs","cmdbar","nv","nightvision",
            "warp","title","blur","alerts","bing","dog","fling",
            "explode","re","res","loopwarp","sit","lay","seated",
            "freeze","stun","ragdoll","kill","damage","godmode",
            "fly","speed","noclip","invisible","size","scale",
            "copy","clone","duplicate","steal","export"
        }
        local namecallHooked = false
        local function installNamecallHook()
            if namecallHooked then return true end
            local ok = pcall(function()
                local mt = getrawmetatable and getrawmetatable(game)
                if not mt then error("no metatable") end
                local old = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    local m = getnamecallmethod()
                    if states.CmdBlock and (m == "FireServer" or m == "InvokeServer") then
                        local a1 = ...
                        if type(a1) == "string" and not isWhitelisted(a1) then
                            local l = string.lower(a1)
                            for _, b in ipairs(blockedCmds) do
                                if string.find(l, b, 1, true) then return end
                            end
                        end
                    end
                    return old(self, ...)
                end)
                setreadonly(mt, true)
            end)
            if ok then namecallHooked = true end
            return ok
        end
        
        -- ═══════════════════════════════════════════════════════════
        -- ⚡ Starters / Stoppers
        -- ═══════════════════════════════════════════════════════════
        local starters, stoppers = {}, {}
        
        function starters.NV()
            if states.NV then return end
            states.NV = true
            for _, o in ipairs(ReplicatedStorage:GetDescendants()) do if isNV(o.Name) then hideObj(o) end end
            for _, o in ipairs(playerGui:GetDescendants()) do if isNV(o.Name) then hideObj(o) end end
            connections.NV = {
                ReplicatedStorage.DescendantAdded:Connect(function(d) if states.NV and isNV(d.Name) then task.defer(hideObj, d) end end),
                playerGui.DescendantAdded:Connect(function(d) if states.NV and isNV(d.Name) then task.defer(hideObj, d) end end),
            }
        end
        function stoppers.NV()
            states.NV = false
            if connections.NV then for _, c in ipairs(connections.NV) do pcall(function() c:Disconnect() end) end connections.NV = nil end
        end
        
        function starters.Alerts()
            if states.Alerts then return end
            states.Alerts = true
            for _, o in ipairs(ReplicatedStorage:GetDescendants()) do if isAlert(o.Name) then disableScript(o) end end
            connections.Alerts = {ReplicatedStorage.DescendantAdded:Connect(function(d) if states.Alerts and isAlert(d.Name) then task.defer(disableScript, d) end end)}
        end
        function stoppers.Alerts()
            states.Alerts = false
            if connections.Alerts then for _, c in ipairs(connections.Alerts) do pcall(function() c:Disconnect() end) end connections.Alerts = nil end
        end
        
        function starters.CmdBlock()
            if states.CmdBlock then return end
            states.CmdBlock = true
            refreshHD()
            installNamecallHook()
            connections.CmdBlock = {ReplicatedStorage.DescendantAdded:Connect(function(d)
                if d.Name == "ExecuteClientCommand" and d:IsA("RemoteEvent") then task.delay(0.3, refreshHD) end
            end)}
        end
        function stoppers.CmdBlock()
            states.CmdBlock = false
            if connections.CmdBlock then for _, c in ipairs(connections.CmdBlock) do pcall(function() c:Disconnect() end) end connections.CmdBlock = nil end
        end
        
        function starters.ECC()
            if states.ECC then return end
            states.ECC = true
            refreshHD()
            local function applyECC()
                refreshHD()
                if not HD.signals then return end
                for _, r in ipairs(HD.signals:GetChildren()) do
                    if isECC(r.Name) and not hasHiddenChar(r.Name) and not isWhitelisted(r.Name) then
                        if not renamedObj[r] then renamedObj[r] = r.Name end
                        r.Name = r.Name .. hiddenChar
                    end
                end
            end
            applyECC()
            connections.ECC = {ReplicatedStorage.DescendantAdded:Connect(function(d)
                if states.ECC and (d.Name == "ExecuteClientCommand" or d.Name == "ExecuteClientCommand2") then task.delay(0.3, applyECC) end
            end)}
        end
        function stoppers.ECC()
            states.ECC = false
            if connections.ECC then for _, c in ipairs(connections.ECC) do pcall(function() c:Disconnect() end) end connections.ECC = nil end
        end
        
        function starters.Nuke()
            if states.Nuke then return end
            states.Nuke = true
            local function applyNuke(obj)
                if not obj or not (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then return end
                if isWhitelisted(obj.Name) then return end
                local l = L(obj.Name)
                if string.find(l, "executeclientcommand", 1, true) or string.find(l, "requestcommand", 1, true) then hideObj(obj) end
            end
            for _, o in ipairs(ReplicatedStorage:GetDescendants()) do applyNuke(o) end
            connections.Nuke = {ReplicatedStorage.DescendantAdded:Connect(function(d) if states.Nuke then task.defer(applyNuke, d) end end)}
        end
        function stoppers.Nuke()
            states.Nuke = false
            if connections.Nuke then for _, c in ipairs(connections.Nuke) do pcall(function() c:Disconnect() end) end connections.Nuke = nil end
        end
        
        function starters.Rename()
            if states.Rename then return end
            states.Rename = true
            for _, o in ipairs(ReplicatedStorage:GetDescendants()) do if RRNames[o.Name] and not isWhitelisted(o.Name) then hideObj(o) end end
            connections.Rename = {
                ReplicatedStorage.DescendantAdded:Connect(function(d) if states.Rename and RRNames[d.Name] and not isWhitelisted(d.Name) then task.defer(hideObj, d) end end),
                playerGui.DescendantAdded:Connect(function(d) if states.Rename and RRNames[d.Name] and not isWhitelisted(d.Name) then task.defer(hideObj, d) end end),
            }
        end
        function stoppers.Rename()
            states.Rename = false
            if connections.Rename then for _, c in ipairs(connections.Rename) do pcall(function() c:Disconnect() end) end connections.Rename = nil end
        end
        
        function starters.Error()
            if states.Error then return end
            states.Error = true
            refreshHD()
            local function applyError(obj)
                if not obj or isWhitelisted(obj.Name) then return end
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then disableScript(obj)
                elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    if getconnections and obj:IsA("RemoteEvent") then
                        pcall(function()
                            for _, c in ipairs(getconnections(obj.OnClientEvent)) do
                                if not disabledConns[c] then c:Disable(); disabledConns[c] = true end
                            end
                        end)
                    end
                end
            end
            if HD.signals then for _, c in ipairs(HD.signals:GetChildren()) do if isError(c.Name) then applyError(c) end end end
            connections.Error = {ReplicatedStorage.DescendantAdded:Connect(function(d) if states.Error and isError(d.Name) then task.defer(applyError, d) end end)}
        end
        function stoppers.Error()
            states.Error = false
            if connections.Error then for _, c in ipairs(connections.Error) do pcall(function() c:Disconnect() end) end connections.Error = nil end
        end
        
        function starters.Warp()
            if states.Warp then return end
            states.Warp = true
            local function applyWarp(obj)
                if not obj or isWhitelisted(obj.Name) then return end
                if obj:IsA("WarpEffect") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("GuiObject") or obj:IsA("Tool") or obj:IsA("Folder") then hideObj(obj) end
            end
            for _, o in ipairs(Workspace:GetDescendants()) do if isWarp(o.Name) then applyWarp(o) end end
            for _, o in ipairs(ReplicatedStorage:GetDescendants()) do if isWarp(o.Name) then applyWarp(o) end end
            connections.Warp = {
                Workspace.DescendantAdded:Connect(function(d) if states.Warp and isWarp(d.Name) then task.defer(applyWarp, d) end end),
                ReplicatedStorage.DescendantAdded:Connect(function(d) if states.Warp and isWarp(d.Name) then task.defer(applyWarp, d) end end),
                Lighting.DescendantAdded:Connect(function(d) if states.Warp and isWarp(d.Name) then task.defer(applyWarp, d) end end),
            }
        end
        function stoppers.Warp()
            states.Warp = false
            if connections.Warp then for _, c in ipairs(connections.Warp) do pcall(function() c:Disconnect() end) end connections.Warp = nil end
        end
        
        function starters.Blur()
            if states.Blur then return end
            states.Blur = true
            local function killBlur(obj)
                if not obj or isWhitelisted(obj.Name) then return end
                pcall(function()
                    if obj:IsA("BlurEffect") then
                        if obj.Size > 15 then obj.Size = 0; obj.Enabled = false; obj:Destroy() end
                    elseif obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") then
                        local n = L(obj.Name)
                        if string.find(n,"crash",1,true) or string.find(n,"blind",1,true) or string.find(n,"trip",1,true) or string.find(n,"blur",1,true) then obj:Destroy() end
                    end
                end)
            end
            connections.Blur = {Lighting.ChildAdded:Connect(killBlur)}
            task.spawn(function()
                while states.Blur do
                    task.wait(0.25)
                    for _, c in ipairs(Lighting:GetChildren()) do killBlur(c) end
                    local cam = Workspace.CurrentCamera
                    if cam then for _, c in ipairs(cam:GetChildren()) do killBlur(c) end end
                end
            end)
        end
        function stoppers.Blur()
            states.Blur = false
            if connections.Blur then for _, c in ipairs(connections.Blur) do pcall(function() c:Disconnect() end) end connections.Blur = nil end
        end
        
        -- ═══════════════════════════════════════════════════════════
        -- 🌑 GUI — النافذة الرئيسية
        -- ═══════════════════════════════════════════════════════════
        local gui = Instance.new("ScreenGui")
        gui.Name = "TRO_StarryProtection"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 999
        gui.Parent = playerGui
        
        local MAIN_W, MAIN_H = 380, 480
        if not camera then camera = workspace:WaitForChild("Camera") end
        local vp = camera.ViewportSize
        local main = Instance.new("Frame", gui)
        main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
        main.Position = UDim2.fromOffset(vp.X * 0.5 - MAIN_W/2, vp.Y * 0.5 - MAIN_H/2)
        main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        main.BorderSizePixel = 0
        main.Active = true
        main.ClipsDescendants = true
        main.Visible = true
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
        
        local mainStroke = Instance.new("UIStroke", main)
        mainStroke.Color = Color3.fromRGB(255, 255, 255)
        mainStroke.Thickness = 1.5
        mainStroke.Transparency = 0.35
        
        -- ✨ نجوم منبضة
        local starLayer = Instance.new("Frame", main)
        starLayer.Size = UDim2.fromScale(1, 1)
        starLayer.BackgroundTransparency = 1
        starLayer.ZIndex = 1
        starLayer.ClipsDescendants = true
        
        local rng = Random.new()
        local stars = {}
        for i = 1, 60 do
            local s = Instance.new("Frame", starLayer)
            s.Size = UDim2.fromOffset(rng:NextInteger(1, 3), rng:NextInteger(1, 3))
            s.Position = UDim2.fromScale(rng:NextNumber(0.02, 0.98), rng:NextNumber(0.02, 0.98))
            s.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            s.BackgroundTransparency = rng:NextNumber(0.2, 0.7)
            s.BorderSizePixel = 0
            s.ZIndex = 1
            Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
            table.insert(stars, {frame = s, base = s.BackgroundTransparency, phase = rng:NextNumber(0, math.pi*2), speed = rng:NextNumber(0.8, 2.5), amp = rng:NextNumber(0.3, 0.6)})
        end
        
        -- 💫 شهب
        local shooting = {}
        for i = 1, 3 do
            local s = Instance.new("Frame", starLayer)
            s.Size = UDim2.fromOffset(60, 1.5)
            s.Position = UDim2.fromScale(1.2, 0.2)
            s.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
            s.BackgroundTransparency = 1
            s.BorderSizePixel = 0
            s.Rotation = 20
            s.ZIndex = 1
            Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
            local grad = Instance.new("UIGradient", s)
            grad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(120,120,140))
            grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
            table.insert(shooting, {frame = s, delay = (i - 1) * 4})
        end
        
        -- Header
        local header = Instance.new("Frame", main)
        header.Size = UDim2.new(1, 0, 0, 52)
        header.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        header.BorderSizePixel = 0
        header.ZIndex = 5
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
        local headerFill = Instance.new("Frame", header)
        headerFill.Size = UDim2.new(1, 0, 0, 26)
        headerFill.Position = UDim2.new(0, 0, 1, -26)
        headerFill.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        headerFill.BorderSizePixel = 0
        headerFill.ZIndex = 5
        
        local titleLbl = Instance.new("TextLabel", header)
        titleLbl.Size = UDim2.new(1, -60, 1, 0)
        titleLbl.Position = UDim2.fromOffset(16, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = "✦ TRO ANTI ✦"
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.Font = Enum.Font.GothamBlack
        titleLbl.TextSize = 15
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 6
        
        -- زر الإغلاق
        local closeBtn = Instance.new("TextButton", header)
        closeBtn.Size = UDim2.fromOffset(30, 30)
        closeBtn.Position = UDim2.new(1, -40, 0, 11)
        closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 13
        closeBtn.AutoButtonColor = false
        closeBtn.ZIndex = 6
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
        local cStroke = Instance.new("UIStroke", closeBtn)
        cStroke.Color = Color3.fromRGB(255, 255, 255)
        cStroke.Thickness = 1
        cStroke.Transparency = 0.6
        
        -- Drag
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = main.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        
        -- Master
        local masterBox = Instance.new("Frame", main)
        masterBox.Size = UDim2.new(1, -24, 0, 58)
        masterBox.Position = UDim2.fromOffset(12, 64)
        masterBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        masterBox.BorderSizePixel = 0
        masterBox.ZIndex = 3
        Instance.new("UICorner", masterBox).CornerRadius = UDim.new(0, 10)
        local mStroke = Instance.new("UIStroke", masterBox)
        mStroke.Color = Color3.fromRGB(255, 255, 255)
        mStroke.Thickness = 1
        mStroke.Transparency = 0.75
        
        local masterDot = Instance.new("Frame", masterBox)
        masterDot.Size = UDim2.fromOffset(12, 12)
        masterDot.Position = UDim2.new(0, 16, 0.5, -6)
        masterDot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        masterDot.BorderSizePixel = 0
        masterDot.ZIndex = 4
        Instance.new("UICorner", masterDot).CornerRadius = UDim.new(1, 0)
        
        local masterTitle = Instance.new("TextLabel", masterBox)
        masterTitle.Size = UDim2.new(1, -170, 0, 18)
        masterTitle.Position = UDim2.fromOffset(36, 10)
        masterTitle.BackgroundTransparency = 1
        masterTitle.Text = "MASTER PROTECTION"
        masterTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
        masterTitle.Font = Enum.Font.GothamBold
        masterTitle.TextSize = 11
        masterTitle.TextXAlignment = Enum.TextXAlignment.Left
        masterTitle.ZIndex = 4
        
        local masterStatus = Instance.new("TextLabel", masterBox)
        masterStatus.Size = UDim2.new(1, -170, 0, 16)
        masterStatus.Position = UDim2.fromOffset(36, 30)
        masterStatus.BackgroundTransparency = 1
        masterStatus.Text = "● OFFLINE"
        masterStatus.TextColor3 = Color3.fromRGB(180, 80, 80)
        masterStatus.Font = Enum.Font.Code
        masterStatus.TextSize = 9
        masterStatus.TextXAlignment = Enum.TextXAlignment.Left
        masterStatus.ZIndex = 4
        
        local masterBtn = Instance.new("TextButton", masterBox)
        masterBtn.Size = UDim2.fromOffset(120, 34)
        masterBtn.Position = UDim2.new(1, -132, 0.5, -17)
        masterBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        masterBtn.Text = "🚀 تفعيل الكل"
        masterBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        masterBtn.Font = Enum.Font.GothamBold
        masterBtn.TextSize = 10
        masterBtn.AutoButtonColor = false
        masterBtn.ZIndex = 4
        Instance.new("UICorner", masterBtn).CornerRadius = UDim.new(0, 8)
        
        -- Scroll
        local scroll = Instance.new("ScrollingFrame", main)
        scroll.Size = UDim2.new(1, -24, 1, -210)
        scroll.Position = UDim2.fromOffset(12, 132)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ZIndex = 3
        Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 6)
        
        local footer = Instance.new("TextLabel", main)
        footer.Size = UDim2.new(1, 0, 0, 18)
        footer.Position = UDim2.new(0, 0, 1, -22)
        footer.BackgroundTransparency = 1
        footer.Text = "✦ TRO ANTI ✦"
        footer.TextColor3 = Color3.fromRGB(120, 120, 120)
        footer.Font = Enum.Font.GothamBold
        footer.TextSize = 9
        footer.ZIndex = 3
        
        -- ═══════════════════════════════════════════════════════════
        -- 🎯 Features
        -- ═══════════════════════════════════════════════════════════
        local features = {
            {key="NV",       name="مضاد NightVision", desc="يمنع تفعيل NV",        icon="🌙"},
            {key="Alerts",   name="مضاد التنبيهات",   desc="يحظر CreateAlert",     icon="🔔"},
            {key="CmdBlock", name="حظر الأوامر",      desc="يمنع أوامر التخريب",   icon="🛑"},
            {key="ECC",      name="مضاد ECC",         desc="ExecuteClientCommand", icon="🔒"},
            {key="Nuke",     name="مضاد Nuke",        desc="يحمي من Remote Nuke",  icon="☢️"},
            {key="Rename",   name="إخفاء أدوات الأدمن",desc="يخفي أدوات HD Admin", icon="👁"},
            {key="Error",    name="مضاد الأخطاء",     desc="يعطل Error Signals",   icon="⚠️"},
            {key="Warp",     name="مضاد Warp",        desc="يمنع تأثيرات Warp",    icon="🌀"},
            {key="Blur",     name="مضاد Blur",        desc="يحمي من Blur",         icon="🌫"},
        }
        
        local uiRefs = {}
        local function refreshMaster()
            local allOn = true
            for _, f in ipairs(features) do if not states[f.key] then allOn = false; break end end
            if allOn then
                masterDot.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
                masterStatus.Text = "● ALL ACTIVE"
                masterStatus.TextColor3 = Color3.fromRGB(100, 255, 180)
            else
                masterDot.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
                masterStatus.Text = "● OFFLINE"
                masterStatus.TextColor3 = Color3.fromRGB(180, 80, 80)
            end
        end
        
        local function setFeature(key, on)
            local f = uiRefs[key]
            if not f then return end
            if on and not states[key] then
                starters[key]()
                f.toggle.Text = "ON"
                f.toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                f.toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
                f.row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                f.rowStroke.Transparency = 0.2
            elseif not on and states[key] then
                stoppers[key]()
                f.toggle.Text = "OFF"
                f.toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                f.toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
                f.row.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                f.rowStroke.Transparency = 0.8
            end
            refreshMaster()
        end
        
        for _, f in ipairs(features) do
            local row = Instance.new("Frame", scroll)
            row.Size = UDim2.new(1, 0, 0, 48)
            row.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            row.BorderSizePixel = 0
            row.ZIndex = 3
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = Color3.fromRGB(255, 255, 255)
            rowStroke.Thickness = 1
            rowStroke.Transparency = 0.8
        
            local icon = Instance.new("TextLabel", row)
            icon.Size = UDim2.fromOffset(34, 34)
            icon.Position = UDim2.fromOffset(8, 7)
            icon.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            icon.Text = f.icon
            icon.Font = Enum.Font.GothamBlack
            icon.TextSize = 15
            icon.BorderSizePixel = 0
            icon.ZIndex = 4
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)
        
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -160, 0, 16)
            nameLbl.Position = UDim2.fromOffset(50, 7)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = f.name
            nameLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 10
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.ZIndex = 4
        
            local descLbl = Instance.new("TextLabel", row)
            descLbl.Size = UDim2.new(1, -160, 0, 14)
            descLbl.Position = UDim2.fromOffset(50, 24)
            descLbl.BackgroundTransparency = 1
            descLbl.Text = f.desc
            descLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 8
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.ZIndex = 4
        
            local toggle = Instance.new("TextButton", row)
            toggle.Size = UDim2.fromOffset(48, 26)
            toggle.Position = UDim2.new(1, -56, 0.5, -13)
            toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            toggle.Text = "OFF"
            toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
            toggle.Font = Enum.Font.GothamBold
            toggle.TextSize = 9
            toggle.AutoButtonColor = false
            toggle.ZIndex = 4
            Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
            local tStroke = Instance.new("UIStroke", toggle)
            tStroke.Color = Color3.fromRGB(255, 255, 255)
            tStroke.Thickness = 1
            tStroke.Transparency = 0.7
        
            toggle.Activated:Connect(function() setFeature(f.key, not states[f.key]) end)
            uiRefs[f.key] = {row = row, rowStroke = rowStroke, toggle = toggle}
        end
        
        masterBtn.Activated:Connect(function()
            local allOn = true
            for _, f in ipairs(features) do if not states[f.key] then allOn = false; break end end
            for _, f in ipairs(features) do setFeature(f.key, not allOn) end
            if not allOn then
                masterBtn.Text = "⛔ إيقاف الكل"
                masterBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                masterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                notify("TRO ANTI", "✅ تم تفعيل جميع الحمايات")
            else
                masterBtn.Text = "🚀 تفعيل الكل"
                masterBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                masterBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
                notify("TRO ANTI", "⛔ تم إيقاف جميع الحمايات")
            end
        end)
        
        -- ═══════════════════════════════════════════════════════════
        -- 🌟 الأيقونة العائمة — TRO
        -- ═══════════════════════════════════════════════════════════
        local iconGui = Instance.new("ScreenGui")
        iconGui.Name = "TRO_StarryIcon"
        iconGui.ResetOnSpawn = false
        iconGui.IgnoreGuiInset = true
        iconGui.DisplayOrder = 1000
        iconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        iconGui.Parent = playerGui
        
        local ICON_SIZE = 64
        local iconBtn = Instance.new("TextButton", iconGui)
        iconBtn.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
        iconBtn.Position = UDim2.fromOffset(20, vp.Y * 0.4)
        iconBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        iconBtn.Text = "TRO"
        iconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconBtn.Font = Enum.Font.GothamBlack
        iconBtn.TextSize = 16
        iconBtn.AutoButtonColor = false
        iconBtn.Active = true
        iconBtn.ZIndex = 1000
        Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(1, 0)
        
        local iconStroke = Instance.new("UIStroke", iconBtn)
        iconStroke.Color = Color3.fromRGB(255, 255, 255)
        iconStroke.Thickness = 2
        iconStroke.Transparency = 0.1
        
        -- هالة بيضاء داخلية
        local iconGlow = Instance.new("Frame", iconBtn)
        iconGlow.Size = UDim2.new(1, -10, 1, -10)
        iconGlow.Position = UDim2.new(0, 5, 0, 5)
        iconGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iconGlow.BackgroundTransparency = 0.92
        iconGlow.BorderSizePixel = 0
        iconGlow.ZIndex = 0
        Instance.new("UICorner", iconGlow).CornerRadius = UDim.new(1, 0)
        
        -- نبض على حدود الأيقونة
        task.spawn(function()
            while iconGui.Parent do
                TweenService:Create(iconStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2.8, Transparency = 0.35}):Play()
                TweenService:Create(iconGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.85}):Play()
                task.wait(1.2)
                if not iconGui.Parent then break end
                TweenService:Create(iconStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1.6, Transparency = 0.05}):Play()
                TweenService:Create(iconGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.95}):Play()
                task.wait(1.2)
            end
        end)
        
        -- سحب الأيقونة
        local iconDragging, iconMoved, iconStartPos, iconStartInput = false, false, nil, nil
        iconBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                iconDragging = true
                iconMoved = false
                iconStartInput = input.Position
                iconStartPos = iconBtn.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - iconStartInput
                if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then iconMoved = true end
                if iconMoved then
                    iconBtn.Position = UDim2.fromOffset(iconStartPos.X.Offset + d.X, iconStartPos.Y.Offset + d.Y)
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if iconDragging and not iconMoved then
                    if main.Visible then
                        TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                            Size = UDim2.fromOffset(0, 0),
                        }):Play()
                        task.delay(0.22, function() main.Visible = false end)
                    else
                        main.Visible = true
                        main.Size = UDim2.fromOffset(20, 20)
                        main.Position = UDim2.fromOffset(vp.X * 0.5 - 10, vp.Y * 0.5 - 10)
                        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(MAIN_W, MAIN_H),
                            Position = UDim2.fromOffset(vp.X * 0.5 - MAIN_W/2, vp.Y * 0.5 - MAIN_H/2),
                        }):Play()
                    end
                end
                iconDragging = false
            end
        end)
        
        -- Hover
        iconBtn.MouseEnter:Connect(function()
            TweenService:Create(iconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
        end)
        iconBtn.MouseLeave:Connect(function()
            TweenService:Create(iconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end)
        
        -- زر إغلاق النافذة
        closeBtn.Activated:Connect(function()
            TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
            }):Play()
            task.delay(0.22, function() main.Visible = false end)
        end)
        
        -- ═══════════════════════════════════════════════════════════
        -- ✨ Animation Loop
        -- ═══════════════════════════════════════════════════════════
        local t0 = os.clock()
        RunService.RenderStepped:Connect(function()
            if not gui.Parent then return end
            if not gui.Enabled then return end
            local t = os.clock() - t0
        
            for _, s in ipairs(stars) do
                if s.frame.Parent then
                    local new = s.base + math.sin(t * s.speed + s.phase) * s.amp
                    s.frame.BackgroundTransparency = math.clamp(new, 0, 1)
                end
            end
        
            for _, ss in ipairs(shooting) do
                if ss.frame.Parent then
                    local cyc = (t + ss.delay) % 12
                    if cyc < 1.6 then
                        local p = cyc / 1.6
                        ss.frame.Position = UDim2.fromScale(1.15 - p * 1.3, 0.05 + p * 0.85)
                        ss.frame.BackgroundTransparency = math.sin(p * math.pi) * 0.3
                    else
                        ss.frame.BackgroundTransparency = 1
                    end
                end
            end
        
            mainStroke.Transparency = 0.35 + math.sin(t * 1.8) * 0.15
        end)
        
        refreshMaster()
        notify("✦ TRO ANTI ✦", "تم فتح نافذة الحماية؛ استخدم زر TRO لإخفائها أو إظهارها")
        print("[TRO ANTI] Loaded ✓ — اضغط TRO")
    end)
    if not ok then
        warn("[TRO ANTI integration]", err)
        notify("TRO ANTI", "خطأ: " .. string.sub(tostring(err), 1, 140))
        troAntiLoaded = false
    end
end

-- ========== ANTIS PAGE ==========
local acTitle = Instance.new("TextLabel", pageAntis)
acTitle.Position = UDim2.fromOffset(0, 0)
acTitle.Size = UDim2.new(1, 0, 0, 24)
acTitle.BackgroundTransparency = 1
acTitle.Text = "🛡️ Anti-Chain"
acTitle.TextColor3 = C_TEXT
acTitle.Font = Enum.Font.GothamBold
acTitle.TextSize = 13
acTitle.TextXAlignment = Enum.TextXAlignment.Left

local acToggleBtn = mkBtn(pageAntis, "🟢 الحماية مفعلة", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 30), nil, true)

bindClick(acToggleBtn, function()
    AC.enabled = not AC.enabled
    if AC.enabled then
        acToggleBtn.Text = "🟢 الحماية مفعلة"
        acToggleBtn.BackgroundColor3 = C_BTN_ACTIVE
        acLog("✅ ON")
    else
        acToggleBtn.Text = "🔴 الحماية معطلة"
        acToggleBtn.BackgroundColor3 = C_BTN_IDLE
        acLog("⛔ OFF")
    end
end, "AcTog")

local acCounter = Instance.new("TextLabel", pageAntis)
acCounter.Position = UDim2.fromOffset(0, 78)
acCounter.Size = UDim2.new(1, 0, 0, 30)
acCounter.BackgroundColor3 = C_BLACK
acCounter.BackgroundTransparency = 0.4
acCounter.Text = "Sit: 0 | PS: 0 | CF: 0 | W: 0"
acCounter.TextColor3 = C_TEXT
acCounter.Font = Enum.Font.GothamBold
acCounter.TextSize = 10
Instance.new("UICorner", acCounter).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", acCounter).Color = C_STROKE

local acLogBox = Instance.new("TextLabel", pageAntis)
acLogBox.Position = UDim2.fromOffset(0, 114)
acLogBox.Size = UDim2.new(1, 0, 0, 80)
acLogBox.BackgroundColor3 = C_BLACK
acLogBox.BackgroundTransparency = 0.4
acLogBox.Text = "> جاهز..."
acLogBox.TextColor3 = C_TEXT_DIM
acLogBox.Font = Enum.Font.Code
acLogBox.TextSize = 9
acLogBox.TextXAlignment = Enum.TextXAlignment.Left
acLogBox.TextYAlignment = Enum.TextYAlignment.Top
acLogBox.TextWrapped = true
Instance.new("UICorner", acLogBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", acLogBox).Color = C_STROKE

local acUncuffBtn = mkBtn(pageAntis, "🔓 فك", UDim2.new(0.32, -3, 0, 34), UDim2.fromOffset(0, 200), function()
    AC.lastUncuff = 0
    local n = acUncuff()
    acLog("🔓 UnCuff → " .. n)
end)

local acLockBtn = mkBtn(pageAntis, "🔒 قفل", UDim2.new(0.32, -3, 0, 34), UDim2.new(0.34, 0, 0, 200), function()
    AC.defending = false
    AC.baselineCF = nil
    acLock("يدوي")
end)

local acResetBtn = mkBtn(pageAntis, "💀 إعادة", UDim2.new(0.32, -3, 0, 34), UDim2.new(0.68, 0, 0, 200), function()
    AC.lastReset = 0
    acReset("يدوي")
end)

local div1 = Instance.new("Frame", pageAntis)
div1.Position = UDim2.fromOffset(0, 240)
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = C_STROKE
div1.BorderSizePixel = 0

local dgTitle = Instance.new("TextLabel", pageAntis)
dgTitle.Position = UDim2.fromOffset(0, 250)
dgTitle.Size = UDim2.new(1, 0, 0, 24)
dgTitle.BackgroundTransparency = 1
dgTitle.Text = "⚡ المراوغة (Q)"
dgTitle.TextColor3 = C_TEXT
dgTitle.Font = Enum.Font.GothamBold
dgTitle.TextSize = 12
dgTitle.TextXAlignment = Enum.TextXAlignment.Left

local dgStatus = Instance.new("TextLabel", pageAntis)
dgStatus.Position = UDim2.fromOffset(0, 278)
dgStatus.Size = UDim2.new(1, 0, 0, 24)
dgStatus.BackgroundColor3 = C_BLACK
dgStatus.BackgroundTransparency = 0.4
dgStatus.Text = "المراوغة: 0 | Auto: OFF"
dgStatus.TextColor3 = C_TEXT
dgStatus.Font = Enum.Font.Code
dgStatus.TextSize = 9
dgStatus.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", dgStatus).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", dgStatus).Color = C_STROKE

local dgAutoBtn = mkBtn(pageAntis, "▶️ تلقائي: OFF", UDim2.new(0.49, -4, 0, 40), UDim2.fromOffset(0, 310))
local dgManualBtn = mkBtn(pageAntis, "⚡ مراوغة (Q)", UDim2.new(0.49, -4, 0, 40), UDim2.new(0.51, 0, 0, 310))

bindClick(dgAutoBtn, function()
    Dg.auto = not Dg.auto
    if Dg.auto then
        dgAutoBtn.Text = "⏹️ تلقائي: ON"
        dgAutoBtn.BackgroundColor3 = C_BTN_ACTIVE
        dgLog("▶️ Auto ON")
        task.spawn(function()
            while Dg.auto do
                if not Dg.dodging then dgDo() end
                task.wait(0.35)
            end
        end)
    else
        dgAutoBtn.Text = "▶️ تلقائي: OFF"
        dgAutoBtn.BackgroundColor3 = C_BTN_IDLE
        dgLog("⏹️ Auto OFF")
    end
end, "DgAuto")

bindClick(dgManualBtn, function() dgDo() end, "DgManual")

local div2 = Instance.new("Frame", pageAntis)
div2.Position = UDim2.fromOffset(0, 360)
div2.Size = UDim2.new(1, 0, 0, 1)
div2.BackgroundColor3 = C_STROKE
div2.BorderSizePixel = 0

local afkTitle = Instance.new("TextLabel", pageAntis)
afkTitle.Position = UDim2.fromOffset(0, 370)
afkTitle.Size = UDim2.new(1, 0, 0, 24)
afkTitle.BackgroundTransparency = 1
afkTitle.Text = "⌛ Anti-AFK"
afkTitle.TextColor3 = C_TEXT
afkTitle.Font = Enum.Font.GothamBold
afkTitle.TextSize = 12
afkTitle.TextXAlignment = Enum.TextXAlignment.Left

local afkStatus = Instance.new("TextLabel", pageAntis)
afkStatus.Position = UDim2.fromOffset(0, 398)
afkStatus.Size = UDim2.new(1, 0, 0, 24)
afkStatus.BackgroundColor3 = C_BLACK
afkStatus.BackgroundTransparency = 0.4
afkStatus.Text = "Anti-AFK: OFF"
afkStatus.TextColor3 = C_TEXT_DIM
afkStatus.Font = Enum.Font.Code
afkStatus.TextSize = 9
afkStatus.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", afkStatus).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", afkStatus).Color = C_STROKE

local afkToggleBtn = mkBtn(pageAntis, "▶️ تفعيل Anti-AFK", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 430))

bindClick(afkToggleBtn, function()
    AFK.enabled = not AFK.enabled
    if AFK.enabled then
        afkStart()
        afkToggleBtn.Text = "⏹️ إيقاف Anti-AFK"
        afkToggleBtn.BackgroundColor3 = C_BTN_ACTIVE
        afkStatus.TextColor3 = C_TEXT
    else
        afkStop()
        afkToggleBtn.Text = "▶️ تفعيل Anti-AFK"
        afkToggleBtn.BackgroundColor3 = C_BTN_IDLE
        afkStatus.TextColor3 = C_TEXT_DIM
    end
end, "AfkToggle")

-- ========== PROTECTIONS PAGE ==========
local protectionsHeader = Instance.new("TextLabel", pageProtections)
protectionsHeader.Position = UDim2.fromOffset(0, 4)
protectionsHeader.Size = UDim2.new(1, 0, 0, 28)
protectionsHeader.BackgroundTransparency = 1
protectionsHeader.Text = "🛡️ قسم الحمايات"
protectionsHeader.TextColor3 = C_TEXT
protectionsHeader.Font = Enum.Font.GothamBold
protectionsHeader.TextSize = 14
protectionsHeader.TextXAlignment = Enum.TextXAlignment.Left

local troAntiBtn = mkBtn(pageProtections, "🛡️ حماية أساسية", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 42), function()
    launchTROAnti()
end)
troAntiBtn.BackgroundColor3 = C_BTN_ACTIVE

-- حماية الرقصات: يتم تشغيل السكربت الأصلي كما هو عند الضغط على الزر.
local danceProtectionSource = [====[
-- ============================================================
-- Anti-Emote — يمنع الرقصات القسرية
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("AntiEmoteGUI")
if old then old:Destroy() end

local WL = {
    ["rbxassetid://507766666"]=1, ["rbxassetid://507766951"]=1, ["rbxassetid://507766388"]=1,
    ["rbxassetid://507777826"]=1, ["rbxassetid://507767714"]=1, ["rbxassetid://507765000"]=1,
    ["rbxassetid://507767968"]=1, ["rbxassetid://507765644"]=1, ["rbxassetid://507784897"]=1,
    ["rbxassetid://507785072"]=1, ["rbxassetid://507768133"]=1, ["rbxassetid://507768375"]=1,
    ["rbxassetid://507770239"]=1, ["rbxassetid://507770453"]=1, ["rbxassetid://507771019"]=1,
    ["rbxassetid://507771931"]=1,
    ["rbxassetid://180435571"]=1, ["rbxassetid://180435792"]=1, ["rbxassetid://180426354"]=1,
    ["rbxassetid://125750702"]=1, ["rbxassetid://180436148"]=1, ["rbxassetid://180436334"]=1,
}

local state = {active = false, blocked = 0, conns = {}, allowed = {}}

local gui = Instance.new("ScreenGui")
gui.Name = "AntiEmoteGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 996
gui.Parent = PG

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(340, 440)
main.Position = UDim2.fromOffset(workspace.CurrentCamera.ViewportSize.X / 2 - 170, workspace.CurrentCamera.ViewportSize.Y / 2 - 220)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = Color3.fromRGB(255, 255, 255)
mStroke.Thickness = 1.5
mStroke.Transparency = 0.4

local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - main.AbsolutePosition.Y < 50 then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -60, 0, 28)
title.Position = UDim2.fromOffset(15, 8)
title.BackgroundTransparency = 1
title.Text = "🚫 ANTI-EMOTE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left

-- زر عائم لإعادة فتح واجهة حماية الرقصات بعد إخفائها.
local reopenBtn = Instance.new("TextButton")
reopenBtn.Name = "AntiEmoteReopenButton"
reopenBtn.Size = UDim2.fromOffset(48, 48)
reopenBtn.Position = UDim2.new(0, 18, 0.5, -24)
reopenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
reopenBtn.Text = "💃"
reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reopenBtn.Font = Enum.Font.GothamBlack
reopenBtn.TextSize = 22
reopenBtn.Visible = false
reopenBtn.Active = true
reopenBtn.Parent = gui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 14)
local reopenStroke = Instance.new("UIStroke", reopenBtn)
reopenStroke.Color = Color3.fromRGB(255, 255, 255)
reopenStroke.Thickness = 1.5

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.Activated:Connect(function()
    main.Visible = false
    reopenBtn.Visible = true
end)
reopenBtn.Activated:Connect(function()
    main.Visible = true
    reopenBtn.Visible = false
end)

local descL = Instance.new("TextLabel", main)
descL.Size = UDim2.new(1, -30, 0, 40)
descL.Position = UDim2.fromOffset(15, 42)
descL.BackgroundTransparency = 1
descL.Text = "يمنع أي شخص من إجبارك على رقصة\nأو جلوس أو PlatformStand."
descL.TextColor3 = Color3.fromRGB(180, 180, 180)
descL.Font = Enum.Font.Gotham
descL.TextSize = 10
descL.TextXAlignment = Enum.TextXAlignment.Left
descL.TextWrapped = true

local counter = Instance.new("TextLabel", main)
counter.Size = UDim2.new(1, -30, 0, 24)
counter.Position = UDim2.fromOffset(15, 88)
counter.BackgroundTransparency = 1
counter.Text = "BLOCKED: 0"
counter.TextColor3 = Color3.fromRGB(255, 255, 255)
counter.Font = Enum.Font.GothamBlack
counter.TextSize = 14
counter.TextXAlignment = Enum.TextXAlignment.Left

local toggleBtn = Instance.new("TextButton", main)
toggleBtn.Size = UDim2.new(1, -30, 0, 44)
toggleBtn.Position = UDim2.fromOffset(15, 118)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "▶️ تشغيل الحماية"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 13
toggleBtn.AutoButtonColor = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
local tStroke = Instance.new("UIStroke", toggleBtn)
tStroke.Color = Color3.fromRGB(255, 255, 255)
tStroke.Thickness = 1.2
tStroke.Transparency = 0.5

local logBox = Instance.new("ScrollingFrame", main)
logBox.Size = UDim2.new(1, -30, 1, -180)
logBox.Position = UDim2.fromOffset(15, 172)
logBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 2
logBox.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
logBox.CanvasSize = UDim2.new(0, 0, 0, 0)
logBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 6)
local lS = Instance.new("UIStroke", logBox)
lS.Color = Color3.fromRGB(255, 255, 255); lS.Transparency = 0.85; lS.Thickness = 1
Instance.new("UIListLayout", logBox).Padding = UDim.new(0, 2)

local function log(reason)
    state.blocked = state.blocked + 1
    counter.Text = "BLOCKED: " .. state.blocked
    local l = Instance.new("TextLabel", logBox)
    l.Size = UDim2.new(1, -4, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = "  🚫 " .. reason .. "  (" .. os.date("%H:%M:%S") .. ")"
    l.TextColor3 = Color3.fromRGB(255, 200, 200)
    l.Font = Enum.Font.Code
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function setup(char)
    for _, c in ipairs(state.conns) do pcall(function() c:Disconnect() end) end
    state.conns = {}

    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    table.insert(state.conns, hum:GetPropertyChangedSignal("Sit"):Connect(function()
        if state.active and hum.Sit then hum.Sit = false; log("Sit blocked") end
    end))
    table.insert(state.conns, hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if state.active and hum.PlatformStand then hum.PlatformStand = false; log("PlatformStand") end
    end))
    table.insert(state.conns, hum.StateChanged:Connect(function(_, ns)
        if not state.active then return end
        if ns == Enum.HumanoidStateType.Sitting or ns == Enum.HumanoidStateType.PlatformStanding then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end))

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    for _, t in pairs(animator:GetPlayingAnimationTracks()) do
        local a = t.Animation
        if a and a.AnimationId and a.AnimationId ~= "" then state.allowed[a.AnimationId] = true end
    end

    table.insert(state.conns, animator.AnimationPlayed:Connect(function(track)
        if not state.active then return end
        local a = track.Animation
        if not a then return end
        local id = a.AnimationId
        if not id or id == "" then return end
        if WL[id] or state.allowed[id] then return end
        pcall(function()
            track:AdjustSpeed(0)
            track:AdjustWeight(0, 0)
            track:Stop(0)
        end)
        task.defer(function() pcall(function() track:Destroy() end) end)
        log("Anim blocked")
    end))
end

toggleBtn.Activated:Connect(function()
    state.active = not state.active
    if state.active then
        toggleBtn.Text = "⏹️ إيقاف الحماية"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        tStroke.Color = Color3.fromRGB(0, 255, 100)
        tStroke.Transparency = 0.3
        if LP.Character then task.spawn(function() setup(LP.Character) end) end
    else
        toggleBtn.Text = "▶️ تشغيل الحماية"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tStroke.Color = Color3.fromRGB(255, 255, 255)
        tStroke.Transparency = 0.5
        for _, c in ipairs(state.conns) do pcall(function() c:Disconnect() end) end
        state.conns = {}
    end
end)

LP.CharacterAdded:Connect(function(char)
    if state.active then task.spawn(function() setup(char) end) end
end)

print("[Anti-Emote] Loaded ✓")
]====]

local danceProtectionBtn = mkBtn(pageProtections, "💃 حماية رقصات", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 92), function()
    if type(loadstring) ~= "function" then
        warn("[TRO] loadstring غير متاح لتشغيل حماية الرقصات.")
        return
    end
    local runDanceProtection, compileError = loadstring(danceProtectionSource)
    if not runDanceProtection then
        warn("[TRO] تعذر تحميل حماية الرقصات: " .. tostring(compileError))
        return
    end
    local ok, runError = pcall(runDanceProtection)
    if not ok then
        warn("[TRO] خطأ أثناء تشغيل حماية الرقصات: " .. tostring(runError))
    end
end)
danceProtectionBtn.BackgroundColor3 = C_BTN_ACTIVE


-- ========== TOOLS PAGE ==========
local toolsHeader = Instance.new("TextLabel", pageTools)
toolsHeader.Position = UDim2.fromOffset(0, 4)
toolsHeader.Size = UDim2.new(1, 0, 0, 28)
toolsHeader.BackgroundTransparency = 1
toolsHeader.Text = "🧰 قسم الأدوات"
toolsHeader.TextColor3 = C_TEXT
toolsHeader.Font = Enum.Font.GothamBold
toolsHeader.TextSize = 14
toolsHeader.TextXAlignment = Enum.TextXAlignment.Left

-- Original user-provided tool scripts embedded as-is.
local autoClickerSource = [====[
-- ============================================================
-- Auto Clicker — نقرة تلقائية في نقاط
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("TRO_AutoClicker")
if old then old:Destroy() end

local active = false
local repeatMode = true
local delay = 0.05
local targets = {}

local gui = Instance.new("ScreenGui")
gui.Name = "TRO_AutoClicker"
gui.ResetOnSpawn = false
gui.DisplayOrder = 997
gui.Parent = PG

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(360, 340)
main.Position = UDim2.fromOffset(workspace.CurrentCamera.ViewportSize.X / 2 - 180, workspace.CurrentCamera.ViewportSize.Y / 2 - 170)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = Color3.fromRGB(255, 255, 255)
mStroke.Thickness = 1.5
mStroke.Transparency = 0.4

local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - main.AbsolutePosition.Y < 50 then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -60, 0, 28)
title.Position = UDim2.fromOffset(15, 8)
title.BackgroundTransparency = 1
title.Text = "🖱 AUTO CLICKER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.Activated:Connect(function() main.Visible = false end)

-- أيقونة عائمة لفتح وإخفاء واجهة الأوتو كلكر.
local toggleIcon = Instance.new("TextButton", gui)
toggleIcon.Name = "TRO_AutoClicker_ToggleIcon"
toggleIcon.Size = UDim2.fromOffset(48, 48)
toggleIcon.Position = UDim2.new(0, 18, 0.55, 0)
toggleIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleIcon.Text = "🖱️"
toggleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleIcon.Font = Enum.Font.GothamBlack
toggleIcon.TextSize = 22
toggleIcon.AutoButtonColor = true
toggleIcon.Active = true
toggleIcon.ZIndex = 20
Instance.new("UICorner", toggleIcon).CornerRadius = UDim.new(1, 0)
local toggleStroke = Instance.new("UIStroke", toggleIcon)
toggleStroke.Color = Color3.fromRGB(255, 255, 255)
toggleStroke.Thickness = 1.5
toggleIcon.Activated:Connect(function() main.Visible = not main.Visible end)

local function mkBtn(text, x, y, w, h)
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(w or 0.44, 0, 0, h or 38)
    b.Position = UDim2.fromOffset(x, y)
    b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(255, 255, 255); s.Thickness = 1; s.Transparency = 0.7
    return b
end

local createBtn = mkBtn("+ CREATE", 15, 55)
local startBtn = mkBtn("START", 200, 55)
local clearBtn = mkBtn("CLEAR", 15, 100, 0.44, 30)
local repBtn = mkBtn("REPEAT: ON", 200, 100, 0.44, 30)
local speedBtn = mkBtn("SPEED: NORM", 15, 138, 0.44, 30)

local targetLbl = Instance.new("TextLabel", main)
targetLbl.Size = UDim2.new(0.44, 0, 0, 30)
targetLbl.Position = UDim2.fromOffset(200, 138)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "TARGETS: 0"
targetLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 11
targetLbl.TextXAlignment = Enum.TextXAlignment.Left

local infoLbl = Instance.new("TextLabel", main)
infoLbl.Size = UDim2.new(1, -30, 0, 100)
infoLbl.Position = UDim2.fromOffset(15, 180)
infoLbl.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
infoLbl.BorderSizePixel = 0
infoLbl.Text = "> System ready.\n> اضغط CREATE لإضافة نقطة."
infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLbl.TextXAlignment = Enum.TextXAlignment.Left
infoLbl.TextYAlignment = Enum.TextYAlignment.Top
infoLbl.Font = Enum.Font.Code
infoLbl.TextSize = 9
infoLbl.TextWrapped = true
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 6)
local iS = Instance.new("UIStroke", infoLbl)
iS.Color = Color3.fromRGB(255, 255, 255); iS.Transparency = 0.85; iS.Thickness = 1

createBtn.Activated:Connect(function()
    local marker = Instance.new("Frame", gui)
    marker.Size = UDim2.fromOffset(44, 44)
    marker.Position = UDim2.fromOffset(workspace.CurrentCamera.ViewportSize.X/2 - 22, workspace.CurrentCamera.ViewportSize.Y/2 - 22)
    marker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    marker.BackgroundTransparency = 0.25
    marker.BorderSizePixel = 2
    marker.BorderColor3 = Color3.fromRGB(255, 255, 255)
    marker.ZIndex = 999
    Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", marker)
    dot.Size = UDim2.fromOffset(10, 10)
    dot.Position = UDim2.new(0.5, -5, 0.5, -5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.ZIndex = 1000
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local d, p1, p2, cn
    marker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            d = true; p1 = input.Position; p2 = marker.Position
            cn = UserInputService.InputChanged:Connect(function(i)
                if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local delta = i.Position - p1
                    marker.Position = UDim2.fromOffset(p2.X.Offset + delta.X, p2.Y.Offset + delta.Y)
                end
            end)
        end
    end)
    marker.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            d = false
            if cn then cn:Disconnect() end
        end
    end)

    table.insert(targets, {marker = marker})
    targetLbl.Text = "TARGETS: " .. #targets
end)

startBtn.Activated:Connect(function()
    if #targets == 0 then
        infoLbl.Text = "> ❌ ما فيه نقاط! اضغط CREATE\n> " .. infoLbl.Text
        return
    end
    active = not active
    startBtn.Text = active and "STOP" or "START"
    startBtn.BackgroundColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(25, 25, 25)
    startBtn.TextColor3 = active and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end)

clearBtn.Activated:Connect(function()
    for _, v in ipairs(targets) do pcall(function() v.marker:Destroy() end) end
    targets = {}
    targetLbl.Text = "TARGETS: 0"
    active = false
    startBtn.Text = "START"
    startBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

repBtn.Activated:Connect(function()
    repeatMode = not repeatMode
    repBtn.Text = "REPEAT: " .. (repeatMode and "ON" or "OFF")
end)

local speeds = {{"SLOW", 0.2}, {"NORM", 0.05}, {"FAST", 0.01}}
local si = 2
speedBtn.Activated:Connect(function()
    si = si % #speeds + 1
    delay = speeds[si][2]
    speedBtn.Text = "SPEED: " .. speeds[si][1]
end)

task.spawn(function()
    while gui.Parent do
        if active and #targets > 0 then
            for _, v in ipairs(targets) do
                if v.marker and v.marker.Parent then
                    local pos = v.marker.AbsolutePosition + v.marker.AbsoluteSize / 2
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    task.wait(0.02)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                    task.wait(delay)
                end
            end
            if not repeatMode then
                active = false
                startBtn.Text = "START"
                startBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        task.wait(0.05)
    end
end)

print("[AutoClicker] Loaded ✓")
]====]

local fpsBoosterSource = [====[
-- ============================================================
-- FPS Booster v2 — Reversible
-- ============================================================
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("FPSBoost_GUI")
if old then old:Destroy() end

local saved = {}
local active = false
local busy = false
local connect = nil

local function resetSaved()
    saved = {parts = {}, meshParts = {}, decals = {}, particles = {}, postEffects = {},
             textLabels = {}, sky = {}, atmosphere = {}, sounds = {}, lighting = nil, quality = nil}
end
resetSaved()

local function countOptimized()
    local n = 0
    for _ in pairs(saved.parts) do n = n + 1 end
    for _ in pairs(saved.meshParts) do n = n + 1 end
    for _ in pairs(saved.decals) do n = n + 1 end
    for _ in pairs(saved.particles) do n = n + 1 end
    for _ in pairs(saved.postEffects) do n = n + 1 end
    for _ in pairs(saved.sky) do n = n + 1 end
    for _ in pairs(saved.atmosphere) do n = n + 1 end
    for _ in pairs(saved.sounds) do n = n + 1 end
    return n
end

local function process(obj)
    if obj:IsDescendantOf(Players) then return end
    if obj:IsA("Decal") or obj:IsA("Texture") then
        if not saved.decals[obj] then saved.decals[obj] = {transparency = obj.Transparency} end
        pcall(function() obj.Transparency = 1 end)
        return
    end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        if not saved.particles[obj] then saved.particles[obj] = {enabled = obj.Enabled} end
        pcall(function() obj.Enabled = false end)
        return
    end
    if obj:IsA("PostEffect") then
        if not saved.postEffects[obj] then saved.postEffects[obj] = {enabled = obj.Enabled} end
        pcall(function() obj.Enabled = false end)
        return
    end
    if obj:IsA("Sky") then
        if not saved.sky[obj] then saved.sky[obj] = {parent = obj.Parent} end
        pcall(function() obj.Parent = nil end)
        return
    end
    if obj:IsA("Atmosphere") then
        if not saved.atmosphere[obj] then saved.atmosphere[obj] = {parent = obj.Parent} end
        pcall(function() obj.Parent = nil end)
        return
    end
    if obj:IsA("Sound") then
        if not saved.sounds[obj] then saved.sounds[obj] = {volume = obj.Volume} end
        pcall(function() obj.Volume = 0 end)
        return
    end
    if obj:IsA("MeshPart") then
        if not saved.meshParts[obj] then
            saved.meshParts[obj] = {renderFidelity = obj.RenderFidelity, reflectance = obj.Reflectance, material = obj.Material, castShadow = obj.CastShadow}
        end
        pcall(function()
            obj.RenderFidelity = Enum.RenderFidelity.Performance
            obj.Reflectance = 0; obj.Material = Enum.Material.Plastic; obj.CastShadow = false
        end)
        return
    end
    if obj:IsA("BasePart") then
        if not saved.parts[obj] then
            saved.parts[obj] = {castShadow = obj.CastShadow, material = obj.Material, reflectance = obj.Reflectance}
        end
        pcall(function() obj.CastShadow = false; obj.Material = Enum.Material.Plastic; obj.Reflectance = 0 end)
        return
    end
    if obj:IsA("TextLabel") and obj:IsDescendantOf(workspace) then
        if not saved.textLabels[obj] then
            saved.textLabels[obj] = {textScaled = obj.TextScaled, richText = obj.RichText}
        end
        pcall(function() obj.TextScaled = false; obj.RichText = false end)
        return
    end
end

local function start()
    if active then return end
    active = true
    resetSaved()
    saved.lighting = {
        globalShadows = Lighting.GlobalShadows, fogEnd = Lighting.FogEnd,
        shadowSoftness = Lighting.ShadowSoftness, brightness = Lighting.Brightness,
    }
    pcall(function()
        saved.quality = {qualityLevel = settings().Rendering.QualityLevel, meshDetail = settings().Rendering.MeshPartDetailLevel}
    end)
    pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 5000
        Lighting.ShadowSoftness = 0; Lighting.Brightness = 1
    end)
    pcall(function()
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end)
    for _, v in ipairs(workspace:GetDescendants()) do process(v) end
    for _, v in ipairs(Lighting:GetDescendants()) do process(v) end
    if connect then connect:Disconnect() end
    connect = workspace.DescendantAdded:Connect(function(obj)
        if active then task.wait(0.1); if active then process(obj) end end
    end)
end

local function stop()
    if not active then return end
    active = false
    if connect then connect:Disconnect(); connect = nil end
    if saved.lighting then
        pcall(function()
            Lighting.GlobalShadows = saved.lighting.globalShadows
            Lighting.FogEnd = saved.lighting.fogEnd
            Lighting.ShadowSoftness = saved.lighting.shadowSoftness
            Lighting.Brightness = saved.lighting.brightness
        end)
    end
    pcall(function()
        if saved.quality then
            settings().Rendering.QualityLevel = saved.quality.qualityLevel
            settings().Rendering.MeshPartDetailLevel = saved.quality.meshDetail
        end
    end)
    for obj, data in pairs(saved.parts) do
        if obj and obj.Parent then
            pcall(function() obj.CastShadow = data.castShadow; obj.Material = data.material; obj.Reflectance = data.reflectance end)
        end
    end
    for obj, data in pairs(saved.meshParts) do
        if obj and obj.Parent then
            pcall(function() obj.RenderFidelity = data.renderFidelity; obj.Reflectance = data.reflectance; obj.Material = data.material; obj.CastShadow = data.castShadow end)
        end
    end
    for obj, data in pairs(saved.decals) do
        if obj and obj.Parent then pcall(function() obj.Transparency = data.transparency end) end
    end
    for obj, data in pairs(saved.particles) do
        if obj and obj.Parent then pcall(function() obj.Enabled = data.enabled end) end
    end
    for obj, data in pairs(saved.postEffects) do
        if obj and obj.Parent then pcall(function() obj.Enabled = data.enabled end) end
    end
    for obj, data in pairs(saved.textLabels) do
        if obj and obj.Parent then pcall(function() obj.TextScaled = data.textScaled; obj.RichText = data.richText end) end
    end
    for obj, data in pairs(saved.sky) do
        if obj and data.parent then pcall(function() obj.Parent = data.parent end) end
    end
    for obj, data in pairs(saved.atmosphere) do
        if obj and data.parent then pcall(function() obj.Parent = data.parent end) end
    end
    for obj, data in pairs(saved.sounds) do
        if obj and obj.Parent then pcall(function() obj.Volume = data.volume end) end
    end
    resetSaved()
end

local gui = Instance.new("ScreenGui")
gui.Name = "FPSBoost_GUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 998
gui.Parent = PG

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(380, 290)
main.Position = UDim2.fromOffset(workspace.CurrentCamera.ViewportSize.X / 2 - 190, workspace.CurrentCamera.ViewportSize.Y / 2 - 145)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = Color3.fromRGB(255, 255, 255)
mStroke.Thickness = 1.5
mStroke.Transparency = 0.4

local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - main.AbsolutePosition.Y < 50 then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -60, 0, 30)
title.Position = UDim2.fromOffset(15, 8)
title.BackgroundTransparency = 1
title.Text = "⚡ FPS BOOSTER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.Activated:Connect(function() main.Visible = false end)

-- أيقونة عائمة لفتح وإخفاء واجهة تحسين FPS.
local toggleIcon = Instance.new("TextButton", gui)
toggleIcon.Name = "FPSBoost_ToggleIcon"
toggleIcon.Size = UDim2.fromOffset(48, 48)
toggleIcon.Position = UDim2.new(0, 18, 0.65, 0)
toggleIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleIcon.Text = "⚡"
toggleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleIcon.Font = Enum.Font.GothamBlack
toggleIcon.TextSize = 24
toggleIcon.AutoButtonColor = true
toggleIcon.Active = true
toggleIcon.ZIndex = 20
Instance.new("UICorner", toggleIcon).CornerRadius = UDim.new(1, 0)
local toggleStroke = Instance.new("UIStroke", toggleIcon)
toggleStroke.Color = Color3.fromRGB(255, 255, 255)
toggleStroke.Thickness = 1.5
toggleIcon.Activated:Connect(function() main.Visible = not main.Visible end)

local sub = Instance.new("TextLabel", main)
sub.Size = UDim2.new(1, -30, 0, 14)
sub.Position = UDim2.fromOffset(15, 36)
sub.BackgroundTransparency = 1
sub.Text = "REVERSIBLE • SAVE & RESTORE"
sub.TextColor3 = Color3.fromRGB(150, 150, 150)
sub.Font = Enum.Font.Code
sub.TextSize = 9
sub.TextXAlignment = Enum.TextXAlignment.Left

local boostBtn = Instance.new("TextButton", main)
boostBtn.Size = UDim2.new(1, -30, 0, 50)
boostBtn.Position = UDim2.fromOffset(15, 62)
boostBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
boostBtn.Text = "🚀 تشغيل التحسين"
boostBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
boostBtn.Font = Enum.Font.GothamBold
boostBtn.TextSize = 14
boostBtn.AutoButtonColor = false
Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1, -30, 0, 20)
statusLbl.Position = UDim2.fromOffset(15, 122)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "STATUS: STANDBY"
statusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLbl.Font = Enum.Font.Code
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local countLbl = Instance.new("TextLabel", main)
countLbl.Size = UDim2.new(1, -30, 0, 20)
countLbl.Position = UDim2.fromOffset(15, 145)
countLbl.BackgroundTransparency = 1
countLbl.Text = "OPTIMIZED: 0 objects"
countLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
countLbl.Font = Enum.Font.Code
countLbl.TextSize = 10
countLbl.TextXAlignment = Enum.TextXAlignment.Left

local logLbl = Instance.new("TextLabel", main)
logLbl.Size = UDim2.new(1, -30, 0, 100)
logLbl.Position = UDim2.fromOffset(15, 172)
logLbl.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
logLbl.BorderSizePixel = 0
logLbl.Text = "> النظام جاهز.\n> اضغط تشغيل للبدء.\n> اضغط إيقاف للاستعادة."
logLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
logLbl.TextXAlignment = Enum.TextXAlignment.Left
logLbl.TextYAlignment = Enum.TextYAlignment.Top
logLbl.Font = Enum.Font.Code
logLbl.TextSize = 9
logLbl.TextWrapped = true
logLbl.ClipsDescendants = true
Instance.new("UICorner", logLbl).CornerRadius = UDim.new(0, 6)
local lS = Instance.new("UIStroke", logLbl)
lS.Color = Color3.fromRGB(255, 255, 255); lS.Transparency = 0.85; lS.Thickness = 1

boostBtn.Activated:Connect(function()
    if busy then return end
    busy = true
    if not active then
        boostBtn.Text = "⏳ جاري التحسين..."
        boostBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLbl.Text = "> Scanning workspace...\n> Saving original state...\n> Applying..."
        task.spawn(function()
            start()
            local n = countOptimized()
            boostBtn.Text = "⏹ إيقاف واستعادة"
            boostBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            statusLbl.Text = "STATUS: 🟢 ACTIVE"
            countLbl.Text = "OPTIMIZED: " .. n .. " objects"
            logLbl.Text = "> ✅ التحسين مفعل.\n> عدد الكائنات: " .. n .. "\n> اضغط إيقاف للاستعادة."
            busy = false
        end)
    else
        boostBtn.Text = "⏳ جاري الاستعادة..."
        boostBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLbl.Text = "> Restoring...\n> Please wait..."
        task.spawn(function()
            stop()
            boostBtn.Text = "🚀 تشغيل التحسين"
            boostBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            boostBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            statusLbl.Text = "STATUS: STANDBY"
            countLbl.Text = "OPTIMIZED: 0 objects"
            logLbl.Text = "> ✅ تم استعادة كل شيء.\n> جاهز للتحسين مرة أخرى."
            busy = false
        end)
    end
end)

print("[FPS Booster v2] Loaded ✓")
]====]

local chatEncryptionSource = [====[
-- ============================================================
-- TET v7 — تشفير + نجوم + أيقونة عائمة
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Chat = game:GetService("Chat")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- تنظيف
for _, n in ipairs({"TET_GUI", "TET_Icon"}) do
    local o = PG:FindFirstChild(n)
    if o then o:Destroy() end
end

-- ═══════════════════════════════════════════════════════════
-- State
-- ═══════════════════════════════════════════════════════════
local autoEncrypt = false
local bypassAuto = false
local intensity = 2
local workingTarget = nil
local workingMethod = nil
local intercepts = 0
local lastIn = ""
local lastOut = ""
local lastErrors = ""

-- ═══════════════════════════════════════════════════════════
-- Encoder
-- ═══════════════════════════════════════════════════════════
local diacritics = {"\217\142", "\217\144", "\217\143", "\217\146", "\217\145", "\217\139", "\217\141", "\217\140"}
local TATWEEL = "\217\128"

local function hasArabic(text)
    return text and string.find(text, "[\216\217][\128-\191]") ~= nil
end

local function glitchify(text, lvl)
    if not text or text == "" then return text end
    local maxDia = ({1, 2, 2, 3, 4})[lvl] or 2
    local tatChance = ({5, 4, 2, 1, 1})[lvl] or 3
    return (text:gsub("[\216\217][\128-\191]", function(char)
        local fb = string.byte(char, 1)
        local sb = string.byte(char, 2)
        if fb == 217 and sb >= 139 and sb <= 146 then return char end
        if fb == 217 and sb == 128 then return char end
        local out = char
        for i = 1, math.random(1, maxDia) do
            out = out .. diacritics[math.random(1, #diacritics)]
        end
        if math.random(1, tatChance) == 1 then out = out .. TATWEEL end
        return out
    end))
end

-- ═══════════════════════════════════════════════════════════
-- Manual Send
-- ═══════════════════════════════════════════════════════════
local function trySend(text)
    local errors = {}

    if workingMethod and workingTarget then
        local ok = pcall(function()
            if workingMethod == "TextChatService" then
                workingTarget:SendAsync(text)
            elseif workingMethod == "SayMessageRequest" then
                workingTarget:FireServer(text, "All")
            end
        end)
        if ok then return true, workingMethod end
    end

    if LP.Character then
        local head = LP.Character:FindFirstChild("Head")
        if head then
            local ok, err = pcall(function()
                Chat:Chat(head, text, Enum.ChatColor.White)
            end)
            if ok then
                workingMethod = "Chat:Chat"
                workingTarget = nil
                return true, "Chat:Chat"
            end
            table.insert(errors, "Chat:Chat → " .. tostring(err))
        end
    end

    local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if ev then
        local req = ev:FindFirstChild("SayMessageRequest")
        if req then
            local ok, err = pcall(function()
                req:FireServer(text, "All")
            end)
            if ok then
                workingMethod = "SayMessageRequest"
                workingTarget = req
                return true, "SayMessageRequest"
            end
            table.insert(errors, "SayMessageRequest → " .. tostring(err))
        end
    end

    local channels = TextChatService:FindFirstChild("TextChannels")
    if channels then
        local channel = channels:FindFirstChild("RBXGeneral") or channels:GetChildren()[1]
        if channel and channel:IsA("TextChannel") then
            local ok, err = pcall(function()
                channel:SendAsync(text)
            end)
            if ok then
                workingMethod = "TextChatService"
                workingTarget = channel
                return true, "TextChatService"
            end
            table.insert(errors, "TextChatService → " .. tostring(err))
        end
    end

    lastErrors = table.concat(errors, "\n")
    return false, nil
end

-- ═══════════════════════════════════════════════════════════
-- Hook
-- ═══════════════════════════════════════════════════════════
local hookInstalled = false
local hookOldNamecall = nil

local function installHook()
    if hookInstalled then return true end
    if not (hookmetamethod and newcclosure and getnamecallmethod) then return false end

    local ok = pcall(function()
        local mt = getrawmetatable(game)
        hookOldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if autoEncrypt and not bypassAuto then
                local shouldEncrypt = false
                if workingTarget and self == workingTarget then
                    shouldEncrypt = true
                elseif not workingTarget then
                    local name = ""
                    pcall(function() name = string.lower(tostring(self.Name or "")) end)
                    if method == "FireServer" or method == "InvokeServer" or method == "SendAsync" then
                        if name:find("say") or name:find("chat") or name:find("message") or name:find("send") then
                            shouldEncrypt = true
                        end
                    end
                end

                if shouldEncrypt and type(args[1]) == "string" and hasArabic(args[1]) then
                    local orig = args[1]
                    args[1] = glitchify(orig, intensity)
                    intercepts = intercepts + 1
                    lastIn = orig
                    lastOut = args[1]
                    return hookOldNamecall(self, table.unpack(args))
                end
            end

            return hookOldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    if ok then hookInstalled = true end
    return ok
end

installHook()

-- ═══════════════════════════════════════════════════════════
-- GUI (مخفي افتراضياً)
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "TET_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = PG

local vp = workspace.CurrentCamera.ViewportSize
local MAIN_W, MAIN_H = 430, 660
local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
main.Position = UDim2.fromOffset(vp.X/2 - MAIN_W/2, vp.Y/2 - MAIN_H/2)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

local mStroke = Instance.new("UIStroke", main)
mStroke.Color = Color3.fromRGB(255, 255, 255)
mStroke.Thickness = 1.5
mStroke.Transparency = 0.4

-- ✨ النجوم
local starLayer = Instance.new("Frame", main)
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.ZIndex = 1
starLayer.ClipsDescendants = true

local rng = Random.new()
local stars = {}
for i = 1, 70 do
    local s = Instance.new("Frame", starLayer)
    s.Size = UDim2.fromOffset(rng:NextInteger(1, 3), rng:NextInteger(1, 3))
    s.Position = UDim2.fromScale(rng:NextNumber(0.02, 0.98), rng:NextNumber(0.02, 0.98))
    s.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    s.BackgroundTransparency = rng:NextNumber(0.2, 0.7)
    s.BorderSizePixel = 0
    s.ZIndex = 1
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
    table.insert(stars, {
        frame = s,
        base = s.BackgroundTransparency,
        phase = rng:NextNumber(0, math.pi * 2),
        speed = rng:NextNumber(0.7, 2.2),
        amp = rng:NextNumber(0.25, 0.55),
    })
end

-- 🌠 شهب
local shooting = {}
for i = 1, 3 do
    local s = Instance.new("Frame", starLayer)
    s.Size = UDim2.fromOffset(60, 1.5)
    s.Position = UDim2.fromScale(1.15, 0.2)
    s.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.Rotation = 20
    s.ZIndex = 1
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
    local grad = Instance.new("UIGradient", s)
    grad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(120,120,140))
    grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
    table.insert(shooting, {frame = s, delay = (i - 1) * 4})
end

-- Drag
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y - main.AbsolutePosition.Y < 55 then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
header.ZIndex = 5
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
local hFill = Instance.new("Frame", header)
hFill.Size = UDim2.new(1, 0, 0, 27)
hFill.Position = UDim2.new(0, 0, 1, -27)
hFill.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
hFill.BackgroundTransparency = 0.3
hFill.BorderSizePixel = 0
hFill.ZIndex = 5

local headerIcon = Instance.new("TextLabel", header)
headerIcon.Size = UDim2.fromOffset(30, 30)
headerIcon.Position = UDim2.fromOffset(15, 12)
headerIcon.BackgroundTransparency = 1
headerIcon.Text = "✦"
headerIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
headerIcon.Font = Enum.Font.GothamBlack
headerIcon.TextSize = 20
headerIcon.ZIndex = 6

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -100, 0, 22)
title.Position = UDim2.fromOffset(48, 8)
title.BackgroundTransparency = 1
title.Text = "TET — تشفير الكلام"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 6

local subtitle = Instance.new("TextLabel", header)
subtitle.Size = UDim2.new(1, -100, 0, 14)
subtitle.Position = UDim2.fromOffset(48, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "STARRY EDITION"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 8
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 6

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -42, 0, 11)
closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 6
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
local cStroke = Instance.new("UIStroke", closeBtn)
cStroke.Color = Color3.fromRGB(255, 255, 255)
cStroke.Thickness = 1
cStroke.Transparency = 0.6

-- Status
local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1, -30, 0, 42)
statusLbl.Position = UDim2.fromOffset(15, 65)
statusLbl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statusLbl.BackgroundTransparency = 0.15
statusLbl.Text = "① اضغط (اختبار الإرسال) أولاً"
statusLbl.TextColor3 = Color3.fromRGB(255, 220, 150)
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 11
statusLbl.TextWrapped = true
statusLbl.ZIndex = 3
Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 8)
local stS = Instance.new("UIStroke", statusLbl)
stS.Color = Color3.fromRGB(255, 255, 255)
stS.Thickness = 1
stS.Transparency = 0.8

-- Test
local testBtn = Instance.new("TextButton", main)
testBtn.Size = UDim2.new(1, -30, 0, 46)
testBtn.Position = UDim2.fromOffset(15, 115)
testBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
testBtn.Text = "🧪 اختبار الإرسال — يجرب كل الطرق"
testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testBtn.Font = Enum.Font.GothamBold
testBtn.TextSize = 12
testBtn.AutoButtonColor = false
testBtn.ZIndex = 3
Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 8)
local tS = Instance.new("UIStroke", testBtn)
tS.Color = Color3.fromRGB(255, 255, 255)
tS.Thickness = 1.2
tS.Transparency = 0.5

testBtn.Activated:Connect(function()
    local testText = "هلا " .. math.random(100, 999)
    bypassAuto = true
    local ok, method = trySend(glitchify(testText, 1))
    bypassAuto = false

    if ok then
        testBtn.Text = "✅ نجح: " .. method
        testBtn.BackgroundColor3 = Color3.fromRGB(20, 150, 60)
        statusLbl.Text = "✅ الطريقة الشغالة: " .. method .. "\nتقدر تفعّل التلقائي الحين"
        statusLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        testBtn.Text = "❌ فشلت كل الطرق"
        testBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusLbl.Text = "❌ لا توجد طريقة إرسال متاحة"
        statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    task.delay(2.5, function()
        testBtn.Text = "🧪 اختبار الإرسال — يجرب كل الطرق"
        testBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 200)
    end)
end)

-- Auto
local autoBtn = Instance.new("TextButton", main)
autoBtn.Size = UDim2.new(1, -30, 0, 52)
autoBtn.Position = UDim2.fromOffset(15, 168)
autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
autoBtn.Text = "⚡ تفعيل التلقائي (بعد الاختبار)"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Font = Enum.Font.GothamBlack
autoBtn.TextSize = 13
autoBtn.AutoButtonColor = false
autoBtn.ZIndex = 3
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 8)
local aS = Instance.new("UIStroke", autoBtn)
aS.Color = Color3.fromRGB(255, 255, 255)
aS.Thickness = 1.2
aS.Transparency = 0.5

autoBtn.Activated:Connect(function()
    if not workingMethod then
        autoBtn.Text = "⚠️ اضغط اختبار الإرسال أولاً"
        autoBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
        task.delay(2, function()
            autoBtn.Text = "⚡ تفعيل التلقائي (بعد الاختبار)"
            autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end)
        return
    end
    if not hookInstalled then
        autoBtn.Text = "❌ Hook غير مدعوم بهذا الـ executor"
        autoBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
        return
    end

    autoEncrypt = not autoEncrypt
    if autoEncrypt then
        autoBtn.Text = "✅ التلقائي يعمل — اكتب بالشات"
        autoBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        autoBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        aS.Color = Color3.fromRGB(0, 255, 100)
        aS.Transparency = 0.2
    else
        autoBtn.Text = "⚡ تفعيل التلقائي"
        autoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        aS.Color = Color3.fromRGB(255, 255, 255)
        aS.Transparency = 0.5
    end
end)

-- Diagnostic
local diagBox = Instance.new("Frame", main)
diagBox.Size = UDim2.new(1, -30, 0, 200)
diagBox.Position = UDim2.fromOffset(15, 228)
diagBox.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
diagBox.BackgroundTransparency = 0.15
diagBox.BorderSizePixel = 0
diagBox.ZIndex = 3
Instance.new("UICorner", diagBox).CornerRadius = UDim.new(0, 8)
local dS = Instance.new("UIStroke", diagBox)
dS.Color = Color3.fromRGB(255, 255, 255)
dS.Thickness = 1
dS.Transparency = 0.75

local diagScroll = Instance.new("ScrollingFrame", diagBox)
diagScroll.Size = UDim2.new(1, -8, 1, -8)
diagScroll.Position = UDim2.fromOffset(4, 4)
diagScroll.BackgroundTransparency = 1
diagScroll.BorderSizePixel = 0
diagScroll.ScrollBarThickness = 3
diagScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
diagScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
diagScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
diagScroll.ZIndex = 4

local diagText = Instance.new("TextLabel", diagScroll)
diagText.Size = UDim2.new(1, -4, 0, 0)
diagText.BackgroundTransparency = 1
diagText.TextColor3 = Color3.fromRGB(200, 200, 200)
diagText.Font = Enum.Font.Code
diagText.TextSize = 10
diagText.TextXAlignment = Enum.TextXAlignment.Left
diagText.TextYAlignment = Enum.TextYAlignment.Top
diagText.TextWrapped = true
diagText.AutomaticSize = Enum.AutomaticSize.Y
diagText.ZIndex = 5

local function updateDiag()
    local lines = {}
    table.insert(lines, "═══ الحالة ═══")
    table.insert(lines, "Hook: " .. (hookInstalled and "✅" or "❌"))
    table.insert(lines, "الطريقة: " .. (workingMethod or "غير معروفة"))
    table.insert(lines, "تلقائي: " .. (autoEncrypt and "ON" or "OFF"))
    table.insert(lines, "اعتراضات: " .. intercepts)

    if lastIn ~= "" then
        table.insert(lines, "")
        table.insert(lines, "═══ آخر تشفير ═══")
        table.insert(lines, "دخل: " .. lastIn)
        table.insert(lines, "خرج: " .. lastOut)
    end

    if lastErrors ~= "" then
        table.insert(lines, "")
        table.insert(lines, "═══ أخطاء ═══")
        table.insert(lines, lastErrors)
    end

    diagText.Text = table.concat(lines, "\n")
end

task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        updateDiag()
    end
end)

-- Input
local input = Instance.new("TextBox", main)
input.Size = UDim2.new(1, -30, 0, 45)
input.Position = UDim2.fromOffset(15, 436)
input.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
input.BackgroundTransparency = 0.1
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.PlaceholderText = "اكتب نص عربي..."
input.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
input.Text = "هلو"
input.Font = Enum.Font.Gotham
input.TextSize = 13
input.ClearTextOnFocus = false
input.BorderSizePixel = 0
input.ZIndex = 3
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)
local iS = Instance.new("UIStroke", input)
iS.Color = Color3.fromRGB(255, 255, 255)
iS.Thickness = 1
iS.Transparency = 0.8

-- Preview
local prevBox = Instance.new("Frame", main)
prevBox.Size = UDim2.new(1, -30, 0, 46)
prevBox.Position = UDim2.fromOffset(15, 488)
prevBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
prevBox.BackgroundTransparency = 0.15
prevBox.BorderSizePixel = 0
prevBox.ZIndex = 3
Instance.new("UICorner", prevBox).CornerRadius = UDim.new(0, 8)
local pS = Instance.new("UIStroke", prevBox)
pS.Color = Color3.fromRGB(255, 255, 255)
pS.Thickness = 1
pS.Transparency = 0.85

local prevText = Instance.new("TextLabel", prevBox)
prevText.Size = UDim2.new(1, -16, 1, -8)
prevText.Position = UDim2.fromOffset(8, 4)
prevText.BackgroundTransparency = 1
prevText.TextColor3 = Color3.fromRGB(255, 255, 255)
prevText.TextSize = 12
prevText.Font = Enum.Font.Gotham
prevText.TextWrapped = true
prevText.TextXAlignment = Enum.TextXAlignment.Left
prevText.ZIndex = 4

local function updatePreview()
    local src = input.Text == "" and "..." or input.Text
    if hasArabic(src) then
        prevText.Text = glitchify(src, intensity)
        prevText.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        prevText.Text = src .. "  (ما فيه عربي)"
        prevText.TextColor3 = Color3.fromRGB(200, 150, 100)
    end
end
input:GetPropertyChangedSignal("Text"):Connect(updatePreview)

-- Send + Copy
local sendBtn = Instance.new("TextButton", main)
sendBtn.Size = UDim2.new(0.62, -15, 0, 42)
sendBtn.Position = UDim2.fromOffset(15, 540)
sendBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.Text = "📤 إرسال يدوي"
sendBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
sendBtn.Font = Enum.Font.GothamBlack
sendBtn.TextSize = 12
sendBtn.AutoButtonColor = false
sendBtn.ZIndex = 3
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 8)

sendBtn.Activated:Connect(function()
    if input.Text == "" then return end
    if not hasArabic(input.Text) then
        sendBtn.Text = "⚠️ ما فيه عربي"
        task.delay(1.5, function() sendBtn.Text = "📤 إرسال يدوي" end)
        return
    end
    bypassAuto = true
    local ok, method = trySend(glitchify(input.Text, intensity))
    bypassAuto = false
    if ok then
        sendBtn.Text = "✓ " .. method
        sendBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    else
        sendBtn.Text = "❌ فشل"
        sendBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    end
    task.delay(2, function()
        sendBtn.Text = "📤 إرسال يدوي"
        sendBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)
end)

local copyBtn = Instance.new("TextButton", main)
copyBtn.Size = UDim2.new(0.35, -15, 0, 42)
copyBtn.Position = UDim2.new(0.65, 0, 0, 540)
copyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
copyBtn.Text = "📋 نسخ"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.AutoButtonColor = false
copyBtn.ZIndex = 3
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
local cbS = Instance.new("UIStroke", copyBtn)
cbS.Color = Color3.fromRGB(255, 255, 255)
cbS.Thickness = 1
cbS.Transparency = 0.6

copyBtn.Activated:Connect(function()
    if input.Text == "" then return end
    pcall(function() setclipboard(glitchify(input.Text, intensity)) end)
    copyBtn.Text = "✓ نُسخ"
    task.delay(1.5, function() copyBtn.Text = "📋 نسخ" end)
end)

-- Intensity
local names = {"خفيف", "متوسط", "ثقيل", "مجنون", "خارق"}
local intBtns = {}
for i = 1, 5 do
    local b = Instance.new("TextButton", main)
    b.Size = UDim2.new(0.18, -6, 0, 32)
    b.Position = UDim2.fromOffset(15 + (i-1)*0.18*400, 590)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = names[i]
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.AutoButtonColor = false
    b.ZIndex = 3
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke", b)
    bs.Color = Color3.fromRGB(255, 255, 255)
    bs.Transparency = 0.7
    intBtns[i] = b
    b.Activated:Connect(function()
        intensity = i
        for j, btn in ipairs(intBtns) do
            btn.BackgroundColor3 = (j == i) and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,20,20)
            btn.TextColor3 = (j == i) and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)
        end
        updatePreview()
    end)
end
intBtns[2].BackgroundColor3 = Color3.fromRGB(255,255,255)
intBtns[2].TextColor3 = Color3.fromRGB(0,0,0)

local hint = Instance.new("TextLabel", main)
hint.Size = UDim2.new(1, -30, 0, 24)
hint.Position = UDim2.fromOffset(15, 628)
hint.BackgroundTransparency = 1
hint.Text = "① اختبار  •  ② تفعيل  •  ③ اكتب بالشات"
hint.TextColor3 = Color3.fromRGB(150, 150, 150)
hint.Font = Enum.Font.Gotham
hint.TextSize = 9
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.ZIndex = 3

-- ═══════════════════════════════════════════════════════════
-- 🌟 الأيقونة العائمة
-- ═══════════════════════════════════════════════════════════
local iconGui = Instance.new("ScreenGui")
iconGui.Name = "TET_Icon"
iconGui.ResetOnSpawn = false
iconGui.IgnoreGuiInset = true
iconGui.DisplayOrder = 1000
iconGui.Parent = PG

local ICON_SIZE = 64
local iconBtn = Instance.new("TextButton", iconGui)
iconBtn.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
iconBtn.Position = UDim2.fromOffset(20, vp.Y * 0.4)
iconBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconBtn.Text = "TET"
iconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
iconBtn.Font = Enum.Font.GothamBlack
iconBtn.TextSize = 16
iconBtn.AutoButtonColor = false
iconBtn.Active = true
Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(1, 0)

local iconStroke = Instance.new("UIStroke", iconBtn)
iconStroke.Color = Color3.fromRGB(255, 255, 255)
iconStroke.Thickness = 2
iconStroke.Transparency = 0.1

-- هالة داخلية
local iconGlow = Instance.new("Frame", iconBtn)
iconGlow.Size = UDim2.new(1, -10, 1, -10)
iconGlow.Position = UDim2.new(0, 5, 0, 5)
iconGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
iconGlow.BackgroundTransparency = 0.92
iconGlow.BorderSizePixel = 0
iconGlow.ZIndex = 0
Instance.new("UICorner", iconGlow).CornerRadius = UDim.new(1, 0)

-- نبض على الحدود
task.spawn(function()
    while iconGui.Parent do
        TweenService:Create(iconStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 2.8, Transparency = 0.35}):Play()
        TweenService:Create(iconGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.85}):Play()
        task.wait(1.2)
        if not iconGui.Parent then break end
        TweenService:Create(iconStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Thickness = 1.6, Transparency = 0.05}):Play()
        TweenService:Create(iconGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.95}):Play()
        task.wait(1.2)
    end
end)

-- نقطة حالة صغيرة
local statusDot = Instance.new("Frame", iconBtn)
statusDot.Size = UDim2.fromOffset(12, 12)
statusDot.Position = UDim2.new(1, -12, 0, 4)
statusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 5
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
local dotStroke = Instance.new("UIStroke", statusDot)
dotStroke.Color = Color3.fromRGB(0, 0, 0)
dotStroke.Thickness = 2

-- سحب الأيقونة
local iconDragging, iconMoved, iconStartPos, iconStartInput = false, false, nil, nil
iconBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconMoved = false
        iconStartInput = input.Position
        iconStartPos = iconBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - iconStartInput
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then iconMoved = true end
        if iconMoved then
            iconBtn.Position = UDim2.fromOffset(iconStartPos.X.Offset + d.X, iconStartPos.Y.Offset + d.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if iconDragging and not iconMoved then
            -- ضغطة = فتح/إغلاق
            if main.Visible then
                TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Size = UDim2.fromOffset(0, 0),
                }):Play()
                task.delay(0.22, function() main.Visible = false end)
            else
                main.Visible = true
                main.Size = UDim2.fromOffset(20, 20)
                main.Position = UDim2.fromOffset(vp.X * 0.5 - 10, vp.Y * 0.5 - 10)
                TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(MAIN_W, MAIN_H),
                    Position = UDim2.fromOffset(vp.X * 0.5 - MAIN_W/2, vp.Y * 0.5 - MAIN_H/2),
                }):Play()
            end
        end
        iconDragging = false
    end
end)

-- Hover
iconBtn.MouseEnter:Connect(function()
    TweenService:Create(iconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
end)
iconBtn.MouseLeave:Connect(function()
    TweenService:Create(iconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
end)

-- زر إغلاق النافذة
closeBtn.Activated:Connect(function()
    TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0),
    }):Play()
    task.delay(0.22, function() main.Visible = false end)
end)

-- تحديث نقطة الحالة كل 0.5 ثانية
task.spawn(function()
    while iconGui.Parent do
        task.wait(0.5)
        if statusDot.Parent then
            if autoEncrypt then
                statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            elseif workingMethod then
                statusDot.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
            else
                statusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- Animations
-- ═══════════════════════════════════════════════════════════
local t0 = os.clock()
RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    local t = os.clock() - t0

    for _, s in ipairs(stars) do
        if s.frame.Parent then
            local new = s.base + math.sin(t * s.speed + s.phase) * s.amp
            s.frame.BackgroundTransparency = math.clamp(new, 0, 1)
        end
    end

    for _, ss in ipairs(shooting) do
        if ss.frame.Parent then
            local cyc = (t + ss.delay) % 14
            if cyc < 1.6 then
                local p = cyc / 1.6
                ss.frame.Position = UDim2.fromScale(1.15 - p * 1.3, 0.05 + p * 0.9)
                ss.frame.BackgroundTransparency = math.sin(p * math.pi) * 0.3
            else
                ss.frame.BackgroundTransparency = 1
            end
        end
    end

    mStroke.Transparency = 0.4 + math.sin(t * 1.5) * 0.15
end)

updatePreview()
updateDiag()
print("[TET v7] Loaded — اضغط TET")
]====]

local function runToolSource(source, label)
    if type(loadstring) ~= "function" then
        warn("[TRO] loadstring غير متاح لتشغيل " .. label)
        notify("TRO - أدوات", "المنفّذ لا يدعم loadstring لتشغيل " .. label, 5)
        return
    end
    local fn, compileError = loadstring(source)
    if not fn then
        warn("[TRO] تعذر تحميل " .. label .. ": " .. tostring(compileError))
        notify("TRO - أدوات", "تعذر تحميل " .. label, 4)
        return
    end
    local ok, runError = pcall(fn)
    if not ok then
        warn("[TRO] خطأ أثناء تشغيل " .. label .. ": " .. tostring(runError))
        notify("TRO - أدوات", "حدث خطأ أثناء تشغيل " .. label, 4)
    end
end

local autoClickerBtn = mkBtn(pageTools, "🖱️ أوتو كلكر", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 42), function()
    runToolSource(autoClickerSource, "أوتو كلكر")
end)
autoClickerBtn.BackgroundColor3 = C_BTN_ACTIVE

local fpsBoosterBtn = mkBtn(pageTools, "⚡ TRO FPS V2", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 92), function()
    runToolSource(fpsBoosterSource, "TRO FPS V2")
end)
fpsBoosterBtn.BackgroundColor3 = C_BTN_ACTIVE

local chatEncryptionBtn = mkBtn(pageTools, "🔤 تشفير كلام", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 142), function()
    -- أوقف مضاد الكلبشة تلقائياً حتى لا يتداخل مع أداة تشفير الكلام.
    AC.enabled = false
    if acToggleBtn then
        acToggleBtn.Text = "🔴 الحماية معطلة"
        acToggleBtn.BackgroundColor3 = C_BTN_IDLE
    end
    acLog("⛔ OFF — تعطيل تلقائي لتشغيل تشفير الكلام")
    runToolSource(chatEncryptionSource, "تشفير كلام")
end)
chatEncryptionBtn.BackgroundColor3 = C_BTN_ACTIVE

local toolsNote = Instance.new("TextLabel", pageTools)
toolsNote.Position = UDim2.fromOffset(2, 198)
toolsNote.Size = UDim2.new(1, -4, 0, 46)
toolsNote.BackgroundTransparency = 1
toolsNote.Text = "ملاحظة: تشفير الكلام يحتاج تضغط «اختبار الإرسال — يجرب كل الطرق» أولاً، ومضاد الكلبشة يتم إيقافه تلقائياً عند فتح الأداة."
toolsNote.TextColor3 = C_TEXT_DIM
toolsNote.Font = Enum.Font.Gotham
toolsNote.TextSize = 10
toolsNote.TextWrapped = true
toolsNote.TextXAlignment = Enum.TextXAlignment.Left
toolsNote.TextYAlignment = Enum.TextYAlignment.Top

-- خط تحت الملاحظة للتأكيد البصري.
local toolsNoteUnderline = Instance.new("Frame", pageTools)
toolsNoteUnderline.Position = UDim2.fromOffset(0, 247)
toolsNoteUnderline.Size = UDim2.new(1, 0, 0, 1)
toolsNoteUnderline.BackgroundColor3 = C_STROKE_HI
toolsNoteUnderline.BorderSizePixel = 0

pageTools.CanvasSize = UDim2.new(0, 0, 0, 275)

task.spawn(function()
    while pageAntis.Parent do
        task.wait(0.4)
        if pageAntis.Visible then
            acCounter.Text = "Sit: " .. AC.blockedSit .. " | PS: " .. AC.blockedPS .. " | CF: " .. AC.blockedCF .. " | W: " .. AC.blockedW
            if #AC.logs > 0 then acLogBox.Text = table.concat(AC.logs, "\n") end
            dgStatus.Text = "المراوغة: " .. Dg.count .. " | Auto: " .. (Dg.auto and "ON" or "OFF")
            afkStatus.Text = "Anti-AFK: " .. (AFK.enabled and "ON" or "OFF")
        end
    end
end)

-- ========== HEADER ==========
local title = Instance.new("TextLabel", root)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 20)
title.Size = UDim2.new(1, -75, 0, 28)
title.Font = Enum.Font.GothamMedium
title.Text = "TRO"
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(235, 235, 242)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 10

local closeBtn = Instance.new("TextButton", root)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -18, 0, 17)
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
closeBtn.ZIndex = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
bindClick(closeBtn, function() gui.Enabled = false end, "Close")

-- ============================================================
-- 🖱️ HEAVY DRAG
-- ============================================================
local dragBar = Instance.new("TextButton", root)
dragBar.BackgroundTransparency = 1
dragBar.Text = ""
dragBar.AutoButtonColor = false
dragBar.Size = UDim2.new(1, -95, 0, 55)
dragBar.ZIndex = 5

local dragActive = false
local dragStartPos = nil
local dragTargetPos = nil
local dragMouseStart = nil

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = true
        dragMouseStart = input.Position
        dragStartPos = root.Position
        dragTargetPos = root.Position
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragActive = false end
end)

UIS.InputChanged:Connect(function(input)
    if dragActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragMouseStart
        dragTargetPos = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + d.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + d.Y
        )
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not dragTargetPos then return end
    local cur = root.Position
    local t = math.clamp(dt * 12, 0, 1)
    local newX = cur.X.Offset + (dragTargetPos.X.Offset - cur.X.Offset) * t
    local newY = cur.Y.Offset + (dragTargetPos.Y.Offset - cur.Y.Offset) * t
    root.Position = UDim2.new(cur.X.Scale, newX, cur.Y.Scale, newY)
end)

-- ============================================================
-- 🔲 RESIZE HANDLE
-- ============================================================
local resizeHandle = Instance.new("TextButton", root)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -8, 1, -8)
resizeHandle.Size = UDim2.fromOffset(38, 38)
resizeHandle.BackgroundTransparency = 1
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 100

for i, spec in ipairs({
    {pos = UDim2.new(0, 17, 1, -7), size = UDim2.fromOffset(12, 3), rot = -4},
    {pos = UDim2.new(0, 10, 1, -11), size = UDim2.fromOffset(3, 8), rot = -18},
    {pos = UDim2.new(0, 7, 1, -19), size = UDim2.fromOffset(3, 7), rot = -32},
}) do
    local seg = Instance.new("Frame", resizeHandle)
    seg.AnchorPoint = Vector2.new(0, 0.5)
    seg.Position = spec.pos
    seg.Size = spec.size
    seg.Rotation = spec.rot
    seg.BackgroundColor3 = Color3.fromRGB(248, 248, 252)
    seg.BorderSizePixel = 0
    seg.ZIndex = 101
    Instance.new("UICorner", seg).CornerRadius = UDim.new(1, 0)
end

local resizing = false
local rStart = nil
local rSize = nil

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        rStart = input.Position
        rSize = root.AbsoluteSize
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
end)

UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - rStart
        root.Size = UDim2.fromOffset(
            math.max(340, rSize.X + d.X),
            math.max(280, rSize.Y + d.Y)
        )
    end
end)

-- ============================================================
-- 🌟 TOGGLE ICON
-- ============================================================
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "TRO_ToggleIcon"
toggleGui.ResetOnSpawn = false
toggleGui.IgnoreGuiInset = true
toggleGui.DisplayOrder = 1000
toggleGui.Parent = guiParent

local toggleContainer = Instance.new("TextButton", toggleGui)
toggleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
toggleContainer.Position = UDim2.new(1, -70, 0, 130)
toggleContainer.Size = UDim2.fromOffset(90, 90)
toggleContainer.BackgroundTransparency = 1
toggleContainer.Text = ""
toggleContainer.AutoButtonColor = false
toggleContainer.ZIndex = 1000

local outerRing = Instance.new("Frame", toggleContainer)
outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
outerRing.Size = UDim2.fromOffset(88, 88)
outerRing.BackgroundTransparency = 1
outerRing.ZIndex = 1000
Instance.new("UICorner", outerRing).CornerRadius = UDim.new(1, 0)
local outerStroke = Instance.new("UIStroke", outerRing)
outerStroke.Thickness = 2
outerStroke.Color = Color3.fromRGB(180, 180, 195)
outerStroke.Transparency = 0.2

local innerRing = Instance.new("Frame", toggleContainer)
innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
innerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
innerRing.Size = UDim2.fromOffset(72, 72)
innerRing.BackgroundTransparency = 1
innerRing.ZIndex = 1001
Instance.new("UICorner", innerRing).CornerRadius = UDim.new(1, 0)
local innerStroke = Instance.new("UIStroke", innerRing)
innerStroke.Thickness = 1.5
innerStroke.Color = Color3.fromRGB(140, 140, 155)
innerStroke.Transparency = 0.4

local toggleBtn = Instance.new("Frame", toggleContainer)
toggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
toggleBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
toggleBtn.Size = UDim2.fromOffset(60, 60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 1002
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color = Color3.fromRGB(180, 180, 195)
btnStroke.Thickness = 2.5

local tglText = Instance.new("TextLabel", toggleBtn)
tglText.Size = UDim2.fromScale(1, 1)
tglText.BackgroundTransparency = 1
tglText.Text = "TRO"
tglText.TextColor3 = Color3.fromRGB(230, 230, 240)
tglText.Font = Enum.Font.GothamBlack
tglText.TextSize = 14
tglText.ZIndex = 1003

local statusDot = Instance.new("Frame", toggleBtn)
statusDot.AnchorPoint = Vector2.new(1, 0)
statusDot.Position = UDim2.new(1, -6, 0, 6)
statusDot.Size = UDim2.fromOffset(10, 10)
statusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 165)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 1004
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
local dotStroke = Instance.new("UIStroke", statusDot)
dotStroke.Color = Color3.fromRGB(12, 12, 16)
dotStroke.Thickness = 2

local tglDragging = false
local tglMoved = false
local tglStartMouse = nil
local tglStartPos = nil
local tglTargetPos = nil

toggleContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tglDragging = true
        tglMoved = false
        tglStartMouse = input.Position
        tglStartPos = toggleContainer.Position
        tglTargetPos = toggleContainer.Position
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if tglDragging then
            tglDragging = false
            if not tglMoved then gui.Enabled = not gui.Enabled end
        end
    end
end)

UIS.InputChanged:Connect(function(input)
    if tglDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - tglStartMouse
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then
            tglMoved = true
            tglTargetPos = UDim2.new(
                tglStartPos.X.Scale, tglStartPos.X.Offset + d.X,
                tglStartPos.Y.Scale, tglStartPos.Y.Offset + d.Y
            )
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not tglTargetPos then return end
    local cur = toggleContainer.Position
    local t = math.clamp(dt * 10, 0, 1)
    local newX = cur.X.Offset + (tglTargetPos.X.Offset - cur.X.Offset) * t
    local newY = cur.Y.Offset + (tglTargetPos.Y.Offset - cur.Y.Offset) * t
    toggleContainer.Position = UDim2.new(cur.X.Scale, newX, cur.Y.Scale, newY)
end)

-- ============================================================
-- 🎬 ANIMATIONS
-- ============================================================
local t0 = os.clock()
local outerRot = 0
local innerRot = 0
local pulseT = 0

RunService.RenderStepped:Connect(function(dt)
    if not gui.Parent then return end
    local t = os.clock() - t0

    for _, s in ipairs(starData) do
        if s.dot.Parent then
            s.dot.BackgroundTransparency = math.clamp(s.base + math.sin(t * s.speed + s.phase) * 0.24, 0.04, 0.88)
        end
    end

    for i, b in ipairs(waveData) do
        if b.Parent then
            b.Position = UDim2.new(0.5, math.sin(t * (0.4 + i * 0.06)) * 24, 0.25 + i * 0.12, math.sin(t * 0.8 + i) * 7)
            b.Rotation = ((i % 2 == 0) and -2 or 2) + math.sin(t * 0.45 + i) * 2
        end
    end

    if orb.Parent then
        orb.Position = UDim2.new(0.5, 0, 0.61, math.sin(t * 0.5) * 2)
    end

    if toggleGui.Parent then
        pulseT = pulseT + dt
        outerRot = outerRot + dt * 45
        innerRot = innerRot - dt * 70

        if outerRing.Parent then outerRing.Rotation = outerRot end
        if innerRing.Parent then innerRing.Rotation = innerRot end

        if gui.Enabled then
            local pulse = 1 + math.sin(pulseT * 2) * 0.03
            toggleBtn.Size = UDim2.fromOffset(60 * pulse, 60 * pulse)
        end
    end
end)

-- ========== INIT ==========
acLog("✅ V23 loaded - 20 Presets")
dgLog("✅ V23 loaded")

pcall(function()
    SG:SetCore("SendNotification", {
        Title = "TRO V23",
        Text = "✅ 20 أمر ادمن كامل + مقبض تحجيم",
        Duration = 5
    })
end)

print("[TRO] ✅ V23 Loaded COMPLETE")
print("[TRO] Presets: 20 كامل")
print("[TRO] User: " .. player.Name)