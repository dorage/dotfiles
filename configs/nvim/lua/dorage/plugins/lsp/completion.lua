return {
	{
		"saghen/blink.cmp",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		dependencies = {
			"L3MON4D3/LuaSnip",
			version = "v2.*",
		},
		opts = {
			snippets = { preset = "luasnip" },
			keymap = { preset = "super-tab" },
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = {
					auto_show = true,
					window = { border = "single" },
				},
				ghost_text = { enabled = true },
			},
			signature = {
				enabled = true,
				window = { border = "single" },
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
}
