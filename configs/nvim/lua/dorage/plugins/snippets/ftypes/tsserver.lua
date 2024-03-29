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

local es6 = {
	s(
		{ name = "return ~", trig = "re" },
		fmt(
			[[
	return <>;
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
	-- async
	s({ name = "async ~", trig = "as" }, { t("async") }),
	-- await
	s({ name = "await ~", trig = "aw" }, { t("await") }),
	-- import
	s(
		{ name = "import statement", trig = "im" },
		fmt(
			[[
	import <> from '<>';
	]],
			{
				c(2, {
					fmt(
						[[
					{<>}
					]],
						{ i(1) },
						fmtopt
					),
				}),
				i(1),
			},
			fmtopt
		)
	),
	-- export
	s(
		{ name = "export statement", trig = "ex" },
		fmt(
			[[
	<> <>
	]],
			{ c(1, { t("export"), t("export default") }), i(2) },
			fmtopt
		)
	),
	-- variable
	s(
		{ name = "variable statement", trig = "var" },
		fmt(
			[[
	<> <> = <>
	]],
			{
				c(1, {
					t("const"),
					t("let"),
					t("var"),
				}),
				i(2, "name"),
				i(3, ""),
			},
			fmtopt
		)
	),
	-- arrow function
	s(
		{
			name = "arrow function",
			trig = "fna",
		},
		fmt(
			[[
	(<>) =>> <>
	]],
			{
				i(1),
				c(2, {
					fmt(
						[[
				{
					<>
				}
				]],
						{ i(1) },
						fmtopt
					),
					i(1),
				}),
			},
			fmtopt
		)
	),
	-- normal function
	s(
		{
			name = "function statement",
			trig = "fns",
		},
		fmt(
			[[
	function <> (<>){
		<>
	}
	]],
			{ i(1), i(2), i(3) },
			fmtopt
		)
	),
	-- try-catch statement
	s(
		{ name = "try-catch statement", trig = "try" },
		fmt(
			[[
	try {
		<>
	} catch(err) {
		<>
	}
	]],
			{ i(1), c(2, {
				sn(1, { t("console.error(err);"), i(1) }),
				i(1),
			}) },
			fmtopt
		)
	),
	-- default statement
	s(
		{ name = "try-default statement", trig = "tryd" },
		fmt(
			[[
	default {
		<>
	}
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- if statement
	s(
		{ name = "if statement", trig = "if" },
		fmt(
			[[
	if (<>) {
		<>
	}
	]],
			{ i(1, "true"), i(2) },
			fmtopt
		)
	),
	-- else if statement
	s(
		{
			name = "else if statement",
			trig = "ifi",
		},
		fmt(
			[[
	else if(<>) {
		<>
	}
	]],
			{ i(1, "true"), i(2) },
			fmtopt
		)
	),
	-- else statement
	s(
		{ name = "else statement", trig = "ife" },
		fmt(
			[[
	else {
		<>
	}
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- switch statement
	s(
		{ name = "switch statement", trig = "sw" },
		fmt(
			[[
	switch(<>) {
	<>
	}
	]],
			{
				i(1, "value"),
				sn(0, {
					i(1),
				}),
			},
			fmtopt
		)
	),
	-- case statement
	s(
		{ name = "switch-case statement", trig = "swc" },
		fmt(
			[[
	case <>:
		<>
		<>
	]],
			{
				i(1, "value"),
				i(2),
				c(3, {
					t("break;"),
					t(""),
				}),
			},
			fmtopt
		)
	),
	-- default statement
	s(
		{ name = "switch-default statement", trig = "swd" },
		fmt(
			[[
	default:
		<>
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- break statement
	s({ name = "break statement", trig = "br" }, { t("break;") }),
	-- continue statement
	s({ name = "continue statement", trig = "cn" }, { t("continue;") }),
	-- -- for..idx statement
	-- postfix(
	-- 	".for",
	-- 	fmt(
	-- 		[[
	-- for(let <> = 1; <>;	<>){
	-- 	<>
	-- }
	-- ]],
	-- 		{
	-- 			i(1, "i"),
	-- 		},
	-- 		fmtopt
	-- 	)
	-- ),
	-- s(
	-- 	{ name = "for statement", trig = "for" },
	-- 	fmt(
	-- 		[[
	-- for(<>;<>;<>){
	-- 	<>
	-- }
	-- ]],
	-- 		{ i(2), i(1), i(3) },
	-- 		fmtopt
	-- 	)
	-- ),
	-- -- for..of statement
	s(
		{ name = "for statement", trig = "for" },
		fmt(
			[[
	for(const <> of <>){
		<>
	}
	]],
			{ i(2), i(1), i(3) },
			fmtopt
		)
	),
	-- forEach ff
	postfix(".forEach", fmt([[.forEach((<>)=>>{<>})]], { c(1, { t("e"), t("e, i"), t("e, i, arr") }), i(2) }, fmtopt)),
	-- map ff
	postfix(".map", fmt([[.map((<>)=>>{return <>})]], { c(1, { t("e"), t("e, i"), t("e, i, arr") }), i(2) }, fmtopt)),
	-- filter ff
	postfix(
		".filter",
		fmt([[.filter((<>)=>>{return <>})]], { c(1, { t("e"), t("e, i"), t("e, i, arr") }), i(2) }, fmtopt)
	),
	-- every ff
	postfix(
		".every",
		fmt([[.every((<>)=>>{return <>})]], { c(1, { t("e"), t("e, i"), t("e, i, arr") }), i(2) }, fmtopt)
	),
	-- some ff
	postfix(".some", fmt([[.some((<>)=>>{return <>})]], { c(1, { t("e"), t("e, i"), t("e, i, arr") }), i(2) }, fmtopt)),
	-- reduce ff
	postfix(
		".reduce",
		fmt(
			[[.reduce((<>)=>>{return <>}, <>)]],
			{ c(3, { t("a, c"), t("a, c, i"), t("a, c, i, arr") }), i(2), i(1) },
			fmtopt
		)
	),
	-- sort
	postfix(".sort", fmt(".sort((a, b)=>>{return <>})", { i(1) }, fmtopt)),
	-- console.log
	s(
		{ name = "console.log", trig = "log" },
		fmt(
			[[
			console.log(<>)
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
	-- -- console.error
	s(
		{ name = "console.error", trig = "err" },
		fmt(
			[[
			console.error(<>)
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
	-- console.debug
	s(
		{ name = "console.debug", trig = "dbg" },
		fmt(
			[[
			console.debug(<>)
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

local react = {
	s({ name = "react component", trig = "rec" }, {
		fmt(
			[[
		import React from "react";

		export interface <a>Props{
			<a>
		}

		const <a> = (props: <a>Props) =>> {
			return <c>;
		}

		export default <a>;
			]],
			{ a = i(1, "Name"), c = i(2, "<></>") },
			fmtopt
		),
	}),
}

ls.add_snippets("javascript", es6)
ls.add_snippets("typescript", es6)
ls.add_snippets("javascriptreact", es6)
ls.add_snippets("typescriptreact", es6)
ls.add_snippets("typescriptreact", react)
