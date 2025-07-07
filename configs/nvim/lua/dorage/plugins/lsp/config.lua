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
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "williamboman/mason.nvim", config = true },
			{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
		},
		config = function()
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
