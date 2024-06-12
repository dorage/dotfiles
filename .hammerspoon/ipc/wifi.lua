local wifi = require("hs.wifi")

function isWifiConnected()
	local network = wifi.currentNetwork()
	if network == nil then
		return
	end
end
