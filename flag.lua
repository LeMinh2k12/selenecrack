-- ============================================================
--  HitboxMode v3  –  LocalScript
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
    HITBOX_COLOR    = Color3.fromRGB(255, 50,  50),   -- hitbox player khác
    SELF_COLOR      = Color3.fromRGB(50,  200, 255),  -- hitbox bản thân
    EFFECT_COLOR    = Color3.fromRGB(255, 210, 0),    -- hitbox skill lớn
    BOX_THICKNESS   = 0.07,
    BOX_FILL_ALPHA  = 0.80,
    SMALL_STUDS     = 5,   -- part/effect nhỏ hơn giá trị này (studs) sẽ bị xoá
}

-- Effect nhỏ dạng Instance → xoá luôn
local REMOVE_CLASSES = {
    "ParticleEmitter","Smoke","Fire","Sparkles",
    "Trail","Beam","BillboardGui","SurfaceGui",
    "PointLight","SpotLight","SurfaceLight",
    "SelectionBox","Highlight","Explosion",
}

-- Folder chứa skill/projectile
local EFFECT_FOLDERS = {
    "effects","skills","projectiles","spells","abilities",
    "fx","vfx","attacks","bullets","aoes","hitboxes",
    "combat","magic","powers","shots","orbs",
}

-- ────────────────────────────────────────────────────────────
-- HELPERS
-- ────────────────────────────────────────────────────────────
local function isRemoveClass(obj)
    for _, cls in ipairs(REMOVE_CLASSES) do
        if obj:IsA(cls) then return true end
    end
    return false
end

local function isSmallPart(obj)
    if not obj:IsA("BasePart") then return false end
    local s = obj.Size
    return s.X < CFG.SMALL_STUDS
       and s.Y < CFG.SMALL_STUDS
       and s.Z < CFG.SMALL_STUDS
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

-- Trả về true nếu obj thuộc character của player
local function isPlayerCharacterPart(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end

-- Trả về true nếu obj thuộc model có Humanoid (NPC hoặc player)
local function isLivingModelPart(obj)
    if isPlayerCharacterPart(obj) then return true end
    -- Tìm model cha gần nhất
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

-- ────────────────────────────────────────────────────────────
-- 1. LIGHTING – tắt shadow, GIỮ màu sắc bình thường
--    KHÔNG thêm bất kỳ PostEffect nào → không xám màn hình
-- ────────────────────────────────────────────────────────────
local function applyLighting()
    Lighting.GlobalShadows  = false
    Lighting.ShadowSoftness = 0

    -- Xoá các PostEffect CÓ SẴN (bloom, blur, dof, sunrays, colorcorrection)
    -- KHÔNG tạo mới → màn hình giữ nguyên màu gốc
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") then
            child:Destroy()
        end
    end

    -- Ngăn game tự thêm lại PostEffect
    Lighting.ChildAdded:Connect(function(child)
        if child:IsA("PostEffect") then
            task.defer(function()
                if child and child.Parent then child:Destroy() end
            end)
        end
    end)

    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end

-- ────────────────────────────────────────────────────────────
-- 2. XOÁ TEXTURE TRÊN PART (giữ màu + hình dạng gốc)
-- ────────────────────────────────────────────────────────────
local stripped = {}

local function stripTextures(part)
    if not part:IsA("BasePart") then return end
    if stripped[part] then return end
    stripped[part] = true

    part.Material    = Enum.Material.SmoothPlastic
    part.Reflectance = 0
    part.CastShadow  = false

    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal")
        or child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance") then
            child:Destroy()
        end
    end

    -- Chặn game thêm lại texture
    part.DescendantAdded:Connect(function(d)
        if d:IsA("Texture") or d:IsA("Decal") or d:IsA("SurfaceAppearance") then
            task.defer(function() if d.Parent then d:Destroy() end end)
        end
    end)
end

-- ────────────────────────────────────────────────────────────
-- 3. HITBOX
-- ────────────────────────────────────────────────────────────
local boxes = {}

local function makeHitbox(part, color)
    if boxes[part] then return end
    local box = Instance.new("SelectionBox")
    box.Adornee             = part
    box.Color3              = color
    box.LineThickness        = CFG.BOX_THICKNESS
    box.SurfaceTransparency = CFG.BOX_FILL_ALPHA
    box.SurfaceColor3       = color
    box.Parent              = part
    boxes[part] = box

    part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(game) then
            box:Destroy()
            boxes[part]   = nil
            stripped[part] = nil
        end
    end)
end

-- ────────────────────────────────────────────────────────────
-- 4. CHARACTER
-- ────────────────────────────────────────────────────────────
local function handleCharacter(char, isSelf)
    local color = isSelf and CFG.SELF_COLOR or CFG.HITBOX_COLOR

    local function proc(obj)
        if isRemoveClass(obj) then
            task.defer(function() if obj.Parent then obj:Destroy() end end)
            return
        end
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CastShadow   = false
            stripTextures(obj)
            makeHitbox(obj, color)
        end
    end

    for _, obj in ipairs(char:GetDescendants()) do proc(obj) end
    char.DescendantAdded:Connect(function(obj)
        task.wait()
        proc(obj)
    end)
end

local function bindPlayer(player)
    local isSelf = (player == LocalPlayer)
    if player.Character then task.spawn(handleCharacter, player.Character, isSelf) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        handleCharacter(char, isSelf)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do bindPlayer(p) end
Players.PlayerAdded:Connect(bindPlayer)

-- ────────────────────────────────────────────────────────────
-- 4b. NPC (Model có Humanoid, không phải player)
-- ────────────────────────────────────────────────────────────
local handledModels = {}

local function handleNPC(model)
    if handledModels[model] then return end
    handledModels[model] = true

    local function proc(obj)
        if isRemoveClass(obj) then
            task.defer(function() if obj.Parent then obj:Destroy() end end)
            return
        end
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CastShadow   = false
            stripTextures(obj)
            makeHitbox(obj, CFG.HITBOX_COLOR)
        end
    end

    for _, obj in ipairs(model:GetDescendants()) do proc(obj) end
    model.DescendantAdded:Connect(function(obj)
        task.wait()
        proc(obj)
    end)
end

-- Scan NPC hiện có + lắng nghe NPC spawn sau
local function scanForNPCs(parent)
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            -- Không phải character của player nào
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == obj then isPlayer = true break end
            end
            if hum and not isPlayer then
                task.spawn(handleNPC, obj)
            end
        end
    end
end


-- ────────────────────────────────────────────────────────────
-- 5. WORKSPACE  (map + skill/effect)
-- ────────────────────────────────────────────────────────────
local function handleObj(obj)
    -- Bỏ qua part thuộc player character hoặc NPC (xử lý riêng)
    if isLivingModelPart(obj) then return end

    -- Class nhỏ (particle, light…) → xoá
    if isRemoveClass(obj) then
        task.defer(function() if obj.Parent then obj:Destroy() end end)
        return
    end

    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
        -- Part nhỏ hơn 5 studs → xoá
        if isSmallPart(obj) then
            task.defer(function() if obj.Parent then obj:Destroy() end end)
            return
        end

        -- Part nằm trong folder skill → ẩn + hitbox
        if inEffectFolder(obj) then
            obj.Transparency = 1
            obj.CastShadow   = false
            stripTextures(obj)
            makeHitbox(obj, CFG.EFFECT_COLOR)
            return
        end

        -- Part map thông thường → chỉ xoá texture, giữ màu
        stripTextures(obj)
    end
end

for _, obj in ipairs(workspace:GetDescendants()) do
    task.spawn(handleObj, obj)
end

workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    handleObj(obj)
end)

-- ────────────────────────────────────────────────────────────
-- 6. GIỮ GRAPHICS THẤP
-- ────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if settings().Rendering.QualityLevel ~= Enum.QualityLevel.Level01 then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

-- ────────────────────────────────────────────────────────────
applyLighting()
print("[HitboxMode v3] ✅ Màn hình bình thường | Bỏ texture | Part <5 studs bị xoá | Hitbox rõ")
