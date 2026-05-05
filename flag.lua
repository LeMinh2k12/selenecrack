-- ============================================================
--  HitboxMode v2  –  LocalScript
--  StarterPlayer > StarterPlayerScripts
-- ============================================================

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local Lighting   = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────
-- CẤU HÌNH
-- ────────────────────────────────────────────────────────────
local CFG = {
    HITBOX_COLOR     = Color3.fromRGB(255, 50,  50),   -- hitbox player khác
    SELF_COLOR       = Color3.fromRGB(50,  200, 255),  -- hitbox bản thân
    EFFECT_COLOR     = Color3.fromRGB(255, 210, 0),    -- hitbox skill lớn
    BOX_THICKNESS    = 0.07,
    BOX_FILL_ALPHA   = 0.80,   -- độ trong suốt mặt box (0=đặc, 1=trong)
}

-- Class effect nhỏ → tự xoá luôn
local SMALL_EFFECTS = {
    "ParticleEmitter", "Smoke", "Fire", "Sparkles",
    "Trail", "Beam", "BillboardGui", "SurfaceGui",
    "PointLight", "SpotLight", "SurfaceLight",
    "SelectionBox",  -- xoá box cũ nếu game tự tạo
    "Highlight",
    "Explosion",     -- chỉ visual, không cần
}

-- Class effect lớn (có va chạm) → ẩn + vẽ hitbox
local BIG_EFFECT_CLASSES = {
    "Part", "MeshPart", "UnionOperation", "SpecialMesh",
}

-- Tên folder chứa skill/projectile của game
local EFFECT_FOLDERS = {
    "effects","skills","projectiles","spells","abilities",
    "fx","vfx","attacks","bullets","aoes","hitboxes",
    "combat","magic","powers","shots","orbs",
}

-- ────────────────────────────────────────────────────────────
-- HELPER
-- ────────────────────────────────────────────────────────────
local function isSmallEffect(obj)
    for _, cls in ipairs(SMALL_EFFECTS) do
        if obj:IsA(cls) then return true end
    end
    return false
end

local function inEffectFolder(obj)
    local cur = obj.Parent
    while cur and cur ~= game do
        local name = cur.Name:lower()
        for _, tag in ipairs(EFFECT_FOLDERS) do
            if name == tag or name:find(tag) then return true end
        end
        cur = cur.Parent
    end
    return false
end

local function isBigEffect(obj)
    if not obj:IsA("BasePart") then return false end
    return inEffectFolder(obj)
end

local function isCharacterPart(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

-- ────────────────────────────────────────────────────────────
-- 1. LIGHTING – chỉ tắt shadow, GIỮ màu sắc
-- ────────────────────────────────────────────────────────────
local function applyLighting()
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0

    -- Xoá chỉ shadow/post-process, GIỮ Sky & Atmosphere (màu sắc bình thường)
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("BlurEffect")
        or child:IsA("DepthOfFieldEffect")
        or child:IsA("SunRaysEffect")
        or child:IsA("ColorCorrectionEffect")
        or child:IsA("BloomEffect") then
            child:Destroy()
        end
    end

    -- Đồ họa thấp nhất
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end

-- ────────────────────────────────────────────────────────────
-- 2. BỎ TEXTURE TRÊN PART (giữ màu gốc của Part)
-- ────────────────────────────────────────────────────────────
local clearedParts = {}

local function stripTextures(part)
    if not part:IsA("BasePart") then return end
    if clearedParts[part] then return end
    clearedParts[part] = true

    part.Material    = Enum.Material.SmoothPlastic
    part.Reflectance = 0
    part.CastShadow  = false

    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal")
        or child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance") then
            child:Destroy()
        end
    end

    part.DescendantAdded:Connect(function(d)
        if d:IsA("Texture") or d:IsA("Decal")
        or d:IsA("SurfaceAppearance") then
            task.defer(function() d:Destroy() end)
        end
    end)
end

-- ────────────────────────────────────────────────────────────
-- 3. HITBOX (SelectionBox)
-- ────────────────────────────────────────────────────────────
local boxes = {}

local function makeHitbox(part, color)
    if boxes[part] then return end
    local box = Instance.new("SelectionBox")
    box.Adornee              = part
    box.Color3               = color
    box.LineThickness         = CFG.BOX_THICKNESS
    box.SurfaceTransparency  = CFG.BOX_FILL_ALPHA
    box.SurfaceColor3        = color
    box.Parent               = part
    boxes[part] = box

    part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(game) then
            box:Destroy()
            boxes[part] = nil
            clearedParts[part] = nil
        end
    end)
end

-- ────────────────────────────────────────────────────────────
-- 4. XỬ LÝ CHARACTER
-- ────────────────────────────────────────────────────────────
local function handleCharacter(char, isSelf)
    local color = isSelf and CFG.SELF_COLOR or CFG.HITBOX_COLOR

    local function processPart(obj)
        if obj:IsA("BasePart") then
            -- Ẩn mesh/skin, chỉ giữ hitbox
            obj.Transparency = 1
            obj.CastShadow   = false
            stripTextures(obj)
            makeHitbox(obj, color)
        elseif isSmallEffect(obj) then
            task.defer(function() if obj.Parent then obj:Destroy() end end)
        end
    end

    for _, obj in ipairs(char:GetDescendants()) do
        processPart(obj)
    end
    char.DescendantAdded:Connect(function(obj)
        task.wait()
        processPart(obj)
    end)
end

local function bindPlayer(player)
    local isSelf = (player == LocalPlayer)
    if player.Character then
        task.spawn(handleCharacter, player.Character, isSelf)
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        handleCharacter(char, isSelf)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do bindPlayer(p) end
Players.PlayerAdded:Connect(bindPlayer)

-- ────────────────────────────────────────────────────────────
-- 5. XỬ LÝ WORKSPACE (map + effect)
-- ────────────────────────────────────────────────────────────
local function handleWorkspaceObj(obj)
    -- Bỏ qua character parts (đã xử lý)
    if isCharacterPart(obj) then return end

    -- Effect nhỏ → xoá ngay
    if isSmallEffect(obj) then
        task.defer(function() if obj.Parent then obj:Destroy() end end)
        return
    end

    -- Effect lớn (part trong folder skill) → ẩn + hitbox vàng
    if isBigEffect(obj) then
        obj.Transparency = 1
        obj.CastShadow   = false
        stripTextures(obj)
        makeHitbox(obj, CFG.EFFECT_COLOR)
        return
    end

    -- Part map thông thường → chỉ xoá texture, GIỮ màu + hình dạng
    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
        stripTextures(obj)
    end
end

-- Quét toàn workspace lúc load
for _, obj in ipairs(workspace:GetDescendants()) do
    task.spawn(handleWorkspaceObj, obj)
end

-- Lắng nghe object mới thêm vào (skill spawn, particle...)
workspace.DescendantAdded:Connect(function(obj)
    task.wait()         -- đợi 1 frame để parent được gán
    handleWorkspaceObj(obj)
end)

-- ────────────────────────────────────────────────────────────
-- 6. GIỮ GRAPHICS THẤP LIÊN TỤC
-- ────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if settings().Rendering.QualityLevel ~= Enum.QualityLevel.Level01 then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

-- ────────────────────────────────────────────────────────────
applyLighting()
print("[HitboxMode v2] ✅ Không B&W | Bỏ texture/shadow | Effect nhỏ tự mất | Hitbox rõ")
