return {
	{
		"L3MON4D3/LuaSnip",
		lazy = true,
		build = "make install_jsregexp",
		version = "v2.*",
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

			print("LuaSnip:loaded!")
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "~/.config/nvim/lua/dorage/snippets/vscode" },
			})

			require("dorage.snippets.luasnip")

			-- NOTE: 어떻게 jump/expand할것인가?
			-- 1. in snippet, if expandable, then expand
			-- 2. in snippet, if not expandable and jumpable then, jump
			-- 3. not in snippet, if expandable, then expand
			-- 4. not in snippet, if not expandable, then add <Tab> char
			vim.keymap.set({ "i", "s" }, "<Tab>", function()
				if ls.expandable() then
					print("expandable")
					ls.expand()
					return
				end

				if ls.in_snippet() then
					if ls.expandable() then
						print("expandable in snippet")
						ls.expand()
					else
						print("jumpable in snippet")
						ls.jump(1)
					end
					return
				end
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
			end, { silent = true })
			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				if ls.in_snippet() then
					if ls.jumpable() then
						print("jumpable in snippet")
						ls.jump(-1)
					end
				end
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
			end, { silent = true })
			vim.keymap.set({ "i", "s" }, "<leader>p", function()
				if ls.choice_active() then
					ls.change_choice(-1)
				else
					print("LuaSnip:No choice active")
				end
			end, { desc = "Previous luasnip choice" })
			vim.keymap.set({ "i", "s" }, "<leader>n", function()
				if ls.choice_active() then
					ls.change_choice(1)
				else
					print("LuaSnip:No choice active")
				end
			end, { desc = "Next luasnip choice" })
			vim.keymap.set(
				{ "n", "i", "s" },
				"<leader>fc",
				function()
					if ls.choice_active() then
						require("luasnip.extras.select_choice")()
					else
						print("LuaSnip:No choice active")
					end
				end,
				-- "<cmd>lua require('luasnip.extras.select_choice')()<cr>",
				{ desc = "luasnip choice" }
			)
		end,
	},
}
