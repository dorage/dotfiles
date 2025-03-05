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

local components_types = {
	fmt(
		[[
type <>Props = {};

export const <> = (props: <>Props) =>> {
	return <<>><><</>>;
};
	]],
		{
			f(ls_utils.identity, { 1 }),
			i(1),
			f(ls_utils.identity, { 1 }),
			i(2),
		},
		fmtopt
	),
	-- 	fmt(
	-- 		[[
	-- const <> = forwardRef<<
	--   HTMLDivElement,
	--   React.HTMLAttributes<<HTMLDivElement>> & {}
	-- >>(({ className, ...props }, ref) =>> {
	--   return <<div className={cn("", className)} {...props} />>;
	-- });
	-- <>.displayName = "<>";
	-- <>
	-- 	]],
	-- 		{
	-- 			i(1),
	-- 			f(ls_utils.identity, { 1 }),
	-- 			f(ls_utils.identity, { 1 }),
	-- 			f(function()
	-- 				require("ts-manual-import").luasnip_callback({
	-- 					{
	-- 						source = "react",
	-- 						modules = {},
	-- 						default_modules = { "forwardRef" },
	-- 					},
	-- 					{
	--
	-- 						source = "@/lib/utils",
	-- 						modules = { "cn" },
	-- 						default_modules = {},
	-- 					},
	-- 				})
	-- 			end),
	-- 		},
	-- 		fmtopt
	-- 	),
}

local M = {
	-- useState
	s(
		{ name = "React: useState", trig = "rehs" },
		fmt(
			[[
	const [<>, set<>] = useState<<<>>>(<>);
		]],
			{
				i(1),
				f(ls_utils.capitalize_first_char, { 1 }),
				i(2),
				i(3),
			},
			fmtopt
		),
		{
			callbacks = require("ts-manual-import").luasnip_callback({
				{
					source = "react",
					modules = { "useState" },
					default_modules = {},
				},
			}),
		}
	),
	-- -- useEffect
	s(
		{ name = "React: useEffect", trig = "rehe" },
		fmt(
			[[
useEffect(() =>> {
	<>
},[<>]);
	]],
			{ i(1), i(2) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "react",
					modules = { "useEffect" },
					default_modules = {},
				},
			}),
		}
	),
	s(
		{ name = "React: useRef", trig = "rehr" },
		fmt(
			[[
const <> = useRef<<<>>>(<>);
	]],
			{ i(1), i(2), i(3) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "react",
					modules = { "useRef" },
					default_modules = {},
				},
			}),
		}
	),
	-- -- useCallback
	s(
		{ name = "React: useCallback", trig = "rehc" },
		fmt(
			[[
const <> = useCallback((<>)=>>{
	<>
}, [<>]);
	]],
			{ i(1), i(2), i(3), i(4) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "react",
					modules = { "useCallback" },
					default_modules = {},
				},
			}),
		}
	),
	-- -- useMemo
	s(
		{ name = "React: useMemo", trig = "rehm" },
		fmt(
			[[
const <> = useMemo(()=>>{
	<>
}, [<>]);
	]],
			{ i(1), i(2), i(3) },
			fmtopt
		),
		{
			callbacks = ls_auto_import.import_callback({
				{
					source = "react",
					modules = { "useMemo" },
					default_modules = {},
				},
			}),
		}
	),
	-- new hook
	s(
		{ name = "React: new hook", trig = "rehn" },
		fmt(
			[[
type <>Props = {};

export const use<> = (props: <>Props) =>> {
	return {};
}
	]],
			{

				f(ls_utils.identity, { 1 }),
				i(1),
				f(ls_utils.identity, { 1 }),
			},
			fmtopt
		)
	),
	-- -- new Component
	-- 	s(
	-- 		{ name = "React: new Component", trig = "recn" },
	-- 		fmt(
	-- 			[[
	-- type <>Props = {};
	--
	-- export const <> = (props: <>Props) =>> {
	-- 	return <<>><><</>>;
	-- };
	-- 	]],
	-- 			{
	-- 				f(ls_utils.identity, { 1 }),
	-- 				i(1),
	-- 				f(ls_utils.identity, { 1 }),
	-- 				i(2),
	-- 			},
	-- 			fmtopt
	-- 		)
	-- 	),
	s({ name = "React: new Component", trig = "recn" }, {
		c(1, components_types),
	}),
	s(
		{ name = "React: new HoC", trig = "rech" },
		fmt(
			[[
type <>Props = {};

type <>DerivedProps = {};

export const <> = <<T,>>(Component: React.ComponentType<<<>DerivedProps & T>>) =>> (props: <>Props & T) =>> {
	return <<Component {...props} />>;
};
	]],
			{
				f(ls_utils.identity, { 1 }),
				f(ls_utils.identity, { 1 }),
				i(1),
				f(ls_utils.identity, { 1 }),
				f(ls_utils.identity, { 1 }),
			},
			fmtopt
		)
	),
}

ls.add_snippets("typescript", M)
ls.add_snippets("typescriptreact", M)
