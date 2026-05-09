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
        "150KYT",
        "LATECUSTOMLEVEL",
        "MOONLESS",
        "ExtraWeek",
        "Shinobi",
        "HeIsComing",
        "TooMuchPain"
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

--================ DAILY REWARD (WINTER) ===================
for day = 1, 28 do
    safeFire(DailyRewardEvent, {"Claim", {"Winter", day}})
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
