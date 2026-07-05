-- =============================================================================
-- TORO HUB: VERSIÓN BASE ESTABLE + FLY POR FUERZAS + CLICK TO TP (LETRA T)
-- =============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local JugadorLocal = Players.LocalPlayer
local Camara = workspace.CurrentCamera
local Mouse = JugadorLocal:GetMouse()

-- ESTADOS DE LOS TOGGLES (FALSO POR DEFECTO)
local MenuConfig = {
    Aimbot = false,
    FullBright = false,
    ESP = false,
    Fly = false,
    Teleport = false
}

-- VALORES ORIGINALES GUARDADOS PARA EL FULLBRIGHT
local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local OriginalClockTime = Lighting.ClockTime
local flySpeed = 60
local sosteniendoT = false

----------------------------------------------------------------
-- 1. INTERFAZ GRÁFICA ORIGINAL (DIRIGIDA A PLAYERGUI)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubGuiFixed"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = JugadorLocal:WaitForChild("PlayerGui")

local FramePrincipal = Instance.new("Frame")
FramePrincipal.Size = UDim2.new(0, 250, 0, 360) -- Modificado el alto para acomodar el botón Fly
FramePrincipal.Position = UDim2.new(0.1, 0, 0.3, 0)
FramePrincipal.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FramePrincipal.BorderSizePixel = 0
FramePrincipal.Active = true
FramePrincipal.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = FramePrincipal

local Titulo = Instance.new("TextLabel")
Titulo.Size = UDim2.new(1, -40, 0, 40)
Titulo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Titulo.Text = "⚡ TORO HUB V11 ⚡"
Titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
Titulo.Font = Enum.Font.SourceSansBold
Titulo.TextSize = 18
Titulo.Parent = FramePrincipal

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 10)
UICorner2.Parent = Titulo

-- BOTÓN DE CIERRE CON UNA EQUIX (X)
local BotonCierreX = Instance.new("TextButton")
BotonCierreX.Size = UDim2.new(0, 40, 0, 40)
BotonCierreX.Position = UDim2.new(1, -40, 0, 0)
BotonCierreX.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
BotonCierreX.Text = "X"
BotonCierreX.TextColor3 = Color3.fromRGB(255, 255, 255)
BotonCierreX.Font = Enum.Font.SourceSansBold
BotonCierreX.TextSize = 16
BotonCierreX.Parent = FramePrincipal

local UICornerX = Instance.new("UICorner")
UICornerX.CornerRadius = UDim.new(0, 10)
UICornerX.Parent = BotonCierreX

BotonCierreX.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local ContenedorBotones = Instance.new("Frame")
ContenedorBotones.Size = UDim2.new(1, 0, 1, -40)
ContenedorBotones.Position = UDim2.new(0, 0, 0, 40)
ContenedorBotones.BackgroundTransparency = 1
ContenedorBotones.Parent = FramePrincipal

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Parent = ContenedorBotones

----------------------------------------------------------------
-- 2. SISTEMA DE ARRASTRE DE MENÚ MODERNO
----------------------------------------------------------------
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    FramePrincipal.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

FramePrincipal.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = FramePrincipal.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

FramePrincipal.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

----------------------------------------------------------------
-- 3. FUNCIÓN PARA CREAR INTERRUPTORES (TOGGLES)
----------------------------------------------------------------
local function CrearToggle(NombreConfig, TextoBoton)
    local Boton = Instance.new("TextButton")
    Boton.Size = UDim2.new(0, 210, 0, 40)
    Boton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Boton.Text = TextoBoton .. ": OFF"
    Boton.TextColor3 = Color3.fromRGB(200, 50, 50)
    Boton.Font = Enum.Font.SourceSansBold
    Boton.TextSize = 16
    Boton.Parent = ContenedorBotones

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Boton

    Boton.MouseButton1Click:Connect(function()
        MenuConfig[NombreConfig] = not MenuConfig[NombreConfig]
        
        if MenuConfig[NombreConfig] then
            Boton.Text = TextoBoton .. ": ON"
            TweenService:Create(Boton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 150, 50)}):Play()
            Boton.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            if NombreConfig == "Teleport" then
                EjecutarTeleport()
                MenuConfig[NombreConfig] = false
                Boton.Text = TextoBoton .. ": OFF"
                TweenService:Create(Boton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                Boton.TextColor3 = Color3.fromRGB(200, 50, 50)
            end
        else
            Boton.Text = TextoBoton .. ": OFF"
            TweenService:Create(Boton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            Boton.TextColor3 = Color3.fromRGB(200, 50, 50)
        end
    end)
end

CrearToggle("Aimbot", "🎯 Habilitar Aimbot")
CrearToggle("FullBright", "💡 FullBright")
CrearToggle("ESP", "👁️ Ver Jugadores (ESP)")
CrearToggle("Fly", "🦅 Vuelo (Fly)")
CrearToggle("Teleport", "🌀 Teleport Más Cercano")

----------------------------------------------------------------
-- 4. LÓGICA DE JUGADORES Y SISTEMAS DIRECTOS
----------------------------------------------------------------

local function ObtenerJugadorMasCercano()
    local Objetivo = nil
    local DistanciaMaxima = math.huge

    for _, Jugador in pairs(Players:GetPlayers()) do
        if Jugador ~= JugadorLocal and Jugador.Character and Jugador.Character:FindFirstChild("HumanoidRootPart") and Jugador.Character:FindFirstChild("Humanoid") then
            if Jugador.Character.Humanoid.Health > 0 then
                local PosicionPantalla, EnPantalla = Camara:WorldToScreenPoint(Jugador.Character.HumanoidRootPart.Position)
                
                if EnPantalla then
                    local DistanciaMouse = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(PosicionPantalla.X, PosicionPantalla.Y)).Magnitude
                    if DistanciaMouse < DistanciaMaxima then
                        DistanciaMaxima = DistanciaMouse
                        Objetivo = Jugador.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return Objetivo
end

-- BUCLE PRINCIPAL DE CORRECCIÓN (MÁXIMA ESTABILIDAD)
RunService.RenderStepped:Connect(function()
    -- Lógica del Aimbot Permanente
    if MenuConfig.Aimbot then
        local ObjetivoActual = ObtenerJugadorMasCercano()
        if ObjetivoActual then
            Camara.CFrame = CFrame.new(Camara.CFrame.Position, ObjetivoActual.Position)
        end
    end

    -- Lógica del FullBright
    if MenuConfig.FullBright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = OriginalAmbient
        Lighting.OutdoorAmbient = OriginalOutdoorAmbient
        Lighting.ClockTime = OriginalClockTime
    end
    
    -- Lógica del ESP Clásico
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= JugadorLocal and player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if MenuConfig.ESP then
                if not highlight then
                    local newHighlight = Instance.new("Highlight")
                    newHighlight.Name = "ESPHighlight"
                    newHighlight.Adornee = player.Character
                    newHighlight.FillColor = Color3.fromRGB(255, 0, 0)
                    newHighlight.FillTransparency = 0.5
                    newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    newHighlight.OutlineTransparency = 0
                    newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    newHighlight.Parent = player.Character
                end
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end)

-- LÓGICA DEL TELEPORT COMPATIBLE
function EjecutarTeleport()
    if JugadorLocal.Character and JugadorLocal.Character:FindFirstChild("HumanoidRootPart") then
        local Objetivo = ObtenerJugadorMasCercano()
        if Objetivo then
            JugadorLocal.Character.HumanoidRootPart.CFrame = Objetivo.CFrame * CFrame.new(0, 3, 0)
        end
    end
end

-- LÓGICA DEL CLICK TO TELEPORT (LETRA T SOTENIDA + UN CLICK)
UserInputService.InputBegan:Connect(function(Input, Procesado)
    if Procesado then return end
