---
name: spec-build-artifact
description: PR·이슈·브랜치·계획을 조사해 검토자가 읽고 결정할 검토용 스펙을 공유 가능한 문서(Claude Docs artifact)로 만들어요. 문서 뼈대를 먼저 띄우고 절 단위로 채우며, 플로우차트는 편집 가능한 다이어그램으로 그려요. spec-build 의 기본 형식이에요. 트리거 - `/spec-build-artifact {요청}`, `/spec-build {요청}`, "스펙을 문서로 만들어줘", "검토용 스펙 공유 문서"
---

# spec-build-artifact — 검토용 스펙, 공유 문서

무엇을 조사하고 어떤 절을 쓰는지는 `~/.claude/skills/spec-build/references/spec-contract.md` 를 따른다. 이 스킬은 "문서를 어떤 순서로 만드는가" 만 정한다.

## 도구 확인

- Claude Docs 도구(`mcp__claude_ai_Claude_Docs__batch` 등)가 있으면 아래 「Docs 경로」
- 없으면 「대체 경로」
- 문서 도구 스킬(`anthropic-skills:docs` 등)이 목록에 있으면 첫 문서 호출 전에 불러온다. 그 스킬과 연결 도구의 지시가 이 문서보다 우선한다

## Docs 경로

순서가 중요하다. **문서 뼈대가 조사보다 먼저다.** 마스터가 문서가 채워지는 것을 지켜보게 하기 위해서다.

- **뼈대 먼저.** 계약서를 다시 읽거나 조사하기 전에, 첫 문서 호출로 뼈대를 만든다: `batch(container={"kind":"project","create":{"name":"{대상} 검토 스펙","doc":{blocks, markdown}}}, batch=[])`
    - 머리: 제목, `<?claude block asof?> · <?claude block me?>` (오늘 날짜 칩 · 마스터 멘션)
    - 계약서 절마다 `pending` 블록 하나. `intent` 에 절 이름과 들어갈 내용을 적는다
    - 플로우차트 절의 intent 에는 "다이어그램" 이라고 적는다
- **바로 연다.** 응답의 링크를 `Artifact(action="open", url=...)` 로 연다. 같은 메시지에 `guide(["topic.index"])`, `guide(["topic.diagram"])` 를 각각 부른다
- **조사.** 계약서의 「입력 해석」「조사 절차」대로 조사한다. 오래 걸리면 채팅에 "지금 {무엇} 확인 중" 한 줄을 남긴다
- **절마다 채운다.** 절 하나 = `update` 호출 하나. 그 절의 `pending` 블록을 `replace` 로 `## {헤딩}` + 본문으로 바꾼다 (`"as":"markdown"`). 글로 된 절을 먼저 순서대로, 플로우차트는 마지막에
- **플로우차트.** `topic.diagram` 규칙대로 widget 노드(SVG 모듈) + embed 를 한 `batch` 로 만든다. 제목은 결론 문장, 실패 경로는 `--cds-chart-status-critical`, 강조는 하나
- **눈으로 확인.** `read(ref=widget, engine="widget", payload={"kind":"screenshot"})` 로 렌더를 보고, 선이 글자를 가로지르거나 글자가 상자를 넘으면 고친다
- **끝맺음.** 계약서의 「끝맺음」을 따르되, 첫 줄은 문서 링크와 "바로 고치거나 댓글을 달 수 있다" 는 한 줄

## 대체 경로 (Docs 도구가 없을 때)

- `Artifact(action="quickstart", intent="document")` 로 먼저 쓸 수 있는 문서 타입을 확인하고, 그 결과의 지시를 따른다
- 문서 타입이 없으면 `artifact-design` 스킬을 불러와 HTML 한 페이지로 만든다. 플로우차트는 인라인 SVG(`artifact-diagramming` 스킬)로 그린다
- 둘 다 안 되면 `spec-build-md` 로 넘기고, 그 사실을 한 줄로 알린다

## 하지 않는 것

- 조사를 다 마친 뒤 문서를 한 번에 쓰지 않는다. 마스터가 빈 화면을 오래 보게 된다
- 문서 내용을 채팅에 다시 늘어놓지 않는다
