local afterThemeConfig = function()
	-- setup transparent bg
	vim.call("background#enable")

	-- setup line number highlighting
	vim.api.nvim_set_hl(0, "lineNr", { fg = "#16FF00", bold = true })
	vim.api.nvim_set_hl(0, "lineNrAbove", { fg = "#AAAAAA", bold = true })
	vim.api.nvim_set_hl(0, "lineNrBelow", { fg = "#AAAAAA", bold = true })

	-- setup current line highlight
	vim.opt.cursorline = true
	-- vim.cmd([[hi CursorLine   guifg=#E3FCBF]])
	-- vim.cmd([[hi CursorColumn guifg=#E3FCBF]])
	--
	-- setup color highlighter
	require("colorizer").setup()
end

return { afterThemeConfig = afterThemeConfig }
