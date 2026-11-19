---
name: bdd
description: sdd:draft 의 요구사항 문서(requirements.md)로 Gherkin 시나리오를 써요. requirements.md 경로를 받거나 같은 폴더에 sdd:design 의 설계 문서(design.md)가 없으면, 테스트 층을 따지지 않고 정해진 인수 조건을 마크다운 문서(scenarios.md)의 gherkin 코드 블록에 쓰고, 아직 정해지지 않은 인수 조건은 같은 문서의 「미결 사항」에 남겨요. 폴더나 design.md 경로를 받았고 설계 문서가 있으면 「완성」인지 확인하고, 「요구사항 추적」 표에서 테스트 층이 E2E·통합인 인수 조건만 features/ 아래 *.feature 에 써요. 요구사항 문서가 없거나 설계 문서가 「완성」이 아니면 쓰지 않고 빠진 명령이나 남은 결정을 알려요. 트리거 - `/sdd:bdd {requirements.md | design.md 경로 | 폴더}`, "시나리오 써줘", "feature 파일 만들어줘"
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

## 레퍼런스

먼저 `${CLAUDE_PLUGIN_ROOT}/references/spec-format.md` 와 `${CLAUDE_PLUGIN_ROOT}/references/bdd.md` 를 읽는다. 파일 구성, 형식, Feature 분할, 시나리오·스텝·표 규칙, 템플릿, 로컬라이제이션, 태그, 예시, 마크다운 문서 모양은 뒤 문서를 따른다. 이 스킬은 위 원칙과 아래의 쓰는 과정만 정한다.

## 입력 찾기

- spec-format 「저장 위치」의 「폴더 고르기」로 폴더를 정한다. 파일 경로를 받으면 그 파일이 있는 폴더다
- 폴더에 `requirements.md` 가 없으면 쓰지 않고 `/sdd:draft {설명}` 을 알린다
- 경로를 고른다
    - `requirements.md` 경로를 받았다 → 「기획 경로」. 같은 폴더에 `design.md` 가 있어도, 「완성」이 아니어도 그렇다
    - `design.md` 경로를 받았다 → 「설계 경로」
    - 폴더를 받았다 → `design.md` 가 없으면 「기획 경로」, 있으면 「설계 경로」
- 고른 경로의 입력 문서를 끝까지 읽는다. 앞부분만 보고 쓰지 않는다

## 기획 경로

`sdd:draft → sdd:bdd`. 설계 전에 기획자가 인수 조건을 예시로 맞춰 보는 경로다. 입력은 `requirements.md` 하나다.

- 테스트 층을 따지지 않는다. 정해진 인수 조건과 정해진 업무 규칙 경계 행을 시나리오의 근거로 쓴다. 근거에 없는 행동을 시나리오로 더하지 않는다
    - 정해졌다: 마커가 `@결정`·`@확정`·`@해석` 이고, 괄호 속 결정 ID 가 요구사항 문서 「열린 결정」에 없다
    - 그 밖(`@초안`·`@미정`, 또는 열린 결정에 걸림)은 미결이다. 시나리오를 쓰지 않고 `scenarios.md` 「미결 사항」에 남긴다. 마스터가 정하지 않은 행동을 예시로 굳히면, 답이 나는 순간 시나리오를 다시 써야 하기 때문이다
- 「열린 결정」이 남아 있어도 멈추지 않는다. 정해진 인수 조건만으로 쓴다. 정해진 인수 조건이 하나도 없으면 「미결 사항」만 쓴다
- 시나리오의 마커 태그는 근거 인수 조건의 마커를 그대로 쓴다
- `design.md` 가 있어도 읽지 않는다. 스텝은 화면·API 모양 없이 업무 언어로만 쓴다
- 결과물은 `references/bdd.md` 「마크다운 문서 (기획 경로)」 모양의 `scenarios.md` 다

## 설계 경로

`sdd:draft → sdd:design → sdd:bdd`. 구현에서 자동화할 시나리오를 쓰는 경로다. 입력은 `requirements.md` 와 `design.md` 다.

### 완성 확인

`sdd:task` 「완성 확인」과 같은 조건으로 확인한다. 하나라도 어긋나면 시나리오를 쓰지 않고, 그 절의 답 모양대로 남은 결정을 알린다. 마지막 줄의 명령은 `/sdd:bdd {폴더}` 다. 결정이 남은 채 시나리오를 쓰면, 결정이 나는 순간 시나리오를 다시 써야 하기 때문이다. 설계 문서가 「완성」이 아니어도 기획 경로로 바꿔 쓰지 않는다.

### 시나리오로 만들 인수 조건

- 설계 문서 「요구사항 추적」 표에서 테스트 층이 E2E 또는 통합인 행만 고른다. 단위·운영 확인 층은 시나리오로 만들지 않는다
- 고른 인수 조건의 행동과 요구사항 문서 업무 규칙의 경계 행을 시나리오의 근거로 쓴다. 근거에 없는 행동을 시나리오로 더하지 않는다
- 결과물은 `references/bdd.md` 「Files and organization」 모양의 `*.feature` 다

## 저장 위치

- 기획 경로: 입력 폴더의 `scenarios.md` (예: `~/.sdd/dotfiles/20261102143005_제휴카페-임직원-할인/scenarios.md`)
- 설계 경로: 입력 폴더의 `features/` 아래. 폴더 안 구조와 파일 이름은 `references/bdd.md` 「Files and organization」을 따른다 (예: `~/.sdd/dotfiles/20261102143005_제휴카페-임직원-할인/features/order/customer-pays-order.feature`)
- 나머지는 spec-format 「저장 위치」를 따른다. 두 결과물 모두 윤문을 거치지 않는다 (spec-format 「윤문」)
- 마스터가 요청하기 전에는 커밋하지 않는다
