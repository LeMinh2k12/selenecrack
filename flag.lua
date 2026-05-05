local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local Lighting   = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local CFG = {
    HITBOX_COLOR    = Color3.fromRGB(255, 50,  50), 
    SELF_COLOR      = Color3.fromRGB(50,  200, 255),  
    EFFECT_COLOR    = Color3.fromRGB(255, 210, 0),  
    BOX_THICKNESS   = 0.07,
    BOX_FILL_ALPHA  = 0.80,
    SMALL_STUDS     = 5,   
}
local REMOVE_CLASSES = {
    "ParticleEmitter","Smoke","Fire","Sparkles",
    "Trail","Beam","BillboardGui","SurfaceGui",
    "PointLight","SpotLight","SurfaceLight",
    "SelectionBox","Highlight","Explosion",
}

local EFFECT_FOLDERS = {
    "effects","skills","projectiles","spells","abilities",
    "fx","vfx","attacks","bullets","aoes","hitboxes",
    "combat","magic","powers","shots","orbs",
}

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

local function isPlayerCharacterPart(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and obj:IsDescendantOf(p.Character) then
            return true
        end
    end
    return false
end
local function isLivingModelPart(obj)
    if isPlayerCharacterPart(obj) then return true end
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

local function applyLighting()
    Lighting.GlobalShadows  = false
    Lighting.ShadowSoftness = 0

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") then
            child:Destroy()
        end
    end

    Lighting.ChildAdded:Connect(function(child)
        if child:IsA("PostEffect") then
            task.defer(function()
                if child and child.Parent then child:Destroy() end
            end)
        end
    end)

    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end

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

    part.DescendantAdded:Connect(function(d)
        if d:IsA("Texture") or d:IsA("Decal") or d:IsA("SurfaceAppearance") then
            task.defer(function() if d.Parent then d:Destroy() end end)
        end
    end)
end

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

local function scanForNPCs(parent)
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
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

local function handleObj(obj)
    if isLivingModelPart(obj) then return end

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
        if inEffectFolder(obj) then
            obj.Transparency = 1
            obj.CastShadow   = false
            stripTextures(obj)
            makeHitbox(obj, CFG.EFFECT_COLOR)
            return
        end

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

RunService.RenderStepped:Connect(function()
    if settings().Rendering.QualityLevel ~= Enum.QualityLevel.Level01 then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

applyLighting()
