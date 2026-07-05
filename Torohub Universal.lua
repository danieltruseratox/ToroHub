-- ToroHub Universal
-- Script principal para Roblox con pestañas y animaciones

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local config = {
    Aimbot = false,
    FullBright = false,
    ESP = false,
    ClickToTP = false,
    Walkspeed = 16,
    JumpPower = 50,
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
        local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
        tween:Play()
        return tween
    end
    for property, value in pairs(properties) do
        instance[property] = value
    end
end

local function applyTheme(themeName)
    local theme = themePalette[themeName] or themePalette.Midnight
    Window.BackgroundColor3 = theme.Window
    TitleBar.BackgroundColor3 = theme.Title
    TitleText.TextColor3 = theme.Text
    CloseButton.BackgroundColor3 = theme.Accent
    CloseButton.TextColor3 = theme.Text

    for _, button in ipairs(tabButtons) do
        button.BackgroundColor3 = state.ActiveTab == button.Name and theme.TabActive or theme.TabInactive
        button.TextColor3 = theme.Text
    end

    for _, button in ipairs(allButtons) do
        if button:IsA("TextButton") and button ~= CloseButton then
            button.BackgroundColor3 = theme.Button
            button.TextColor3 = theme.Text
        end
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
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        safeTween(button, {BackgroundColor3 = themePalette[config.Theme].ButtonHover}, 0.1)
    end)
    button.MouseLeave:Connect(function()
        safeTween(button, {BackgroundColor3 = themePalette[config.Theme].Button}, 0.1)
    end)

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

-- UI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubUniversalGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 360, 0, 340)
Window.Position = UDim2.new(0.12, 0, 0.18, 0)
Window.BackgroundColor3 = themePalette[config.Theme].Window
Window.BorderSizePixel = 0
Window.Active = true
Window.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 16)
WindowCorner.Parent = Window

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 56)
TitleBar.BackgroundColor3 = themePalette[config.Theme].Title
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Window

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -120, 1, 0)
TitleText.Position = UDim2.new(0, 20, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ToroHub Universal"
TitleText.TextColor3 = themePalette[config.Theme].Text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 22
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 90, 0, 20)
VersionLabel.Position = UDim2.new(1, -110, 0, 14)
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
TabBar.Size = UDim2.new(1, -40, 0, 40)
TabBar.Position = UDim2.new(0, 20, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Window

local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -40, 1, -120)
contentArea.Position = UDim2.new(0, 20, 0, 110)
contentArea.BackgroundTransparency = 1
contentArea.Parent = Window

local tabButtons = {}
local allButtons = {CloseButton}
local tabFrames = {}
local activeTarget = nil

local pageNames = {"Main", "Misc", "Character", "Settings"}

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
    local button = createButton(name, UDim2.new(0, 80, 0, 36), UDim2.new(0, (index - 1) * 88, 0, 0), TabBar)
    button.Name = name
    button.TextSize = 13
    button.Text = name
    button.BackgroundColor3 = themePalette[config.Theme].TabInactive
    button.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
    table.insert(tabButtons, button)
    table.insert(allButtons, button)

    local frame = Instance.new("Frame")
    frame.Name = name .. "Page"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = contentArea
    tabFrames[name] = frame
end

-- Main page
local mainPage = tabFrames.Main
local mainLabel = createLabel("Funciones principales para combate y visión.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), mainPage)
createToggle("Aimbot", UDim2.new(0, 0, 0, 48), mainPage, "Aimbot")
createToggle("ESP", UDim2.new(0, 0, 0, 98), mainPage, "ESP")
createToggle("ClickToTP", UDim2.new(0, 0, 0, 148), mainPage, "ClickToTP")
local aimbotHint = createLabel("Pulsa F para bloquear el objetivo cuando Aimbot está activo.", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 198), mainPage)

-- Misc page
local miscPage = tabFrames.Misc
createToggle("FullBright", UDim2.new(0, 0, 0, 0), miscPage, "FullBright")
local flyButton = createButton("Teleport Mouse", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 60), miscPage)
flyButton.Text = "Teleport al Mouse"
flyButton.MouseButton1Click:Connect(function()
    local root = getRoot(LocalPlayer.Character)
    if root and Mouse.Hit then
        root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)
local miscLabel = createLabel("Utilidades rápidas para moverte y ajustar el entorno.", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 110), miscPage)

-- Character page
local characterPage = tabFrames.Character
local speedLabel = createLabel("Velocidad del personaje: " .. config.Walkspeed, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), characterPage)
local jumpLabel = createLabel("Potencia de salto: " .. config.JumpPower, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 34), characterPage)

local function updateCharacterLabels()
    speedLabel.Text = "Velocidad del personaje: " .. config.Walkspeed
    jumpLabel.Text = "Potencia de salto: " .. config.JumpPower
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = config.Walkspeed
            humanoid.JumpPower = config.JumpPower
        end
    end
end

local speedUp = createButton("+5 Velocidad", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 70), characterPage)
speedUp.MouseButton1Click:Connect(function()
    config.Walkspeed = math.clamp(config.Walkspeed + 5, 16, 200)
    updateCharacterLabels()
end)
local speedDown = createButton("-5 Velocidad", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 70), characterPage)
speedDown.MouseButton1Click:Connect(function()
    config.Walkspeed = math.clamp(config.Walkspeed - 5, 16, 200)
    updateCharacterLabels()
end)
local jumpUp = createButton("+5 Salto", UDim2.new(0, 150, 0, 40), UDim2.new(0, 0, 0, 130), characterPage)
jumpUp.MouseButton1Click:Connect(function()
    config.JumpPower = math.clamp(config.JumpPower + 5, 50, 250)
    updateCharacterLabels()
end)
local jumpDown = createButton("-5 Salto", UDim2.new(0, 150, 0, 40), UDim2.new(0, 170, 0, 130), characterPage)
jumpDown.MouseButton1Click:Connect(function()
    config.JumpPower = math.clamp(config.JumpPower - 5, 50, 250)
    updateCharacterLabels()
end)
local resetCharacter = createButton("Reset Personaje", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 190), characterPage)
resetCharacter.MouseButton1Click:Connect(function()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end)

-- Settings page
local settingsPage = tabFrames.Settings
local animationsToggle = createButton("Animaciones: ON", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 0), settingsPage)
animationsToggle.MouseButton1Click:Connect(function()
    config.Animations = not config.Animations
    animationsToggle.Text = "Animaciones: " .. (config.Animations and "ON" or "OFF")
end)

local themeButton = createButton("Cambiar Tema", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 60), settingsPage)
themeButton.MouseButton1Click:Connect(function()
    config.Theme = config.Theme == "Midnight" and "Aurora" or "Midnight"
    applyTheme(config.Theme)
    animationsToggle.Text = "Animaciones: " .. (config.Animations and "ON" or "OFF")
end)

local resetButton = createButton("Restaurar Tema", UDim2.new(0, 320, 0, 40), UDim2.new(0, 0, 0, 120), settingsPage)
resetButton.MouseButton1Click:Connect(function()
    config = {
        Aimbot = false,
        FullBright = false,
        ESP = false,
        ClickToTP = false,
        Walkspeed = 16,
        JumpPower = 50,
        Theme = config.Theme,
        Animations = config.Animations
    }
    state.AimbotLocked = false
    updateCharacterLabels()
    for _, button in ipairs(mainPage:GetChildren()) do
        if button:IsA("TextButton") and button.Name:find("Toggle") then
            button.Text = button.Text:gsub("ON", "OFF")
            safeTween(button, {BackgroundColor3 = themePalette[config.Theme].Button}, 0)
        end
    end
end)

local footerLabel = createLabel("Usa F para bloquear Aimbot, T + click para TP, Numpad 3 para ocultar UI.", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 250), Window)
footerLabel.TextColor3 = themePalette[config.Theme].Text

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.Ambient = originalLighting.Ambient
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

-- Helpers
local function getRoot(character)
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

local function getClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = getRoot(player.Character)

            if humanoid and humanoid.Health > 0 and rootPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDistance then
                        bestDistance = dist
                        closest = rootPart
                    end
                end
            end
        end
    end

    return closest
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == toggleKeys.Aimbot and config.Aimbot then
        state.AimbotLocked = not state.AimbotLocked
        if not state.AimbotLocked then
            activeTarget = nil
        end
    elseif input.KeyCode == toggleKeys.HideMenu then
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

-- Fullbright light
local fullBrightLight = Instance.new("PointLight")
fullBrightLight.Range = 10000
fullBrightLight.Brightness = 3
fullBrightLight.Enabled = false
fullBrightLight.Parent = Camera

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

setActiveTab("Main")
applyTheme(config.Theme)
updateCharacterLabels()

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
        else
            activeTarget = nil
        end

        -- FullBright
        applyFullBright(config.FullBright)

        -- ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("ESPHl")
                if config.ESP then
                    if not highlight and getRoot(player.Character) then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "ESPHl"
                        highlight.FillColor = Color3.fromRGB(255, 65, 65)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                    end
                else
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
        end
    end)
end)
