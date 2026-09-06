local function get_vmstat_in_gb()
	local vmStats = hs.host.vmStat()
	local pageSize = vmStats["pageSize"]

	for partition, size in pairs(vmStats) do
		if partition ~= "pageSize" then
			print(math.floor((size * pageSize) / 1023 / 1024 / 1024 * 100) / 100)
		end
	end
end

local function get_available_memory_in_gb()
	-- local GB = 1024 * 1024 * 1024
	local vmStats = hs.host.vmStat()

	-- local totalMemory = vmStats["memSize"] / GB

	-- File Cache: -> File-backed pages
	-- Wired Memory: -> Pages wired down
	-- Compressed: -> Pages occupied by compressor
	-- App Memory: -> Pages Active + Pages Speculative

	-- local pageSize = vmStats["pageSize"] / GB
	--
	-- -- Calculate total memory used by adding up relevant page counts
	-- local appMemory = vmStats["pagesActive"] + vmStats["pagesSpeculative"] + vmStats["pagesUsedByVMCompressor"]
	-- local wiredMemory = vmStats["pagesWiredDown"]
	--
	-- local totalPagesUsed = appMemory + wiredMemory
	-- local totalMemoryUsage = totalPagesUsed * pageSize

	-- local available = (totalMemory - totalMemoryUsage) / 1024 / 1024 / 1024
	-- local available = totalMemory - totalMemoryUsage

	-- https://www.reddit.com/r/MacOS/comments/1dg8vgb/tracking_historical_ram_usage_on_a_mac/
	local pageSizeKB = 16
	local freeMemoryKB = (vmStats["pagesFree"] + vmStats["pagesInactive"] + vmStats["pagesSpeculative"]) * pageSizeKB

	local availableGB = freeMemoryKB / 1024 / 1024

	return math.floor(availableGB * 10) / 10
end

local M = {}

M.init = function() end

M.update = function()
	local avaialbeMemory = get_available_memory_in_gb()

	hs.execute("sketchybar --set memory label='" .. avaialbeMemory .. "GB'", true)
end

return M
