---
description: 개발팀 PO 보조 — Notion 스프린트/백로그 운영. sprint init {1~4} / sprint plan {1~4} / sprint update / sprint report
argument-hint: sprint init {1~4} | sprint plan {1~4} | sprint update | sprint report
---

PO(Product Owner) 보조 커맨드예요. 입력 인자: `$ARGUMENTS`

먼저 `po` 스킬을 따라요 — 대상 Notion 리소스 ID·속성 매핑·스프린트 규칙·안전 규칙이 모두 거기 있어요. Notion 조작은 `notion` 스킬(`ntn` CLI)에 의존하고, **작업 전 `ntn whoami` 로 인증을 확인**해요.

`$ARGUMENTS` 를 파싱해 서브커맨드로 분기해요:

- `sprint init {N}` (N=1~4) → `po` 스킬의 **스프린트 생성** 절차. 가장 가까운 다가오는 월요일부터 N주간(월~일) **빈 스프린트**(제목+기간)를 스프린트 DB 에 생성.
- `sprint plan {N}` (N=1~4) → `sprint-plan` 스킬. 스프린트를 만들고 **백로그까지 채워요** — 이번 주 회고와 미완료 백로그를 근거로 이월 항목 생성, 제품 백로그 이동, 신규 항목 생성(한 건씩 확인), 스코어링, 용량 점검, 제목 갱신.
- `sprint update` → `po` 스킬의 **스프린트 제목 정리** 절차. 어떤 스프린트인지 먼저 물어보고, 연결된 백로그를 근거로 한 줄 제목을 지어 교체.
- `sprint report` → `sprint-report` 스킬. 지난 스프린트에서 한 일과 이번 스프린트에서 할 일을 작업자별로 요약한 브리핑을 이번 주 스프린트 페이지 최상단에 작성.
- 인자가 없거나 위에 해당하지 않으면 → 무엇을 하려는지 짧게 되묻고, 사용 가능한 서브커맨드(`sprint init {1~4}`, `sprint plan {1~4}`, `sprint update`, `sprint report`)를 안내. 임의로 실행하지 않아요.

`init` 과 `plan` 은 다른 커맨드예요. "스프린트 만들어줘"만이면 `init`, "백로그도 채워줘 / 회고 보고 계획 세워줘"가 붙으면 `plan` 이에요. 애매하면 물어봐요.

페이지 생성·제목 교체 같은 쓰기 작업은 대상 ID 와 부모를 스킬의 규칙과 대조하고, 애매하면 실행 전 확인해요.
