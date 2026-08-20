--// ============================================================
--//                 🍪 COOKIES HUB
--//                  MOBILE EDITION
--//             ALL-IN-ONE MOBILE EDITION
--// ============================================================

repeat task.wait() until game:IsLoaded()

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


--// ============================================================
--// DROP BR
--// ============================================================

local dropActive = false
local dropConnections = {}


local function showDropMessage()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")

    local old = CoreGui:FindFirstChild("CookiesDropNotice")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CookiesDropNotice"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 0)
    holder.Position = UDim2.new(0.5, 0, -0.12, 0)
    holder.Size = UDim2.fromOffset(340, 52)
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🍪  SE DROPEÓ BRAINROT"
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 22
    label.TextStrokeTransparency = 0.1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Parent = holder

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
    })
    grad.Parent = label

    -- Entra desde arriba hacia abajo, como una notificación animada.
    local enter = TweenService:Create(
        holder,
        TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.07, 0)}
    )
    enter:Play()

    task.spawn(function()
        while holder.Parent do
            grad.Rotation = (grad.Rotation + 8) % 360
            task.wait(0.035)
        end
    end)

    task.delay(1.15, function()
        if not holder.Parent then return end

        -- Sale hacia abajo.
        local exit = TweenService:Create(
            holder,
            TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, 0, 0.16, 0)}
        )
        exit:Play()
        exit.Completed:Wait()

        if gui.Parent then
            gui:Destroy()
        end
    end)
end

local function runDrop()
    if dropActive then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then return end

    pcall(function() root.Anchored = false end)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.PlatformStand = false end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    dropActive = true
    showDropMessage()
    local changedCollisions = {}

    local function cleanupDrop()
        dropActive = false
        for _, c in ipairs(dropConnections) do
            if typeof(c) == "RBXScriptConnection" then
                pcall(function() c:Disconnect() end)
            elseif type(c) == "thread" then
                pcall(coroutine.close, c)
            end
        end
        table.clear(dropConnections)

        for part, oldValue in pairs(changedCollisions) do
            if typeof(part) == "Instance" and part.Parent then
                pcall(function() part.CanCollide = oldValue end)
            end
        end
    end

    table.insert(dropConnections, RunService.Stepped:Connect(function()
        if not dropActive then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if changedCollisions[part] == nil then
                            changedCollisions[part] = part.CanCollide
                        end
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end
        end
    end))

    local flingThread = coroutine.create(function()
        while dropActive do
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if not r then break end

            pcall(function() r.Anchored = false end)
            local vel = r.Velocity
            pcall(function()
                r.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            end)

            RunService.RenderStepped:Wait()
            if r and r.Parent then pcall(function() r.Velocity = vel end) end
            RunService.Stepped:Wait()
            if r and r.Parent then pcall(function() r.Velocity = vel + Vector3.new(0, 0.1, 0) end) end
        end
    end)

    table.insert(dropConnections, flingThread)
    local ok = coroutine.resume(flingThread)
    if not ok then cleanupDrop() return end
    task.delay(0.25, cleanupDrop)
end


--// ============================================================
--// DEFENSE SOURCES
--// Anti Bee + Anti Ragdoll + DROP BR
--// ============================================================

local Defense = {
    AntiBee = false,
    AntiRagdoll = false,
}

-- Anti Bee
local AntiBeeData = {
    running = false,
    connections = {},
    originalMoveFunction = nil,
    controlsProtected = false,
    badLightingNames = {
        Blue = true,
        DiscoEffect = true,
        BeeBlur = true,
        ColorCorrection = true,
    },
}

local function antiBeeNuke(obj)
    if not obj or not obj.Parent then return end
    if AntiBeeData.badLightingNames[obj.Name] then
        pcall(function() obj:Destroy() end)
    end
end

local function antiBeeDisconnectAll()
    for _, conn in ipairs(AntiBeeData.connections) do
        pcall(function() conn:Disconnect() end)
    end
    AntiBeeData.connections = {}
end

local function antiBeeProtectControls()
    if AntiBeeData.controlsProtected then return end
    pcall(function()
        local playerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
        if not playerModule then return end
        local controls = require(playerModule):GetControls()
        if not controls then return end

        if not AntiBeeData.originalMoveFunction then
            AntiBeeData.originalMoveFunction = controls.moveFunction
        end

        local function protectedMove(self, moveVector, relativeToCamera)
            if AntiBeeData.originalMoveFunction then
                AntiBeeData.originalMoveFunction(self, moveVector, relativeToCamera)
            end
        end

        local acc = 0
        table.insert(AntiBeeData.connections, RunService.Heartbeat:Connect(function(dt)
            if not AntiBeeData.running then return end
            acc += dt
            if acc < 0.25 then return end
            acc = 0
            if controls.moveFunction ~= protectedMove then
                controls.moveFunction = protectedMove
            end
        end))

        controls.moveFunction = protectedMove
        AntiBeeData.controlsProtected = true
    end)
end

local function antiBeeRestoreControls()
    if not AntiBeeData.controlsProtected then return end
    pcall(function()
        local playerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
        if not playerModule then return end
        local controls = require(playerModule):GetControls()
        if controls and AntiBeeData.originalMoveFunction then
            controls.moveFunction = AntiBeeData.originalMoveFunction
            AntiBeeData.controlsProtected = false
        end
    end)
end

local function antiBeeBlockBuzzing()
    pcall(function()
        local beeScript = LocalPlayer.PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then
                buzzing:Stop()
                buzzing.Volume = 0
            end
        end
    end)
end

local function enableAntiBee()
    if AntiBeeData.running then return end
    AntiBeeData.running = true

    for _, inst in ipairs(Lighting:GetDescendants()) do
        antiBeeNuke(inst)
    end

    table.insert(AntiBeeData.connections, Lighting.DescendantAdded:Connect(function(obj)
        if AntiBeeData.running then antiBeeNuke(obj) end
    end))

    antiBeeProtectControls()

    local acc = 0
    table.insert(AntiBeeData.connections, RunService.Heartbeat:Connect(function(dt)
        if not AntiBeeData.running then return end
        acc += dt
        if acc < 0.25 then return end
        acc = 0
        antiBeeBlockBuzzing()
    end))
end

local function disableAntiBee()
    if not AntiBeeData.running then return end
    AntiBeeData.running = false
    antiBeeRestoreControls()
    antiBeeDisconnectAll()
end

-- Anti Ragdoll
local AntiRagdoll = {
    running = false,
    connections = {},
}

local function antiRagdollRemoveConstraints(char)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint")
            or d:IsA("NoCollisionConstraint")
            or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end

local function antiRagdollResetCharacter(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Anchored = false
        rootPart.Velocity = Vector3.zero
    end
    if humanoid then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid.PlatformStand = false
        humanoid.Sit = false
        if humanoid.Health > 0 then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = humanoid end
    end
end

local function antiRagdollCharacterAdded(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    char:WaitForChild("HumanoidRootPart", 5)
    if not humanoid then return end

    if AntiRagdoll.connections.charDescAdded then
        pcall(function() AntiRagdoll.connections.charDescAdded:Disconnect() end)
    end
    AntiRagdoll.connections.charDescAdded = char.DescendantAdded:Connect(function(obj)
        if not AntiRagdoll.running then return end
        if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint")
            or obj:IsA("NoCollisionConstraint")
            or (obj:IsA("Attachment") and obj.Name:find("RagdollAttachment")) then
            task.defer(function()
                if AntiRagdoll.running and obj.Parent then pcall(function() obj:Destroy() end) end
            end)
        end
    end)

    AntiRagdoll.connections.platformStand = humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if not AntiRagdoll.running then return end
        if humanoid.PlatformStand then
            task.defer(function()
                if AntiRagdoll.running then
                    antiRagdollResetCharacter(char)
                    antiRagdollRemoveConstraints(char)
                end
            end)
        end
    end)

    antiRagdollRemoveConstraints(char)
    antiRagdollResetCharacter(char)
end

local function enableAntiRagdoll()
    if AntiRagdoll.running then return end
    AntiRagdoll.running = true
    local tickAcc = 0

    AntiRagdoll.connections.heartbeat = RunService.Heartbeat:Connect(function(dt)
        if not AntiRagdoll.running then return end
        tickAcc += dt
        if tickAcc < 0.1 then return end
        tickAcc = 0

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        local state = hum:GetState()
        local ragdolled = state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
        local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then ragdolled = true end

        if ragdolled then
            antiRagdollRemoveConstraints(char)
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
            end
            if hum.Health > 0 then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = hum end
            root.Anchored = false
            root.Velocity = Vector3.zero
        end
    end)

    AntiRagdoll.connections.charAdded = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        if AntiRagdoll.running then antiRagdollCharacterAdded(char) end
    end)

    if LocalPlayer.Character then antiRagdollCharacterAdded(LocalPlayer.Character) end
end

local function disableAntiRagdoll()
    AntiRagdoll.running = false
    for _, conn in pairs(AntiRagdoll.connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    AntiRagdoll.connections = {}
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        end
    end)
end

--// ============================================================
--// CONFIG
--// ============================================================

local Config = {
    AutoSteal = true,
    Podiums = true,
    NextBase = true,
    StealRadius = 59,
    StealDuration = 1.3,

    --// PLAYER ESP
    PlayerESP = false,
    PlayerESPNames = true,
    PlayerESPDistance = true,

    --// ESP
    TimerESP = false,
    AllowedESP = false,
    CloneESP = false,
    LineToBase = false,
    XRay = false,

    Sounds = true,
    Watermark = true,

    UIScale = 1,
}

local Connections = {}

--// ============================================================
--// CLEAN OLD VERSION
--// ============================================================

if _G.__CookiesHubCleanup then
    pcall(_G.__CookiesHubCleanup)
end

--// ============================================================
--// COLORS
--// ============================================================

local Colors = {
    Background = Color3.fromRGB(8, 8, 12),
    Background2 = Color3.fromRGB(14, 14, 20),
    Card = Color3.fromRGB(18, 18, 27),

    Red = Color3.fromRGB(255, 45, 65),
    RedLight = Color3.fromRGB(255, 90, 105),

    Blue = Color3.fromRGB(55, 185, 255),
    Green = Color3.fromRGB(45, 230, 120),
    Yellow = Color3.fromRGB(255, 205, 70),

    White = Color3.fromRGB(245, 245, 250),
    Gray = Color3.fromRGB(150, 150, 165),
    DarkGray = Color3.fromRGB(40, 40, 50),
    Black = Color3.fromRGB(0, 0, 0),
}

--// ============================================================
--// HELPERS
--// ============================================================

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function disconnect(c)
    if c then
        pcall(function()
            c:Disconnect()
        end)
    end
end

local function playClick()
    if not Config.Sounds then
        return
    end

    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6895079813"
        sound.Volume = 0.18
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 1)
    end)
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.DarkGray
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0
    stroke.Parent = parent
    return stroke
end

--// ============================================================
--// GUI
--// ============================================================

local oldGui = PlayerGui:FindFirstChild("COOKIES_HUB")

if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "COOKIES_HUB"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--// ============================================================
--// LOADING SCREEN
--// ============================================================

local LoadingScreen = Instance.new("Frame")
LoadingScreen.Name = "LoadingScreen"
LoadingScreen.Size = UDim2.fromScale(1, 1)
LoadingScreen.Position = UDim2.fromScale(0, 0)
LoadingScreen.BackgroundColor3 = Colors.Background
LoadingScreen.BorderSizePixel = 0
LoadingScreen.ZIndex = 999
LoadingScreen.Parent = ScreenGui

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(1, 0, 0, 45)
LoadingTitle.Position = UDim2.new(0, 0, 0.38, 0)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "🍪 COOKIES HUB"
LoadingTitle.Font = Enum.Font.GothamBlack
LoadingTitle.TextSize = 28
LoadingTitle.TextColor3 = Colors.White
LoadingTitle.ZIndex = 1000
LoadingTitle.Parent = LoadingScreen

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 25)
LoadingSubtitle.Position = UDim2.new(0, 0, 0.46, 0)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "MOBILE EDITION"
LoadingSubtitle.Font = Enum.Font.GothamBold
LoadingSubtitle.TextSize = 11
LoadingSubtitle.TextColor3 = Colors.RedLight
LoadingSubtitle.ZIndex = 1000
LoadingSubtitle.Parent = LoadingScreen

local LoadingTrack = Instance.new("Frame")
LoadingTrack.Size = UDim2.fromOffset(280, 8)
LoadingTrack.Position = UDim2.new(0.5, -140, 0.53, 0)
LoadingTrack.BackgroundColor3 = Colors.DarkGray
LoadingTrack.BorderSizePixel = 0
LoadingTrack.ZIndex = 1000
LoadingTrack.Parent = LoadingScreen

createCorner(LoadingTrack, 5)

local LoadingFill = Instance.new("Frame")
LoadingFill.Size = UDim2.new(0, 0, 1, 0)
LoadingFill.BackgroundColor3 = Colors.Red
LoadingFill.BorderSizePixel = 0
LoadingFill.ZIndex = 1001
LoadingFill.Parent = LoadingTrack

createCorner(LoadingFill, 5)

local LoadingPercent = Instance.new("TextLabel")
LoadingPercent.Size = UDim2.fromOffset(280, 25)
LoadingPercent.Position = UDim2.new(0.5, -140, 0.56, 0)
LoadingPercent.BackgroundTransparency = 1
Load
