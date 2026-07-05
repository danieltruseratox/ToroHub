local Players = game:GetService("Players")
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
    ClickToTP = false -- modo único: teletransportar a jugador cercano por clic
}

local originalShadows = Lighting.GlobalShadows
local originalAmbient = Lighting.Ambient

--------------------------------------------------------------------------------
-- UI (simplificada)
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
TitleLabel.Text = "⚡ TORO HUB - TP ÚNICO ⚡"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.Parent = MainFrame

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
-- Helpers
--------------------------------------------------------------------------------
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

local function getClosestTargetToCursor()
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
-- Botones / Toggles
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
        end
    end)

    return button
end

createToggleButton("ClickToTP", "🌀 Click to TP (a jugador cercano)", 100)

--------------------------------------------------------------------------------
-- Input: Teleport al clic -> jugador más cercano al cursor
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and cfg.ClickToTP then
        pcall(function()
            local myRoot = getRoot(LocalPlayer.Character)
            if not myRoot then return end

            local tgt = getClosestTargetToCursor()
            if tgt and tgt.Position then
                myRoot.CFrame = CFrame.new(tgt.Position + Vector3.new(0, 3, 0))
            end
        end)
    end
end)

--------------------------------------------------------------------------------
-- Loop: Fullbright y ESP opcionales
--------------------------------------------------------------------------------
local fullBrightLight = Instance.new("PointLight")
fullBrightLight.Range = 10000
fullBrightLight.Brightness = 3
fullBrightLight.Enabled = false
fullBrightLight.Parent = Camera

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Fullbright
        fullBrightLight.Enabled = cfg.FullBright
        if cfg.FullBright then
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1, 1, 1)
        else
            Lighting.GlobalShadows = originalShadows
            Lighting.Ambient = originalAmbient
        end

        -- ESP (mantiene comportamiento anterior)
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
