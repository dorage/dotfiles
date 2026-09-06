require("hs.ipc")

-- reload config
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	require("Spoons.Annotation").init()
	hs.reload()
end)

-- import modules
require("Spoons.language")
require("Spoons.hotkey-window")
require("Spoons.tiling")

require("sketchybar")

hs.alert.show("Config loaded")
