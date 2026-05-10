repeat task.wait() until game:IsLoaded()
task.wait(2)

-- ================= CONFIG CHECK =================
local Config = getgenv().Config

if not Config then
	warn("❌ ไม่มี Config — ข้ามการซื้อทั้งหมด")
	return
end
-- ===============================================

-- ================= PLACE CHECK =================
local TARGET_PLACE = 16146832113
if game.PlaceId ~= TARGET_PLACE then
	warn("❌ PlaceId ไม่ตรง — ไม่ทำงาน")
	return
end
-- ===============================================

-- ================= SERVICES =================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopEvent = ReplicatedStorage
	:WaitForChild("Networking")
	:WaitForChild("Shop")
	:WaitForChild("PurchaseItem")
-- ============================================

-- ================= BUY FUNCTION =================
local function buyItem(shopName, itemName, amountPerTime, times)
	for i = 1, times do
		local success, err = pcall(function()
			ShopEvent:FireServer(
				shopName,
				itemName,
				amountPerTime
			)
		end)

		if not success then
			warn("❌ ซื้อไม่สำเร็จ:", itemName, "| รอบ:", i, "| Error:", err)
		end

		task.wait(0.15) -- กัน server หน่วง / block
	end

	print("✅ ซื้อสำเร็จ:", itemName, "x", amountPerTime * times)
end
-- ===============================================

-- ================= BUY TRAIT REROLL =================
if Config.BuyTraitReroll == true then
	buyItem(
		"Spring Shop",
		"TraitRerolls",
		5,   -- ซื้อครั้งละ 5
		40   -- 40 ครั้ง
	)
else
	warn("⏭️ ปิด BuyTraitReroll")
end
-- ==================================================

-- ================= BUY MEMORIA SHARDS =================
if Config.BuyMemoriaShards == true then
	buyItem(
		"Spring Shop",
		"MemoriaShards",
		5,   -- ซื้อครั้งละ 5
		40   -- 40 ครั้ง
	)
else
	warn("⏭️ ปิด BuyMemoriaShards")
end
-- =====================================================

print("🎉 Script ซื้อของทำงานเสร็จทั้งหมด")
