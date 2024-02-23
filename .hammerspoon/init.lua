-- reload config

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)
hs.alert.show("Config loaded")

-- key mapping for vim 
-- Convert input soruce as English and sends 'escape' if inputSource is not English.
-- Sends 'escape' if inputSource is English.
-- key bindding reference --> https://www.hammerspoon.org/docs/hs.hotkey.html
local inputEnglish = "com.apple.keylayout.ABC"
local inputKorean = "com.apple.inputmethod.Korean.2SetKorean"
local esc_bind

function convert_to_eng_with_esc()
	local inputSource = hs.keycodes.currentSourceID()
	if not (inputSource == inputEnglish) then
		hs.eventtap.keyStroke({}, 'right')
		hs.keycodes.currentSourceID(inputEnglish)
	end
	esc_bind:disable()
	hs.eventtap.keyStroke({}, 'escape')
	esc_bind:enable()
end

esc_bind = hs.hotkey.new({}, 'escape', convert_to_eng_with_esc):enable()

-- hotkey window

function create_hot_key_window(app_name, command_key, key)
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

create_hot_key_window('alacritty', {'cmd', 'shift'}, 'g')
