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
local fmtopt = { delimiters = "<>" }

return {
	singular = function(input)
		local plural_word = input[1][1]
		local last_word = string.match(plural_word, "[_%w]*$")

		-- initialize with fallback
		local singular_word = "item"

		if string.match(last_word, ".s$") then
			-- assume the given input is plural if it ends in s. This isn't always
			-- perfect, but it's pretty good
			singular_word = string.gsub(last_word, "s$", "", 1)
		elseif string.match(last_word, "^_?%w.+") then
			-- include an underscore in the match so that inputs like '_name' will
			-- become '_n' and not just '_'
			singular_word = string.match(last_word, "^_?.")
		end

		return s("{}", i(1, singular_word))
	end,
}
