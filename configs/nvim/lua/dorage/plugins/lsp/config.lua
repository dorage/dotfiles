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
					"pyright",
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
				},
			})

			vim.lsp.config("basedpyright", {
				root_markers = { ".git" },
				settings = {
					basedpyright = {
						analysis = {
							autoSearchPaths = true,
							autoImportCompletions = true,
							useLibraryCodeForTypes = true,
							logLevel = "Warning",
						},
					},
					python = {
						pythonPath = vim.fn.exepath("python3"), -- 또는 가상환경 경로
					},
				},
			})

			vim.lsp.enable({
				"tsgo",
				"jdtls",
				"bashls",
				-- "eslint",
				-- "denols",
				"basedpyright",
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
				-- "tailwindcss",
				"nil_ls", -- nix
				"taplo",
				"vuels",
				"yamlls",
				"marksman",
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
	-- flutter-tools
	{
		"nvim-flutter/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
		},
		config = true,
	},
}
