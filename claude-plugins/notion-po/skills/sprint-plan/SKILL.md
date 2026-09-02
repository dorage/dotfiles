---
name: sprint-plan
description: 다음 스프린트를 만들고 백로그까지 채워요 — 이번 주 회고와 미완료 백로그를 근거로 이월 항목을 만들고, 회고 액션아이템을 기존 백로그와 대조해 제품→스프린트로 옮기거나 신규 생성한 뒤 스코어링·용량점검·제목까지 마무리. `/po sprint plan {1~4}` 커맨드나 "다음 주 스프린트 만들고 백로그도 채워줘 / 회고 보고 다음 스프린트 계획 세워줘" 같은 요청으로 트리거해요. Notion 조작은 [[notion]] 스킬, 스프린트/백로그 DB 정보는 [[po]] 스킬을 따라요.
---

# 스프린트 계획 (생성 + 백로그 구성)

빈 스프린트만 만드는 `sprint init` 과 달리, **다음 스프린트를 만들고 그 안의 백로그까지 채우는** skill 이에요. 근거는 두 가지뿐이에요 — 이번 주 스프린트 페이지의 **회고 회의노트**와 **백로그 DB 의 실제 상태**. 둘 다 조회하지 않고 항목을 지어내지 않아요.

- 스프린트/백로그/에픽 data source ID·속성 맵은 [po 스킬](../po/SKILL.md) 의 표를 단일 출처로 써요.
- 점수(작업크기·비즈니스가치·긴급도·위험도·가치판단)는 [backlog-scoring 스킬](../backlog-scoring/SKILL.md) 의 rubric 을 그대로 적용해요.
- 이월 판정은 [po 스킬의 백로그 이월 규칙](../po/SKILL.md#백로그-이월-규칙) 을 따라요.
- `ntn` CLI 사용법·인증은 [notion 스킬](../notion/SKILL.md). **작업 전 `ntn whoami` 로 인증부터 확인**해요.
- 스프린트 DS `3a3f68d9-4082-807e-8a43-000b9965f503` / 백로그 DS `a07f68d9-4082-8359-9579-07c5578db49e` / 에픽 DS `cdff68d9-4082-82aa-a99b-878327253130`

> **선행 관계**: 이 skill 은 스프린트를 **만들고 채워요**. 채운 결과를 사람이 읽을 브리핑으로 만드는 건 [sprint-report 스킬](../sprint-report/SKILL.md) 의 일이에요. 계획을 끝낸 뒤 브리핑까지 원하면 `sprint report` 를 이어서 돌려요.

---

## ⚠️ 실행 주의 (실측으로 확인됨)

이 네 가지를 어기면 조용히 틀린 결과가 나와요.

1. **쓰기 JSON 은 셸 heredoc 으로 만들지 않아요.** 한글·`·`·`—` 가 섞인 바디를 heredoc 으로 쓰면 깨져서 `error: Invalid JSON from --data` 가 나요. **Python 스크립트에서 `json.dump(..., ensure_ascii=False)` 로 임시 파일을 쓰고 `-d @<path>`** 로 넘겨요. 항목이 여러 건이면 아래 [드라이버 스크립트](#드라이버-스크립트-패턴)로 한 번에 처리해요.

2. **`datasources query` 는 반드시 페이지네이션해요.** 한 번 호출로 전부 오지 않아요(실측: 백로그 전체 72건이 여러 페이지로 나뉨). 응답의 `has_more` 가 `true` 면 `next_cursor` 를 `--start-cursor` 로 넘겨 다음 장을 받아요. **첫 장만 보고 "없다"고 판정하면 중복 항목을 새로 만들어 버려요.**

3. **비대화 호출은 `< /dev/null`, 쓰기는 `timeout 60`.** 없으면 CLI 가 stdin 을 기다리며 멈춰요.

4. **응답의 `object` 가 `error` 면 즉시 중단**하고 `code`/`message` 를 보고해요. 여러 건을 도는 루프에서는 실패 건을 표시하고 계속하되, 마지막 보고에 실패 목록을 반드시 넣어요.

---

## 절차

### 0. 인증·범위 확인

```bash
ntn whoami
```

인자 `N`(스프린트 주 수)을 확인해요. `1~4` 정수가 아니면 실행하지 말고 안내해요. 인자가 없으면 `1` 로 가정하지 말고 물어봐요.

### 1. 날짜 계산과 중복 확인

`sprint init` 과 동일한 규칙이에요 — 시작일은 오늘 이후 가장 가까운 월요일(오늘이 월요일이면 오늘), 종료일은 `start + (N*7 - 1)`일.

```bash
python3 - "$N" <<'PY'
import datetime as dt, sys
n = int(sys.argv[1])
today = dt.date.today()
start = today + dt.timedelta(days=(0 - today.weekday()) % 7)
end = start + dt.timedelta(days=n*7 - 1)
print(start.isoformat(), end.isoformat())
print(start.strftime('%y%m%d'), end.strftime('%y%m%d'))
PY
```

스프린트 DS 를 조회해 **같은 시작일의 스프린트가 이미 있는지** 확인해요. 있으면 만들지 말고 사용자에게 알리고 계속할지 물어요.

같은 조회로 **이번 주 스프린트**(오늘을 포함하는 것 중 시작일이 가장 최근)도 함께 골라둬요 — 2단계의 근거가 돼요. 판정이 애매하면(스프린트 공백기) 후보를 보여주며 확인해요.

> 기간·제목 없는 빈 스프린트 행이 보드에 남아 있을 수 있어요. 판정에서 제외하고, 보고에서 한 줄로 알려요. 임의로 지우지 않아요.

### 2. 스프린트 생성

data source 를 부모로 placeholder 제목의 빈 페이지를 만들어요. 제목은 `[{시작일 YYMMDD}-{종료일 YYMMDD}]스프린트`, 본문 블록은 만들지 않아요. 자세한 바디 형식은 [po 스킬의 스프린트 생성](../po/SKILL.md#스프린트-생성--sprint-init-n) 4단계와 같아요.

먼저 만들어 두는 이유는, 뒤이어 만들 백로그가 `⚡ 스프린트` relation 으로 이 페이지 ID 를 필요로 하기 때문이에요. 생성된 페이지 ID 를 기록해요.

### 3. 이번 주 회고 읽기

```bash
ntn pages get <THIS_SPRINT_PAGE_ID> < /dev/null
```

세 곳이 근거예요:

- **`## 백로그 회고` / `## 스프린트 리뷰` 의 meeting-notes `<summary>`** — 액션 아이템, 이슈, **"다음주 계획"** 절. 다음 스프린트 항목의 1차 출처예요.
- **`## 이월/취소 기록`** 절 (있으면) — 이미 처리된 이월 내역.
- **본문 상단 브리핑** (있으면) — 이번 주에 하기로 했던 일 목록.

`<summary>` 가 `<empty-block/>` 뿐이면 **회고 근거 없음**으로 취급해요. 이때는 백로그 상태만으로 이월 항목만 만들고, 신규 항목은 지어내지 말고 사용자에게 "회고가 비어 있어 신규 항목 근거가 없어요"라고 알린 뒤 직접 받아요.

### 4. 백로그 실태 조사

**(a) 이번 주 스프린트의 백로그** — 상태·작업자·점수를 뽑아요:

```bash
ntn datasources query a07f68d9-4082-8359-9579-07c5578db49e \
  --filter '{"property":"⚡ 스프린트","relation":{"contains":"<THIS_SPRINT_PAGE_ID>"}}' --json < /dev/null
```

**(b) 백로그 전체** — 중복 검사와 고아 항목 점검에 쓰니 **페이지네이션으로 전부** 받아요:

```bash
DS=a07f68d9-4082-8359-9579-07c5578db49e
CURSOR=""
for i in $(seq 1 12); do
  if [ -z "$CURSOR" ]; then
    timeout 120 ntn datasources query $DS --json < /dev/null > all_$i.json
  else
    timeout 120 ntn datasources query $DS --start-cursor "$CURSOR" --json < /dev/null > all_$i.json
  fi
  HAS=$(python3 -c "import json;print(json.load(open('all_$i.json')).get('has_more'))")
  CURSOR=$(python3 -c "import json;print(json.load(open('all_$i.json')).get('next_cursor') or '')")
  [ "$HAS" != "True" ] && break
  [ -z "$CURSOR" ] && break
done
```

이 덤프에서 세 가지를 뽑아요:

- **미완료 목록** — (a) 중 상태가 `완료`·`취소` 가 아닌 것 → 5단계 이월 판정 대상.
- **고아 항목** — 상태가 `완료`·`취소`·`제품` 이 아닌데 `⚡ 스프린트` 가 비어 있는 것. 보드 정합성 결함이라 **6단계 전에 사용자에게 알리고 처리**해요 (완료 처리·스프린트 연결·제품으로 되돌림 중 선택).
- **작업자 people ID** — 신규 백로그의 `작업자` 를 채우려면 Notion user ID 가 필요해요. 기존 백로그의 `작업자` 값에서 이름→ID 맵을 만들어요. 덤프에 없는 사람은 임의로 추측하지 말고 비워두고 사용자에게 물어요.

### 5. 이월 판정

미완료 항목마다 상태로 갈라요. **원본의 `⚡ 스프린트` relation 은 어떤 경우에도 바꾸지 않아요.**

| 상태 | 기본 처리 |
| :-- | :-- |
| `스테이징` | **이월하지 않아요.** 검증만 남은 단계라 원 스프린트에서 마무리하는 게 팀 전례예요. |
| `진행 중` | **잔여만 분리**해 신규 백로그를 만들고 재스코어링해요. 원본에는 `지연사유` 를 남겨요. |
| `스프린트`(미착수) | 값(점수 4종·가치판단·에픽·작업자)을 **그대로 복제**해 신규 백로그를 만들어요. |

- 잔여 범위는 **회고에서 근거를 찾아요**. 회고 액션아이템이 원본 한 건을 두 갈래로 쪼개고 있으면 두 건으로 나누는 게 맞아요 (실제 사례: "정산정보 수집·계산 로직" → "Toss 정산 불일치 수정" + "KICC 정산 추가"). 근거가 없으면 지어내지 말고 사용자에게 물어요.
- 신규 항목 본문에는 **원 항목 링크**를 `## 참고` 로 남겨요. 원본에는 `지연사유` 속성(rich_text)에 **왜 못 끝냈는지 + 어디로 이월했는지**를 적어요.
- 상태별 기본 처리와 다르게 가고 싶으면 사용자 지시가 이겨요. 다만 전례와 어긋난다는 점을 한 줄로 알리고 진행해요.

### 6. 회고 액션아이템 → 백로그 매핑

회고의 액션 아이템과 "다음주 계획"을 한 건씩 훑으며 4-(b) 덤프와 대조해요. 세 갈래예요:

1. **이미 있고 상태가 `제품`** → 상태를 `스프린트` 로 바꾸고 새 스프린트에 연결. 점수가 이미 있으면 건드리지 않아요.
2. **이미 있고 상태가 `스테이징`·`진행 중`** → 5단계 이월 판정으로 넘겨요. 새로 만들지 않아요.
3. **없음** → 신규 생성.

대조는 **제목 문자열 일치가 아니라 내용 일치**로 봐요. 제목이 달라도 같은 일이면 중복이에요. 애매하면 후보를 보여주며 물어요. 이미 `[x]` 로 닫힌 액션아이템은 제외해요.

### 7. 항목별 확인 (한 건씩)

**신규로 만들 항목은 한 건에 질문 하나로, 순차로 물어요.** 5건이면 5번 물어요. 묶어서 묻지 않아요 — 앞 항목의 답이 뒤 항목 판단을 바꾸기 때문이에요. 질문마다 이 셋을 보여줘요:

- **항목 문장** (작업 이름), **선제조건**, **완수조건**
- 선택지에는 "추가 안 함" 과, 가능하면 "두 건으로 분리" 같은 실제 대안을 넣어요.

이미 등록·스코어링된 항목을 **고르기만 하는 경우**(제품→스프린트 이동)는 새로 쓰는 게 아니라, `multiSelect` 로 한 번에 물어도 돼요.

작업 이름은 팀 관행인 **"{목적}을 위해, {행위}한다"** 형식을 따라요. 순수 조사·`[스파이크]` 항목은 팀 관행대로 **점수를 공란**으로 둬요.

### 8. 반영 (write)

승인된 내용을 [드라이버 스크립트](#드라이버-스크립트-패턴)로 한 번에 반영해요. 순서는 이래요:

1. **신규 백로그 생성** — `상태=스프린트`, `⚡ 스프린트`=새 스프린트, `에픽`, `작업자`, 점수 4종, `가치판단`, 본문(`## 배경` / `## 완료 조건` / `## 참고`).
2. **제품 → 스프린트 이동** — `상태` 와 `⚡ 스프린트` 만 PATCH. 점수·본문은 건드리지 않아요.
3. **이월 원본에 `지연사유` 기입** — 원본의 다른 속성은 건드리지 않아요.

### 9. 용량 점검

반영 후 새 스프린트의 백로그를 다시 조회해 **WIP 합계와 작업자별 부하**를 집계해요.

```bash
ntn datasources query a07f68d9-4082-8359-9579-07c5578db49e \
  --filter '{"property":"⚡ 스프린트","relation":{"contains":"<NEW_SPRINT_PAGE_ID>"}}' --json < /dev/null
```

- **직전 스프린트 WIP 과 비교**해요. 크게 늘었으면(대략 1.5배 이상) 수치를 들어 알리고, **가장 우선순위가 낮은 항목**을 이름과 함께 지목해 제품 백로그로 내리는 안을 제시해요. 임의로 빼지 않아요.
- 한 사람에게 몰렸으면 그 사람의 포인트·건수를 보여줘요.
- 점수·에픽이 빈 항목이 있으면(스파이크 제외) 경고로 표시해요.

용량 판단 근거는 [스크럼 실전 플레이북](../../references/scrum-playbook.md) 의 벨로시티·용량계획 절을 따라요.

### 10. 제목 갱신

연결된 백로그를 관통하는 한 줄 요약으로 placeholder 를 교체해요. 형식은 [po 스킬의 스프린트 제목 형식](../po/SKILL.md#스프린트-제목-형식). 교체 전에 후보를 보여주고 승인받고, 이전 제목은 보고에 남겨요.

### 11. 보고

- 새 스프린트 제목·기간·URL, 백로그 건수·WIP
- 우선순위 내림차순 표 (우선순위 · 크기 · 작업자 · 작업 이름)
- 한 일 분류: 신규 N건 / 제품→스프린트 N건 / 이월 원본 N건에 지연사유 / 이월하지 않은 스테이징 N건 / 고아 항목 처리
- **짚어둘 것** — 용량 경고, 범위 미확정 항목, 실패한 쓰기. 없으면 없다고 써요.

---

## 드라이버 스크립트 패턴

여러 건의 쓰기는 셸 루프 대신 Python 하나로 처리해요. 한글 JSON 이 안전하고, 실패 건을 모아 보고하기 쉬워요.

```python
import json, subprocess, tempfile, os

BACKLOG_DS = "a07f68d9-4082-8359-9579-07c5578db49e"
NEW_SPRINT = "<NEW_SPRINT_PAGE_ID>"

def ntn(path, method, body):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(body, f, ensure_ascii=False)
        tmp = f.name
    try:
        r = subprocess.run(["timeout", "60", "ntn", "api", path, "-X", method, "-d", "@" + tmp],
                           capture_output=True, text=True, stdin=subprocess.DEVNULL)
    finally:
        os.unlink(tmp)
    if r.returncode != 0 or not r.stdout.strip():
        return {"object": "error", "code": "cli", "message": (r.stderr or r.stdout)[:300]}
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"object": "error", "code": "parse", "message": r.stdout[:300]}

def blocks(배경, 완수조건, 참고=None):
    def h2(t): return {"object":"block","type":"heading_2",
                       "heading_2":{"rich_text":[{"type":"text","text":{"content":t}}]}}
    def p(t):  return {"object":"block","type":"paragraph",
                       "paragraph":{"rich_text":[{"type":"text","text":{"content":t}}]}}
    out = [h2("배경"), p(배경), h2("완료 조건"), p(완수조건)]
    if 참고: out += [h2("참고"), p(참고)]
    return out

def create(name, people_ids, epic_id, size, value, urgency, risk, judgement, 배경, 완수조건, 참고=None):
    props = {
        "작업 이름": {"title": [{"text": {"content": name}}]},
        "상태": {"status": {"name": "스프린트"}},
        "⚡ 스프린트": {"relation": [{"id": NEW_SPRINT}]},
        "에픽": {"relation": [{"id": epic_id}]},
        "작업자": {"people": [{"object": "user", "id": i} for i in people_ids]},
    }
    if size:  # 스파이크는 점수를 비워요
        props.update({
            "작업크기":     {"select": {"name": size}},
            "비즈니스가치": {"select": {"name": value}},
            "긴급도":       {"select": {"name": urgency}},
            "위험도":       {"select": {"name": risk}},
            "가치판단":     {"rich_text": [{"text": {"content": judgement}}]},
        })
    return ntn("/v1/pages", "POST", {
        "parent": {"type": "data_source_id", "data_source_id": BACKLOG_DS},
        "properties": props,
        "children": blocks(배경, 완수조건, 참고),
    })

def move_to_sprint(page_id):
    return ntn(f"/v1/pages/{page_id}", "PATCH", {"properties": {
        "상태": {"status": {"name": "스프린트"}},
        "⚡ 스프린트": {"relation": [{"id": NEW_SPRINT}]},
    }})

def mark_delayed(page_id, reason):
    return ntn(f"/v1/pages/{page_id}", "PATCH",
               {"properties": {"지연사유": {"rich_text": [{"text": {"content": reason}}]}}})
```

---

## 주의

- **원본 백로그의 `⚡ 스프린트` relation 은 절대 바꾸지 않아요.** relation 은 1개 제한이라 옮기면 원 스프린트의 WIP 기록이 사라져요.
- 상태 select 값은 `제품`·`스프린트`·`진행 중`·`스테이징`·`완료`·`취소` 중 하나. 점수 select 는 `1/2/3/5/8` 만. 그 외 값을 쓰면 Notion 이 새 옵션을 만들어 버려요.
- `우선순위`·`스토리포인트`·`WIP` 는 formula 라 직접 못 써요. 입력 4종만 채우면 자동 계산돼요.
- 생성한 백로그는 `ntn pages trash <page-id>` 로 되돌릴 수 있어요. 상태 변경은 되돌리려면 이전 값이 필요하니 **PATCH 전 값을 로그로 남겨요**.
- 이 skill 은 스프린트 페이지 **본문 블록을 건드리지 않아요**. 브리핑 작성은 [sprint-report](../sprint-report/SKILL.md) 의 일이고, 거기서도 `ntn pages edit` 는 회의노트 파손 위험 때문에 쓰지 않아요.
- 회고에 근거가 없는 항목은 만들지 않아요. "있으면 좋을 것 같은" 백로그를 추측으로 채우지 않아요.
