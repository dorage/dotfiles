local wifi = require("hs.wifi")

function isWifiConnected()
	local network = wifi.currentNetwork()
	if network == nil then
		print("")
		return
	end
	print(network)
end
