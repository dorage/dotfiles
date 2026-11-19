# sdd

스펙 주도 개발(SDD) 스킬 묶음이다.

- `/sdd:draft` — 구현 전 요구사항 문서(requirements.md)
- `/sdd:persona-review` — requirements.md 의 참여자마다 에이전트를 띄워 빠진 과정을 찾아 같은 문서에 보강. 참여자가 확정되면 draft 가 부른다
- `/sdd:design` — requirements.md 를 받아 설계 문서(design.md)
- `/sdd:flow` — requirements.md 를 받아 pug-frame 와이어프레임 전에 확인할 화면흐름 문서(flow.md). 흐름별 mermaid 흐름도와 화면별 변경 표
- `/sdd:task` — requirements.md 와 design.md 를 받아 구현 계획 문서(tasks.md)
- `/sdd:brief-dev` — requirements.md 에서 마커를 걷어 낸 개발자용 기획 문서(brief-dev.md)
- `/sdd:brief-nondev` — requirements.md 를 비개발자도 읽게 바꾼 기획 문서(brief-nondev.md)
- `/sdd:quick` — 작은 작업의 스펙과 설계를 채팅 답 하나로
- `/sdd:bdd` — requirements.md 경로를 주거나 requirements.md 만 있으면 정해진 인수 조건을 scenarios.md 의 gherkin 코드 블록으로(미결은 「미결 사항」에), 「완성」 design.md 도 있으면 E2E·통합 인수 조건을 Gherkin 시나리오(features/*.feature)
- `/sdd:setup` — `~/.sdd/{리포지토리 이름}/` 보관 폴더와 윤문 플러그인(`humanize-korean@im-not-ai`) 준비

문서를 쓰는 아홉 스킬이 함께 따르는 공용 포맷(결정·마커·답 반영·저장 위치·윤문)은 `references/spec-format.md` 한 곳에 있다. 단계마다 결과물 모양(절 구성·템플릿·완성 조건)은 `references/{스킬 이름}.md` (`draft`·`persona-review`·`design`·`flow`·`task`·`quick`·`bdd`)에 있고, 두 brief 스킬의 변환 규칙은 `references/brief-format.md` 에 있다. SKILL.md 에는 쓰는 과정만 둔다.

- 어떤 명령을 어떤 순서로 쓰는지: [WORKFLOW.md](WORKFLOW.md)
- 결과물이 어디에 남고 서로 무엇을 읽는지: [OUTPUT.md](OUTPUT.md)

## 고친 뒤 반영하기

- `.claude-plugin/plugin.json` 의 `version` 을 올린다
    - 문장만 고쳤으면 셋째 자리 (0.1.0 → 0.1.1)
    - 스킬을 더하거나 빼거나 이름을 바꿨으면 둘째 자리 (0.1.1 → 0.2.0)
- `/plugin update sdd@dotfiles` 를 실행하고 새 세션을 연다

## 평가

스킬을 고치거나 버전을 올렸으면 `npx tsx claude-plugins/sdd/evals/run.ts` 로 스킬마다 결과물이 포맷 규칙을 지키는지 재고, 이전 버전보다 나빠졌는지 확인한다. 돌리는 법과 판정 규칙은 [evals/README.md](evals/README.md) 에 있다.
