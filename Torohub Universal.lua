local P = game:GetService("Players")
local LP = P.LocalPlayer
local Cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local L = game:GetService("Lighting")
local RS = game:GetService("RunService")

local cfg = {Aimbot = false, FullBright = false, ESP = false, Fly = false}
local lock, targ, open = false, nil, true
local oS, oA = L.GlobalShadows, L.Ambient

-- REFERENCIA DIRECTA AL RATÓN PARA CLICK TO TP
local MouseNativo = LP:GetMouse()
local sosteniendoT = false

-- INTERFAZ ORIGINAL REPARADA
local G = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
G.Name = "ToroHub" G.ResetOnSpawn = false

local M = Instance.new("Frame", G)
M.Size, M.Position, M.BackgroundColor3, M.Active = UDim2.new(0,220,0,280), UDim2.new(0.1,0,0.3,0), Color3.fromRGB(20,20,20), true
Instance.new("UICorner", M).CornerRadius = UDim.new(0,8)

local T = Instance.new("TextLabel", M)
T.Size, T.Text, T.BackgroundColor3, T.TextColor3, T.Font, T.TextSize = UDim2.new(1,-40,0,35), "⚡ TORO HUB V11 ⚡", Color3.fromRGB(30,30,30), Color3.fromRGB(255,255,255), Enum.Font.SourceSansBold, 14
Instance.new("UICorner", T).CornerRadius = UDim.new(0,8)

local X = Instance.new("TextButton", M)
X.Size, X.Position, X.BackgroundColor3, X.Text, X.TextColor3, X.Font, X.TextSize = UDim2.new(0,35,0,35), UDim2.new(1,-35,0,0), Color3.fromRGB(180,40,40), "X", Color3.fromRGB(255,255,255), Enum.Font.SourceSansBold, 14
Instance.new("UICorner", X).CornerRadius = UDim.new(0,8)
X.MouseButton1Click:Connect(function() G:Destroy() end)

local Pack = Instance.new("Frame", M)
Pack.Size, Pack.Position, Pack.BackgroundTransparency = UDim2.new(1,0,1,-40), UDim2.new(0,0,0,40), 1
local Lst = Instance.new("UIListLayout", Pack) Lst.Padding = UDim.new(0,5)
Lst.HorizontalAlignment, Lst.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center

-- SISTEMA DE ARRASTRE
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

-- TARGETING (AIMBOT)
function GetT()
    local obj, maxD, mP = nil, math.huge, UIS:GetMouseLocation()
    for _,v in pairs(P:GetPlayers()) do 
        if v ~= LP and v.Character and getRoot(v.Character) and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local p, onS = Cam:WorldToScreenPoint(getRoot(v.Character).Position)
            if onS then 
                local d = (Vector2.new(mP.X, mP.Y) - Vector2.new(p.X, p.Y)).Magnitude
                if d < maxD then maxD, obj = d, getRoot(v.Character) end 
            end 
        end 
    end; return obj 
end

-- CREADOR DE BOTONES
local function cBtn(k, txt, func)
    local b = Instance.new("TextButton", Pack)
    b.Size, b.BackgroundColor3 = UDim2.new(0,190,0,32), Color3.fromRGB(40,40,40)
    b.Text, b.TextColor3, b.Font, b.TextSize = txt..": OFF", Color3.fromRGB(220,60,60), Enum.Font.SourceSansBold, 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        cfg[k] = not cfg[k]
        if cfg[k] then 
            b.Text, b.BackgroundColor3, b.TextColor3 = txt..": ON", Color3.fromRGB(45,140,45), Color3.fromRGB(255,255,255)
            if func then func() b.Text, b.BackgroundColor3, b.TextColor3 = txt..": OFF", Color3.fromRGB(40,40,40), Color3.fromRGB(220,60,60) cfg[k] = false end
        else 
            b.Text, b.BackgroundColor3, b.TextColor3 = txt..": OFF", Color3.fromRGB(40,40,40), Color3.fromRGB(220,60,60) 
            if k == "Aimbot" then lock, targ = false, nil end
        end
    end)
end

cBtn("Aimbot", "🎯 Permitir Aimbot")
cBtn("FullBright", "💡 FullBright")
cBtn("ESP", "👁️ Ver Jugadores (ESP)")
cBtn("Fly", "🦅 Vuelo (Fly)")
cBtn("Teleport", "🌀 Teleport Cercano", function()
    local o = GetT() if o and getRoot(LP.Character) then getRoot(LP.Character).CFrame = o.CFrame * CFrame.new(0,4,0) end
end)

-- ENTRADAS DE TECLADO Y CLICK TO TP
UIS.InputBegan:Connect(function(i,p) 
    if not p then 
        if i.KeyCode == Enum.KeyCode.F and cfg.Aimbot then 
            lock = not lock; if not lock then targ = nil end 
        elseif i.KeyCode == Enum.KeyCode.KeypadThree then 
            open = not open; G.Enabled = open 
        elseif i.KeyCode == Enum.KeyCode.T then
            sosteniendoT = true
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 and sosteniendoT then
            pcall(function()
                if getRoot(LP.Character) and MouseNativo.Hit then
                    getRoot(LP.Character).CFrame = CFrame.new(MouseNativo.Hit.Position + Vector3.new(0, 3, 0))
                end
            end)
        end 
    end 
end)

UIS.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.T then sosteniendoT = false end end)

-- SISTEMA FLY ESTÁTICO COMPATIBLE
task.spawn(function()
    while true do
        local dt = RS.Heartbeat:Wait()
        if cfg.Fly then
            pcall(function()
                local hrp, hum = getRoot(LP.Character), LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum then
                    hum.PlatformStand = true
                    local dir = Vector3.new(0,0,0)
                    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
                    hrp.CFrame = CFrame.new(hrp.Position + (dir * flySpeed * dt), hrp.Position + Cam.CFrame.LookVector * 100)
                    hrp.Velocity = Vector3.new(0,0,0)
                end
            end)
        else
            pcall(function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.PlatformStand then hum.PlatformStand = false end
            end)
        end
    end
end)

-- BUCLE DE RENDERIZADO PRINCIPAL
local fL = Instance.new("PointLight", Cam) fL.Range, fL.Brightness, fL.Enabled = 10000, 3, false
RS.RenderStepped:Connect(function()
    pcall(function()
        if cfg.Aimbot and lock then 
            if not targ or not targ.Parent or not targ.Parent:FindFirstChild("Humanoid") or targ.Parent.Humanoid.Health <= 0 then targ = GetT() end
            if targ then Cam.CFrame = CFrame.new(Cam.CFrame.Position, targ.Position) end 
        else targ = nil end
        
        fL.Enabled = cfg.FullBright
        if cfg.FullBright then L.GlobalShadows, L.Ambient = false, Color3.fromRGB(255,255,255) else L.GlobalShadows, L.Ambient = oS, oA end
        
        for _,v in pairs(P:GetPlayers()) do 
            if v ~= LP and v.Character then 
                local h = v.Character:FindFirstChild("ESPHl")
                if cfg.ESP then 
                    if not h and getRoot(v.Character) then 
                        h = Instance.new("Highlight", v.Character) h.Name = "ESPHl"
                        h.FillColor, h.FillTransparency, h.OutlineColor, h.DepthMode = Color3.fromRGB(255,0,0), 0.5, Color3.fromRGB(255,255,255), Enum.HighlightDepthMode.AlwaysOnTop
                    end
                else if h then h:Destroy() end end 
            end 
        end
    end)
end)
