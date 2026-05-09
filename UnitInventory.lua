repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่อัพเกรดกระเป๋า")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local playerGui = player.PlayerGui

-- =========================
-- CONFIG
-- =========================
local MAX_UNIT = 500
local MAX_MEMORIA = 500
local CHECK_DELAY = 5

-- =========================
-- GET MAX SLOT FROM TEXT x/y
-- =========================
local function getMaxSlot()
    local ok, label = pcall(function()
        return playerGui.Windows.GlobalInventory.Holder
            .LeftContainer.BottomBar.OwnedItems.ItemAmount
    end)

    if not ok or not label then
        return nil
    end

    local text = label.ContentText or label.Text
    if not text then
        return nil
    end

    local current, max = text:match("(%d+)%s*/%s*(%d+)")
    if max then
        return tonumber(max)
    end

    return nil
end

-- =========================
-- PURCHASE UNIT EXPANSION
-- =========================
local function purchaseUnitExpansion()
    local args = {
        [1] = "Purchase"
    }

    ReplicatedStorage:WaitForChild("Networking")
        :WaitForChild("UnitExpansionEvent")
        :FireServer(unpack(args))

    print("[UnitExpansion] Purchase fired")
end

-- =========================
-- PURCHASE MEMORIA EXPANSION
-- =========================
local function purchaseMemoriaExpansion()
    local args = {
        [1] = "Purchase"
    }

    ReplicatedStorage:WaitForChild("Networking")
        :WaitForChild("Memorias")
        :WaitForChild("MemoriaExpansionEvent")
        :FireServer(unpack(args))

    print("[MemoriaExpansion] Purchase fired")
end

-- =========================
-- MAIN LOOP
-- =========================
task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local maxSlot = getMaxSlot()

        if maxSlot then
            print("[Inventory] Current Max =", maxSlot)

            -- ซื้อ Unit Slot
            if maxSlot < MAX_UNIT then
                purchaseMemoriaExpansion()
                purchaseUnitExpansion()
            end

            -- ซื้อ Memoria Slot
            if maxSlot < MAX_MEMORIA then
                purchaseMemoriaExpansion()
                purchaseUnitExpansion()
            end
        end
    end
end)
