local afterThemeConfig = function()
	-- setup transparent bg
	vim.call("background#enable")

	-- setup line number highlighting
	vim.api.nvim_set_hl(0, "lineNr", { fg = "#16FF00", bold = true })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#16FF00", bold = true })
	vim.api.nvim_set_hl(0, "lineNrAbove", { fg = "#AAAAAA", bold = false })
	vim.api.nvim_set_hl(0, "lineNrBelow", { fg = "#AAAAAA", bold = false })

	-- clear float highlight
	vim.api.nvim_set_hl(0, "BufferOffset", { guibg = nil })
	vim.api.nvim_set_hl(0, "BufferTabpageFill", { guibg = nil })
	vim.api.nvim_set_hl(0, "BufferTabpages", { guibg = nil })
	vim.api.nvim_set_hl(0, "BufferTabpagesSep", { guibg = nil })
	vim.api.nvim_set_hl(0, "BufferScrollArrowBufferTabpageFill", { guibg = nil })

	-- setup current line highlight
	vim.opt.cursorline = true
	--
	-- setup color highlighter
	require("colorizer").setup()
	require("dorage.themes.lualine")
end

return { afterThemeConfig = afterThemeConfig }
