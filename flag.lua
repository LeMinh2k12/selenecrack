-- 🔧 Roblox Lag Fix Script
-- No Texture | No Shadow | No VFX | Hitbox Only
-- Đặt vào: StarterPlayerScripts (LocalScript)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ══════════════════════════════════════
-- ⚙️ CẤU HÌNH
-- ══════════════════════════════════════
local CONFIG = {
    NoTexture    = true,
    NoShadow     = true,
    NoVFX        = true,
    ShowHitbox   = true,
    HitboxColor  = Color3.fromRGB(255, 0, 0),
    HitboxAlpha  = 0.6,  -- 0 = trong suốt hoàn toàn, 1 = đục
}

-- ══════════════════════════════════════
-- 🖼️ XÓA TEXTURE
-- ══════════════════════════════════════
local function removeTextures(obj)
    if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SpecialMesh") then
        obj:Destroy()
    elseif obj:IsA("BasePart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Color = Color3.fromRGB(163, 162, 165)
    end
    for _, child in ipairs(obj:GetChildren()) do
        removeTextures(child)
    end
end

-- ══════════════════════════════════════
-- 🌑 TẮT SHADOW & LIGHTING
-- ══════════════════════════════════════
local function disableShadows()
    Lighting.GlobalShadows    = false
    Lighting.FogEnd           = 9e9
    Lighting.FogStart         = 9e9
    Lighting.Brightness       = 1
    Lighting.Ambient          = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient   = Color3.fromRGB(178, 178, 178)

    -- Xóa các hiệu ứng Lighting
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Sky") or effect:IsA("Atmosphere") then
            effect:Destroy()
        end
    end
end

-- ══════════════════════════════════════
-- 💥 XÓA VFX (Particles, Beams, ...)
-- ══════════════════════════════════════
local VFX_CLASSES = {
    "ParticleEmitter", "Trail", "Beam",
    "Fire", "Smoke", "Sparkles",
    "BillboardGui", "SurfaceGui",
}

local function removeVFX(obj)
    for _, cls in ipairs(VFX_CLASSES) do
        if obj:IsA(cls) then
            obj:Destroy()
            return
        end
    end
    for _, child in ipairs(obj:GetChildren()) do
        removeVFX(child)
    end
end

-- ══════════════════════════════════════
-- 📦 HIỆN HITBOX (chỉ character players)
-- ══════════════════════════════════════
local function applyHitbox(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Ẩn mesh/appearance, giữ lại hitbox trong suốt
            part.CastShadow = false
            if CONFIG.ShowHitbox then
                -- Làm trong suốt nhưng vẫn thấy viền
                local box = Instance.new("SelectionBox")
                box.Adornee      = part
                box.Color3       = CONFIG.HitboxColor
                box.LineThickness = 0.04
                box.SurfaceTransparency = CONFIG.HitboxAlpha
                box.SurfaceColor3 = CONFIG.HitboxColor
                box.Parent       = part
            end
        end
        if CONFIG.NoVFX then removeVFX(part) end
        if CONFIG.NoTexture then
            if part:IsA("Texture") or part:IsA("Decal") then
                part:Destroy()
            end
        end
    end
end

-- ══════════════════════════════════════
-- 🔁 ÁP DỤNG CHO TẤT CẢ PLAYERS
-- ══════════════════════════════════════
local function onCharacterAdded(character)
    task.wait(1) -- chờ load xong
    applyHitbox(character)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        applyHitbox(plr.Character)
    end
    plr.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(onCharacterAdded)
end)

-- ══════════════════════════════════════
-- 🌍 ÁP DỤNG CHO MAP (Workspace)
-- ══════════════════════════════════════
if CONFIG.NoShadow  then disableShadows() end
if CONFIG.NoTexture then removeTextures(game.Workspace) end
if CONFIG.NoVFX     then removeVFX(game.Workspace) end

-- Theo dõi object mới thêm vào workspace
game.Workspace.DescendantAdded:Connect(function(obj)
    if CONFIG.NoTexture then removeTextures(obj) end
    if CONFIG.NoVFX     then removeVFX(obj) end
    if obj:IsA("BasePart") and CONFIG.NoShadow then
        obj.CastShadow = false
    end
end)

print("✅ Lag Fix đã bật! No Texture | No Shadow | No VFX | Hitbox ON")
