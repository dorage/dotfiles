return {
	'https://github.com/voldikss/vim-floaterm',
	config = function()
		vim.keymap.set('n', '<C-g>', '<Cmd>:FloatermNew lazygit<CR>')
	end
}
