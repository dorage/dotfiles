return {
	-- status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	-- floating terminal
	{
		"https://github.com/voldikss/vim-floaterm",
		config = function()
			vim.keymap.set(
				"n",
				"<leader>ag",
				"<Cmd>:FloatermNew --width=0.95 --height=0.95 lazygit<CR>",
				{ desc = "Lazygit" }
			)
			vim.keymap.set(
				"n",
				"<leader>ao",
				"<Cmd>:FloatermNew --width=0.95 --height=0.95 lazydocker<CR>",
				{ desc = "Lazydocker" }
			)
			-- remove border
			vim.api.nvim_set_hl(0, "FloatermBorder", { default = false })
		end,
	},
	-- show shortcut hints
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			preset = "helix",
			win = {
				border = "single",
				title_pos = "center",
				no_overlap = false,
			},
			icons = {
				breadcrumb = "󰇘", -- symbol used in the command line area that shows your active key combo
				separator = "", -- symbol used between a key and it's label
				group = " ", -- symbol prepended to a group
			},
		},
	},
	-- cursor movement
	{
		"gen740/SmoothCursor.nvim",
		config = function()
			require("smoothcursor").setup({
				type = "default", -- Cursor movement calculation method, choose "default", "exp" (exponential) or "matrix".

				cursor = "🔥", -- Cursor shape (requires Nerd Font). Disabled in fancy modee.
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
	-- yank visualizer
	{
		"rachartier/tiny-glimmer.nvim",
		event = "TextYankPost",
		config = function()
			require("tiny-glimmer").setup({
				transparency_color = "333333ef",
			})
		end,
	},
	{
		"hedyhli/outline.nvim",
		config = function()
			-- Example mapping to toggle outline
			vim.keymap.set("n", "<leader>fo", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

			require("outline").setup({
				-- Your setup opts here (leave empty to use defaults)
			})
		end,
	},
}
