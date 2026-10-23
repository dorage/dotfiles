---
name: spec-bdd
description: 마스터가 계획, 스펙 작성 혹은 동작이 변경이 예상되는 코드 생성/수정을 계획단계없이 요청했을 때, 테스트케이스 구성을 위해 이 스킬을 사용해요. Gherkin 문법을 이용해 BDD 테스트 시나리오 가드라인을 작성해요. 트리거 - /spec-bdd {요청}, '계획 작성', '~ 부분 수정해줘'
metadata:
  author: AutomationPanda
  source: https://github.com/AutomationPanda/gherkin-guidelines-for-ai
---

# Gherkin Guidelines

This document is a **context contract** for writing, reviewing, and maintaining Gherkin feature files that serve as
**living documentation** and **specification by example**.

The goals are:
- **Readable** by non-automation stakeholders
- **Deterministic** enough for LLMs to follow
- **Automation-ready** without leaking implementation details

This guidance assumes **Cucumber-compatible Gherkin** (the "Queen's Gherkin"). Reference: https://cucumber.io/docs/gherkin/reference/

---

## Guiding principles (apply everywhere)

- **Be behavior-driven**: describe *what* the system does, not *how* it’s implemented.
- **Write for humans first**: any engineer should understand what to do and what should happen.
- **Specification by example**: scenarios are concrete examples of behavior.
- **One behavior per scenario**: each scenario targets a single behavior.
- **Independent scenarios**: each scenario can run in isolation.

---

## Files and organization

- **MUST** save Gherkin in `*.feature` files.
- **MUST** use kebab-case file names.
- **SHOULD** keep all feature files under one main directory unless the project dictates otherwise.
- **MAY** use sub-directories; **SHOULD** organize by functional behavior area.

---

## Formatting rules (make diffs and parsing reliable)

- **MUST** use one `Feature` per file.
- **MAY** have multiple `Scenario` / `Scenario Outline` blocks under a single `Feature`.
- **MUST** indent the body of these sections by **2 spaces**:
  - `Feature`
  - `Background`
  - `Scenario`
  - `Scenario Outline`
  - `Examples`
- **SHOULD** keep lines under **120 characters**.
- **Vertical whitespace** (keep these together when editing a file):
  - **SHOULD** separate major sections with **one blank line**.
  - **SHOULD** put **one blank line** between adjacent `Scenario` / `Scenario Outline` blocks for
    readability and cleaner diffs.
  - **MUST NOT** put blank lines *between steps* within a scenario or background.
- **SHOULD** avoid comments; the scenario text should be self-explanatory.

---

## Vocabulary (ubiquitous language)

- **MUST** use one stable vocabulary for roles, domain objects, and states.
- **MUST NOT** swap synonyms for the same concept unless the product meaningfully distinguishes them
  (for example: "order" vs "purchase" vs "cart").

---

## Feature blocks

- **MUST** name `Feature:` after the behavior area it covers.
- **SHOULD** align the file name with the `Feature:` title.
- **MUST** keep the `Feature:` title to a single line.
- **SHOULD** include a short user story directly under the `Feature:` title using three lines:
  - `As a <role>`
  - `I want <goal>`
  - `So that <reason>`

---

## Background sections

- **MAY** omit `Background` entirely. `Background` is optional.
- **MUST** use `Background` only for a starting state shared by **multiple** scenarios in the file.
- **MUST NOT** have more than one `Background` section per `Feature` (and this guidance requires one
  `Feature` per file).
- **MUST NOT** use `Background` when only one scenario needs the setup.
- **SHOULD** keep backgrounds short; if a background grows, consider splitting feature files.

---

## Scenarios (structure + intent)

- **MUST** give each `Scenario:` / `Scenario Outline:` a single-line, behavior-focused title.
- **MUST** be chronologically executable step-by-step.
- **SHOULD** be declarative rather than imperative.
- **MUST** focus on behavior concerns; step definitions (automation code) handle implementation details.
- **SHOULD** keep steps at a **domain / business level of abstraction**: describe what actors do and
  what the system does in **product language**, not in framework or plumbing terms.
- **MUST NOT** leak automation or UI mechanics into steps (for example: selectors, XPath, "wait for,"
  "scroll to," "click element #foo") unless the behavior under test is truly about that mechanic.
- **MUST NOT** put HTTP endpoints, SQL, internal schema, or raw storage mechanics in step text unless
  the **behavior being specified** is inherently at that layer (for example, a service exposed only as
  an API).
- **SHOULD** prefer **state over navigation**: describe meaningful starting states (for example,
  "Given the user is signed in with role \"Editor\"") instead of imperative UI tours through every
  click and field, unless the **interaction path** is what this scenario is meant to specify.
- **SHOULD** use **minimal but sufficient** `Given` context: include only preconditions a reader needs
  to understand the behavior; omit unrelated setup that does not change the meaning of the example.
- **MUST NOT** bundle **multiple independent quality concerns** in one scenario (for example, core
  functional behavior together with performance, accessibility, or unrelated security checks) unless
  the scenario title and steps explicitly specify **one** behavior that legitimately spans those
  concerns. Otherwise split into separate scenarios.
- **SHOULD** use **concrete, realistic** example values in steps and tables (names, amounts, dates,
  realistic identifiers) so the scenario reads as a believable example.
- **SHOULD NOT** use meaningless placeholder data (`foo`, `bar`, `test`, `lorem`) unless the scenario
  is intentionally about generic, invalid, or deliberately nonsensical input.
- **SHOULD** target **< 10 steps**. If longer, consider splitting behaviors or using tables.

### Scenario Outline usage

- **MUST** use `Scenario Outline` only when the **same behavior** needs multiple input variations.
- **SHOULD** prefer `Scenario` when inputs don’t materially change the behavior being specified.

---

## Steps (language + semantics)

### Language rules

- **MUST** write steps in **third person** and **present tense**.
- **MUST** use **subject–predicate** phrasing.
- **MUST** use proper English grammar and spelling.
- **SHOULD** minimize punctuation; use it only when required for readability.
- **MUST** use double quotes (`"`) for string parameters.
- **SHOULD NOT** combine multiple actions/assertions with conjunctions inside one step; split into
  separate steps.

### Given / When / Then rules

- Treat **Given / When / Then** as **Arrange / Act / Assert**:
  - `Given` sets up context
  - `When` performs the action
  - `Then` verifies outcomes
- **MUST** maintain strict Given/When/Then order.
- **MUST NOT** repeat Given/When/Then phases inside one scenario; create separate scenarios instead.
- **MAY** use `And` to continue the same step type.
- **MAY** use `But` sparingly when a contrast improves readability.
- **MUST NOT** use `Or` as a step keyword. If choices matter, use separate scenarios or a
  `Scenario Outline`.

### Observable outcomes

- **MUST** make `Then` outcomes **observable and checkable** from the scenario text:
  what changed, what the user sees, or what the system reports.
- **MUST NOT** use vague outcomes like "it works" / "it succeeds" without stating how that is known.

### Multiline and structured payloads

- **SHOULD** use doc strings (`"""` … `"""`) for multiline or structured payloads
  (for example, JSON, XML, or an email body) instead of an enormous quoted string or many `And`s.

---

## Tables (data without step spam)

- **SHOULD** use step data tables to pass lists/sets of inputs instead of long `And` chains.
- **SHOULD** use concise, descriptive headers (often single-token with kebab-case).
- **SHOULD** keep step tables and `Examples` tables to a single screen view.
- If a table becomes large, reconsider whether the scenario is drifting into pure data-driven testing.

---

## Common anti-patterns (avoid)

- Mixing multiple behaviors into one scenario (multiple unrelated actions or assertions).
- Mixing unrelated **concerns** in one scenario (for example, happy-path functionality plus load time
  or unrelated accessibility rules) when they deserve separate specifications.
- Encoding UI implementation details (selectors, DOM structure) into step text.
- Over-specifying navigation and clicks when **state** would communicate the same precondition more
  clearly.
- Bloated `Given` chains that set up context the scenario never needs.
- Vague assertions ("it works", "it succeeds", "the user is logged in" without an observable signal).
- Placeholder example data (`foo` / `bar`) that does not read like a real specification example.
- Overusing `Scenario Outline` to generate many rows without distinct behavioral value.
- Extremely long scenarios or tables that no human will read or will seem like a [wall of text](https://en.wikipedia.org/wiki/Wikipedia:Wall_of_text).

---

## Quick checklist (for humans and LLMs)

Before finalizing a scenario, verify:
- [ ] One behavior only; can run independently
- [ ] No unrelated concerns bundled (split functional vs performance, a11y, etc. when separate)
- [ ] Stable vocabulary (no synonym swapping)
- [ ] Domain-level abstraction; no unnecessary UI/API/DB plumbing in steps
- [ ] State over navigation where it keeps the scenario clearer
- [ ] Minimal but sufficient `Given` context
- [ ] Concrete, realistic example data (not generic placeholders)
- [ ] Steps are third-person, present tense, subject–predicate
- [ ] Strict Given → When → Then order; `Then` outcomes are observable
- [ ] No UI/automation mechanics leaked into steps
- [ ] Blank line between scenarios in the same file
- [ ] Scenario is short (ideally < 10 steps); tables fit on one screen

---

## Recommended template

Use this as a starting point:

```gherkin
Feature: <behavior area>
  As a <role>
  I want <goal>
  So that <reason>

  Background:
    Given <shared starting state>

  Scenario: <single behavior>
    Given <context>
    And <additional context>
    When <action>
    And <continued action>
    Then <observable outcome>
    And <additional observable outcome>

  Scenario: <single behavior using a step data table>
    Given the following <domain entities> exist:
      | <column-a> | <column-b> |
      | <value 1>  | <value 2>  |
      | <value 3>  | <value 4>  |
    When <action>
    Then <observable outcome>

  Scenario Outline: <same behavior, varying inputs>
    Given <context>
    When <action> with "<input>"
    Then the outcome is "<outcome>"

    Examples:
      | input   | outcome   |
      | <case1> | <result1> |
      | <case2> | <result2> |
```

## 로컬라이제이션

| Keyword | Equivalent(s) |
|---|---|
| Feature | 기능 |
| Background | 배경 |
| Rule | 규칙 |
| Scenario | 시나리오 |
| Scenario Outline | 시나리오 개요 |
| Examples | 예 |
| Given | `*`, 조건, 먼저 |
| When | `*`, 만일, 만약 |
| Then | `*`, 그러면 |
| And | `*`, 그리고 |
| But | `*`, 하지만, 단 |

원문에서 붙어 있던 값들(`*조건먼저` 등)은 Gherkin 공식 키워드 목록 기준으로 `*`, `조건`, `먼저`처럼 개별 키워드로 나눴습니다. `*`는 모든 스텝 키워드 대신 쓸 수 있는 범용 스텝 키워드입니다.

## 태그

- @결정: 마스터가 스펙/SSOT에 적은 결정을 그대로 옮긴 것입니다. 마스터가 직접 정했습니다.
- @해석: 마스터가 정하긴 했지만 결정 문장이 짧아서, LLM이 뜻을 풀어 쓴 것입니다. 풀어 쓴 내용이 마스터의 뜻과 맞는지 확인이 필요합니다.
- @초안: 마스터의 결정 문장이 아예 없습니다. 근처에서 내려진 결정 때문에 빈 곳이 드러났고, LLM이 그 빈 곳을 새 규칙으로 채웠습니다. 세 표기 가운데 틀릴 가능성이 가장 큽니다.

``` gherkin
# language: ko
기능: 주문 금액과 주문 당시 기록
  고객사로서
  주문할 때의 상품 이름과 구성과 금액이 나중에도 그대로 보이길 바란다
  그래서 상품이 바뀌거나 지워져도 무엇을 얼마에 주문했는지 안다

  배경:
    조건 공급사 "세척공방"의 상품 "한식 세트"의 구성은 다음과 같다:
      | 용기   | 상품당-수량 | 개당-가격 |
      | 밥그릇 | 60          | 300       |
      | 국그릇 | 60          | 250       |
    그리고 상품 "16oz 80개 박스"의 구성은 16oz 컵 80개, 개당 200원이다
    그리고 두 상품 모두 고객사 "카페 봄날"에 매핑되어 있다

  @결정
  시나리오: 주문 금액은 원 단위 정수로 구성 가격에서 계산하고 부가세는 별도다
    만약 고객사 "카페 봄날"이 한 주문에 다음 상품을 담는다:
      | 상품           | 수량 |
      | 한식 세트      | 2    |
      | 16oz 80개 박스 | 3    |
    그러면 주문 라인 금액은 다음과 같다:
      | 상품           | 상품-1개-금액 | 라인-금액 |
      | 한식 세트      | 33,000        | 66,000    |
      | 16oz 80개 박스 | 16,000        | 48,000    |
    그리고 주문 총액은 114,000원이다

  @초안
  시나리오: 주문 뒤에 상품을 고쳐도 주문에 남은 상품 정보는 그대로다
    조건 고객사 "카페 봄날"이 상품 "한식 세트"를 2개 주문했다
    만약 공급사 "세척공방"이 상품 이름을 "한식 세트 A"로, 밥그릇 개당 가격을 350원으로 고친다
    그러면 그 주문의 상품 이름은 "한식 세트"이다
    그리고 그 주문의 "한식 세트" 1개 금액은 33,000원이다
    그리고 그 주문의 구성은 밥그릇 60개 300원, 국그릇 60개 250원이다
```
