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
local TARGET_PRESENTS = 300000   -- ✅ จำนวน Presents ที่ต้องการ
local CHECK_DELAY = 60           -- วินาทีต่อการเช็ค
local EXIT_DELAY = 4             -- หน่วงก่อนออก Lobby

-- =========================
-- Loop เช็ค Presents
-- =========================
local alreadyExit = false

task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local presents = player:GetAttribute("Presents26") or 0
        local lv = player:GetAttribute("Level") or 0

        print("🎁 Presents26:", presents, "/", TARGET_PRESENTS)
        print("💠 level:", lv)

        if not Config.LockLV then
            if presents >= TARGET_PRESENTS and not alreadyExit then
                alreadyExit = true
                warn("✅ Presents26 ครบ (" .. presents .. ") → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")

                task.delay(EXIT_DELAY, function()
                    pcall(function()
                        TeleportEvent:FireServer("Lobby")
                    end)
                end)
            end
        elseif lv >= Config.LockLV then
            if presents >= TARGET_PRESENTS and not alreadyExit then
                alreadyExit = true
                warn("✅ Presents26 ครบ (" .. presents .. ") → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")

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

print("✅ Present Checker Loaded")
