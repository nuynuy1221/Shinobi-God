repeat task.wait() until game:IsLoaded()
task.wait(1.5)

-- =========================
-- เช็ค PlaceId (บังคับ)
-- =========================
local TARGET_PLACE = 16277809958
if game.PlaceId ~= TARGET_PLACE then
    warn("❌ ผิดแมพ! ต้องอยู่ในแมพฟาร์มเท่านั้น")
    return
end

if getgenv().Config == nil then
    getgenv().Config = {
        LockLV = nil,
        FarmOnly = false,
        FarmOnlyFlowers26 = 0
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = {
        LockLV = nil,
        FarmOnly = false,
        FarmOnlyFlowers26 = 0
    }
    getgenv().Config = Config
end

if type(Config.LockLV) ~= "number" then
    Config.LockLV = nil
end

-- =========================
-- Services
-- =========================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Networking = RS:WaitForChild("Networking", 10)
local TeleportEvent = Networking:WaitForChild("TeleportEvent", 8)

if not TeleportEvent then
    warn("❌ ไม่เจอ TeleportEvent")
    return
end

-- =========================
-- CONFIG
-- =========================
local TARGET_PRESENTS = 300000
local CHECK_DELAY     = 60
local EXIT_DELAY      = 4

-- =========================
-- เช็ค SpringXP Max
-- =========================
local function isSpringXPMax()
    local ok, result = pcall(function()
        local xpText = player.PlayerGui
            :WaitForChild("SpringEventMenu", 5)
            :WaitForChild("Frame", 5)
            :WaitForChild("Holder", 5)
            :WaitForChild("Content", 5)
            :WaitForChild("Column", 5)
            :WaitForChild("Header", 5)
            :WaitForChild("RightGroup", 5)
            :WaitForChild("XpProgressBar", 5)
            :WaitForChild("BarTrack", 5)
            :WaitForChild("XpText", 5)

        return xpText and xpText.Text == "Max level · 3000 XP earned"
    end)

    if ok and result then
        return true
    end

    -- SpringEventMenu ยังไม่เปิด/โหลด = ยังไม่ Max
    return false
end

-- =========================
-- Loop เช็ค Level (ถ้าเริ่มต่ำกว่า 30)
-- =========================
local alreadyExit    = false
local initialLevel   = player:GetAttribute("Level") or 0
local shouldWatchLevel = initialLevel < 30

if shouldWatchLevel then
    task.spawn(function()
        while true do
            task.wait(10)
            local lv = player:GetAttribute("Level") or 0
            if lv >= 30 then
                warn("🎓 Level ถึง 30 → TP กลับ Lobby")
                pcall(function()
                    TeleportEvent:FireServer("Lobby")
                end)
                break
            end
        end
    end)
else
    print("✅ เริ่มต้นเลเวล " .. initialLevel .. " ≥ 30 → ไม่ต้อง watch")
end

-- =========================
-- Loop หลัก
-- =========================
task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local Flowers26 = player:GetAttribute("Flowers26") or 0
        local lv        = player:GetAttribute("Level") or 0
        local xpMax     = isSpringXPMax()

        print("💐 Flowers26:", Flowers26, "/", TARGET_PRESENTS)
        print("💠 Level:", lv)
        print("🌸 SpringXP Max:", xpMax and "✅ Max" or "❌ ยังไม่ Max")

        local flowers26Done = Config.FarmOnly
            and Flowers26 >= Config.FarmOnlyFlowers26
            or (not Config.FarmOnly and Flowers26 >= TARGET_PRESENTS)
        local levelDone = Config.LockLV and lv >= Config.LockLV and lv > initialLevel

        if (flowers26Done or levelDone) and not alreadyExit then
            -- ✅ เช็ค SpringXP ก่อนออก
            if not xpMax then
                warn("⏳ Flowers26/Level ครบแล้ว แต่ SpringXP ยังไม่ Max → รอต่อ")
            else
                alreadyExit = true
                local reason = flowers26Done
                    and "🌾 Flowers26 ครบ (" .. Flowers26 .. "/" .. TARGET_PRESENTS .. ")"
                    or "🎓 Level ถึง (" .. lv .. "/" .. Config.LockLV .. ")"
                warn(reason .. " + SpringXP Max ✅ → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")
                task.delay(EXIT_DELAY, function()
                    pcall(function()
                        TeleportEvent:FireServer("Lobby")
                    end)
                end)
            end
        else
            print("⏳ ฟาร์มต่อ | Flowers26:", Flowers26, "| Level:", lv, "| SpringXP Max:", xpMax)
        end
    end
end)

print("✅ Flowers26 + SpringXP Checker Loaded")
