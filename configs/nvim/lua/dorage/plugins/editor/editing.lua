return {
	-- emmet
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
	--	 easy commenting
	{ "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = true } },
	{
		"echasnovski/mini.comment",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		version = "*",
		opts = {
			mappings = {
				-- Toggle comment (like `gcip` - comment inner paragraph) for both
				-- Normal and Visual modes
				comment = "gc",
				-- Toggle comment on current line
				comment_line = "gcc",
				-- Toggle comment on visual selection
				comment_visual = "gc",
				-- Define 'comment' textobject (like `dgc` - delete whole comment block)
				-- Works also in Visual mode if mapping differs from `comment_visual`
				textobject = "gc",
			},
			options = {
				custom_commentstring = function()
					return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
				end,
			},
		},
	},
	-- easy surrounding
	{
		"echasnovski/mini.surround",
		version = "*",
		opts = {
			mappings = {
				add = "sa", -- Add surrounding in Normal and Visual modes
				delete = "sd", -- Delete surrounding
				find = "sf", -- Find surrounding (to the right)
				find_left = "sF", -- Find surrounding (to the left)
				highlight = "sh", -- Highlight surrounding
				replace = "sr", -- Replace surrounding
				update_n_lines = "sn", -- Update `n_lines`

				suffix_last = "l", -- Suffix to search with "prev" method
				suffix_next = "n", -- Suffix to search with "next" method
			},
		},
	},
	-- show indent guide
	{
		"lukas-reineke/indent-blankline.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = { enabled = false },
		},
		main = "ibl",
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

			vim.keymap.set("n", "<leader>ftt", function()
				require("trouble").toggle()
			end)
			vim.keymap.set("n", "<leader>ftw", function()
				require("trouble").toggle("workspace_diagnostics")
			end)
			vim.keymap.set("n", "<leader>ftd", function()
				require("trouble").toggle("document_diagnostics")
			end)
			vim.keymap.set("n", "<leader>ftq", function()
				require("trouble").toggle("quickfix")
			end)
			vim.keymap.set("n", "<leader>ftl", function()
				require("trouble").toggle("loclist")
			end)
			vim.keymap.set("n", "gtr", function()
				require("trouble").toggle("lsp_references")
			end)
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
