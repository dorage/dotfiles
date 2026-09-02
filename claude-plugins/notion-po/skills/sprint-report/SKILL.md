---
name: sprint-report
description: 이번 주 스프린트 페이지 최상단에 보고용 브리핑을 써요 — 지난 스프린트에서 누가 어떤 작업을 했는지(회고/리뷰·백로그 상태 근거)와 이번 스프린트에서 누가 어떤 작업을 할지 요약. `/po sprint report` 커맨드나 "스프린트 브리핑 써줘 / 지난 스프린트 요약해서 이번 스프린트 페이지에 올려줘" 같은 요청으로 트리거해요. Notion 조작은 [[notion]] 스킬, 스프린트/백로그 DB 정보는 [[po]] 스킬을 따라요.
---

# 스프린트 브리핑 (보고용 요약)

이번 주 스프린트 페이지 **최상단**에 보고용 브리핑을 만드는 skill 이에요. 지난 스프린트에서 **누가 어떤 작업을 했는지**, 이번 스프린트에서 **누가 어떤 작업을 할지**를 한눈에 파악할 수 있게 정리해요.

- 스프린트/백로그 data source ID·속성 맵은 [po 스킬](../po/SKILL.md) 의 표를 단일 출처로 써요.
- `ntn` CLI 사용법·인증·**비대화 호출 주의(`< /dev/null`, 한글 바디는 `-d @file`, `timeout`)** 는 [notion 스킬](../notion/SKILL.md) 을 따라요. **작업 전 `ntn whoami` 로 인증부터 확인**해요.
- 스프린트 data source: `3a3f68d9-4082-807e-8a43-000b9965f503` / 백로그 data source: `a07f68d9-4082-8359-9579-07c5578db49e`

> **⚠️ 절대 `ntn pages edit` 를 쓰지 않아요.** 스프린트 페이지에는 회의노트(meeting-notes) 블록이 있어서 전체 덮어쓰기가 회의 기록을 망가뜨릴 수 있어요. 삽입은 반드시 blocks API(`/v1/blocks/.../children`)로만 해요.

## 산출물 형식

브리핑은 아래 형식의 마크다운으로 만들어요. **`## 📋 스프린트 브리핑` heading 으로 시작하고 divider(`---`)로 끝나요** — 이 두 개가 브리핑 블록 범위를 식별하는 마커라서(재실행 시 교체 기준) 생략하면 안 돼요.

```markdown
## 📋 스프린트 브리핑 (YYYY-MM-DD)
> **지난 스프린트** [260727-260803]카페 선결제·EasyPay 도입과 매출·정산 현황 개선 — 완료 6건 · 이월 5건 · 취소 1건
> **이번 스프린트** [260803-260809]선결제 어드민·API 마무리와 채널 와이어프레임, EasyPay 검증 — 백로그 14건 · 20pt

### 지난 스프린트에서 한 일
- **이강현** — 매출현황 UI/UX 개선 ✅ · 공급사 용기주문 수정 권한 ✅ · 정산과정 개편은 범위 확대로 취소 후 스파이크+스토리로 분할 이월
- **박은지** — 선결제 카페 관리 페이지 ✅(매출 탭만 이월) · 웹어드민 카페 선결제 페이지 미착수 → 이월
- **박시영** — EasyPay 전환 백엔드 완료, 웹 결제 경로·실거래 테스트 이월

### 특이사항 (회고·리뷰)
- 백로그를 너무 크게 잡아 분할 필요 — 정산과정 개편(8pt)이 대표 사례
- KICC 스테이징 이전 대기로 결제 API 일부 지연

### 이번 스프린트에서 할 일
- **이강현** — GitHub Actions env 자동화(2pt) · [스파이크] 정산 플로우 재점검
- **박은지** — 웹어드민 카페 선결제 페이지(2pt) · 선결제 회사 페이지(2pt) · 카페 매출 탭(1pt)
- **정순재** — 선결제 사용내역·관리 API(2pt)
- **정순재·남기덕 (공동)** — 채널별 선결제 유즈케이스·와이어프레임(포스/키오스크/아란테 앱)

---
```

### 작성 원칙 (보고용)

- **사람 중심, 연속 배치**: 작업자별 한 줄. 이름은 `**굵게**`, 작업들은 `·` 로 연결. **같은 사람의 작업은 반드시 한 곳에 연속으로 모아요** — 상태·주제별로 흩뿌리지 않아요. 여러 명이 붙은 작업은 각자 줄에 중복하지 말고 `- **정순재·남기덕 (공동)** — ...` 처럼 공동 그룹 줄로 묶어요. 작업자가 빈 항목은 마지막에 `- **미배정** — ...` 으로 모아요.
- **이름은 한국식 표기 (사용자 확정)**: Notion people 값이 "이름 성" 서구식이면 "성이름" 한국식으로 바꿔 써요 — "강현 이"→"이강현", "은지 박"→"박은지", "기덕 남"→"남기덕". 공백 없는 이름(박시영, 정순재)은 그대로. 어느 쪽인지 애매한 이름은 바꾸지 말고 그대로 써요.
- **작업 이름은 요지만**: 백로그 제목의 "~하기 위해," 같은 목적절은 빼고 핵심 행위만 남겨요 (예: "웹어드민에 카페 선결제 페이지를 추가한다" → "웹어드민 카페 선결제 페이지").
- **한 일의 상태 표기**: 완료 ✅, `스테이징` 은 "스테이징 반영", 미완료는 "→ 이월"(이월/취소 기록과 교차 확인), `취소` 는 사유 한 줄과 함께.
- **특이사항은 2~4개**: 회고/리뷰 요약에서 보고 대상이 알아야 할 성과·이슈·결정만 골라요. 회고/리뷰가 비어 있으면 이 절을 빼요 — 백로그 상태만으로 지어내지 않아요.
- **근거는 실제 조회 데이터만**: 조회한 백로그·회고 내용에 없는 서술을 만들지 않아요. 전체 분량은 20줄 내외.
- **문법 제약**: 아래 블록 변환기가 지원하는 문법만 써요 — `##`, `###`, `- `(1단, 들여쓰기 금지), `> `, `**굵게**`, `---`. 링크·표·중첩 목록은 쓰지 않아요.

## 절차

### 1. 스프린트 식별

이번/지난 스프린트를 실제 날짜로 골라요. 스프린트 기간이 월~월로 겹치는 관행이 있어서(경계일엔 오늘이 두 스프린트에 포함) **이번 = 오늘을 포함하는 것 중 시작일이 가장 최근**, **지난 = 이번보다 먼저 시작한 것 중 종료일이 가장 최근**으로 판정해요:

```bash
ntn datasources query 3a3f68d9-4082-807e-8a43-000b9965f503 --json < /dev/null | python3 -c "
import sys,json,datetime as dt
today=dt.date.today().isoformat()
rows=[]
for p in json.load(sys.stdin).get('results',[]):
    pr=p['properties']
    t=''.join(x['plain_text'] for x in pr.get('이름',{}).get('title',[]))
    d=pr.get('기간',{}).get('date') or {}
    if d.get('start') and d.get('end'): rows.append((d['start'],d['end'],p['id'],t))
cur=max([r for r in rows if r[0]<=today<=r[1]], default=None, key=lambda r:r[0])
last=max([r for r in rows if cur and r[0]<cur[0]], default=None, key=lambda r:r[1])
print('이번:',cur); print('지난:',last)
"
```

둘 중 하나라도 못 찾거나 판정이 애매하면(스프린트 공백기 등) 임의로 고르지 말고 후보를 보여주며 사용자에게 확인해요 (`AskUserQuestion` 권장).

### 2. 근거 수집

**(a) 지난 스프린트 페이지 본문** — 회고/리뷰 회의노트의 `<summary>` 와 `이월/취소 기록` 절이 핵심 근거예요:

```bash
ntn pages get <LAST_SPRINT_PAGE_ID> < /dev/null
```

- `## 스프린트 리뷰` / `## 스프린트 회고` meeting-notes 블록의 `<summary>` → 완료/진행/잔여 현황, 특이사항.
- `## 이월/취소 기록` 절 → 이월·취소 항목과 사유.
- summary 가 `<empty-block/>` 뿐이면 회고 근거 없음으로 취급하고 (b) 백로그 상태로만 판단해요.

**(b) 양쪽 스프린트의 백로그** — 상태·작업자·포인트를 뽑아요 (지난/이번 각각 `<SPRINT_PAGE_ID>` 만 바꿔 실행):

```bash
ntn datasources query a07f68d9-4082-8359-9579-07c5578db49e \
  --filter '{"property":"⚡ 스프린트","relation":{"contains":"<SPRINT_PAGE_ID>"}}' --json < /dev/null \
  | python3 -c "
import sys,json
for p in json.load(sys.stdin).get('results',[]):
    pr=p['properties']
    name=''.join(x['plain_text'] for x in pr.get('작업 이름',{}).get('title',[]))
    status=(pr.get('상태',{}).get('status') or {}).get('name')
    people=', '.join(u.get('name','?') for u in pr.get('작업자',{}).get('people',[]))
    sp=(pr.get('스토리포인트',{}).get('formula') or {}).get('number')
    print(f'[{status}] {name} | 작업자: {people or \"-\"} | {sp}pt')
"
```

이번 스프린트에 연결된 백로그가 없으면 브리핑을 만들지 말고 사용자에게 알려요 (스프린트 계획이 아직 없는 상태).

### 3. 브리핑 작성

[산출물 형식](#산출물-형식)에 맞춰 마크다운을 만들어요. 헤더의 건수(완료·이월·취소)는 (b) 상태 집계로, 이월 여부는 (a) 이월/취소 기록과 교차 확인해요. 대화형이면 본문을 사용자에게 먼저 보여주고 승인받은 뒤 4단계로 가요.

### 4. 블록 변환

마크다운을 임시 파일(예: `/tmp/brief.md`)에 쓰고, Notion 블록 JSON 으로 변환해요. (변환기 스크립트는 heredoc = stdin 이라, 마크다운은 stdin 이 아니라 **파일 인자**로 넘겨요.)

```bash
python3 - /tmp/brief.md > /tmp/brief_blocks.json <<'PY'
import sys, json

def rt(text):
    out = []
    for i, seg in enumerate(text.split('**')):
        if seg:
            out.append({"type": "text", "text": {"content": seg},
                        "annotations": {"bold": i % 2 == 1}})
    return out

TYPES = [('### ', 'heading_3'), ('## ', 'heading_2'),
         ('- ', 'bulleted_list_item'), ('> ', 'quote')]
blocks = []
for line in open(sys.argv[1]).read().splitlines():
    s = line.strip()
    if not s:
        continue
    if s == '---':
        blocks.append({"type": "divider", "divider": {}})
        continue
    for prefix, typ in TYPES:
        if s.startswith(prefix):
            blocks.append({"type": typ, typ: {"rich_text": rt(s[len(prefix):])}})
            break
    else:
        blocks.append({"type": "paragraph", "paragraph": {"rich_text": rt(s)}})
json.dump({"children": blocks}, sys.stdout, ensure_ascii=False)
PY
```

블록이 100개를 넘으면 append API 가 거부해요 — 브리핑은 20줄 내외라 정상이면 도달하지 않아요. 넘었다면 분량부터 줄여요.

### 5. 최상단 삽입 (분기)

이번 스프린트 페이지의 기존 블록을 먼저 확인해요:

```bash
ntn api /v1/blocks/<THIS_SPRINT_PAGE_ID>/children < /dev/null
```

결과에 따라 세 갈래예요:

**(가) 본문이 비어 있으면** (새로 만든 스프린트의 기본 상태) — 그냥 append 하면 최상단이에요:

```bash
timeout 60 ntn api /v1/blocks/<THIS_SPRINT_PAGE_ID>/children -X PATCH -d @/tmp/brief_blocks.json < /dev/null
```

**(나) 첫 블록이 기존 브리핑이면** (heading 텍스트에 `스프린트 브리핑` 포함) — 재실행이에요. 기존 브리핑 범위 = 첫 블록부터 **첫 divider 블록까지**. 순서가 중요해요: **새 것을 먼저 넣고, 성공을 확인한 뒤 옛 것을 지워요** (중간에 실패해도 브리핑이 사라지지 않는 안전망):

```bash
# 1) 새 브리핑을 기존 브리핑 마지막 블록(divider) 뒤에 삽입
python3 -c "
import json
d=json.load(open('/tmp/brief_blocks.json')); d['after']='<기존 divider 블록 ID>'
json.dump(d,open('/tmp/brief_blocks.json','w'),ensure_ascii=False)
"
timeout 60 ntn api /v1/blocks/<THIS_SPRINT_PAGE_ID>/children -X PATCH -d @/tmp/brief_blocks.json < /dev/null

# 2) 응답이 정상이면(object=list) 기존 브리핑 블록들을 삭제
timeout 60 ntn api /v1/blocks/<기존 블록 ID> -X DELETE < /dev/null   # 범위 내 블록마다 반복
```

**(다) 본문에 다른 콘텐츠가 있는데 브리핑은 없으면** — Notion API 는 "첫 블록 앞" 삽입을 지원하지 않아요. 임의로 진행하지 말고 사용자에게 두 안을 제시해 골라요:
- 첫 블록 **뒤**에 삽입 (최상단은 아니지만 안전).
- 첫 블록이 문단/heading 같은 단순 블록이면: 브리핑+첫 블록 사본을 첫 블록 뒤에 삽입한 뒤 원본 첫 블록을 삭제해 최상단을 확보 (회의노트 등 특수 블록이면 이 방법은 못 써요).

### 6. 보고

브리핑이 반영된 스프린트 페이지 URL, 근거로 삼은 데이터(지난/이번 백로그 건수, 회고 요약 유무), (나) 경로였다면 교체된 블록 수를 사용자에게 알려요.

## 주의

- 쓰기 응답의 `object` 가 `error` 면 즉시 중단하고 `code`/`message` 를 보고해요. (나) 경로에서 삽입이 실패했으면 삭제 단계로 넘어가지 않아요.
- 백로그·스프린트 속성은 아무것도 바꾸지 않아요. 이 스킬은 이번 스프린트 페이지 **본문 블록 추가/교체**만 해요.
- 블록 삭제는 (나) 경로의 기존 브리핑 범위(첫 블록~첫 divider)에서만 해요. 범위 판정이 애매하면(divider 가 없거나 회의노트가 범위에 걸리면) 지우지 말고 사용자에게 확인해요.
- 작업자 이름은 [작성 원칙](#작성-원칙-보고용)의 한국식 표기 규칙만 적용하고, 그 외 임의로 줄이거나 별명으로 바꾸지 않아요. Notion 백로그 제목 등 원문 데이터의 이름 표기는 건드리지 않아요.
