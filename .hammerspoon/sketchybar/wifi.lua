local icon = {
	on = "󰖩",
	off = "󰖪",
	nosignal = "󱚵",
}

local function handleChangeWifi(watcher, message)
	print("change", watcher, message)
	local network = hs.wifi.currentNetwork()
	print("network", network)

	if network == nil then
		hs.execute("sketchybar --set wifi label='OFF' icon='" .. icon["off"] .. "'", true)
		return
	end

	hs.execute("sketchybar --set wifi label='CON' icon='" .. icon["on"] .. "'", true)
end

WifiWatcher = hs.wifi.watcher.new(handleChangeWifi)
-- Watcher:watchingFor({ "SSIDChange", "BSSIDChange", "linkChange", "powerChange", "modeChange" })
WifiWatcher:start()
