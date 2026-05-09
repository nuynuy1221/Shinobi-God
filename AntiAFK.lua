repeat task.wait() until game:IsLoaded()
task.wait(15)

-- Cache services ครั้งเดียวนอก loop (เดิมประกาศซ้ำทุกรอบ)
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local function clickAFK()
    local ok, button = pcall(function()
        return game:GetService("CoreGui")
            .TopBarApp.TopBarApp.UnibarLeftFrame
            .UnibarMenu["2"]["3"].nine_dot.IconHitArea_nine_dot
    end)
    if not ok or not button then return end

    button.Selectable = true
    GuiService.SelectedCoreObject = button
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    GuiService.SelectedCoreObject = nil
end

task.spawn(function()
    while true do
        clickAFK()   -- กดครั้งแรก
        task.wait(15)
        clickAFK()   -- กดครั้งที่สอง (toggle กลับ)
        task.wait(15)
    end
end)
