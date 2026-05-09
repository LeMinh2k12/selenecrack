getgenv().Config = {
    Team = "Pirates",
    FarmConfig = {
        ["Out game when done all"] = true,
        ["Bypass Teleport"] = true,
        ["Double Quest(RISK)"] = true
    },
    Items = {
        ["Saber"] = true,
        ["Pole (1st form)"] = true,
        ["Skull Guitar"] = true,
        ["Cursed Dual Katana"] = true,
        ["Godhuman"] = true
    },
    Webhook = {
        ["Enabled"] = false,
        ["Url"] = ""
    }
}
loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/d6c7959dcc94cd24467080d82a56dcf9.lua"))()
