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
				},
			})

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "live grep" })
			vim.keymap.set("n", "<leader>fbb", builtin.buffers, { desc = "buffers" })
			vim.keymap.set(
				"n",
				"<leader>fbf",
				builtin.current_buffer_fuzzy_find,
				{ desc = "current buffer fuzzy find" }
			)
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "help tags" })
			vim.keymap.set("n", "<leader>fld", builtin.lsp_definitions, { desc = "lsp definitions" })
			vim.keymap.set("n", "<leader>flr", builtin.lsp_references, { desc = "lsp references" })
			vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "keymaps" })

			-- load extension
			require("telescope").load_extension("ui-select")
		end,
	},
	-- markdown
	{
		"renerocksai/telekasten.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("telekasten").setup({
				home = vim.fn.expand("~/workspace/thinking-vault"),
			})

			-- Launch panel if nothing is typed after <leader>z
			vim.keymap.set("n", "<leader>z", "<cmd>Telekasten panel<CR>")

			-- Most used functions
			vim.keymap.set("n", "<leader>zf", "<cmd>Telekasten find_notes<CR>")
			vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
			vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
			vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
			vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
			vim.keymap.set("n", "<leader>zl", "<cmd>Telekasten insert_link<CR>")
		end,
	},
}
