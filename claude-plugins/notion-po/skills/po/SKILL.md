---
name: po
description: 개발팀 PO(Product Owner) 보조 — Notion 의 개발 스크럼/스프린트/백로그/에픽 DB 를 다뤄요. 스프린트 생성·정리, 백로그 기반 스프린트 제목 작성 등. `/po sprint init {1~4}`, `/po sprint update` 같은 `/po ...` 커맨드나 "이번 스프린트 만들어줘 / 스프린트 제목 정리해줘" 같은 요청으로 트리거해요. Notion 조작은 [[notion]] 스킬(`ntn` CLI)에 의존해요.
---

# 개발팀 PO 보조 (Notion)

Circularlabs 개발팀의 스크럼 운영을 Notion 에서 보조하는 skill 이에요. `ntn` CLI 로 스프린트·백로그·에픽 DB 를 읽고 써요. Notion CLI 사용법·인증·안전 규칙은 [notion 스킬](../notion/SKILL.md) 을 따라요 — **작업 전 `ntn whoami` 로 인증부터 확인**해요.

> **참조 문서**: 스크럼 운영 원칙(스프린트 이벤트, 백로그/에픽/스파이크, WSJF 우선순위, 벨로시티 용량계획, 긴급 건·우선순위 개입 대응)은 [스크럼 실전 플레이북](../../references/scrum-playbook.md) 을 단일 출처로 참고해요. "왜 이렇게 하나 / 어떤 순서로 계획하나" 를 판단할 때 이 문서를 근거로 삼아요. 단, 실제 Notion 척도는 `1/2/3/5/8` 로, 플레이북의 `13/20` 은 쓰지 않고 그 이상은 작업 분할로 처리해요.

## 대상 Notion 리소스 (단일 출처)

| 이름 | 종류 | ID |
| :-- | :-- | :-- |
| 개발 스크럼 | 페이지 (스프린트 DB 부모) | `3a3f68d9-4082-8096-a1af-dcf7797ef1d7` |
| 스프린트 | 데이터베이스 | `3a3f68d9-4082-8084-9813-c8e2b5eb36a1` |
| 스프린트 | **data source** (쿼리/생성용) | `3a3f68d9-4082-807e-8a43-000b9965f503` |
| 백로그 | 데이터베이스 | `1d1f68d9-4082-8235-9889-014a90701890` |
| 백로그 | **data source** | `a07f68d9-4082-8359-9579-07c5578db49e` |
| 에픽 | 데이터베이스 | `741f68d9-4082-8213-9f32-01f1bd372da3` |
| 에픽 | **data source** | `cdff68d9-4082-82aa-a99b-878327253130` |

> API 호출(쿼리·페이지 생성)에는 **data source ID** 를 써요. database ID 로는 쿼리가 안 돼요. ID 가 바뀐 것 같으면 `ntn datasources resolve <database-id>` 로 다시 확인해요.

> **⚠️ 실행 주의 (검증됨)**
> - `ntn api` / `ntn datasources` / `ntn pages` 를 **비대화(스크립트) 환경**에서 호출할 땐 반드시 stdin 을 닫아요: 명령 끝에 `< /dev/null`. 없으면 CLI 가 stdin 바디를 기다리며 **멈춰요(hang)**.
> - 쓰기(`POST`/`PATCH`) 바디에 한글이 들어가면 셸 이스케이프 사고를 피하려고 **임시 파일에 JSON 을 쓰고 `-d @<path>`** 로 넘겨요.
> - 쓰기 호출엔 타임아웃(`timeout 60 ...`)을 걸어 무한 대기를 막아요.

### 스프린트 DB 속성

| 속성 | 타입 | 비고 |
| :-- | :-- | :-- |
| `이름` | title | 스프린트 제목 |
| `기간` | date (범위) | `start`~`end` |
| `백로그` | relation → 백로그 | dual property `⚡ 스프린트` |
| `WIP` | formula | 연결된 백로그 스토리포인트 합(취소 제외) |
| `생성일` | created_time | |

### 백로그 DB 속성

| 속성 | 타입 | 비고 |
| :-- | :-- | :-- |
| `작업 이름` | title | |
| `⚡ 스프린트` | relation → 스프린트 | 소속 스프린트 |
| `에픽` | relation → 에픽 | |
| `상태` | status | `제품`·`스프린트`·`진행 중`·`스테이징`·`완료`·`취소` |
| `우선순위` | formula | |
| `스토리포인트` | formula | |
| `비즈니스가치`·`긴급도`·`위험도`·`작업크기` | select | `1`·`2`·`3`·`5`·`8` |
| `가치판단` | rich_text | 위 네 점수의 근거 서술 ([backlog-scoring](../backlog-scoring/SKILL.md) 형식) |
| `지연사유` | rich_text | 이월 시 "왜 못 끝냈는지 + 어디로 이월했는지" — 본문 블록이 아니라 이 속성에 적어요 |
| `긴급` | checkbox | |
| `기간` | date | |
| `작업자` | people | 신규 생성 시 Notion user ID 가 필요해요. 기존 백로그의 `작업자` 값에서 이름→ID 맵을 만들어요 |

## 스프린트 제목 형식

스프린트 `이름` 은 다음 형식을 따라요 (단일 출처 — init placeholder 와 update 결과 모두 이 형식):

```
[{시작일 YYMMDD}-{종료일 YYMMDD}]{백로그들 요약}
```

- 날짜는 스프린트 `기간` 속성의 start/end 를 `YYMMDD` 로 줄여요. 구분자는 하이픈(`-`), 닫는 대괄호 뒤 공백 없음.
- 예: `[260727-260803]카페 선결제·EasyPay 도입과 매출·정산 현황 개선`

## 백로그 이월 규칙

스프린트가 끝났는데 완료되지 못한 백로그를 다룰 때의 규칙이에요. "이 백로그 다음 스프린트로 옮겨줘" 같은 요청을 받으면 그대로 옮기지 말고 이 규칙을 따라요:

1. **이전 스프린트의 백로그는 옮기지 않아요** — 이전 주의 스프린트에 포함되어 있던 백로그의 `⚡ 스프린트` relation 을 다른 스프린트로 바꾸지 않아요. relation 은 1개 제한이라 옮기면 원 스프린트의 WIP 기록이 사라져요.
2. **미완료 작업은 신규 백로그로 이월해요**:
   - 완료되지 못한 백로그의 **`지연사유` 속성**에 왜 완료하지 못했는지와 어디로 이월했는지를 적어요.
   - 완료되지 못한 작업 내용으로 **신규 백로그를 만들어** 새 스프린트에 연결해요 (`⚡ 스프린트` relation). 신규 항목 본문에는 `## 참고` 로 원 항목 링크를 남겨요.

미완료 상태별 기본 처리는 이래요:

| 상태 | 처리 |
| :-- | :-- |
| `스테이징` | **이월하지 않아요.** 검증만 남은 단계라 원 스프린트에서 마무리하는 게 팀 전례예요. |
| `진행 중` | **잔여만 분리**해 신규 백로그를 만들고 [backlog-scoring](../backlog-scoring/SKILL.md) rubric 으로 재스코어링해요. |
| `스프린트`(미착수) | 값(점수 4종·가치판단·에픽·작업자)을 **그대로 복제**해요. |

사용자가 규칙에 어긋나는 이동을 요청하면 이 규칙을 알리고 이월(지연사유 + 신규 백로그) 방식으로 진행할지 확인해요.

## 커맨드 라우팅

`/po` 커맨드는 `$ARGUMENTS` 의 첫 토큰들로 서브커맨드를 가려요.

- `sprint init {N}` → [스프린트 생성](#스프린트-생성--sprint-init-n) — 빈 스프린트(제목+기간)만 만들어요.
- `sprint plan {N}` → [sprint-plan 스킬](../sprint-plan/SKILL.md) — 스프린트를 만들고 **백로그까지 채워요**. 이번 주 회고와 미완료 백로그를 근거로 이월·제품이동·신규생성·스코어링·용량점검·제목까지.
- `sprint update` → [스프린트 제목 정리](#스프린트-제목-정리--sprint-update)
- `sprint report` → [sprint-report 스킬](../sprint-report/SKILL.md) — 지난/이번 스프린트를 작업자별로 요약한 브리핑을 이번 주 스프린트 페이지 최상단에 작성.
- 그 외/모호 → 무엇을 원하는지 짧게 되물어요. 임의 실행하지 않아요.

> `init` 과 `plan` 을 헷갈리지 않아요. 사용자가 "스프린트 만들어줘"라고만 하면 빈 스프린트(`init`)를, "백로그도 채워줘 / 회고 보고 계획 세워줘"가 붙으면 `plan` 이에요. 애매하면 물어봐요.

---

## 스프린트 생성 — `sprint init {N}`

**가장 가까운 (다가오는) 월요일부터 N주간** 진행할 스프린트를 스프린트 DB 에 새로 만들어요.

### 규칙 (사용자 확정)

- **N**: `1`~`4` 정수. 벗어나면 실행하지 말고 사용자에게 알려요.
- **시작일**: 오늘 이후 가장 가까운 월요일. **오늘이 월요일이면 오늘**. → `start = today + ((0 - weekday) % 7)` (Mon=0)
- **종료일**: `start + (N*7 - 1)`일 — 월~일 전체를 포함한 N주. (N=2, 시작 월 → 2주 뒤 일요일)
- **이름(placeholder)**: `"[{시작일 YYMMDD}-{종료일 YYMMDD}]스프린트"`. 이후 `sprint update` 로 백로그 기반 제목으로 교체 — 최종 제목 형식은 [스프린트 제목 형식](#스프린트-제목-형식) 참고.

> **알려진 편차**: 라이브 보드의 기존 스프린트는 월~월(예: `2026-07-27 ~ 2026-08-03`, 8일)로 종료일을 다음 주 월요일에 두는 관행이 관찰됐어요. 현재 규칙은 사용자가 명시 확정한 **월~일(N*7일)** 이에요. 팀 관행에 맞추려면(`월~월`) 종료일을 `start + N*7`일로 바꾸면 돼요 — 실행 전 어긋난다고 느끼면 사용자에게 확인해요.

### 절차

1. **N 검증** — `1~4` 아니면 중단·안내.
2. **날짜 계산** — 실제 시스템 날짜로 계산해요 (하드코딩 금지):

   ```bash
   python3 - "$N" <<'PY'
   import datetime as dt, sys
   n = int(sys.argv[1])
   today = dt.date.today()
   start = today + dt.timedelta(days=(0 - today.weekday()) % 7)
   end = start + dt.timedelta(days=n*7 - 1)
   print(start.isoformat(), end.isoformat())
   print(start.strftime('%y%m%d'), end.strftime('%y%m%d'))  # 제목용 YYMMDD
   PY
   ```

3. **중복 확인(안전망)** — 같은 시작일의 스프린트가 이미 있는지 가볍게 확인. 있으면 만들지 말고 사용자에게 알리고 계속할지 물어요:

   ```bash
   ntn datasources query 3a3f68d9-4082-807e-8a43-000b9965f503 --json < /dev/null \
     | python3 -c "import sys,json; d=json.load(sys.stdin); print('\n'.join((p['properties'].get('기간',{}).get('date') or {}).get('start','') or '' for p in d.get('results',[])))"
   ```

4. **생성** — data source 를 부모로 페이지 생성. 한글 바디는 임시 파일에 쓰고 `-d @file`, stdin 은 닫아요:

   ```bash
   cat > /tmp/sprint_body.json <<JSON
   {
     "parent": {"type": "data_source_id", "data_source_id": "3a3f68d9-4082-807e-8a43-000b9965f503"},
     "properties": {
       "이름": {"title": [{"text": {"content": "[260727-260809]스프린트"}}]},
       "기간": {"date": {"start": "2026-07-27", "end": "2026-08-09"}}
     }
   }
   JSON
   timeout 60 ntn api /v1/pages -X POST -d @/tmp/sprint_body.json < /dev/null
   ```

   `이름`·`기간` 값은 2단계 결과로 치환해요. 응답 `object` 가 `error` 면 중단하고 `code`/`message` 를 보고해요. 본문 블록은 만들지 않아요(속성만).

5. **보고** — 생성된 스프린트 제목·기간·URL(응답 `url`)을 사용자에게 알려요.

### 주의

- 생성은 되돌리기 쉬워요(`ntn pages trash <page-id>`). 하지만 부모 data source 는 위 스프린트 DS 로 고정 — 다른 곳에 만들지 않아요.
- 백로그 연결·상태 설정은 이 커맨드의 책임이 아니에요. 빈 스프린트(제목+기간)만 만들어요.

---

## 스프린트 제목 정리 — `sprint update`

업데이트할 스프린트를 **먼저 물어보고**, 그 스프린트에 연결된 백로그들을 바탕으로 스프린트를 한 줄로 설명하는 제목을 지어 `이름` 을 교체해요.

### 절차

1. **스프린트 선택** — 스프린트 목록을 뽑아 사용자에게 물어요 (`AskUserQuestion` 권장). 각 항목은 현재 `이름` + `기간` 으로 표시:

   ```bash
   ntn datasources query 3a3f68d9-4082-807e-8a43-000b9965f503 --json < /dev/null \
     | python3 -c "
   import sys,json
   for p in json.load(sys.stdin).get('results',[]):
       pr=p['properties']
       t=''.join(x['plain_text'] for x in pr.get('이름',{}).get('title',[]))
       d=pr.get('기간',{}).get('date') or {}
       print(p['id'], '|', t, '|', d.get('start'),'~',d.get('end'))
   "
   ```

   최근(진행/예정) 스프린트가 여러 개면 기간 기준으로 정렬해 보여줘요. 사용자가 자연어로 "이번 스프린트"라고 하면 오늘 날짜가 `기간` 에 드는 스프린트를 후보 1순위로.

2. **백로그 수집** — 선택된 스프린트에 연결된 백로그를 relation 필터로 조회해요:

   ```bash
   ntn datasources query a07f68d9-4082-8359-9579-07c5578db49e \
     --filter '{"property":"⚡ 스프린트","relation":{"contains":"<SPRINT_PAGE_ID>"}}' --json < /dev/null \
     | python3 -c "
   import sys,json
   for p in json.load(sys.stdin).get('results',[]):
       pr=p['properties']
       name=''.join(x['plain_text'] for x in pr.get('작업 이름',{}).get('title',[]))
       status=(pr.get('상태',{}).get('status') or {}).get('name')
       print(f'- [{status}] {name}')
   "
   ```

   `취소` 상태 항목은 제목 생성에서 제외해요. 필요하면 각 백로그의 `에픽` relation 도 함께 봐서 공통 테마를 파악해요 (에픽 이름은 에픽 DS 를 조회하거나 relation 의 페이지를 `ntn pages get` 으로 확인).

3. **제목 생성** — 수집한 백로그 작업들을 관통하는 **한 줄 한국어 요약**을 짓고, [스프린트 제목 형식](#스프린트-제목-형식)에 맞춰 날짜 접두를 붙여요. 날짜는 해당 스프린트의 `기간` 속성에서 가져와요. 요약 원칙:
   - 개별 작업 나열이 아니라 스프린트의 **테마·목표**를 요약 (예: `[260727-260803]카페 선결제·EasyPay 도입과 매출·정산 현황 개선`).
   - 요약 부분은 30자 내외, 명사구 중심. 백로그가 하나의 에픽에 쏠려 있으면 그 에픽 주제를 제목의 축으로.
   - 백로그가 비어 있으면 제목을 억지로 만들지 말고 사용자에게 "연결된 백로그가 없어요"라고 알려요.
   - 제목은 추측이 아니라 **실제 조회한 백로그 내용**에 근거해요.

4. **확인 후 교체** — 만든 제목을 사용자에게 보여주고(대화형이면 승인 받고), `이름` 을 갱신해요. 기존 제목은 로그로 남겨요(되돌림 대비):

   ```bash
   cat > /tmp/sprint_title.json <<JSON
   {"properties": {"이름": {"title": [{"text": {"content": "<새 제목>"}}]}}}
   JSON
   timeout 60 ntn api /v1/pages/<SPRINT_PAGE_ID> -X PATCH -d @/tmp/sprint_title.json < /dev/null
   ```

5. **보고** — `이전 제목 → 새 제목`, 반영된 스프린트 URL, 근거로 삼은 백로그 개수를 알려요.

### 주의

- `이름` 교체는 기존 제목을 덮어써요. 3단계에서 반드시 실제 백로그를 조회해 근거를 만들고, 대화형이면 교체 전에 새 제목을 보여줘 확인받아요.
- 백로그 상태/포인트는 건드리지 않아요. 이 커맨드는 스프린트 `이름` 만 갱신해요.

---

## 확장 여지

`sprint start/close`(상태 전환), `backlog groom`(우선순위 재정렬), `standup`(진행 요약) 등은 아직 없어요. 요청이 오면 기존 커맨드와 같은 패턴(조회 → 근거 → 확인 → 쓰기)으로 추가해요.
