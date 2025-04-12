return {
	-- Neovim dev env
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		dependencies = {
			{ "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
		},
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
	-- LSP config
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"williamboman/mason.nvim",
				lazy = false,
				config = true,
			},
			{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
			{ "saghen/blink.cmp" },
		},
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"bashls",
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
					"bashls",
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
					"nil_ls", -- nix
					"taplo",
					"vuels",
					"yamlls",
					"marksman",
					"sqlls",
					"perlnavigator",
					"autotools_ls",
					"graphql",
				},
			})

			local enable_lsp = function(name, config)
				vim.lsp.config(
					name,
					vim.tbl_extend("force", require("lspconfig.configs." .. name).default_config, config)
				)
				vim.lsp.enable(name)
			end

			vim.lsp.config("lua_ls", {
				cmd = { "lua-language-server" },
				filetypes = { "lua" },
				root_markers = {
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					".stylua.toml",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
					".git",
				},
			})
			vim.lsp.enable("lua_ls")

			vim.lsp.config(
				"ts_ls",
				vim.tbl_extend("force", require("lspconfig.configs.ts_ls").default_config, {
					root_markers = {
						"tsconfig.json",
						"jsconfig.json",
						"package.json",
						".git",
					},
				})
			)
			vim.lsp.enable("ts_ls")

			enable_lsp("tailwindcss", {})

			-- blink cmp
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities =
				vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))

			capabilities = vim.tbl_deep_extend("force", capabilities, {
				textDocument = {
					foldingRange = {
						dynamicRegistration = false,
						lineFoldingOnly = true,
					},
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
