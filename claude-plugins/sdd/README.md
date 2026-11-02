# sdd

스펙 주도 개발(SDD) 스킬 묶음이다.

- `/sdd:draft` — 구현 전 요구사항 문서(requirements.md)
- `/sdd:design` — requirements.md 를 받아 설계 문서(design.md)
- `/sdd:task` — requirements.md 와 design.md 를 받아 구현 계획 문서(tasks.md)
- `/sdd:brief-dev` — requirements.md 에서 마커를 걷어 낸 개발자용 기획 문서(brief-dev.md)
- `/sdd:brief-nondev` — requirements.md 를 비개발자도 읽게 바꾼 기획 문서(brief-nondev.md)
- `/sdd:quick` — 작은 작업의 스펙과 설계를 채팅 답 하나로
- `/sdd:bdd` — requirements.md 와 「완성」 design.md 를 받아 Gherkin 시나리오(features/*.feature)
- `/sdd:setup` — `~/.sdd/{리포지토리 이름}/` 보관 폴더와 윤문 플러그인(`humanize-korean@im-not-ai`) 준비

문서를 쓰는 일곱 스킬이 함께 따르는 공용 포맷(결정·마커·답 반영·저장 위치·윤문)은 `references/spec-format.md` 한 곳에 있다. 단계마다 결과물 모양(절 구성·템플릿·완성 조건)은 `references/{스킬 이름}.md` (`draft`·`design`·`task`·`quick`·`bdd`)에 있고, 두 brief 스킬의 변환 규칙은 `references/brief-format.md` 에 있다. SKILL.md 에는 쓰는 과정만 둔다.

- 어떤 명령을 어떤 순서로 쓰는지: [WORKFLOW.md](WORKFLOW.md)
- 결과물이 어디에 남고 서로 무엇을 읽는지: [OUTPUT.md](OUTPUT.md)

## 고친 뒤 반영하기

- `.claude-plugin/plugin.json` 의 `version` 을 올린다
    - 문장만 고쳤으면 셋째 자리 (0.1.0 → 0.1.1)
    - 스킬을 더하거나 빼거나 이름을 바꿨으면 둘째 자리 (0.1.1 → 0.2.0)
- `/plugin update sdd@dotfiles` 를 실행하고 새 세션을 연다
