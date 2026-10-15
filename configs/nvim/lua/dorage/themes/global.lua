local afterThemeConfig = function()
	-- setup transparent bg
	vim.call("background#enable")

	-- setup line number highlighting
	vim.api.nvim_set_hl(0, "lineNr", { fg = "#4BFF36", bold = true })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#4BFF36", bold = true })
	vim.api.nvim_set_hl(0, "lineNrAbove", { fg = "#AAAAAA", bold = false })
	vim.api.nvim_set_hl(0, "lineNrBelow", { fg = "#AAAAAA", bold = false })

	-- border color
	-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = nil })
	-- vim.api.nvim_set_hl(0, "FloatBorder", { link = "#74FAFC" })

	-- setup current line highlight
	vim.opt.cursorline = true

	-- setup color highlighter
	require("colorizer").setup()
	require("dorage.themes.lualine")
end

return { afterThemeConfig = afterThemeConfig }
