-- reload config
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)
hs.alert.show("Config loaded")

-- import modules
require("Spoons.language")
require("Spoons.hotkey-window")
