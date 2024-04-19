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
			require("telescope").setup({
				defaults = {
					theme = "cursor",
					file_ignore_patterns = {
						"node_modules",
						"build",
						"dist",
						"yarn.lock",
						".git",
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
				home = vim.fn.expand("~/workspace/thinking-vault/vaults"),
			})

			-- Launch panel if nothing is typed after <leader>z
			vim.keymap.set("n", "<leader>zo", "<cmd>Telekasten panel<CR>")

			-- Most used functions
			vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
			vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
			vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
			vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
			vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
			vim.keymap.set("n", "<leader>zl", "<cmd>Telekasten insert_link<CR>")
		end,
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
}
