return {
	-- Neovim dev env
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
				{ path = "~/.hammerspoon/Spoons/Annotation/annotations", words = { "hs" } },
				{ path = "~/.config/lua_ls/defold/api" },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
	-- LSP config helper
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		lazy = true,
		config = false,
		init = function()
			-- Disable automatic setup, we are doing it manually
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},
	-- LSP installation manager
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = true,
	},
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	{
		"williamboman/mason-lspconfig.nvim",
	},
	-- LSP config
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			-- This is where all the LSP shenanigans will live
			local lsp_zero = require("lsp-zero")
			lsp_zero.extend_lspconfig()

			--- if you want to know more about lsp-zero and mason.nvim
			--- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				lsp_zero.default_keymaps({ buffer = bufnr })
			end)

			lsp_zero.set_sign_icons({
				error = "✘",
				warn = "▲",
				hint = "⚑",
				info = "»",
			})

			require("mason-tool-installer").setup({
				ensure_installed = {
					"prettier",
					"eslint_d",
					"markdownlint",
					"isort",
					"black",
					"perlnavigator",
					"perl-debug-adapter",
					"stylua",
					"js-debug-adapter",
				},
			})

			require("mason-lspconfig").setup({
				automatic_installation = true,
				ensure_installed = {
					"pyright",
					"rust_analyzer",
					"lua_ls",
					"ts_ls",
					"astro",
					"html",
					"jedi_language_server",
					"biome",
					"cssls",
					"tailwindcss",
					"taplo",
					"vuels",
					"yamlls",
					"marksman",
					"sqlls",
					"perlnavigator",
					"autotools_ls",
				},
				handlers = {
					lsp_zero.default_setup,
					lua_ls = function()
						-- (Optional) Configure lua language server for neovim
						-- local lua_opts = lsp_zero.nvim_lua_ls()
						require("lspconfig").lua_ls.setup({
							settings = {
								-- Lua = {
								-- 	diagnostics = {
								-- 		globals = { "vim" },
								-- 	},
								-- 	completion = {
								-- 		callSnippet = "Replace",
								-- 	},
								-- },
							},
						})
					end,
					ts_ls = function()
						require("lspconfig").ts_ls.setup({
							filetypes = { "javascript", "javascriptreact" },
						})
					end,
				},
			})
		end,
	},
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		config = function()
			require("typescript-tools").setup({
				filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
				on_attach = function(_, bufnr)
					vim.keymap.set(
						"n",
						"gd",
						"<cmd>TSToolsGoToSourceDefinition<cr>",
						{ buffer = bufnr, desc = "TS Go to source definition" }
					)
					vim.keymap.set(
						"n",
						"<leader>lr",
						"<cmd>TSToolsRenameFile<cr>",
						{ buffer = bufnr, desc = "TS Rename file" }
					)
					vim.keymap.set(
						"n",
						"<leader>loa",
						"<cmd>TSToolsOrganizeImports<cr>",
						{ buffer = bufnr, desc = "TS Sort and Remove unused imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>los",
						"<cmd>TSToolsSortImports<cr>",
						{ buffer = bufnr, desc = "TS Sort imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>lod",
						"<cmd>TSToolsRemoveUnusedImports<cr>",
						{ buffer = bufnr, desc = "TS Remove unused imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>lf",
						"<cmd>TSToolsFileReferences<cr>",
						{ buffer = bufnr, desc = "TS Remove unused imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>lof",
						"<cmd>TSToolsAddMissingImports<cr>",
						{ buffer = bufnr, desc = "TS Add missing imports" }
					)
				end,
			})
		end,
	},
	-- tailwind-tools.lua
	{
		"luckasRanarison/tailwind-tools.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {}, -- your configuration
	},
}
