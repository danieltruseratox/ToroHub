local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local cfg = {
    Aimbot = false,
    FullBright = false,
    ESP = false,
    ClickToTP = false
}

local lock = false
local target = nil
local menuOpen = true
local holdingT = false

local teclaOcultarMenu = Enum.KeyCode.KeypadThree
local teclaAimbot = Enum.KeyCode.F
local teclaClickToTeleport = Enum.KeyCode.T

local originalShadows = Lighting.GlobalShadows
local originalAmbient = Lighting.Ambient

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubTradicionalGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 250)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.Text = "⚡ TORO HUB V15 ⚡"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 16
CloseButton.Parent = MainFrame

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--------------------------------------------------------------------------------
-- Dragging
--------------------------------------------------------------------------------
local dragging = false
local dragStart
local startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

local function getClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local bestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local root = getRoot(player.Character)

            if humanoid and humanoid.Health > 0 and root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        closest = root
                    end
                end
            end
        end
    end

    return closest
end

--------------------------------------------------------------------------------
-- Toggle Buttons
--------------------------------------------------------------------------------
local function createToggleButton(configKey, text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 210, 0, 35)
    button.Position = UDim2.new(0, 15, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.Text = text .. ": OFF"
    button.TextColor3 = Color3.fromRGB(200, 50, 50)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        cfg[configKey] = not cfg[configKey]

        if cfg[configKey] then
            button.Text = text .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.Text = text .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            button.TextColor3 = Color3.fromRGB(200, 50, 50)

            if configKey == "Aimbot" then
                lock = false
                target = nil
            end
        end
    end)
end

createToggleButton("Aimbot", "🎯 Habilitar Aimbot", 55)
createToggleButton("FullBright", "💡 FullBright", 100)
createToggleButton("ESP", "👁️ Ver Jugadores (ESP)", 145)
createToggleButton("ClickToTP", "🌀 Click to TP (Tecla T)", 190)

--------------------------------------------------------------------------------
-- Inputs
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == teclaAimbot and cfg.Aimbot then
        lock = not lock
        if not lock then
            target = nil
        end

    elseif input.KeyCode == teclaOcultarMenu then
        menuOpen = not menuOpen
        ScreenGui.Enabled = menuOpen

    elseif input.KeyCode == teclaClickToTeleport then
        holdingT = true

    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and holdingT and cfg.ClickToTP then
        local characterRoot = getRoot(LocalPlayer.Character)
        if characterRoot and Mouse.Hit then
            characterRoot.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == teclaClickToTeleport then
        holdingT = false
    end
end)

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------
local fullBrightLight = Instance.new("PointLight")
fullBrightLight.Range = 10000
fullBrightLight.Brightness = 3
fullBrightLight.Enabled = false
fullBrightLight.Parent = Camera

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Aimbot
        if cfg.Aimbot and lock then
            if not target or not target.Parent or not target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Humanoid.Health <= 0 then
                target = getClosestTarget()
            end

            if target then
                local lookDirection = (target.Position - Camera.CFrame.Position).Unit
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookDirection)
            end
        else
            target = nil
        end

        -- Fullbright
        fullBrightLight.Enabled = cfg.FullBright
        if cfg.FullBright then
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1, 1, 1)
        else
            Lighting.GlobalShadows = originalShadows
            Lighting.Ambient = originalAmbient
        end

        -- ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("ESPHl")
                if cfg.ESP then
                    if not highlight and getRoot(player.Character) then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "ESPHl"
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
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
