task.spawn(function()

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local SettingsEvent = ReplicatedStorage
		:WaitForChild("Networking")
		:WaitForChild("Settings")
		:WaitForChild("SettingsEvent")

	--=========================
	-- CHECK COLOR (SETTING)
	--=========================
	local function isOff(uiGradient)

		if not uiGradient or not uiGradient:IsA("UIGradient") then
			return false
		end

		local keypoints = uiGradient.Color.Keypoints
		if #keypoints == 0 then
			return false
		end

		local r,g,b = 0,0,0

		for _,kp in ipairs(keypoints) do
			r += kp.Value.R
			g += kp.Value.G
			b += kp.Value.B
		end

		r /= #keypoints
		g /= #keypoints
		b /= #keypoints

		-- ถ้าเขียวไม่เด่น = OFF
		return (g < r or g < b)
	end

	--=========================
	-- SETTINGS (เปิด Toggle ต่างๆ)
	--=========================
	local settingsList = {
		{ Name = "AutoSkipWaves", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Gameplay.AutoSkipWaves.Slider.UIStroke.UIGradient },
		{ Name = "DisableCameraShake", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableCameraShake.Slider.UIStroke.UIGradient },
		{ Name = "DisableDepthOfField", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableDepthOfField.Slider.UIStroke.UIGradient },
		{ Name = "HideFamiliars", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.HideFamiliars.Slider.UIStroke.UIGradient },
		{ Name = "LowDetailMode", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.LowDetailMode.Slider.UIStroke.UIGradient },
		{ Name = "DisableGlobalMessages", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.DisableGlobalMessages.Slider.UIStroke.UIGradient },
		{ Name = "SkipSummonAnimation", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.SkipSummonAnimation.Slider.UIStroke.UIGradient },
		{ Name = "DisableDamageIndicators", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableDamageIndicators.Slider.UIStroke.UIGradient },
		{ Name = "DisableVisualEffects", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableVisualEffects.Slider.UIStroke.UIGradient },
		{ Name = "DisableEnemyTags", Path = game:GetService("Players").LocalPlayer.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Enemies.DisableEnemyTags.Slider.UIGradient },
	}

	for _,setting in ipairs(settingsList) do
		if isOff(setting.Path) then
			print("🔥 TOGGLE:",setting.Name)
			SettingsEvent:FireServer("Toggle",setting.Name)
			task.wait(0.08)
		end
	end

	--=========================
	-- 🔥 FORCE AUTO SELL (Memoria + Unit)
	--=========================
	task.wait(0.5)

	local raritiesList = {"Rare","Epic","Legendary","Mythic"}

	for _,rarity in ipairs(raritiesList) do

		-- Memoria
		SettingsEvent:FireServer("ChangeValue", {
			["Value"] = rarity,
			["Name"] = "AutoSellMemorias",
			["DeepValue"] = true
		})
		print("🧠 Sell Memoria:",rarity)
		task.wait(0.1)

		-- Unit
		SettingsEvent:FireServer("ChangeValue", {
			["Value"] = rarity,
			["Name"] = "AutoSellUnits",
			["DeepValue"] = true
		})
		print("⚔️ Sell Unit:",rarity)
		task.wait(0.1)
	end

	print("✅ ตั้งค่า Auto Sell ครบแล้ว")

end)
