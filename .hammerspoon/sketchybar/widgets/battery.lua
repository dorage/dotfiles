local icon = {
	[100] = "󱈏",
	[90] = "󰂂",
	[80] = "󰂁",
	[70] = "󰂀",
	[60] = "󰁿",
	[50] = "󰁾",
	[40] = "󰁽",
	[30] = "󰁼",
	[20] = "󰁻",
	[10] = "󰁺",
	[0] = "󰂃",
	charging = "󰂄",
}

local update = function()
	local percentage = GetBatteryPercentage()
	local isCharging = GetBatteryIsCharging()

	if isCharging then
		hs.execute("sketchybar --set battery label='" .. percentage .. "%' icon='" .. icon["charging"] .. "'", true)
		return
	end

	for i = 100, 0, -10 do
		if percentage >= i then
			hs.execute("sketchybar --set battery label='" .. percentage .. "%' icon='" .. icon[i] .. "'", true)
			return
		end
	end

	hs.execute("sketchybar --set battery label='" .. percentage .. "%' icon='" .. icon[0] .. "'", true)
end

battery_watcher = hs.battery.watcher.new(update)

-- return number
-- ex) 0, 40, 80, 100
local function get_percentage()
	local battery = hs.battery.getAll()
	local percentage = math.floor(battery.percentage)

	return percentage
end

-- return boolean string
-- ex) true, false
local function get_is_charging()
	local battery = hs.battery.getAll()
	local isCharging = battery.powerSource == "AC Power"

	print(isCharging)
	return isCharging
end

local M = {}

M.init = function()
	-- start Watcher
	battery_watcher:start()
end

M.update = update
return M
