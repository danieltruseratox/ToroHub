-- =============================================================================
-- ████████╗ ██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗ 
-- ╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
--    ██║   ██║   ██║██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
--    ██║   ██║   ██║██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔══██╗
--    ██║   ╚██████╔╝██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║  ██║
--    ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
-- =============================================================================

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

-- INTERFAZ GRÁFICA CORREGIDA (CAPAS Y TAMAÑOS VISIBLES FIJOS)
local G = Instance.new("ScreenGui")
G.Name = "ToroHubFixedVisual"
G.ResetOnSpawn = false
G.Parent = LocalPlayer:WaitForChild("PlayerGui")

local M = Instance.new("Frame")
M.Name = "Main"
M.Size = UDim2.new(0, 240, 0, 260)
M.Position = UDim2.new(0.1, 0, 0.3, 0)
M.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
M.BorderSizePixel = 0
M.Active = true
M.Parent = G

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = M

local T = Instance.new("TextLabel")
T.Size = UDim2.new(1, -40, 0, 40)
T.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
T.Text = "⚡ TORO HUB V12 ⚡"
T.TextColor3 = Color3.fromRGB(255, 255, 255)
T.Font = Enum.Font.SourceSansBold
T.TextSize = 14
T.Parent = M

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = T

local X = Instance.new("TextButton")
X.Size = UDim2.new(0, 35, 0, 35)
X.Position = UDim2.new(1, -38, 0, 2)
X.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
X.Text = "X"
X.TextColor3 = Color3.fromRGB(255, 255, 255)
X.Font = Enum.Font.SourceSansBold
X.TextSize = 14
X.Parent = M

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = X
X.MouseButton1Click:Connect(function() G:Destroy() end)

-- CONTENEDOR AJUSTADO EXPRESAMENTE PARA EVITAR BOTONES INVISIBLES
local Pack = Instance.new("Frame")
Pack.Name = "Container"
Pack.Size = UDim2.new(1, 0, 0, 200)
Pack.Position = UDim2.new(0, 0, 0, 50)
Pack.BackgroundTransparency = 1
Pack.Parent = M

local Lst = Instance.new("UIListLayout")
Lst.Padding = UDim.new(0, 6)
Lst.HorizontalAlignment = Enum.HorizontalAlignment.Center
Lst.VerticalAlignment = Enum.VerticalAlignment.Top
Lst.Parent = Pack

-- ARRASTRE
local drag, dragI, start, sPos
M.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag, start, sPos = true, i.Position, M.Position end end)
M.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragI = i end end)
UIS.InputChanged:Connect(function(i) if i == dragI and drag then local d = i.Position-start; M.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+d.X, sPos.Y.Scale, sPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

-- DETECTOR DE RAÍZ
local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

-- TARGETING
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

-- OPTIMIZADOR INTEGRAL DE FPS
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

-- BOTONES MODIFICADOS CON ORDEN DE RENDERIZADO FORZADO
local function cBtn(k, txt, func)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 210, 0, 35) -- Forzamos tamaño exacto visible
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    b.Text = txt..": OFF"
    b.TextColor3 = Color3.fromRGB(220, 60, 60)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 13
    b.Parent = Pack

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = b

    b.MouseButton1Click:Connect(function()
        cfg[k] = not cfg[k]
        if cfg[k] then 
            b.Text = txt..": ON"
            b.BackgroundColor3 = Color3.fromRGB(45, 140, 45)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            if k == "FullBright" then AplicarOptimizarMundo(true) end
            if func then func() end
        else 
            b.Text = txt..": OFF"
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            b.TextColor3 = Color3.fromRGB(220, 60, 60)
            if k == "FullBright" then AplicarOptimizarMundo(false) end
            if k == "Aimbot" then lock, targ = false, nil end
        end
    end)
end

cBtn("Aimbot", "🎯 Permitir Aimbot")
cBtn("FullBright", "💡 Iluminación + FPS")
cBtn("ESP", "👁️ Ver Jugadores (ESP)")
cBtn("ClickToTP", "🌀 Click to TP (Tecla T)")

-- INPUTS GENERALES
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
                if getRoot(LocalPlayer.Character) and MouseNativo.Hit then
                    getRoot(LocalPlayer.Character).CFrame = CFrame.new(MouseNativo.Hit.Position + Vector3.new(0, 3, 0))
                end
            end)
        end 
    end 
end)

UIS.InputEnded:Connect(function(i) if i.KeyCode == TeclaClickToTeleport then sosteniendoT = false end end)

-- BUCLE DE RENDERIZADO PRINCIPAL
local fL = Instance.new("PointLight", Camera) fL.Range, fL.Brightness, fL.Enabled = 10000, 3, false
RunService.RenderStepped:Connect(function()
    pcall(function()
        if cfg.Aimbot and lock then 
            if not targ or not targ.Parent or not targ.Parent:FindFirstChild("Humanoid") or targ.Parent.Humanoid.Health <= 0 then targ = GetT() end
            if targ then Camera.CFrame = CFrame.new(Camera.CFrame.Position, targ.Position) end 
        else targ = nil end
        
        fL.Enabled = cfg.FullBright
        if cfg.FullBright then 
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255,255,255) 
        else 
            Lighting.GlobalShadows = oS
            Lighting.Ambient = oA 
        end
        
        for _,v in pairs(Players:GetPlayers()) do 
            if v ~= LocalPlayer and v.Character then 
                local h = v.Character:FindFirstChild("ESPHl")
                if cfg.ESP then 
                    if not h and getRoot(v.Character) then 
                        h = Instance.new("Highlight", v.Character) h.Name = "ESPHl"
                        h.FillColor, h.FillTransparency, h.OutlineColor, h.DepthMode = Color3.fromRGB(255,0,0), 0.5, Color3.fromRGB(255,255,255), Enum.HighlightDepthMode.AlwaysOnTop
                    end
                else 
                    if h then h:Destroy() end 
                end 
            end 
        end
    end)
end)
