repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
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
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = CoreGui

local hudVisible = true

-- =========================
-- SCALE (อ้างอิง 1280x720 → ตัวใหญ่ขึ้นมาก)
-- =========================
local BASE_W = 480
local BASE_H = 270

local function getScale()
    local vp = camera.ViewportSize
    return math.min(vp.X / BASE_W, vp.Y / BASE_H)
end

local function px(v)
    return math.round(v * getScale())
end

local DIM    = Color3.fromRGB(0, 130, 55)
local BRIGHT = Color3.fromRGB(100, 255, 150)
local WARN   = Color3.fromRGB(255, 220, 60)
local ERR    = Color3.fromRGB(255, 80, 80)
local BLUE   = Color3.fromRGB(180, 230, 255)

local hudFrame   = nil
local valLabels  = {}
local cachedHasShinobiGod = false

local function buildHUD()
    if hudFrame then hudFrame:Destroy() end
    valLabels = {}

    local S       = getScale()
    local MARGIN  = px(18)
    local HEADER  = px(80)
    local ROW_H   = px(90)    -- ใหญ่มาก
    local FOOTER  = px(52)

    -- PANEL
    local panel = Instance.new("Frame", screenGui)
    panel.Name                   = "Panel"
    panel.AnchorPoint            = Vector2.new(0, 0)
    panel.Position               = UDim2.new(0, MARGIN, 0, MARGIN)
    panel.Size                   = UDim2.new(1, -MARGIN*2, 1, -MARGIN*2)
    panel.BackgroundColor3       = Color3.fromRGB(2, 8, 2)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel        = 0
    panel.ZIndex                 = 10
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, px(12))
    hudFrame = panel

    local stroke = Instance.new("UIStroke", panel)
    stroke.Color        = Color3.fromRGB(0, 200, 80)
    stroke.Thickness    = math.max(1, px(2))
    stroke.Transparency = 0.3

    local scanline = Instance.new("ImageLabel", panel)
    scanline.Size               = UDim2.new(1, 0, 1, 0)
    scanline.BackgroundTransparency = 1
    scanline.Image              = "rbxassetid://6372755229"
    scanline.ImageColor3        = Color3.fromRGB(0, 255, 80)
    scanline.ImageTransparency  = 0.96
    scanline.ScaleType          = Enum.ScaleType.Tile
    scanline.TileSize           = UDim2.new(0, px(5), 0, px(5))
    scanline.ZIndex             = 11

    -- CORNER DECO
    local CSIZ = px(28)
    local CTHK = math.max(2, px(3))
    local function makeCorner(ax, ay, px2, py2)
        local c = Instance.new("Frame", panel)
        c.Size = UDim2.new(0, CSIZ, 0, CSIZ)
        c.AnchorPoint = Vector2.new(ax, ay)
        c.Position = UDim2.new(px2, 0, py2, 0)
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0; c.ZIndex = 15

        local h = Instance.new("Frame", c)
        h.Size = UDim2.new(1, 0, 0, CTHK)
        h.Position = UDim2.new(0, 0, ay == 0 and 0 or 1, ay == 0 and 0 or -CTHK)
        h.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        h.BorderSizePixel = 0; h.ZIndex = 16

        local v = Instance.new("Frame", c)
        v.Size = UDim2.new(0, CTHK, 1, 0)
        v.Position = UDim2.new(ax == 0 and 0 or 1, ax == 0 and 0 or -CTHK, 0, 0)
        v.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        v.BorderSizePixel = 0; v.ZIndex = 16
    end
    makeCorner(0,0,0,0); makeCorner(1,0,1,0)
    makeCorner(0,1,0,1); makeCorner(1,1,1,1)

    -- ===== HEADER =====
    local header = Instance.new("Frame", panel)
    header.Size               = UDim2.new(1, 0, 0, HEADER)
    header.BackgroundColor3   = Color3.fromRGB(0, 30, 10)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel    = 0; header.ZIndex = 12
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, px(12))
    local hFix = Instance.new("Frame", header)
    hFix.Size = UDim2.new(1,0,0,px(12))
    hFix.Position = UDim2.new(0,0,1,-px(12))
    hFix.BackgroundColor3 = Color3.fromRGB(0,30,10)
    hFix.BackgroundTransparency = 0.3
    hFix.BorderSizePixel = 0; hFix.ZIndex = 12

    local dot = Instance.new("Frame", header)
    dot.Size             = UDim2.new(0, px(12), 0, px(12))
    dot.Position         = UDim2.new(0, px(22), 0.5, -px(6))
    dot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    dot.BorderSizePixel  = 0; dot.ZIndex = 13
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        while dot and dot.Parent do
            TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine),
                {BackgroundTransparency = 0.85}):Play()
            task.wait(0.9)
            TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine),
                {BackgroundTransparency = 0}):Play()
            task.wait(0.9)
        end
    end)

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size             = UDim2.new(0.62, -px(46), 1, 0)
    titleLbl.Position         = UDim2.new(0, px(46), 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text             = "SYS://DUCKKUNG_TRACKER"
    titleLbl.TextColor3       = Color3.fromRGB(0, 220, 80)
    titleLbl.Font             = Enum.Font.Code
    titleLbl.TextScaled       = true   -- FIX: หดอัตโนมัติ
    titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
    titleLbl.ZIndex           = 13
	local tc1 = Instance.new("UITextSizeConstraint", titleLbl)
   tc1.MaxTextSize = px(28)   -- ไม่ใหญ่เกินนี้
   tc1.MinTextSize = 8

    local timeLbl = Instance.new("TextLabel", header)
    timeLbl.Size             = UDim2.new(0.36, -px(16), 1, 0)
    timeLbl.AnchorPoint      = Vector2.new(1, 0)
    timeLbl.Position         = UDim2.new(1, -px(12), 0, 0)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text             = os.date("%H:%M:%S")
    timeLbl.TextColor3       = Color3.fromRGB(0, 140, 60)
    timeLbl.Font             = Enum.Font.Code
    timeLbl.TextScaled       = true   -- FIX
    timeLbl.TextXAlignment   = Enum.TextXAlignment.Right
    timeLbl.ZIndex           = 13
    local tc2 = Instance.new("UITextSizeConstraint", timeLbl)
    tc2.MaxTextSize = px(20)
    tc2.MinTextSize = 8

    -- title width = พื้นที่ที่เหลือ (ก่อน time)
    titleLbl.Size = UDim2.new(1, -(px(46) + px(200) + px(24)), 1, 0)

    -- Typewriter loop สำหรับ title
    task.spawn(function()
        local full = "SYS://DUCKKUNG_TRACKER"
        while titleLbl and titleLbl.Parent do
            -- พิมพ์ทีละตัว
            for i = 1, #full do
                if not (titleLbl and titleLbl.Parent) then return end
                titleLbl.Text = string.sub(full, 1, i) .. "_"
                task.wait(0.07)   -- ความเร็วพิมพ์ (วินาที/ตัว)
            end
            -- หยุดสักครู่ตอนพิมพ์ครบ
            titleLbl.Text = full .. "_"
            task.wait(3)
            -- ลบทีละตัว
            for i = #full, 0, -1 do
                if not (titleLbl and titleLbl.Parent) then return end
                titleLbl.Text = string.sub(full, 1, i) .. "_"
                task.wait(0.04)   -- ลบเร็วกว่าพิมพ์
            end
            -- หยุดก่อนเริ่มใหม่
            task.wait(0.5)
        end
    end)

    local div = Instance.new("Frame", panel)
    div.Size             = UDim2.new(1, -px(32), 0, math.max(1, px(2)))
    div.Position         = UDim2.new(0, px(16), 0, HEADER + px(2))
    div.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    div.BackgroundTransparency = 0.5
    div.BorderSizePixel  = 0; div.ZIndex = 12

    -- ===== ROWS =====
    local ROWS      = 5
    local panelH    = camera.ViewportSize.Y - MARGIN * 2
    local usedH     = HEADER + px(4) + FOOTER + px(8)
    local freeH     = panelH - usedH
    local rowStep   = freeH / ROWS
    local rowStartY = HEADER + px(10)

    local rowDefs = {
        {">  USER    ", "...",  BLUE},
        {">  LEVEL   ", "...",  WARN},
        {">  FLOWER  ", "...",  WARN},
        {">  SHINOBI ", "...",  ERR},
        {">  MEMORIA ", "...",  ERR},
    }
    local keys = {"user","level","flower","shinobi","memoria"}

    for i, def in ipairs(rowDefs) do
        local prefix, _, valColor = def[1], def[2], def[3]
        local yOff = rowStartY + (i - 1) * rowStep
        local bgH  = math.round(rowStep - px(10))

        local bg = Instance.new("Frame", panel)
        bg.Size             = UDim2.new(1, -px(32), 0, bgH)
        bg.Position         = UDim2.new(0, px(16), 0, yOff)
        bg.BackgroundColor3 = Color3.fromRGB(0, 22, 8)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel  = 0; bg.ZIndex = 11
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, px(8))

        -- accent bar
        local accent = Instance.new("Frame", bg)
        accent.Size             = UDim2.new(0, math.max(3, px(5)), 1, -px(16))
        accent.Position         = UDim2.new(0, 0, 0, px(8))
        accent.BackgroundColor3 = valColor
        accent.BackgroundTransparency = 0.25
        accent.BorderSizePixel  = 0; accent.ZIndex = 12
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, px(3))

        -- prefix
        local prefLbl = Instance.new("TextLabel", bg)
        prefLbl.Size            = UDim2.new(0.4, 0, 1, 0)
        prefLbl.Position        = UDim2.new(0, px(18), 0, 0)
        prefLbl.BackgroundTransparency = 1
        prefLbl.Text            = prefix
        prefLbl.TextColor3      = DIM
        prefLbl.Font            = Enum.Font.Code
        prefLbl.TextSize        = math.max(10, px(22))  -- ใหญ่
        prefLbl.TextXAlignment  = Enum.TextXAlignment.Left
        prefLbl.ZIndex          = 13

        -- cursor blink
        local cur = Instance.new("TextLabel", bg)
        cur.Size            = UDim2.new(0, px(16), 1, 0)
        cur.Position        = UDim2.new(0.4, 0, 0, 0)
        cur.BackgroundTransparency = 1
        cur.Text            = "│"
        cur.TextColor3      = DIM
        cur.Font            = Enum.Font.Code
        cur.TextSize        = math.max(10, px(22))
        cur.ZIndex          = 13
        task.spawn(function()
            while cur and cur.Parent do
                cur.TextTransparency = 0 task.wait(0.5)
                cur.TextTransparency = 1 task.wait(0.5)
            end
        end)

        -- value
        local valLbl = Instance.new("TextLabel", bg)
        valLbl.Size             = UDim2.new(0.55, -px(16), 1, 0)
        valLbl.Position         = UDim2.new(0.43, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text             = "..."
        valLbl.TextColor3       = valColor
        valLbl.Font             = Enum.Font.Code
        valLbl.TextSize         = math.max(12, px(30))  -- ใหญ่มาก
        valLbl.TextXAlignment   = Enum.TextXAlignment.Left
        valLbl.ZIndex           = 13

        valLabels[keys[i]] = valLbl

        -- separator
        local sep = Instance.new("Frame", panel)
        sep.Size             = UDim2.new(1, -px(64), 0, 1)
        sep.Position         = UDim2.new(0, px(32), 0, yOff + bgH + px(4))
        sep.BackgroundColor3 = Color3.fromRGB(0, 60, 25)
        sep.BackgroundTransparency = 0.45
        sep.BorderSizePixel  = 0; sep.ZIndex = 11
    end

    -- ===== FOOTER =====
    local fdiv = Instance.new("Frame", panel)
    fdiv.Size             = UDim2.new(1, -px(32), 0, math.max(1, px(2)))
    fdiv.Position         = UDim2.new(0, px(16), 1, -FOOTER - px(2))
    fdiv.BackgroundColor3 = Color3.fromRGB(0, 180, 60)
    fdiv.BackgroundTransparency = 0.6
    fdiv.BorderSizePixel  = 0; fdiv.ZIndex = 12

    local footerLbl = Instance.new("TextLabel", panel)
    footerLbl.Size             = UDim2.new(1, -px(32), 0, FOOTER)
    footerLbl.Position         = UDim2.new(0, px(16), 1, -FOOTER)
    footerLbl.BackgroundTransparency = 1
    footerLbl.Text             = "[ B ] TOGGLE HUD  //  SYS READY"
    footerLbl.TextColor3       = Color3.fromRGB(0, 100, 45)
    footerLbl.Font             = Enum.Font.Code
    footerLbl.TextSize         = math.max(8, px(18))
    footerLbl.TextXAlignment   = Enum.TextXAlignment.Right
    footerLbl.ZIndex           = 13

    if not hudVisible then
        panel.Position = UDim2.new(1, 40, 0, MARGIN)
    end
end

-- =========================
-- REBUILD เมื่อ viewport เปลี่ยน
-- =========================
local lastVP = camera.ViewportSize
buildHUD()

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local vp = camera.ViewportSize
    if math.abs(vp.X - lastVP.X) > 2 or math.abs(vp.Y - lastVP.Y) > 2 then
        lastVP = vp
        task.wait(0.05)
        buildHUD()
    end
end)

-- =========================
-- TOGGLE B
-- =========================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B then
        hudVisible = not hudVisible
        if hudFrame then
            local MARGIN = px(18)
            TweenService:Create(hudFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {Position = hudVisible
                    and UDim2.new(0, MARGIN, 0, MARGIN)
                    or  UDim2.new(1, 40,     0, MARGIN)}
            ):Play()
        end
    end
end)

-- =========================
-- DATA
-- =========================
local function getAttr(list)
    for _, name in ipairs(list) do
        local v = player:GetAttribute(name)
        if v ~= nil then return tonumber(v) or 0 end
    end
    return 0
end
local function getLevel()     return getAttr({"Level","level","PlayerLevel","currentLevel"}) end
local function getFlowers26() return getAttr({"Flowers26","flowers26"}) end
local function hasMemoria()   return player:GetAttribute("Spring26MemoriaVanguardPityCompleted") == true end

local TARGET = "Shinobi God"

local function checkShinobiGod()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    local place = game.PlaceId
    if place == 16277809958 then
        local ok, units = pcall(function() return pg.Windows.Units.Holder.Main.Units end)
        if not ok or not units then return false end
        for _, item in ipairs(units:GetChildren()) do
            local ok2, lbl = pcall(function() return item.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text and lbl.Text:lower():find(TARGET:lower()) then return true end
        end
    elseif place == 16146832113 then
        local ok, cc = pcall(function()
            return pg.Windows.GlobalInventory.Holder.LeftContainer.FakeScrollingFrame.Items.CacheContainer
        end)
        if not ok or not cc then return false end
        for _, gf in ipairs(cc:GetChildren()) do
            local ok2, lbl = pcall(function() return gf.Container.Holder.Main.UnitName end)
            if ok2 and lbl and lbl.Text and lbl.Text:lower():find(TARGET:lower()) then return true end
        end
    end
    return false
end

task.spawn(function()
    while true do
        pcall(function() cachedHasShinobiGod = checkShinobiGod() end)
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            local u  = valLabels["user"]
            local l  = valLabels["level"]
            local f  = valLabels["flower"]
            local sh = valLabels["shinobi"]
            local me = valLabels["memoria"]
            if not (u and u.Parent) then return end

            u.Text  = player.Name
            l.Text  = tostring(getLevel())
            f.Text  = tostring(getFlowers26())

            sh.Text       = cachedHasShinobiGod and "[  OK  ]" or "[  --  ]"
            sh.TextColor3 = cachedHasShinobiGod and BRIGHT or ERR

            local mem = hasMemoria()
            me.Text       = mem and "[  OK  ]" or "[  --  ]"
            me.TextColor3 = mem and BRIGHT or ERR
        end)
        task.wait(0.5)
    end
end)

print("✅ HUD BIG | กด B เปิด/ปิด")
