-- =============================================================================
-- ████████╗ ██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗ 
-- ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
--    ██║   ██║   ██║██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
--    ██║   ██║   ██║██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔══██╗
--    ██║   ╚██████╔╝██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║  ██║
--    ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
-- =============================================================================
-- CODIFICACIÓN NUEVA: SISTEMA DE LÍNEAS DE TEXTO INTERACTIVAS (ANTI-BLOQUEO XENO)

local ServJugadores = game:GetService("Players")
local ServEntradas = game:GetService("UserInputService")
local ServIluminacion = game:GetService("Lighting")
local ServBucle = game:GetService("RunService")

local Yo = ServJugadores.LocalPlayer
local CamaraMundo = workspace.CurrentCamera
local MouseJugador = Yo:GetMouse()

-- CONTROLADOR DE FUNCIONES INTERNAS (NUEVO FORMATO DE MATRIZ)
local Interruptores = {
    ["Aimbot"] = false,
    ["FullBright"] = false,
    ["ESP"] = false,
    ["ClickToTP"] = false
}

local CandadoMira = false
local VictimaFijada = nil
local TeclaT_Presionada = false

-- BACKUPS DE ILUMINACIÓN NATIVA
local RespShadows = ServIluminacion.GlobalShadows
local RespAmbient = ServIluminacion.Ambient

--------------------------------------------------------------------------------
-- 1. ESTRUCTURA VISUAL PLANA (SISTEMA DE TEXTO DIRECTO)
--------------------------------------------------------------------------------
local CapaGui = Instance.new("ScreenGui", Yo:WaitForChild("PlayerGui"))
CapaGui.Name = "ToroHubTextEdition"
CapaGui.ResetOnSpawn = false

local VentanaFondo = Instance.new("Frame", CapaGui)
VentanaFondo.Size = UDim2.new(0, 240, 0, 240)
VentanaFondo.Position = UDim2.new(0.05, 0, 0.25, 0)
VentanaFondo.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
VentanaFondo.BorderSizePixel = 1
VentanaFondo.BorderColor3 = Color3.fromRGB(40, 40, 40)
VentanaFondo.Active = true
VentanaFondo.Draggable = true -- Habilitado por contingencia de inyección

local BarraSuperior = Instance.new("Frame", VentanaFondo)
BarraSuperior.Size = UDim2.new(1, 0, 0, 30)
BarraSuperior.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
BarraSuperior.BorderSizePixel = 0

local TextoTitulo = Instance.new("TextLabel", BarraSuperior)
TextoTitulo.Size = UDim2.new(1, -35, 1, 0)
TextoTitulo.BackgroundTransparency = 1
TextoTitulo.Text = "  TORO HUB V13 [TEXT EDIT]"
TextoTitulo.TextColor3 = Color3.fromRGB(240, 240, 240)
TextoTitulo.Font = Enum.Font.Code
TextoTitulo.TextSize = 13
TextoTitulo.TextXAlignment = Enum.TextXAlignment.Left

local BotonCerrar = Instance.new("TextButton", BarraSuperior)
BotonCerrar.Size = UDim2.new(0, 30, 1, 0)
BotonCerrar.Position = UDim2.new(1, -30, 0, 0)
BotonCierre.BackgroundTransparency = 1 or BotonCerrar
BotonCerrar.Text = "[X]"
BotonCerrar.TextColor3 = Color3.fromRGB(200, 50, 50)
BotonCerrar.Font = Enum.Font.Code
BotonCerrar.TextSize = 13
BotonCerrar.MouseButton1Click:Connect(function() CapaGui:Destroy() end)

--------------------------------------------------------------------------------
-- 2. ENRUTADOR SEGURO DE EXTREMIDADES
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
-- 3. PROCESADOR DE OPCIONES (NUEVO MÉTODO DE ENLACE DE TEXTO INTERACTIVO)
--------------------------------------------------------------------------------
local function CrearTextoInteractivo(LlaveConfig, EtiquetaNombre, DesplazamientoY)
    local LabelBoton = Instance.new("TextButton", VentanaFondo)
    LabelBoton.Size = UDim2.new(1, -20, 0, 30)
    LabelBoton.Position = UDim2.new(0, 10, 0, DesplazamientoY)
    LabelBoton.BackgroundTransparency = 1
    LabelBoton.Text = "-> " .. EtiquetaNombre .. ": [DESACTIVADO]"
    LabelBoton.TextColor3 = Color3.fromRGB(180, 50, 50)
    LabelBoton.Font = Enum.Font.Code
    LabelBoton.TextSize = 13
    LabelBoton.TextXAlignment = Enum.TextXAlignment.Left

    LabelBoton.MouseButton1Click:Connect(function()
        Interruptores[LlaveConfig] = not Interruptores[LlaveConfig]
        
        if Interruptores[LlaveConfig] then
            LabelBoton.Text = "-> " .. EtiquetaNombre .. ": [ACTIVADO]"
            LabelBoton.TextColor3 = Color3.fromRGB(50, 180, 50)
        else
            LabelBoton.Text = "-> " .. EtiquetaNombre .. ": [DESACTIVADO]"
            LabelBoton.TextColor3 = Color3.fromRGB(180, 50, 50)
            if LlaveConfig == "Aimbot" then CandadoMira, VictimaFijada = false, nil end
        end
    end)
end

-- Inyección de opciones sobre coordenadas planas fijas sin Layouts intermediarios
CrearTextoInteractivo("Aimbot", "Fijar Aimbot Inteligente", 45)
CrearTextoInteractivo("FullBright", "Anular Sombras y Niebla", 85)
CrearTextoInteractivo("ESP", "Efecto Silueta de Jugadores", 125)
CrearTextoInteractivo("ClickToTP", "Teleportar por Clic (Tecla T)", 165)

--------------------------------------------------------------------------------
-- 4. CAPTURA SEPARADA DE EVENTOS FISICOS (ENTRADAS)
--------------------------------------------------------------------------------
ServEntradas.InputBegan:Connect(function(tecla, juegoProcesado)
    if juegoProcesado then return end
    
    if tecla.KeyCode == Enum.KeyCode.F and Interruptores["Aimbot"] then
        CandadoMira = not CandadoMira
        if not CandadoMira then VictimaFijada = nil end
    elseif tecla.KeyCode == Enum.KeyCode.KeypadThree then
        VentanaFondo.Visible = not VentanaFondo.Visible
    elseif tecla.KeyCode == Enum.KeyCode.T then
        TeclaT_Presionada = true
    elseif tecla.UserInputType == Enum.UserInputType.MouseButton1 and TeclaT_Presionada and Interruptores["ClickToTP"] then
        pcall(function()
            local torsoYo = LocalizarCentro(Yo.Character)
            if torsoYo and MouseJugador.Hit then
                torsoYo.CFrame = CFrame.new(MouseJugador.Hit.Position + Vector3.new(0, 3, 0))
            end
        end)
    end
end)

ServEntradas.InputEnded:Connect(function(tecla)
    if tecla.KeyCode == Enum.KeyCode.T then TeclaT_Presionada = false end
end)

--------------------------------------------------------------------------------
-- 5. SUB-PROCESOS ASÍNCRONOS INDEPENDIENTES (ANTI-LAG)
--------------------------------------------------------------------------------

-- Hilo Aimbot
task.spawn(function()
    while true do
        ServBucle.RenderStepped:Wait()
        if Interruptores["Aimbot"] and CandadoMira then
            pcall(function()
                if not VictimaFijada or not VictimaFijada.Parent or not VictimaFijada.Parent:FindFirstChildOfClass("Humanoid") or VictimaFijada.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
                    VictimaFijada = RastrearObjetivoCursor()
                end
                if VictimaFijada then
                    CamaraMundo.CFrame = CFrame.new(CamaraMundo.CFrame.Position, VictimaFijada.Position)
                end
            end)
        end
    end
end)

-- Hilo FullBright de Iluminación Local
local LamparaVirtual = Instance.new("PointLight", CamaraMundo)
LamparaVirtual.Range, LamparaVirtual.Brightness, LamparaVirtual.Enabled = 10000, 3, false

task.spawn(function()
    while true do
        task.wait(0.2)
        pcall(function()
            LamparaVirtual.Enabled = Interruptores["FullBright"]
            if Interruptores["FullBright"] then
                if ServIluminacion.GlobalShadows ~= false then ServIluminacion.GlobalShadows = false end
                if ServIluminacion.Ambient ~= Color3.fromRGB(255, 255, 255) then ServIluminacion.Ambient = Color3.fromRGB(255, 255, 255) end
            else
                if ServIluminacion.GlobalShadows ~= RespShadows then ServIluminacion.GlobalShadows = RespShadows end
                if ServIluminacion.Ambient ~= RespAmbient then ServIluminacion.Ambient = RespAmbient end
            end
        end)
    end
end)

-- Hilo ESP de Siluetas Asíncronas
task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            for _, jugador in pairs(ServJugadores:GetPlayers()) do
                if jugador ~= Yo and jugador.Character then
                    local resalte = jugador.Character:FindFirstChild("ToroHl")
                    if Interruptores["ESP"] then
                        if not resalte and LocalizarCentro(jugador.Character) then
                            resalte = Instance.new("Highlight", jugador.Character)
                            resalte.Name = "ToroHl"
                            resalte.FillColor = Color3.fromRGB(255, 0, 0)
