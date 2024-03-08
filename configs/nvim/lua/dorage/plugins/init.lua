return {
	'nvim-lua/plenary.nvim', -- famouse lua scripting library
	"MunifTanjim/nui.nvim", -- ui component lib
	'https://github.com/tpope/vim-commentary', -- easy commenting
	{ "folke/neodev.nvim", opts = {}, config = true },
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		}
	},
	{'mg979/vim-visual-multi', branch = 'master' }, -- multiline curosr
	"nvimtools/none-ls.nvim",
}
