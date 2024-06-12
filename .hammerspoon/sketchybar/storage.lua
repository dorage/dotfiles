function GetAvailableStoarge()
	local volumeInformation = hs.host.volumeInformation()
	local availableSpace = volumeInformation["/"].NSURLVolumeAvailableCapacityKey / 1024 / 1024 / 1024
	availableSpace = math.floor(availableSpace * 10) / 10

	print(availableSpace .. "GB")
	return availableSpace
end

function InitStorageSketchybar()
	local availableSpace = GetAvailableStoarge()

	if availableSpace >= 100 then
		hs.execute("sketchybar --set storage label='≥100GB'", true)
		return
	end

	hs.execute("sketchybar --set storage label='" .. availableSpace .. "GB'", true)
end
