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
					"tsgo",
					"mdx-analyzer",
					"markdown-oxide",
				},
			})

			vim.lsp.config("ty", {
				root_markers = { ".git" },
			})

			vim.lsp.config("tsgo", {
				root_markers = { ".git", "pnpm-lock.yaml" },
			})

			vim.lsp.config("mdx-analyzer", {})

			vim.lsp.config("markdown-oxide", {
				root_markers = { ".git" },
				filetypes = { "markdown" },
			})

			vim.lsp.enable({
				"markdown-oxide",
				"tsgo",
				"mdx-analyzer",
				"jdtls",
				"bashls",
				"gherkin",
				"terraformls",
				-- "eslint",
				-- "denols",
				"ty", -- astral.sh
				-- "pyrefly",
				-- "basedpyright",
				-- "pyright",
				"rust_analyzer",
				"lua_ls",
				-- "ts_ls",
				"astro",
				"html",
				-- "jedi_language_server",
				-- "biome",
				"cssls",
				"dartls",
				"tailwindcss",
				"nil_ls", -- nix
				"taplo",
				"vuels",
				"yamlls",
				"sqlls",
				"perlnavigator",
				"autotools_ls",
				"dcmls",
			})
		end,
	},
	-- {
	-- 	"pmizio/typescript-tools.nvim",
	-- 	dependencies = { "nvim-lua/plenary.nvim" },
	-- 	config = function()
	-- 		require("typescript-tools").setup({
	-- 			filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
	-- 		})
	-- 	end,
	-- },
}
