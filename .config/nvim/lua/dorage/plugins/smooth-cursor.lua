return {
'gen740/SmoothCursor.nvim',
config = function()
	require('smoothcursor').setup({
		type = "default",           -- Cursor movement calculation method, choose "default", "exp" (exponential) or "matrix".

		cursor = "🍕",              -- Cursor shape (requires Nerd Font). Disabled in fancy modee.
		texthl = "SmoothCursor",   -- Highlight group. Default is { bg = nil, fg = "#FFD400" }. Disabled in fancy mode.
		linehl = nil,              -- Highlights the line under the cursor, similar to 'cursorline'. "CursorLine" is recommended. Disabled in fancy mode.

		autostart = true,           -- Automatically start SmoothCursor
		always_redraw = true,       -- Redraw the screen on each update
		flyin_effect = nil,         -- Choose "bottom" or "top" for flying effect
		speed = 25,                 -- Max speed is 100 to stick with your current position
		intervals = 35,             -- Update intervals in milliseconds
		priority = 10,              -- Set marker priority
		timeout = 3000,             -- Timeout for animations in milliseconds
		threshold = 10,              -- Animate only if cursor moves more than this many lines
		disable_float_win = false,  -- Disable in floating windows
		enabled_filetypes = nil,    -- Enable only for specific file types, e.g., { "lua", "vim" }
		disabled_filetypes = nil,   -- Disable for these file types, ignored if enabled_filetypes is set. e.g., { "TelescopePrompt", "NvimTree" }
		-- Show the position of the latest input mode positions. 
		-- A value of "enter" means the position will be updated when entering the mode.
		-- A value of "leave" means the position will be updated when leaving the mode.
		-- `nil` = disabled
		show_last_positions = nil,
	})
end
}
