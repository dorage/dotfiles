function getAppIcon()
	local ax = require("hs.axuielement")
	-- Get the focused application
	local focusedApp = ax.applicationElement(ax.systemWideElement():attributeValue("AXFocusedApplication"))
	-- Get the icon of the focused application
	local appIcon = focusedApp:imageForProperty("AXApplicationIconImagePtr")
	-- Display the icon (for demonstration purposes)
	hs.image.imageFromAppBundle("org.hammerspoon.Hammerspoon", "/Resources/AppIcon.png"):setRawImageData(appIcon)
end
