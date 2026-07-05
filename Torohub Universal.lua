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

-- CONFIGURACIÓN GENERAL (ESTADOS COMPLETAMENTE SINCRONIZADOS)
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

-- INTERFAZ GRÁFICA
local G = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
G.Name = "ToroHub" G.ResetOnSpawn = false

local M = Instance.new("Frame", G)
M.Size, M.Position, M.BackgroundColor3, M.Active = UDim2.new(0,220,0,280), UDim2.new(0.1,0,0.3,0), Color3.fromRGB(20,20,20), true
Instance.new("UICorner", M).CornerRadius = UDim.new(0,8)

local T = Instance.new("TextLabel", M)
T.Size, T.Text, T.BackgroundColor3, T.TextColor3, T.Font, T.TextSize = UDim2.new(1,-40,0,35), "⚡ TORO HUB V12 ⚡", Color3.fromRGB(30,30,30), Color3.fromRGB(255,255,255), Enum.Font.SourceSansBold, 14
Instance.new("UICorner", T).CornerRadius = UDim.new(0,8)

local X = Instance.new("TextButton", M)
X.Size, X.Position, X.BackgroundColor3, X.Text, X.TextColor3, X.Font, X.TextSize = UDim2.new(0,35,0,35), UDim2.new(1,-35,0,0), Color3.fromRGB(180, 40, 40), "X", Color3.fromRGB(255,255,255), Enum.Font.SourceSansBold, 14
Instance.new("UICorner", X).CornerRadius = UDim.new(0,8)
X.MouseButton1Click:Connect(function() G:Destroy() end)

local Pack = Instance.new("Frame", M)
Pack.Size, Pack.Position, Pack.BackgroundTransparency = UDim2.new(1,0,1,-40), UDim2.new(0,0,0,40), 1
local Lst = Instance.new("UIListLayout", Pack) Lst.Padding = UDim.new(0,5)
Lst.HorizontalAlignment, Lst.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center

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

-- BOTONES
local function cBtn(k, txt, func)
    local b = Instance.new("TextButton", Pack)
    b.Size, b.BackgroundColor3 = UDim2.new(0,190,0,32), Color3.fromRGB(40,40,40)
    b.Text, b.TextColor3, b.Font, b.TextSize = txt..": OFF", Color3.fromRGB(220,60,60), Enum.Font.SourceSansBold, 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        cfg[k] = not cfg[k]
        if cfg[k] then 
            b.Text, b.BackgroundColor3, b.TextColor3 = txt..": ON", Color3.fromRGB(45,140,45), Color3.fromRGB(255,255,255)
            if k == "FullBright" then AplicarOptimizarMundo(true) end
            if func then func() end
        else 
            b.Text, b.BackgroundColor3, b.TextColor3 = txt..": OFF", Color3.fromRGB(40,40,40), Color3.fromRGB(220,60,60) 
            if k == "FullBright" then AplicarOptimizarMundo(false) end
            if k == "Aimbot" then lock, targ = false, nil end
        end
    end)
end

cBtn("Aimbot", "🎯 Permitir Aimbot")
cBtn("FullBright", "💡 Iluminación + FPS")
cBtn("ESP", "👁️ Ver Jugadores (ESP)")
cBtn("ClickToTP", "🌀 Click to TP (Tecla T)")

-- INPUTS GENERALES Y CAPTURA DEL MOUSE
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

-- BUCLE DE RENDERIZADO PRINCIPAL AUTOMÁTICO
local fL = Instance.new("PointLight", Camera) fL.Range, fL.Brightness, fL.Enabled = 10000, 3, false
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- AIMBOT LOGIC
        if cfg.Aimbot and lock then 
            if not targ or not targ.Parent or not targ.Parent:FindFirstChild("Humanoid") or targ.Parent.Humanoid.Health <= 0 then targ = GetT() end
            if targ then Camera.CFrame = CFrame.new(Camera.CFrame.Position, targ.Position) end 
        else targ = nil end
        
        -- FULLBRIGHT LOGIC (Asigna los estados de la tabla cfg)
        fL.Enabled = cfg.FullBright
        if cfg.FullBright then 
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255,255,255) 
        else 
            Lighting.GlobalShadows = oS
            Lighting.Ambient = oA 
        end
        
        -- ESP HIGHLIGHT LOGIC (Asigna los estados de la tabla cfg)
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
