return {
	-- html toolkit
	{
		"mattn/emmet-vim",
		branch = "master",
	},
	-- easy commenting
	{
		"https://github.com/tpope/vim-commentary",
	},
	-- easy surrounding
	{
		"https://github.com/tpope/vim-surround",
	},
	-- show indent guide
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("ibl").setup()
		end,
	},
}
