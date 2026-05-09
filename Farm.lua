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
-- Shrine
-- ======================
local function buyFromShrine(shrineName, index)
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local interactions = map:FindFirstChild("Interactions")
    if not interactions then return end
    local shrine = interactions:FindFirstChild(shrineName)
    if not shrine then return end
    local node = shrine:FindFirstChild(tostring(index))
    if not node then return end
    local prompt = node:FindFirstChild("ProximityPrompt")
    firePrompt(prompt)
end

local function buyGuts()    buyFromShrine("UnitShrine_RabbitHero", 1) end
local function buyWagon()   buyFromShrine("UnitShrine_Sprintwagon", 1) end
local function buyTakaroda() buyFromShrine("UnitShrine_Takaroda", 1) end

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
-- LANES / BOX / BARRICADE / MONACH
-- ======================
local function buyLane(num)
    firePrompt(workspace.Map.Interactions["PurchaseLane"..num].Part.ProximityPrompt)
end

local function buyBox()
    firePrompt(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.ProximityPrompt)
end

local function buyBarricade(num)
    firePrompt(workspace.Map.Interactions["Barricade"..num].default.ProximityPrompt)
end

local function startBarricadeLoop()
    if BarricadeLoopRunning then return end
    BarricadeLoopRunning = true
    BarricadeLoopThread = task.spawn(function()
        while BarricadeLoopRunning do
            for i = 1, 3 do
                buyBarricade(i)
                task.wait(0.3)
            end
            for i = 1, 20 do
                if not BarricadeLoopRunning then return end
                task.wait(1)
            end
        end
    end)
    print("🧱 เริ่ม Auto ซื้อ Barricade ทุก 20 วินาที")
end

local function stopBarricadeLoop()
    if not BarricadeLoopRunning then return end
    BarricadeLoopRunning = false
    BarricadeLoopThread = nil
    print("🛑 หยุด Auto ซื้อ Barricade (Wave 0)")
end

local function buyMonach()
    firePrompt(workspace.Map.Interactions.PackATrait1["Cube.005"].ProximityPrompt)
end

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

        -- RESET (WAVE 0)
        if wave == 0 then
            if inGame then
                warn("🔄 Wave 0 → รีรอบเกม รีเซ็ตทุกอย่าง")
                Executed = {}
                ExecutedGutReady1 = false
                ExecutedGutReady2 = false
                MonachApplied = {}
                inGame = false
                unitManagerOpened = false
            end
            stopBarricadeLoop()
            continue
        end

        if not inGame and wave >= 1 then
            inGame = true
            warn("▶ เกมเริ่มแล้ว (Wave "..wave..") เริ่ม Auto")
        end

        -- WAVE 1
        if wave >= 1 and not Executed[1] then
            Executed[1] = true
            buyGuts()
            buyGuts()
            task.wait(1)
        end

        if wave >= 1 and not ExecutedGutReady1 then
            placeUnit("Rabbit Hero (Guts)", "364:Evolved", Vector3.new(20.8433,252.5818,95.2065), 1)
            task.wait(1)
            placeUnit("Rabbit Hero (Guts)", "364:Evolved", Vector3.new(20.6082,252.5819,99.6623), 2)
            task.wait(1.5)
        end

        -- WAVE 2
        if wave >= 2 and not Executed[2] then
            Executed[2] = true
            ExecutedGutReady1 = true
            buyGuts()
            buyGuts()
            placeUnit("Rabbit Hero (Guts)", "364:Evolved", Vector3.new(18.577674865722656,252.5818634033203,97.36162567138672), 3)
        end

        if wave >= 2 and not ExecutedGutReady2 then
            placeUnit("Rabbit Hero (Guts)", "364:Evolved", Vector3.new(18.577674865722656,252.5818634033203,97.36162567138672), 3)
            task.wait(1.5)
        end

        -- WAVE 3
        if wave >= 3 and not Executed[3] then
            Executed[3] = true
            ExecutedGutReady2 = true
            buyWagon() buyWagon() buyWagon()
            task.wait(5)
            -- วาง 3 Wagon slots ซ้ำ 2 รอบ
            local wagonPositions = {
                {Vector3.new(4.9603,251.6905,115.8387), 69},
                {Vector3.new(2.4375,251.6905,115.3120), 70},
                {Vector3.new(-0.7760,251.5234,115.2861), 71},
            }
            for _ = 1, 2 do
                for _, wp in ipairs(wagonPositions) do
                    placeUnit("Sprintwagon", "35", wp[1], wp[2])
                    task.wait(1)
                end
                task.wait(5)
            end
        end

        if wave >= 4 and not Executed[4] then
            Executed[4] = true
            task.wait(5)
            upgradeUnit("Sprintwagon", 4)
        end

        if wave >= 6 and not Executed[6] then
            Executed[6] = true
            task.wait(5)
            buyLane(2)
            task.wait(1)
            buyLane(3)
        end

        if wave >= 7 and not Executed[7] then
            Executed[7] = true
            buyTakaroda()
            placeUnitBurst("Takaroda", "47", {Vector3.new(-13.5438,251.5234,91.1173)}, 7)
        end

        if wave >= 8 and not Executed[8] then
            Executed[8] = true
            upgradeUnit("Takaroda", 6)
        end

        if wave >= 9 and not Executed[9] then
            Executed[9] = true
            buyFromShrine("UnitShrine_TempestPirate", 1)
            task.wait(3)
            placeUnitBurst("Tempest Pirate (Navigator)", "343:Evolved", {Vector3.new(20.609821319580078,251.86569213867188,104.9205322265625)}, 8, 2)
            task.wait(1)
            buyFromShrine("UnitShrine_TempestPirate", 1)
            task.wait(3)
            placeUnitBurst("Tempest Pirate (Navigator)", "343:Evolved", {Vector3.new(20.609821319580078,251.86569213867188,104.9205322265625)}, 8, 2)
        end

        if wave >= 10 and not Executed["TP6"] then
            Executed["TP6"] = true
            upgradeUnit("Tempest Pirate (Navigator)", 6)
        end

        if wave >= 11 and not Executed[11] then
            Executed[11] = true
            upgradeUnit("Rabbit Hero (Guts)", 8)
        end

        if wave >= 15 and not Executed[15] then
            Executed[15] = true
            buyFromShrine("UnitShrine_TempestPirate", 1)
            placeUnitBurst("Tempest Pirate (Navigator)", "343:Evolved", {Vector3.new(20.609821319580078,251.86569213867188,104.9205322265625)}, 8, 2)
        end

        if wave >= 15 and not Executed["TP6-2"] then
            Executed["TP6-2"] = true
            task.wait(0.5)
            upgradeUnit("Tempest Pirate (Navigator)", 6)
        end

        if wave >= 19 and not Executed[19] then Executed[19] = true; buyModifier("FortuneCity")   end
        if wave >= 20 and not Executed[20] then Executed[20] = true; buyModifier("EagleEyed")     end
        if wave >= 21 and not Executed[21] then Executed[21] = true; buyModifier("HeavyHitter")   end
        if wave >= 22 and not Executed[22] then Executed[22] = true; buyModifier("FastHands")     end
        if wave >= 25 and not Executed[25] then Executed[25] = true; buyModifier("ArmorBeGone")   end

        if wave >= 30 and not Executed[30] then
            Executed[30] = true
            for i = 1, 150 do buyBox(); task.wait(0.1) end
        end

        if wave >= 37 and not Executed[37] then
            Executed[37] = true
            upgradeUnit("Koguro (Unsealed)", 5);  task.wait(1)
            upgradeUnit("Lich King (Ruler)", 5);  task.wait(1)
            upgradeUnit("Iscanur (Pride)", 5);    task.wait(1)
            upgradeUnit("Ice Queen (Release)", 5); task.wait(1)
        end

        if wave >= 44 and not Executed[44] then
            Executed[44] = true
            upgradeUnit("Koguro (Unsealed)", 8);  task.wait(1)
            upgradeUnit("Lich King (Ruler)", 8);  task.wait(1)
            upgradeUnit("Iscanur (Pride)", 8);    task.wait(1)
            upgradeUnit("Ice Queen (Release)", 8); task.wait(1)
        end

        if wave >= 47 and not Executed[47] then
            Executed[47] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Rabbit Hero (Guts)", 1); task.wait(0.3)
            end
        end

        if wave >= 49 and not Executed[49] then
            Executed[49] = true
            upgradeUnit("Koguro (Unsealed)", 10); task.wait(1)
            upgradeUnit("Lich King (Ruler)", 10); task.wait(1)
            upgradeUnit("Iscanur (Pride)", 10);   task.wait(1)
            upgradeUnit("Ice Queen (Release)", 10); task.wait(1)
        end

        if wave >= 50 and not Executed[50] then
            Executed[50] = true
            for i = 1, 100 do buyBox(); task.wait(0.1) end
        end

        if wave >= 58 and not Executed[58] then
            Executed[58] = true
            Networking.Units["Update 9.5"].ConfirmLichSpells:FireServer({2,3,5,19})
        end

        if wave >= 59 and not Executed[59] then
            Executed[59] = true
            upgradeUnit("Koguro (Unsealed)", 12); task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13); task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15);   task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15); task.wait(1)
        end

        if wave >= 62 and not Executed[62] then
            Executed[62] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Rabbit Hero (Guts)", 1); task.wait(0.3)
            end
        end

        if wave >= 63 and not Executed[63] then
            Executed[63] = true
            for i = 1, 10 do buyBox(); task.wait(0.1) end
        end

        if wave >= 64 and not Executed[64] then
            Executed[64] = true
            local monachTargets = {
                {"Lich King (Ruler)"}, {"Koguro (Unsealed)"},
                {"Ice Queen (Release)"}, {"Iscanur (Pride)"}
            }
            for _, t in ipairs(monachTargets) do
                buyMonach(); task.wait(1)
                applyMonachToUnit(t[1], 1); task.wait(1)
            end
        end

        if wave >= 65 and not Executed[65] then
            Executed[65] = true
            for i = 1, 10 do buyBox(); task.wait(0.1) end
        end

        if wave >= 66 and not Executed[66] then
            Executed[66] = true
            local iceManPositions = {
                Vector3.new(14.536787033081055,252.58160400390625,91.04071807861328),
                Vector3.new(12.214313507080078,252.58157348632812,90.87340545654297),
                Vector3.new(14.403878211975098,252.5816650390625,92.87925720214844),
                Vector3.new(11.800287246704102,253.0923614501953,93.03865051269531),
            }
            for i, pos in ipairs(iceManPositions) do
                placeUnit("Ice Manipulator (Admiral)", "361:Evolved", pos, 12 + i)
                task.wait(1)
            end
        end

        if wave >= 66 and not Executed["IM8"] then
            Executed["IM8"] = true
            upgradeUnit("Ice Manipulator (Admiral)", 8)
        end

        if wave >= 67 and not Executed[67] then
            Executed[67] = true
            for i = 1, 25 do buyBox(); task.wait(0.1) end
        end

        if wave >= 69 and not Executed["WB9"] then
            Executed["WB9"] = true
            upgradeUnit("Trash Gamer (Twin Blades)", 9)
        end

        if wave >= 70 and not Executed[70] then
            Executed[70] = true
            for i = 1, 25 do buyBox(); task.wait(0.1) end
        end

        if wave >= 72 and not Executed["AM12"] then
            Executed["AM12"] = true
            upgradeUnit("Armored Mage (Requip)", 12)
        end

        if wave >= 73 and not Executed[73] then
            Executed[73] = true
            for i = 1, 25 do buyBox(); task.wait(0.1) end
        end

        if wave >= 75 and not Executed["CC11"] then
            Executed["CC11"] = true
            upgradeUnit("Company Captain (Hybrid)", 11)
        end

        if wave >= 76 and not Executed[76] then
            Executed[76] = true
            for i = 1, 25 do buyBox(); task.wait(0.1) end
        end

        if wave >= 78 and not Executed[78] then
            Executed[78] = true
            local monachTargets = {
                {"Lich King (Ruler)"}, {"Koguro (Unsealed)"},
                {"Ice Queen (Release)"}, {"Iscanur (Pride)"}
            }
            for _, t in ipairs(monachTargets) do
                buyMonach(); task.wait(1)
                applyMonachToUnit(t[1], 1); task.wait(1)
            end
        end

        if wave >= 79 and not Executed[79] then
            Executed[79] = true
            upgradeUnit("Koguro (Unsealed)", 12); task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13); task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15);   task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15); task.wait(1)
        end

        if wave >= 80 and not Executed[80] then
            Executed[80] = true
            MonachApplied = {}
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Rabbit Hero (Guts)", 1); task.wait(0.3)
            end
        end

        if wave >= 82 and not Executed[82] then
            Executed[82] = true
            for i = 1, 4 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Ice Manipulator (Admiral)", 1); task.wait(0.3)
            end
        end

        if wave >= 86 and not Executed[86] then
            Executed[86] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Trash Gamer (Twin Blades)", 1); task.wait(0.3)
            end
        end

        if wave >= 90 and not Executed[90] then
            Executed[90] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Armored Mage (Requip)", 1); task.wait(0.3)
            end
        end

        if wave >= 95 and not Executed[95] then
            Executed[95] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Company Captain (Hybrid)", 1); task.wait(0.3)
            end
        end

        if wave >= 100 and not Executed[100] then
            Executed[100] = true
            MonachApplied = {}
            local monachTargets = {
                {"Lich King (Ruler)"}, {"Koguro (Unsealed)"},
                {"Ice Queen (Release)"}, {"Iscanur (Pride)"}
            }
            for _, t in ipairs(monachTargets) do
                buyMonach(); task.wait(1)
                applyMonachToUnit(t[1], 1); task.wait(1)
            end
        end

        if wave >= 101 and not Executed[101] then
            Executed[101] = true
            MonachApplied = {}
            local batches = {
                {"Company Captain (Hybrid)", 3},
                {"Armored Mage (Requip)", 3},
                {"Trash Gamer (Twin Blades)", 3},
                {"Ice Manipulator (Admiral)", 4},
                {"Rabbit Hero (Guts)", 3},
            }
            for _, b in ipairs(batches) do
                for i = 1, b[2] do
                    buyMonach(); task.wait(0.4)
                    applyMonachToUnit(b[1], 1); task.wait(0.3)
                end
                task.wait(1)
            end
        end

        if wave >= 110 and not Executed["110"] then
            Executed["110"] = true
            upgradeUnit("Ice Queen (Release)", 15)
        end

        if wave >= 111 and not Executed[111] then
            Executed[111] = true
            for i = 1, 3 do
                buyMonach(); task.wait(0.4)
                applyMonachToUnit("Ice Queen (Release)", 1); task.wait(0.3)
            end
        end

        if wave >= 116 and not Executed[116] then
            Executed[116] = true
            upgradeUnit("Koguro (Unsealed)", 12); task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13); task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15);   task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15); task.wait(1)
        end

        if wave >= 117 and not Executed[117] then
            Executed[117] = true
            MonachApplied = {}
            local monachTargets = {
                {"Lich King (Ruler)"}, {"Koguro (Unsealed)"},
                {"Ice Queen (Release)"}, {"Iscanur (Pride)"}
            }
            for _, t in ipairs(monachTargets) do
                buyMonach(); task.wait(1)
                applyMonachToUnit(t[1], 1); task.wait(1)
            end
        end

        if wave >= 118 and not Executed[118] then
            Executed[118] = true
            local uuid = findUnitUUID("Koguro (Unsealed)")
            if uuid then
                ReplicatedStorage.Networking.Units["Update 6.5"].Koguro_DomainEvent
                    :FireServer("ToggleAuto", uuid)
            end
        end

        if wave >= 125 and not Executed["BARRICADE"] then
            Executed["BARRICADE"] = true
            startBarricadeLoop()
        end

        if wave >= 159 and not Executed[159] then
            Executed[159] = true
            for _, ln in ipairs({4,5,6,7}) do buyLane(ln) end
            task.wait(10)
            for _, ln in ipairs({4,5,6,7}) do buyLane(ln) end
        end
    end
end)

-- ======================
-- UNIT PLACEMENT BURST LOOP
-- ลด task.wait ระหว่าง unit จาก 2 วิ → 1.5 วิ
-- และรวม 3 Sprintwagon เป็น batch ครั้งเดียว
-- ======================
local PLACE_DELAY = 1.5  -- ลดจาก 2 วิ

task.spawn(function()
    local units = {
        {"Koguro (Unsealed)",        "235",       Vector3.new(6.1883745193481445,253.0923614501953,100.23284912109375),  50, 2},
        {"Lich King (Ruler)",        "338",       Vector3.new(5.769950866699219,249.0923614501953,95.12089538574219),   51, 2},
        {"Iscanur (Pride)",          "270",       Vector3.new(5.73417329788208,253.0923614501953,90.96935272216797),    52, 2},
        {"Ice Queen (Release)",      "363",       Vector3.new(-21.437185287475586,252.0919647216797,101.15544891357422), 53, 2},
        {"Company Captain (Hybrid)", "360",       Vector3.new(20.010068893432617,252.58169555664062,102.87059020996094), 54, 1},
        {"Company Captain (Hybrid)", "360",       Vector3.new(17.010068893432617,252.58169555664062,102.87059020996094), 55, 1},
        {"Company Captain (Hybrid)", "360",       Vector3.new(14.010068893432617,252.58169555664062,102.87059020996094), 56, 1},
        {"Armored Mage (Requip)",    "358:Evolved",Vector3.new(20.010068893432617,252.58169555664062,91.87059020996094),  57, 1},
        {"Armored Mage (Requip)",    "358:Evolved",Vector3.new(17.010068893432617,252.58169555664062,91.87059020996094),  58, 1},
        {"Armored Mage (Requip)",    "358:Evolved",Vector3.new(14.010068893432617,252.58169555664062,91.87059020996094),  59, 1},
        {"Trash Gamer (Twin Blades)","366:Evolved",Vector3.new(10.069950866699219,249.0923614501953,95.12089538574219),  60, 1},
        {"Trash Gamer (Twin Blades)","366:Evolved",Vector3.new(10.069950866699219,249.0923614501953,97.12089538574219),  61, 1},
        {"Trash Gamer (Twin Blades)","366:Evolved",Vector3.new(10.069950866699219,249.0923614501953,99.12089538574219),  62, 1},
        {"Ice Manipulator (Admiral)","361:Evolved",Vector3.new(13.069950866699219,249.0923614501953,94.12089538574219),  63, 1},
        {"Ice Manipulator (Admiral)","361:Evolved",Vector3.new(13.069950866699219,249.0923614501953,96.12089538574219),  64, 1},
        {"Ice Manipulator (Admiral)","361:Evolved",Vector3.new(13.069950866699219,249.0923614501953,98.12089538574219),  65, 1},
        {"Ice Manipulator (Admiral)","361:Evolved",Vector3.new(13.069950866699219,249.0923614501953,100.12089538574219), 66, 1},
        {"Ice Queen (Release)",      "363",        Vector3.new(-21.148853302001953,252.0919647216797,97.92547607421875), 67, 2},
        {"Ice Queen (Release)",      "363",        Vector3.new(-20.91863441467285,252.0919647216797,94.68634796142578),  68, 2},
        -- 3 Sprintwagons รวม batch เดียว
        {"Sprintwagon", "35", Vector3.new(4.9603,251.6905,115.8387),   69, 1},
        {"Sprintwagon", "35", Vector3.new(2.4375,251.6905,115.3120),   70, 1},
        {"Sprintwagon", "35", Vector3.new(-0.7760,251.5234,115.2861),  71, 1},
    }

    while true do
        for _, u in ipairs(units) do
            placeUnit(u[1], u[2], u[3], u[4])
            task.wait(PLACE_DELAY)
        end
        task.wait(5) -- รอพักก่อนวนใหม่
    end
end)
