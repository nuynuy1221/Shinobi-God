repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่ EquipUnits ให้")
    return
end

local player = game:GetService("Players").LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local equipEvent = rep:WaitForChild("Networking"):WaitForChild("Units"):WaitForChild("EquipEvent")

local targetName1 = "Ackers"
local targetName2 = "Bounty Hunter"

-- Path inventory
local inventoryPath = player.PlayerGui
	:WaitForChild("Windows")
	:WaitForChild("GlobalInventory")
	:WaitForChild("Holder")
	:WaitForChild("LeftContainer")
	:WaitForChild("FakeScrollingFrame")
	:WaitForChild("Items")
local cacheContainer = inventoryPath:WaitForChild("CacheContainer")

local lastEquipped = nil  -- กันยิงซ้ำ

-- ฟังก์ชันค้นหา GUID ของ Ackers
local function findAckersGUID()
	for _, item in ipairs(cacheContainer:GetChildren()) do
		local ok, name = pcall(function()
			return item.Container.Holder.Main.UnitName.Text
		end)

		if ok and name == targetName1 then
			return item.Name -- GUID
		end
	end
	return nil
end

-- ฟังก์ชันค้นหา GUID ของ Hunter
local function findHunterGUID()
	for _, item in ipairs(cacheContainer:GetChildren()) do
		local ok, name = pcall(function()
			return item.Container.Holder.Main.UnitName.Text
		end)

		if ok and name == targetName2 then
			return item.Name -- GUID
		end
	end
	return nil
end
-- Auto loop
local lastEquipped = {
    Ackers = nil,
    Hunter  = nil
}

task.spawn(function()
    while true do
        local guidAckers = findAckersGUID()
        local guidHunter  = findHunterGUID()

        -- Equip Ackers
        if guidAckers then
            if lastEquipped.Ackers ~= guidAckers then
                print("✅ พบ Ackers | GUID =", guidAckers)
                local args = {
                    [1] = "Equip",
                    [2] = guidAckers
                }
                equipEvent:FireServer(unpack(args))
                print("🎯 Equip Ackers สำเร็จ")
                lastEquipped.Ackers = guidAckers
            end
        else
            print("❌ ไม่พบ Ackers — จะเช็คใหม่…")
        end
		
        wait(1)
        -- Equip Hunter
        if guidHunter then
            if lastEquipped.Hunter ~= guidHunter then
                print("✅ พบ Hunter | GUID =", guidHunter)
                local args = {
                    [1] = "Equip",
                    [2] = guidHunter
                }
                equipEvent:FireServer(unpack(args))
                print("🎯 Equip Bounty Hunter สำเร็จ")
                lastEquipped.Hunter = guidHunter
            end
        else
            print("❌ ไม่พบ Hunter — จะเช็คใหม่…")
        end

        task.wait(3)
    end
end)


