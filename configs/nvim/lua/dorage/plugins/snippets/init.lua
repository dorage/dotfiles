return {
	{
		"l3mon4d3/luasnip",
		lazy = true,
		build = "make install_jsregexp",
		config = function()
			local ls = require("luasnip")
			local s = ls.snippet
			local sn = ls.snippet_node
			local isn = ls.indent_snippet_node
			local t = ls.text_node
			local i = ls.insert_node
			local f = ls.function_node
			local c = ls.choice_node
			local d = ls.dynamic_node
			local r = ls.restore_node
			local events = require("luasnip.util.events")
			local ai = require("luasnip.nodes.absolute_indexer")
			local extras = require("luasnip.extras")
			local l = extras.lambda
			local rep = extras.rep
			local p = extras.partial
			local m = extras.match
			local n = extras.nonempty
			local dl = extras.dynamic_lambda
			local fmt = require("luasnip.extras.fmt").fmt
			local fmta = require("luasnip.extras.fmt").fmta
			local conds = require("luasnip.extras.expand_conditions")
			local postfix = require("luasnip.extras.postfix").postfix
			local types = require("luasnip.util.types")
			local parse = require("luasnip.util.parser").parse_snippet
			local ms = ls.multi_snippet
			local k = require("luasnip.nodes.key_indexer").new_key

			ls.setup({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				enable_autosnippets = true,
			})

			ls.add_snippets("lua", {
				s("luasnip-import", {
					t({
						'local ls = require("luasnip")',
						"local s = ls.snippet",
						"local sn = ls.snippet_node",
						"local isn = ls.indent_snippet_node",
						"local t = ls.text_node",
						"local i = ls.insert_node",
						"local f = ls.function_node",
						"local c = ls.choice_node",
						"local d = ls.dynamic_node",
						"local r = ls.restore_node",
						'local events = require("luasnip.util.events")',
						'local ai = require("luasnip.nodes.absolute_indexer")',
						'local extras = require("luasnip.extras")',
						"local l = extras.lambda",
						"local rep = extras.rep",
						"local p = extras.partial",
						"local m = extras.match",
						"local n = extras.nonempty",
						"local dl = extras.dynamic_lambda",
						'local fmt = require("luasnip.extras.fmt").fmt',
						'local fmta = require("luasnip.extras.fmt").fmta',
						'local conds = require("luasnip.extras.expand_conditions")',
						'local postfix = require("luasnip.extras.postfix").postfix',
						'local types = require("luasnip.util.types")',
						'local parse = require("luasnip.util.parser").parse_snippet',
						"local ms = ls.multi_snippet",
						'local k = require("luasnip.nodes.key_indexer").new_key',
						'local fmtopt = { delimiters = "<>" }',
					}),
				}),
			})

			require("dorage.plugins.snippets.ftypes.all")
			require("dorage.plugins.snippets.ftypes.tsserver")
			require("dorage.plugins.snippets.ftypes.markdown")

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
