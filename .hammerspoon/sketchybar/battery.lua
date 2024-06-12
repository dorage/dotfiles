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

local function handleChangeBattery()
	local percentage = GetBatteryPercentage()
	local isCharging = GetBatteryIsCharging()

	if isCharging then
		hs.execute("sketchybar --set battery label='" .. percentage .. "%' icon='" .. icon["charging"] .. "'", true)
		return
	end

	for i = 100, 0, -10 do
		if percentage >= i then
			hs.execute("sketchybar --set battery label='" .. percentage .. "%' icon='" .. icon[i] .. "'", true)
			break
		end
	end
end

BatteryWatcher = hs.battery.watcher.new(handleChangeBattery)
-- start Watcher
BatteryWatcher:start()

-- return number
-- ex) 0, 40, 80, 100
function GetBatteryPercentage()
	local battery = hs.battery.getAll()
	local percentage = math.floor(battery.percentage)

	print(percentage)
	return percentage
end

-- return boolean string
-- ex) true, false
function GetBatteryIsCharging()
	local battery = hs.battery.getAll()
	local isCharging = battery.powerSource == "AC Power"

	print(isCharging)
	return isCharging
end

-- IPC
function InitBatterySketchybar()
	print("InitBatterySketchybar")
	handleChangeBattery()
end
