return {
	"bluz71/vim-moonfly-colors",
	config = function()
		-- Lua initialization file
		local custom_highlight = vim.api.nvim_create_augroup("CustomHighlight", {})
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "moonfly",
			callback = function()
				vim.api.nvim_set_hl(0, "MoonflyVisual", { bg = "#323437" })
			end,
			group = custom_highlight,
		})

		vim.cmd([[colorscheme moonfly]])

		vim.g.moonflyCursorColor = true
		vim.g.moonflyItalics = true
		vim.g.moonflyNormalFloat = true
		vim.g.moonflyTerminalColors = true
		vim.g.moonflyTransparent = true
		vim.g.moonflyUndercurls = true
		vim.g.moonflyUnderlineMatchParen = true
		vim.g.moonflyVirtualTextColor = true
		vim.g.moonflyWinSeparator = 2
		vim.opt.fillchars = {
			horiz = "━",
			horizup = "┻",
			horizdown = "┳",
			vert = "┃",
			vertleft = "┫",
			vertright = "┣",
			verthoriz = "╋",
		}
	end,
}
