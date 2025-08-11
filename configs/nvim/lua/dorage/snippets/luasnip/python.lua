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
local ls_utils = require("dorage.snippets.luasnip.common")
local ls_auto_import = require("dorage.customs.js-auto-import")
local fp = require("dorage.utils.fp")

local M = {
	-- keywords
	s({ name = "async keyword", trig = "lka" }, { t("async "), i(1) }),
	s({
		name = "await keyowrd",
		trig = "lkw",
	}, {
		t("await "),
		i(1),
	}, {
		callbacks = {
			[-1] = {
				[events.enter] = function()
					vim.schedule(function()
						require("dorage.snippets.utils").restore_cursor(function()
							require("dorage.snippets.utils.typescript").auto_async()
						end)
					end)
				end,
			},
		},
	}),
	-- types
	-- variables
	s({ name = "variable", trig = "lvl" }, fmt([[<> = <>]], { i(1), i(2) }, fmtopt)),
	s({ name = "variable", trig = "lvc" }, fmt([[<> = <>]], { i(1), i(2) }, fmtopt)),
	-- functions
	s(
		{ name = "function", trig = "lf" },
		fmt(
			[[
			def <>(<>) ->> <>:
				<>
	]],
			{ i(1), i(2), i(3, "None"), i(4, "pass") },
			fmtopt
		)
	),
	-- statements
	-- statement: if
	s(
		{ name = "if statement", trig = "lsif" },
		fmt(
			[[
	if <>: <>
	]],
			{
				i(1, "True"),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	s(
		{
			name = "else if statement",
			trig = "lsifi",
		},
		fmt(
			[[
	elif(<>): <>
	]],
			{
				i(1, "True"),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	s(
		{ name = "else statement", trig = "lsife" },
		fmt(
			[[
	else: <>
	]],
			{
				i(1, "pass"),
			},
			fmtopt
		)
	),
	-- statement: switch
	s(
		{ name = "switch statement", trig = "lss" },
		fmt(
			[[
	match(<>):
		<>
	]],
			{
				i(1),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	s(
		{ name = "switch-case statement", trig = "lssc" },
		fmt(
			[[
	case <>:
		<>
	]],
			{
				i(1, "value"),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	s(
		{ name = "switch-default statement", trig = "lssd" },
		fmt(
			[[
	case _:
		<>
	]],
			{ i(1, "pass") },
			fmtopt
		)
	),
	--- statement: while
	s(
		{ name = "while statement", trig = "lsw" },
		fmt(
			[[
	while <>:
		<>
	]],
			{
				i(1, "False"),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	--- statement: for
	s(
		{ name = "for statement", trig = "lsf" },
		fmt(
			[[
	for <> in <>:
		<>
	]],
			{
				i(2),
				i(1),
				i(3, "pass"),
			},
			fmtopt
		)
	),
	-- statement: try
	s(
		{ name = "try-catch statement", trig = "lst" },
		fmt(
			[[
	try:
		<>
	]],
			{ i(1, "pass") },
			fmtopt
		)
	),
	-- default statement
	s(
		{ name = "try-default statement", trig = "lstd" },
		fmt(
			[[
	else: 
		<>
	]],
			{ i(1, "pass") },
			fmtopt
		)
	),
	-- statement: return
	s(
		{ name = "with statement", trig = "lswi" },
		fmt(
			[[
	with <>:
		<>
	]],
			{
				c(1, {
					sn(1, { i(1) }),
					sn(1, { i(1), t(" as "), i(2) }),
				}),
				i(2, "pass"),
			},
			fmtopt
		)
	),
	-- statement: return
	s(
		{ name = "return statement", trig = "lsr" },
		fmt(
			[[
	return <>
	]],
			{
				d(1, function()
					local reg = string.gsub(vim.fn.getreg(0), "[\n\r]", "")
					return sn(nil, { i(1, reg) })
				end),
			},
			fmtopt
		)
	),
	-- statement: import
	s(
		{ name = "import statement", trig = "lsi" },
		fmt(
			[[
	<>;
	]],
			{
				c(1, {
					sn(1, {
						t("from "),
						i(1),
						t(" import "),
						i(2),
					}),
					sn(1, {
						t("import "),
						i(1),
					}),
				}),
			},
			fmtopt
		)
	),
	-- comments
	s(
		{ name = "Multiline comment", trig = "lcm" },
		fmt(
			[[
			"""
			<>
			"""
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "TODO comment", trig = "lct" },
		fmt(
			[[
	# TODO:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "WARN comment", trig = "lcw" },
		fmt(
			[[
	# WARN:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "NOTE comment", trig = "lcn" },
		fmt(
			[[
	# NOTE:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "TEST comment", trig = "lcs" },
		fmt(
			[[
	# TEST:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "FIX comment", trig = "lcf" },
		fmt(
			[[
	# FIX:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "AI comment", trig = "lca" },
		fmt(
			[[
	# AI:
	# <>
	]],
			{
				i(1),
			},
			fmtopt
		)
	),
	s(
		{ name = "comment - GWT", trig = "lcg" },
		fmt(
			[[
	# Given
	# <>

	# When
	# <>

	# Then
	# <>

	]],
			{
				i(1),
				i(2),
				i(3),
			},
			fmtopt
		)
	),
	s(
		{ name = "print", trig = "log" },
		fmt(
			[[
			print(<>)
			]],
			{
				d(1, function()
					local reg = string.gsub(vim.fn.getreg(0), "[\n\r]", "")
					return sn(nil, { i(1, reg) })
				end),
			},
			fmtopt
		)
	),
}

ls.add_snippets("python", M)
