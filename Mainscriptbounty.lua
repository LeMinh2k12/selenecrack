loadstring(game:HttpGet("https://raw.githubusercontent.com/LeMinh2k12/selenecrack/refs/heads/main/time.lua"))()
repeat task.wait() until game:IsLoaded()
    and game:GetService("Players")
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChild("PlayerGui")
_G.SeleneCFG = {
    Team          = "Pirates",   -- "Pirates" or "Marines" choose team
    Region        = "Singapore", -- choose sever
    WebhookURL    = "",
    DiscordID     = "",
    SuperBoostFps      = true, -- setting false if want see all
}
loadstring(game:HttpGet("https://gist.githubusercontent.com/LeMinh2k12/7341d1a7e1208b959ba70511a6448c63/raw/00d03157131efe06ca10a340e43b9bf9f5e6698b/gistfile1.txt"))()

task.spawn(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/LeMinh2k12/selenecrack/refs/heads/main/bounty.lua"))() end)
