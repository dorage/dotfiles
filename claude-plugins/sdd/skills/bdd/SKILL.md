---
name: bdd
description: sdd:draft 의 요구사항 문서(requirements.md)와 「완성」 상태인 sdd:design 의 설계 문서(design.md)를 받아, 같은 폴더의 features/ 아래에 Gherkin 시나리오(*.feature)를 써요. 설계 문서 「요구사항 추적」 표에서 테스트 층이 E2E·통합인 인수 조건만 시나리오로 만들어요. 두 문서 중 하나가 없거나 설계 문서가 「완성」이 아니면 쓰지 않고 빠진 명령이나 남은 결정을 알려요. 트리거 - `/sdd:bdd {폴더 | design.md 경로}`, "시나리오 써줘", "feature 파일 만들어줘"
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

먼저 `${CLAUDE_PLUGIN_ROOT}/references/spec-format.md` 와 `${CLAUDE_PLUGIN_ROOT}/references/bdd.md` 를 읽는다. 파일 구성, 형식, Feature 분할, 시나리오·스텝·표 규칙, 템플릿, 로컬라이제이션, 태그, 예시는 뒤 문서를 따른다. 이 스킬은 위 원칙과 아래의 쓰는 과정만 정한다.

## 입력 찾기

- spec-format 「저장 위치」의 「폴더 고르기」로 폴더를 정한다. 파일 경로를 받으면 그 파일이 있는 폴더다
- 폴더에 `requirements.md` 와 `design.md` 가 **둘 다** 있어야 한다. 하나라도 없으면 쓰지 않고 빠진 문서와 만드는 명령을 알린다
    - `requirements.md` 가 없다 → `/sdd:draft {설명}`
    - `design.md` 가 없다 → `/sdd:design {requirements.md 경로}`
- 두 문서를 끝까지 읽는다. 앞부분만 보고 쓰지 않는다

## 완성 확인

`sdd:task` 「완성 확인」과 같은 조건으로 확인한다. 하나라도 어긋나면 시나리오를 쓰지 않고, 그 절의 답 모양대로 남은 결정을 알린다. 마지막 줄의 명령은 `/sdd:bdd {폴더}` 다. 결정이 남은 채 시나리오를 쓰면, 결정이 나는 순간 시나리오를 다시 써야 하기 때문이다.

## 시나리오로 만들 인수 조건

- 설계 문서 「요구사항 추적」 표에서 테스트 층이 E2E 또는 통합인 행만 고른다. 단위·운영 확인 층은 시나리오로 만들지 않는다
- 고른 인수 조건의 행동과 요구사항 문서 업무 규칙의 경계 행을 시나리오의 근거로 쓴다. 근거에 없는 행동을 시나리오로 더하지 않는다

## 저장 위치

- 입력 폴더의 `features/` 아래. 폴더 안 구조와 파일 이름은 `references/bdd.md` 「Files and organization」을 따른다 (예: `~/.sdd/dotfiles/20261102143005_제휴카페-임직원-할인/features/order/customer-pays-order.feature`)
- 나머지는 spec-format 「저장 위치」를 따른다
- 마스터가 요청하기 전에는 커밋하지 않는다
