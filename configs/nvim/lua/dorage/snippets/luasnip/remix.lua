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
	-- Remix new loader
	s(
		{ name = "Remix: new Loader", trig = "reml" },
		fmt(
			[[
export const loader = async ({}: LoaderFunctionArgs) =>> {
	<>

	return json({});
};
	]],
			{ i(1) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "@remix-run/node",
					modules = { "LoaderFunctionArgs", "json" },
					default_modules = {},
				},
			}),
		}
	),
	-- Remix new action
	s(
		{ name = "Remix: new Action", trig = "rema" },
		fmt(
			[[
export const action = async ({ }: ActionFunctionArgs) =>> {
	<>

	return json({ ok: true });
};
	]],
			{ i(1) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "@remix-run/node",
					modules = { "ActionFunctionArgs", "json" },
					default_modules = {},
				},
			}),
		}
	),
	-- Remix new Route
	s(
		{ name = "Remix: new Route", trig = "remr" },
		fmt(
			[[
export default function <>() {
	return <<>><</>>
}
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- Remix useLoaderData
	s({ name = "Remix: useLoaderData", trig = "remhd" }, {
		t("const loaderData = useLoaderData<typeof loader>();"),
	}, {
		callbacks = ls_auto_import.import_callback({
			{
				source = "@remix-run/react",
				modules = { "useLoaderData" },
				default_modules = {},
			},
		}),
	}),
}

ls.add_snippets("typescriptreact", M)
