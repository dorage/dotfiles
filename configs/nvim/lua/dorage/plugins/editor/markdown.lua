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
		"jakewvincent/mkdnflow.nvim",
		config = function()
			require("mkdnflow").setup({
				mappings = {
					MkdnEnter = false,
					MkdnTab = false,
					MkdnSTab = false,
					MkdnNextLink = false,
					MkdnPrevLink = false,
					MkdnNextHeading = { "n", "<leader>z;" },
					MkdnPrevHeading = { "n", "<leader>z," },
					MkdnGoBack = false,
					MkdnGoForward = false,
					MkdnCreateLink = false,
					MkdnCreateLinkFromClipboard = false,
					MkdnFollowLink = false,
					MkdnDestroyLink = false,
					MkdnTagSpan = false,
					MkdnMoveSource = false,
					MkdnYankAnchorLink = false,
					MkdnYankFileAnchorLink = false,
					MkdnIncreaseHeading = { "n", "<leader>z+" },
					MkdnDecreaseHeading = { "n", "<leader>z-" },
					MkdnToggleToDo = { { "n", "v" }, "<leader>zt" },
					MkdnNewListItem = false,
					MkdnNewListItemBelowInsert = false,
					MkdnNewListItemAboveInsert = false,
					MkdnExtendList = false,
					MkdnUpdateNumbering = false,
					MkdnTableNextCell = { { "i", "n" }, "<leader>z;" },
					MkdnTablePrevCell = { { "i", "n" }, "<leader>z," },
					MkdnTableNextRow = false,
					MkdnTablePrevRow = false,
					MkdnTableNewRowBelow = { "n", "<leader>zr" },
					MkdnTableNewRowAbove = { "n", "<leader>zR" },
					MkdnTableNewColAfter = { "n", "<leader>zc" },
					MkdnTableNewColBefore = { "n", "<leader>zC" },
					MkdnFoldSection = false,
					MkdnUnfoldSection = false,
				},
			})
		end,
	},
}
