-- =============================================================================
-- ████████╗ ██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗ 
-- ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
--    ██║   ██║   ██║██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
--    ██║   ██║   ██║██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔══██╗
--    ██║   ╚██████╔╝██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║  ██║
--    ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
-- =============================================================================
-- INTERFAZ REDISEÑADA CON COORDENADAS FIJAS ABSOLUTAS ANTI-PANTALLA NEGRA

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MouseNativo = LocalPlayer:GetMouse()

-- CONFIGURACIÓN GENERAL (ESTADOS)
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

-- VALORES ORIGINALES
local oS, oA = Lighting.GlobalShadows, Lighting.Ambient
local oFogEnd, oFogStart = Lighting.FogEnd, Lighting.FogStart
local sosteniendoT = false

--------------------------------------------------------------------------------
-- 1. BASE DE LA INTERFAZ (UI PRINCIPAL)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubDefinitivoGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 250)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -40, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleLabel.Text = "⚡ TORO HUB V13 ⚡"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.ZIndex = 2
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleLabel

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -38, 0, 2)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 14
CloseButton.ZIndex = 2
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

--------------------------------------------------------------------------------
-- 2. ARRASTRE DE MENÚ COMPATIBLE CON XENO
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
-- 3. LOGICA Y DETERMINACION DE EXTREMIDADES (TARGETING)
--------------------------------------------------------------------------------
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

function GetT()
    local obj, maxD, mP = nil, math.huge, UIS:GetMouseLocation()
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
-- 4. OPTIMIZADOR INTELLIGENT DE FPS
--------------------------------------------------------------------------------
local function AplicarOptimizarMundo(Activar)
    pcall(function()
        if Activar then
            Lighting.FogEnd, Lighting.FogStart = 999999, 999999
            for _, e in pairs(Lighting:GetChildren()) do if e:IsA("Clouds") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("BloomEffect") then e.Enabled = false end end
            for _, o in pairs(workspace:GetDescendants()) do
                if not o:IsDescendantOf(LocalPlayer.Character) and not Players:GetPlayerFromCharacter(o.Parent) then
                    if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Sparkles") then o.Enabled = false 
                    elseif o:IsA("Decal") or o:IsA("Texture") then if o.Name ~= "face" and not o.Parent:IsA("Shirt") and not o.Parent:IsA("Pants") then o.Transparency = 1 end end
                end
            end
        else
            Lighting.FogEnd, Lighting.FogStart = oFogEnd, oFogStart
            for _, e in pairs(Lighting:GetChildren()) do if e:IsA("Clouds") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("BloomEffect") then e.Enabled = true end end
            for _, o in pairs(workspace:GetDescendants()) do
                if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Sparkles") then o.Enabled = true 
                elseif o:IsA("Decal") or o:IsA("Texture") then if o.Name ~= "face" then o.Transparency = 0 end end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 5. CREACIÓN DE BOTONES MANUALES CON COORDENADAS COHESIVAS ABSOLUTAS
--------------------------------------------------------------------------------
local function CrearBotonFijo(ConfigKey, TextoBase, PosicionY)
    local Boton = Instance.new("TextButton")
    Boton.Size = UDim2.new(0, 210, 0, 35)
    Boton.Position = UDim2.new(0, 15, 0, PosicionY) -- Coordenadas fijas en pixeles exactos
    Boton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Boton.Text = TextoBase .. ": OFF"
    Boton.TextColor3 = Color3.fromRGB(220, 60, 60)
    Boton.Font = Enum.Font.SourceSansBold
    Boton.TextSize = 13
    Boton.ZIndex = 5 -- Máxima capa superior: imposibilita quedar oculto tras el fondo
    Boton.Parent = MainFrame

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Boton

    Boton.MouseButton1Click:Connect(function()
        cfg[ConfigKey] = not cfg[ConfigKey]
        if cfg[ConfigKey] then 
            Boton.Text = TextoBase .. ": ON"
            Boton.BackgroundColor3 = Color3.fromRGB(45, 140, 45)
            Boton.TextColor3 = Color3.fromRGB(255, 255, 255)
            if ConfigKey == "FullBright" then AplicarOptimizarMundo(true) end
        else 
            Boton.Text = TextoBase .. ": OFF"
            Boton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Boton.TextColor3 = Color3.fromRGB(220, 60, 60)
            if ConfigKey == "FullBright" then AplicarOptimizarMundo(false) end
            if ConfigKey == "Aimbot" then lock, targ = false, nil end
        end
    end)
end

-- Posicionamiento vertical escalonado (Evita encimamientos)
CrearBotonFijo("Aimbot", "🎯 Permitir Aimbot", 55)
CrearBotonFijo("FullBright", "💡 Iluminación + FPS", 100)
CrearBotonFijo("ESP", "👁️ Ver Jugadores (ESP)", 145)
CrearBotonFijo("ClickToTP", "🌀 Click to TP (Tecla T)", 190)

--------------------------------------------------------------------------------
-- 6. CAPTURA DE EVENTOS Y ENTRADAS (TECLADO / MOUSE)
--------------------------------------------------------------------------------
UIS.InputBegan:Connect(function(i,p) 
    if not p then 
        if i.KeyCode == TeclaAimbot and cfg.Aimbot then 
            lock = not lock; if not lock then targ = nil end 
        elseif i.KeyCode == TeclaOcultarMenu then 
            open = not open; G.Enabled = open 
        elseif i.KeyCode == TeclaClickToTeleport then
            sosteniendoT = true
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 and sosteniendoT and cfg.ClickToTP then
            pcall(function()
