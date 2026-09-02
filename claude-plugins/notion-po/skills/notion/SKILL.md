---
name: notion
description: Notion CLI(`ntn`)로 Notion 워크스페이스를 다뤄요 — 페이지 읽기/생성/편집, 데이터소스(DB) 쿼리, 임의의 Notion API 호출, Workers 관리까지. Notion 페이지·DB URL 이나 페이지 ID 를 주며 "노션에서 ~ 가져와/올려/수정해", "이 DB 쿼리해줘", "노션 API 로 ~ 해줘" 같은 요청, 또는 `/notion` 슬래시 커맨드로 트리거해요.
---

# Notion CLI (`ntn`)

Notion 워크스페이스를 터미널에서 다루는 skill 이에요. 설치된 `ntn` CLI(0.19.x 기준)를 써서 페이지·데이터소스·임의 API·Workers 를 조작해요.

핵심 원칙: **모르는 엔드포인트는 추측하지 말고 CLI 의 탐색 기능(`ntn api ls`, `--spec`, `--docs`)으로 먼저 확인**해요. Notion API 스키마는 넓고 자주 바뀌므로, 결정적 단정 전에 출처를 확인해요.

## 언제 쓰나

- "노션 페이지 `<url>` 내용 가져와줘 / 마크다운으로 뽑아줘"
- "이 내용을 노션 `<부모>` 아래 새 페이지로 올려줘"
- "노션 페이지 `<url>` 에 이 내용 추가/수정해줘"
- "이 데이터베이스(`<url>`) 에서 `<조건>` 인 항목 찾아줘"
- "노션 API 로 `<작업>` 해줘" (검색, 코멘트, 사용자 조회 등 페이지/DB 이외)
- `/notion {요청}` 슬래시 커맨드
- Workers 배포·운영 관련 요청 (2차 영역 → [reference.md](reference.md) 의 Workers 섹션)

## 시작 전 확인 (항상)

작업 전에 인증 상태를 한 번 확인해요. 인증이 안 되어 있으면 사용자에게 로그인을 요청하고 멈춰요 — 임의로 `ntn login` 을 대신 실행하지 않아요 (브라우저 인터랙션 필요).

```bash
ntn whoami
```

- 성공 → 인증된 사용자/워크스페이스가 출력돼요. 진행.
- 실패(미인증) → 사용자에게 이렇게 안내: "노션 로그인이 필요해요. 프롬프트에 `! ntn login` 을 입력해 로그인한 뒤 다시 요청해 주세요." 그리고 멈춰요.
- 환경변수 `NOTION_API_TOKEN` 이 설정돼 있으면 키체인 대신 그 토큰을 써요. 사용자가 토큰을 주면 그 값을 노출하지 말고 해당 명령에만 환경변수로 전달해요.

문제가 모호하면 (`ntn doctor` 로 auth·keychain·network·config 진단 가능).

## Notion ID 다루기

사용자는 보통 **URL** 을 줘요. URL 에서 ID 를 뽑아야 해요.

- 페이지 URL: `https://www.notion.so/워크스페이스/제목-<32자hex>` → 끝의 32자 hex(하이픈 없는 UUID)가 페이지 ID. `ntn` 은 하이픈 유무 모두 대체로 허용하지만, 애매하면 8-4-4-4-12 형태로 하이픈을 넣어줘요.
- 데이터베이스 URL: `https://www.notion.so/워크스페이스/<32자hex>?v=...` → `?v=` 앞의 hex 가 **database ID**. Notion API 는 database 를 직접 쿼리하지 않고 **data source** 를 쿼리하므로, database ID 는 먼저 resolve 해야 해요 (아래 데이터소스 섹션 참고).
- ID 를 확신할 수 없으면 사용자에게 URL 을 그대로 달라고 요청해요. 잘못된 ID 로 추측 실행하지 않아요.

## 주요 작업

### 1. 페이지 읽기 — `ntn pages get`

페이지 본문을 마크다운으로 가져와요. 요약·분석·인용 요청의 기본 진입점.

```bash
ntn pages get <PAGE_ID>          # 마크다운
ntn pages get <PAGE_ID> --json   # 원본 블록 구조가 필요할 때
```

### 2. 페이지 생성 — `ntn pages create`

마크다운으로 새 페이지를 만들어요. `--parent` 로 위치를 지정해요.

```bash
# 부모 페이지 아래 하위 페이지로
ntn pages create --parent page:<PARENT_PAGE_ID> --content "# 제목

본문 마크다운"

# 데이터소스(DB)에 새 행(항목)으로
ntn pages create --parent data-source:<DATA_SOURCE_ID> --content "..."

# stdin 으로 긴 본문 전달 (--content 생략 시 stdin 을 읽음)
cat body.md | ntn pages create --parent page:<PARENT_PAGE_ID>
```

- `--parent` 형식: `page:<id>`, `database:<id>`, `data-source:<id>`.
- 본문이 길거나 특수문자가 많으면 파일로 작성 후 stdin 파이프를 써요 (셸 이스케이프 사고 방지).
- **되돌리기 주의**: 생성은 되돌리기 쉽지만(`ntn pages trash`), 어디에 만드는지(부모)는 반드시 사용자 지시와 일치시켜요. 부모가 불명확하면 확인 후 진행.

### 3. 페이지 편집 — `ntn pages edit`

기존 페이지 내용을 마크다운으로 갱신해요.

```bash
ntn pages edit <PAGE_ID> --content "..."
cat new.md | ntn pages edit <PAGE_ID>
```

- **위험 신호**: `--allow-deleting-content` 는 하위 페이지·DB 삭제를 허용해요. 이 플래그는 사용자가 명시적으로 삭제를 원할 때만 붙여요. 기본은 붙이지 않아요.
- 편집은 기존 내용을 덮어쓸 수 있으므로, 중요한 페이지면 먼저 `ntn pages get <ID>` 로 현재 내용을 백업(출력 보관)한 뒤 편집해요. 이게 이 작업의 안전망이에요.

### 4. 페이지 휴지통 — `ntn pages trash`

```bash
ntn pages trash <PAGE_ID>        # 확인 프롬프트
ntn pages trash <PAGE_ID> --yes  # 프롬프트 생략 (비대화 세션)
```

- 되돌릴 수 있지만(휴지통) 파괴적 작업이라, 대상 페이지가 사용자가 말한 그 페이지인지 `ntn pages get` 으로 제목을 한 번 확인한 뒤 실행하는 걸 권해요.

### 5. 데이터소스(DB) 쿼리 — `ntn datasources`

Notion 의 database 를 쿼리하려면 먼저 database ID → data source ID 로 resolve 해요.

```bash
# 1) database ID 를 data source ID 로 변환
ntn datasources resolve <DATABASE_ID>

# 2) data source 쿼리
ntn datasources query <DATA_SOURCE_ID>
ntn datasources query <DATA_SOURCE_ID> --limit 50
ntn datasources query <DATA_SOURCE_ID> -s "이름 asc" -s "생성일 desc"
ntn datasources query <DATA_SOURCE_ID> --filter '<filter JSON>'
ntn datasources query <DATA_SOURCE_ID> --filter-file filter.json   # '-' 면 stdin
```

- 필터 JSON 스키마가 헷갈리면 추측하지 말고 `ntn api pages 관련 docs` 또는 공식 "Filter data source entries" 레퍼런스를 확인해요. 필요하면 `ntn api <path> --docs` 로 관련 문서를 뽑아요.
- 결과가 페이지네이션되면 응답의 `next_cursor` 를 `--start-cursor` 로 넘겨 다음 페이지를 가져와요.

### 6. 임의 API 호출 — `ntn api` (페이지/DB 이외의 모든 것)

검색, 코멘트, 사용자, 블록 등 전용 서브커맨드가 없는 작업은 `ntn api` 로 처리해요. **탐색 → 확인 → 실행** 순서를 지켜요.

```bash
# 탐색: 지원 엔드포인트 목록
ntn api ls

# 확인: 특정 엔드포인트의 스키마 / 공식 문서
ntn api <path> --spec     # 축약된 OpenAPI 조각
ntn api <path> --docs     # 전체 공식 마크다운 문서

# 실행: GET (기본), 인라인 입력으로 헤더·쿼리·바디 필드 지정
ntn api search -d '{"query":"회의록"}'

# 명시적 메서드 / JSON 바디
ntn api <path> -X POST -d '{"key":"value"}'
ntn api <path> -d @body.json     # 파일에서 바디
ntn api <path> -d @-             # stdin 에서 바디
```

- 어떤 엔드포인트를 쓸지 불확실하면 반드시 `ntn api ls` → `--spec`/`--docs` 로 먼저 확인한 뒤 호출해요. 이게 이 skill 의 가장 중요한 습관이에요.
- 더 넓은 문서가 필요하면 문서 인덱스(`https://developers.notion.com/llms.txt`)를 `WebFetch` 로 받아 탐색해요.

## 출력 형식

대부분의 명령이 사람이 읽는 출력 / `--json` / `--plain`(TSV, 헤더 없음) 을 지원해요.

- 결과를 사용자에게 요약해 보여줄 때는 기본 출력.
- 후속 스크립트/파이프로 값을 뽑아야 하면 `--json` (후 `jq`) 또는 `--plain`.
- `--json` 과 `--plain` 은 동시 사용 불가.

## 안전 규칙 (요약)

- 파괴적/외부 영향 작업 = 페이지 생성·편집·휴지통, DB 쓰기, `-X POST/PATCH/DELETE`. 이런 작업은 대상 ID 와 부모를 사용자 지시와 대조하고, 애매하면 실행 전 확인해요.
- 편집 전 `ntn pages get` 으로 원본을 확보하는 걸 기본 안전망으로 삼아요.
- `--allow-deleting-content`, `-X DELETE`, `pages trash` 는 명시적 삭제 의사가 있을 때만.
- 인증/토큰 값은 출력에 노출하지 않아요.
- 읽기 작업(`get`, `query`, GET `api`)은 부담 없이 바로 실행해요.
- **비대화 환경 주의(검증됨)**: 스크립트/에이전트에서 `ntn` 을 호출할 땐 명령 끝에 `< /dev/null` 을 붙여요. 없으면 CLI 가 stdin 바디를 기다리며 멈춰요(hang). 쓰기 바디에 한글이 있으면 임시 파일에 JSON 을 쓰고 `-d @<path>` 로 넘기고, 쓰기엔 `timeout` 을 걸어요.

## 전체 커맨드 레퍼런스

Workers(배포·sync·env·oauth·runs·webhooks), 전역 플래그, 환경변수 등 전체 목록은 [reference.md](reference.md) 를 참고해요. Workers 관련 요청이 들어오면 그 파일을 먼저 읽어요.

애매한 서브커맨드/플래그는 항상 `ntn <command> --help` 로 실제 설치본에서 확인해요 (버전에 따라 차이가 있을 수 있어요).
