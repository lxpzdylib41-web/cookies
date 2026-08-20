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
--// DEFENSE SOURCES
--// Anti Bee + Anti Admin Panel + Anti Ragdoll
--// ============================================================

local Defense = {
    AntiBee = false,
    AntiAdminPanel = false,
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

-- Anti Admin Panel
local AntiAdmin = {
    running = false,
    originalScales = {},
    originalHipHeight = nil,
    controls = nil,
    characterController = nil,
    jumpscare = nil,
    characterConnection = nil,
}

local adminScaleNames = {
    "HeadScale", "BodyDepthScale", "BodyHeightScale",
    "BodyProportionScale", "BodyTypeScale", "BodyWidthScale",
}

local function adminCaptureOriginals()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    AntiAdmin.originalHipHeight = hum.HipHeight
    AntiAdmin.originalScales = {}
    for _, name in ipairs(adminScaleNames) do
        local sv = hum:FindFirstChild(name)
        if sv then AntiAdmin.originalScales[name] = sv.Value end
    end
end

local function adminGetControls()
    if AntiAdmin.controls then return AntiAdmin.controls end
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local pm = ps and ps:FindFirstChild("PlayerModule")
    if not pm then return nil end
    local ok, mod = pcall(require, pm)
    if not ok or not mod then return nil end
    local ok2, controls = pcall(function() return mod:GetControls() end)
    if ok2 and controls then AntiAdmin.controls = controls end
    return AntiAdmin.controls
end

local function adminGetCharacterController()
    if AntiAdmin.characterController ~= nil then return AntiAdmin.characterController end
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CharacterController"))
    end)
    AntiAdmin.characterController = ok and mod or false
    return AntiAdmin.characterController
end

local function adminGetJumpscare()
    if AntiAdmin.jumpscare ~= nil then return AntiAdmin.jumpscare end
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("AdminCommands"):WaitForChild("jumpscare"))
    end)
    AntiAdmin.jumpscare = ok and mod or false
    return AntiAdmin.jumpscare
end

local function antiAdminStep()
    if not AntiAdmin.running then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") or v:IsA("Attachment") then
            pcall(function() v:Destroy() end)
        elseif v:IsA("Motor6D") then
            v.Enabled = true
        end
    end

    local ctrl = adminGetControls()
    if ctrl then pcall(function() ctrl:Enable() end) end

    local state = hum:GetState()
    if state ~= Enum.HumanoidStateType.Running
        and state ~= Enum.HumanoidStateType.Jumping
        and state ~= Enum.HumanoidStateType.Freefall then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    if workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject ~= hum then
        workspace.CurrentCamera.CameraSubject = hum
    end

    local ragdollEnd = LocalPlayer:GetAttribute("RagdollEndTime") or 0
    if ragdollEnd > workspace:GetServerTimeNow() then
        hrp.Velocity = Vector3.zero
        pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", 0) end)
    end

    local cc = adminGetCharacterController()
    if cc and ctrl then
        ctrl.moveFunction = function(p, x, z)
            pcall(function() cc:RequestMove(p, x, z) end)
        end
    end

    local jm = adminGetJumpscare()
    if jm and jm.effects and jm.effects.Victim then
        jm.effects.Victim = function() end
    end

    if AntiAdmin.originalHipHeight and hum.HipHeight ~= AntiAdmin.originalHipHeight then
        hum.HipHeight = AntiAdmin.originalHipHeight
    end

    for _, name in ipairs(adminScaleNames) do
        local sv = hum:FindFirstChild(name)
        if sv and AntiAdmin.originalScales[name] and sv.Value ~= AntiAdmin.originalScales[name] then
            sv.Value = AntiAdmin.originalScales[name]
        end
    end

    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Model") and not v:IsA("BackpackItem") then
            pcall(function() v:Destroy() end)
        end
    end
end

local function enableAntiAdminPanel()
    if AntiAdmin.running then return end
    AntiAdmin.running = true
    adminCaptureOriginals()

    if AntiAdmin.characterConnection then
        pcall(function() AntiAdmin.characterConnection:Disconnect() end)
    end
    AntiAdmin.characterConnection = LocalPlayer.CharacterAdded:Connect(function()
        AntiAdmin.controls = nil
        task.wait(0.1)
        if AntiAdmin.running then adminCaptureOriginals() end
    end)

    task.spawn(function()
        while AntiAdmin.running do
            task.wait(0.1)
            antiAdminStep()
        end
    end)
end

local function disableAntiAdminPanel()
    AntiAdmin.running = false
    if AntiAdmin.characterConnection then
        pcall(function() AntiAdmin.characterConnection:Disconnect() end)
        AntiAdmin.characterConnection = nil
    end
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
LoadingPercent.Text = "0%"
LoadingPercent.Font = Enum.Font.GothamBlack
LoadingPercent.TextSize = 10
LoadingPercent.TextColor3 = Colors.White
LoadingPercent.ZIndex = 1000
LoadingPercent.Parent = LoadingScreen

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.fromOffset(320, 25)
LoadingStatus.Position = UDim2.new(0.5, -160, 0.61, 0)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "Initializing..."
LoadingStatus.Font = Enum.Font.Gotham
LoadingStatus.TextSize = 9
LoadingStatus.TextColor3 = Colors.Gray
LoadingStatus.ZIndex = 1000
LoadingStatus.Parent = LoadingScreen

task.spawn(function()

    local steps = {
        {10, "Starting Cookies Hub..."},
        {25, "Loading interface..."},
        {40, "Loading components..."},
        {55, "Loading mobile controls..."},
        {70, "Loading visual systems..."},
        {85, "Preparing ESP..."},
        {100, "Cookies Hub ready!"},
    }

    for _, step in ipairs(steps) do

        local percent = step[1]
        local text = step[2]

        LoadingStatus.Text = text

        TweenService:Create(
            LoadingFill,
            TweenInfo.new(
                0.35,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {
                Size = UDim2.new(percent / 100, 0, 1, 0)
            }
        ):Play()

        LoadingPercent.Text = percent .. "%"

        task.wait(0.35)
    end

    task.wait(0.35)

    for _, object in ipairs(LoadingScreen:GetDescendants()) do

        if object:IsA("TextLabel") then

            TweenService:Create(
                object,
                TweenInfo.new(0.4),
                {
                    TextTransparency = 1
                }
            ):Play()

        elseif object:IsA("Frame") then

            TweenService:Create(
                object,
                TweenInfo.new(0.4),
                {
                    BackgroundTransparency = 1
                }
            ):Play()

        end
    end

    TweenService:Create(
        LoadingScreen,
        TweenInfo.new(0.45),
        {
            BackgroundTransparency = 1
        }
    ):Play()

    task.wait(0.5)

    if LoadingScreen and LoadingScreen.Parent then
        LoadingScreen:Destroy()
    end
end)

--// ============================================================
--// MAIN
--// ============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(620, 430)
Main.Position = UDim2.new(0.5, -310, 0.5, -215)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

createCorner(Main, 14)
createStroke(Main, Colors.Red, 1.5)

local MainStroke = Main:FindFirstChildOfClass("UIStroke")

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Colors.Red),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 10, 20)),
    ColorSequenceKeypoint.new(1, Colors.Red),
})
Gradient.Parent = MainStroke

task.spawn(function()
    while Main.Parent do
        Gradient.Rotation = (Gradient.Rotation + 1) % 360
        task.wait(0.025)
    end
end)

--// ============================================================
--// UI SCALE
--// ============================================================

local MainScale = Instance.new("UIScale")
MainScale.Scale = Config.UIScale
MainScale.Parent = Main

local MIN_SCALE = 0.70
local MAX_SCALE = 1.45

local function setUIScale(value)

    value = math.clamp(
        value,
        MIN_SCALE,
        MAX_SCALE
    )

    Config.UIScale = value
    MainScale.Scale = value
end

--// ============================================================
--// MINI COOKIE BUTTON
--// ============================================================

local MiniButton = Instance.new("TextButton")
MiniButton.Name = "CookiesMiniButton"
MiniButton.Size = UDim2.fromOffset(60, 60)
MiniButton.Position = UDim2.new(1, -78, 1, -85)
MiniButton.BackgroundColor3 = Colors.Background
MiniButton.BorderSizePixel = 0
MiniButton.Text = "🍪"
MiniButton.TextSize = 31
MiniButton.TextColor3 = Colors.White
MiniButton.Font = Enum.Font.GothamBlack
MiniButton.Visible = false
MiniButton.Active = true
MiniButton.AutoButtonColor = false
MiniButton.Parent = ScreenGui

createCorner(MiniButton, 15)
createStroke(MiniButton, Colors.Red, 2)

local MiniGradient = Instance.new("UIGradient")
MiniGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Colors.Red),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 10, 20)),
    ColorSequenceKeypoint.new(1, Colors.Red),
})
MiniGradient.Parent = MiniButton

--// ============================================================
--// DRAG MAIN
--// ============================================================

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

local DragArea = Instance.new("Frame")
DragArea.Size = UDim2.new(1, -115, 0, 58)
DragArea.BackgroundTransparency = 1
DragArea.Parent = Main

connect(DragArea.InputBegan, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

    end
end)

connect(UserInputService.InputChanged, function(input)

    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        updateDrag(input)

    end
end)

connect(UserInputService.InputEnded, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false

    end
end)

--// ============================================================
--// MINI BUTTON DRAG
--// ============================================================

local miniDragging = false
local miniDragStart
local miniStartPosition

connect(MiniButton.InputBegan, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        miniDragging = true
        miniDragStart = input.Position
        miniStartPosition = MiniButton.Position

    end
end)

connect(UserInputService.InputChanged, function(input)

    if miniDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - miniDragStart

        MiniButton.Position = UDim2.new(
            miniStartPosition.X.Scale,
            miniStartPosition.X.Offset + delta.X,
            miniStartPosition.Y.Scale,
            miniStartPosition.Y.Offset + delta.Y
        )

    end
end)

connect(UserInputService.InputEnded, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        miniDragging = false

    end
end)

--// ============================================================
--// HEADER
--// ============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = Colors.Background2
Header.BorderSizePixel = 0
Header.Parent = Main

createCorner(Header, 14)

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, -190, 0, 30)
Logo.Position = UDim2.fromOffset(18, 8)
Logo.BackgroundTransparency = 1
Logo.Text = "🍪 COOKIES HUB MOBILE EDITION•PREMIUM"
Logo.Font = Enum.Font.GothamBlack
Logo.TextSize = 15
Logo.TextColor3 = Colors.White
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.TextTruncate = Enum.TextTruncate.AtEnd
Logo.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.fromOffset(250, 18)
Subtitle.Position = UDim2.fromOffset(20, 33)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "ALL-IN-ONE MOBILE CONTROL PANEL"
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 8
Subtitle.TextColor3 = Colors.RedLight
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.fromOffset(80, 25)
FPSLabel.Position = UDim2.new(1, -145, 0, 15)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: --"
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 10
FPSLabel.TextColor3 = Colors.Green
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.Parent = Header

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.fromOffset(32, 32)
MinimizeButton.Position = UDim2.new(1, -82, 0, 13)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Colors.White
MinimizeButton.Font = Enum.Font.GothamBlack
MinimizeButton.TextSize = 18
MinimizeButton.Parent = Header

createCorner(MinimizeButton, 8)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(32, 32)
CloseButton.Position = UDim2.new(1, -42, 0, 13)
CloseButton.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
CloseButton.Text = "×"
CloseButton.TextColor3 = Colors.RedLight
CloseButton.Font = Enum.Font.GothamBlack
CloseButton.TextSize = 20
CloseButton.Parent = Header

createCorner(CloseButton, 8)

--// ============================================================
--// SIDEBAR
--// ============================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 145, 1, -68)
Sidebar.Position = UDim2.fromOffset(10, 64)
Sidebar.BackgroundColor3 = Colors.Background2
Sidebar.BorderSizePixel = 0
Sidebar.ClipsDescendants = true
Sidebar.Parent = Main

createCorner(Sidebar, 10)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 5)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 10)
SidePadding.PaddingLeft = UDim.new(0, 8)
SidePadding.PaddingRight = UDim.new(0, 8)
SidePadding.Parent = Sidebar

--// ============================================================
--// CONTENT
--// ============================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -165, 1, -68)
Content.Position = UDim2.fromOffset(155, 64)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}
local SideButtons = {}

local function createPage(name)

    local page = Instance.new("ScrollingFrame")

    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Colors.Red
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    connect(
        layout:GetPropertyChangedSignal(
            "AbsoluteContentSize"
        ),
        function()

            page.CanvasSize = UDim2.fromOffset(
                0,
                layout.AbsoluteContentSize.Y + 10
            )

        end
    )

    Pages[name] = page

    return page
end

local function showPage(name)

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for buttonName, button in pairs(SideButtons) do

        if buttonName == name then

            button.BackgroundColor3 = Colors.Red
            button.TextColor3 = Colors.White

        else

            button.BackgroundColor3 =
                Color3.fromRGB(22, 22, 30)

            button.TextColor3 = Colors.Gray

        end
    end
end

local function createSideButton(name, icon)

    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    button.BorderSizePixel = 0
    button.Text = icon .. "  " .. name
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.TextColor3 = Colors.Gray
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.TextTruncate = Enum.TextTruncate.AtEnd
    button.Parent = Sidebar

    createCorner(button, 8)

    SideButtons[name] = button

    connect(button.MouseButton1Click, function()

        playClick()
        showPage(name)

    end)

    return button
end

local Dashboard = createPage("Dashboard")
local AutoStealPage = createPage("Auto Steal")
local PodiumsPage = createPage("Podiums")
local BasesPage = createPage("Bases")
local ESPPage = createPage("ESP")
local ServerPage = createPage("Server")
local SettingsPage = createPage("Settings")
local DefensePage = createPage("Defense")

createSideButton("Dashboard", "⌂")
createSideButton("Auto Steal", "⚡")
createSideButton("Podiums", "🐾")
createSideButton("Bases", "⌂")
createSideButton("ESP", "👁")
createSideButton("Server", "▣")
createSideButton("Settings", "⚙")
createSideButton("Defense", "🛡")

--// ============================================================
--// COMPONENTS
--// ============================================================

local function createTitle(parent, text, subtitle)

    local frame = Instance.new("Frame")

    frame.Size = UDim2.new(1, -10, 0, 52)
    frame.BackgroundColor3 = Colors.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    createCorner(frame, 9)

    local title = Instance.new("TextLabel")

    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.fromOffset(10, 6)
    title.BackgroundTransparency = 1
    title.Text = text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 15
    title.TextColor3 = Colors.White
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    if subtitle then

        local sub = Instance.new("TextLabel")

        sub.Size = UDim2.new(1, -20, 0, 17)
        sub.Position = UDim2.fromOffset(10, 29)
        sub.BackgroundTransparency = 1
        sub.Text = subtitle
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 9
        sub.TextColor3 = Colors.Gray
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = frame

    end

    return frame
end

local function createToggle(parent, text, default, callback)

    local row = Instance.new("Frame")

    row.Size = UDim2.new(1, -10, 0, 52)
    row.BackgroundColor3 = Colors.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    createCorner(row, 9)

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.fromOffset(14, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Colors.White
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local status = Instance.new("TextLabel")

    status.Size = UDim2.fromOffset(35, 20)
    status.Position = UDim2.new(1, -83, 0, 16)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamBold
    status.TextSize = 8
    status.Parent = row

    local toggle = Instance.new("TextButton")

    toggle.Size = UDim2.fromOffset(42, 22)
    toggle.Position = UDim2.new(1, -50, 0, 15)
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.Parent = row

    createCorner(toggle, 12)

    local circle = Instance.new("Frame")

    circle.Size = UDim2.fromOffset(16, 16)
    circle.BackgroundColor3 = Colors.White
    circle.Parent = toggle

    createCorner(circle, 10)

    local state = default

    local function update()

        status.Text = state and "ON" or "OFF"
        status.TextColor3 =
            state and Colors.Green or Colors.Gray

        TweenService:Create(
            toggle,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 =
                    state and Colors.Red
                    or Colors.DarkGray
            }
        ):Play()

        TweenService:Create(
            circle,
            TweenInfo.new(
                0.15,
                Enum.EasingStyle.Back
            ),
            {
                Position =
                    state
                    and UDim2.new(1, -19, 0, 3)
                    or UDim2.fromOffset(3, 3)
            }
        ):Play()
    end

    update()

    connect(toggle.MouseButton1Click, function()

        playClick()

        state = not state
        update()

        if callback then
            callback(state)
        end
    end)

    return {
        Get = function()
            return state
        end,

        Set = function(value)

            state = value
            update()

            if callback then
                callback(state)
            end
        end,
    }
end

local function createInfo(parent, text, color)

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1, -10, 0, 38)
    label.BackgroundColor3 = Colors.Card
    label.BorderSizePixel = 0
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = color or Colors.Gray
    label.Parent = parent

    createCorner(label, 8)

    return label
end

local function createAction(parent, text, callback)

    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -10, 0, 44)
    button.BackgroundColor3 = Colors.Card
    button.BorderSizePixel = 0
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextColor3 = Colors.White
    button.Parent = parent

    createCorner(button, 8)
    createStroke(button, Colors.DarkGray, 1)

    connect(button.MouseButton1Click, function()

        playClick()

        if callback then
            callback(button)
        end
    end)

    return button
end

--// ============================================================
--// DEFENSE
--// ============================================================

createTitle(
    DefensePage,
    "🛡️ DEFENSE",
    "Anti Bee • Anti Admin Panel • Anti Ragdoll"
)

createInfo(
    DefensePage,
    "Client-side protection sources integrated into Cookies Hub",
    Colors.RedLight
)

createToggle(
    DefensePage,
    "Anti Bee",
    false,
    function(value)
        Defense.AntiBee = value
        if value then enableAntiBee() else disableAntiBee() end
    end
)

createToggle(
    DefensePage,
    "Anti Admin Panel",
    false,
    function(value)
        Defense.AntiAdminPanel = value
        if value then enableAntiAdminPanel() else disableAntiAdminPanel() end
    end
)

createToggle(
    DefensePage,
    "Anti Ragdoll",
    false,
    function(value)
        Defense.AntiRagdoll = value
        if value then enableAntiRagdoll() else disableAntiRagdoll() end
    end
)

--// ============================================================
--// DASHBOARD
--// ============================================================

createTitle(
    Dashboard,
    "🍪 MOBILE EDITION",
    "COOKIES HUB • ALL-IN-ONE CONTROL PANEL"
)

createInfo(
    Dashboard,
    "ALL SYSTEMS  •  READY",
    Colors.Green
)

createToggle(
    Dashboard,
    "Watermark",
    true,
    function(value)
        Config.Watermark = value
    end
)

createInfo(
    Dashboard,
    "Auto Steal: "
    .. (Config.AutoSteal and "ON" or "OFF")
    .. "    |    Podiums: "
    .. (Config.Podiums and "ON" or "OFF"),
    Colors.RedLight
)

--// ============================================================
--// AUTO STEAL
--// ============================================================

createTitle(
    AutoStealPage,
    "⚡ AUTO STEAL",
    "Automatic proximity prompt handling"
)

local ProgressBarFill
local ProgressLabel
local ProgressPercent

local progressFrame = Instance.new("Frame")

progressFrame.Size = UDim2.new(1, -10, 0, 70)
progressFrame.BackgroundColor3 = Colors.Card
progressFrame.BorderSizePixel = 0
progressFrame.Parent = AutoStealPage

createCorner(progressFrame, 9)

ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(0.7, 0, 0, 25)
ProgressLabel.Position = UDim2.fromOffset(12, 7)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 11
ProgressLabel.TextColor3 = Colors.White
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.Parent = progressFrame

ProgressPercent = Instance.new("TextLabel")
ProgressPercent.Size = UDim2.new(0.25, 0, 0, 25)
ProgressPercent.Position = UDim2.new(0.72, 0, 0, 7)
ProgressPercent.BackgroundTransparency = 1
ProgressPercent.Text = ""
ProgressPercent.Font = Enum.Font.GothamBlack
ProgressPercent.TextSize = 11
ProgressPercent.TextColor3 = Colors.RedLight
ProgressPercent.Parent = progressFrame

local progressTrack = Instance.new("Frame")

progressTrack.Size = UDim2.new(1, -24, 0, 7)
progressTrack.Position = UDim2.fromOffset(12, 45)
progressTrack.BackgroundColor3 =
    Color3.fromRGB(30, 30, 38)
progressTrack.BorderSizePixel = 0
progressTrack.Parent = progressFrame

createCorner(progressTrack, 5)

ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Colors.Red
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.Parent = progressTrack

createCorner(ProgressBarFill, 5)

createToggle(
    AutoStealPage,
    "Auto Steal",
    Config.AutoSteal,
    function(value)
        Config.AutoSteal = value
    end
)

createInfo(
    AutoStealPage,
    "RADIUS  "
    .. Config.StealRadius
    .. " studs     •     DURATION  "
    .. Config.StealDuration
    .. "s",
    Colors.RedLight
)

--// ============================================================
--// PODIUMS
--// ============================================================

local PodiumHolder

local function setupPodiumMarkers()

    if PodiumHolder then
        PodiumHolder:Destroy()
    end

    PodiumHolder = Instance.new("Folder")
    PodiumHolder.Name = "__CookiesPodiumMarkers"
    PodiumHolder.Parent = workspace
end

local FLOOR_TOL = 8
local DEDUP_R = 10

local function baseBounds(slot)

    local target =
        slot:FindFirstChild("Base")
        or slot

    if target:IsA("Model") then

        local ok, cf, size =
            pcall(function()
                return target:GetBoundingBox()
            end)

        if ok then
            return cf, size
        end

    elseif target:IsA("BasePart") then

        return target.CFrame, target.Size

    end
end

local function makePodiumBox(cf, size)

    if not PodiumHolder then
        return
    end

    local part = Instance.new("Part")

    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 1
    part.Size = size
    part.CFrame = cf
    part.Parent = PodiumHolder

    local box = Instance.new("SelectionBox")

    box.Adornee = part
    box.Color3 = Colors.Blue
    box.SurfaceColor3 = Colors.Blue
    box.LineThickness = 0.06
    box.Transparency = 0
    box.SurfaceTransparency = 0.82
    box.Parent = part
end

local function getFloorOffsets()

    local Plots = workspace:FindFirstChild("Plots")

    if not Plots then
        return {}
    end

    local best

    for _, plot in ipairs(Plots:GetChildren()) do

        local pods =
            plot:FindFirstChild("AnimalPodiums")

        if pods then

            local ys = {}

            for _, slot in ipairs(pods:GetChildren()) do

                local cf = baseBounds(slot)

                if cf then
                    table.insert(
                        ys,
                        cf.Position.Y
                    )
                end
            end

            table.sort(ys)

            local levels = {}

            for _, y in ipairs(ys) do

                local exists = false

                for _, level in ipairs(levels) do

                    if math.abs(level - y)
                        <= FLOOR_TOL then

                        exists = true
                        break

                    end
                end

                if not exists then
                    table.insert(levels, y)
                end
            end

            if not best
                or #levels > #best then

                best = levels
            end
        end
    end

    local offsets = {}

    if best and #best >= 2 then

        for i = 2, #best do

            table.insert(
                offsets,
                best[i] - best[1]
            )
        end
    end

    return offsets
end

local function buildPodiums()

    if not Config.Podiums then
        return
    end

    local Plots =
        workspace:FindFirstChild("Plots")

    if not Plots then
        return
    end

    setupPodiumMarkers()

    local offsets =
        getFloorOffsets()

    for _, plot in ipairs(Plots:GetChildren()) do

        local pods =
            plot:FindFirstChild("AnimalPodiums")

        if pods then

            local slots = {}
            local live = {}
            local minY = math.huge

            for _, slot in ipairs(pods:GetChildren()) do

                local cf, size =
                    baseBounds(slot)

                if cf then

                    table.insert(
                        slots,
                        {
                            cf = cf,
                            size = size,
                        }
                    )

                    table.insert(
                        live,
                        cf.Position
                    )

                    minY =
                        math.min(
                            minY,
                            cf.Position.Y
                        )
                end
            end

            for _, slot in ipairs(slots) do
                makePodiumBox(
                    slot.cf,
                    slot.size
                )
            end

            for _, slot in ipairs(slots) do

                if slot.cf.Position.Y
                    <= minY + FLOOR_TOL then

                    for _, dy in ipairs(offsets) do

                        local up =
                            slot.cf
                            + Vector3.new(
                                0,
                                dy,
                                0
                            )

                        local exists = false

                        for _, position in ipairs(live) do

                            if (
                                position
                                - up.Position
                            ).Magnitude
                                <= DEDUP_R then

                                exists = true
                                break
                            end
                        end

                        if not exists then

                            makePodiumBox(
                                up,
                                slot.size
                            )
                        end
                    end
                end
            end
        end
    end
end

createTitle(
    PodiumsPage,
    "🐾 PODIUMS",
    "Visual podium markers"
)

createToggle(
    PodiumsPage,
    "Podium Markers",
    Config.Podiums,
    function(value)

        Config.Podiums = value

        if value then

            buildPodiums()

        elseif PodiumHolder then

            PodiumHolder:Destroy()
            PodiumHolder = nil

        end
    end
)

createAction(
    PodiumsPage,
    "↻  REBUILD MARKERS",
    function()

        if Config.Podiums then
            buildPodiums()
        end
    end
)

createInfo(
    PodiumsPage,
    "COLOR  •  CYAN / BLUE",
    Colors.Blue
)

--// ============================================================
--// BASES
--// ============================================================

local BASE_POSITIONS = {

    Vector3.new(
        -342.439,
        10.399,
        113.107
    ),

    Vector3.new(
        -342.439,
        10.465,
        6.107
    ),

    Vector3.new(
        -476.752,
        10.465,
        114.107
    ),

    Vector3.new(
        -476.752,
        10.465,
        7.107
    ),

    Vector3.new(
        -342.440,
        10.464,
        220.107
    ),

    Vector3.new(
        -476.752,
        10.465,
        221.107
    ),

    Vector3.new(
        -342.439,
        10.465,
        -100.893
    ),

    Vector3.new(
        -476.752,
        10.465,
        -99.893
    ),
}

local MATCH_TOL = 6
local EMPTY_TEXT = "Empty Base"

local NextAnchor
local NextBillboard
local BaseConnections = {}
local BaseData = {}

local function cleanupNextBase()

    for _, c in ipairs(BaseConnections) do

        pcall(function()
            c:Disconnect()
        end)
    end

    BaseConnections = {}
    BaseData = {}

    if NextAnchor then

        NextAnchor:Destroy()
        NextAnchor = nil

    end

    NextBillboard = nil
end

local function baseIndexFor(model)

    local ok, cf =
        pcall(function()
            return model:GetBoundingBox()
        end)

    if not ok then
        return nil
    end

    local position = cf.Position

    local bestIndex
    local bestDistance

    for i, basePosition in ipairs(
        BASE_POSITIONS
    ) do

        local dx =
            position.X - basePosition.X

        local dz =
            position.Z - basePosition.Z

        local distance =
            math.sqrt(
                dx * dx + dz * dz
            )

        if not bestDistance
            or distance < bestDistance then

            bestIndex = i
            bestDistance = distance
        end
    end

    if bestDistance
        and bestDistance <= MATCH_TOL then

        return bestIndex
    end
end

local function setupNextBase()

    cleanupNextBase()

    if not Config.NextBase then
        return
    end

    local Plots =
        workspace:FindFirstChild("Plots")

    if not Plots then
        return
    end

    NextAnchor = Instance.new("Part")

    NextAnchor.Name =
        "__CookiesNextBaseAnchor"

    NextAnchor.Anchored = true
    NextAnchor.CanCollide = false
    NextAnchor.CanQuery = false
    NextAnchor.CanTouch = false
    NextAnchor.Transparency = 1
    NextAnchor.Size =
        Vector3.new(1, 1, 1)

    NextAnchor.Parent = workspace

    NextBillboard =
        Instance.new("BillboardGui")

    NextBillboard.Size =
        UDim2.fromScale(30, 10)

    NextBillboard.StudsOffset =
        Vector3.new(0, 10, 0)

    NextBillboard.MaxDistance =
        math.huge

    NextBillboard.AlwaysOnTop = true
    NextBillboard.LightInfluence = 0
    NextBillboard.Enabled = false
    NextBillboard.Adornee = NextAnchor
    NextBillboard.Parent = NextAnchor

    local top =
        Instance.new("TextLabel")

    top.Size =
        UDim2.fromScale(1, 0.5)

    top.Position =
        UDim2.fromScale(0, 0.1)

    top.BackgroundTransparency = 1
    top.Text = "↓  NEXT  ↓"
    top.Font = Enum.Font.GothamBlack
    top.TextScaled = true
    top.TextColor3 = Colors.Green
    top.TextStrokeColor3 =
        Color3.new(0, 0, 0)

    top.TextStrokeTransparency = 0
    top.Parent = NextBillboard

    local bottom =
        Instance.new("TextLabel")

    bottom.Size =
        UDim2.fromScale(1, 0.4)

    bottom.Position =
        UDim2.fromScale(0, 0.58)

    bottom.BackgroundTransparency = 1
    bottom.Text = "EMPTY BASE"
    bottom.Font = Enum.Font.GothamBlack
    bottom.TextScaled = true
    bottom.TextColor3 = Colors.White
    bottom.TextStrokeColor3 =
        Color3.new(0, 0, 0)

    bottom.TextStrokeTransparency = 0
    bottom.Parent = NextBillboard

    local function isEmpty(label)

        return label.Text
            :gsub("^%s+", "")
            :gsub("%s+$", "")
            == EMPTY_TEXT
    end

    local function recompute()

        if not Config.NextBase then

            if NextBillboard then
                NextBillboard.Enabled = false
            end

            return
        end

        local target

        for i = 1, #BASE_POSITIONS do

            local data = BaseData[i]

            if data
                and data.label
                and isEmpty(data.label) then

                target = data
                break
            end
        end

        if target then

            NextAnchor.CFrame =
                target.cf

            NextBillboard.Enabled = true

        else

            NextBillboard.Enabled = false

        end
    end

    local function scan()

        for _, plot in ipairs(
            Plots:GetChildren()
        ) do

            local sign =
                plot:FindFirstChild(
                    "PlotSign"
                )

            local model =
                sign
                and sign:FindFirstChild(
                    "Model"
                )

            local gui =
                sign
                and sign:FindFirstChild(
                    "SurfaceGui"
                )

            local frame =
                gui
                and gui:FindFirstChild(
                    "Frame"
                )

            local label =
                frame
                and frame:FindFirstChild(
                    "TextLabel"
                )

            if model and label then

                local index =
                    baseIndexFor(model)

                if index then

                    local ok, cf =
                        pcall(function()
                            return model:GetBoundingBox()
                        end)

                    if ok then

                        BaseData[index] = {
                            label = label,
                            cf = cf,
                        }

                        table.insert(
                            BaseConnections,
                            label:GetPropertyChangedSignal(
                                "Text"
                            ):Connect(
                                recompute
                            )
                        )
                    end
                end
            end
        end

        recompute()
    end

    scan()

    table.insert(
        BaseConnections,
        Plots.DescendantAdded:Connect(
            function()
                task.defer(scan)
            end
        )
    )

    table.insert(
        BaseConnections,
        Plots.ChildAdded:Connect(
            function()
                task.defer(scan)
            end
        )
    )
end

createTitle(
    BasesPage,
    "🏠 BASES",
    "Find the next empty base"
)

createToggle(
    BasesPage,
    "Next Empty Base",
    Config.NextBase,
    function(value)

        Config.NextBase = value

        if value then
            setupNextBase()
        else
            cleanupNextBase()
        end
    end
)

createAction(
    BasesPage,
    "↻  RESCAN BASES",
    function()
        setupNextBase()
    end
)

--// ============================================================
--// ESP
--// ============================================================

local TimerESPObjects = {}
local AllowedESPObjects = {}

--// ============================================================
--// PLAYER ESP • RAINBOW
--// ============================================================

local PlayerESPObjects = {}
local RainbowHue = 0

local function getRainbowColor()
    return Color3.fromHSV(RainbowHue % 1, 1, 1)
end

local function removePlayerESP(player)

    local data = PlayerESPObjects[player]

    if not data then
        return
    end

    if data.highlight then
        pcall(function()
            data.highlight:Destroy()
        end)
    end

    if data.billboard then
        pcall(function()
            data.billboard:Destroy()
        end)
    end

    PlayerESPObjects[player] = nil
end

local function clearPlayerESP()

    for player in pairs(PlayerESPObjects) do
        removePlayerESP(player)
    end
end

local function createPlayerESP(player)

    if player == LocalPlayer or not Config.PlayerESP then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not character or not root then
        return
    end

    removePlayerESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "__CookiesRainbowPlayerESP"
    highlight.Adornee = character
    highlight.FillColor = getRainbowColor()
    highlight.FillTransparency = 0.45
    highlight.OutlineColor = getRainbowColor()
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "__CookiesRainbowPlayerESPInfo"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(240, 48)
    billboard.StudsOffset = Vector3.new(0, 3.3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2500
    billboard.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = getRainbowColor()
    label.TextStrokeColor3 = Colors.Black
    label.TextStrokeTransparency = 0
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = billboard

    PlayerESPObjects[player] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
end

local function updatePlayerESP()

    if not Config.PlayerESP then
        clearPlayerESP()
        return
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local rainbow = getRainbowColor()

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then

            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if character and root then

                local data = PlayerESPObjects[player]

                if not data or not data.billboard or not data.billboard.Parent then
                    createPlayerESP(player)
                    data = PlayerESPObjects[player]
                end

                if data then
                    if data.highlight then
                        data.highlight.FillColor = rainbow
                        data.highlight.OutlineColor = rainbow
                    end

                    if data.label then
                        data.label.TextColor3 = rainbow

                        local text = ""

                        if Config.PlayerESPNames then
                            text = "🍪 " .. player.DisplayName .. "  (@" .. player.Name .. ")"
                        end

                        if Config.PlayerESPDistance and myRoot then
                            local distance = math.floor((root.Position - myRoot.Position).Magnitude)

                            if text ~= "" then
                                text = text .. "\n"
                            end

                            text = text .. "📏 " .. distance .. " studs"
                        end

                        data.label.Text = text
                    end
                end
            else
                removePlayerESP(player)
            end
        end
    end
end

connect(Players.PlayerRemoving, function(player)
    removePlayerESP(player)
end)

connect(Players.PlayerAdded, function(player)
    connect(player.CharacterAdded, function()
        task.wait(0.5)
        if Config.PlayerESP then
            createPlayerESP(player)
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        connect(player.CharacterAdded, function()
            task.wait(0.5)
            if Config.PlayerESP then
                createPlayerESP(player)
            end
        end)
    end
end

--// ============================================================
--// TIMER ESP
--// ============================================================

local function clearTimerESP()

    for _, billboard in pairs(
        TimerESPObjects
    ) do

        if billboard
            and billboard.Parent then

            billboard:Destroy()
        end
    end

    table.clear(TimerESPObjects)
end

local function updateTimerESP()

    if not Config.TimerESP then
        return
    end

    local plots =
        workspace:FindFirstChild("Plots")

    if not plots then
        return
    end

    local seen = {}

    for _, plot in ipairs(
        plots:GetChildren()
    ) do

        local purchases =
            plot:FindFirstChild(
                "Purchases"
            )

        local plotBlock =
            purchases
            and purchases:FindFirstChild(
                "PlotBlock"
            )

        local mainPart =
            plotBlock
            and plotBlock:FindFirstChild(
                "Main"
            )

        local timeGui =
            mainPart
            and mainPart:FindFirstChild(
                "BillboardGui"
            )

        local timeLabel =
            timeGui
            and timeGui:FindFirstChild(
                "RemainingTime"
            )

        if mainPart and timeLabel then

            seen[plot] = true

            local billboard =
                TimerESPObjects[plot]

            if not billboard
                or not billboard.Parent then

                billboard =
                    Instance.new(
                        "BillboardGui"
                    )

                billboard.Name =
                    "__CookiesTimerESP"

                billboard.Size =
                    UDim2.fromOffset(
                        100,
                        32
                    )

                billboard.StudsOffset =
                    Vector3.new(0, 7, 0)

                billboard.AlwaysOnTop = true
                billboard.MaxDistance = 1500
                billboard.Adornee = mainPart
                billboard.Parent = plot

                local background =
                    Instance.new("Frame")

                background.Size =
                    UDim2.fromScale(1, 1)

                background.BackgroundColor3 =
                    Colors.Background

                background.BackgroundTransparency =
                    0.2

                background.BorderSizePixel = 0
                background.Parent = billboard

                createCorner(
                    background,
                    6
                )

                local stroke =
                    Instance.new("UIStroke")

                stroke.Color =
                    Colors.Blue

                stroke.Thickness = 1
                stroke.Parent =
                    background

                local label =
                    Instance.new("TextLabel")

                label.Name =
                    "TimerLabel"

                label.Size =
                    UDim2.fromScale(1, 1)

                label.BackgroundTransparency =
                    1

                label.Font =
                    Enum.Font.GothamBold

                label.TextSize = 11
                label.TextColor3 =
                    Colors.Blue

                label.TextStrokeTransparency =
                    0.3

                label.TextStrokeColor3 =
                    Colors.Black

                label.Parent =
                    background

                TimerESPObjects[plot] =
                    billboard
            end

            local label =
                billboard:FindFirstChild(
                    "TimerLabel",
                    true
                )

            if label then
                label.Text =
                    timeLabel.Text
            end
        end
    end

    for plot, billboard in pairs(
        TimerESPObjects
    ) do

        if not seen[plot] then

            if billboard
                and billboard.Parent then

                billboard:Destroy()
            end

            TimerESPObjects[plot] = nil
        end
    end
end

--// ============================================================
--// ALLOWED ESP
--// ============================================================

local function clearAllowedESP()

    for _, object in ipairs(
        AllowedESPObjects
    ) do

        if object
            and object.Parent then

            object:Destroy()
        end
    end

    table.clear(
        AllowedESPObjects
    )
end

local function updateAllowedESP()

    clearAllowedESP()

    if not Config.AllowedESP then
        return
    end

    local scanRoot =
        workspace:FindFirstChild("Plots")
        or workspace

    for _, prompt in ipairs(
        scanRoot:GetDescendants()
    ) do

        if prompt:IsA("ProximityPrompt") then

            local parent =
                prompt.Parent

            if parent
                and parent:IsA("BasePart") then

                local text =
                    string.lower(
                        prompt.ObjectText
                        or ""
                    )

                if string.find(
                    text,
                    "friends"
                ) then

                    local allowed =
                        string.find(
                            text,
                            "disallow"
                        ) ~= nil

                    local billboard =
                        Instance.new(
                            "BillboardGui"
                        )

                    billboard.Name =
                        "__CookiesAllowedESP"

                    billboard.Size =
                        UDim2.fromOffset(
                            160,
                            40
                        )

                    billboard.StudsOffset =
                        Vector3.new(0, 5, 0)

                    billboard.AlwaysOnTop = true
                    billboard.Adornee = parent
                    billboard.Parent = parent

                    local label =
                        Instance.new(
                            "TextLabel"
                        )

                    label.Size =
                        UDim2.fromScale(1, 1)

                    label.BackgroundTransparency =
                        1

                    label.Font =
                        Enum.Font.GothamBlack

                    label.TextSize = 15
                    label.TextStrokeTransparency =
                        0.3

                    label.TextStrokeColor3 =
                        Colors.Black

                    if allowed then

                        label.Text =
                            "✅ Allowed"

                        label.TextColor3 =
                            Colors.Green

                    else

                        label.Text =
                            "❌ Disallowed"

                        label.TextColor3 =
                            Colors.Red

                    end

                    label.Parent =
                        billboard

                    table.insert(
                        AllowedESPObjects,
                        billboard
                    )
                end
            end
        end
    end
end

--// ============================================================
--// CLONE ESP
--// ============================================================

local function highlightClone(model)

    if not Config.CloneESP then
        return
    end

    if not model:IsA("Model") then
        return
    end

    if not string.find(
        model.Name,
        "_Clone"
    ) then

        return
    end

    if not model:FindFirstChild(
        "__CookiesCloneESP"
    ) then

        local highlight =
            Instance.new("Highlight")

        highlight.Name =
            "__CookiesCloneESP"

        highlight.FillColor =
            Colors.Blue

        highlight.FillTransparency =
            0.4

        highlight.OutlineColor =
            Colors.White

        highlight.OutlineTransparency = 0

        highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        highlight.Parent = model
    end

    local head =
        model:FindFirstChild("Head")

    if head
        and not head:FindFirstChild(
            "__CookiesCloneLabel"
        ) then

        local billboard =
            Instance.new(
                "BillboardGui"
            )

        billboard.Name =
            "__CookiesCloneLabel"

        billboard.Adornee = head

        billboard.Size =
            UDim2.fromOffset(
                240,
                40
            )

        billboard.StudsOffset =
            Vector3.new(0, 3, 0)

        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label =
            Instance.new("TextLabel")

        label.Size =
            UDim2.fromScale(1, 1)

        label.BackgroundTransparency = 1
        label.Text = "👥 CLONE"
        label.TextColor3 =
            Colors.White

        label.TextSize = 14
        label.Font =
            Enum.Font.GothamBold

        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 =
            Colors.Black

        label.Parent = billboard
    end
end

local function clearCloneESP()

    for _, object in ipairs(
        workspace:GetDescendants()
    ) do

        if object.Name ==
            "__CookiesCloneESP"
            or object.Name ==
            "__CookiesCloneLabel" then

            object:Destroy()
        end
    end
end

--// ============================================================
--// LINE TO BASE
--// ============================================================

local LineBeam
local LineAttachment0
local LineAttachment1
local LineAnchor

local function findMyBasePosition()

    local plots =
        workspace:FindFirstChild("Plots")

    if not plots then
        return nil
    end

    for _, plot in ipairs(
        plots:GetChildren()
    ) do

        local sign =
            plot:FindFirstChild(
                "PlotSign"
            )

        if sign then

            local yourBase =
                sign:FindFirstChild(
                    "YourBase"
                )

            if yourBase
                and yourBase:IsA(
                    "BillboardGui"
                )
                and yourBase.Enabled then

                local ok, position =
                    pcall(function()

                        return plot:GetPivot()
                            .Position

                    end)

                if ok then
                    return position
                end
            end
        end
    end

    return nil
end

local function cleanupLineToBase()

    if LineBeam then
        LineBeam:Destroy()
        LineBeam = nil
    end

    if LineAttachment0 then
        LineAttachment0:Destroy()
        LineAttachment0 = nil
    end

    if LineAttachment1 then
        LineAttachment1:Destroy()
        LineAttachment1 = nil
    end

    if LineAnchor then
        LineAnchor:Destroy()
        LineAnchor = nil
    end
end

local function setupLineToBase()

    cleanupLineToBase()

    local character =
        LocalPlayer.Character

    local root =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
    end

    local position =
        findMyBasePosition()

    if not position then
        return
    end

    LineAnchor =
        Instance.new("Part")

    LineAnchor.Name =
        "__CookiesLineBaseAnchor"

    LineAnchor.Anchored = true
    LineAnchor.CanCollide = false
    LineAnchor.CanTouch = false
    LineAnchor.CanQuery = false
    LineAnchor.Transparency = 1
    LineAnchor.Size =
        Vector3.new(
            0.1,
            0.1,
            0.1
        )

    LineAnchor.CFrame =
        CFrame.new(position)

    LineAnchor.Parent = workspace

    LineAttachment0 =
        Instance.new("Attachment")

    LineAttachment0.Parent =
        root

    LineAttachment1 =
        Instance.new("Attachment")

    LineAttachment1.Parent =
        LineAnchor

    LineBeam =
        Instance.new("Beam")

    LineBeam.Name =
        "__CookiesLineToBase"

    LineBeam.Attachment0 =
        LineAttachment0

    LineBeam.Attachment1 =
        LineAttachment1

    LineBeam.FaceCamera = true
    LineBeam.LightInfluence = 0
    LineBeam.Width0 = 0.08
    LineBeam.Width1 = 0.08

    LineBeam.Transparency =
        NumberSequence.new({
            NumberSequenceKeypoint.new(
                0,
                0.1
            ),
            NumberSequenceKeypoint.new(
                1,
                0.7
            ),
        })

    LineBeam.Color =
        ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Colors.Red
            ),
            ColorSequenceKeypoint.new(
                0.5,
                Colors.RedLight
            ),
            ColorSequenceKeypoint.new(
                1,
                Colors.Red
            ),
        })

    LineBeam.Parent = root
end

--// ============================================================
--// X-RAY
--// ============================================================

local OriginalTransparency = {}
local XRAY_TRANSPARENCY = 0.6

local function applyXRay()

    local plots =
        workspace:FindFirstChild("Plots")

    if not plots then
        return
    end

    for _, plot in ipairs(
        plots:GetChildren()
    ) do

        local decorations =
            plot:FindFirstChild(
                "Decorations"
            )

        if decorations then

            for _, part in ipairs(
                decorations:GetDescendants()
            ) do

                if part:IsA("BasePart") then

                    if OriginalTransparency[part]
                        == nil then

                        OriginalTransparency[part] =
                            part.Transparency
                    end

                    part.Transparency =
                        XRAY_TRANSPARENCY
                end
            end
        end
    end
end

local function removeXRay()

    for part, transparency in pairs(
        OriginalTransparency
    ) do

        if part and part.Parent then

            part.Transparency =
                transparency
        end
    end

    table.clear(
        OriginalTransparency
    )
end

--// ============================================================
--// ESP PAGE
--// ============================================================

createTitle(
    ESPPage,
    "👁 ESP",
    "Advanced visual tools"
)

createInfo(
    ESPPage,
    "ESP • VISUAL SYSTEMS READY",
    Colors.RedLight
)

--// PLAYERS
createTitle(
    ESPPage,
    "👤 PLAYER ESP",
    "Rainbow player visualization"
)

createToggle(
    ESPPage,
    "Players ESP • RAINBOW",
    Config.PlayerESP,
    function(value)
        Config.PlayerESP = value

        if value then
            updatePlayerESP()
        else
            clearPlayerESP()
        end
    end
)

createToggle(
    ESPPage,
    "Player Names",
    Config.PlayerESPNames,
    function(value)
        Config.PlayerESPNames = value
        if Config.PlayerESP then
            updatePlayerESP()
        end
    end
)

createToggle(
    ESPPage,
    "Player Distance",
    Config.PlayerESPDistance,
    function(value)
        Config.PlayerESPDistance = value
        if Config.PlayerESP then
            updatePlayerESP()
        end
    end
)

createInfo(
    ESPPage,
    "RAINBOW • HIGHLIGHT + NAME + DISTANCE • 2500 STUDS",
    Colors.Blue
)

--// WORLD
createTitle(
    ESPPage,
    "🌎 WORLD ESP",
    "Visual information around the map"
)

createToggle(
    ESPPage,
    "Timer ESP",
    Config.TimerESP,
    function(value)

        Config.TimerESP = value

        if value then
            updateTimerESP()
        else
            clearTimerESP()
        end
    end
)

createToggle(
    ESPPage,
    "Allowed ESP",
    Config.AllowedESP,
    function(value)

        Config.AllowedESP = value

        if value then
            updateAllowedESP()
        else
            clearAllowedESP()
        end
    end
)

--// ENTITY
createTitle(
    ESPPage,
    "👥 ENTITY ESP",
    "Entity visualization"
)

createToggle(
    ESPPage,
    "Clone ESP",
    Config.CloneESP,
    function(value)

        Config.CloneESP = value

        if value then

            for _, object in ipairs(
                workspace:GetDescendants()
            ) do

                if object:IsA("Model") then
                    highlightClone(object)
                end
            end

        else

            clearCloneESP()

        end
    end
)

--// NAVIGATION
createTitle(
    ESPPage,
    "📍 NAVIGATION",
    "Navigation assistance"
)

createToggle(
    ESPPage,
    "Line to Base",
    Config.LineToBase,
    function(value)

        Config.LineToBase = value

        if value then
            setupLineToBase()
        else
            cleanupLineToBase()
        end
    end
)

--// VISUAL
createTitle(
    ESPPage,
    "🔍 VISUAL",
    "World visual settings"
)

createToggle(
    ESPPage,
    "X-Ray",
    Config.XRay,
    function(value)

        Config.XRay = value

        if value then
            applyXRay()
        else
            removeXRay()
        end
    end
)

createInfo(
    ESPPage,
    "ESP • TIMER / ALLOWED / CLONE / BASE / X-RAY",
    Colors.Blue
)

--// ============================================================
--// SERVER
--// ============================================================

local JobID = game.JobId

createTitle(
    ServerPage,
    "▣ SERVER",
    "Current server information"
)

local JobLabel =
    createInfo(
        ServerPage,
        "JOB ID\n" .. JobID,
        Colors.White
    )

JobLabel.TextWrapped = true
JobLabel.TextSize = 9

createAction(
    ServerPage,
    "📋  COPY JOB ID",
    function()

        if setclipboard then

            pcall(function()
                setclipboard(JobID)
            end)

        end
    end
)

createInfo(
    ServerPage,
    "SERVER ID: " .. JobID,
    Colors.Gray
)

--// ============================================================
--// SETTINGS
--// ============================================================

createTitle(
    SettingsPage,
    "⚙ SETTINGS",
    "Interface preferences"
)

createInfo(
    SettingsPage,
    "UI SIZE  •  AJUSTA EL TAMAÑO DEL PANEL",
    Colors.Blue
)

local SizeFrame = Instance.new("Frame")

SizeFrame.Size =
    UDim2.new(1, -10, 0, 78)

SizeFrame.BackgroundColor3 =
    Colors.Card

SizeFrame.BorderSizePixel = 0
SizeFrame.Parent = SettingsPage

createCorner(SizeFrame, 9)

local SizeLabel =
    Instance.new("TextLabel")

SizeLabel.Size =
    UDim2.new(1, -30, 0, 25)

SizeLabel.Position =
    UDim2.fromOffset(15, 6)

SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "SIZE: 100%"
SizeLabel.Font =
    Enum.Font.GothamBold

SizeLabel.TextSize = 10
SizeLabel.TextColor3 =
    Colors.White

SizeLabel.TextXAlignment =
    Enum.TextXAlignment.Left

SizeLabel.Parent = SizeFrame

local SizeTrack =
    Instance.new("Frame")

SizeTrack.Size =
    UDim2.new(1, -30, 0, 8)

SizeTrack.Position =
    UDim2.fromOffset(15, 47)

SizeTrack.BackgroundColor3 =
    Colors.DarkGray

SizeTrack.BorderSizePixel = 0
SizeTrack.Active = true
SizeTrack.Parent = SizeFrame

createCorner(SizeTrack, 5)

local SizeFill =
    Instance.new("Frame")

SizeFill.Size =
    UDim2.new(0.444, 0, 1, 0)

SizeFill.BackgroundColor3 =
    Colors.Red

SizeFill.BorderSizePixel = 0
SizeFill.Parent = SizeTrack

createCorner(SizeFill, 5)

local SizeKnob =
    Instance.new("TextButton")

SizeKnob.Size =
    UDim2.fromOffset(18, 18)

SizeKnob.Position =
    UDim2.new(
        0.444,
        -9,
        0.5,
        -9
    )

SizeKnob.BackgroundColor3 =
    Colors.White

SizeKnob.BorderSizePixel = 0
SizeKnob.Text = ""
SizeKnob.AutoButtonColor = false
SizeKnob.Parent = SizeTrack

createCorner(SizeKnob, 20)

local sizeDragging = false

local function updateSizeFromX(x)

    local left =
        SizeTrack.AbsolutePosition.X

    local width =
        SizeTrack.AbsoluteSize.X

    if width <= 0 then
        return
    end

    local percent =
        math.clamp(
            (x - left) / width,
            0,
            1
        )

    local scale =
        MIN_SCALE
        + (
            (MAX_SCALE - MIN_SCALE)
            * percent
        )

    setUIScale(scale)

    SizeFill.Size =
        UDim2.new(
            percent,
            0,
            1,
            0
        )

    SizeKnob.Position =
        UDim2.new(
            percent,
            -9,
            0.5,
            -9
        )

    SizeLabel.Text =
        "SIZE: "
        .. math.floor(
            scale * 100
        )
        .. "%"
end

connect(
    SizeTrack.InputBegan,
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            sizeDragging = true

            updateSizeFromX(
                input.Position.X
            )
        end
    end
)

connect(
    SizeKnob.InputBegan,
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            sizeDragging = true

            updateSizeFromX(
                input.Position.X
            )
        end
    end
)

connect(
    UserInputService.InputChanged,
    function(input)

        if sizeDragging and (
            input.UserInputType ==
                Enum.UserInputType.MouseMovement
            or input.UserInputType ==
                Enum.UserInputType.Touch
        ) then

            updateSizeFromX(
                input.Position.X
            )
        end
    end
)

connect(
    UserInputService.InputEnded,
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            sizeDragging = false
        end
    end
)

local function setPresetScale(scale)

    local percent =
        (
            scale - MIN_SCALE
        ) / (
            MAX_SCALE - MIN_SCALE
        )

    setUIScale(scale)

    SizeFill.Size =
        UDim2.new(
            percent,
            0,
            1,
            0
        )

    SizeKnob.Position =
        UDim2.new(
            percent,
            -9,
            0.5,
            -9
        )

    SizeLabel.Text =
        "SIZE: "
        .. math.floor(
            scale * 100
        )
        .. "%"
end

createAction(
    SettingsPage,
    "SMALL  •  80%",
    function()
        setPresetScale(0.80)
    end
)

createAction(
    SettingsPage,
    "NORMAL  •  100%",
    function()
        setPresetScale(1)
    end
)

createAction(
    SettingsPage,
    "LARGE  •  125%",
    function()
        setPresetScale(1.25)
    end
)

createAction(
    SettingsPage,
    "MINIMIZE  •  🍪",
    function()

        Main.Visible = false
        MiniButton.Visible = true

    end
)

createToggle(
    SettingsPage,
    "Click Sounds",
    Config.Sounds,
    function(value)
        Config.Sounds = value
    end
)

createToggle(
    SettingsPage,
    "COOKIES HUB Watermark",
    Config.Watermark,
    function(value)
        Config.Watermark = value
    end
)

createAction(
    SettingsPage,
    "↻  REBUILD ALL VISUALS",
    function()

        if Config.Podiums then
            buildPodiums()
        end

        if Config.NextBase then
            setupNextBase()
        end

        if Config.TimerESP then
            updateTimerESP()
        end

        if Config.AllowedESP then
            updateAllowedESP()
        end

        if Config.CloneESP then

            for _, object in ipairs(
                workspace:GetDescendants()
            ) do

                if object:IsA("Model") then
                    highlightClone(object)
                end
            end
        end

        if Config.LineToBase then
            setupLineToBase()
        end

        if Config.XRay then
            applyXRay()
        end
    end
)

--// ============================================================
--// MINIMIZE / RESTORE
--// ============================================================

local function minimizeHub()

    Main.Visible = false
    MiniButton.Visible = true
end

local function restoreHub()

    Main.Visible = true
    MiniButton.Visible = false
end

connect(
    MinimizeButton.MouseButton1Click,
    function()

        playClick()
        minimizeHub()
    end
)

connect(
    MiniButton.MouseButton1Click,
    function()

        playClick()
        restoreHub()
    end
)

--// ============================================================
--// WATERMARK
--// ============================================================

local Watermark =
    Instance.new("TextLabel")

Watermark.Size =
    UDim2.fromOffset(
        260,
        30
    )

Watermark.Position =
    UDim2.new(
        1,
        -275,
        1,
        -42
    )

Watermark.BackgroundTransparency = 1
Watermark.Text =
    "🍪 COOKIES HUB MOBILE EDITION"

Watermark.Font =
    Enum.Font.GothamBlack

Watermark.TextSize = 11
Watermark.TextColor3 =
    Colors.RedLight

Watermark.TextStrokeColor3 =
    Color3.new(0, 0, 0)

Watermark.TextStrokeTransparency =
    0.3

Watermark.TextXAlignment =
    Enum.TextXAlignment.Right

Watermark.Parent =
    ScreenGui

connect(
    RunService.Heartbeat,
    function()

        if Watermark
            and Watermark.Parent then

            Watermark.Visible =
                Config.Watermark
        end
    end
)

--// ============================================================
--// FPS
--// ============================================================

local frameCount = 0
local lastFPS = os.clock()

connect(
    RunService.RenderStepped,
    function()

        frameCount += 1

        local now = os.clock()
        local elapsed =
            now - lastFPS

        if elapsed >= 0.5 then

            local fps =
                math.floor(
                    frameCount / elapsed
                )

            frameCount = 0
            lastFPS = now

            FPSLabel.Text =
                "FPS: " .. fps

            if fps >= 60 then

                FPSLabel.TextColor3 =
                    Colors.Green

            elseif fps >= 30 then

                FPSLabel.TextColor3 =
                    Colors.Yellow

            else

                FPSLabel.TextColor3 =
                    Colors.Red
            end
        end
    end
)

--// ============================================================
--// AUTO STEAL
--// ============================================================

local isStealing = false
local stealStartTime = 0
local StealData = {}

local function isMyPlotByName(name)

    local Plots =
        workspace:FindFirstChild("Plots")

    if not Plots then
        return false
    end

    local plot =
        Plots:FindFirstChild(name)

    if not plot then
        return false
    end

    local sign =
        plot:FindFirstChild(
            "PlotSign"
        )

    if sign then

        local yourBase =
            sign:FindFirstChild(
                "YourBase"
            )

        if yourBase
            and yourBase:IsA(
                "BillboardGui"
            ) then

            return yourBase.Enabled == true
        end
    end

    return false
end

local function findNearestPrompt()

    local character =
        LocalPlayer.Character

    local root =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return nil
    end

    local Plots =
        workspace:FindFirstChild("Plots")

    if not Plots then
        return nil
    end

    local nearestPrompt
    local nearestDistance =
        math.huge

    local nearestName

    for _, plot in ipairs(
        Plots:GetChildren()
    ) do

        if not isMyPlotByName(
            plot.Name
        ) then

            local podiums =
                plot:FindFirstChild(
                    "AnimalPodiums"
                )

            if podiums then

                for _, podium in ipairs(
                    podiums:GetChildren()
                ) do

                    pcall(function()

                        local base =
                            podium:FindFirstChild(
                                "Base"
                            )

                        local spawn =
                            base
                            and base:FindFirstChild(
                                "Spawn"
                            )

                        if spawn then

                            local distance =
                                (
                                    spawn.Position
                                    - root.Position
                                ).Magnitude

                            if distance
                                < nearestDistance
                                and distance
                                <= Config.StealRadius then

                                local attachment =
                                    spawn:FindFirstChild(
                                        "PromptAttachment"
                                    )

                                if attachment then

                                    for _, child in ipairs(
                                        attachment:GetChildren()
                                    ) do

                                        if child:IsA(
                                            "ProximityPrompt"
                                        ) then

                                            nearestPrompt =
                                                child

                                            nearestDistance =
                                                distance

                                            nearestName =
                                                podium.Name

                                            break
                                        end
                                    end
                                end
                            end
                        end

                    end)
                end
            end
        end
    end

    return nearestPrompt,
        nearestDistance,
        nearestName
end

local function resetProgress()

    if ProgressLabel then
        ProgressLabel.Text = "READY"
    end

    if ProgressPercent then
        ProgressPercent.Text = ""
    end

    if ProgressBarFill then
        ProgressBarFill.Size =
            UDim2.new(
                0,
                0,
                1,
                0
            )
    end
end

local function executeSteal(
    prompt,
    name
)

    if isStealing then
        return
    end

    if not prompt then
        return
    end

    if not StealData[prompt] then

        StealData[prompt] = {
            hold = {},
            trigger = {},
            ready = true,
        }

        pcall(function()

            if getconnections then

                for _, c in ipairs(
                    getconnections(
                        prompt.PromptButtonHoldBegan
                    )
                ) do

                    if c.Function then

                        table.insert(
                            StealData[prompt].hold,
                            c.Function
                        )
                    end
                end

                for _, c in ipairs(
                    getconnections(
                        prompt.Triggered
                    )
                ) do

                    if c.Function then

                        table.insert(
                            StealData[prompt].trigger,
                            c.Function
                        )
                    end
                end
            end
        end)
    end

    local data =
        StealData[prompt]

    if not data.ready then
        return
    end

    data.ready = false
    isStealing = true
    stealStartTime = os.clock()

    ProgressLabel.Text =
        name or "STEALING..."

    task.spawn(function()

        while isStealing do

            local progress =
                math.clamp(
                    (
                        os.clock()
                        - stealStartTime
                    )
                    / Config.StealDuration,
                    0,
                    1
                )

            ProgressBarFill.Size =
                UDim2.new(
                    progress,
                    0,
                    1,
                    0
                )

            ProgressPercent.Text =
                math.floor(
                    progress * 100
                )
                .. "%"

            if progress >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end
    end)

    task.spawn(function()

        for _, fn in ipairs(
            data.hold
        ) do

            task.spawn(fn)
        end

        task.wait(
            Config.StealDuration
        )

        for _, fn in ipairs(
            data.trigger
        ) do

            task.spawn(fn)
        end

        isStealing = false
        data.ready = true

        resetProgress()
    end)
end

connect(
    RunService.Heartbeat,
    function()

        if not Config.AutoSteal
            or isStealing then

            return
        end

        local prompt, _, name =
            findNearestPrompt()

        if prompt then
            executeSteal(
                prompt,
                name
            )
        end
    end
)

--// ============================================================
--// PODIUM WATCHER
--// ============================================================

local podiumPending = false

local function schedulePodiumRebuild()

    if podiumPending then
        return
    end

    podiumPending = true

    task.delay(
        0.4,
        function()

            podiumPending = false

            if Config.Podiums then
                buildPodiums()
            end
        end
    )
end

local Plots =
    workspace:FindFirstChild("Plots")

if Plots then

    connect(
        Plots.ChildAdded,
        function(plot)

            task.spawn(function()

                local pods =
                    plot:WaitForChild(
                        "AnimalPodiums",
                        20
                    )

                if pods then

                    connect(
                        pods.ChildAdded,
                        schedulePodiumRebuild
                    )

                    connect(
                        pods.ChildRemoved,
                        schedulePodiumRebuild
                    )
                end
            end)

            schedulePodiumRebuild()
        end
    )

    for _, plot in ipairs(
        Plots:GetChildren()
    ) do

        task.spawn(function()

            local pods =
                plot:WaitForChild(
                    "AnimalPodiums",
                    20
                )

            if pods then

                connect(
                    pods.ChildAdded,
                    schedulePodiumRebuild
                )

                connect(
                    pods.ChildRemoved,
                    schedulePodiumRebuild
                )
            end
        end)
    end
end

--// ============================================================
--// ESP UPDATE LOOP
--// ============================================================

local playerAccumulator = 0
local timerAccumulator = 0
local allowedAccumulator = 0
local cloneAccumulator = 0
local xrayAccumulator = 0
local lineAccumulator = 0

connect(
    RunService.Heartbeat,
    function(dt)

        --// PLAYER ESP • RAINBOW
        RainbowHue = (RainbowHue + dt * 0.18) % 1

        if Config.PlayerESP then
            playerAccumulator += dt

            if playerAccumulator >= 0.10 then
                playerAccumulator = 0
                updatePlayerESP()
            end
        else
            playerAccumulator = 0
        end

        --// TIMER ESP
        if Config.TimerESP then

            timerAccumulator += dt

            if timerAccumulator >= 0.5 then

                timerAccumulator = 0

                updateTimerESP()
            end
        else

            timerAccumulator = 0
        end

        --// ALLOWED ESP
        if Config.AllowedESP then

            allowedAccumulator += dt

            if allowedAccumulator >= 1 then

                allowedAccumulator = 0

                updateAllowedESP()
            end
        else

            allowedAccumulator = 0
        end

        --// CLONE ESP
        if Config.CloneESP then

            cloneAccumulator += dt

            if cloneAccumulator >= 0.5 then

                cloneAccumulator = 0

                for _, object in ipairs(
                    workspace:GetDescendants()
                ) do

                    if object:IsA("Model") then
                        highlightClone(object)
                    end
                end
            end
        else

            cloneAccumulator = 0
        end

        --// X-RAY
        if Config.XRay then

            xrayAccumulator += dt

            if xrayAccumulator >= 0.5 then

                xrayAccumulator = 0

                applyXRay()
            end
        else

            xrayAccumulator = 0
        end

        --// LINE TO BASE
        if Config.LineToBase then

            lineAccumulator += dt

            if lineAccumulator >= 0.25 then

                lineAccumulator = 0

                local position =
                    findMyBasePosition()

                if position
                    and LineAnchor then

                    LineAnchor.CFrame =
                        CFrame.new(position)

                elseif not LineBeam then

                    setupLineToBase()
                end
            end
        else

            lineAccumulator = 0
        end
    end
)

--// ============================================================
--// INITIALIZE
--// ============================================================

showPage("Dashboard")

if Config.Podiums then
    task.spawn(buildPodiums)
end

if Config.NextBase then
    task.spawn(setupNextBase)
end

--// ============================================================
--// CLOSE / CLEANUP
--// ============================================================

local function cleanup()

    Config.AutoSteal = false
    Config.Podiums = false
    Config.NextBase = false
    Config.PlayerESP = false

    Config.TimerESP = false
    Config.AllowedESP = false
    Config.CloneESP = false
    Config.LineToBase = false
    Config.XRay = false

    isStealing = false

    --// Connections
    for _, connection in ipairs(
        Connections
    ) do

        pcall(function()
            connection:Disconnect()
        end)
    end

    Connections = {}

    --// Base
    cleanupNextBase()

    --// ESP
    clearPlayerESP()
    clearTimerESP()
    clearAllowedESP()
    clearCloneESP()
    cleanupLineToBase()
    removeXRay()

    --// Podiums
    if PodiumHolder then

        PodiumHolder:Destroy()
        PodiumHolder = nil
    end

    --// GUI
    if ScreenGui then
        ScreenGui:Destroy()
    end

    _G.__CookiesHubCleanup = nil
end

_G.__CookiesHubCleanup = cleanup

connect(
    CloseButton.MouseButton1Click,
    function()

        playClick()
        cleanup()
    end
)

print(
    "🍪 COOKIES HUB MOBILE EDITION + ESP loaded successfully."
)
