repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่รันสคริปต์")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
repeat task.wait() until player:FindFirstChild("PlayerGui")

local playerGui = player.PlayerGui

local Networking = ReplicatedStorage:WaitForChild("Networking")

local MemoriaEvent = Networking
:WaitForChild("Memorias")
:WaitForChild("MemoriaEvent")

local SellEvent = Networking
:WaitForChild("Units")
:WaitForChild("SellEvent")

--------------------------------------------------
-- UPDATE LOG
--------------------------------------------------

pcall(function()

    local Update = {
        [1] = "Update",
        [2] = true
    }

    Networking
    :WaitForChild("UpdateLogEvent")
    :FireServer(unpack(Update))

end)

--------------------------------------------------
-- AUTO CLOSE ALL POPUPS
--------------------------------------------------

local function pressButton(button)

    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize

    local x = pos.X + size.X/2
    local y = pos.Y + size.Y/2

    VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,1)
    VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,1)

end

task.spawn(function()

    for i = 1,30 do

        for _, gui in pairs(playerGui:GetChildren()) do

            local holder = gui:FindFirstChild("Holder")
            local close = holder and holder:FindFirstChild("Close")
            local button = close and close:FindFirstChild("Button")

            if button then
                pcall(function()
                    pressButton(button)
                end)
            end

        end

        task.wait(0.5)

    end

end)

--------------------------------------------------
-- BUTTON PRESS
--------------------------------------------------

local function pressButton(button)

    button.Selectable = true
    GuiService.SelectedCoreObject = button

    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Return,false,game)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Return,false,game)

    task.wait(0.1)

    GuiService.SelectedCoreObject = nil

end

--------------------------------------------------
-- OPEN INVENTORY
--------------------------------------------------

local function openInventory()

    local button = playerGui.HUD.SideButtons.Buttons.Units.Button
    pressButton(button)

    task.wait(0.5)

end

--------------------------------------------------
-- OPEN TABS
--------------------------------------------------

local function openUnitsTab()

    local button = playerGui.Windows.GlobalInventory.Header.Tabs.Units.Button
    pressButton(button)

    task.wait(0.3)

end

local function openMemoriaTab()

    local button = playerGui.Windows.GlobalInventory.Header.Tabs.Memorias.Button
    pressButton(button)

    task.wait(0.3)

end

--------------------------------------------------
-- GET ITEMS
--------------------------------------------------

local function getItems()

    local success, items = pcall(function()
        return playerGui.Windows
        .GlobalInventory.Holder
        .LeftContainer.FakeScrollingFrame
        .Items
    end)

    if success then
        return items
    end

end

--------------------------------------------------
-- SELL NON SHINY MYTHIC
--------------------------------------------------

local function sellNonShinyMythic(items)

    local unitsToSell = {}

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then

            for _, guidFrame in ipairs(cache:GetChildren()) do

                local guid = guidFrame.Name
                local container = guidFrame:FindFirstChild("Container")
                if not container then continue end

                local holder = container:FindFirstChild("Holder")
                local main = holder and holder:FindFirstChild("Main")
                if not main then continue end

                local isMythic = main:FindFirstChild("Mythic")

                local shinyFrame = container:FindFirstChild("ShinyFrame")
                local isShiny = shinyFrame and shinyFrame.Visible

                if isMythic and not isShiny then
                    table.insert(unitsToSell, guid)
                end

            end

        end
    end

    if #unitsToSell > 0 then

        pcall(function()
            SellEvent:FireServer(unitsToSell)
        end)

    end

end

--------------------------------------------------
-- SELL MEMORIA
--------------------------------------------------

local function sellMemoria(items)

    local memoriaToSell = {}

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then

            for _, guidFrame in ipairs(cache:GetChildren()) do

                local guid = guidFrame.Name

                local container = guidFrame:FindFirstChild("Container")
                if not container then continue end

                local holder = container:FindFirstChild("Holder")
                local main = holder and holder:FindFirstChild("Main")
                if not main then continue end

                if main:FindFirstChild("Rare")
                or main:FindFirstChild("Epic")
                or main:FindFirstChild("Legendary")
                or main:FindFirstChild("Mythic") then

                    table.insert(memoriaToSell, guid)

                end

            end

        end
    end

    if #memoriaToSell > 0 then

        pcall(function()
            MemoriaEvent:FireServer("Sell", memoriaToSell)
        end)

    end

end

--------------------------------------------------
-- กดกลางจอ
--------------------------------------------------

local VirtualInputManager = game:GetService("VirtualInputManager")

local function clickCenter()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local size = cam.ViewportSize
    local x = size.X / 2
    local y = size.Y / 2

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

task.spawn(function()

    while true do
        clickCenter()

        -----------------------
        -- MEMORIA
        -----------------------

        local items = getItems()

        if items then
            sellNonShinyMythic(items)
            sellMemoria(items)
        end

        task.wait(5)

        -----------------------
        -- UNITS
        -----------------------


        items = getItems()

        if items then
            sellNonShinyMythic(items)
            sellMemoria(items)
        end

        task.wait(5)

    end

end)

--------------------------------------------------
-- Auto Cancal Alert Popup
--------------------------------------------------
task.spawn(function()

    local GuiService = game:GetService("GuiService")
    local VIM = game:GetService("VirtualInputManager")
    local player = game:GetService("Players").LocalPlayer

    while true do
        task.wait(0.3)

        local ok, button = pcall(function()
            return player.PlayerGui.PopupScreen.BaseCancelFrame.Main.Buttons.Cancel.Button
        end)

        if ok and button and button.Visible then
            print("พบ Cancel → กดด้วย Enter")

            button.Selectable = true
            GuiService.SelectedObject = button

            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

            task.wait(0.1)
            GuiService.SelectedObject = nil

            task.wait(1)
        end
    end

end)
