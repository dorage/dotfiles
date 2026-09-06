function get_available_storage()
	local volumeInformation = hs.host.volumeInformation()
	local availableSpace = volumeInformation["/"].NSURLVolumeAvailableCapacityKey / 1024 / 1024 / 1024
	availableSpace = math.floor(availableSpace * 10) / 10

	return availableSpace
end

local M = {}

M.init = function() end

M.update = function()
	local availableSpace = get_available_storage()

	if availableSpace >= 100 then
		hs.execute("sketchybar --set storage label='≥100GB'", true)
		return
	end

	hs.execute("sketchybar --set storage label='" .. availableSpace .. "GB'", true)
end

return M
