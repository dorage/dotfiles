local theme_config = function(theme_name)
	local theme = require("dorage.themes." .. theme_name)

	return {
		theme[1],
		dependencies = {
			"tribela/vim-transparent", -- remove background color on vim
			"nvim-lualine/lualine.nvim",
			"norcalli/nvim-colorizer.lua", -- high-performance color highlighter
		},
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			theme.config()
			require("dorage.themes.global").afterThemeConfig()
		end,
	}
end

return {
	{
		"tribela/vim-transparent", -- remove background color on vim
	},
	{
		"norcalli/nvim-colorizer.lua", -- high-performance color highlighter
	},
	-- color scheme
	theme_config("moonfly"),
}
