return {
	"EdenEast/nightfox.nvim",
	config = function()
		require("nightfox").setup({
			options = {
				transparent = true,
			},
			palettes = { carbonfox = { comment = "#999999" } },
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

		require("lualine").setup({})
	end,
}
