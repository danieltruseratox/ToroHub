-- =============================================================================
-- ████████╗ ██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗ 
-- ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
--    ██║   ██║   ██║██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
--    ██║   ██║   ██║██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔══██╗
--    ██║   ╚██████╔╝██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║  ██║
--    ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
-- =============================================================================

local ServJugadores = game:GetService("Players")
local ServEntradas = game:GetService("UserInputService")
local ServIluminacion = game:GetService("Lighting")
local ServBucle = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Yo = ServJugadores.LocalPlayer
local CamaraMundo = workspace.CurrentCamera
local MouseJugador = Yo:GetMouse()

-- CONTROLADOR DE ESTADOS SINCRO
local Interruptores = {
    ["Aimbot"] = false,
    ["FullBright"] = false,
    ["ESP"] = false,
    ["ClickToTP"] = false
}

local CandadoMira = false
local VictimaFijada = nil
local TeclaT_Presionada = false

local RespShadows = ServIluminacion.GlobalShadows
local RespAmbient = ServIluminacion.Ambient

--------------------------------------------------------------------------------
-- 1. DISEÑO DE INTERFAZ: FORMATO NEÓN GLOW
--------------------------------------------------------------------------------
local CapaGui = Instance.new("ScreenGui", Yo:WaitForChild("PlayerGui"))
CapaGui.Name = "ToroHubNeonEdition"
CapaGui.ResetOnSpawn = false

-- Marco principal del menú (Fondo Oscuro Premium)
local VentanaFondo = Instance.new("Frame", CapaGui)
VentanaFondo.Size = UDim2.new(0, 240, 0, 260)
VentanaFondo.Position = UDim2.new(0.05, 0, 0.25, 0)
VentanaFondo.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
VentanaFondo.BorderSizePixel = 0
VentanaFondo.Active = true
VentanaFondo.Draggable = true
VentanaFondo.ZIndex = 1

local MainCorner = Instance.new("UICorner", VentanaFondo)
MainCorner.CornerRadius = UDim.new(0, 8)

-- Línea de contorno Neón (Efecto Resplandor)
local NeonBorder = Instance.new("Frame", VentanaFondo)
NeonBorder.Size = UDim2.new(1, 2, 1, 2)
NeonBorder.Position = UDim2.new(0, -1, 0, -1)
NeonBorder.BackgroundColor3 = Color3.fromRGB(0, 255, 150) -- Verde Neón
NeonBorder.ZIndex = 0

local BorderCorner = Instance.new("UICorner", NeonBorder)
BorderCorner.CornerRadius = UDim.new(0, 9)

-- Encabezado del Menú
local BarraSuperior = Instance.new("Frame", VentanaFondo)
BarraSuperior.Size = UDim2.new(1, 0, 0, 35)
BarraSuperior.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
BarraSuperior.BorderSizePixel = 0
BarraSuperior.ZIndex = 2

local TopCorner = Instance.new("UICorner", BarraSuperior)
TopCorner.CornerRadius = UDim.new(0, 8)

local TextoTitulo = Instance.new("TextLabel", BarraSuperior)
TextoTitulo.Size = UDim2.new(1, -45, 1, 0)
TextoTitulo.BackgroundTransparency = 1
TextoTitulo.Text = "  TORO HUB — NEÓN V13"
TextoTitulo.TextColor3 = Color3.fromRGB(255, 255, 255)
TextoTitulo.Font = Enum.Font.SourceSansBold
TextoTitulo.TextSize = 14
TextoTitulo.TextXAlignment = Enum.TextXAlignment.Left
TextoTitulo.ZIndex = 3

local BotonCerrar = Instance.new("TextButton", BarraSuperior)
BotonCerrar.Size = UDim2.new(0, 30, 0, 30)
BotonCerrar.Position = UDim2.new(1, -35, 0, 2)
BotonCerrar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
BotonCerrar.Text = "✕"
BotonCerrar.TextColor3 = Color3.fromRGB(150, 150, 160)
BotonCerrar.Font = Enum.Font.SourceSansBold
BotonCerrar.TextSize = 12
BotonCerrar.ZIndex = 3

local CloseCorner = Instance.new("UICorner", BotonCerrar)
CloseCorner.CornerRadius = UDim.new(0, 6)

BotonCerrar.MouseButton1Click:Connect(function() CapaGui:Destroy() end)

--------------------------------------------------------------------------------
-- 2. RAÍZ DE EXTREMIDADES (TARGETING)
--------------------------------------------------------------------------------
local function LocalizarCentro(modelo)
    if not modelo then return nil end
    return modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChild("Torso") or modelo:FindFirstChild("UpperTorso")
end

local function RastrearObjetivoCursor()
    local ParticulaCercana, DistanciaMinima = nil, math.huge
    local CoorMouse = ServEntradas:GetMouseLocation()

    for _, enemigo in pairs(ServJugadores:GetPlayers()) do
        if enemigo ~= Yo and enemigo.Character and LocalizarCentro(enemigo.Character) then
            local vida = enemigo.Character:FindFirstChildOfClass("Humanoid")
            if vida and vida.Health > 0 then
                local puntoPantalla, visible = CamaraMundo:WorldToScreenPoint(LocalizarCentro(enemigo.Character).Position)
                if visible then
                    local operacion = (Vector2.new(CoorMouse.X, CoorMouse.Y) - Vector2.new(puntoPantalla.X, puntoPantalla.Y)).Magnitude
                    if operacion < DistanciaMinima then
                        DistanciaMinima = operacion
                        ParticulaCercana = LocalizarCentro(enemigo.Character)
                    end
                end
            end
        end
    end
    return ParticulaCercana
end

--------------------------------------------------------------------------------
-- 3. INTERRUPTORES DE FORMATO MODERNO (SLIDERS FILTRADOS)
--------------------------------------------------------------------------------
local function CrearComponenteNeon(LlaveConfig, EtiquetaNombre, DesplazamientoY)
    -- Contenedor de la opción
    local FilaContenedor = Instance.new("Frame", VentanaFondo)
    FilaContenedor.Size = UDim2.new(1, -20, 0, 40)
    FilaContenedor.Position = UDim2.new(0, 10, 0, DesplazamientoY)
    FilaContenedor.BackgroundTransparency = 1
    FilaContenedor.ZIndex = 2

    -- Texto descriptor de la opción
    local TextoOpcion = Instance.new("TextLabel", FilaContenedor)
    TextoOpcion.Size = UDim2.new(1, -60, 1, 0)
    TextoOpcion.BackgroundTransparency = 1
    TextoOpcion.Text = EtiquetaNombre
    TextoOpcion.TextColor3 = Color3.fromRGB(180, 180, 190)
    TextoOpcion.Font = Enum.Font.SourceSansSemibold
    TextoOpcion.TextSize = 14
    TextoOpcion.TextXAlignment = Enum.TextXAlignment.Left
    TextoOpcion.ZIndex = 3

    -- Switch deslizable (Fondo del toggle)
    local SwitchFondo = Instance.new("TextButton", FilaContenedor)
    SwitchFondo.Size = UDim2.new(0, 44, 0, 22)
    SwitchFondo.Position = UDim2.new(1, -44, 0, 9)
    SwitchFondo.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    SwitchFondo.Text = ""
    SwitchFondo.ZIndex = 3

    local SwitchCorner = Instance.new("UICorner", SwitchFondo)
    SwitchCorner.CornerRadius = UDim.new(1, 0)

    -- Botón circular interno deslizable
    local CirculoIndicador = Instance.new("Frame", SwitchFondo)
    CirculoIndicador.Size = UDim2.new(0, 16, 0, 16)
    CirculoIndicador.Position = UDim2.new(0, 3, 0, 3)
    CirculoIndicador.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    CirculoIndicador.BorderSizePixel = 0
    CirculoIndicador.ZIndex = 4

    local CirculoCorner = Instance.new("UICorner", CirculoIndicador)
    CirculoCorner.CornerRadius = UDim.new(1, 0)

    -- Animación y Cambio de Estados
    SwitchFondo.MouseButton1Click:Connect(function()
        Interruptores[LlaveConfig] = not Interruptores[LlaveConfig]
        
        if Interruptores[LlaveConfig] then
            -- ON: Animación hacia la derecha con tono verde Neón
            TweenService:Create(SwitchFondo, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 100)}):Play()
            TweenService:Create(CirculoIndicador, TweenInfo.new(0.2), {Position = UDim2.new(0, 25, 0, 3), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TextoOpcion.TextColor3 = Color3.fromRGB(240, 240, 240)
        else
            -- OFF: Regresa a la izquierda con tono neutro oscuro
            TweenService:Create(SwitchFondo, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
            TweenService:Create(CirculoIndicador, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0, 3), BackgroundColor3 = Color3.fromRGB(150, 150, 160)}):Play()
            TextoOpcion.TextColor3 = Color3.fromRGB(180, 180, 190)
            if LlaveConfig == "Aimbot" then CandadoMira, VictimaFijada = false, nil end
        end
    end)
end

-- Lista estructurada en formato Neón
CrearComponenteNeon("Aimbot", "🎯 Sistema Aimbot Inteligente", 50)
CrearComponenteNeon("FullBright", "💡 Iluminación + Modo FPS", 100)
CrearComponenteNeon("ESP", "👁️ Rastreador Visual (ESP)", 150)
CrearComponenteNeon("ClickToTP", "🌀 Teleportar por Clic (Tecla T)", 200)

--------------------------------------------------------------------------------
-- 4. CAPTURA SEPARADA DE EVENTOS FISICOS (ENTRADAS)
--------------------------------------------------------------------------------
ServEntradas.InputBegan:Connect(function(tecla, juegoProcesado)
    if juegoProcesado then return end
    
    if tecla.KeyCode == Enum.KeyCode.F and Interruptores["Aimbot"] then
        CandadoMira = not CandadoMira
        if not CandadoMira then VictimaFijada = nil end
    elseif tecla.KeyCode == TeclaOcultarMenu then
        VentanaFondo.Visible = not VentanaFondo.Visible
        NeonBorder.Visible = VentanaFondo.Visible
    elseif tecla.KeyCode == Enum.KeyCode.T then
        TeclaT_Presionada = true
    elseif tecla.UserInputType == Enum.UserInputType.MouseButton1 and TeclaT_Presionada and Interruptores["ClickToTP"] then
        pcall(function()
            local torsoYo = LocalizerCentro(Yo.Character)
            if torsoYo and MouseJugador.Hit then
                torsoYo.CFrame = CFrame.new(MouseJugador.Hit.Position + Vector3.new(0, 3, 0))
            end
        end)
    end
end)

ServEntradas.InputEnded:Connect(function(tecla)
    if tecla.KeyCode == Enum.KeyCode.T then TeclaT_Presionada = false end
end)

