repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================
-- GUI HUD
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorfulStatusHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local hudVisible = true

local function createBar(name, posScale, bgColor, emoji)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, posScale, 0)
    frame.Size = UDim2.new(0.85, 0, 0.15, 0)
    frame.BackgroundColor3 = bgColor
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = bgColor:lerp(Color3.new(1, 1, 1), 0.3)
    stroke.Thickness = 3

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = emoji .. " " .. name
    label.ZIndex = 11
    label.Parent = frame

    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MaxTextSize = 28
    textLimit.Parent = label

    return label
end

local userLabel       = createBar("User",       0.18, Color3.fromRGB(52, 152, 219),  "🧑")
local levelLabel      = createBar("Level",      0.36, Color3.fromRGB(46, 204, 113),  "🏆")
local Flowers26Label = createBar("Flowers26", 0.54, Color3.fromRGB(241, 196, 15),  "💐")
local ShinobiGodLabel   = createBar("Shinobi God",   0.72, Color3.fromRGB(231, 76, 60),   "👑")
local memoriaLabel    = createBar("Memoria",    0.90, Color3.fromRGB(155, 89, 182),  "🃏")

-- Toggle HUD (B)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B then
        hudVisible = not hudVisible
        screenGui.Enabled = hudVisible
    end
end)

if player:GetAttribute("HasShinobiGod") == nil then
    player:SetAttribute("HasShinobiGod", false)
end

-- =========================
-- Helper
-- =========================
local function getAttr(list)
    for _, name in ipairs(list) do
        local v = player:GetAttribute(name)
        if v ~= nil then return tonumber(v) or 0 end
    end
    return 0
end

local function getLevel()    return getAttr({"Level","level","PlayerLevel","currentLevel"}) end
local function getFlowers26() return getAttr({"Flowers26","flowers26"}) end
local function hasMemoria()  return player:GetAttribute("WinterMemoriaVanguardPityCompleted") == true end

-- =========================
-- checkShinobi God — throttled loop ทุก 3 วิ
-- เดิมอยู่ใน RenderStepped (60x/วิ!) ลด CPU มาก
-- =========================
local TARGET = "Shinobi God"
local cachedHasShinobiGod = false

local function checkShinobiGod()
    local place = game.PlaceId
    if place == 16277809958 then
        local ok, units = pcall(function()
            return playerGui.Windows.Units.Holder.Main.Units
        end)
        if not ok or not units then return false end
        for _, item in ipairs(units:GetChildren()) do
            local ok2, lbl = pcall(function() return item.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text and lbl.Text:lower():find(TARGET:lower()) then return true end
        end
    elseif place == 16146832113 then
        local ok, cc = pcall(function()
            return playerGui.Windows.GlobalInventory.Holder
                .LeftContainer.FakeScrollingFrame.Items.CacheContainer
        end)
        if not ok or not cc then return false end
        for _, gf in ipairs(cc:GetChildren()) do
            local ok2, lbl = pcall(function() return gf.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text and lbl.Text:lower():find(TARGET:lower()) then return true end
        end
    end
    return false
end

-- Loop แยก: สแกน inventory ทุก 3 วิ แทนทุกเฟรม
task.spawn(function()
    while true do
        pcall(function()
            cachedHasShinobiGod = checkShinobiGod()
            player:SetAttribute("HasShinobiGod", cachedHasShinobiGod)
        end)
        task.wait(3)
    end
end)

-- =========================
-- RenderStepped: อัพแค่ Text — ไม่สแกน inventory แล้ว
-- =========================
RunService.RenderStepped:Connect(function()
    pcall(function()
        userLabel.Text        = "🤖 User : "     .. player.Name
        levelLabel.Text       = "⬆️ Level : "    .. getLevel()
        Flowers26Label.Text  = "💐 Flowers26 : " .. getFlowers26()
        ShinobiGodLabel.Text    = "👑 Shinobi God : " .. (cachedHasShinobiGod and "✅" or "❌")
        memoriaLabel.Text     = "🃏 Memoria : "   .. (hasMemoria() and "✅" or "❌")
    end)
end)

print("HUD Loaded | กด B เพื่อเปิด/ปิด")
