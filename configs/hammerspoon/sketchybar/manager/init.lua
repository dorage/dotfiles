_widgets = {}

local M = {}

M.add_widget = function(widget, opts)
	if opts == nil then
		opts = {}
	end

	widget.init()

	local widget_id = hs.host.uuid()
	_widgets[widget_id] = {}

	if not opts.only_init then
		local timer = hs.timer.new(opts.time, function()
			if not hs.application.get("sketchybar") then
				return
			end

			widget.update()
		end)
		_widgets[widget_id].timer = timer
		timer:start()
	end
	_widgets[widget_id].widget = widget

	return widget_id
end

M.remove_widget = function(widget_id)
	if not _widgets[widget_id].timer then
		_widgets[widget_id].timer:stop()
	end
	_widgets[widget_id] = nil
end

return M
