function GetAvailableStoarge()
	local volumeInformation = hs.host.volumeInformation()
	local availableSpace = volumeInformation["/"].NSURLVolumeAvailableCapacityKey / 1024 / 1024 / 1024
	availableSpace = math.floor(availableSpace * 10) / 10

	print(availableSpace .. "GB")
end
