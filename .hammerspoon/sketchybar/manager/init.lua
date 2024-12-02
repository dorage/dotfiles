_configs = { sec = 3 }
_widgets = {}

_timer = hs.timer.new(_configs.sec, function()
	print("sketchybar: tik-tok")
	if not hs.application.get("sketchybar") then
		return
	end

	for _, widget in ipairs(_widgets) do
		widget.update()
	end
end)

_timer:start()

local M = {}

M.config = function(configs)
	_configs = configs
	_timer:stop()
	_timer:start()
end

M.add_widget = function(widget)
	widget.init()
	table.insert(_widgets, widget)
end

return M
