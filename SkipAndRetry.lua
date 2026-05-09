repeat task.wait() until game:IsLoaded()
task.wait(2)

--== เช็ค PlaceId ก่อนรัน ==--
local targetPlace = 16277809958
if game.PlaceId ~= targetPlace then
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")

-- =========================
-- ฟังก์ชันเช็ค Custom Level
-- =========================
local function isCustomLevel()
    local ok, text = pcall(function()
        return player.PlayerGui.Guides.List.StageInfo.StageFrame.StageType.Text
    end)
    if ok and text == "Custom Level" then
        return true
    end
    return false
end

-- =========================
-- ฟังก์ชัน Skip Wave
-- =========================
local function pressSkipButton()
    pcall(function()
        Networking:WaitForChild("SkipWaveEvent"):FireServer("Skip")
    end)
end

-- =========================
-- ฟังก์ชัน Vote Retry
-- =========================
local function pressRetryButton()
    pcall(function()
        Networking:WaitForChild("EndScreen"):WaitForChild("VoteEvent"):FireServer("Retry")
    end)
end

-- =========================
-- ฟังก์ชัน Vote MatchRestart
-- =========================
local function voteMatchRestart()
    pcall(function()
        Networking:WaitForChild("MatchRestartSettingEvent"):FireServer("Vote")
    end)
end

-- =========================
-- ฟังก์ชันเช็ค Wave
-- =========================
local function getWave()
    local ok, waveObj = pcall(function()
        return playerGui.HUD.Map.WavesAmount
    end)
    if ok and waveObj and waveObj.ContentText then
        local waveNumberStr = waveObj.ContentText:match("^(%d+)")
        return tonumber(waveNumberStr) or 0
    end
    return 0
end

-- =========================
-- Loop สำหรับ Skip Wave (ยกเว้น Custom Level)
-- =========================
task.spawn(function()
    while true do
        task.wait(2)
        
        if not isCustomLevel() then
            pressSkipButton()
        end
        -- ถ้าเป็น Custom Level จะข้ามการกด Skip อัตโนมัติ
    end
end)

-- =========================
-- Loop สำหรับ Retry + Vote MatchRestart
-- =========================
task.spawn(function()
    while true do
        task.wait(15)
        pressRetryButton()
        
        local wave = getWave()
        if wave >= 140 then
            task.wait(5)
            voteMatchRestart()
        end
    end
end)

print("✅ สคริปต์ Skip Wave ทำงานแล้ว (ข้าม Skip เมื่อเป็น Custom Level)")
