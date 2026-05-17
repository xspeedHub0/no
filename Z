local HttpService = game:GetService("HttpService")

local url = "https://discord.com/api/webhooks/1477754423634563297/26-MI5ZlyzQySrZWvVd_sfuX3ATwQMAJNiLpcyUUFj_26gqD_xTX3WkTtZgmpbTqBZK6"

pcall(function()
	local response = HttpService:RequestAsync({
		Url = url,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({
			content = "joiner ejecuciónes"
		})
	})
end)
