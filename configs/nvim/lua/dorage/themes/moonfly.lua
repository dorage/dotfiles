return {
	"bluz71/vim-moonfly-colors",
	config = function()
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
