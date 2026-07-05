local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MouseNativo = LocalPlayer:GetMouse()

-- CONFIGURACIÓN GENERAL (ESTADOS TOGGLES ANTIGUOS)
local cfg = {
    Aimbot = false,
    FullBright = false,
    ESP = false,
    ClickToTP = false
}

local lock, targ, open = false, nil, true

local TeclaOcultarMenu = Enum.KeyCode.KeypadThree
local TeclaAimbot = Enum.KeyCode.F
local TeclaClickToTeleport = Enum.KeyCode.T

-- VALORES ORIGINALES RESPALDADOS
local oS = Lighting.GlobalShadows
local oA = Lighting.Ambient
local sosteniendoT = false

--------------------------------------------------------------------------------
-- 1. BASE DE LA INTERFAZ (FORMATO TRADICIONAL VISIBLE)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubTradicionalGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 250)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -40, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.Text = "⚡ TORO HUB V14 ⚡"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 16
TitleLabel.ZIndex = 2
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 16
CloseButton.ZIndex = 2
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseButton
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

--------------------------------------------------------------------------------
-- 2. ARRASTRE DE MENÚ COMPATIBLE
--------------------------------------------------------------------------------
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateDrag(input) end
end)

--------------------------------------------------------------------------------
-- 3. DETECTOR DE RAÍZ Y TARGETING
--------------------------------------------------------------------------------
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

function GetT()
    local obj, maxD, mP = nil, math.huge, UserInputService:GetMouseLocation()
    for _,v in pairs(Players:GetPlayers()) do 
        if v ~= LocalPlayer and v.Character and getRoot(v.Character) and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local p, onS = Camera:WorldToScreenPoint(getRoot(v.Character).Position)
            if onS then 
                local d = (Vector2.new(mP.X, mP.Y) - Vector2.new(p.X, p.Y)).Magnitude
                if d < maxD then maxD, obj = d, getRoot(v.Character) end 
            end 
        end 
    end; return obj 
end

--------------------------------------------------------------------------------
-- 4. BOTONES FORMATO TRADICIONAL TOGGLE (CON ENFOQUE ZINDEX SUPERIOR)
--------------------------------------------------------------------------------
local function CrearBotonToggle(ConfigKey, TextoBase, PosicionY)
    local Boton = Instance.new("TextButton")
    Boton.Size = UDim2.new(0, 210, 0, 35)
    Boton.Position = UDim2.new(0, 15, 0, PosicionY)
    Boton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Boton.Text = TextoBase .. ": OFF"
    Boton.TextColor3 = Color3.fromRGB(200, 50, 50)
    Boton.Font = Enum.Font.SourceSansBold
    Boton.TextSize = 14
    Boton.ZIndex = 5 -- Asegura renderizado superior absoluto
    Boton.Parent = MainFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Boton

    Boton.MouseButton1Click:Connect(function()
        cfg[ConfigKey] = not cfg[ConfigKey]
        if cfg[ConfigKey] then 
            Boton.Text = TextoBase .. ": ON"
            Boton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            Boton.TextColor3 = Color3.fromRGB(255, 255, 255)
        else 
            Boton.Text = TextoBase .. ": OFF"
            Boton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Boton.TextColor3 = Color3.fromRGB(200, 50, 50)
            if ConfigKey == "Aimbot" then lock, targ = false, nil end
        end
    end)
end

-- Posiciones fijas tradicionales escalonadas
CrearBotonToggle("Aimbot", "🎯 Habilitar Aimbot", 55)
CrearBotonToggle("FullBright", "💡 FullBright", 100)
CrearBotonToggle("ESP", "👁️ Ver Jugadores (ESP)", 145)
CrearBotonToggle("ClickToTP", "🌀 Click to TP (Tecla T)", 190)

--------------------------------------------------------------------------------
-- 5. ENTRADAS FISICAS (TECLADO / MOUSE)
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(i,p) 
    if not p then 
        if i.KeyCode == TeclaAimbot and cfg.Aimbot then 
            lock = not lock; if not lock then targ = nil end 
        elseif i.KeyCode == TeclaOcultarMenu then 
            open = not open; ScreenGui.Enabled = open 
        elseif i.KeyCode == TeclaClickToTeleport then
            sosteniendoT = true
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 and sosteniendoT and cfg.ClickToTP then
            pcall(function()
                if getRoot(LocalPlayer.Character) and MouseNativo.Hit then
                    getRoot(LocalPlayer.Character).CFrame = CFrame.new(MouseNativo.Hit.Position + Vector3.new(0, 3, 0))
                end
            end)
        end 
    end 
end)

UserInputService.InputEnded:Connect(function(i) if i.KeyCode == TeclaClickToTeleport then sosteniendoT = false end end)

--------------------------------------------------------------------------------
-- 6. PROCESAMIENTO NATIVO CONTINUO EN SEGUNDO PLANO (REPARADO)
--------------------------------------------------------------------------------
local fL = Instance.new("PointLight", Camera) fL.Range, fL.Brightness, fL.Enabled = 10000, 3, false

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- AIMBOT SYSTEM
        if cfg.Aimbot and lock then 
            if not targ or not targ.Parent or not targ.Parent:FindFirstChild("Humanoid") or targ.Parent.Humanoid.Health <= 0 then targ = GetT() end
            if targ then Camera.CFrame = CFrame.new(Camera.CFrame.Position, targ.Position) end 
        else targ = nil end
        
        -- FULLBRIGHT SYSTEM
        fL.Enabled = cfg.FullBright
        if cfg.FullBright then 
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255,255,255) 
        else 
            Lighting.GlobalShadows = oS
            Lighting.Ambient = oA 
        end
        
        -- ESP SYSTEM (HIGHLIGHT RECONSTRUIDO CON PROPIEDADES DIRECTAS)
        for _,v in pairs(Players:GetPlayers()) do 
            if v ~= LocalPlayer and v.Character then 
                local h = v.Character:FindFirstChild("ESPHl")
                if cfg.ESP then 
                    if not h and getRoot(v.Character) then 
                        h = Instance.new("Highlight")
                        h.Name = "ESPHl"
                        h.FillColor = Color3.fromRGB(255,0,0)
                        h.FillTransparency = 0.5
                        h.OutlineColor = Color3.fromRGB(255,255,255)
                        h.OutlineTransparency = 0
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.Adornee = v.Character
                        h.Parent = v.Character
                    end
                else 
                    if h then h:Destroy() end 
                end 
            end 
        end
    end)
end)
