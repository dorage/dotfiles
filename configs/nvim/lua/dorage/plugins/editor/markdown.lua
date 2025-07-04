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
		"HakonHarnes/img-clip.nvim",
		event = "VeryLazy",
		opts = {
			default = {
				template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
			},
			markdown = {
				url_encode_path = true, ---@type boolean | fun(): boolean
				template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
				download_images = true, ---@type boolean | fun(): boolean
			},
		},
		keys = {},
	},
}
