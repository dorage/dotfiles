return {
	'Exafunction/codeium.nvim',
	event = 'BufEnter',
	config = function ()
		require('codeium').setup({})
	end
}
