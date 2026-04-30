local allowed = 
{
    ["RobloxGui"] = true,
    ["CoreGui"] = true,
    ["PlayerList"] = true,
    ["Chat"] = true,
    ["AutoScanGUI"] = true,
    ["HideSelene"] = true
}
local CoreGui = game:GetService("CoreGui")

local function handle(v)
    if v:IsA("ScreenGui") and not allowed[v.Name] then
        v.Enabled = false
    end
end

task.spawn(function()
    while true do
        for _,v in pairs(CoreGui:GetChildren()) do
            handle(v)
        end
        task.wait(1)
    end
end)

CoreGui.DescendantAdded:Connect(function(v)
    task.wait()
    handle(v)
end)
