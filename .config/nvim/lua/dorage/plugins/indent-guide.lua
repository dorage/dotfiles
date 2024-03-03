return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		dependencies = {
				"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require('ibl').setup()
		end
	},
	{
		"briangwaltney/paren-hint.nvim",
		lazy = false,
		dependencies = {
				"nvim-treesitter/nvim-treesitter",
		},
		config = function()
				require("paren-hint").setup({
						-- Include the opening paren in the ghost text
						include_paren = true,

						-- Show ghost text when cursor is anywhere on the line that includes the close paren rather just when the cursor is on the close paren
						anywhere_on_line = true,

						-- show the ghost text when the opening paren is on the same line as the close paren
						show_same_line_opening = false,
				})
		end
	}
}
