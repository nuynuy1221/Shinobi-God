repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16277809958

if game.PlaceId == targetPlace then
    local map2 = workspace:WaitForChild("Map")

    local assets = map2:FindFirstChild("Assets")
    if assets then
        for _, obj in ipairs(assets:GetChildren()) do obj:Destroy() end
    end

    local skellingtons = map2:FindFirstChild("Skellingtons")
    if skellingtons then skellingtons:Destroy() end
end

task.wait(1)

if game.PlaceId ~= targetPlace then

    local function cleanMainLobby()
        local lobby = workspace:FindFirstChild("MainLobby")
        if not lobby then return end

        local gamemodes = lobby:FindFirstChild("Gamemodes")
        if gamemodes then
            local play = gamemodes:FindFirstChild("Play")
            if play then
                local keep = play:FindFirstChild("Lights / Lighting")
                for _, obj in ipairs(play:GetChildren()) do
                    if obj ~= keep then obj:Destroy() end
                end
            end
            for _, obj in ipairs(gamemodes:GetChildren()) do
                if obj.Name ~= "Play" then obj:Destroy() end
            end
        end

        for _, obj in ipairs(lobby:GetChildren()) do
            if obj.Name ~= "NPC"
            and obj.Name ~= "ChallengeBanner"
            and obj.Name ~= "Credits"
            and obj.Name ~= "Gamemodes" then
                obj:Destroy()
            end
        end
    end

    local function createInvisibleFloor()
        if workspace:FindFirstChild("InvisibleFloor") then return end
        local floor = Instance.new("Part")
        floor.Name = "InvisibleFloor"
        floor.Size = Vector3.new(5000, 1, 5000)
        floor.Position = Vector3.new(0, 4, 0)
        floor.Anchored = true
        floor.CanCollide = true
        floor.Transparency = 1
        floor.Parent = workspace
    end

    cleanMainLobby()
    createInvisibleFloor()

    -- กัน spawn ใหม่ทุก 10 วิ (เดิม 5 วิ — ไม่จำเป็นต้องถี่)
    task.spawn(function()
        while task.wait(10) do
            cleanMainLobby()
        end
    end)
end

local DEL_TEXTURE    = true
local DEL_BACKGROUND = true
local DEL_OBJECTS    = true
local MUTE_SOUNDS    = true

local Lighting     = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local function S(o, p, v)
    pcall(function() o[p] = v end)
end

-- =========================
-- REMOVE TEXTURE
-- ใช้ DescendantAdded จัดการ real-time
-- sweep ทุก 30 วิ (เดิม 5 วิ) เพราะ DescendantAdded ครอบอยู่แล้ว
-- =========================
if DEL_TEXTURE then
    local function applyTexture(obj)
        if obj:IsA("Decal") or obj:IsA("Texture") then
            S(obj, "Transparency", 1)
            S(obj, "Texture", "")
        end
        if obj:IsA("SpecialMesh") then
            S(obj, "TextureId", "")
        end
        if obj:IsA("BasePart") then
            S(obj, "Material", Enum.Material.SmoothPlastic)
        end
    end

    local function applyAllTextures()
        for _, obj in ipairs(workspace:GetDescendants()) do
            applyTexture(obj)
        end
        pcall(function()
            Lighting.Technology = Enum.Technology.Compatibility
        end)
    end

    applyAllTextures()

    workspace.DescendantAdded:Connect(function(obj)
        task.wait()
        applyTexture(obj)
    end)

    -- sweep backup ทุก 30 วิ (เดิม 5 วิ)
    task.spawn(function()
        while task.wait(30) do
            applyAllTextures()
        end
    end)
end

-- =========================
-- REMOVE BACKGROUND
-- sweep ทุก 30 วิ (เดิม 5 วิ)
-- =========================
if DEL_BACKGROUND then
    local function applyBackground()
        S(Lighting, "FogColor", Color3.new(1, 1, 1))
        S(Lighting, "FogEnd", 0.001)
        S(Lighting, "FogStart", 0)
        S(Lighting, "Brightness", 0)
        S(Lighting, "Ambient", Color3.new(0, 0, 0))

        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj.ClassName == "Sky" then
                pcall(function() obj:Destroy() end)
            elseif obj.ClassName == "Atmosphere" then
                S(obj, "Density", 0)
                S(obj, "Haze", 0)
                S(obj, "Glare", 0)
            end
        end
    end

    applyBackground()

    Lighting.ChildAdded:Connect(function(obj)
        task.wait()
        if obj.ClassName == "Sky" then
            pcall(function() obj:Destroy() end)
        elseif obj.ClassName == "Atmosphere" then
            S(obj, "Density", 0)
            S(obj, "Haze", 0)
            S(obj, "Glare", 0)
        end
    end)

    task.spawn(function()
        while task.wait(30) do
            applyBackground()
        end
    end)
end

-- =========================
-- REMOVE EFFECTS
-- sweep ทุก 30 วิ (เดิม 5 วิ)
-- =========================
if DEL_OBJECTS then
    local KILL = {
        ParticleEmitter=1, Beam=1, Trail=1,
        PointLight=1, SpotLight=1, SurfaceLight=1,
        SelectionBox=1, SelectionSphere=1,
        BillboardGui=1, SurfaceGui=1
    }

    local function killObj(obj)
        if KILL[obj.ClassName] then
            S(obj, "Enabled", false)
            S(obj, "Visible", false)
            S(obj, "Rate", 0)
        end
    end

    local function applyAllObjects()
        for _, obj in ipairs(workspace:GetDescendants()) do
            killObj(obj)
        end
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t then
            S(t, "Decoration", false)
            S(t, "WaterWaveSize", 0)
            S(t, "WaterReflectance", 0)
            S(t, "CastShadow", false)
        end
    end

    applyAllObjects()

    workspace.DescendantAdded:Connect(function(obj)
        task.wait()
        killObj(obj)
    end)

    task.spawn(function()
        while task.wait(30) do
            applyAllObjects()
        end
    end)
end

-- =========================
-- MUTE SOUND
-- sweep ทุก 15 วิ (เดิม 3 วิ)
-- =========================
if MUTE_SOUNDS then
    local function muteObj(obj)
        if obj:IsA("Sound") then
            pcall(function()
                obj:Stop()
                obj.Volume = 0
                obj.PlaybackSpeed = 0
            end)
        end
    end

    local function applyAllMute()
        for _, obj in ipairs(workspace:GetDescendants()) do muteObj(obj) end
        for _, obj in ipairs(SoundService:GetDescendants()) do muteObj(obj) end
        pcall(function() SoundService.AmbientReverb = Enum.ReverbType.NoReverb end)
    end

    applyAllMute()

    workspace.DescendantAdded:Connect(function(obj) task.wait() muteObj(obj) end)
    SoundService.DescendantAdded:Connect(function(obj) task.wait() muteObj(obj) end)

    task.spawn(function()
        while task.wait(15) do
            applyAllMute()
        end
    end)
end
