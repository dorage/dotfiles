local function create_hot_key_window(app_name, command_key, key)
	local spaces = require("hs.spaces")

	hs.hotkey.bind(command_key, key, function()
		local app = hs.application.find(app_name)

		if app == nil then
			hs.application.launchOrFocus(app_name)
		elseif app:isFrontmost() then
			app:hide()
		else
			local win = app:mainWindow()

			local activeSpaces = spaces.activeSpaces()

			spaces.moveWindowToSpace(win:id(), spaces.activeSpaceOnScreen())
			win:focus()
		end
	end)
end

create_hot_key_window("net.kovidgoyal.kitty", { "cmd", "shift" }, "g")
create_hot_key_window("com.google.Chrome", { "cmd", "shift" }, "a")
create_hot_key_window("safari", { "cmd", "shift" }, "s")
create_hot_key_window("com.apple.finder", { "cmd", "shift" }, "d")
