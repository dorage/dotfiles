return {
	-- status line
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	-- tabline plugin
	{
		"https://github.com/romgrk/barbar.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		config = function()
			require("barbar").setup({
				animation = false,
				clickable = false,
				hide = { extensions = true },
			})

			local map = vim.api.nvim_set_keymap
			local opts = { noremap = true, silent = true }

			-- Move to previous/next
			map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
			map("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)
			-- Re-order to previous/next
			map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts)
			map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", opts)
			-- Goto buffer in position...
			map("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", opts)
			map("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", opts)
			map("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", opts)
			map("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", opts)
			map("n", "<A-5>", "<Cmd>BufferGoto 5<CR>", opts)
			map("n", "<A-6>", "<Cmd>BufferGoto 6<CR>", opts)
			map("n", "<A-7>", "<Cmd>BufferGoto 7<CR>", opts)
			map("n", "<A-8>", "<Cmd>BufferGoto 8<CR>", opts)
			map("n", "<A-9>", "<Cmd>BufferGoto 9<CR>", opts)
			map("n", "<A-0>", "<Cmd>BufferLast<CR>", opts)
			-- Pin/unpin buffer
			map("n", "<A-p>", "<Cmd>BufferPin<CR>", opts)
			-- Close buffer
			map("n", "<A-c>", "<Cmd>BufferClose<CR>", opts)
			-- Wipeout buffer
			--                 :BufferWipeout
			-- Close commands
			--                 :BufferCloseAllButCurrent
			--                 :BufferCloseAllButPinned
			--                 :BufferCloseAllButCurrentOrPinned
			--                 :BufferCloseBuffersLeft
			--                 :BufferCloseBuffersRight
			-- Magic buffer-picking mode
			-- map("n", "<C-p>", "<Cmd>BufferPick<CR>", opts)
			-- Sort automatically by...
			-- map("n", "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", opts)
			-- map("n", "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>", opts)
			-- map("n", "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>", opts)
			-- map("n", "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", opts)

			-- Other:
			-- :BarbarEnable - enables barbar (enabled by default)
			-- :BarbarDisable - very bad command, should never be used
		end,
	},
	-- file tree explorer
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			-- nvim-tree setup
			-- disable netrw at the very start of your init.lua
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1

			-- optionally enable 24-bit colour
			vim.opt.termguicolors = true

			local nvim_tree = require("nvim-tree")
			nvim_tree.setup({
				sort = {
					sorter = "case_sensitive",
				},
				view = {
					width = 30,
					relativenumber = true,
				},
				renderer = {
					group_empty = true,
				},
				filters = {
					-- dotfiles = true,
				},
				actions = {
					change_dir = {
						enable = false,
						global = false,
						restrict_above_cwd = false,
					},
				},
			})
			vim.cmd([[
					:hi      NvimTreeExecFile    guifg=#ffa0a0
					:hi      NvimTreeSpecialFile guifg=#ff80ff gui=underline
					:hi      NvimTreeSymlink     guifg=Yellow  gui=italic
					:hi link NvimTreeImageFile   Title
			]])

			vim.keymap.set("n", "<leader>ab", "<Cmd>:NvimTreeToggle<CR>", { silent = true })
		end,
	},
	-- floating terminal
	{
		"https://github.com/voldikss/vim-floaterm",
		config = function()
			vim.keymap.set("n", "<leader>ag", "<Cmd>:FloatermNew --width=0.95 --height=0.95 lazygit<CR>")
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
			window = {
				border = "single",
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

				cursor = "", -- Cursor shape (requires Nerd Font). Disabled in fancy modee.
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
	-- notify
	{
		"rcarriga/nvim-notify",
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
		lazy = true,
		config = function()
			local notify = require("notify")
			notify.setup({
				fps = 1,
				render = "compact",
				states = "static",
				level = 3,
				background_color = nil,
			})
			vim.notify = notify

			require("telescope").load_extension("notify")
			vim.keymap.set({ "n" }, "<leader>fn", "<Cmd>Telescope notify<cr>", { desc = "notify" })
		end,
	},
	-- pretty command line
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("noice").setup({
				lsp = {
					-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = true, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = false, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = false, -- add a border to hover docs and signature help
				},
				views = {
					cmdline_popup = {
						position = {
							row = "50%", -- 40% from top of the screen. This will position it almost at the center.
							col = "50%",
						},
						size = {
							width = 120,
							height = "auto",
						},
						cursorline = false,
					},
					popupmenu = {
						position = {
							row = "auto", -- Popup will show up below the cmdline automatically
							col = "auto",
						},
						size = {
							width = 120,
							height = "auto",
						},
					},
				},
			})
			vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { link = "MoonflyCrimson" })
			require("telescope").load_extension("noice")
		end,
	},
}
