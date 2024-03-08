return {
	'jakewvincent/mkdnflow.nvim',
	config = function ()
		require('mkdnflow').setup({
			mappings = {
				MkdnEnter = false,
				MkdnTab = false,
				MkdnSTab = false,
				MkdnNextLink = false,
				MkdnPrevLink = false,
				MkdnNextHeading = {'n', '<leader>z]'},
				MkdnPrevHeading = {'n', '<leader>z['},
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
				MkdnIncreaseHeading = {'n', '<leader>z+'},
				MkdnDecreaseHeading = {'n', '<leader>z-'},
				MkdnToggleToDo = {{'n', 'v'}, '<leader>zt'},
				MkdnNewListItem = false,
				MkdnNewListItemBelowInsert = false,
				MkdnNewListItemAboveInsert = false,
				MkdnExtendList = false,
				MkdnUpdateNumbering = false,
				MkdnTableNextCell = {{'i', 'n'}, '<leader>z;'},
				MkdnTablePrevCell = {{'i', 'n'}, '<leader>z,'},
				MkdnTableNextRow = false,
				MkdnTablePrevRow = false,
				MkdnTableNewRowBelow = {'n', '<leader>zo'},
				MkdnTableNewRowAbove = {'n', '<leader>zO'},
				MkdnTableNewColAfter = {'n', '<leader>za'},
				MkdnTableNewColBefore = {'n', '<leader>zi'},
				MkdnFoldSection = false,
				MkdnUnfoldSection = false,
			}
		})
	end
}
