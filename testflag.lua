-- GraySkyFPS LocalScript
-- Đặt vào: StarterPlayerScripts hoặc StarterCharacterScripts

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- ============================================================
-- 1. BẦU TRỜI XÁM (Gray Sky)
-- ============================================================
local function setGraySky()
    -- Xoá Skybox mặc định
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- Màu sắc bầu trời xám
    Lighting.Ambient         = Color3.fromRGB(90, 90, 90)
    Lighting.OutdoorAmbient  = Color3.fromRGB(100, 100, 100)
    Lighting.FogColor        = Color3.fromRGB(120, 120, 120)
    Lighting.FogEnd          = 1000
    Lighting.FogStart        = 200
    Lighting.Brightness      = 0.5
    Lighting.ClockTime       = 14       -- giữa trưa
    Lighting.GeographicLatitude = 0
    Lighting.ShadowSoftness  = 0.5

    -- Tắt bloom / atmosphere nếu có
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = false
        end
        if effect:IsA("Atmosphere") then
            effect.Density   = 0.5
            effect.Color     = Color3.fromRGB(110, 110, 110)
            effect.Glare     = 0
            effect.Haze      = 2
        end
    end

    print("[GraySky] Bầu trời đã chuyển sang xám.")
end

-- ============================================================
-- 2. GIẢM CHẤT LƯỢNG TEXTURE (Lower Texture Quality)
-- ============================================================
local function lowerTextureQuality()
    -- Mức thấp nhất = 0 (Low), cao nhất = 3 (High)
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    -- Tắt một số hiệu ứng render nặng
    local renderSettings = settings().Rendering
    -- Giảm độ phân giải render
    pcall(function()
        renderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.DistanceBased
    end)

    print("[LowTexture] Chất lượng texture đã giảm xuống mức thấp.")
end

-- ============================================================
-- 3. HIỂN THỊ FPS (FPS Counter GUI)
-- ============================================================
local function createFPSDisplay()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    -- Frame nền
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 110, 0, 36)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Bo góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    -- Label FPS
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "FPS: --"
    label.Parent = frame

    -- Biến đếm FPS
    local frameCount = 0
    local elapsed    = 0
    local fps        = 0

    -- Màu theo FPS
    local function getFPSColor(f)
        if f >= 55 then
            return Color3.fromRGB(80, 255, 80)   -- xanh lá: tốt
        elseif f >= 30 then
            return Color3.fromRGB(255, 200, 0)   -- vàng: trung bình
        else
            return Color3.fromRGB(255, 60, 60)   -- đỏ: thấp
        end
    end

    -- Cập nhật mỗi frame
    RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        elapsed    = elapsed + dt

        if elapsed >= 0.5 then          -- cập nhật mỗi 0.5 giây
            fps        = math.floor(frameCount / elapsed)
            frameCount = 0
            elapsed    = 0

            label.Text      = string.format("FPS: %d", fps)
            label.TextColor3 = getFPSColor(fps)
        end
    end)

    print("[FPS] Đồng hồ FPS đã bật.")
end

-- ============================================================
-- KHỞI CHẠY
-- ============================================================
setGraySky()
lowerTextureQuality()
createFPSDisplay()
