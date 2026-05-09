repeat task.wait() until game:IsLoaded()
task.wait(1)

-- =======================
-- เช็ค PlaceId ก่อนเสมอ
-- =======================
local targetPlace = 18219125606
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง — ไม่รันสคริปต์")
    return
end

local AFKReturn = {
    [1] = "TeleportMain"
}

game:GetService("ReplicatedStorage").Networking.AFKEvent:FireServer(unpack(AFKReturn))
