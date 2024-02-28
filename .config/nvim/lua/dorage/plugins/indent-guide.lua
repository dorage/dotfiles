return {
	'preservim/vim-indent-guides',
	config = function()
		vim.cmd([[let g:indent_guides_enable_on_vim_startup = 1]])
		vim.cmd([[let g:indent_guides_auto_colors = 0]])
		vim.cmd([[let g:indent_guides_guide_size = 1]])
		vim.cmd([[let g:indent_guides_start_level = 2]])
		vim.cmd([[hi IndentGuidesOdd  guibg=#666666   ctermbg=3]])
		vim.cmd([[hi IndentGuidesEven guibg=#999999 ctermbg=4]])
	end
}
