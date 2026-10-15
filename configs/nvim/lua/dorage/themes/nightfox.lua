return {
	"EdenEast/nightfox.nvim",
	config = function()
		require("nightfox").setup({
			options = {
				transparent = true,
			},
			palettes = {
				carbonfox = {
					red = "#ee5396",
					green = "#4BFF36",
					cyan = "#74FAFC",
					blue = "#33b1ff",
					yellow = "#FFEB01",
					magenta = "#E92EFB",
					orange = "#FF5C00",
					white = "#dfdfdf",
					comment = "#999999",
				},
			},
			groups = {
				all = {
					NormalFloat = { fg = "fg1", bg = "NONE" },
				},
			},
		})

		-- vim.cmd([[ colorscheme nightfox ]])
		-- vim.cmd([[ colorscheme dayfox ]])
		-- vim.cmd([[ colorscheme dawnfox ]])
		-- vim.cmd([[ colorscheme duskfox ]])
		-- vim.cmd([[ colorscheme nordfox ]])
		-- vim.cmd([[ colorscheme terafox ]])
		vim.cmd([[ colorscheme carbonfox ]])
	end,
}
