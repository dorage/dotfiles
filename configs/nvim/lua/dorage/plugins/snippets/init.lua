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

			ls.add_snippets("all", {
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
					}),
				}),
			})

			require("dorage.plugins.snippets.all")
			require("dorage.plugins.snippets.tsserver")

			vim.keymap.set({ "i", "s" }, "<leader>;", "<Plug>luasnip-next-choice", {})
			vim.keymap.set({ "i", "s" }, "<leader>,", "<Plug>luasnip-prev-choice", {})
			vim.keymap.set({ "i", "s" }, "<C-k>", function()
				if ls.expand_or_jumpable() then
					ls.expand_or_jump()
				end
			end, { silent = true })
			vim.keymap.set("n", "<leader>as", function()
				require("luasnip.loaders").edit_snippet_files()
			end, { desc = "Snippet search" })
		end,
	},
}
