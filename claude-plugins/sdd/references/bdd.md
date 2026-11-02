# Gherkin 시나리오 (*.feature)

`sdd:bdd` 가 쓰는 Gherkin 시나리오의 모양이다. 마커 태그는 `references/spec-format.md` 를 따른다. 영어 본문은 AutomationPanda 의 gherkin-guidelines-for-ai (https://github.com/AutomationPanda/gherkin-guidelines-for-ai) 를 옮겨 고친 것이다.

## Files and organization

- **MUST** save Gherkin in `*.feature` files.
- **MUST** use kebab-case file names.
- **MUST** save feature files under `features/` in the spec folder (`references/spec-format.md` 「저장 위치」), next to `requirements.md` and `design.md`.
- **MAY** use sub-directories; **SHOULD** organize by functional behavior area.
- **MUST** group a domain (for example, 주문) with a directory, not with a single `Feature`.
- **MUST** name files `<actor>-<flow>.feature` (for example, `customer-requests-refund.feature`).
  Permission features use `<domain>-<action>-permission.feature`.

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

- **MUST** name `Feature:` after one actor and one flow, or one permission. See "Feature 분할 기준".
- **SHOULD** align the file name with the `Feature:` title.
- **MUST** keep the `Feature:` title to a single line.
- **SHOULD** include a short user story directly under the `Feature:` title using three lines:
  - `As a <role>`
  - `I want <goal>`
  - `So that <reason>`

---

## Feature 분할 기준

- **MUST** 하나의 Feature 는 아래 단위 중 하나로만 묶어요.
  - 주체 × 플로우 (기본)
    - 한 주체가 한 흐름을 겪는 것
    - 예: 고객의 주문 결제, 셀러의 주문 접수, 고객의 환불 요청
  - 권한 (예외)
    - "누가 이 행동을 할 수 있고 누가 못 하는가"만 다뤄요
    - 여러 주체가 함께 나와도 돼요. 대신 흐름의 상세(금액, 상태 변화)는 쓰지 않아요
    - 주체만 다르고 같은 행동이면 `Scenario Outline` 과 주체 열로 써요
- **MUST** 사람이 아닌 시스템(배치, 스케줄러, 외부 연동)이 움직이는 흐름은 "시스템"을 주체 하나로 봐요.
  - 예: `system-settles-monthly.feature`
- **MUST** 다른 주체의 행동이 전제로 필요하면 `Given` 에 이미 일어난 상태로 써요.
  - 예: `조건 셀러 "세척공방"이 주문을 접수했다`
  - 그 행동 자체의 흐름은 그 주체의 Feature 에서 다뤄요
- **MUST NOT** `Rule` 키워드로 여러 플로우를 한 Feature 에 몰아넣지 않아요.
  `Rule` 은 한 플로우 안의 비즈니스 규칙을 묶을 때만 써요.
- 쪼개야 한다는 신호예요.
  - user story 의 `As a <role>` 에 주체가 둘 이상 필요해요
  - 시나리오마다 `When` 의 행동 주체가 바뀌어요
  - 같은 도메인 객체라도 상황(결제, 환불, 반품)이 바뀌어요
  - `Background` 가 일부 시나리오에만 맞아요

```
features/
  order/
    customer-places-order.feature
    customer-pays-order.feature
    customer-requests-refund.feature
    customer-requests-return.feature
    seller-accepts-order.feature
    seller-processes-refund.feature
    system-settles-monthly.feature
    order-cancel-permission.feature
```

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
- [ ] Feature 하나에 주체 하나 × 플로우 하나 (권한 Feature 제외); 다른 주체의 행동은 `Given` 에 있음
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

시나리오 위에 붙이는 태그는 `references/spec-format.md` 의 「마커」와 「답 반영」을 따릅니다. 정의를 이 파일에 따로 적지 않습니다. 시나리오마다 마커 태그 하나를 붙입니다.

## 예시

아래 모양을 따릅니다. 한국어 키워드(`# language: ko`), 여러 시나리오가 함께 쓰는 시작 상태는 `배경:` 의 데이터 표, 시나리오마다 마커 태그 하나, `그러면` 에는 확인할 수 있는 결과를 씁니다.

- `api-` 로 시작하는 파일은 API 로만 드러나는 동작을 정하는 Feature 입니다. 그래서 「Scenarios (structure + intent)」의 예외("unless the service is exposed only as an API")에 따라 응답 상태(409)와 거절 사유 코드를 스텝에 씁니다

``` gherkin
# language: ko
기능: 관리자의 예약 API
  관리자로서
  모든 예약을 찾아보고 필요하면 상태와 일시를 바로잡길 바란다
  그래서 현장의 실수나 옛 데이터를 시스템에 맞게 고친다

  배경:
    조건 요청자는 관리자 "본사 운영팀"이다
    그리고 다음 예약이 있다:
      | 예약 | 지점   | 고객     | 상태     | 예약-시각           |
      | A    | 강남점 | 김민지   | 예약취소 | 2026-10-20 09:00:00 |
      | B    | 강남점 | 박서준   | 예약확인 | 2026-10-21 10:00:00 |
      | C    | 판교점 | 김민지   | 방문완료 | 2026-10-22 10:00:00 |

  @결정
  시나리오: 관리자의 예약 목록에는 여러 지점과 고객의 예약이 함께 보인다
    만약 관리자가 예약 목록을 조회한다
    그러면 목록에 예약 A, B, C가 모두 있다

  @결정
  시나리오: 관리자가 취소된 예약을 강제로 되돌리면 이력 사유에 관리자 강제 변경과 사유가 남는다
    만약 관리자가 사유 "고객 요청 복구"로 예약 A를 "예약대기"로 강제 변경한다
    그러면 응답의 상태는 "예약대기"이다
    그리고 조회한 예약 A의 마지막 이력 사유는 "관리자 강제 변경: 고객 요청 복구"이다

  @초안
  시나리오: 관리자가 공백뿐인 사유로 강제 변경하면 사유 오류로 거절된다
    만약 관리자가 사유 "   "로 예약 A를 "예약대기"로 강제 변경한다
    그러면 응답 상태는 409이다
    그리고 거절 사유는 "RESERVATION_FORCE_REASON_INVALID"이다
    그리고 조회한 예약 A는 예약취소 그대로다

  @결정
  시나리오: 관리자가 예약 시각을 고치면 예약 시각만 바뀌고 방문 희망일은 그대로다
    조건 예약 B의 방문 희망일은 2026-10-24이다
    만약 관리자가 사유 "전화 예약 시각 반영"으로 예약 B의 예약 시각을 2026-10-20 17:30:00으로 고친다
    그러면 응답의 예약 시각은 2026-10-20 17:30:00이다
    그리고 조회한 예약 B의 방문 희망일은 2026-10-24이다
```
