return {
	'nvim-tree/nvim-tree.lua',
	dependencies = {
		'nvim-tree/nvim-web-devicons',
	},
	config = function()
		-- nvim-tree setup
		-- disable netrw at the very start of your init.lua
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		-- optionally enable 24-bit colour
		vim.opt.termguicolors = true

		local nvim_tree = require('nvim-tree')
		nvim_tree.setup({
			sort = {
				sorter = "case_sensitive",
			},
			view = {
				width = 30,
				relativenumber = true
			},
			renderer = {
				group_empty = true,
			},
			filters = {
				-- dotfiles = true,
			},
			actions = {
				change_dir = {
					enable = false,
					global = false,
					restrict_above_cwd = false,
				}
			}
		})
		vim.cmd([[
				:hi      NvimTreeExecFile    guifg=#ffa0a0
				:hi      NvimTreeSpecialFile guifg=#ff80ff gui=underline
				:hi      NvimTreeSymlink     guifg=Yellow  gui=italic
				:hi link NvimTreeImageFile   Title
		]])

		vim.keymap.set('n', '<leader>ab', '<Cmd>:NvimTreeToggle<CR>', {silent = true})
	end
}
