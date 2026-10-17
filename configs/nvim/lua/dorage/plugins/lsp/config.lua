return {
	-- Java LSP
	{ "nvim-java/nvim-java" },
	-- Neovim dev env
	{
		"folke/lazydev.nvim",
		ft = "lua",
		dependencies = {
			{ "Bilal2453/luvit-meta", lazy = true },
		},
		opts = {
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	-- LSP config
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		priority = 100,
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
		},
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"tailwindcss-language-server",
					"prettier",
					"ty",
					"jdtls",
					"eslint_d",
					"black",
					"perlnavigator",
					"stylua",
					"js-debug-adapter",
					"debugpy",
					"tsgo",
					"mdx-analyzer",
					"markdown-oxide",
					"kotlin-lsp",
				},
			})

			vim.lsp.config("tsgo", {
				root_markers = { ".git", "pnpm-lock.yaml" },
			})

			vim.lsp.config("markdown_oxide", {
				root_markers = { ".git" },
				filetypes = { "markdown" },
			})

			vim.lsp.enable({
				"markdown_oxide",
				"tsgo",
				"mdx_analyzer",
				"jdtls",
				"ty", -- astral.sh
				"rust_analyzer",
				"lua_ls",
				"dartls",
				"tailwindcss",
				"perlnavigator",
				"kotlin_lsp",
			})
		end,
	},
}
