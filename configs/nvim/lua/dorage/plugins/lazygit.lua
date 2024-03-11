return {
	'https://github.com/voldikss/vim-floaterm',
	config = function()
		vim.keymap.set('n', '<leader>ag', '<Cmd>:FloatermNew lazygit<CR>')
	end
}
