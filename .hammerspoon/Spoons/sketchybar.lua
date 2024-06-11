-- Update Active App icon

-- Create a window filter to watch for window events
activeWindowWatcher = hs.window.filter.new(true)

-- Define a function to handle window focus changes
local function handleWindowFocusChange(window, appName, watcher)
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

activeWindowWatcher:subscribe({
	[hs.window.filter.windowFocused] = handleWindowFocusChange,
	[hs.window.filter.windowUnfocused] = handleWindowFocusChange,
})

-- Update Wifi

-- Update Battery

-- Update caffeinate
