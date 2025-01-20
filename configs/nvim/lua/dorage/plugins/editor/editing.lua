return {
	-- emmet
	{
		"https://github.com/mattn/emmet-vim",
		config = function()
			vim.g.user_emmet_settings = "{ 'javascript.jsx' : { 'extends' : 'jsx' } }"
			vim.g.user_emmet_settings = "{ 'typescriptreact.tsx' : { 'extends' : 'tsx' } }"
			vim.g.user_emmet_leader_key = "<leader>e"
		end,
	},
	{
		"dorage/tree-emmet.nvim",
		config = function()
			local emmet = require("tree-emmet")
			vim.keymap.set({ "n" }, "<leader>ed", emmet.balance_inward, { desc = "Emmet:Balance Inward" })
			vim.keymap.set({ "n" }, "<leader>eD", emmet.balance_outward, { desc = "Emmet:Balance Outward" })
			vim.keymap.set({ "n" }, "<leader>et", emmet.go_to_matching_pair, { desc = "Emmet:Go to Matching Pair" })
			vim.keymap.set({ "n" }, "<leader>eM", emmet.merge_line, { desc = "Emmet:Merge Line" })
		end,
	},
	-- jsdoc
	{
		"heavenshell/vim-jsdoc",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		build = "make install",
		config = function()
			vim.keymap.set({ "n" }, "<leader>ld", "<cmd>JsDoc<cr>", { desc = "JsDoc: insert" })
		end,
	},

	-- pretty diagnostic
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("trouble").setup({
				icons = {
					indent = {
						middle = " ",
						last = " ",
						top = " ",
						ws = "│  ",
					},
				},
				modes = {
					diagnostics = {
						groups = {
							{ "filename", format = "{file_icon} {basename:Title} {count}" },
						},
					},
				},
			})

			vim.keymap.set(
				"n",
				"<leader>ftw",
				"<cmd>Trouble diagnostics toggle<cr>",
				{ desc = "Trouble: Toggle workspace_diagnostics" }
			)
			vim.keymap.set(
				"n",
				"<leader>ftb",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				{ desc = "Trouble: Toggle buffer_diagnostics" }
			)
			vim.keymap.set("n", "<leader>fts", "<cmd>Trouble symbols toggle<cr>", { desc = "Trouble: Toggle symbols" })
			vim.keymap.set("n", "<leader>ftl", "<cmd>Trouble lsp toggle<cr>", { desc = "Trouble: Toggle LSP" })
			vim.keymap.set("n", "<leader>lq", "<cmd>Trouble qflist toggle<cr>", { desc = "Trouble: Quick Fix" })
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("todo-comments").setup()
			vim.keymap.set("n", "<leader>fo", "<Cmd>TodoTelescope<CR>", { desc = "Todo comments" })
		end,
	},
	{
		"nvim-pack/nvim-spectre",
		config = function()
			vim.keymap.set("n", "<leader>so", '<cmd>lua require("spectre").toggle()<CR>', {
				desc = "Toggle Spectre",
			})
			vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
				desc = "Search current word",
			})
			vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
				desc = "Search current word",
			})
			vim.keymap.set("n", "<leader>ep", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
				desc = "Search on current file",
			})
		end,
	},
}
