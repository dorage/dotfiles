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

local markdown = {
	-- heading
	s(
		{ name = "heading", regTrig = true, trig = "h([1-6])" },
		{ f(function(args, snip)
			return string.rep("#", snip.captures[1]) .. " "
		end), i(1) }
	),
	-- warning
	-- bold
	postfix({ name = "font bold", trig = ".fb" }, {
		f(function(_, parent)
			return "**" .. parent.snippet.env.POSTFIX_MATCH .. "**"
		end, {}),
	}),
	s(
		{ name = "font bold", trig = "fb" },
		fmt(
			[[
	**<>**
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- italic
	postfix({ name = "font italic", trig = ".fi" }, {
		f(function(_, parent)
			return "*" .. parent.snippet.env.POSTFIX_MATCH .. "*"
		end, {}),
	}),
	s(
		{ name = "font italic", trig = "fi" },
		fmt(
			[[
	*<>*
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- bold and italic
	postfix({ name = "font bold & italic", trig = ".fbi" }, {
		f(function(_, parent)
			return "***" .. parent.snippet.env.POSTFIX_MATCH .. "***"
		end, {}),
	}),
	s(
		{ name = "font bold & italic", trig = "fbi" },
		fmt(

			[[
	***<>***
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- block quotes
	s(
		{ name = "block quote", trig = "bq" },
		fmt(
			[[
	>> <>
	]],
			{ i(1) },
			fmtopt
		)
	),
	-- code
	s(
		{ name = "code", trig = "cda" },
		fmt(
			[[
	`<>`
	]],
			{ i(1) },
			fmtopt
		)
	),
	s(
		{ name = "fenced code block", trig = "cdm" },
		fmt(
			[[
	``` <>
	<>
	```
	]],
			{ i(1), i(2) },
			fmtopt
		)
	),
	-- claude skills
	s(
		{ name = "Claude Skills", trig = "csk" },
		fmt(
			[[---
name: <>
description: <>
---

# <>

## Instruction

<>
	]],
			{ i(1), i(2), rep(1), i(3) },
			fmtopt
		)
	),
	-- horizontal rule
	s({ name = "horizontal rule", trig = "hr" }, { t("---") }),
	-- break a line
	s({ name = "break a line", trig = "br" }, { t("<br/>") }),
	-- checkbox
	s({ name = "checkbox", trig = "cb" }, { t("- [ ]") }),
	-- links
	postfix(
		{ name = "link postfix", trig = ".ln", match_pattern = "[^ ]+$" },
		fmt(
			[[
	<>[<>](<>)
	]],
			{
				c(1, { t(""), t("!") }),
				f(function(_, parent)
					local url = parent.snippet.env.POSTFIX_MATCH
					local title = require("dorage.snippets.utils.markdown").get_url_title(url)

					return title
				end),
				f(function(_, parent)
					return parent.snippet.env.POSTFIX_MATCH
				end),
			},
			fmtopt
		)
	),
	-- table
	-- EARS (Easy Approach to Requirements Syntax)
	-- | 패턴        | 형식                                               | 시간논리       | 불변식과의 관계                  |
	-- | Ubiquitous  | The <system> shall <response>                      | □P             | 가장 가까움, 트리거 없이 항상 활성 |
	-- | While       | While <state>, the <system> shall <response>       | □(S → R)       | 조건부(상태) 불변식               |
	-- | When        | When <trigger>, the <system> shall <response>      | □(T → ◇R/○R)   | 응답 성질, 사건 발생 시 의무      |
	-- | If…then     | If <condition>, then the <system> shall <response> | When 과 유사   | 예외·고장 대응, 복구 의무         |
	-- | Where       | Where <feature>, the <system> shall <response>     | 구성 조건      | 제품 변형 선택 조건               |
	-- | Complex     | 위 키워드 조합 (Where → While → When/If)           | 조합           | 경우에 따라 다름                  |
	s(
		{ name = "EARS ubiquitous", trig = "earsu", dscr = "The <system> shall <response> (□P)" },
		{ t("The "), i(1, "system"), t(" shall "), i(2, "response"), t(".") }
	),
	s({ name = "EARS state-driven", trig = "earsw", dscr = "While <state>, ... (□(S → R))" }, {
		t("While "),
		i(1, "state"),
		t(", the "),
		i(2, "system"),
		t(" shall "),
		i(3, "response"),
		t("."),
	}),
	s({ name = "EARS event-driven", trig = "earse", dscr = "When <trigger>, ... (□(T → ◇R))" }, {
		t("When "),
		i(1, "trigger"),
		t(", the "),
		i(2, "system"),
		t(" shall "),
		i(3, "response"),
		t("."),
	}),
	s({ name = "EARS unwanted behaviour", trig = "earsi", dscr = "If <condition>, then ... (복구 의무)" }, {
		t("If "),
		i(1, "condition"),
		t(", then the "),
		i(2, "system"),
		t(" shall "),
		i(3, "response"),
		t("."),
	}),
	s({ name = "EARS optional feature", trig = "earso", dscr = "Where <feature>, ... (구성 조건)" }, {
		t("Where "),
		i(1, "feature"),
		t(", the "),
		i(2, "system"),
		t(" shall "),
		i(3, "response"),
		t("."),
	}),
	s({ name = "EARS complex", trig = "earsc", dscr = "While <state>, when <trigger>, ... (조합)" }, {
		t("While "),
		i(1, "state"),
		t(", "),
		c(2, {
			sn(nil, { t("when "), i(1, "trigger"), t(", the ") }),
			sn(nil, { t("if "), i(1, "condition"), t(", then the ") }),
		}),
		i(3, "system"),
		t(" shall "),
		i(4, "response"),
		t("."),
	}),
}

ls.add_snippets("mdx", markdown)
ls.add_snippets("markdown", markdown)
ls.add_snippets("telekasten", markdown)
