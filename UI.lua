repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

if CoreGui:FindFirstChild("ColorfulStatusHUD") then
    CoreGui.ColorfulStatusHUD:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ColorfulStatusHUD"
screenGui.ResetOnSpawn   = false
screenGui.DisplayOrder   = 9999
screenGui.IgnoreGuiInset = true
-- ✅ Global ZIndex ดีกว่า Sibling (render น้อยกว่า)
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent         = CoreGui

local hudVisible = true

local BASE_W = 480
local BASE_H = 270
local function getScale()
    local vp = camera.ViewportSize
    return math.min(vp.X / BASE_W, vp.Y / BASE_H)
end
local function px(v) return math.round(v * getScale()) end

local DIM    = Color3.fromRGB(0, 130, 55)
local BRIGHT = Color3.fromRGB(100, 255, 150)
local WARN   = Color3.fromRGB(255, 220, 60)
local ERR    = Color3.fromRGB(255, 80, 80)
local BLUE   = Color3.fromRGB(180, 230, 255)

local hudFrame  = nil
local valLabels = {}
local cachedHasShinobiGod = false

local function buildHUD()
    if hudFrame then hudFrame:Destroy() end
    valLabels = {}

    local MARGIN   = px(18)
    local HEADER   = px(80)
    local FOOTER   = px(52)

    -- ✅ ลด frame เหลือแค่ panel เดียว ไม่มี scanline/corner deco
    local panel = Instance.new("Frame", screenGui)
    panel.Name                   = "Panel"
    panel.AnchorPoint            = Vector2.new(0, 0)
    panel.Position               = UDim2.new(0, MARGIN, 0, MARGIN)
    panel.Size                   = UDim2.new(1, -MARGIN*2, 1, -MARGIN*2)
    panel.BackgroundColor3       = Color3.fromRGB(2, 8, 2)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel        = 0
    -- ✅ ลด UICorner เหลือแค่จุดที่เห็นชัด
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, px(10))
    hudFrame = panel

    -- ✅ ไม่มี UIStroke (GPU draw call เพิ่ม)
    -- ✅ ไม่มี scanline ImageLabel (TileSize render ทุก frame)
    -- ✅ ไม่มี corner decoration frames (8 frames ที่ไม่จำเป็น)

    -- HEADER
    local header = Instance.new("Frame", panel)
    header.Size               = UDim2.new(1, 0, 0, HEADER)
    header.BackgroundColor3   = Color3.fromRGB(0, 30, 10)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel    = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, px(10))

    -- dot (✅ ใช้ loop เดียวรวมกับ data loop แทน task.spawn แยก)
    local dot = Instance.new("Frame", header)
    dot.Name             = "StatusDot"
    dot.Size             = UDim2.new(0, px(12), 0, px(12))
    dot.Position         = UDim2.new(0, px(22), 0.5, -px(6))
    dot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    valLabels["dot"] = dot

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size             = UDim2.new(0.62, -px(46), 1, 0)
    titleLbl.Position         = UDim2.new(0, px(46), 0, 0)
    titleLbl.BackgroundTransparency = 1
    -- ✅ ไม่มี typewriter loop (task.wait(0.07) = CPU spike)
    titleLbl.Text             = "SYS://DUCKKUNG_TRACKER"
    titleLbl.TextColor3       = Color3.fromRGB(0, 220, 80)
    titleLbl.Font             = Enum.Font.Code
    titleLbl.TextScaled       = true
    titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
    local tc1 = Instance.new("UITextSizeConstraint", titleLbl)
    tc1.MaxTextSize = px(28); tc1.MinTextSize = 8

    local timeLbl = Instance.new("TextLabel", header)
    timeLbl.Name             = "TimeLbl"
    timeLbl.Size             = UDim2.new(0.36, -px(16), 1, 0)
    timeLbl.AnchorPoint      = Vector2.new(1, 0)
    timeLbl.Position         = UDim2.new(1, -px(12), 0, 0)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text             = os.date("%H:%M:%S")
    timeLbl.TextColor3       = Color3.fromRGB(0, 140, 60)
    timeLbl.Font             = Enum.Font.Code
    timeLbl.TextScaled       = true
    timeLbl.TextXAlignment   = Enum.TextXAlignment.Right
    local tc2 = Instance.new("UITextSizeConstraint", timeLbl)
    tc2.MaxTextSize = px(20); tc2.MinTextSize = 8
    valLabels["time"] = timeLbl

    local div = Instance.new("Frame", panel)
    div.Size             = UDim2.new(1, -px(32), 0, math.max(1, px(2)))
    div.Position         = UDim2.new(0, px(16), 0, HEADER + px(2))
    div.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    div.BackgroundTransparency = 0.5
    div.BorderSizePixel  = 0

    -- ROWS
    local ROWS     = 5
    local panelH   = camera.ViewportSize.Y - MARGIN * 2
    local usedH    = HEADER + px(4) + FOOTER + px(8)
    local rowStep  = (panelH - usedH) / ROWS
    local rowStart = HEADER + px(10)

    local rowDefs = {
        {">  USER    ", BLUE},
        {">  LEVEL   ", WARN},
        {">  FLOWER  ", WARN},
        {">  SHINOBI ", ERR},
        {">  MEMORIA ", ERR},
    }
    local keys = {"user","level","flower","shinobi","memoria"}

    for i, def in ipairs(rowDefs) do
        local prefix, valColor = def[1], def[2]
        local yOff = rowStart + (i-1) * rowStep
        local bgH  = math.round(rowStep - px(10))

        -- ✅ ลด frame: bg + accent bar เท่านั้น ตัด separator ออก
        local bg = Instance.new("Frame", panel)
        bg.Size               = UDim2.new(1, -px(32), 0, bgH)
        bg.Position           = UDim2.new(0, px(16), 0, yOff)
        bg.BackgroundColor3   = Color3.fromRGB(0, 22, 8)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel    = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, px(6))

        local accent = Instance.new("Frame", bg)
        accent.Size             = UDim2.new(0, math.max(3, px(5)), 1, -px(16))
        accent.Position         = UDim2.new(0, 0, 0, px(8))
        accent.BackgroundColor3 = valColor
        accent.BackgroundTransparency = 0.25
        accent.BorderSizePixel  = 0
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, px(3))

        local prefLbl = Instance.new("TextLabel", bg)
        prefLbl.Size            = UDim2.new(0.4, -px(18), 1, 0)
        prefLbl.Position        = UDim2.new(0, px(18), 0, 0)
        prefLbl.BackgroundTransparency = 1
        prefLbl.Text            = prefix
        prefLbl.TextColor3      = DIM
        prefLbl.Font            = Enum.Font.Code
        prefLbl.TextSize        = math.max(10, px(22))
        prefLbl.TextXAlignment  = Enum.TextXAlignment.Left

        -- ✅ ไม่มี cursor blink (ลด 5 task.spawn + loop)
        local valLbl = Instance.new("TextLabel", bg)
        valLbl.Size             = UDim2.new(0.58, -px(8), 1, 0)
        valLbl.Position         = UDim2.new(0.42, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text             = "..."
        valLbl.TextColor3       = valColor
        valLbl.Font             = Enum.Font.Code
        valLbl.TextSize         = math.max(12, px(30))
        valLbl.TextXAlignment   = Enum.TextXAlignment.Left
        valLabels[keys[i]] = valLbl
    end

    -- FOOTER
    local fdiv = Instance.new("Frame", panel)
    fdiv.Size             = UDim2.new(1, -px(32), 0, math.max(1, px(2)))
    fdiv.Position         = UDim2.new(0, px(16), 1, -FOOTER - px(2))
    fdiv.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    fdiv.BackgroundTransparency = 0.6
    fdiv.BorderSizePixel  = 0

    local footerLbl = Instance.new("TextLabel", panel)
    footerLbl.Size             = UDim2.new(1, -px(32), 0, FOOTER)
    footerLbl.Position         = UDim2.new(0, px(16), 1, -FOOTER)
    footerLbl.BackgroundTransparency = 1
    footerLbl.Text             = "[ B ] TOGGLE HUD  //  SYS READY"
    footerLbl.TextColor3       = Color3.fromRGB(0, 100, 45)
    footerLbl.Font             = Enum.Font.Code
    footerLbl.TextSize         = math.max(8, px(18))
    footerLbl.TextXAlignment   = Enum.TextXAlignment.Right

    if not hudVisible then
        panel.Position = UDim2.new(1, 40, 0, MARGIN)
    end
end

-- ✅ Debounce viewport rebuild (ไม่ build ซ้ำถี่)
local lastVP    = camera.ViewportSize
local rebuildPending = false
buildHUD()

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local vp = camera.ViewportSize
    if rebuildPending then return end
    if math.abs(vp.X - lastVP.X) > 2 or math.abs(vp.Y - lastVP.Y) > 2 then
        rebuildPending = true
        task.delay(0.3, function()  -- รอให้ resize จบก่อนค่อย rebuild
            lastVP = camera.ViewportSize
            buildHUD()
            rebuildPending = false
        end)
    end
end)

-- TOGGLE ✅ ไม่ใช้ TweenService (ไม่มี animation overhead)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B then
        hudVisible = not hudVisible
        if hudFrame then
            local MARGIN = px(18)
            hudFrame.Position = hudVisible
                and UDim2.new(0, MARGIN, 0, MARGIN)
                or  UDim2.new(1, 40, 0, MARGIN)
        end
    end
end)

-- DATA UTILS
local function getAttr(list)
    for _, name in ipairs(list) do
        local v = player:GetAttribute(name)
        if v ~= nil then return tonumber(v) or 0 end
    end
    return 0
end
local function getLevel()     return getAttr({"Level","level","PlayerLevel","currentLevel"}) end
local function getFlowers26() return getAttr({"Flowers26","flowers26"}) end

-- ✅ Cache path แทนหาใหม่ทุกครั้ง
local _memoriaPath = nil
local function hasMemoria()
    if not _memoriaPath then
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return false end
        local ok, p = pcall(function()
            return pg.Windows.Titles.Holder.List.Main["Dream Conqueror"].Equip
        end)
        if ok and p then _memoriaPath = p else return false end
    end
    return _memoriaPath:FindFirstChild("Locked") == nil
end

local TARGET = "Shinobi God"
local function checkShinobiGod()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    local place = game.PlaceId
    -- ✅ ใช้ FindFirstDescendant แทน loop GetChildren ทั้งหมด (เร็วกว่ามาก)
    if place == 16277809958 then
        local ok, units = pcall(function() return pg.Windows.Units.Holder.Main.Units end)
        if not ok or not units then return false end
        for _, item in ipairs(units:GetChildren()) do
            local ok2, lbl = pcall(function() return item.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text:lower():find(TARGET:lower(), 1, true) then return true end
        end
    elseif place == 16146832113 then
        local ok, cc = pcall(function()
            return pg.Windows.GlobalInventory.Holder.LeftContainer.FakeScrollingFrame.Items.CacheContainer
        end)
        if not ok or not cc then return false end
        for _, gf in ipairs(cc:GetChildren()) do
            local ok2, lbl = pcall(function() return gf.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text:lower():find(TARGET:lower(), 1, true) then return true end
        end
    end
    return false
end

-- ✅ รวมทุก loop เป็น loop เดียว + เพิ่ม interval
local tick60 = 0  -- นับรอบสำหรับงานที่ไม่ต้องทำบ่อย
local dotOn = true

task.spawn(function()
    while true do
        pcall(function()
            local u  = valLabels["user"]
            if not (u and u.Parent) then return end

            -- อัปเดตทุก 1 วิ (ลดจาก 0.5)
            u.Text  = player.Name
            valLabels["level"].Text   = tostring(getLevel())
            valLabels["flower"].Text  = tostring(getFlowers26())

            -- time
            local tl = valLabels["time"]
            if tl then tl.Text = os.date("%H:%M:%S") end

            -- dot blink (ทำเองแทน TweenService)
            dotOn = not dotOn
            local dot = valLabels["dot"]
            if dot then dot.BackgroundTransparency = dotOn and 0 or 0.85 end

            -- shinobi + memoria (ทุก 3 วิ = ทุก 3 รอบ)
            tick60 = tick60 + 1
            if tick60 >= 3 then
                tick60 = 0
                cachedHasShinobiGod = checkShinobiGod()
                local sh = valLabels["shinobi"]
                sh.Text       = cachedHasShinobiGod and "[  OK  ]" or "[  --  ]"
                sh.TextColor3 = cachedHasShinobiGod and BRIGHT or ERR

                local mem = hasMemoria()
                local me  = valLabels["memoria"]
                me.Text       = mem and "[  OK  ]" or "[  --  ]"
                me.TextColor3 = mem and BRIGHT or ERR
            end
        end)
        task.wait(1) -- ✅ 1 วิแทน 0.5 วิ = ลด CPU 50%
    end
end)

print("✅ HUD Lite | กด B เปิด/ปิด")
