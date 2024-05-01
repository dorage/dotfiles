return {
	{
		"Exafunction/codeium.nvim",
		event = "BufEnter",
		config = function()
			require("codeium").setup({})
		end,
	},
	{
		"saadparwaiz1/cmp_luasnip",
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{ "VonHeikemen/lsp-zero.nvim" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "l3mon4d3/luasnip" }, -- snippet
			{ "saadparwaiz1/cmp_luasnip" }, -- snippet
			{ "onsails/lspkind.nvim" }, -- vscode style compeletion
			{ "Exafunction/codeium.nvim" }, -- ai autocompletion
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			cmp.setup({
				sources = cmp.config.sources({
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "codeium" },
					{ name = "mkdnflow" },
				}),
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- For 'luasnip' users
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- Enable "Super Tab"
					["<Tab>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function()
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						elseif cmp.visible() then
							cmp.select_prev_item()
						else
							print("nothing to jump to!")
						end
					end, { "i", "s" }),

					["<CR>"] = cmp.mapping({
						i = function(fallback)
							if cmp.visible() and cmp.get_active_entry() then
								cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
							else
								fallback()
							end
						end,
						s = cmp.mapping.confirm({ select = true }),
						c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
					}),
					["<Esc>"] = cmp.mapping.abort(),
				}),
				window = {
					completion = {
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
						col_offset = -3,
						side_padding = 2,
					},
					-- documentation = cmp.config.window.bordered(winhighlight),
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						ellipsis_char = "...",
						show_labelDetails = true,
						symbol_map = {
							Codeium = "🤖",
							Snippet = "✨",
						},
					}),
				},
			})
		end,
	},
}
