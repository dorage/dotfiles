-- Create a window filter to watch for window events
WindowWatcher = hs.window.filter.new(true)

-- Define a function to handle window focus changes
local function update(window, appName, watcher)
	local activeWindow = hs.window.focusedWindow()

	-- update app_icon item
	if watcher == "windowFocused" then
		hs.execute(
			"sketchybar --set app_icon background.drawing=on background.image=app."
				.. activeWindow:application():bundleID(),
			true
		)
	elseif watcher == "windowUnfocused" then
		if activeWindow == nil then
			hs.execute("sketchybar --set app_icon background.drawing=off", true)
		end
	end
end

local M = {}

M.init = function()
	WindowWatcher:subscribe({
		[hs.window.filter.windowFocused] = update,
		[hs.window.filter.windowUnfocused] = update,
	})
end

M.update = function()
	-- DO NOT WRITE CODE
	-- update by hammerspoon builtin watcher
end

return M
