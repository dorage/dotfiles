return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"html",
					"astro",
					"c",
					"css",
					"lua",
					"vim",
					"vimdoc",
					"query",
					"javascript",
					"typescript",
					"tsx",
					"json",
					"python",
					"regex",
					"rust",
					"sql",
					"perl",
					"http",
					"nix",
				},
				highlight = {
					enable = true,
					-- additional_vim_regex_highlighting = true,
					disable = {
						"lua",
					},
				},
				indent = {
					enable = true,
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["aa"] = { query = "@assignment.outer", desc = "@assignment.outer" },
							["ia"] = { query = "@assignment.inner", desc = "@assignment.inner" },
							["la"] = { query = "@assignment.lhs", desc = "@assignment.lhs" },
							["ra"] = { query = "@assignment.rhs", desc = "@assignment.rhs" },
							["ab"] = { query = "@block.outer", desc = "@block.outer" },
							["ib"] = { query = "@block.inner", desc = "@block.inner" },
							["af"] = { query = "@function.outer", desc = "@function.outer" },
							["if"] = { query = "@function.inner", desc = "@function.inner" },
							["ac"] = { query = "@comment.outer", desc = "@comment.outer" },
							["ic"] = { query = "@comment.inner", desc = "@comment.inner" },
							["ai"] = { query = "@conditional.outer", desc = "@conditional.outer" },
							["ii"] = { query = "@conditional.inner", desc = "@conditional.inner" },
							["al"] = { query = "@loop.outer", desc = "@loop.outer" },
							["il"] = { query = "@loop.inner", desc = "@loop.inner" },
						},
					},
					move = {
						enable = true,
						set_jumps = true,
					},
				},
				sync_install = true,
				auto_install = true,
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "gnn",
						scope_incremental = "gnm",
						node_incremental = "gn;",
						node_decremental = "gn,",
					},
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 10, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = "⎯",
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})

			vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { bg = nil })
			vim.api.nvim_set_hl(0, "TreesitterContext", { bg = nil })
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup({
				opts = {
					-- Defaults
					enable_close = true, -- Auto close tags
					enable_rename = true, -- Auto rename pairs of tags
					enable_close_on_slash = true, -- Auto close on trailing </
				},
			})
		end,
	},
}
