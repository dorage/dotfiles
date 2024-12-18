local icon = {
	on = "󰖩",
	off = "󰖪",
	nosignal = "󱚵",
}

local function update(watcher, message)
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

WifiWatcher = hs.wifi.watcher.new(update)
-- Watcher:watchingFor({ "SSIDChange", "BSSIDChange", "linkChange", "powerChange", "modeChange" })

local M = {}

M.init = function()
	WifiWatcher:start()
end

M.update = function()
	-- DO NOT WRITE CODE
	-- update by hammerspoon builtin watcher
end

return M
