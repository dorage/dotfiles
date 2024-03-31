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

local markdown = {
	-- heading
	s(
		{ name = "heading", regTrig = true, trig = "h([1-6])" },
		{ f(function(args, snip)
			return string.rep("#", snip.captures[1]) .. " "
		end), i(1) }
	),
	-- warning
	-- bold
	postfix({ name = "font bold", trig = ".fb" }, {
		f(function(_, parent)
			return "**" .. parent.snippet.env.POSTFIX_MATCH .. "**"
		end, {}),
	}),
	s(
		{ name = "font bold", trig = "fb" },
		fmt(
			[[
	**<>**
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- italic
	postfix({ name = "font italic", trig = ".fi" }, {
		f(function(_, parent)
			return "*" .. parent.snippet.env.POSTFIX_MATCH .. "*"
		end, {}),
	}),
	s(
		{ name = "font italic", trig = "fi" },
		fmt(
			[[
	*<>*
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- bold and italic
	postfix({ name = "font bold & italic", trig = ".fbi" }, {
		f(function(_, parent)
			return "***" .. parent.snippet.env.POSTFIX_MATCH .. "***"
		end, {}),
	}),
	s(
		{ name = "font bold & italic", trig = "fbi" },
		fmt(

			[[
	***<>***
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- block quotes
	s(
		{ name = "block quote", trig = "bq" },
		fmt(
			[[
	>> <>
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- code
	s(
		{ name = "code", trig = "cda" },
		fmt(
			[[
	`<>`
	]],
			{ i(1) },
			fmtopt
		)
	),
	s(
		{ name = "fenced code block", trig = "cdm" },
		fmt(
			[[
	``` <>
	<>
	```
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	-- horizontal rule
	s({ name = "horizontal rule", trig = "hr" }, { t("---") }),
	-- links
	postfix(
		{ name = "link postfix", trig = ".ln", match_pattern = "[^ ]+$" },
		fmt(
			[[
	<>[<>](<>)
	]],
			{
				c(1, { t(""), t("!") }),
				i(2),
				f(function(_, parent)
					return parent.snippet.env.POSTFIX_MATCH
				end),
			},
			fmtopt
		)
	),
	s(
		{ name = "link", trig = "ln" },
		fmt(
			[[
	<>[<>](<>)
	]],
			{
				c(1, { t(""), t("!") }),
				i(0),
				i(2),
			},
			fmtopt
		)
	),
	-- table
}

ls.add_snippets("markdown", markdown)
ls.add_snippets("telekasten", markdown)
