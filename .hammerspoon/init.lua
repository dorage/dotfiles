require("hs.ipc")

-- reload config
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)

-- generate hammerspoon annotation
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "L", function()
	require("Spoons.Annotation").init()
	hs.alert.show("HS annotation generated")
end)

-- import modules
require("Spoons.language")
require("Spoons.hotkey-window")
require("Spoons.tiling")

require("sketchybar")

hs.alert.show("Config loaded")
