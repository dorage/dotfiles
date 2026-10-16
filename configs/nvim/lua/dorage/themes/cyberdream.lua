return {
	"scottmckendry/cyberdream.nvim",
	config = function()
		require("cyberdream").setup({
			options = {
				theme = "light",
			},
			colors = {
				bg = "#16181a",
				bg_alt = "#1e2124",
				bg_highlight = "#2c2f36",
				fg = "#e8ebf0",
				grey = "#99a0ae",
				blue = "#71c4ff",
				green = "#5eff6c",
				cyan = "#5ef1ff",
				red = "#ffa491",
				yellow = "#f1ff5e",
				magenta = "#ff95ff",
				pink = "#ff9fc7",
				orange = "#ffbd5e",
				purple = "#cfacff",
			},
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
