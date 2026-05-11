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

-- ตรวจสอบ RestartMethod
local Config = getgenv().Config or {}
if Config.RestartMethod == nil then
    Config.RestartMethod = true -- default = true
end

if Config.RestartMethod == false then
    print("💯 ฟาร์มปกติ")
end

if Config.RestartMethod ~= false then
    return
end

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
        [2] = "MonarchTrait"
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
                MonachApplied = {}
                inGame = false
                unitManagerOpened = false
            end
            continue
        end

        if not inGame and wave >= 1 then
            inGame = true
            warn("▶ เกมเริ่มแล้ว (Wave "..wave..") เริ่ม Auto")
        end

        -- WAVE 1
        if wave >= 1 and not Executed[1] then
            Executed[1] = true
            local Wall1 = {
                [1] = 2,
                [2] = 2
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("PlaceWall"):FireServer(unpack(Wall1))

            task.wait(1)

            local Wall2 = {
                [1] = 2,
                [2] = 4
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("PlaceWall"):FireServer(unpack(Wall2))

            task.wait(1)

            placeUnit("Strongest Shinobi (Martial)", "407:Evolved", Vector3.new(-206.64663696289062, 289.5259704589844, -296.1669616699219), 1, 3)
            task.wait(1)
            placeUnit("Strongest Shinobi (Martial)", "407:Evolved", Vector3.new(-206.44752502441406, 289.5259704589844, -294.2572326660156), 2, 3)
            task.wait(1)
            placeUnit("Strongest Shinobi (Martial)", "407:Evolved", Vector3.new(-206.68373107910156, 289.5259704589844, -292.1937255859375), 3, 3)
            task.wait(1)
            placeUnit("Tempest Pirate (Navigator)", "343:Evolved", Vector3.new(-204.38978576660156, 289.50933837890625, -326.347412109375), 4, 5)
            task.wait(1)
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        -- WAVE 2
        if wave >= 2 and not Executed[2] then
            Executed[2] = true

            placeUnit("Takaroda", "343:Evolved", Vector3.new(-202.53758239746094, 289.5093078613281, -326.4234313964844), 5, 6)
            task.wait(1)
            placeUnit("Devoted Demon (Obsessed)", "402:Evolved", Vector3.new(-204.83383178710938, 289.5259704589844, -296.1212463378906), 6, 2)
            task.wait(1)
            placeUnit("Devoted Demon (Obsessed)", "402:Evolved", Vector3.new(-204.67103576660156, 289.5259704589844, -294.1499938964844), 7, 2)
            task.wait(1)
            placeUnit("Devoted Demon (Obsessed)", "402:Evolved", Vector3.new(-204.69192504882812, 289.5259704589844, -291.9969787597656), 8, 2)
            task.wait(10)
            buyFortuneTrait(); task.wait(0.4)
            applyMonachToUnit("Tempest Pirate (Navigator)", 1); task.wait(0.3)
        end

        -- WAVE 3
        if wave >= 3 and not Executed[3] then
            Executed[3] = true
            task.wait(15)
            buyFortuneTrait(); task.wait(0.4)
            applyMonachToUnit("Takaroda", 1); task.wait(0.3)
            upgradeUnit("Takaroda", 6)
            upgradeUnit("Tempest Pirate (Navigator)", 5)
        end

        -- WAVE 4
        if wave >= 4 and not Executed[4] then
            Executed[4] = true

            placeUnit("Fruit Eater (He Wins)", "404:Evolved", Vector3.new(-201.60874938964844, 289.5259704589844, -291.89398193359375), 9, 1)
            task.wait(1)
            placeUnit("Fruit Eater (He Wins)", "404:Evolved", Vector3.new(-201.39892578125, 289.5259704589844, -293.7369689941406), 10, 1)
            task.wait(1)
            placeUnit("Fruit Eater (He Wins)", "404:Evolved", Vector3.new(-201.5526123046875, 289.5259704589844, -295.5173034667969), 11, 1)
            task.wait(1)
        end
        
        -- WAVE 6
        if wave >= 6 and not Executed[6] then
            Executed[6] = true

            local Wall3 = {
                [1] = 4,
                [2] = 6
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("PlaceWall"):FireServer(unpack(Wall3))

            task.wait(1)

            local Wall4 = {
                [1] = 3,
                [2] = 1
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("PlaceWall"):FireServer(unpack(Wall4))

            task.wait(1)
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        if wave >= 8 and not Executed[8] then
            Executed[8] = true
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Strongest Shinobi (Martial)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Strongest Shinobi (Martial)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Strongest Shinobi (Martial)", 1); task.wait(0.3)
        end

        if wave >= 9 and not Executed[9] then
            Executed[9] = true
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Devoted Demon (Obsessed)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Devoted Demon (Obsessed)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Devoted Demon (Obsessed)", 1); task.wait(0.3)
        end

        if wave >= 10 and not Executed[10] then
            Executed[10] = true
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Fruit Eater (He Wins)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Fruit Eater (He Wins)", 1); task.wait(0.3)
            task.wait(5)
            buyMonachTrait(); task.wait(0.4)
            applyMonachToUnit("Fruit Eater (He Wins)", 1); task.wait(0.3)
        end

        if wave >= 11 and not Executed[11] then
            Executed[11] = true
            local Wall5 = {
                [1] = 4,
                [2] = 4
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("PlaceWall"):FireServer(unpack(Wall5))
            task.wait(1)
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
            task.wait(1)
            local S5 = {
                [1] = "Purchase",
                [2] = "SkipWaves5"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ShopEvent"):FireServer(unpack(S5))
        end

        if wave >= 15 and not Executed[15] then
            Executed[15] = true
            upgradeUnit("Strongest Shinobi (Martial)", 5)
            upgradeUnit("Devoted Demon (Obsessed)", 5)
            upgradeUnit("Fruit Eater (He Wins)", 5)
        end

        if wave >= 16 and not Executed[16] then
            Executed[16] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        if wave >= 21 and not Executed[21] then
            Executed[21] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
            task.wait(1)
            local S5 = {
                [1] = "Purchase",
                [2] = "SkipWaves5"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ShopEvent"):FireServer(unpack(S5))
        end

        if wave >= 25 and not Executed[25] then
            Executed[25] = true
            upgradeUnit("Strongest Shinobi (Martial)", 8)
            upgradeUnit("Devoted Demon (Obsessed)", 8)
            upgradeUnit("Fruit Eater (He Wins)", 7)
        end

        if wave >= 26 and not Executed[26] then
            Executed[26] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        if wave >= 31 and not Executed[31] then
            Executed[31] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
            task.wait(1)
            local S5 = {
                [1] = "Purchase",
                [2] = "SkipWaves5"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ShopEvent"):FireServer(unpack(S5))
        end

        if wave >= 35 and not Executed[35] then
            Executed[35] = true
            upgradeUnit("Strongest Shinobi (Martial)", 12)
        end

        if wave >= 36 and not Executed[36] then
            Executed[36] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        if wave >= 41 and not Executed[41] then
            Executed[41] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
            task.wait(1)
            local S5 = {
                [1] = "Purchase",
                [2] = "SkipWaves5"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ShopEvent"):FireServer(unpack(S5))
        end

        if wave >= 46 and not Executed[46] then
            Executed[46] = true
            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("ConfirmPlacement"):FireServer()
        end

        if wave >= 51 and not Executed[51] then
        Executed[51] = true
        local RS = {
            [1] = "Vote"
        }

        game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("MatchRestartSettingEvent"):FireServer(unpack(RS))
        end
    end
end)
