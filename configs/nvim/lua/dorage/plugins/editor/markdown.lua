return {
	-- markdown preview
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
		config = function()
			vim.keymap.set("n", "<leader>zp", "<cmd>MarkdownPreviewToggle<CR>")
		end,
	},
	{
		"OXY2DEV/markview.nvim",
		lazy = false,
		config = function()
			vim.keymap.set("n", "<leader>zv", "<cmd>Markview Toggle<CR>")
		end,
	},
}
