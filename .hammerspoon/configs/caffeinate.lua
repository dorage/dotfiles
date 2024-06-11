local caffeinate = require("hs.caffeinate")

-- https://www.hammerspoon.org/docs/hs.caffeinate.html#set
-- displayIdle - Controls whether the screen will be allowed to sleep (and also the system) if the user is idle.
-- systemIdle - Controls whether the system will be allowed to sleep if the user is idle (display may still sleep).
-- system - Controls whether the system will be allowed to sleep for any reason.

-- Default Setup
-- keep waken up on charging
caffeinate.set("displayIdle", true, true)
caffeinate.set("systemIdle", true, true)
caffeinate.set("system", true, true)

-- Sketchybar IPC

function ToggleCaffeinate(sleepType)
	local aValue = caffeinate.get(sleepType)
	caffeinate.set(sleepType, !aValue, true)

	-- toggle sketchybar options
	local text = aValue and 'on' or 'off'
	os.execute("sketchybar --set caffeinate_" .. sleepType .." label=" .. text )
end
