local HttpService = game:GetService("HttpService")

local url = "https://discord.com/api/webhooks/1477754420665257984/0OlgzertmflVNHO-6dh9mN__0uBVIuBTIJl3yJedq7U7FGXbsVe7ydQY5RhPRbUkSABM"

pcall(function()
	local response = HttpService:RequestAsync({
		Url = url,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({
			content = "gg"
		})
	})
end)


loadstring(game:HttpGet("https://raw.githubusercontent.com/xspeedHub0/Zlhub/refs/heads/main/Centergg.lua"))()
