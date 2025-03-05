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

local language = {
	-- keywords
	s({ name = "async keyword", trig = "lka" }, { t("async "), i(1) }),
	s({ name = "await keyowrd", trig = "lkw" }, { t("await "), i(1) }),
	s({ name = "break keyowrd", trig = "lkb" }, { t("break;"), i(1) }),
	s({ name = "continue keyowrd", trig = "lkc" }, { t("continue;"), i(1) }),
	-- types
	s({ name = "string type", trig = "lts" }, { t("string") }),
	s({ name = "number type", trig = "ltn" }, { t("number") }),
	s({ name = "boolean type", trig = "ltb" }, { t("boolean") }),
	s({ name = "null type", trig = "ltn" }, { t("null") }),
	s({ name = "undefined type", trig = "ltu" }, { t("undefined") }),
	-- variables
	s(
		{ name = "let variable", trig = "lvl" },
		fmt(
			[[<> = <>]],
			{ c(1, {
				sn(1, { t("let "), r(1, "var") }),
				sn(1, { t("const "), r(1, "var") }),
			}), i(2) },
			fmtopt
		)
	),
	s(
		{ name = "constant variable", trig = "lvc" },
		fmt(
			[[<> = <>]],
			{ c(1, {
				sn(1, { t("const "), r(1, "var") }),
				sn(1, { t("let "), r(1, "var") }),
			}), i(2) },
			fmtopt
		)
	),
	-- functions
	s(
		{ name = "js function", trig = "lf" },
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
	s({ name = "arrow function", trig = "lfa" }, common.arrow_function(i(1))),
	-- statements
	-- statement: if
	s(
		{ name = "if statement", trig = "lsif" },
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
						{ r(1, "") },
						fmtopt
					),
					r(1, ""),
				}),
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
						{ r(1, "") },
						fmtopt
					),
					r(1, ""),
				}),
			},
			fmtopt
		)
	),
	s(
		{ name = "else statement", trig = "lsife" },
		fmt(
			[[
	else <>	
	]],
			{
				c(1, {
					fmt(
						[[
				{
					<>
				}
				]],
						{ r(1, "") },
						fmtopt
					),
					r(1, ""),
				}),
			},
			fmtopt
		)
	),
	-- statement: switch
	s(
		{ name = "switch statement", trig = "lss" },
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
	s(
		{ name = "switch-case statement", trig = "lssc" },
		fmt(
			[[
	case <>:
		<>
	]],
			{
				i(1, "value"),
				c(2, {
					sn(1, {
						r(1, ""),
						t("break;"),
					}),
					sn(1, { r(1, "") }),
				}),
			},
			fmtopt
		)
	),
	s(
		{ name = "switch-default statement", trig = "lssd" },
		fmt(
			[[
	default:
		<>
	]],
			{ i(1) },
			fmtopt
		)
	),
	--- statement: for
	s(
		{ name = "for statement", trig = "lsf" },
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
	s(
		{ name = "for..of statement", trig = "lsfo" },
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
	s(
		{ name = "for..in statement", trig = "lsfi" },
		fmt(
			[[
	for(const <> in <>){
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
	-- statement: try
	s(
		{ name = "try-catch statement", trig = "lst" },
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
		{ name = "try-default statement", trig = "lstd" },
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
	-- statement: export
	s(
		{ name = "export statement", trig = "lse" },
		fmt(
			[[
	<> <>
	]],
			{ c(1, { t("export"), t("export default") }), i(2) },
			fmtopt
		)
	),
	-- statement: import
	s(
		{ name = "import statement", trig = "lsi" },
		fmt(
			[[
	import <>;
	]],
			{
				c(1, {
					sn(1, {
						-- destructive
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
						t(" from '"),
						r(1, "module"),
						t("'"),
					}),
					sn(1, { t("'"), r(1, "module"), t("'") }),
				}),
			},
			fmtopt
		)
	),
	-- comments
	s({ name = "js TODO comment", trig = "lct" }, { t("// TODO: "), i(1) }),
	s({ name = "js WARN comment", trig = "lcw" }, { t("// WARN: "), i(1) }),
	s({ name = "js NOTE comment", trig = "lcn" }, { t("// NOTE: "), i(1) }),
	s({ name = "js TEST comment", trig = "lcs" }, { t("// TEST: "), i(1) }),
	s({ name = "js FIX comment", trig = "lcf" }, { t("// FIX: "), i(1) }),
	s({ name = "js AI comment", trig = "lca" }, { t("// LLM: "), i(1) }),
	s(
		{ name = "js Separator comment", trig = "lcf" },
		fmt(
			[[
// --------------------------------------------------------------------------------------------------

<>
	]],
			{ i(1) },
			fmtopt
		)
	),
	s(
		{ name = "js Header comment", trig = "lch" },
		fmt(
			[[
// --------------------------------------------------------------------------------------------------
// <>
// --------------------------------------------------------------------------------------------------

<>
		]],
			{
				i(1),
				i(2),
			},
			fmtopt
		)
	),
	-- array
	s({ name = "Empty Array", trig = "lae" }, fmt([[Array(<>).fill(null))]], { i(1) }, fmtopt)),
	-- array: highorder
	postfix(
		{ name = ".forEach~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".for" },
		fmt([[<>.forEach(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				1,
				common.arrow_function(c(1, {
					t("el"),
					t("el, idx"),
					t("el, idx, arr"),
				}))
			),
		}, fmtopt)
	),
	postfix(
		{ name = ".map~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".map" },
		fmt([[<>.map(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				1,
				common.arrow_function(c(1, {
					t("el"),
					t("el, idx"),
					t("el, idx, arr"),
				}))
			),
		}, fmtopt)
	),
	postfix(
		{ name = ".filter~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".fil" },
		fmt([[<>.filter(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				1,
				common.arrow_function(c(1, {
					t("el"),
					t("el, idx"),
					t("el, idx, arr"),
				}))
			),
		}, fmtopt)
	),
	postfix(
		{ name = ".every~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".eve" },
		fmt([[<>.every(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				1,
				common.arrow_function(c(1, {
					t("el"),
					t("el, idx"),
					t("el, idx, arr"),
				}))
			),
		}, fmtopt)
	),
	postfix(
		{ name = ".some~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".som" },
		fmt([[<>.some(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				1,
				common.arrow_function(c(1, {
					t("el"),
					t("el, idx"),
					t("el, idx, arr"),
				}))
			),
		}, fmtopt)
	),
	postfix(
		{ name = ".reduce~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".red" },
		fmt([[<>.reduce(<>, <>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(
				2,
				common.arrow_function(c(1, {
					t("acc, el"),
					t("acc, el, idx"),
					t("acc, el, idx, arr"),
				}))
			),
			i(1, "{}"),
		}, fmtopt)
	),
	postfix(
		{ name = ".sort~", match_pattern = "[%w%.%_%-%\"%'%`%[%]]+$", trig = ".sor" },
		fmt([[<>.sort(<>)]], {
			f(function(_, parent)
				return parent.snippet.env.POSTFIX_MATCH
			end, {}),
			sn(1, common.arrow_function(t("a, b"))),
		}, fmtopt)
	),
	-- JSON
	s(
		{ name = "JSON.stringify", trig = "lfjs" },
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
		{ name = "JSON.parse", trig = "lfjp" },
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

ls.add_snippets("javascript", language)
ls.add_snippets("javascriptreact", language)

ls.add_snippets("typescript", language)
ls.add_snippets("typescript", typescript)
ls.add_snippets("typescript", jest)

ls.add_snippets("typescriptreact", language)
ls.add_snippets("typescriptreact", typescript)
ls.add_snippets("typescriptreact", jest)
