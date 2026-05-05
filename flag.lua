-- ============================================================
--  HitboxMode LocalScript
--  Đặt vào: StarterPlayerScripts hoặc StarterCharacterScripts
-- ============================================================

local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer  = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────
-- CẤU HÌNH
-- ────────────────────────────────────────────────────────────
local CONFIG = {
    SKY_COLOR        = Color3.fromRGB(160, 160, 160),  -- màu bầu trời
    GROUND_COLOR     = Color3.fromRGB(120, 120, 120),  -- màu mặt đất
    HITBOX_COLOR     = Color3.fromRGB(255, 60,  60),   -- màu hitbox player khác
    SELF_COLOR       = Color3.fromRGB(60,  200, 255),  -- màu hitbox bản thân
    EFFECT_COLOR     = Color3.fromRGB(255, 200, 0),    -- màu hitbox skill/effect
    BOX_THICKNESS    = 0.08,
    SHADOW_SOFTNESS  = 0,
    AMBIENT_BRIGHTNESS = 0.4,
}

-- ────────────────────────────────────────────────────────────
-- 1. ĐỒ HỌA THẤP & BẦU TRỜI XÁM
-- ────────────────────────────────────────────────────────────
local function applyLowGraphics()
    -- Tắt mọi hiệu ứng hậu kỳ
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Sky") or effect:IsA("Atmosphere") then
            effect:Destroy()
        end
    end

    -- Ánh sáng tối giản
    Lighting.Brightness         = CONFIG.AMBIENT_BRIGHTNESS
    Lighting.GlobalShadows      = false
    Lighting.ShadowSoftness     = CONFIG.SHADOW_SOFTNESS
    Lighting.Ambient            = Color3.fromRGB(120, 120, 120)
    Lighting.OutdoorAmbient     = Color3.fromRGB(120, 120, 120)
    Lighting.FogEnd             = 10000
    Lighting.FogStart           = 9999
    Lighting.FogColor           = CONFIG.SKY_COLOR
    Lighting.ColorShift_Bottom  = Color3.new(0, 0, 0)
    Lighting.ColorShift_Top     = Color3.new(0, 0, 0)
    Lighting.EnvironmentDiffuseScale  = 0
    Lighting.EnvironmentSpecularScale = 0

    -- Đặt màu nền (sky color qua ColorCorrectionEffect)
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0
    cc.Contrast   = 0
    cc.Saturation = -1   -- desaturate hoàn toàn → xám
    cc.TintColor  = Color3.fromRGB(200, 200, 200)
    cc.Parent     = Lighting

    -- Đặt graphics level thấp nhất
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end

-- ────────────────────────────────────────────────────────────
-- 2. XÓA TEXTURE / LÀM TRONG SUỐT TẤT CẢ PART
-- ────────────────────────────────────────────────────────────
local processedParts = {}

local function clearPart(part)
    if not part:IsA("BasePart") then return end
    if processedParts[part] then return end
    processedParts[part] = true

    part.Material    = Enum.Material.SmoothPlastic
    part.Reflectance = 0
    part.CastShadow  = false

    -- Xóa texture con
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SpecialMesh") then
            child:Destroy()
        end
    end

    -- Làm trong suốt (giữ collision)
    part.Transparency = 1
end

local function clearModel(model)
    for _, desc in ipairs(model:GetDescendants()) do
        clearPart(desc)
    end
    model.DescendantAdded:Connect(function(desc)
        task.wait()
        clearPart(desc)
    end)
end

-- ────────────────────────────────────────────────────────────
-- 3. VẼ HITBOX (SelectionBox) CHO PART / MODEL
-- ────────────────────────────────────────────────────────────
local hitboxes = {} -- part → SelectionBox

local function makeHitbox(part, color)
    if not part:IsA("BasePart") then return end
    if hitboxes[part] then return end

    local box = Instance.new("SelectionBox")
    box.Adornee       = part
    box.Color3        = color
    box.LineThickness = CONFIG.BOX_THICKNESS
    box.SurfaceTransparency = 0.85
    box.SurfaceColor3 = color
    box.Parent        = part

    hitboxes[part] = box

    part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(game) then
            box:Destroy()
            hitboxes[part] = nil
            processedParts[part] = nil
        end
    end)
end

-- ────────────────────────────────────────────────────────────
-- 4. XỬ LÝ CHARACTER (Player)
-- ────────────────────────────────────────────────────────────
local function handleCharacter(character, isSelf)
    local color = isSelf and CONFIG.SELF_COLOR or CONFIG.HITBOX_COLOR
    clearModel(character)

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            makeHitbox(part, color)
        end
    end
    character.DescendantAdded:Connect(function(part)
        task.wait()
        if part:IsA("BasePart") then
            clearPart(part)
            makeHitbox(part, color)
        end
    end)
end

-- Bind tất cả player hiện tại & tương lai
local function bindPlayer(player)
    local isSelf = (player == LocalPlayer)

    if player.Character then
        handleCharacter(player.Character, isSelf)
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        handleCharacter(char, isSelf)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do bindPlayer(p) end
Players.PlayerAdded:Connect(bindPlayer)

-- ────────────────────────────────────────────────────────────
-- 5. XỬ LÝ SKILL / EFFECT (Workspace)
-- ────────────────────────────────────────────────────────────
-- Tag tên folder chứa effect của game bạn vào đây
local EFFECT_TAGS = {
    "Effects", "Skills", "Projectiles", "Spells",
    "Abilities", "FX", "VFX", "Attacks",
}

local function isEffectObject(obj)
    -- Nhận biết qua tên cha hoặc tag
    local parent = obj.Parent
    if parent then
        for _, tag in ipairs(EFFECT_TAGS) do
            if parent.Name:lower():find(tag:lower()) then return true end
        end
    end
    -- Nhận biết bằng tên object chứa từ khóa
    local name = obj.Name:lower()
    for _, tag in ipairs(EFFECT_TAGS) do
        if name:find(tag:lower()) then return true end
    end
    return false
end

local function handleWorkspaceDesc(obj)
    if not obj:IsA("BasePart") then return end

    -- Bỏ qua character part (đã xử lý riêng)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then return end
    end

    -- Bỏ qua Terrain
    if obj:IsA("Terrain") then return end

    -- Nếu là effect → hitbox vàng
    if isEffectObject(obj) then
        clearPart(obj)
        makeHitbox(obj, CONFIG.EFFECT_COLOR)
    else
        -- Part thông thường (map) → xóa texture, giữ trong suốt nhẹ
        obj.Material    = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow  = false
        -- Giữ part map nhìn thấy được nhưng xám, không texture
        obj.Transparency = math.max(obj.Transparency, 0)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Texture") or child:IsA("Decal") then
                child:Destroy()
            end
        end
    end
end

-- Quét toàn bộ workspace lúc đầu
for _, obj in ipairs(workspace:GetDescendants()) do
    task.spawn(handleWorkspaceDesc, obj)
end

workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    handleWorkspaceDesc(obj)
end)

-- ────────────────────────────────────────────────────────────
-- 6. XỬ LÝ TERRAIN (mặt đất xám)
-- ────────────────────────────────────────────────────────────
local function grayTerrain()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end

    -- Đặt tất cả màu terrain về xám
    local grayColor = ColorSequence.new(CONFIG.GROUND_COLOR)
    terrain.WaterColor    = CONFIG.GROUND_COLOR
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterTransparency = 0
    terrain.WaterReflectance  = 0

    -- Override material color qua SurfaceAppearance (nếu có)
    for _, child in ipairs(terrain:GetChildren()) do
        if child:IsA("SurfaceAppearance") then child:Destroy() end
    end
end

grayTerrain()

-- ────────────────────────────────────────────────────────────
-- 7. GIỮ SETTINGS ĐỒ HỌA THẤP LIÊN TỤC
-- ────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if settings().Rendering.QualityLevel ~= Enum.QualityLevel.Level01 then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

-- ────────────────────────────────────────────────────────────
-- KHỞI CHẠY
-- ────────────────────────────────────────────────────────────
applyLowGraphics()
grayTerrain()

print("[HitboxMode] ✅ Đã bật: Bầu trời xám | Không texture | Đồ họa thấp | Chỉ hiện hitbox")
