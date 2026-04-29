--if you can read it my code is vibe coding :)))
--// ===== FILE =====
local fileName = "bf_stats.txt"
local Http = game:GetService("HttpService")

--// ===== FORMAT NUMBER =====
local function formatNumber(num)
    local abs = math.abs(num)
    if abs >= 1e6 then
        return string.format("%.1fM", num/1e6)
    elseif abs >= 1e3 then
        return string.format("%.1fk", num/1e3)
    else
        return tostring(num)
    end
end

--// ===== FORMAT TIME =====
local function formatTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = math.floor(sec%60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

--// ===== LOAD DATA =====
local data = {
    StartTime = 0,
    TotalGain = 0,
    TotalLoss = 0
}

if isfile and isfile(fileName) then
    local ok, decoded = pcall(function()
        return Http:JSONDecode(readfile(fileName))
    end)
    if ok and decoded then
        data = decoded
    end
end

--// ===== SERVICES =====
local player = game.Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

--// ===== GUI =====
local gui = Instance.new("ScreenGui", pg)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 160)
frame.Position = UDim2.new(1, -270, 1, -170)
frame.BackgroundColor3 = Color3.fromRGB(0,170,255)
frame.BackgroundTransparency = 0.3
Instance.new("UICorner", frame)

local text = Instance.new("TextLabel", frame)
text.Size = UDim2.new(1,-10,1,-50)
text.Position = UDim2.new(0,5,0,5)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.new(1,1,1)
text.Font = Enum.Font.GothamBold
text.TextScaled = true

-- RESET BUTTON
local reset = Instance.new("TextButton", frame)
reset.Size = UDim2.new(1,-10,0,35)
reset.Position = UDim2.new(0,5,1,-40)
reset.Text = "RESET"
reset.BackgroundColor3 = Color3.fromRGB(255,80,80)
reset.TextColor3 = Color3.new(1,1,1)
reset.Font = Enum.Font.GothamBold
reset.TextScaled = true
Instance.new("UICorner", reset)

--// ===== GET BOUNTY =====
local function getBounty()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local val = ls:FindFirstChild("Bounty/Honor")
    return val and val.Value or 0
end

--// ===== VAR =====
local lastValue = getBounty()

--// ===== SAVE =====
local function save()
    if writefile then
        writefile(fileName, Http:JSONEncode(data))
    end
end

task.spawn(function()
    while true do
        save()
        task.wait(5)
    end
end)

--// ===== RESET =====
reset.MouseButton1Click:Connect(function()
    data.StartTime = 0
    data.TotalGain = 0
    data.TotalLoss = 0
end)

--// ===== LOOP =====
task.spawn(function()
    while true do
        local current = getBounty()
        local diff = current - lastValue

        -- 🔥 FILTER CHUẨN (bounty thường +5k / +25k / -25k)
        if diff ~= 0 and math.abs(diff) <= 50000 then
            
            -- start time 1 lần duy nhất
            if data.StartTime == 0 then
                data.StartTime = tick()
            end

            if diff > 0 then
                data.TotalGain += diff
            else
                data.TotalLoss += math.abs(diff)
            end
        end

        -- TIME luôn chạy sau khi bắt đầu
        local elapsed = 0
        if data.StartTime ~= 0 then
            elapsed = tick() - data.StartTime
        end

        -- PER HOUR
        local perHour = 0
        if elapsed > 0 then
            perHour = math.floor((data.TotalGain / elapsed) * 3600)
        end

        -- DIFF TEXT
        local diffText = ""
        if diff > 0 and math.abs(diff) <= 50000 then
            diffText = "+ "..formatNumber(diff)
        elseif diff < 0 and math.abs(diff) <= 50000 then
            diffText = "- "..formatNumber(math.abs(diff))
        end

        -- DISPLAY
        text.Text =
            "Bounty/Honor: "..formatNumber(current).."\n"..
            diffText.."\n\n"..
            "Time: "..formatTime(elapsed).."\n"..
            "Farm: +"..formatNumber(data.TotalGain).."\n"..
            "Lost: -" ..formatNumber(data.TotalLoss).."\n"..
            "Per Hour: "..formatNumber(perHour)

        lastValue = current
        task.wait(0.5)
    end
end)
