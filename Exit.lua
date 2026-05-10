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
        LockLV = nil
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = {
        LockLV = nil
    }
    getgenv().Config = Config
end

-- LockLV ต้องเป็นตัวเลขเท่านั้น
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
local TARGET_PRESENTS = 150000   -- ✅ จำนวน Presents ที่ต้องการ
local CHECK_DELAY = 60           -- วินาทีต่อการเช็ค
local EXIT_DELAY = 4             -- หน่วงก่อนออก Lobby

-- =========================
-- Loop เช็ค Presents
-- =========================
local alreadyExit = false

-- ✅ เช็คเลเวลตอนแรก ถ้าต่ำกว่า 30 ให้ watch ด้วย
local initialLevel = player:GetAttribute("Level") or 0
local shouldWatchLevel = initialLevel < 30

if shouldWatchLevel then
    task.spawn(function()
        while true do
            task.wait(10)
            local lv = player:GetAttribute("Level") or 0
            if lv >= 30 then
                warn("🎓 Level ถึง 30 (จากที่เริ่มต่ำกว่า) → TP กลับ Lobby")
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

task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local Flowers26 = player:GetAttribute("Flowers26") or 0
        local lv = player:GetAttribute("Level") or 0

        print("💐 Flowers26:", Flowers26, "/", TARGET_PRESENTS)
        print("💠 level:", lv)

        if not Config.LockLV then
            if Flowers26 >= TARGET_PRESENTS and not alreadyExit then
                alreadyExit = true
                warn("✅ Flowers26 ครบ (" .. presents .. ") → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")

                task.delay(EXIT_DELAY, function()
                    pcall(function()
                        TeleportEvent:FireServer("Lobby")
                    end)
                end)
            end
        elseif lv >= Config.LockLV then
            if Flowers26 >= TARGET_PRESENTS and not alreadyExit then
                alreadyExit = true
                warn("✅ Flowers26 ครบ (" .. presents .. ") → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")

                task.delay(EXIT_DELAY, function()
                    pcall(function()
                        TeleportEvent:FireServer("Lobby")
                    end)
                end)
            end
        else
            print("❌ เวลยังไม่ถึง Config ฟาร์มต่อ")
        end
    end
end)

print("✅ Flowers26 Checker Loaded")
