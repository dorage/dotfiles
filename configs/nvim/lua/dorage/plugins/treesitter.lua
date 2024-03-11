return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	build = ":TSUpdate",
	event = { "BufReadPre", "BufNewFile" },
	config = function ()
		require('nvim-treesitter.configs').setup({
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
				}
			}
		})
	end
}
