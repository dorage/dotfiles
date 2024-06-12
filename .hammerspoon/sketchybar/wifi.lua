local icon = {
	on = "󰖩",
	off = "󰖪",
	nosignal = "󱚵",
}

local function handleChangeWifi(watcher, message)
	local network = hs.wifi.currentNetwork()

	if network == nil then
		hs.execute("sketchybar --set wifi label='OFF' icon='" .. icon["off"] .. "'", true)
		return
	end

	hs.execute(
		"sketchybar --set wifi label='" .. string.sub(network, 0, 4) .. ".." .. "' icon='" .. icon["on"] .. "'",
		true
	)
end

WifiWatcher = hs.wifi.watcher.new(handleChangeWifi)
-- Watcher:watchingFor({ "SSIDChange", "BSSIDChange", "linkChange", "powerChange", "modeChange" })
WifiWatcher:start()

function InitWifiSketchybar()
	handleChangeWifi()
end
