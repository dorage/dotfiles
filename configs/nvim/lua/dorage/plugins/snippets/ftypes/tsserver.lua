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

local cmn = require("dorage.plugins.snippets.ftypes.common")

local es6 = {
	-- javascript types
	s({ name = "string type", trig = "str" }, { t("string") }),
	s({ name = "number type", trig = "num" }, { t("number") }),
	s({ name = "boolean type", trig = "boo" }, { t("boolean") }),
	s({ name = "object type", trig = "obj" }, { t("object") }),
	-- return statement
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
	s({ name = "async ~", trig = "as" }, { t("async "), i(1) }),
	-- await
	s({ name = "await ~", trig = "aw" }, { t("await "), i(1) }),
	-- import
	s(
		{ name = "import statement", trig = "im" },
		fmt(
			[[
	import <> from '<>';
	]],
			{
				c(2, {
					i(1),
					fmt(
						[[
					{ <> }
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
	-- -- for..of statement
	s(
		{ name = "for statement", trig = "for" },
		fmt(
			[[
	for(<>){
		<>
	}
	]],
			{
				c(1, {
					fmt([[const <> of <>]], {
						d(2, cmn.singular, { 1 }),
						i(1, "elements"),
					}, fmtopt),
					fmt([[let <> = <>; <> << <>.length; <>++]], {
						i(2, "i"),
						i(3, "0"),
						rep(1),
						i(1, "arr"),
						rep(1),
					}, fmtopt),
				}),
				i(2),
			},
			fmtopt
		)
	),
	-- forEach highorder function
	postfix(
		{ name = ".forEach", trig = ".hfe" },
		fmt([[<>.forEach((<>)=>>{<>})]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(1, { t("e"), t("e, i"), t("e, i, arr") }),
			i(2),
		}, fmtopt)
	),
	-- map highorder function
	postfix(
		{ name = ".map", trig = ".hma" },
		fmt([[<>.map((<>)=>>{return <>})]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(1, { t("e"), t("e, i"), t("e, i, arr") }),
			i(2),
		}, fmtopt)
	),
	-- filter highorder function
	postfix(
		{ name = ".filter", trig = ".hfi" },
		fmt([[<>.hfi((<>)=>>{return <>})]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(1, { t("e"), t("e, i"), t("e, i, arr") }),
			i(2),
		}, fmtopt)
	),
	-- every highorder function
	postfix(
		{ name = ".every", trig = ".hev" },
		fmt([[<>.hev((<>)=>>{return <>})]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(1, { t("e"), t("e, i"), t("e, i, arr") }),
			i(2),
		}, fmtopt)
	),
	-- some highorder function
	postfix(
		{ name = ".some", trig = ".hso" },
		fmt([[<>.some((<>)=>>{return <>})]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(1, { t("e"), t("e, i"), t("e, i, arr") }),
			i(2),
		}, fmtopt)
	),
	-- reduce highorder function
	postfix(
		{ name = ".reduce", trig = ".hre" },
		fmt([[<>.reduce((<>)=>>{return <>}, <>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			c(3, { t("a, c"), t("a, c, i"), t("a, c, i, arr") }),
			i(2),
			i(1),
		}, fmtopt)
	),
	-- sort
	postfix(
		{ name = ".sort", trig = ".hso" },
		fmt(
			"<>.sort((a, b)=>>{return <>})",
			{ f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}), i(1) },
			fmtopt
		)
	),
	-- JSON
	s(
		{ name = "JSON.stringify", trig = "fjss" },
		fmt(
			[[
	JSON.stringify(<>)
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
	s(
		{ name = "JSON.parse", trig = "fjsp" },
		fmt(
			[[
	JSON.parse(<>)
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
	-- template string
	s(
		{ name = "template string", trig = "$" },
		fmt(
			[[
	${<>}
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- env variable
	s({ name = "env variable", trig = "env" }, { t("process.env."), i(1, "NODE_ENV") }),
}

local typescript = {
	-- extends
	s({ name = "typescript extends", trig = "ext" }, { t(" extends "), i(1) }),
	-- interface
	s(
		{ name = "typescript interface", trig = "int" },
		fmt(
			[[
		interface <><>{
			<>
		}
		]],
			{
				i(1, "Name"),
				c(2, { t(""), sn(1, { t(" extends "), i(1, "Parent") }) }),
				i(2),
			},
			fmtopt
		)
	),
	-- type
	s(
		{ name = "typescript type", trig = "typ" },
		fmt(
			[[
			type <> = <>
			]],
			{ i(1, "Name"), i(2) },
			fmtopt
		)
	),
}

local repeatFn = function(args, parent, user_args)
	return args[1][1]
end

local react = {
	s(
		{ name = "react component", trig = "rec" },
		fmt(
			[[
		import React from "react";

		export interface <>Props{
		}

		const <> = (props: <>Props) =>> {
			return <<>><</>>;
		}

		export default <>;
			]],
			{
				f(repeatFn, { 1 }),
				i(1, "Name"),
				f(repeatFn, { 1 }),
				f(repeatFn, { 1 }),
			},
			fmtopt
		)
	),
}

ls.add_snippets("javascript", es6)
ls.add_snippets("typescript", es6)
ls.add_snippets("typescript", typescript)
ls.add_snippets("javascriptreact", es6)
ls.add_snippets("typescriptreact", es6)
ls.add_snippets("typescriptreact", react)
ls.add_snippets("typescriptreact", typescript)
