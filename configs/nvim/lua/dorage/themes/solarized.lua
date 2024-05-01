return {
	"Tsuzat/NeoSolarized.nvim",
	config = function()
		vim.cmd([[ colorscheme NeoSolarized ]])

		require("NeoSolarized").setup({
			style = "dark", -- "dark" or "light"
			transparent = true, -- true/false; Enable this to disable setting the background color
		})
	end,
}
