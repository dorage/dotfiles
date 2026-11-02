# sdd

스펙 주도 개발(SDD) 스킬 묶음이다.

- `/sdd:draft` — 구현 전 요구사항 문서(requirements.md)
- `/sdd:design` — requirements.md 를 받아 설계 문서(design.md)
- `/sdd:brief` — 비개발자도 읽는 기획 문서(brief.md)
- `/sdd:quick` — 작은 작업의 스펙과 설계를 채팅 답 하나로
- `/sdd:bdd` — Gherkin 테스트 시나리오

다섯 스킬이 함께 따르는 포맷은 `references/spec-format.md` 한 곳에 있다.

## 고친 뒤 반영하기

- `.claude-plugin/plugin.json` 의 `version` 을 올린다
    - 문장만 고쳤으면 셋째 자리 (0.1.0 → 0.1.1)
    - 스킬을 더하거나 빼거나 이름을 바꿨으면 둘째 자리 (0.1.1 → 0.2.0)
- `/plugin update sdd@dotfiles` 를 실행하고 새 세션을 연다
