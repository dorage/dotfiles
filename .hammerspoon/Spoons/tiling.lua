-- properties
local w = 15
local h = 2
local history = {}

local record_history = function(window, last_move)
	history = {
		window = window,
		last_move = last_move,
	}
end

local move = function(layout, no_recording)
	local activeWindow = hs.window.focusedWindow()
	if not activeWindow then
		return
	end
	hs.grid.set(activeWindow, layout)
	if no_recording then
		return
	end
	record_history(activeWindow:id(), layout)
end

local Tiling = {}

Tiling.move_to_half_left = function()
	move("1,0 14x2")
end

Tiling.undo_move = function()
	local activeWindow = hs.window.focusedWindow()
	if not activeWindow then
		return
	end
	if history["window"] ~= activeWindow:id() then
		return
	end

	move(history["last_move"], true)
end

hs.grid.setGrid(w .. "x" .. h)

-- half to left
hs.hotkey.bind({ "cmd", "shift" }, "h", function()
	local activeWindow = hs.window.focusedWindow()
	hs.grid.set(activeWindow, "1,0 7x2")
end)

local windowChooser = function(active_win_id, callback)
	local chooser = hs.chooser.new(callback)
	local windows = hs.window.allWindows()

	local win_list
	-- remove active window
	win_list = hs.fnutils.filter(windows, function(win)
		return win:id() ~= active_win_id
	end)
	-- format for chooser
	win_list = hs.fnutils.map(win_list, function(win)
		return {
			text = win:title(),
			subText = win:application():name(),
			image = hs.image.imageFromAppBundle(win:application():bundleID()),
			value = win:id(),
		}
	end)
	chooser:choices(win_list)
	chooser:show()
end
-- full
hs.hotkey.bind({ "cmd", "shift" }, "k", function()
	local activeWindow = hs.window.focusedWindow()
	hs.grid.set(activeWindow, "1,0 14x2")
end)
-- half to right
hs.hotkey.bind({ "cmd", "shift" }, "l", function()
	local activeWindow = hs.window.focusedWindow()
	hs.grid.set(activeWindow, "8,0 7x2")
end)

-- find & focus
hs.hotkey.bind({ "cmd", "shift" }, "f", function()
	local activeWindow = hs.window.focusedWindow()
	windowChooser(activeWindow:id(), function(choice)
		hs.window(choice.value):focus()
	end)
end)
