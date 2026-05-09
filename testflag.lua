local function SetGraySky()
    local Lighting = game:GetService("Lighting")

    Lighting.FogColor = Color3.fromRGB(40, 40, 40)
    Lighting.FogEnd = 3000
    Lighting.FogStart = 0
    Lighting.ClockTime = 20 
    Lighting.Brightness = 1
    Lighting.GlobalShadows = false 
    Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50)

    for , v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
            v:Destroy()
        end
    end

    local graySky = Instance.new("Sky", Lighting)
    graySky.SkyboxBk = "rbxassetid://600832773" 
    graySky.SkyboxDn = "rbxassetid://600832773"
    graySky.SkyboxFt = "rbxassetid://600832773"
    graySky.SkyboxLf = "rbxassetid://600832773"
    graySky.SkyboxRt = "rbxassetid://600832773"
    graySky.SkyboxUp = "rbxassetid://600832773"
    graySky.SunAngularSize = 0
    graySky.MoonAngularSize = 0
end

local function LowerTexture()
    for , v in pairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("Texture") or v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("MeshPart") then
            v.TextureID = "" 
            v.Material = Enum.Material.SmoothPlastic
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        end
    end
    for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end
