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
local im = require("dorage.customs.js-auto-import")
local fp = require("dorage.utils.fp")

local zod_import_opts =
	{ callbacks = im.import_callback({
		{ source = "zod", default_modules = {}, modules = { "z" } },
	}) }

local M = {
	-- zod type inference
	s(
		{ name = "Zod: infer type", trig = "zdf" },
		fmt(
			[[
z.infer<<typeof <>>>
	]],
			{ i(1) },
			fmtopt
		),
		zod_import_opts
	),
	-- zod object
	s(
		{ name = "Zod: object", trig = "zdo" },
		fmt(
			[[
z.object({
	<>
})
	]],
			{ i(1) },
			fmtopt
		),
		zod_import_opts
	),
}

ls.add_snippets("typescript", M)
ls.add_snippets("typescriptreact", M)
