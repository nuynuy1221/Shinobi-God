repeat task.wait() until game:IsLoaded()
task.wait(2)

--================ CONFIG (REQUIRED) =================--
local Config = getgenv().Config
if not Config then
    warn("❌ ไม่มี Config — ไม่รัน ClaimItem")
    return
end
if Config.ClaimItem ~= true then
    warn("❌ ClaimItem ไม่ได้เปิดจาก Config — ข้ามการรับของ")
    return
end
--===================================================--

--================ PLACE CHECK =================--
local TARGET_PLACE = 16146832113
if game.PlaceId ~= TARGET_PLACE then
    warn("❌ PlaceId ไม่ตรง — ไม่รับของให้")
    return
end
--=============================================--

--================ SERVICES =================--
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")

local CodesEvent = Networking:WaitForChild("CodesEvent", 5)
local DailyRewardEvent = Networking:WaitForChild("DailyRewardEvent")
local MilestonesEvent = Networking:WaitForChild("Milestones"):WaitForChild("MilestonesEvent")
local EnemyMilestonesEvent = Networking
    :WaitForChild("Milestones")
    :WaitForChild("EnemyMilestonesEvent", 5)
local QuestEvent = Networking:WaitForChild("Quests"):WaitForChild("ClaimQuest")
local BattlepassEvent = Networking:WaitForChild("BattlepassEvent")
local ReturningPlayerEvent = Networking:WaitForChild("ReturningPlayerEvent")
local NewPlayerRewardsEvent = Networking:WaitForChild("NewPlayerRewardsEvent")
local APiratesWelcomeEvent = Networking:WaitForChild("APiratesWelcomeEvent", 5)
--============================================--

local player = Players.LocalPlayer
local DELAY = 0.2

local function safeFire(remote, args)
    local ok, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    if not ok then
        warn("❌ FireServer ล้มเหลว:", err)
    end
    task.wait(DELAY)
end

--================ REDEEM CODES ===================
task.spawn(function()
    if not CodesEvent then
        warn("⚠️ ไม่เจอ CodesEvent — ข้ามการรีดีมโค้ด")
        return
    end

    local codes = {
        "Cog5th",
        "223",
        "Liberation",
        "DMCAFree"
    }

    print("เริ่มรีดีมโค้ด...")

    for _, code in ipairs(codes) do
        pcall(function()
            CodesEvent:FireServer(code)
            warn("รีดีมโค้ด: " .. code)
        end)
        task.wait(1.2)
    end

    print("รีดีมโค้ดทั้งหมดเสร็จสิ้น!")
end)

--================ DAILY REWARD (NORMAL) ===================
for _, reward in ipairs({
    {"Special",1},{"Special",2},{"Special",3},
    {"Special",4},{"Special",5},{"Special",6},{"Special",7}
}) do
    safeFire(DailyRewardEvent, {"Claim", reward})
end

--================ DAILY REWARD (ANNIVERSARY) ===================
for day = 1, 28 do
    safeFire(DailyRewardEvent, {"Claim", {"Anniversary", day}})
end

--================ DAILY REWARD (Spring26) ===================
for day = 1, 28 do
    safeFire(DailyRewardEvent, {"Claim", {"Spring26", day}})
end

--================ MILESTONES ===================
for _, milestone in ipairs({5,10,15,20,25,30,35,40,45,50,55,60,65,70,75}) do
    safeFire(MilestonesEvent, {"Claim", milestone})
end

--================ ENEMY MILESTONES ===================
if EnemyMilestonesEvent then
    for i = 1, 12 do
        safeFire(EnemyMilestonesEvent, {"Claim", "Story/Stage" .. i})
        safeFire(EnemyMilestonesEvent, {"Claim", "Raid/Stage" .. i})
    end
else
    warn("⚠️ ไม่เจอ EnemyMilestonesEvent")
end

--================ QUESTS ===================
safeFire(QuestEvent, {"ClaimAll"})

--================ BATTLEPASS ===================
safeFire(BattlepassEvent, {"ClaimAll"})

--================ RETURNING PLAYER ===================
for day = 1, 7 do
    safeFire(ReturningPlayerEvent, {"Claim", day})
end

--================ NEW PLAYER REWARDS ===================
for day = 1, 7 do
    safeFire(NewPlayerRewardsEvent, {"Claim", day})
end

--================ A PIRATES WELCOME ===================
if APiratesWelcomeEvent then
    for day = 1, 7 do
        safeFire(APiratesWelcomeEvent, {"Claim", day})
    end
end

--================ MAIL (QUESTIONNAIRE + CLAIM) ===================
task.spawn(function()
    local GuiService = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local MailEvent = Networking:WaitForChild("Inbox"):WaitForChild("MailEvent", 5)
    if not MailEvent then
        warn("⚠️ ไม่เจอ MailEvent — ข้ามการรับ Mail")
        return
    end

    local ok, ClientReplicationHandler = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientReplicationHandler"))
    end)
    if not ok then
        warn("⚠️ ไม่เจอ ClientReplicationHandler — ข้ามการรับ Mail")
        return
    end

    local mailList = player.PlayerGui:FindFirstChild("Mails")
        and player.PlayerGui.Mails:FindFirstChild("MailRoot")
        and player.PlayerGui.Mails.MailRoot.Holder.CategoriesContainer.MailList
    if not mailList then
        warn("⚠️ ไม่เจอ MailList UI — ข้ามการรับ Mail")
        return
    end

    local function clickMail(button)
        button.Selectable = true
        GuiService.SelectedCoreObject = button
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.3)
        GuiService.SelectedCoreObject = nil
    end

    local function fireMail(action, id, data)
        local ok2, err = pcall(function()
            if data then
                MailEvent:FireServer(action, id, data)
            else
                MailEvent:FireServer(action, id)
            end
        end)
        if ok2 then
            print("✅ Mail", action, id)
        else
            warn("❌ Mail", action, err)
        end
        task.wait(0.5)
    end

    -- ดึง UUID ทั้งหมด
    local allIDs = {}
    for _, child in pairs(mailList:GetChildren()) do
        local button = child:FindFirstChild("Main") and child.Main:FindFirstChild("Button")
        if button then
            clickMail(button)
            task.wait(0.2)
            local inbox = ClientReplicationHandler.GetData("Inbox")
            if inbox and inbox.Mail and inbox.Mail.ID then
                local id = inbox.Mail.ID
                -- กันซ้ำ
                local exists = false
                for _, v in pairs(allIDs) do
                    if v == id then exists = true break end
                end
                if not exists then
                    print("Found Mail ID:", id)
                    table.insert(allIDs, id)
                end
            end
        end
    end

    print("Total Mail:", #allIDs)

    -- Submit + Claim
    for _, id in pairs(allIDs) do
        fireMail("SubmitQuestionnaire", id, {
            pirate_dynasty_characters_fun = { yes = true },
            exclusive_units_returning = { yes = true },
            better_macro_system = { yes = true },
            why_like_pirate_dynasty = "It new gameplay that i didnt it will come",
            pirate_dynasty_characters_unique = { yes = true },
            pirate_dynasty_enjoyed_cog_5 = { yes = true },
            pirate_dynasty_enjoyed_enemy_waves = { yes = true },
            pirate_dynasty_well_balanced = { yes = true },
            more_gamemodes = { yes = true },
            pvp_revamp = { no = true },
            likes_loadout_systems = { yes = true },
            enjoy_pirate_dynasty = { yes = true },
            pirate_dynasty_enjoyed_boss_fight = { yes = true },
            pirate_dynasty_runs_well = { no = true },
            plays_pvp = { no = true },
            more_difficult_td = { yes = true },
            phased_units = { yes = true },
            vanguard_units_returning = { yes = true },
            pirate_dynasty_too_hard = { no = true },
            questionnaire_thoughts = "",
            pirate_dynasty_enjoyed_capturing_points = { yes = true }
        })

        fireMail("SubmitQuestionnaire", id, {
            funness = 8,
            grind_length_satisfaction = 7,
            new_unit_enjoyment = { strong = true },
            favorite_part = { units = true },
            dmca_ok = { yes = true },
            happy_with_dmca_models = { some = true },
            update_rating = 7,
            prefer_lower_quality = { no = true },
            unit_count_satisfaction = 4,
            suggestions = ""
        })

        fireMail("ClaimMail", id)
    end

    print("✅ Mail: รับของครบทั้งหมด")
end)

print("✅ ClaimItem: รับของทั้งหมดเสร็จเรียบร้อย")

--================ CHECK DAILY UI THEN REJOIN ===================
task.wait(3)

local dailyUI = player:FindFirstChild("PlayerGui")
    and player.PlayerGui:FindFirstChild("DailyRewards")

if dailyUI then
    warn("🔁 พบ DailyRewards → กำลัง Rejoin")
    TeleportService:Teleport(game.PlaceId, player)
else
    print("✅ ไม่พบ DailyRewards → ไม่ต้องรีจอย")
end
