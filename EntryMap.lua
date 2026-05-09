repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่เข้าแมพให้")
    return
end

-- RESET CONFIG ถ้าไม่ได้ตั้งเอง
if getgenv().Config == nil then
    getgenv().Config = {
        BuyMemoria = false,
        LockLV = nil,
        CustomRR = false
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = {
        BuyMemoria = false,
        LockLV = nil,
        CustomRR = false
    }
    getgenv().Config = Config
end

-- บังคับให้เปิดได้เฉพาะ true เท่านั้น
Config.BuyMemoria = (Config.BuyMemoria == true)
Config.CustomRR = (Config.CustomRR == true)

-- LockLV ต้องเป็นตัวเลขเท่านั้น
if type(Config.LockLV) ~= "number" then
    Config.LockLV = nil
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local playerGui = player:WaitForChild("PlayerGui", 10)

-- =========================
-- ฟังก์ชันดึงเลเวลจาก Attribute (เสถียรกว่า GUI)
-- =========================
local function getLevel()
    -- ชื่อ Attribute ที่น่าจะเป็น (เรียงจากน่าจะเจอมากที่สุด)
    local possibleLevelNames = {
        "Level",          -- ชื่อมาตรฐานที่สุด
        "PlayerLevel",
        "level",
        "playerLevel",
        "CurrentLevel"
    }
    
    for _, name in ipairs(possibleLevelNames) do
        local value = player:GetAttribute(name)
        if value ~= nil then
            local num = tonumber(value)
            if num then
                print("พบ Level จาก Attribute:", name, "=", num)  -- debug ว่าชื่อจริงคืออะไร
                return num
            end
        end
    end
    
    -- ถ้าไม่เจอเลย ให้ fallback ไปเช็ค GUI เดิม (หรือ return 0)
    warn("ไม่พบ Attribute Level — fallback ไปเช็ค GUI")
    local success, levelLabel = pcall(function()
        return playerGui:WaitForChild("HUD", 5)
                     :WaitForChild("Main", 5)
                     :WaitForChild("Level", 5)  -- หรือปรับ path ตามจริง
    end)
    
    if success and levelLabel and levelLabel:IsA("TextLabel") then
        local text = levelLabel.Text or ""
        local num = text:match("%d+")  -- ดึงตัวเลขแรก
        return tonumber(num) or 0
    end
    
    return 0  -- ถ้าไม่เจอทั้งคู่
end

-- =========================
-- ฟังก์ชัน WinterEvent
-- =========================
local function GoWinter()
    print("🔥 Level ≥ 11 → WinterEvent")
    
    local winterEvent = rep:WaitForChild("Networking"):WaitForChild("Winter"):WaitForChild("WinterLTMEvent")
    local lobbyEvent = rep:WaitForChild("Networking"):WaitForChild("LobbyEvent")
    
    pcall(function() winterEvent:FireServer("Create", "Normal") end)
    task.wait(3)
    pcall(function() lobbyEvent:FireServer("StartMatch") end)
end

-- =========================
-- เช็ค Presents26 (ทำให้ง่ายขึ้น)
-- =========================
local function getPresents26()
    local value = player:GetAttribute("Presents26")
    if value ~= nil then
        return tonumber(value) or 0
    end
    return 0
end

-- =========================
-- เช็ค Ice Queen (Release)
-- =========================
local function hasIceQueen()

    if game.PlaceId ~= 16146832113 then
        return false
    end

    local items
    local start = tick()

    repeat
        local ok
        ok, items = pcall(function()
            return playerGui.Windows.GlobalInventory.Holder
                .LeftContainer.FakeScrollingFrame.Items
        end)
        task.wait(0.5)
    until items or tick() - start > 15

    if not items then
        warn("[IceQueen] ❌ Items not loaded")
        return false
    end

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then
            for _, uuid in ipairs(cache:GetChildren()) do
                local holder = uuid:FindFirstChild("Container")
                    and uuid.Container:FindFirstChild("Holder")

                if holder and holder:FindFirstChild("Ice Queen (Release)") then
                    print("✅ FOUND Ice Queen (Release)")
                    return true
                end
            end
        end
    end

    return false
end

-- =========================
-- เช็ค Memoria จาก Attribute (เสถียรกว่า GUI)
-- =========================
local function hasIceQueenRest()

    local value = player:GetAttribute("WinterMemoriaVanguardPityCompleted")

    if value == true then
        print("✅ FOUND Ice Queen's Rest (Attribute)")
        return true
    end

    return false
end

-- =========================
-- Summon Event
-- =========================

-- Summon ตัวละคร
local summonEvent = rep:WaitForChild("Networking")
    :WaitForChild("Units")
    :WaitForChild("SummonEvent")

local summonArgs = {"SummonMany", "Winter26", 10}
local summonArgs50 = {"SummonMany", "Winter26", 50}

-- 🔹 Summon Memoria
local memoriaArgs = {"SummonMany", "WinterMemoria", 10}
local memoriaArgs50 = {"SummonMany", "WinterMemoria", 50}

-- =========================
-- Click Enemy Index Milestone
-- =========================
local TweenService = game:GetService("TweenService")

function SkyTweenTo(targetCF)
    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local upHeight = 120

    -- ขึ้น
    local up = TweenService:Create(hrp, TweenInfo.new(0.8), {
        CFrame = hrp.CFrame + Vector3.new(0, upHeight, 0)
    })
    up:Play()
    up.Completed:Wait()

    -- ไป
    local mid = TweenService:Create(hrp, TweenInfo.new(1), {
        CFrame = targetCF + Vector3.new(0, upHeight, 0)
    })
    mid:Play()
    mid.Completed:Wait()

    -- ลง (สำคัญ: ใช้ offset ก่อน)
    local down = TweenService:Create(hrp, TweenInfo.new(0.8), {
        CFrame = targetCF + Vector3.new(0, 3, 0)
    })
    down:Play()
    down.Completed:Wait()

    -- fix ตำแหน่งสุดท้าย
    hrp.CFrame = targetCF
end

local isRunningEnemyFlow = false

local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

local function ClickGuiCenter(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then return end

    local absPos = guiObject.AbsolutePosition
    local absSize = guiObject.AbsoluteSize

    local x = absPos.X + absSize.X / 2
    local y = absPos.Y + absSize.Y / 2

    -- กด
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait()
    -- ปล่อย
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function clickCenterScreenSafe()
    if not Camera then return end

    local size = Camera.ViewportSize
    local x = size.X / 2
    local y = size.Y / 2

    -- ยิงเข้า CoreGui → ไม่โดน GUI เกม
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game:GetService("CoreGui"), 0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game:GetService("CoreGui"), 0)

    print("🖱️ Click กลางจอ")
end

local GuiService = game:GetService("GuiService")

local function SelectDialogueOption(btn)
    if not btn then return end

    -- ตั้ง focus ไปที่ปุ่ม
    GuiService.SelectedObject = btn
    task.wait()

    -- 🔥 จำลองการกด Enter (เลือก option)
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait()
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)

    print("✅ เลือก Enemy Index ผ่านระบบเกม")
end

function DoEnemyIndexFlow_Sky()
    if isRunningEnemyFlow then return false end
    isRunningEnemyFlow = true

    local player = Players.LocalPlayer
    local hrp = (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")

    -- =========================
    -- 🔥 ไปหา Lights / Lighting ก่อน
    -- =========================
    local lightTargetCF

    pcall(function()
        local play = workspace:WaitForChild("MainLobby")
            :WaitForChild("Gamemodes")
            :WaitForChild("Play")

        local light = play:WaitForChild("Lights / Lighting")

        -- ⚠️ ใช้ index แต่กันพัง
        local children = light:GetChildren()
        local target = children[9]

        if target then
            lightTargetCF = target:GetPivot()
        end
    end)

    -- ถ้าหาเจอ → บินไปก่อน
    if lightTargetCF then
        print("🌟 Tween ไป Lights / Lighting ก่อน")
        SkyTweenTo(lightTargetCF)
        task.wait(1.5)
    else
        warn("❌ หา Lights ไม่เจอ ข้ามไป NPC เลย")
    end
    
    -- =========================
    -- 🔥 SNAP ไปหา NPC ทันที
    -- =========================
    local npc = workspace:WaitForChild("MainLobby")
        :WaitForChild("NPC")
        :WaitForChild("Okabu")

    local hrp = (Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait())
        :WaitForChild("HumanoidRootPart")

    local npcPos = npc:GetPivot().Position

    -- รอให้นิ่งจริง
    task.wait(0.5)

    --========================
    -- 🔥 ยิง Proximity (เวอร์ชันเสถียร)
    --========================
    local npc = workspace:WaitForChild("MainLobby")
        :WaitForChild("NPC")
        :WaitForChild("Okabu")

    local prompt = npc:WaitForChild("EnemyIndex")

    -- 📍 ใช้ Pivot แทน (แม่นกว่า)
    local npcPos = npc:GetPivot().Position

    -- 🔒 บังคับ snap เข้าใกล้ (กันพลาด)
    hrp.CFrame = CFrame.new(npcPos + Vector3.new(0, 3, -5))

    task.wait(0.3)

    local dist = (hrp.Position - npcPos).Magnitude
    print("Distance to Okabu:", dist)

    if dist <= 20 then
        fireproximityprompt(prompt, 2)
        print("✅ Fired Proximity")
    else
        warn("❌ ยังไกลเกิน:", dist)
    end

    --========================
    -- เร่ง Dialogue (เวอร์ชันใหม่)
    --========================

    local gui = player:WaitForChild("PlayerGui")

    local dialogue
    repeat
        dialogue = gui:FindFirstChild("Dialogue")
        task.wait()
    until dialogue
    
    local content = dialogue.Dialogue:WaitForChild("Content")
    local options = dialogue.Dialogue:WaitForChild("Options")

    print("🖱️ เร่งบทจนกว่าจะเลือกได้...")

    local btn

    repeat
        -- spam click เผื่อระบบเร่ง
        ClickGuiCenter(content)

        -- 🔥 หา button ทุก loop
        local opt = options:FindFirstChild("Option1")
        btn = opt and (opt:FindFirstChild("Enemy Index") or opt:FindFirstChildWhichIsA("TextButton"))

        -- 🔥 ถ้าพร้อมกดก็เลือก
        if btn and btn.Visible and btn.Active then
            SelectDialogueOption(btn)
        end

        task.wait(1) -- กันเฟรมค้าง
    until playerGui:FindFirstChild("EnemyIndex") -- loop จน EnemyIndex GUI ขึ้น

    print("✅ EnemyIndex GUI ขึ้นแล้ว!")

    --========================
    -- Milestones (แก้ให้รอจนขึ้น EnemyMilestones GUI)
    --========================
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local buttonEMS

    repeat
        -- พยายามหา Button
        local enemyIndexGui = playerGui:FindFirstChild("EnemyIndex")
        if enemyIndexGui and enemyIndexGui.Main and enemyIndexGui.Main.Milestones then
            buttonEMS = enemyIndexGui.Main.Milestones:FindFirstChild("Button")
            if buttonEMS then
                buttonEMS.Selectable = true
                GuiService.SelectedCoreObject = buttonEMS

                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                wait(0.1)
                GuiService.SelectedCoreObject = nil
            end
        end

        task.wait(2) -- กันเฟรมค้าง
    until playerGui:FindFirstChild("EnemyMilestones") -- loop จน GUI EnemyMilestones ขึ้น

    print("✅ EnemyMilestones GUI ขึ้นแล้ว!")
end

local function hasUnclaimedMilestone()
    DoEnemyIndexFlow_Sky()
   
    local enemyGui = player.PlayerGui:FindFirstChild("EnemyMilestones")
    if not enemyGui then
        warn("❌ EnemyMilestones GUI ยังไม่โหลด")
        return false
    end

    local holder = enemyGui:FindFirstChild("Holder")
    local list = holder and holder:FindFirstChild("List")
    if not list then
        warn("❌ หา List ไม่เจอ")
        return false
    end

    print("✅ เช็ค EnemyMilestones")

    -- เช็ค Index อื่น ๆ (ไม่รวมการบังคับ 312 แล้ว)
    local checkIndexes = {4,5,6,9,10,11,12,13,14,15,16,17}
    for _, i in ipairs(checkIndexes) do
        local item = list:FindFirstChild(tostring(i)) or list:GetChildren()[i]
        if item then
            local label = item:FindFirstChild("Button") and item.Button:FindFirstChild("Label")
            if label and label:IsA("TextLabel") and label.Text ~= "Claimed" then
                print("❗ เจอ Milestone ยังไม่รับที่ Index:", i)
                return true
            end
        end
    end

    print("✅ ไม่มี Milestone ค้าง")
    return false
end

-- =========================
-- Play Custom Level (สุ่มระหว่าง 1334 กับ 312)
-- =========================
local function playMilestoneLevel()
    -- สุ่ม 50% ระหว่าง 1334 และ 312
    local levelId = math.random(1, 2) == 1 and 1334 or 312

    print("🎲 สุ่มด่าน Milestone → เล่นด่าน ID:", levelId)

    pcall(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("Networking")
            :WaitForChild("Levels")
            :WaitForChild("Play")
            :FireServer(levelId)
    end)
end

-- =========================
-- ลูปหลัก (เพิ่ม pcall ห่อเพื่อป้องกัน crash)
-- =========================
task.spawn(function()
    while true do
        local DelayCheck = 0.2
        local success, err = pcall(function()
            
            local level = getLevel()
            local presents = getPresents26()

            local hasUnit = hasIceQueen()
            local hasMemoria = hasIceQueenRest()

            print(
                "🧠 Decision | Level:", level,
                "| Presents:", presents,
                "| Has Unit:", hasUnit,
                "| Has Memoria:", hasMemoria,
                "| BuyMemoria:", Config.BuyMemoria
            )
                    
            -- ✅ เช็ค Milestone ก่อนทุกอย่าง
            if Config.CustomRR then
                if level >= 30 then
                    if hasUnclaimedMilestone() then
                        task.wait(5)
                        playMilestoneLevel()
                        print("💠 ไปเก็บ Enemy Index")
                        task.wait(5)
                        return
                    end
                end
            else
                print("⏭️ ข้าม Enemy Milestone เพราะปิด CustomRR")
            end

            -- ❌ ไม่เข้า Story แล้ว ไม่สน Level
            -- ทำแต่ Winter เท่านั้น

            if hasUnit and hasMemoria then
                if not Config.LockLV then
                    if presents >= 1500 and presents < 7500 then
                        summonEvent:FireServer(unpack(summonArgs))
                        task.wait(0.1)
                    elseif presents >= 7500 then
                        summonEvent:FireServer(unpack(summonArgs50))
                        task.wait(0.1)
                        clickCenterScreenSafe()
                    else        
                        print("✅ มีของครบอยู่แล้ว (ไม่ล็อคเลเวล)")
                        DelayCheck = 600
                        task.wait(60)
                        GoWinter()
                    end
                elseif level >= Config.LockLV then
                    if presents >= 1500 and presents < 7500 then
                        summonEvent:FireServer(unpack(summonArgs))
                        task.wait(0.1)
                    elseif presents >= 7500 then
                        summonEvent:FireServer(unpack(summonArgs50))
                        task.wait(0.1)
                        clickCenterScreenSafe()
                    else
                        print("🔒 ถึงเลเวลที่ล็อคแล้ว อยู่เฉยๆ")
                        DelayCheck = 600
                        task.wait(60)
                        GoWinter()
                    end
                else
                    if presents >= 1500 and presents < 7500 then
                        summonEvent:FireServer(unpack(summonArgs))
                        task.wait(0.1)
                    elseif presents >= 7500 then
                        summonEvent:FireServer(unpack(summonArgs50))
                        task.wait(0.1)
                        clickCenterScreenSafe()
                    else
                        print("📈 เวลไม่ถึง ล็อคไว้ ต้องไปฟาร์ม")
                        task.wait(60)
                        GoWinter()
                    end
                end
            elseif presents >= 1500 and presents < 7500 then
                if hasMemoria and not hasUnit then
                    print("⁉️ มีแค่ Memoria")
                    summonEvent:FireServer(unpack(summonArgs))
                    task.wait(0.1)
                elseif not hasMemoria and hasUnit then
                    if Config.BuyMemoria then
                        print("⁉️ มีแค่ Ice Queen (Release)")
                        summonEvent:FireServer(unpack(memoriaArgs))
                        task.wait(0.1)
                    else
                        print("❌ ไม่มี Config Memoria")
                    end
                else
                    print("❌ ไม่มีทั้งคู่")

                    if Config.BuyMemoria then
                        print("❎ มี Config Memoria")
                        summonEvent:FireServer(unpack(memoriaArgs))
                        task.wait(1)
                    else
                        print("❎ ไม่มี Config Memoria")
                        summonEvent:FireServer(unpack(summonArgs))
                        task.wait(1)
                    end
                end
            elseif presents >= 7500 then
                if hasMemoria and not hasUnit then
                    print("⁉️ มีแค่ Memoria")
                    summonEvent:FireServer(unpack(summonArgs50))
                    task.wait(0.1)
                    clickCenterScreenSafe()
                elseif not hasMemoria and hasUnit then
                    if Config.BuyMemoria then
                        print("⁉️ มีแค่ Ice Queen (Release)")
                        summonEvent:FireServer(unpack(memoriaArgs50))
                        task.wait(0.1)
                        clickCenterScreenSafe()
                    else
                        print("❌ ไม่มี Config Memoria")
                    end
                else
                    print("❌ ไม่มีทั้งคู่")

                    if Config.BuyMemoria then
                        print("❎ มี Config Memoria")
                        summonEvent:FireServer(unpack(memoriaArgs50))
                        task.wait(1)
                        clickCenterScreenSafe()
                    else
                        print("❎ ไม่มี Config Memoria")
                        summonEvent:FireServer(unpack(summonArgs50))
                        task.wait(1)
                        clickCenterScreenSafe()
                    end
                end
            else
                print("❌ ไม่มี Presents ไปฟาร์ม")
                task.wait(60)
                GoWinter()
            end
        end)

        if not success then
            warn("❌ Error ใน loop:", err)
        end

        task.wait(DelayCheck)
    end
end)
