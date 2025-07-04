return {
	{
		"saghen/blink.cmp",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		dependencies = {
			"L3MON4D3/LuaSnip",
		},
		version = "1.4.1",
		opts = {
			keymap = { preset = "enter" },
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				menu = { border = "single" },
				documentation = {
					auto_show = true,
					window = { border = "single" },
				},
			},
			signature = {
				enabled = true,
				window = { border = "single" },
			},
			sources = {
				default = { "lsp", "buffer", "path" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
}
