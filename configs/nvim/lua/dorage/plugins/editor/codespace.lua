return {
	-- show shortcut hints
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	-- cursor movement
	{
		"gen740/SmoothCursor.nvim",
		config = function()
			require("smoothcursor").setup({
				type = "default", -- Cursor movement calculation method, choose "default", "exp" (exponential) or "matrix".

				cursor = "🍕", -- Cursor shape (requires Nerd Font). Disabled in fancy modee.
				texthl = "SmoothCursor", -- Highlight group. Default is { bg = nil, fg = "#FFD400" }. Disabled in fancy mode.
				linehl = nil, -- Highlights the line under the cursor, similar to 'cursorline'. "CursorLine" is recommended. Disabled in fancy mode.

				autostart = true, -- Automatically start SmoothCursor
				always_redraw = true, -- Redraw the screen on each update
				flyin_effect = nil, -- Choose "bottom" or "top" for flying effect
				speed = 25, -- Max speed is 100 to stick with your current position
				intervals = 35, -- Update intervals in milliseconds
				priority = 10, -- Set marker priority
				timeout = 3000, -- Timeout for animations in milliseconds
				threshold = 10, -- Animate only if cursor moves more than this many lines
				disable_float_win = false, -- Disable in floating windows
				enabled_filetypes = nil, -- Enable only for specific file types, e.g., { "lua", "vim" }
				disabled_filetypes = nil, -- Disable for these file types, ignored if enabled_filetypes is set. e.g., { "TelescopePrompt", "NvimTree" }
				-- Show the position of the latest input mode positions.
				-- A value of "enter" means the position will be updated when entering the mode.
				-- A value of "leave" means the position will be updated when leaving the mode.
				-- `nil` = disabled
				show_last_positions = nil,
			})
		end,
	},
	-- show indent guide
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("ibl").setup()
		end,
	},
	-- show scope name
	{
		"briangwaltney/paren-hint.nvim",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("paren-hint").setup({
				-- Include the opening paren in the ghost text
				include_paren = true,

				-- Show ghost text when cursor is anywhere on the line that includes the close paren rather just when the cursor is on the close paren
				anywhere_on_line = true,

				-- show the ghost text when the opening paren is on the same line as the close paren
				show_same_line_opening = false,
			})
		end,
	},
}
