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
				{ path = "~/.hammerspoon/Spoons/Annotation/annotations", words = { "hs" } },
				{ path = "~/.config/lua_ls/defold/api" },
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
					"typescript-language-server",
					"prettier",
					"ty",
					"pyrefly",
					"pyright",
					"basedpyright",
					"jdtls",
					"eslint_d",
					"markdownlint",
					"isort",
					"black",
					"perlnavigator",
					"perl-debug-adapter",
					"stylua",
					"js-debug-adapter",
					"debugpy",
					"tsgo",
					"mdx-analyzer",
					"markdown-oxide",
					"kotlin-lsp",
				},
			})

			vim.lsp.config("kotlin_lsp", {})

			vim.lsp.config("ty", {
				root_markers = { ".git" },
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
				"bashls",
				"gherkin",
				"terraformls",
				"ty", -- astral.sh
				-- "pyrefly",
				-- "basedpyright",
				-- "pyright",
				"rust_analyzer",
				"lua_ls",
				"astro",
				"html",
				"cssls",
				"dartls",
				"tailwindcss",
				"nil_ls", -- nix
				"taplo",
				"yamlls",
				"sqlls",
				"perlnavigator",
				"autotools_ls",
				"dcmls",
				"kotlin_lsp",
			})
		end,
	},
}
