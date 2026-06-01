repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่เข้าแมพให้")
    return
end

if getgenv().Config == nil then
    getgenv().Config = {
        BuyMemoria = false,
        LockLV = nil,
        CustomRR = false,
        RestartMethod = true,
        FarmOnly = false,
        FarmOnlyFlowers26 = 0
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = {
        BuyMemoria = false,
        LockLV = nil,
        CustomRR = false,
        RestartMethod = true
    }
    getgenv().Config = Config
end

Config.BuyMemoria = (Config.BuyMemoria == true)
Config.CustomRR   = (Config.CustomRR == true)
Config.FarmOnly   = (Config.FarmOnly == true)
if type(Config.FarmOnlyFlowers26) ~= "number" then Config.FarmOnlyFlowers26 = 0 end
if type(Config.LockLV) ~= "number" then Config.LockLV = nil end
if Config.RestartMethod == nil then Config.RestartMethod = true end

if Config.RestartMethod == true then print("⏩ เข้าฟาร์มแบบ Restart") end
if Config.RestartMethod ~= true then return end

local Players  = game:GetService("Players")
local player   = Players.LocalPlayer
local rep      = game:GetService("ReplicatedStorage")
local playerGui = player:WaitForChild("PlayerGui", 10)

local function getLevel()
    local names = {"Level","PlayerLevel","level","playerLevel","CurrentLevel"}
    for _, name in ipairs(names) do
        local v = player:GetAttribute(name)
        if v ~= nil then
            local n = tonumber(v)
            if n then return n end
        end
    end
    local ok, lbl = pcall(function()
        return playerGui:WaitForChild("HUD",5):WaitForChild("Main",5):WaitForChild("Level",5)
    end)
    if ok and lbl and lbl:IsA("TextLabel") then
        return tonumber(lbl.Text:match("%d+")) or 0
    end
    return 0
end

local function GoSpring()
    print("🌸 ไปฟาร์ม Spring")
    local SpringEvent = rep:WaitForChild("Networking"):WaitForChild("SpringEvent"):WaitForChild("Teleport")
    local lobbyEvent  = rep:WaitForChild("Networking"):WaitForChild("LobbyEvent")
    pcall(function() SpringEvent:FireServer("Create") end)
    task.wait(3)
    pcall(function() lobbyEvent:FireServer("StartMatch") end)
end

local function getFlowers26()
    return tonumber(player:GetAttribute("Flowers26")) or 0
end

local function hasShinobiGod()
    if game.PlaceId ~= 16146832113 then return false end
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
    if not items then warn("[Shinobi God] ❌ Items not loaded") return false end
    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then
            for _, uuid in ipairs(cache:GetChildren()) do
                local holder = uuid:FindFirstChild("Container")
                    and uuid.Container:FindFirstChild("Holder")
                if holder and holder:FindFirstChild("Shinobi God (Infinite Dreams)") then
                    print("✅ FOUND Shinobi God") return true
                end
            end
        end
    end
    return false
end

local function hasMemoria()
    local windows = playerGui:FindFirstChild("Windows")
    if not windows then warn("[hasMemoria] Windows ยังไม่โหลด") return false end
    local ok, result = pcall(function()
        return windows.Titles.Holder.List.Main["Dream Conqueror"].Equip:FindFirstChild("Locked")
    end)
    if not ok then return true end
    return result == nil
end

local summonEvent  = rep:WaitForChild("Networking"):WaitForChild("Units"):WaitForChild("SummonEvent")
local summonArgs   = {"SummonMany", "Spring26", 10}
local summonArgs50 = {"SummonMany", "Spring26", 49}

local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService          = game:GetService("GuiService")
local Camera              = workspace.CurrentCamera

local function clickCenterScreenSafe()
    if not Camera then return end
    local size = Camera.ViewportSize
    VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2, 0, true,  game:GetService("CoreGui"), 0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2, 0, false, game:GetService("CoreGui"), 0)
    print("🖱️ Click กลางจอ")
end

local function ClickGuiCenter(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then return end
    local x = guiObject.AbsolutePosition.X + guiObject.AbsoluteSize.X / 2
    local y = guiObject.AbsolutePosition.Y + guiObject.AbsoluteSize.Y / 2
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true,  game, 0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function SelectDialogueOption(btn)
    if not btn then return end
    GuiService.SelectedObject = btn
    task.wait()
    VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Return, false, game)
    task.wait()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

function SkyTweenTo(targetCF)
    local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local up   = 120
    TweenService:Create(hrp, TweenInfo.new(0.8), {CFrame = hrp.CFrame + Vector3.new(0,up,0)}):Play()
    task.wait(0.8)
    TweenService:Create(hrp, TweenInfo.new(1),   {CFrame = targetCF + Vector3.new(0,up,0)}):Play()
    task.wait(1)
    TweenService:Create(hrp, TweenInfo.new(0.8), {CFrame = targetCF + Vector3.new(0,3,0)}):Play()
    task.wait(0.8)
    hrp.CFrame = targetCF
end

local isRunningEnemyFlow = false

function DoEnemyIndexFlow_Sky()
    if isRunningEnemyFlow then return false end
    isRunningEnemyFlow = true

    -- ★ ครอบทุกอย่างใน pcall → reset isRunningEnemyFlow ได้เสมอ
    local ok, err = pcall(function()
        local hrp = (Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait())
            :WaitForChild("HumanoidRootPart")

        -- ★ แก้ path: InteractiveLobby แทน MainLobby + index [4] แทน [9] + ใส่ timeout ทุกจุด
        local lightTargetCF
        pcall(function()
            local children = workspace
                :WaitForChild("InteractiveLobby", 5)
                :WaitForChild("Gamemodes", 5)
                :WaitForChild("Play", 5)
                ["Lights / Lighting"]:GetChildren()
            if children[4] then lightTargetCF = children[4]:GetPivot() end
        end)

        if lightTargetCF then
            SkyTweenTo(lightTargetCF)
            task.wait(1.5)
        else
            warn("❌ หา Lights ไม่เจอ ข้ามไป NPC เลย")
        end

        -- ★ แก้ path NPC: MainLobby + Bounty Hunter
        local npc = workspace
            :WaitForChild("MainLobby", 10)
            :WaitForChild("NPC", 10)
            :FindFirstChild("Bounty Hunter")

        if not npc then
            warn("❌ หา NPC Bounty Hunter ไม่เจอ")
            return
        end

        local npcPos = npc:GetPivot().Position
        hrp = (Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait())
            :WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(npcPos + Vector3.new(0,3,-5))
        task.wait(0.5)

        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

        local gui = player:WaitForChild("PlayerGui")
        local dialogue
        local dialogueTimeout = tick()
        repeat
            dialogue = gui:FindFirstChild("Dialogue")
            task.wait()
            -- ★ timeout 15 วิ กัน hang
        until dialogue or tick() - dialogueTimeout > 15

        if not dialogue then
            warn("❌ Dialogue ไม่ขึ้นใน 15 วิ")
            return
        end

        local content = dialogue.Dialogue:WaitForChild("Content", 5)
        local options = dialogue.Dialogue:WaitForChild("Options", 5)
        if not content or not options then
            warn("❌ หา Content/Options ไม่เจอ")
            return
        end

        local btn
        local eiTimeout = tick()
        repeat
            ClickGuiCenter(content)
            local opt = options:FindFirstChild("Option1")
            btn = opt and (opt:FindFirstChild("Enemy Index") or opt:FindFirstChildWhichIsA("TextButton"))
            if btn and btn.Visible and btn.Active then SelectDialogueOption(btn) end
            task.wait(1)
            -- ★ timeout 30 วิ กัน hang
        until playerGui:FindFirstChild("EnemyIndex") or tick() - eiTimeout > 30

        if not playerGui:FindFirstChild("EnemyIndex") then
            warn("❌ EnemyIndex GUI ไม่ขึ้นใน 30 วิ")
            return
        end

        print("✅ EnemyIndex GUI ขึ้นแล้ว!")

        local buttonEMS
        local emsTimeout = tick()
        repeat
            local ei = playerGui:FindFirstChild("EnemyIndex")
            if ei and ei.Main and ei.Main.Milestones then
                buttonEMS = ei.Main.Milestones:FindFirstChild("Button")
                if buttonEMS then
                    buttonEMS.Selectable = true
                    GuiService.SelectedCoreObject = buttonEMS
                    VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    task.wait(0.1)
                    GuiService.SelectedCoreObject = nil
                end
            end
            task.wait(2)
            -- ★ timeout 30 วิ กัน hang
        until playerGui:FindFirstChild("EnemyMilestones") or tick() - emsTimeout > 30

        if not playerGui:FindFirstChild("EnemyMilestones") then
            warn("❌ EnemyMilestones GUI ไม่ขึ้นใน 30 วิ")
            return
        end

        print("✅ EnemyMilestones GUI ขึ้นแล้ว!")
    end)

    -- ★ reset เสมอ ไม่ว่าจะ error หรือไม่
    isRunningEnemyFlow = false

    if not ok then
        warn("❌ DoEnemyIndexFlow_Sky error:", err)
    end
end

local function hasUnclaimedMilestone()
    DoEnemyIndexFlow_Sky()
    local enemyGui = player.PlayerGui:FindFirstChild("EnemyMilestones")
    if not enemyGui then warn("❌ EnemyMilestones GUI ยังไม่โหลด") return false end
    local list = enemyGui:FindFirstChild("Holder") and enemyGui.Holder:FindFirstChild("List")
    if not list then warn("❌ หา List ไม่เจอ") return false end
    for _, i in ipairs({4,6,7,10,11,12,13,14,15,16,17,18}) do
        local item = list:FindFirstChild(tostring(i)) or list:GetChildren()[i]
        if item then
            local label = item:FindFirstChild("Button") and item.Button:FindFirstChild("Label")
            if label and label:IsA("TextLabel") and label.Text ~= "Claimed" then
                print("❗ Milestone ยังไม่รับ Index:", i) return true
            end
        end
    end
    print("✅ ไม่มี Milestone ค้าง") return false
end

local function playMilestoneLevel()
    local levelId = math.random(1,2) == 1 and 1334 or 312
    print("🎲 สุ่มด่าน Milestone ID:", levelId)
    pcall(function()
        rep:WaitForChild("Networking"):WaitForChild("Levels"):WaitForChild("Play"):FireServer(levelId)
    end)
end

local function farmStory()
    local Add = {
        [1] = "AddMatch",
        [2] = {
            ["Difficulty"]  = "Normal",
            ["Act"]         = "Act1",
            ["StageType"]   = "Story",
            ["Stage"]       = "Stage1",
            ["FriendsOnly"] = false
        }
    }
    rep:WaitForChild("Networking"):WaitForChild("LobbyEvent"):FireServer(unpack(Add))
    task.wait(2)
    rep:WaitForChild("Networking"):WaitForChild("LobbyEvent"):FireServer("StartMatch")
end

-- =========================
-- ลูปหลัก
-- =========================
task.spawn(function()
    while true do
        local DelayCheck = 0.2
        local ok, err = pcall(function()

            local level     = getLevel()
            local Flowers26 = getFlowers26()

            -- ============ FarmOnly mode ============
            if Config.FarmOnly then
                if level < 11 then
                    print("🌾 FarmOnly: เลเวลยังไม่ถึง 11 → ฟาร์ม Story")
                    farmStory()
                    return
                end
                if Flowers26 >= Config.FarmOnlyFlowers26 then
                    print("🌾 FarmOnly: Flowers26 ครบ → หยุดฟาร์ม")
                    DelayCheck = 600
                    task.wait(60)
                    GoSpring()
                else
                    print("🌾 FarmOnly: ฟาร์ม Spring | Flowers26:", Flowers26, "/", Config.FarmOnlyFlowers26)
                    task.wait(60)
                    GoSpring()
                end
                return
            end

            -- ============ เช็ค Milestone ============
            if Config.CustomRR then
                if level >= 30 and hasUnclaimedMilestone() then
                    task.wait(5)
                    playMilestoneLevel()
                    print("💠 ไปเก็บ Enemy Index")
                    task.wait(5)
                    return
                end
            else
                print("⏭️ ข้าม Enemy Milestone เพราะปิด CustomRR")
            end

            print("🧠 Level:", level, "| Flowers26:", Flowers26)

            if level < 11 then
                print("📖 Level < 11 → ฟาร์ม Story")
                farmStory()
                return
            end

            local memoria = hasMemoria()
            if not memoria then
                print("📈 ยังไม่ได้ Memoria → ไปฟาร์ม Spring")
                task.wait(60)
                GoSpring()
                return
            end

            local hasUnit = hasShinobiGod()
            if not hasUnit then
                if Flowers26 >= 1500 and Flowers26 < 7500 then
                    print("🎲 ได้ Memoria แล้ว สุ่ม 10 | Flowers26:", Flowers26)
                    summonEvent:FireServer(unpack(summonArgs))
                    task.wait(0.1)
                elseif Flowers26 >= 7500 then
                    print("🎲 ได้ Memoria แล้ว สุ่ม 49 | Flowers26:", Flowers26)
                    summonEvent:FireServer(unpack(summonArgs50))
                    task.wait(0.1)
                    clickCenterScreenSafe()
                else
                    print("❌ Flowers26 ไม่พอ → ไปฟาร์ม Spring")
                    task.wait(60)
                    GoSpring()
                end
                return
            end

            if Config.LockLV and level < Config.LockLV then
                print("📈 ได้ unit แล้ว แต่เลเวล", level, "ยังไม่ถึง", Config.LockLV, "→ ฟาร์ม Story")
                farmStory()
                return
            end

            if Flowers26 >= 1500 and Flowers26 < 7500 then
                print("🎲 ครบแล้ว สุ่ม 10 | Flowers26:", Flowers26)
                summonEvent:FireServer(unpack(summonArgs))
                task.wait(0.1)
            elseif Flowers26 >= 7500 then
                print("🎲 ครบแล้ว สุ่ม 49 | Flowers26:", Flowers26)
                summonEvent:FireServer(unpack(summonArgs50))
                task.wait(0.1)
                clickCenterScreenSafe()
            else
                local msg = Config.LockLV and "🔒 ถึงเลเวลที่ล็อคแล้ว" or "✅ มีของครบ"
                print(msg .. " → ไปฟาร์ม Spring")
                DelayCheck = 600
                task.wait(60)
                GoSpring()
            end
        end)

        if not ok then warn("❌ Error:", err) end
        task.wait(DelayCheck)
    end
end)
