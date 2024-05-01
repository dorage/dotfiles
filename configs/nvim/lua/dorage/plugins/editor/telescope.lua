return {
	{ "nvim-telescope/telescope-ui-select.nvim" },
	-- fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			-- telescope setup
			-- referenced by NvChad
			require("telescope").setup({
				defaults = {
					theme = "cursor",
					file_ignore_patterns = {
						"node_modules/",
						"build/",
						"dist/",
						"yarn.lock$",
						".git/",
					},
					vimgrep_arguments = {
						"rg",
						"-L",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
					},
					prompt_prefix = "   ",
					selection_caret = "  ",
					entry_prefix = "  ",
					initial_mode = "insert",
					selection_strategy = "reset",
					sorting_strategy = "descending",
					layout_strategy = "horizontal",
					layout_config = {
						horizontal = {
							prompt_position = "bottom",
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							-- mirror = false,
						},
						width = 0.87,
						height = 0.90,
						preview_cutoff = 140,
					},
					file_sorter = require("telescope.sorters").get_fuzzy_file,
					generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
					path_display = { "truncate" },
					winblend = 0,
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					color_devicons = true,
					set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
					file_previewer = require("telescope.previewers").vim_buffer_cat.new,
					grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
					qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
					-- Developer configurations: Not meant for general override
					buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
					mappings = {
						n = { ["q"] = require("telescope.actions").close },
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
				extensios = {
					["ui-select"] = {
						-- require("telescope.themes").get_dropdown({}),
					},
					file_browser = {
						hijack_netrw = true,
					},
				},
			})

			-- remove highlights
			vim.api.nvim_set_hl(0, "TelescopeBorder", { default = false })
			vim.api.nvim_set_hl(0, "TelescopeTitle", { default = false })

			-- load extension
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("file_browser")

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "live grep" })
			vim.keymap.set("n", "<leader>fw", builtin.buffers, { desc = "buffers" })
			vim.keymap.set("n", "<leader>fe", builtin.current_buffer_fuzzy_find, { desc = "current buffer fuzzy find" })
			vim.keymap.set("n", "<leader>fl", builtin.lsp_definitions, { desc = "lsp definitions" })
			vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "lsp references" })
			vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "keymaps" })
			vim.keymap.set("n", "<leader>fb", "<Cmd>Telescope file_browser<CR>", { desc = "file browser" })
			vim.keymap.set(
				"n",
				"<leader>fv",
				"<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
				{ desc = "file browser" }
			)
		end,
	},
	-- markdown
	{
		"renerocksai/telekasten.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telekasten").setup({
				home = vim.fn.expand("~/.config/dorage-vault/vaults"),
			})

			-- Launch panel if nothing is typed after <leader>z
			vim.keymap.set("n", "<leader>zo", "<cmd>Telekasten panel<CR>")

			-- Most used functions
			vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
			vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
			vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
			vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_templated_note<CR>")
			vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
			vim.keymap.set("n", "<leader>zi", "<cmd>Telekasten insert_link<CR>")
		end,
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
}
