-- =============================================================================
-- ████████╗ ██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗ 
-- ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
--    ██║   ██║   ██║██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
--    ██║   ██║   ██║██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔══██╗
--    ██║   ╚██████╔╝██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║  ██║
--    ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
-- =============================================================================
-- Desarrollado y optimizado específicamente para Xeno Launcher.
-- Estructura modular asíncrona libre de recortes o lag por sobrecarga.

-- SERVICIOS NATIVOS DE ROBLOX
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

-- VARIABLES INTERNAS DEL JUGADOR LOCAL Y CÁMARA
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualMouse = LocalPlayer:GetMouse()

-- TABLA DE CONFIGURACIONES GENERALES (ESTADOS DE INTERRUPTORES)
local HubConfig = {
    AimbotHabilitado = false,
    FullBrightHabilitado = false,
    ESPHabilitado = false,
    FlyHabilitado = false
}

-- CONFIGURACIONES INTERNAS Y CONTROL DE TECLAS
local AimbotFijadoActivo = false
local ObjetivoActualAimbot = nil
local MenuAbierto = true

local TeclaOcultarMenu = Enum.KeyCode.KeypadThree -- Numeral 3 derecho
local TeclaFijacionAimbot = Enum.KeyCode.F      -- Letra F para el candado
local TeclaClickToTeleport = Enum.KeyCode.T     -- Letra T para TP por clic

-- ALMACENAMIENTO DE VALORES ORIGINALES DEL SERVIDOR (Para restauración limpia)
local OriginalGlobalShadows = Lighting.GlobalShadows
local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local OriginalFogEnd = Lighting.FogEnd
local OriginalFogStart = Lighting.FogStart

local VelocidadVueloFija = 60
local EstadoSosteniendoTeclaT = false

--------------------------------------------------------------------------------
-- 1. CONSTRUCCIÓN DE INTERFAZ GRÁFICA COMPLETA Y DETALLADA (GUI)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToroHubPremiumGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 320)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -40, 0, 40)
TitleLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
TitleLabel.Text = "⚡ TORO HUB UNIVERSAL ⚡"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleLabel

-- BOTÓN DE DESTRUCCIÓN DEL SCRIPT (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 15
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local ButtonsContainer = Instance.new("Frame")
ButtonsContainer.Name = "ButtonsContainer"
ButtonsContainer.Size = UDim2.new(1, 0, 1, -45)
ButtonsContainer.Position = UDim2.new(0, 0, 0, 45)
ButtonsContainer.BackgroundTransparency = 1
ButtonsContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Parent = ButtonsContainer

--------------------------------------------------------------------------------
-- 2. SISTEMA MODERNO DE ARRASTRE DE MENÚ (DRAG)
--------------------------------------------------------------------------------
local IsDraggingMenu = false
local InputDragStart, DragStartFramePos

local function UpdateMenuPosition(input)
    local DeltaMovement = input.Position - InputDragStart
    MainFrame.Position = UDim2.new(
        DragStartFramePos.X.Scale, 
        DragStartFramePos.X.Offset + DeltaMovement.X, 
        DragStartFramePos.Y.Scale, 
        DragStartFramePos.Y.Offset + DeltaMovement.Y
    )
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsDraggingMenu = true
        InputDragStart = input.Position
        DragStartFramePos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                IsDraggingMenu = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if IsDraggingMenu then
            UpdateMenuPosition(input)
        end
    end
end)

--------------------------------------------------------------------------------
-- 3. FUNCIÓN CREADORA DE INTERRUPTORES (TOGGLES DINÁMICOS)
--------------------------------------------------------------------------------
local function CrearBotonToggle(ConfigKey, TextoVisible, FuncionAlActivar)
    local TextButton = Instance.new("TextButton")
    TextButton.Size = UDim2.new(0, 200, 0, 35)
    TextButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    TextButton.Text = TextoVisible .. ": OFF"
    TextButton.TextColor3 = Color3.fromRGB(210, 55, 55)
    TextButton.Font = Enum.Font.SourceSansBold
    TextButton.TextSize = 13
    TextButton.Parent = ButtonsContainer

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = TextButton

    TextButton.MouseButton1Click:Connect(function()
        HubConfig[ConfigKey] = not HubConfig[ConfigKey]
        
        if HubConfig[ConfigKey] then
            TextButton.Text = TextoVisible .. ": ON"
            TextButton.BackgroundColor3 = Color3.fromRGB(40, 130, 40)
            TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            if ConfigKey == "FullBrightHabilitado" then
                pcall(function() FuncionAlActivar(true) end)
            elseif FuncionAlActivar then
                -- Para funciones instantáneas como el Teleport de un clic
                pcall(FuncionAlActivar)
                HubConfig[ConfigKey] = false
                TextButton.Text = TextoVisible .. ": OFF"
                TextButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
                TextButton.TextColor3 = Color3.fromRGB(210, 55, 55)
            end
        else
            TextButton.Text = TextoVisible .. ": OFF"
            TextButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            TextButton.TextColor3 = Color3.fromRGB(210, 55, 55)
            
            if ConfigKey == "FullBrightHabilitado" then
                pcall(function() FuncionAlActivar(false) end)
            elseif ConfigKey == "AimbotHabilitado" then
                AimbotFijadoActivo = false
                ObjetivoActualAimbot = nil
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- 4. ALGORITMOS DE DETECCIÓN MATEMÁTICA (TARGETING)
--------------------------------------------------------------------------------
function ObtenerJugadorMasCercanoAlCursor()
    local ObjetivoSeleccionado = nil
    local DistanciaMenorRegistrada = math.huge
    local CoordenadasMouse = UserInputService:GetMouseLocation()

    for _, Jugador in pairs(Players:GetPlayers()) do
        if Jugador ~= LocalPlayer and Jugador.Character then
            local RootPart = Jugador.Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Jugador.Character:FindFirstChild("Humanoid")
            
            if RootPart and Humanoid and Humanoid.Health > 0 then
                local PosicionPantalla, EnPantalla = Camera:WorldToScreenPoint(RootPart.Position)
                
                if EnPantalla then
                    local CalculoDistancia = (Vector2.new(CoordenadasMouse.X, CoordenadasMouse.Y) - Vector2.new(PosicionPantalla.X, PosicionPantalla.Y)).Magnitude
                    if CalculoDistancia < DistanciaMenorRegistrada then
                        DistanciaMenorRegistrada = CalculoDistancia
                        ObjetivoSeleccionado = RootPart
                    end
                end
            end
        end
    end
    return ObjetivoSeleccionado
end

--------------------------------------------------------------------------------
-- 5. OPTIMIZADOR PROGRESIVO DE RENDIMIENTO DEL ENTORNO (FPS)
--------------------------------------------------------------------------------
local function AlternarOptimizacionMundo(Habilitar)
    if Habilitar then
        Lighting.FogEnd = 999999
        Lighting.FogStart = 999999
        
        for _, Efecto in pairs(Lighting:GetChildren()) do
