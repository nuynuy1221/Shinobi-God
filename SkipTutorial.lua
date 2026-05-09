repeat task.wait() until game:IsLoaded()
task.wait(5)

task.spawn(function()
    local skip1 = {
        [1] = "PartTwo",
        [2] = "Eligible Player Loaded"
    }

    game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("NEWTutorialEvent"):FireServer(unpack(skip1))

    task.wait(1)
    local skip2 = {
        [1] = "PartOne",
        [2] = "Skip"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("NEWTutorialEvent"):FireServer(unpack(skip2))

    task.wait(1)
    local skip3 = {
        [1] = "PartTwo",
        [2] = "Skip"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("NEWTutorialEvent"):FireServer(unpack(skip3))
end)
