local header = {
	"██████╗  ██████╗ ██████╗  █████╗  ██████╗ ███████╗",
	"██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝ ██╔════╝",
	"██║  ██║██║   ██║██████╔╝███████║██║  ███╗█████╗  ",
	"██║  ██║██║   ██║██╔══██╗██╔══██║██║   ██║██╔══╝  ",
	"██████╔╝╚██████╔╝██║  ██║██║  ██║╚██████╔╝███████╗",
	"╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝",
	"                                                  ",
	"",
}

return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		local db = require("dashboard")

		db.setup({
			theme = "hyper",
			config = {
				header = header,
				shortcut = {
					{
						desc = "💾 Session",
						group = "@property",
						action = "lua require('persistence').load()",
						key = "o",
					},
					{ desc = "💫 Update", group = "@property", action = "Lazy update", key = "u" },
					{
						desc = "📑 Files",
						icon_hl = "@variable",
						group = "Label",
						action = "Telescope find_files",
						key = "f",
					},
				},
				project = {
					enable = false,
				},
				mru = { limit = 5 },
				footer = {},
			},
		})

		vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#e1d800" })

		vim.keymap.set("n", "<leader>ad", "<Cmd>Dashboard<CR>")
	end,
}
