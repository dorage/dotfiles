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

local identifier = "identifier"

local es6 = {
	-- export
	s("jse", { t("export "), i(1, "value") }),
	-- export default
	s("jsed", { t("export default "), i(1, "value") }),
	-- let variable
	s("jsvl", { t("let "), i(1, "name"), t(" = "), i(2, "value"), t(";") }),
	-- const variable
	s("jsvc", { t("const "), i(1, "name"), t(" = "), i(2, "value"), t(";") }),
	-- arrow function
	s("jsfa", { t("( "), i(1, "name"), t(" ) => {"), i(2, "body"), t("}") }),
	-- normal function
	s("jsfs", { t("function "), i(1, "name"), t("( "), i(1, "name"), t(" ) => {"), i(2), t("}") }),
	-- try-catch statement
	s("jsty", { t("try {"), i(1), t("} catch(err){"), i(2), t("}") }),
	-- default statement
	s("jstyd", { t("try {"), i(1), t("} catch(err){"), i(2), t("}") }),
	-- if statement
	s("jsif", { t("if ("), i(1, "cond"), t(") {"), i(2, "body"), t("}") }),
	-- else if statement
	s("jsifef", { t("else if ("), i(1, "cond"), t(") {"), i(2, "body"), t("}") }),
	-- else statement
	s("jsifel", { t("else {"), i(1, "body"), t("}") }),
	-- switch statement
	s("jssw", { t("switch ("), i(1, "var"), t(") {"), i(2, "body"), t("}") }),
	-- case statement
	s("jsswc", { t("case "), i(1, "valut"), t(" :"), i(2, "body") }),
	-- default statement
	s("jsswd", { t("default :"), i(2, "body") }),
	-- break statement
	s("jsbr", { t("break;") }),
	-- continue statement
	s("jscn", { t("continue;") }),
	-- -- for..idx statement
	-- s("jsfr", { t("for(let"), i(2, "body") }),
	-- -- for..of statement
	-- s("jsfo", { t("for(const "), i(1, "body") }),
	-- -- forEach ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- map ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- filter ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- every ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- some ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- reduce ff
	-- s("jsfo", { t("default :"), i(2, "body") }),
	-- -- console.log
	-- -- console.error
	-- -- console.debug
}

ls.add_snippets("javascript", es6)
ls.add_snippets("javascriptreact", es6)
ls.add_snippets("typescript", es6)
ls.add_snippets("typescriptreact", es6)
