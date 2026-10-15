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

---커서가 def 함수 매개변수 괄호 안에 있는지 확인 (lambda 는 타입 표기 불가라 제외)
---@return boolean
local function in_parameters()
	local ok, parser = pcall(vim.treesitter.get_parser, 0, "python")
	if not ok or parser == nil then
		return false
	end
	parser:parse()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local node = vim.treesitter.get_node({ pos = { row - 1, math.max(col - 1, 0) } })
	while node ~= nil do
		local type = node:type()
		if type == "parameters" then
			return true
		end
		if type == "block" or type == "function_definition" then
			return false
		end
		node = node:parent()
	end
	return false
end

local not_in_parameters = function()
	return not in_parameters()
end

---함수 매개변수: name: type, choice 로 name: type = default
local parameter = function()
	return c(1, {
		sn(nil, { r(1, "name", i(1)), t(": "), r(2, "type", i(1)) }),
		sn(nil, { r(1, "name"), t(": "), r(2, "type"), t(" = "), i(3) }),
	})
end

local M = {
	-- keywords
	s({ name = "async keyword", trig = "lka" }, { t("async "), i(1) }),
	s({
		name = "await keyowrd",
		trig = "lkw",
	}, {
		t("await "),
		i(1),
	}, {}),
	-- types
	-- variables
	s({ name = "parameter", trig = "lv" }, { parameter() }, { condition = in_parameters }),
	s({ name = "parameter", trig = "lvl" }, { parameter() }, { condition = in_parameters }),
	s({ name = "variable", trig = "lv" }, fmt([[<> = <>]], { i(1), i(2) }, fmtopt), { condition = not_in_parameters }),
	s({ name = "variable", trig = "lvl" }, fmt([[<> = <>]], { i(1), i(2) }, fmtopt), { condition = not_in_parameters }),
	s({ name = "constant variable", trig = "lvc" }, fmt([[<>: Final = <>]], { i(1), i(2) }, fmtopt)),
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
	-- function: decorator, choice 로 인자를 받는 decorator
	s(
		{ name = "decorator function", trig = "lfd" },
		c(1, {
			sn(
				nil,
				fmt(
					[[
					def <>(func):
						@functools.wraps(func)
						def wrapper(*args, **kwargs):
							return func(*args, **kwargs)
						return wrapper
					]],
					{ r(1, "name", i(1)) },
					fmtopt
				)
			),
			sn(
				nil,
				fmt(
					[[
					def <>(<>):
						def decorator(func):
							@functools.wraps(func)
							def wrapper(*args, **kwargs):
								return func(*args, **kwargs)
							return wrapper
						return decorator
					]],
					{ r(1, "name"), i(2) },
					fmtopt
				)
			),
		})
	),
	-- class
	s(
		{ name = "class", trig = "lo" },
		fmt(
			[[
			class <><>:
				<>
			]],
			{
				i(1),
				c(2, {
					t(""),
					sn(nil, { t("("), i(1), t(")") }),
				}),
				i(3, "pass"),
			},
			fmtopt
		)
	),
	-- class: constructor
	s(
		{ name = "constructor", trig = "loc" },
		fmt(
			[[
			def __init__(self<>):
				<>
			]],
			{ i(1), i(2, "pass") },
			fmtopt
		)
	),
	-- statements
	-- statement: if
	s(
		{ name = "if statement", trig = "lsif" },
		fmt(
			[[
	if <>:
		<>
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
	elif <>:
		<>
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
	else:
		<>
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
	match <>:
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
	except <> as e:
		<>
	]],
			{ i(1, "pass"), i(2, "Exception"), i(3, "pass") },
			fmtopt
		)
	),
	-- statement: try-else
	s(
		{ name = "try-else statement", trig = "lste" },
		fmt(
			[[
	else:
		# 예외가 발생하지 않았을 때 실행할 코드
		<>
	]],
			{ i(1, "pass") },
			fmtopt
		)
	),
	-- statement: try-finally
	s(
		{ name = "try-finally statement", trig = "lstf" },
		fmt(
			[[
	finally:
		# 예외 발생 여부와 상관없이 항상 실행할 코드
		<>
	]],
			{ i(1, "pass") },
			fmtopt
		)
	),
	-- statement: with
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
	<>
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
