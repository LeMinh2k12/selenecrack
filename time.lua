-- It is vibe coding but free :)))
--// ===== SERVICES =====
local player = game.Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

--// ===== GUI =====
local gui = Instance.new("ScreenGui", pg)
gui.Name = "ProBountyHUD"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(1, -250, 1, -150)
frame.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
frame.BackgroundTransparency = 0.3
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local text = Instance.new("TextLabel", frame)
text.Size = UDim2.new(1, -10, 1, -10)
text.Position = UDim2.new(0, 5, 0, 5)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.new(1,1,1)
text.Font = Enum.Font.GothamBold
text.TextScaled = true

--// ===== GET STAT =====
local function getBounty()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local val = ls:FindFirstChild("Bounty/Honor")
    return val and val.Value or 0
end

--// ===== TRACK =====
local startTime = 0
local running = false

local lastValue = getBounty()
local totalGain = 0
local totalLoss = 0

--// ===== FORMAT =====
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

--// ===== LOOP =====
task.spawn(function()
    while true do
        local current = getBounty()
        local diff = current - lastValue

        -- bắt đầu tính time khi có thay đổi
        if diff ~= 0 and not running then
            startTime = tick()
            running = true
        end

        -- cộng dồn
        if diff > 0 then
            totalGain += diff
        elseif diff < 0 then
            totalLoss += math.abs(diff)
        end

        -- tính time
        local elapsed = running and (tick() - startTime) or 0

        -- bounty / hour
        local perHour = 0
        if elapsed > 0 then
            perHour = math.floor((totalGain / elapsed) * 3600)
        end

        -- hiển thị diff realtime
        local diffText = ""
        if diff > 0 then
            diffText = "📈 +" .. diff
        elseif diff < 0 then
            diffText = "📉 -" .. math.abs(diff)
        end

        text.Text =
            "💀 " .. current .. "\n" ..
            diffText .. "\n\n" ..
            "⏱ " .. formatTime(elapsed) .. "\n" ..
            "📊 Farm: +" .. totalGain .. "\n" ..
            "💸 Lost: -" .. totalLoss .. "\n" ..
            "⚡ /h: " .. perHour

        lastValue = current
        task.wait(0.5)
    end
end)
