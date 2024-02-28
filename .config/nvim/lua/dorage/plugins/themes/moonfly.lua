return {
	'bluz71/vim-moonfly-colors',
	dependencies = {
		'tribela/vim-transparent'
	},
	config = function ()
		vim.cmd('syntax on')
		vim.g.termguicolors = true
		vim.cmd [[colorscheme moonfly]]
		vim.cmd [[let g:lightline = {'colorscheme': 'moonfly'}]]
		vim.call('background#enable')
		vim.cmd [[highlight LineNr guifg=#16FF00]]
		vim.cmd [[hi LineNrAbove guifg=#AAAAAA]]
		vim.cmd [[hi LineNrBelow guifg=#AAAAAA]]
		vim.g.moonflyCursorColor = true
		vim.g.moonflyItalics = true
		vim.g.moonflyNormalFloat = true
		vim.g.moonflyTerminalColors = true
		vim.g.moonflyTransparent = true
		local custom_highlight = vim.api.nvim_create_augroup("CustomHighlight", {})
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "moonfly",
			callback = function()
				vim.api.nvim_set_hl(0, "Function", { fg = "#74b2ff", bold = true })
			end,
			group = custom_highlight,
		})
	end
}
