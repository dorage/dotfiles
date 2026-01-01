return {
	-- formatter
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cmd = { "ConformInfo" },
		keys = {
			{
				-- Customize or remove this keymap to your liking
				"<F3>",
				function()
					require("conform").format({ timeout_ms = 500, lsp_fallback = true, async = true, quiet = true })
				end,
				mode = "",
				desc = "Conform:Format buffer",
			},
		},
		-- Everything in opts will be passed to setup()
		init = function()
			-- If you want the formatexpr, here is the place to set it
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
			require("conform").setup({
				-- Define your formatters
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					html = { "prettier" },
					css = { "prettier" },
					json = { "prettier" },
					astro = { "prettier" },
					sql = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					perl = { "perltidy" },
				},
				-- Set up format-on-save
				format_on_save = { timeout_ms = 500, lsp_fallback = true, quiet = true },
				-- Customize formatters
				formatters = {
					shfmt = {
						prepend_args = { "-i", "2" },
					},
					prettier = {
						cwd = require("conform.util").root_file({ ".prettierrc" }),
						require_cwd = true,
					},
				},
			})
		end,
	},
}
