local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local function setGraySky()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
            v:Destroy()
        end
    end

    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://0" 
    sky.SkyboxDn = "rbxassetid://0"
    sky.SkyboxFt = "rbxassetid://0"
    sky.SkyboxLf = "rbxassetid://0"
    sky.SkyboxRt = "rbxassetid://0"
    sky.SkyboxUp = "rbxassetid://0"
    sky.SunTextureId = ""
    sky.MoonTextureId = ""
    
    Lighting.FogColor = Color3.fromRGB(128, 128, 128)
    Lighting.Ambient = Color3.fromRGB(100, 100, 100)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
end

local function lowerGraphics()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        elseif v:IsA("MeshPart") then
            v.RenderFidelity = Enum.RenderFidelity.Performance
        end
    end
end

local function createFPSCounter()
    if CoreGui:FindFirstChild("HM_FPS_Counter") then
        CoreGui.HM_FPS_Counter:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "HM_FPS_Counter"

    local FPSLabel = Instance.new("TextLabel", ScreenGui)
    FPSLabel.Size = UDim2.new(0, 100, 0, 30)
    FPSLabel.Position = UDim2.new(0, 10, 0, 10)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 0) 
    FPSLabel.TextSize = 18
    FPSLabel.Font = Enum.Font.Code
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.TextStrokeTransparency = 0.5

    local lastTime = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 1 then
            FPSLabel.Text = "FPS: " .. tostring(frameCount)

            if frameCount < 30 then
                FPSLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            elseif frameCount < 60 then
                FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
            
            frameCount = 0
            lastTime = currentTime
        end
    end)
end

setGraySky()
lowerGraphics()
createFPSCounter()
