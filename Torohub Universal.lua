-- ToroHub Universal
-- Script principal para Roblox con pestañas, animaciones, anti-afk, weapons y combat

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local config = {
    Aimbot = false,
    FullBright = false,
    ESP = false,
    ClickToTP = false,
    AntiAFK = false,
    KillAura = false,
    ReachAura = false,
    AutoAttack = false,
    AutoEquip = false,
    Walkspeed = 16,
    JumpPower = 50,
    KillAuraRadius = 10,
    ReachAuraRadius = 12,
    Theme = "Midnight",
    Animations = true
}

local state = {
    AimbotLocked = false,
    UIOpen = true,
    HoldingTeleport = false,
    ActiveTab = "Main"
}

local toggleKeys = {
    HideMenu = Enum.KeyCode.KeypadThree,
    Aimbot = Enum.KeyCode.F,
    ClickToTP = Enum.KeyCode.T
}

local themePalette = {
    Midnight = {
        Window = Color3.fromRGB(18, 18, 30),
        Title = Color3.fromRGB(40, 40, 70),
        TabActive = Color3.fromRGB(85, 110, 255),
        TabInactive = Color3.fromRGB(50, 50, 80),
        Button = Color3.fromRGB(50, 50, 80),
        ButtonHover = Color3.fromRGB(75, 95, 170),
        Text = Color3.fromRGB(230, 230, 255),
        Accent = Color3.fromRGB(135, 170, 255)
    },
    Aurora = {
        Window = Color3.fromRGB(15, 25, 40),
        Title = Color3.fromRGB(35, 65, 90),
        TabActive = Color3.fromRGB(100, 200, 220),
        TabInactive = Color3.fromRGB(45, 60, 75),
        Button = Color3.fromRGB(45, 60, 85),
        ButtonHover = Color3.fromRGB(90, 165, 195),
        Text = Color3.fromRGB(240, 245, 255),
        Accent = Color3.fromRGB(100, 210, 180)
    }
}

local originalLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

local function safeTween(instance, properties, duration)
    if config.Animations then
        local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(instance, tweenInfo, properties)
        tween:Play()
        return tween
    end
    for property, value in pairs(properties) do
        instance[property] = value
    end
end

local function getRoot(character)
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

local function getClosestTarget()
    local closestTarget = nil
    local bestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Parent then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = getRoot(player.Character)
            if humanoid and humanoid.Health > 0 and rootPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDistance then
                        bestDistance = dist
                        closestTarget = rootPart
                    end
                end
            end
        end
    end

    return closestTarget
end

local function applyTheme(themeName)
    local theme = themePalette[themeName] or themePalette.Midnight
    Window.BackgroundColor3 = theme.Window
    TitleBar.BackgroundColor3 = theme.Title
    TitleText.TextColor3 = theme.Text
    CloseButton.BackgroundColor3 = theme.Accent
    CloseButton.TextColor3 = theme.Text

    for _, button in ipairs(allButtons) do
        if button ~= CloseButton and not button.IsTab then
            button.BackgroundColor3 = theme.Button
            button.TextColor3 = theme.Text
        end
    end

    for _, button in ipairs(tabButtons) do
        button.BackgroundColor3 = state.ActiveTab == button.Name and theme.TabActive or theme.TabInactive
        button.TextColor3 = theme.Text
    end
end

local function createButton(text, size, position, parent)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = themePalette[config.Theme].Button
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = themePalette[config.Theme].Text
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.TextWrapped = true
    button.TextScaled = false
    button.AutoButtonColor = false
    button.Parent = parent
    button.IsTab = parent == TabBar
    if button.IsTab then
        button.TextScaled = true
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        safeTween(button, {BackgroundColor3 = themePalette[config.Theme].ButtonHover}, 0.1)
    end)
    button.MouseLeave:Connect(function()
        if button.IsTab then
            local active = state.ActiveTab == button.Name
            safeTween(button, {BackgroundColor3 = active and themePalette[config.Theme].TabActive or themePalette[config.Theme].TabInactive}, 0.1)
        else
            safeTween(button, {BackgroundColor3 = themePalette[config.Theme].Button}, 0.1)
        end
    end)

    table.insert(allButtons, button)
    return button
end

local function createToggle(text, position, parent, stateKey)
    local button = createButton(text .. ": OFF", UDim2.new(0, 320, 0, 40), position, parent)
    button.Name = stateKey .. "Toggle"

    button.MouseButton1Click:Connect(function()
        config[stateKey] = not config[stateKey]
        if config[stateKey] then
            safeTween(button, {BackgroundColor3 = themePalette[config.Theme].Accent}, 0.15)
            button.Text = text .. ": ON"
            if stateKey == "Aimbot" then
                state.AimbotLocked = true
                activeTarget = getClosestTarget()
            end
        else
            safeTween(button, {BackgroundColor3 = themePalette[config.Theme].Button}, 0.15)
            button.Text = text .. ": OFF"
            if stateKey == "Aimbot" then
                state.AimbotLocked = false
                activeTarget = nil
            end
        end
    end)

    return button
end

local function createLabel(text, size, position, parent)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = themePalette[config.Theme].Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createSectionTitle(text, size, position, parent)
    local title = Instance.new("TextLabel")
    title.Size = size
    title.Position = position
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = themePalette[config.Theme].Accent
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = parent
    return title
end

-- UI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubUniversalGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 380, 0, 360)
Window.Position = UDim2.new(0.1, 0, 0.12, 0)
Window.BackgroundColor3 = themePalette[config.Theme].Window
Window.BorderSizePixel = 0
Window.Active = true
Window.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 18)
WindowCorner.Parent = Window

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 56)
TitleBar.BackgroundColor3 = themePalette[config.Theme].Title
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Window

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -140, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ToroHub Universal"
TitleText.TextColor3 = themePalette[config.Theme].Text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 22
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 100, 0, 20)
VersionLabel.Position = UDim2.new(1, -120, 0, 16)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v1.0"
VersionLabel.TextColor3 = themePalette[config.Theme].Text
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = 12
VersionLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 42, 0, 42)
CloseButton.Position = UDim2.new(1, -52, 0, 7)
CloseButton.BackgroundColor3 = themePalette[config.Theme].Accent
CloseButton.Text = "X"
CloseButton.TextColor3 = themePalette[config.Theme].Text
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 12)
CloseCorner.Parent = CloseButton

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.new(0, 20, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Window

local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -40, 1, -130)
contentArea.Position = UDim2.new(0, 20, 0, 110)
contentArea.BackgroundTransparency = 1
contentArea.Parent = Window

local tabButtons = {}
local allButtons = {CloseButton}
local tabFrames = {}
local activeTarget = nil
local espHighlights = {}

local pageNames = {"Main", "Misc", "Character", "Combat", "Weapons", "Settings"}

local function setActiveTab(name)
    state.ActiveTab = name
    for tabName, frame in pairs(tabFrames) do
        frame.Visible = tabName == name
        if config.Animations then
            safeTween(frame, {BackgroundTransparency = tabName == name and 0 or 1}, 0.2)
        end
    end
    for _, button in ipairs(tabButtons) do
        local active = button.Name == name
        safeTween(button, {BackgroundColor3 = active and themePalette[config.Theme].TabActive or themePalette[config.Theme].TabInactive}, 0.2)
    end
end

for index, name in ipairs(pageNames) do
    local buttonSize = UDim2.new(0, 60, 0, 36)
    local button = createButton(name, buttonSize, UDim2.new(0, (index - 1) * 63, 0, 0), TabBar)
    button.Name = name
    button.TextSize = 12
    button.BackgroundColor3 = themePalette[config.Theme].TabInactive
    button.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
    table.insert(tabButtons, button)

    local frame = Instance.new("Frame")
    frame.Name = name .. "Page"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = contentArea
    tabFrames[name] = frame
end

-- Main page
local mainPage = tabFrames.Main
createSectionTitle("Principal", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), mainPage)
createToggle("Aimbot", UDim2.new(0, 0, 0, 40), mainPage, "Aimbot")
createToggle("ESP", UDim2.new(0, 0, 0, 90), mainPage, "ESP")
createToggle("ClickToTP", UDim2.new(0, 0, 0, 140), mainPage, "ClickToTP")
createLabel("F = bloquear aimbot | T + click = TP | Numpad 3 = ocultar UI", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 195), mainPage)

-- Misc page
local miscPage = tabFrames.Misc
createSectionTitle("Utilidades", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), miscPage)
createToggle("FullBright", UDim2.new(0, 0, 0, 40), miscPage, "FullBright")
createToggle("AntiAFK", UDim2.new(0, 0, 0, 90), miscPage, "AntiAFK")
local teleportButton = createButton("Teleport al Mouse", UDim2.new(0, 320, 0, 42), UDim2.new(0, 0, 0, 140), miscPage)
teleportButton.MouseButton1Click:Connect(function()
    local root = getRoot(LocalPlayer.Character)
    if root and Mouse.Hit then
        root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)
createLabel("AntiAFK mantendrá tu sesión activa. Teleport solo mueve tu personaje al punto del mouse.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 190), miscPage)

-- Character page
local characterPage = tabFrames.Character
createSectionTitle("Personaje", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), characterPage)
local speedLabel = createLabel("Velocidad: " .. config.Walkspeed, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 40), characterPage)
local jumpLabel = createLabel("Salto: " .. config.JumpPower, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 70), characterPage)

local function updateCharacterLabels()
    speedLabel.Text = "Velocidad: " .. config.Walkspeed
    jumpLabel.Text = "Salto: " .. config.JumpPower
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = config.Walkspeed
            humanoid.JumpPower = config.JumpPower
        end
    end
end

local speedUp = createButton("+5 Velocidad", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 110), characterPage)
speedUp.MouseButton1Click:Connect(function()
    config.Walkspeed = math.clamp(config.Walkspeed + 5, 16, 300)
    updateCharacterLabels()
end)

local speedDown = createButton("-5 Velocidad", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 110), characterPage)
speedDown.MouseButton1Click:Connect(function()
    config.Walkspeed = math.clamp(config.Walkspeed - 5, 16, 300)
    updateCharacterLabels()
end)

local jumpUp = createButton("+5 Salto", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 170), characterPage)
jumpUp.MouseButton1Click:Connect(function()
    config.JumpPower = math.clamp(config.JumpPower + 5, 50, 300)
    updateCharacterLabels()
end)

local jumpDown = createButton("-5 Salto", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 170), characterPage)
jumpDown.MouseButton1Click:Connect(function()
    config.JumpPower = math.clamp(config.JumpPower - 5, 50, 300)
    updateCharacterLabels()
end)

local resetCharacter = createButton("Reset Personaje", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 230), characterPage)
resetCharacter.MouseButton1Click:Connect(function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

-- Combat page
local combatPage = tabFrames.Combat
createSectionTitle("Combate", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), combatPage)
createToggle("KillAura", UDim2.new(0, 0, 0, 40), combatPage, "KillAura")
createToggle("AutoAttack", UDim2.new(0, 0, 0, 90), combatPage, "AutoAttack")
local killRadiusLabel = createLabel("Radio Kill Aura: " .. config.KillAuraRadius .. " studs", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 150), combatPage)
local radiusUp = createButton("+2 Radio", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 180), combatPage)
radiusUp.MouseButton1Click:Connect(function()
    config.KillAuraRadius = math.clamp(config.KillAuraRadius + 2, 6, 30)
    killRadiusLabel.Text = "Radio Kill Aura: " .. config.KillAuraRadius .. " studs"
end)
local radiusDown = createButton("-2 Radio", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 180), combatPage)
radiusDown.MouseButton1Click:Connect(function()
    config.KillAuraRadius = math.clamp(config.KillAuraRadius - 2, 6, 30)
    killRadiusLabel.Text = "Radio Kill Aura: " .. config.KillAuraRadius .. " studs"
end)
createLabel("Kill Aura elimina enemigos cercanos. AutoAttack inflige daño constante.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 240), combatPage)

-- Weapons page
local weaponsPage = tabFrames.Weapons
createSectionTitle("Weapons", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), weaponsPage)
createToggle("ReachAura", UDim2.new(0, 0, 0, 40), weaponsPage, "ReachAura")
createToggle("AutoEquip", UDim2.new(0, 0, 0, 90), weaponsPage, "AutoEquip")
local reachLabel = createLabel("Radio Reach: " .. config.ReachAuraRadius .. " studs", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 140), weaponsPage)
local reachUp = createButton("+2 Reach", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 170), weaponsPage)
reachUp.MouseButton1Click:Connect(function()
    config.ReachAuraRadius = math.clamp(config.ReachAuraRadius + 2, 6, 30)
    reachLabel.Text = "Radio Reach: " .. config.ReachAuraRadius .. " studs"
end)
local reachDown = createButton("-2 Reach", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 170), weaponsPage)
reachDown.MouseButton1Click:Connect(function()
    config.ReachAuraRadius = math.clamp(config.ReachAuraRadius - 2, 6, 30)
    reachLabel.Text = "Radio Reach: " .. config.ReachAuraRadius .. " studs"
end)
local equipButton = createButton("Equipar herramienta", UDim2.new(0, 320, 0, 42), UDim2.new(0, 0, 0, 220), weaponsPage)
equipButton.MouseButton1Click:Connect(function()
    if LocalPlayer.Backpack then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild(item.Name) then
                item.Parent = LocalPlayer.Character
                break
            end
        end
    end
end)
createLabel("AutoEquip equipa tu primera herramienta disponible.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 270), weaponsPage)

-- Settings page
local settingsPage = tabFrames.Settings
createSectionTitle("Ajustes", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), settingsPage)
local animationsToggle = createButton("Animaciones: ON", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 40), settingsPage)
animationsToggle.MouseButton1Click:Connect(function()
    config.Animations = not config.Animations
    animationsToggle.Text = "Animaciones: " .. (config.Animations and "ON" or "OFF")
end)
local themeButton = createButton("Cambiar Tema", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 100), settingsPage)
themeButton.MouseButton1Click:Connect(function()
    config.Theme = config.Theme == "Midnight" and "Aurora" or "Midnight"
    applyTheme(config.Theme)
    animationsToggle.Text = "Animaciones: " .. (config.Animations and "ON" or "OFF")
end)
local resetButton = createButton("Restaurar valores", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 160), settingsPage)
resetButton.MouseButton1Click:Connect(function()
    config.Aimbot = false
    config.FullBright = false
    config.ESP = false
    config.ClickToTP = false
    config.AntiAFK = false
    config.KillAura = false
    config.ReachAura = false
    config.AutoAttack = false
    config.AutoEquip = false
    config.Walkspeed = 16
    config.JumpPower = 50
    config.KillAuraRadius = 10
    config.ReachAuraRadius = 12
    state.AimbotLocked = false
    updateCharacterLabels()
    applyFullBright(config.FullBright)
    reachLabel.Text = "Radio Reach: " .. config.ReachAuraRadius .. " studs"
    killRadiusLabel.Text = "Radio Kill Aura: " .. config.KillAuraRadius .. " studs"
    animationsToggle.Text = "Animaciones: " .. (config.Animations and "ON" or "OFF")
    for _, frame in pairs(tabFrames) do
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Toggle") then
                child.Text = child.Text:gsub("ON", "OFF")
                safeTween(child, {BackgroundColor3 = themePalette[config.Theme].Button}, 0)
            end
        end
    end
end)
createLabel("Anti-AFK, weapons y combat están activos en pestañas separadas.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 220), settingsPage)

local footerLabel = createLabel("Numpad 3 para ocultar UI | usa las pestañas para navegar.", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 300), Window)
footerLabel.TextColor3 = themePalette[config.Theme].Text
footerLabel.TextXAlignment = Enum.TextXAlignment.Center

CloseButton.MouseButton1Click:Connect(function()
    state.UIOpen = false
    ScreenGui.Enabled = false
end)

-- Dragging
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Window.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

LocalPlayer.Idled:Connect(function()
    if config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0))
        wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0))
    end
end)

local function onCharacterAdded(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = config.Walkspeed
        humanoid.JumpPower = config.JumpPower
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

local function applyFullBright(enable)
    fullBrightLight.Enabled = enable
    if enable then
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
    else
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
    end
end

local function applyWeaponAssist()
    if config.AutoEquip and LocalPlayer.Character and LocalPlayer.Backpack then
        local equippedTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not equippedTool then
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item:IsA("Tool") then
                    item.Parent = LocalPlayer.Character
                    break
                end
            end
        end
    end
end

local fullBrightLight = Instance.new("PointLight")
fullBrightLight.Range = 10000
fullBrightLight.Brightness = 3
fullBrightLight.Enabled = false
fullBrightLight.Parent = Camera

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        if espHighlights[player].Parent then
            espHighlights[player]:Destroy()
        end
        espHighlights[player] = nil
    end
end)

setActiveTab("Main")
applyTheme(config.Theme)
updateCharacterLabels()
applyFullBright(config.FullBright)

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Aimbot
        if config.Aimbot and state.AimbotLocked then
            if not activeTarget or not activeTarget.Parent or not activeTarget.Parent:FindFirstChildOfClass("Humanoid") or activeTarget.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
                activeTarget = getClosestTarget()
            end
            if activeTarget then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, activeTarget.Position)
            end
        end

        -- Weapons / Combat
        applyWeaponAssist()
        if LocalPlayer.Character then
            local localRoot = getRoot(LocalPlayer.Character)
            if localRoot then
                local toolEquipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        local rootPart = getRoot(player.Character)
                        if humanoid and humanoid.Health > 0 and rootPart then
                            local distance = (localRoot.Position - rootPart.Position).Magnitude
                            if config.KillAura and distance <= config.KillAuraRadius then
                                humanoid.Health = 0
                            end
                            if config.ReachAura and toolEquipped and distance <= config.ReachAuraRadius then
                                humanoid:TakeDamage(15)
                            end
                            if config.AutoAttack and distance <= config.ReachAuraRadius then
                                humanoid:TakeDamage(10)
                            end
                        end
                    end
                end
            end
        end

        -- FullBright
        applyFullBright(config.FullBright)

        -- ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character.Parent then
                local rootPart = getRoot(player.Character)
                local highlight = espHighlights[player]
                if config.ESP and rootPart then
                    if not highlight or not highlight.Parent then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "ESPHl"
                        highlight.FillColor = Color3.fromRGB(255, 65, 65)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Enabled = true
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                        espHighlights[player] = highlight
                    else
                        highlight.Adornee = player.Character
                        highlight.Enabled = true
                    end
                else
                    if highlight and highlight.Parent then
                        highlight:Destroy()
                    end
                    espHighlights[player] = nil
                end
            else
                if espHighlights[player] then
                    if espHighlights[player].Parent then
                        espHighlights[player]:Destroy()
                    end
                    espHighlights[player] = nil
                end
            end
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == toggleKeys.Aimbot and config.Aimbot then
        state.AimbotLocked = not state.AimbotLocked
        if not state.AimbotLocked then
            activeTarget = nil
        end
    elseif input.KeyCode == toggleKeys.HideMenu or input.KeyCode == Enum.KeyCode.Three then
        state.UIOpen = not state.UIOpen
        ScreenGui.Enabled = state.UIOpen
    elseif input.KeyCode == toggleKeys.ClickToTP then
        state.HoldingTeleport = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and state.HoldingTeleport and config.ClickToTP then
        local characterRoot = getRoot(LocalPlayer.Character)
        if characterRoot and Mouse.Hit then
            characterRoot.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == toggleKeys.ClickToTP then
        state.HoldingTeleport = false
    end
end)
