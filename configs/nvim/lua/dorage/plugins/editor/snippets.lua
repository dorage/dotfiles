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
				-- history = true, -- 끝난 스니펫으로 되돌아가지 않도록
				update_events = "TextChanged,TextChangedI",
				region_check_events = "CursorMoved,CursorMovedI",
				delete_check_events = "TextChanged,InsertLeave",
				enable_autosnippets = true,
			})


			require("dorage.snippets.luasnip")

			-- expand 혹은 jump
			vim.keymap.set({ "i", "s" }, "<Tab>", function()
				if ls.expandable() then
					ls.expand()
				elseif ls.locally_jumpable(1) then -- 커서가 현재 스니펫 영역 안일 때만 이동
					ls.jump(1)
				else
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
				end
			end, { silent = true })

			-- 스니펫 영역 안에서 그냥 탭을 치고 싶을 때: 현재 스니펫에서 강제로 나감
			vim.keymap.set({ "i", "s" }, "<C-e>", function()
				if ls.in_snippet() then
					ls.unlink_current()
				end
			end, { desc = "LuaSnip: 스니펫 빠져나오기" })
			-- 뒤로가기, 스니펫 밖에서는 들여쓰기 풀기
			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				if ls.locally_jumpable(-1) then
					ls.jump(-1)
				elseif vim.fn.mode() == "i" then
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-d>", true, false, true), "ni", false)
				else
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
				end
			end, { silent = true })
			-- choice 이전
			vim.keymap.set({ "i", "s" }, "<leader>p", function()
				if ls.choice_active() then
					ls.change_choice(-1)
				else
					print("LuaSnip:No choice active")
				end
			end, { desc = "Previous luasnip choice" })
			-- choice 다음
			vim.keymap.set({ "i", "s" }, "<leader>n", function()
				if ls.choice_active() then
					ls.change_choice(1)
				else
					print("LuaSnip:No choice active")
				end
			end, { desc = "Next luasnip choice" })
			-- choice 목록
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
