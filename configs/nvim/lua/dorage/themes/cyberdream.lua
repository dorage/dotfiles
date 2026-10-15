return {
	"scottmckendry/cyberdream.nvim",
	config = function()
		require("cyberdream").setup({
			transparent = true,
			highlights = {
				FloatBorder = { fg = "#74FAFC" },
				MiniFilesBorder = { link = "FloatBorder" },
				BlinkCmpMenuBorder = { link = "FloatBorder" },
				WinSeparator = { fg = "#74FAFC" },
			},
			extensions = {
				mini = true,
			},
		})

		vim.cmd([[ colorscheme cyberdream ]])
	end,
}
