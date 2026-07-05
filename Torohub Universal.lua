-- =============================================================================
-- SCRIPT AVANZADO: FLING AUTOMÁTICO AL OBJETIVO + ANTI-FLING PASIVO
-- =============================================================================
-- Activa el ataque al enemigo más cercano presionando la tecla: 'X'

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TeclaAtaque = Enum.KeyCode.X

local BucleAntiFling = nil
local Atacando = false

-- 1. DETECTOR SEGURO DE EXTREMIDADES (De tu guía)
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

-- 2. BUSCADOR DE OBJETIVO MÁS CERCANO A LA MIRA
local function ObtenerEnemigoCercano()
    local objetivo = nil
    local maxDistancia = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local root = getRoot(v.Character)
            local hum = v.Character:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos, enPantalla = camera:WorldToScreenPoint(root.Position)
                if enPantalla then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < maxDistancia then
                        maxDistancia = dist
                        objetivo = root
                    end
                end
            end
        end
    end
    return objetivo
end

-- 3. ANTI-FLING PASIVO CONSTANTE (Inmunidad a colisiones)
local function IniciarAntiFling()
    if BucleAntiFling then BucleAntiFling:Disconnect() end
    BucleAntiFling = RunService.Stepped:Connect(function()
        pcall(function()
            if player.Character and not Atacando then
                -- Desactiva colisiones del cuerpo para que otros flings no te afecten
                for _, parte in pairs(player.Character:GetChildren()) do
                    if parte:IsA("BasePart") then
                        parte.CanCollide = false
                    end
                end
            end
        end)
    end)
end

-- 4. FUNCIONES DE SPIN (Giro de tu guía)
local function spinCharacter(spinSpeed)
    local root = getRoot(player.Character)
    if not root then return end
    for _, child in pairs(root:GetChildren()) do
        if child.Name == "Spinning" then child:Destroy() end
    end
    local Spin = Instance.new("BodyAngularVelocity")
    Spin.Name = "Spinning"
    Spin.Parent = root
    Spin.MaxTorque = Vector3.new(0, math.huge, 0)
    Spin.AngularVelocity = Vector3.new(0, spinSpeed, 0)
    task.wait(0.1)
end

local function unspin()
    local root = getRoot(player.Character)
    if not root then return end
    for _, child in pairs(root:GetChildren()) do
        if child.Name == "Spinning" then
            child:Destroy()
            task.wait(0.05)
        end
    end
end

-- 5. SIMULADOR DE PRESIONAR TECLAS (De tu guía)
local function holdKey(key, hold)
    VirtualInputManager:SendKeyEvent(hold, key, false, game)
    task.wait(0.05)
end

-- 6. EFECTO DE ÓRBITA LOCA DE CÁMARA (De tu guía)
local function crazyCameraOrbit(duration)
    local root = getRoot(player.Character)
    if not root then return end
    local startTime = tick()
    local origCFrame = camera.CFrame
    while tick() - startTime < duration do
        local elapsed = tick() - startTime
        local x = math.cos(elapsed * 30) * 15 
        local y = math.sin(elapsed * 50) * 8 + 5 
        local z = math.sin(elapsed * 25) * 15 
        local jitterX = (math.sin(elapsed * 60) * 2)
        local jitterY = (math.cos(elapsed * 70) * 2)
        local jitterZ = (math.sin(elapsed * 55) * 2)
        local offset = Vector3.new(x + jitterX, y + jitterY, z + jitterZ)
        camera.CFrame = CFrame.new(root.Position + offset, root.Position)
        RunService.RenderStepped:Wait()
    end
    camera.CFrame = origCFrame
end

-- 7. EJECUCIÓN DEL FLING AGRESIVO DIRIGIDO
local function EjecutarFling()
    if Atacando then return end
    
    local root = getRoot(player.Character)
    local objetivo = ObtenerEnemigoCercano()
    
    if not root or not objetivo then 
        print("❌ No se encontró ningún enemigo cercano para lanzarlo.")
        return 
    end
    
    Atacando = true
    local posicionOriginal = root.CFrame -- Guarda tu posición para regresar
    
    pcall(function()
        -- Se teletransporta pegado a la víctima
        root.CFrame = objetivo.CFrame * CFrame.new(0, 0, 1)
        task.wait(0.1)
        
        -- Ejecuta la secuencia exacta de tu guía
        holdKey(Enum.KeyCode.LeftControl, true) -- ShiftLock simulado
        holdKey(Enum.KeyCode.C, true)           -- Gatear simulado
        task.wait(0.3) 
        
        spinCharacter(300)       -- Activa el giro
        crazyCameraOrbit(2)      -- Desata la cámara loca por 2 segundos sobre la víctima
        unspin()                 -- Detiene el giro
        
        holdKey(Enum.KeyCode.C, false)
        holdKey(Enum.KeyCode.LeftControl, false)
        task.wait(0.1)
    end)
    
    -- Te regresa al lugar seguro original de forma limpia
    root.CFrame = posicionOriginal
    Atacando = false
    print("🎯 Fling ejecutado correctamente. Regresando a zona segura.")
end

-- INICIADORES DE TECLADO Y PROTECCIÓN
UserInputService.InputBegan:Connect(function(input, procesado)
    if procesado then return end
    if input.KeyCode == TeclaAtaque then
        task.spawn(EjecutarFling)
    end
end)

pcall(IniciarAntiFling)
