return {
	{
		"l3mon4d3/luasnip",
		lazy = true,
		build = "make install_jsregexp",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"dorage/ts-manual-import.nvim",
		},
		config = function()
			local ls = require("luasnip")
			ls.setup({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				enable_autosnippets = true,
			})

			print("load luasnip")
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "~/.config/nvim/lua/dorage/snippets/vscode" },
			})

			require("dorage.snippets.luasnip")

			vim.keymap.set({ "i", "s" }, "<leader>p", function()
				if ls.choice_active() then
					ls.change_choice(-1)
				else
					print("No choice active")
				end
			end, { desc = "Previous luasnip choice" })
			vim.keymap.set({ "i", "s" }, "<leader>n", function()
				if ls.choice_active() then
					ls.change_choice(1)
				else
					print("No choice active")
				end
			end, { desc = "Next luasnip choice" })
			vim.keymap.set(
				{ "n", "i", "s" },
				"<leader>fc",
				function()
					if ls.choice_active() then
						require("luasnip.extras.select_choice")()
					else
						print("No choice active")
					end
				end,
				-- "<cmd>lua require('luasnip.extras.select_choice')()<cr>",
				{ desc = "luasnip choice" }
			)
		end,
	},
}
