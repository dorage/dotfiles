function GetAvailableMemoryGB()
	local vmStats = hs.host.vmStat()

	local totalMemory = vmStats["memSize"]
	-- Calculate total memory used by adding up relevant page counts
	local totalPagesUsed = vmStats["pagesActive"]
		+ vmStats["pagesCompressed"]
		+ vmStats["pagesDecompressed"]
		+ vmStats["pagesPurgeable"]
		+ vmStats["pagesReactivated"]
		+ vmStats["pagesSpeculative"]
		+ vmStats["pagesThrottled"]
		+ vmStats["pagesUsedByVMCompressor"]
		+ vmStats["pagesWiredDown"]
		+ vmStats["uncompressedPages"]
		+ vmStats["swapIns"]

	local totalMemoryUsage = totalPagesUsed * vmStats["pageSize"]

	local available = (totalMemory - totalMemoryUsage) / 1024 / 1024 / 1024

	return math.floor(available * 10) / 10
end

function InitMemorySketchybar()
	local avaialbeMemory = GetAvailableMemoryGB()

	hs.execute("sketchybar --set memory label='" .. avaialbeMemory .. "GB'", true)
end
