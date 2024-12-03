local w = 15
local h = 2

hs.grid.setGrid(w .. "x" .. h)

hs.hotkey.bind({ "cmd", "shift" }, "c", function()
	local activeWindow = hs.window.focusedWindow()
	hs.grid.set(activeWindow, "1,0 14x2")
end)
hs.hotkey.bind({ "cmd", "shift" }, "f", function()
	local activeWindow = hs.window.focusedWindow()
	hs.grid.set(activeWindow, "0,0 15x2")
end)
