---
name: bdd
description: 마스터가 계획, 스펙 작성 혹은 동작이 변경이 예상되는 코드 생성/수정을 계획단계없이 요청했을 때, 테스트케이스 구성을 위해 이 스킬을 사용해요. Gherkin 문법을 이용해 BDD 테스트 시나리오 가드라인을 작성해요. 트리거 - /sdd:bdd {요청}, '계획 작성', '~ 부분 수정해줘'
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

먼저 `${CLAUDE_PLUGIN_ROOT}/references/spec-format.md` 와 `${CLAUDE_PLUGIN_ROOT}/references/bdd.md` 를 읽는다. 파일 구성, 형식, Feature 분할, 시나리오·스텝·표 규칙, 템플릿, 로컬라이제이션, 태그, 예시는 뒤 문서를 따른다. 이 스킬은 위 원칙만 정한다.
