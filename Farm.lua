repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16277809958
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง — ไม่ฟาร์มให้")
    return
end

-- SERVICES
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- Cache network references ครั้งเดียว (เดิมบาง loop เรียก WaitForChild ซ้ำ)
local Networking  = ReplicatedStorage:WaitForChild("Networking")
local UnitEvent   = Networking:WaitForChild("UnitEvent")

local function isCustomLevel()
    local ok, text = pcall(function()
        return player.PlayerGui.Guides.List.StageInfo.StageFrame.StageType.Text
    end)
    return ok and text == "Custom Level"
end

local function isStoryLevel()
    local ok, text = pcall(function()
        return player.PlayerGui.Guides.List.StageInfo.StageFrame.StageType.Text
    end)
    return ok and text == "Story"
end

local function freezeChar()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hrp.Anchored = true
    hum.PlatformStand = false
    hum.AutoRotate = false
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function unfreezeChar()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hrp.Anchored = false
    hum.PlatformStand = false
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Running)
end

-- PATHS
local waveLabel = player.PlayerGui:WaitForChild("HUD")
    :WaitForChild("Map")
    :WaitForChild("WavesAmount")

-- STATE
local Executed         = {}
local ExecutedGutReady1 = false
local ExecutedGutReady2 = false
local inGame           = false
local MonachApplied    = {}
local Upgrading        = {}
local BarricadeLoopRunning = false
local BarricadeLoopThread  = nil

-- ======================
-- moveToPrompt
-- ======================
local function moveToPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local part = prompt.Parent:IsA("BasePart")
        and prompt.Parent
        or prompt.Parent:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    hrp.Anchored = false
    hum.PlatformStand = false
    hum.AutoRotate = true
    hum:ChangeState(Enum.HumanoidStateType.Running)

    local targetCF = part.CFrame * CFrame.new(0, 0, -2)
    local distance = (hrp.Position - targetCF.Position).Magnitude
    local time = math.clamp(distance / 60, 0.05, 2)

    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = targetCF })
    tween:Play()

    local finished = false
    tween.Completed:Once(function() finished = true end)

    local start = tick()
    while not finished and tick() - start < 2 do task.wait() end
    task.wait(0.05)
end

-- ======================
-- UTIL
-- ======================
local function getWave()
    if not waveLabel or not waveLabel.ContentText then return nil end
    local text = waveLabel.ContentText
    return tonumber(text:match("(%d+)%s*/") or text:match("%d+"))
end

local function getSpringXP()
    local ok, text = pcall(function()
        return player.PlayerGui.SpringEventMenu.Frame.Holder.Content.Column.Header.RightGroup.XpProgressBar.BarTrack.XpText.Text
    end)
    if not ok or not text then return nil end
    -- รูปแบบ "18 / 30 XP" → ดึงแค่เลขหน้า
    return tonumber(text:match("^%s*(%d+)"))
end

local PromptBusy = false
local function firePrompt(prompt)
    if PromptBusy then return end
    PromptBusy = true
    pcall(function()
        unfreezeChar()
        moveToPrompt(prompt)
        if fireproximityprompt then
            fireproximityprompt(prompt, 1)
        end
        task.wait(0.05)
    end)
    PromptBusy = false
end

-- ======================
-- PLACE UNIT
-- ======================
local function placeUnit(name, id, position, slot)
    slot = slot or 1
    UnitEvent:FireServer("Render", {name, id, position, 0}, {SlotIndex = slot})
end

-- ======================
-- UNIT MANAGER
-- ======================
local unitManagerOpened = false

local function ensureUnitManagerOpen()
    local gui = player.PlayerGui
    if gui:FindFirstChild("UnitManager") then
        unitManagerOpened = true
        return true
    end
    unitManagerOpened = false

    local button = gui:FindFirstChild("Guides")
        and gui.Guides:FindFirstChild("List")
        and gui.Guides.List:FindFirstChild("StageInfo")
        and gui.Guides.List.StageInfo:FindFirstChild("Buttons")
        and gui.Guides.List.StageInfo.Buttons:FindFirstChild("UnitManager")
        and gui.Guides.List.StageInfo.Buttons.UnitManager:FindFirstChild("Button")

    if not button or not button:IsA("GuiButton") then
        warn("❌ ไม่เจอปุ่ม Unit Manager")
        return false
    end

    button.Selectable = true
    GuiService.SelectedCoreObject = button
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.03)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(0.15)
    GuiService.SelectedCoreObject = nil

    for _ = 1, 10 do
        if gui:FindFirstChild("UnitManager") then
            unitManagerOpened = true
            return true
        end
        task.wait(0.5)
    end

    warn("❌ กดแล้ว แต่ UnitManager ไม่ขึ้น")
    return false
end

local function hasUnitInInventory(unitName)
    local gui = player.PlayerGui
    local manager = gui:FindFirstChild("UnitManager")
    if not manager then return false end
    local list = manager:FindFirstChild("Holder") and manager.Holder:FindFirstChild("List")
    if not list then return false end

    for _, frame in ipairs(list:GetChildren()) do
        local unit = frame:FindFirstChild("Unit")
        if unit then
            local nameLabel = unit:FindFirstChild("Name")
                or unit:FindFirstChild("NameLabel")
                or unit:FindFirstChildWhichIsA("TextLabel")
            if nameLabel and nameLabel.ContentText then
                if string.find(nameLabel.ContentText, unitName, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local function placeUnitAndWait(name, id, position, slot)
    slot = slot or 1
    placeUnit(name, id, position, slot)
    task.wait(0.8)
    if not hasUnitInInventory(name) then
        warn("❌ วางไม่สำเร็จ:", name)
    else
        print("✅ วางสำเร็จ:", name)
    end
end

local function placeUnitBurst(name, id, positions, startSlot, step)
    startSlot = startSlot or 1
    step = step or 1
    for i, pos in ipairs(positions) do
        local slot = startSlot + (i - 1) * step
        placeUnit(name, id, pos, slot)
        task.wait(0.5)
    end
end

-- ======================
-- UPGRADE UNIT
-- ======================
local function upgradeUnit(unitName, targetLevel)
    if not ensureUnitManagerOpen() then return end
    local list = player.PlayerGui.UnitManager.Holder.List

    for _, frame in ipairs(list:GetChildren()) do
        if not frame:IsA("Frame") then continue end
        local unitRoot = frame:FindFirstChild("Unit")
        if not unitRoot then continue end

        local unitFrame = unitRoot:FindFirstChild(unitName)
        if not unitFrame then continue end

        local unitNameLabel = unitFrame:FindFirstChild("Container")
            and unitFrame.Container:FindFirstChild("Holder")
            and unitFrame.Container.Holder:FindFirstChild("Main")
            and unitFrame.Container.Holder.Main:FindFirstChild("UnitName")

        if not unitNameLabel or not unitNameLabel.ContentText then
            warn("❌ เจอ Unit แต่ไม่เจอ UnitName:", frame.Name)
            continue
        end
        if not string.find(unitNameLabel.ContentText, unitName, 1, true) then continue end

        local upgradeLabel = unitRoot:FindFirstChild("UpgradeLabel")
        if not upgradeLabel or not upgradeLabel.ContentText then
            warn("❌ ไม่มี UpgradeLabel:", frame.Name)
            continue
        end
        if string.find(upgradeLabel.ContentText, "Max") then continue end

        local uuid = frame.Name
        if Upgrading[uuid] then continue end
        Upgrading[uuid] = true

        print("⬆️ เริ่มอัพ:", unitNameLabel.ContentText, "uuid:", uuid)

        task.spawn(function()
            while inGame do
                local text = upgradeLabel.ContentText
                if not text then break end
                if string.find(text, "Max") then break end
                local current = tonumber(text:match("%[(%d+)/"))
                if not current then break end
                if current >= targetLevel then break end
                UnitEvent:FireServer("Upgrade", uuid)
                task.wait(0.8)
            end
            Upgrading[uuid] = nil
            print("✅ อัพเสร็จ:", unitNameLabel.ContentText, "uuid:", uuid)
        end)
    end
end

-- ======================
-- UUID FINDER
-- ======================
local function findUnitUUID(unitName)
    if not ensureUnitManagerOpen() then return nil end
    for _, frame in ipairs(player.PlayerGui.UnitManager.Holder.List:GetChildren()) do
        local unitRoot = frame:FindFirstChild("Unit")
        if unitRoot and unitRoot:FindFirstChild(unitName) then
            return frame.Name
        end
    end
    return nil
end

-- ======================
-- BUY FORTUNE
-- ======================

local function buyFortuneTrait()
    local Mo = {
        [1] = "Purchase",
        [2] = "FortuneTrait"
    }
    game:GetService("ReplicatedStorage")
        :WaitForChild("Networking")
        :WaitForChild("SpringEvent")
        :WaitForChild("ShopEvent")
        :FireServer(unpack(Mo))
end

-- ======================
-- BUY FORTUNE
-- ======================

local function buyMonachTrait()
    local FT = {
        [1] = "Purchase",
        [2] = "MonachTrait"
    }
    game:GetService("ReplicatedStorage")
        :WaitForChild("Networking")
        :WaitForChild("SpringEvent")
        :WaitForChild("ShopEvent")
        :FireServer(unpack(FT))
end

-- ======================
-- MONACH
-- ======================

local function applyMonachToUnit(unitName, limit)
    limit = limit or math.huge
    if not ensureUnitManagerOpen() then
        warn("❌ UnitManager ไม่เปิด")
        return
    end

    local list = player.PlayerGui.UnitManager.Holder.List
    local applied = 0

    for _, frame in ipairs(list:GetChildren()) do
        if applied >= limit then break end
        if not frame:IsA("Frame") then continue end

        local uuid = frame.Name
        if MonachApplied[uuid] then continue end

        local unitRoot = frame:FindFirstChild("Unit")
        if not unitRoot then continue end

        local unitFrame = unitRoot:FindFirstChild(unitName)
        if not unitFrame then continue end

        local button = unitFrame:FindFirstChild("Container")
            and unitFrame.Container:FindFirstChild("Button")

        if not button or not button:IsA("GuiButton") then
            warn("❌ ไม่เจอปุ่ม Monach:", unitName, uuid)
            continue
        end

        button.Selectable = true
        GuiService.SelectedCoreObject = button
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        GuiService.SelectedCoreObject = nil

        MonachApplied[uuid] = true
        applied += 1
        print("👑 ใส่ Monach สำเร็จ:", unitName, "uuid:", uuid)
        task.wait(0.2)
    end

    if applied == 0 then
        warn("⚠️ ไม่มี unit ที่ยังไม่ได้ใส่ Monach:", unitName)
    else
        print("✅ ใส่ Monach เพิ่มทั้งหมด:", applied, "ตัว")
    end
end

-- ======================
-- CUSTOM FARM
-- ======================
local CustomRunning = false
local CustomThread  = nil

local function startCustomFarm()
    if CustomRunning then return end
    CustomRunning = true
    print("🔥 เริ่มโหมด Custom Level (3 Wave) - Eizan Timing")

    -- Cache refs ก่อน loop (เดิมอยู่ใน loop)
    local TeleportEvent = Networking:WaitForChild("TeleportEvent")

    CustomThread = task.spawn(function()
        local startTime = tick()

        while CustomRunning do
            task.wait(0.2)

            if not isCustomLevel() then
                print("🛑 ออกจาก Custom Level → หยุด")
                CustomRunning = false
                break
            end

            local elapsed = tick() - startTime

            if elapsed >= 1 then
                print("📍 วาง Eizan (Aura) 1 ตัว")
                UnitEvent:FireServer("Render",
                    {"Eizan (Aura)", "148:Evolved", Vector3.new(445.74847412109375, 2.29998779296875, -341.93768310546875), 0},
                    {SlotIndex = 1}
                )
                task.wait(1)
                UnitEvent:FireServer("Render",
                    {"Warlord (Of the Sea)", 355, Vector3.new(-264.05078125, 0.5437054634094238, -141.412353515625), 0},
                    {SlotIndex = 5}
                )
                task.wait(1)
            end

            if elapsed >= 55 then
                print("📍 วาง Tuji (Sorcerer Killer) 3 ตัว (หลัง 55 วินาที)")
                local tujiPositions = {
                    Vector3.new(445.5354309082031, 2.29998779296875, -345.1536865234375),
                    Vector3.new(445.4750061035156, 2.29998779296875, -339.2325134277344),
                    Vector3.new(448.35382080078125, 2.29998779296875, -341.8939514160156),
                    Vector3.new(-261.3935241699219, 0.5454464554786682, -137.68838500976562),
                    Vector3.new(-263.14117431640625, 0.5454050302505493, -137.5552978515625),
                    Vector3.new(-265.1268615722656, 0.5452961921691895, -137.5487060546875)
                }
                for _, pos in ipairs(tujiPositions) do
                    UnitEvent:FireServer("Render",
                        {"Tuji (Sorcerer Killer)", "65:Evolved", pos, 0},
                        {SlotIndex = 2}
                    )
                    task.wait(1)
                end
                UnitEvent:FireServer("Render",
                    {"Ackers", 241, Vector3.new(-263.8894958496094, 0.6169147491455078, -125.61129760742188), 0},
                    {SlotIndex = 1}
                )
                task.wait(1)
            end

            if elapsed >= 75 then
                print("📍 วาง Ice Queen (Release) 1 ตัว (หลัง 75 วินาที)")
                UnitEvent:FireServer("Render",
                    {"Ice Queen (Release)", 363, Vector3.new(451.5220642089844, 2.29998779296875, -343.04156494140625), 0},
                    {SlotIndex = 6}
                )
                task.wait(1)
            end

            if elapsed >= 240 then
                print("🏠 ครบ 240 วินาที → กลับ Lobby")
                pcall(function() TeleportEvent:FireServer("Lobby") end)
                CustomRunning = false
                break
            end
        end
    end)
end

local function stopCustomFarm()
    if not CustomRunning then return end
    CustomRunning = false
    CustomThread = nil
    print("🛑 หยุด Custom Farm")
end

-- ======================
-- STORY FARM
-- ======================
local StoryRunning = false
local StoryThread  = nil

local function startStoryFarm()
    if StoryRunning then return end
    StoryRunning = true
    print("📖 เริ่มโหมด Story Farm")

    local TeleportEvent = Networking:WaitForChild("TeleportEvent")

    StoryThread = task.spawn(function()
        local StoryExecuted = {}
        local startTime = tick()

        while StoryRunning do
            task.wait(0.5)

            if not isStoryLevel() then
                print("🛑 ออกจาก Story → หยุด Story Farm")
                StoryRunning = false
                break
            end

            -- ✅ เช็ค Attribute Level ถึง 11 → กลับ Lobby
            local level = player:GetAttribute("Level")
            if level and level >= 11 then
                warn("🎓 Level ถึง " .. level .. " → กลับ Lobby")
                pcall(function() TeleportEvent:FireServer("Lobby") end)
                StoryRunning = false
                break
            end

            local wave = getWave()
            if not wave then continue end

            -- ============ วางตรงนี้เลย ============
            -- ตัวอย่าง: ปรับ positions / unit ตามที่ต้องการ

            -- RESET (WAVE 0)
            if wave == 0 then
                if inGame then
                    warn("🔄 Wave 0 → รีรอบเกม รีเซ็ตทุกอย่าง")
                    Executed = {}
                    local Skip = {
                         [1] = "Skip"
                     }

                     game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SkipWaveEvent"):FireServer(unpack(Skip))
                 end
             end

            if wave >= 1 and not StoryExecuted[1] then
                StoryExecuted[1] = true
                print("📍 [Story] Wave 1 - วาง units")
                placeUnit("Bounty Hunter", "347",
                    Vector3.new(431.1807556152344, 3.338402032852173, -358.1429138183594), 2)
                task.wait(1)
            end

            if wave >= 3 and not StoryExecuted[3] then
                StoryExecuted[3] = true
                print("📍 [Story] Wave 3 - วาง units")
                placeUnit("Bounty Hunter", "347",
                    Vector3.new(425.01348876953125, 2.29998779296875, -359.47314453125), 2)
                task.wait(1)
                placeUnit("Bounty Hunter", "347",
                    Vector3.new(425.176513671875, 2.29998779296875, -357.187744140625), 2)
                task.wait(1)
        
                print("📍 [Story] Wave 3 - upgrade")
                upgradeUnit("Bounty Hunter", 3)
            end
        end
    end)
end

local function stopStoryFarm()
    if not StoryRunning then return end
    StoryRunning = false
    StoryThread = nil
    print("🛑 หยุด Story Farm")
end
-- ======================
-- MODIFIER helper (ลด code ซ้ำ)
-- ======================
local ModifierEvent = Networking:WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent")

local function buyModifier(modId)
    ModifierEvent:FireServer("Purchase", {ModifierId = modId})
end

-- ======================
-- LOOP CHECK WAVE
-- (ลบ wave logger loop แยกออกไป — ประหยัด coroutine + 5x poll/วิ)
-- ======================
local lastWave = nil

task.spawn(function()
    while task.wait(0.5) do
        local wave = getWave()
        if wave == nil then continue end

        -- ✅ Log wave change รวมไว้ใน loop เดียว
        if wave ~= lastWave then
            print("🌊 Wave:", lastWave, "→", wave)
            lastWave = wave
        end

        if isCustomLevel() then
            if not CustomRunning then
                Networking:WaitForChild("CustomLevelEditor"):WaitForChild("ReplayMatch"):FireServer("Start")
                startCustomFarm()
            end
            task.wait(1)
            continue
        else
            stopCustomFarm()
        end

        if isStoryLevel() then
            if not StoryRunning then
                startStoryFarm()
            end
            task.wait(1)
            continue
        else
            stopStoryFarm()
        end

        local xp = getSpringXP()
        if xp and xp >= 3000 then
            warn("⭐ XP ถึง " .. xp .. " → กลับ Lobby")
            pcall(function()
                Networking:WaitForChild("TeleportEvent"):FireServer("Lobby")
            end)
            task.wait(5)
            continue
        end

        -- RESET (WAVE 0)
        if wave == 0 then
            if inGame then
                warn("🔄 Wave 0 → รีรอบเกม รีเซ็ตทุกอย่าง")
                Executed = {}
                local Skip = {
                    [1] = "Skip"
                }

                game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SkipWaveEvent"):FireServer(unpack(Skip))
            end
        end

        if not inGame and wave >= 1 then
            inGame = true
            warn("▶ เกมเริ่มแล้ว (Wave "..wave..") เริ่ม Auto")
        end

        -- WAVE 1
        if wave >= 1 and not Executed[1] then
            Executed[1] = true
            local Vote = {
                [1] = "Vote"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("MatchRestartSettingEvent"):FireServer(unpack(Vote))

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ClaimAllSpringEventLevels"):FireServer()
        end
    end
end)
