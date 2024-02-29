return {
		'bluz71/vim-moonfly-colors', -- color scheme
		name = "moonfly",
		dependencies = {
			'tribela/vim-transparent', -- remove background color on vim 
			'norcalli/nvim-colorizer.lua', -- high-performance color highlighter
			'https://github.com/itchyny/lightline.vim', -- status line
		},
		lazy = false,
		priority = 100,
		config = function ()
			vim.opt.termguicolors = true

			-- setup moonfly
			vim.cmd([[colorscheme moonfly]])

			-- setup transparent bg
			vim.call('background#enable')

			-- setup lightline
			vim.cmd([[let g:lightline = {'colorscheme': 'moonfly'}]])

			-- config moonfly theme
			vim.g.moonflyCursorColor = true
			vim.g.moonflyItalics = true
			vim.g.moonflyNormalFloat = true
			vim.g.moonflyTerminalColors = true
			vim.g.moonflyTransparent = true
			vim.g.moonflyUndercurls = true
			vim.g.moonflyUnderlineMatchParen = true
			vim.g.moonflyVirtualTextColor = true
			vim.g.moonflyWinSeparator = 2
			vim.opt.fillchars = { horiz = '━', horizup = '┻', horizdown = '┳', vert = '┃', vertleft = '┫', vertright = '┣', verthoriz = '╋', }

			-- local custom_highlight = vim.api.nvim_create_augroup("CustomHighlight", {})
			-- vim.api.nvim_create_autocmd("ColorScheme", {
			-- 	pattern = "moonfly",
			-- 	callback = function()
			-- 		vim.api.nvim_set_hl(0, "Function", { fg = "#ffffff", bold = true })
			-- 	end,
			-- 	group = custom_highlight,
			-- })

			-- setup line number
			vim.cmd([[highlight LineNr guifg=#16FF00]])
			vim.cmd([[hi LineNrAbove guifg=#AAAAAA]])
			vim.cmd([[hi LineNrBelow guifg=#AAAAAA]])

			-- setup current line highlight
			vim.opt.cursorline = true
			-- vim.cmd([[hi CursorLine   guifg=#E3FCBF]])
			-- vim.cmd([[hi CursorColumn guifg=#E3FCBF]])
			--
			-- setup color highlighter
			require('colorizer').setup()
		end
}
