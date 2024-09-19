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

local cmn = require("dorage.snippets.luasnip.common")

local common = {
	arrow_function = function(arg, body)
		if body == nil then
			body = c(2, {
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
			})
		end

		return fmt([[(<>) =>> <>]], {
			arg,
			body,
		}, fmtopt)
	end,
}

local es6 = {
	-- keywords
	s({ name = "js async keyword", trig = "jka" }, { t("async "), i(1) }),
	s({ name = "js await keyowrd", trig = "jkw" }, { t("await "), i(1) }),
	-- comments
	s({ name = "js TODO comment", trig = "jct" }, { t("// TODO:"), i(1) }),
	s({ name = "js WARN comment", trig = "jcw" }, { t("// WARN:"), i(1) }),
	s({ name = "js NOTE comment", trig = "jcn" }, { t("// NOTE:"), i(1) }),
	s({ name = "js TEST comment", trig = "jcs" }, { t("// TEST:"), i(1) }),
	s({ name = "js FIX comment", trig = "jcf" }, { t("// FIX:"), i(1) }),
	-- types
	s({ name = "js string type", trig = "jts" }, { t("string") }),
	s({ name = "js number type", trig = "jtn" }, { t("number") }),
	s({ name = "js boolean type", trig = "jtb" }, { t("boolean") }),
	s({ name = "js object type", trig = "jto" }, { t("object") }),
	s({ name = "js null type", trig = "jtn" }, { t("object") }),
	s({ name = "js undefined type", trig = "jtu" }, { t("object") }),
	-- variables
	s({ name = "js variable declaration", trig = "jvl" }, fmt([[let <> = <>]], { i(1, "var"), i(2) }, fmtopt)),
	s({ name = "js constant declaration", trig = "jvc" }, fmt([[const <> = <>]], { i(1, "constant"), i(2) }, fmtopt)),
	-- expressions (function)
	s(
		{ name = "js function expression", trig = "jef" },
		fmt(
			[[
			function (<>) {
				<>
			}
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "js async function expression", trig = "jefa" },
		fmt(
			[[
			async function (<>) {
				<>
			}
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "js arrow function expression", trig = "jea" },
		fmt(
			[[
			(<>) =>> {
				<>
			}
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "js async arrow function expression", trig = "jeaa" },
		fmt(
			[[
			async (<>) =>> {
				<>
			}
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	-- statements (return)
	s(
		{ name = "js return statement", trig = "jsr" },
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
	-- statements (import)
	s(
		{ name = "js import statement", trig = "jsi" },
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
				i(1, "module"),
			},
			fmtopt
		)
	),
	s(
		{ name = "js import only statement", trig = "jsio" },
		fmt(
			[[
	import '<>';
	]],
			{
				i(1, "module"),
			},
			fmtopt
		)
	),
	-- statements (export)
	s(
		{ name = "export statement", trig = "jse" },
		fmt(
			[[
	<> <>
	]],
			{ c(1, { t("export"), t("export default") }), i(2) },
			fmtopt
		)
	),
	-- arrow function
	s({
		name = "arrow function",
		trig = "fna",
	}, common.arrow_function(i(1))),
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
	if (<>) <>
	]],
			{
				i(1, "true"),
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
	-- else if statement
	s(
		{
			name = "else if statement",
			trig = "ifi",
		},
		fmt(
			[[
	else if(<>) <>
	]],
			{
				i(1, "true"),
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
	-- else statement
	s(
		{ name = "else statement", trig = "ife" },
		fmt(
			[[
	else <>	
	]],
			{ c(1, {
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
			}) },
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
	-- for statement
	s(
		{ name = "for statement", trig = "fr" },
		fmt(
			[[
	for(let <> = <>; <> << <>.length; <>++){
		const <> = <>[<>];
		<>
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
	-- arrow function
	s({
		name = "arrow function",
		trig = "fna",
	}, common.arrow_function(i(1))),
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
	if (<>) <>
	]],
			{
				i(1, "true"),
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
	-- else if statement
	s(
		{
			name = "else if statement",
			trig = "ifi",
		},
		fmt(
			[[
	else if(<>) <>
	]],
			{
				i(1, "true"),
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
	-- else statement
	s(
		{ name = "else statement", trig = "ife" },
		fmt(
			[[
	else <>	
	]],
			{ c(1, {
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
			}) },
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
	-- for statement
	s(
		{ name = "for statement", trig = "fr" },
		fmt(
			[[
	for(let <> = <>; <> << <>.length; <>++){
		const <> = <>[<>];
		<>
	}
	]],
			{
				i(2, "i"),
				i(3, "0"),
				rep(2),
				i(1, "elements"),
				rep(2),
				d(4, cmn.singular, { 1 }),
				rep(1),
				rep(2),
				i(5),
			},
			fmtopt
		)
	),
	-- -- for..of statement
	s(
		{ name = "for..of statement", trig = "fro" },
		fmt(
			[[
	for(const <> of <>){
		<>
	}
	]],
			{
				d(2, cmn.singular, { 1 }),
				i(1, "elements"),
				i(3),
			},
			fmtopt
		)
	),
	-- forEach highorder function
	postfix(
		{ name = ".forEach", trig = ".hfe" },
		fmt([[<>.forEach(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(1, { t("e"), t("e, idx"), t("e, idx, arr") })),
		}, fmtopt)
	),
	-- map highorder function
	postfix(
		{ name = ".map", trig = ".hmp" },
		fmt([[<>.map(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(1, { t("e"), t("e, idx"), t("e, idx, arr") })),
		}, fmtopt)
	),
	-- filter highorder function
	postfix(
		{ name = ".filter", trig = ".hfl" },
		fmt([[<>.hfi(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(1, { t("e"), t("e, idx"), t("e, idx, arr") })),
		}, fmtopt)
	),
	-- every highorder function
	postfix(
		{ name = ".every", trig = ".hev" },
		fmt([[<>.hev(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(1, { t("e"), t("e, idx"), t("e, idx, arr") })),
		}, fmtopt)
	),
	-- some highorder function
	postfix(
		{ name = ".some", trig = ".hsm" },
		fmt([[<>.some(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(1, { t("e"), t("e, idx"), t("e, idx, arr") })),
		}, fmtopt)
	),
	-- reduce highorder function
	postfix(
		{ name = ".reduce", trig = ".hrd" },
		fmt([[<>.reduce(<>, <>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			common.arrow_function(c(2, { t("a, c"), t("a, c, i"), t("a, c, i, arr") })),
			i(1),
		}, fmtopt)
	),
	-- sort
	postfix(
		{ name = ".sort", trig = ".hsrt" },
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
		{ name = "JSON.stringify", trig = "jfjs" },
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
		{ name = "JSON.parse", trig = "jfjp" },
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
	s(
		{ name = "console.log object", trig = "logo" },
		fmt(
			[[
			console.log(JSON.stringify(<>, undefined, 2)))
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
	-- interface
	s(
		{ name = "typescript interface definition", trig = "tsdi" },
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
		{ name = "typescript type definition", trig = "tsdt" },
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

-- jest
local jest = {
	s(
		{ name = "jest describe", trig = "jtd" },
		fmt(
			[[
			describe("<>", () =>> {
				<>
			})
			]],
			{ i(1, "description"), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "jest test", trig = "jtt" },
		fmt(
			[[
			test("<>", async () =>> {
				<>
			})
			]],
			{ i(1, "description"), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "jest expect", trig = "jte" },
		fmt(
			[[
			expect(<>)<>
			]],
			{ i(1, "result"), i(2) },
			fmtopt
		)
	),
}

ls.add_snippets("javascript", es6)
ls.add_snippets("javascriptreact", es6)

ls.add_snippets("typescript", es6)
ls.add_snippets("typescript", typescript)
ls.add_snippets("typescript", jest)

ls.add_snippets("typescriptreact", es6)
ls.add_snippets("typescriptreact", typescript)
ls.add_snippets("typescriptreact", jest)
