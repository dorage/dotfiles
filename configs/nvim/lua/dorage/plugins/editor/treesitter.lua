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
		"nvim-treesitter/nvim-treesitter-textobjects",
		lazy = true,
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						-- Automatically jump forward to textobj, similar to targets.vim
						lookahead = true,

						keymaps = {
							["a="] = { query = "@assignment.outer", desc = "outer part of an assignment" },
							["i="] = { query = "@assignment.inner", desc = "inner part of an assignment" },
							["l="] = { query = "@assignment.lhs", desc = "left hand side of an assignment" },
							["r="] = { query = "@assignment.rhs", desc = "right hand side of an assignment" },

							["aa"] = { query = "@parameter.outer", desc = "outer part of a parameter/argument" },
							["ia"] = { query = "@parameter.inner", desc = "inner part of a parameter/argument" },

							["ai"] = { query = "@conditional.outer", desc = "outer part of a conditional" },
							["ii"] = { query = "@conditional.inner", desc = "inner part of a conditional" },

							["al"] = { query = "@loop.outer", desc = "outer part of a loop" },
							["il"] = { query = "@loop.inner", desc = "inner part of a loop" },

							["af"] = { query = "@call.outer", desc = "outer part of a function call" },
							["if"] = { query = "@call.inner", desc = "inner part of a function call" },

							["am"] = { query = "@function.outer", desc = "outer part of a function definition" },
							["im"] = { query = "@function.inner", desc = "inner part of a function definition" },

							["ac"] = { query = "@class.outer", desc = "outer part of a class" },
							["ic"] = { query = "@class.inner", desc = "inner part of a class" },
						},
					},
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]f"] = { query = "@call.outer", desc = "Next function call start" },
							["]m"] = { query = "@function.outer", desc = "Next method/function def start" },
							["]c"] = { query = "@class.outer", desc = "Next class start" },
							["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
							["]l"] = { query = "@loop.outer", desc = "Next loop start" },

							-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
							-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
							["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
							["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
						},
						goto_next_end = {
							["]F"] = { query = "@call.outer", desc = "Next function call end" },
							["]M"] = { query = "@function.outer", desc = "Next method/function def end" },
							["]C"] = { query = "@class.outer", desc = "Next class end" },
							["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
							["]L"] = { query = "@loop.outer", desc = "Next loop end" },
						},
						goto_previous_start = {
							["[f"] = { query = "@call.outer", desc = "Prev function call start" },
							["[m"] = { query = "@function.outer", desc = "Prev method/function def start" },
							["[c"] = { query = "@class.outer", desc = "Prev class start" },
							["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
							["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
						},
						goto_previous_end = {
							["[F"] = { query = "@call.outer", desc = "Prev function call end" },
							["[M"] = { query = "@function.outer", desc = "Prev method/function def end" },
							["[C"] = { query = "@class.outer", desc = "Prev class end" },
							["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
							["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
						},
					},
				},
			})

			local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

			-- vim way: ; goes to the direction you were moving.
			-- It makes default repeatable_move is not working
			-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
			-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

			-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
			-- It makes every textobject to movement like dtf makes tf
			-- vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
			-- vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
			-- vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
			-- vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
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
}
