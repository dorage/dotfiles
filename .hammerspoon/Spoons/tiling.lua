---active_win_id 를 가진 window를 제외한 window들의 chooser를 띄웁니다
---@param active_win_id string|nil
---@param callback fun(PARAM: { value: string }): nil
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

--
-- properties
local left_margin = 98 -- sketchbar width = 90 , margin of left & right = 8

-- half to left
hs.hotkey.bind({ "cmd", "shift" }, "h", function()
	local active_win = hs.window.focusedWindow()
	if active_win == nil then
		return
	end

	local active_frame = active_win:frame()
	local screen_frame = active_win:screen():frame()

	active_frame.x = screen_frame.x + left_margin
	active_frame.y = screen_frame.y
	active_frame.w = (screen_frame.w - left_margin) / 2
	active_frame.h = screen_frame.h

	active_win:setFrame(active_frame)

	windowChooser(active_win:id(), function(choice)
		local other_frame = {}
		other_frame.x = active_frame.x + active_frame.w
		other_frame.y = active_frame.y
		other_frame.w = active_frame.w
		other_frame.h = active_frame.h

		local other_win = hs.window(choice.value)
		if other_win == nil then
			return
		end
		other_win:setFrame(other_frame)
		other_win:focus()
		active_win:focus()
	end)
end)

-- full
hs.hotkey.bind({ "cmd", "shift" }, "k", function()
	local active_win = hs.window.focusedWindow()
	if active_win == nil then
		return
	end

	local active_frame = active_win:frame()
	local screen_frame = active_win:screen():frame()

	active_frame.x = screen_frame.x + left_margin
	active_frame.y = screen_frame.y
	active_frame.w = screen_frame.w - left_margin
	active_frame.h = screen_frame.h

	active_win:setFrame(active_frame)
end)

-- half to right
hs.hotkey.bind({ "cmd", "shift" }, "l", function()
	local active_win = hs.window.focusedWindow()
	if active_win == nil then
		return
	end

	local active_frame = active_win:frame()
	local screen_frame = active_win:screen():frame()

	active_frame.w = (screen_frame.w - left_margin) / 2
	active_frame.h = screen_frame.h
	active_frame.x = screen_frame.x + left_margin + active_frame.w
	active_frame.y = screen_frame.y

	active_win:setFrame(active_frame)

	windowChooser(active_win:id(), function(choice)
		local other_frame = {}
		other_frame.x = active_frame.x - active_frame.w
		other_frame.y = active_frame.y
		other_frame.w = active_frame.w
		other_frame.h = active_frame.h

		local other_win = hs.window(choice.value)
		if other_win == nil then
			return
		end
		other_win:setFrame(other_frame)
		other_win:focus()
		active_win:focus()
	end)
end)

-- find & focus
hs.hotkey.bind({ "cmd", "shift" }, "f", function()
	local activeWindow = hs.window.focusedWindow()
	windowChooser(activeWindow:id(), function(choice)
		hs.window(choice.value):focus()
	end)
end)
