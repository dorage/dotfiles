# `ntn` 전체 커맨드 레퍼런스

SKILL.md 의 운영 가이드로 커버되지 않는 영역(특히 Workers)과 전역 옵션 전체 목록이에요. 버전에 따라 차이가 있을 수 있으니 애매하면 `ntn <command> --help` 로 실제 설치본을 확인해요.

## 문서 인덱스

전체 API 문서 인덱스: `https://developers.notion.com/llms.txt` (`WebFetch` 로 받아 탐색). 개별 엔드포인트는 `ntn api <path> --docs` / `--spec`.

## 전역 플래그 (모든 커맨드)

| 플래그 | 설명 |
| :-- | :-- |
| `-v, --verbose` | 소스 체인 포함 전체 에러 상세 출력 |
| `--workers-config-file <path>` | `workers.json` 경로 지정 (기본 CWD 조회를 덮어씀). 파일의 `workspaceId` 가 인증 커맨드의 워크스페이스를 선택 |
| `-V, --version` | 버전 출력 |
| `-h, --help` | 도움말 |

## 환경변수

| 변수 | 설명 |
| :-- | :-- |
| `NOTION_API_TOKEN` | 인증 토큰 (키체인보다 우선) |
| `NOTION_KEYRING` | `0` 이면 OS 키체인 대신 파일 기반 인증(`~/.config/notion/auth.json`) 사용 |
| `NOTION_WORKERS_CONFIG_FILE` | `workers.json` 경로 (`--workers-config-file` 과 동일) |
| `NOTION_WORKSPACE_ID` | 대상 워크스페이스 ID; 워크스페이스 선택 프롬프트를 건너뜀 |
| `NOTION_API_VERSION` | Notion-Version 헤더 (`--notion-version` 과 동일) |
| `NOTION_ENV` | 대상 환경: `local`/`dev`/`stg`/`prod` (`--env` 와 동일) |
| `NOTION_API_BASE_URL`, `NOTION_BASE_URL` | API/로그인·workers 요청 베이스 URL |

## 인증

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn login` | Notion 로그인 후 워크스페이스 연결 (브라우저 필요 → 사용자가 `! ntn login` 으로 직접 실행) |
| `ntn logout` | 현재 워크스페이스 자격증명 삭제 |
| `ntn whoami` | 인증된 Notion 사용자 표시 |
| `ntn doctor` | auth·keychain·network·config 상태 진단 |
| `ntn update` | 최신 버전으로 업데이트. `--force` (최신이어도 재설치) |
| `ntn completions` | 셸 자동완성 생성 |

## 페이지 (SKILL.md 에 상세)

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn pages get <page-id>` | 마크다운으로 조회. `--json`, `--notion-version` |
| `ntn pages create` | 마크다운으로 생성. `--parent <ref>`(`page:`/`database:`/`data-source:`), `--content`(생략 시 stdin) |
| `ntn pages edit <page-id>` | 마크다운으로 내용 갱신. `--content`(생략 시 stdin), `--allow-deleting-content` |
| `ntn pages trash <page-id>` | 휴지통. `--yes`(프롬프트 생략) |

## 데이터소스 (SKILL.md 에 상세)

| 커맨드 | 설명 · 플래그 |
| :-- | :-- |
| `ntn datasources query <data-source-id>` | `--limit <n>`(기본 25), `--start-cursor <cursor>`, `-s/--sort "<prop> [asc\|desc]"`(반복 가능), `--filter <json>`, `--filter-file <path>`(`-`=stdin), `--notion-version` |
| `ntn datasources resolve <database-id>` | database ID → data source ID. `--notion-version` |

## API

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn api <path> [input]...` | 인증된 Notion API 호출. `-d/--data <json\|@path\|@->`(바디), `-X/--method`, `--spec`(축약 OpenAPI), `--docs`(공식 문서), `--file <path>`(multipart file 필드), `--notion-version` |
| `ntn api ls` | 지원 엔드포인트 목록 |

인라인 `input` 으로 헤더·쿼리 파라미터·바디 필드를 지정할 수 있어요. 메서드는 경로에서 추론되며 `-X` 로 덮어써요.

## 파일

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn files create` | Notion 에 파일 업로드 |
| `ntn files get <upload-id>` | 업로드 상세 |
| `ntn files list` | 업로드 목록 |

---

# Workers (Beta)

Notion Workers 관리. 특정 worker 를 대상으로 하는 커맨드는 다음 순서로 worker ID 를 해석해요: ① `--worker-id` 플래그(또는 위치 인자 `<worker-id>`) → ② CWD `workers.json` 의 `workerId`. 둘 다 없으면 에러.

## Workers 공통 플래그

대부분의 `workers` 서브커맨드에서 지원: `--json`(JSON), `--plain`(헤더 없는 TSV, `--json` 과 배타적), `--worker-id <id>`.

## Workers 코어

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers new [dir]` | worker 프로젝트 스캐폴드. `--force`, `--git`/`--no-git`, `--install`/`--no-install` |
| `ntn workers deploy` | CWD 의 worker 빌드·업로드. `workers.json` 없으면 신규 생성. `--name`(생성 시 필수, 갱신 시 금지), `--local-build`, `--no-git` |
| `ntn workers list` (alias `ls`) | 활성 워크스페이스의 worker 목록 |
| `ntn workers get [worker-id]` | 단일 worker 상세 |
| `ntn workers create` | 코드 배포 없이 worker 생성. `--name` |
| `ntn workers delete [worker-id]` (alias `rm`) | worker 삭제. `--yes` |
| `ntn workers exec <key>` | capability(sync/tool/webhook) 실행·출력. `-d/--data <json>`(생략 시 stdin), `--stream`, `-l/--local`(tsx 로 로컬 실행), `--dotenv <path>`(기본 `.env`), `--no-dotenv` |
| `ntn workers capabilities list` (alias `ls`) | 배포된 capability 목록 |
| `ntn workers tui` (alias `ui`) | 대화형 터미널 UI |

## Workers — sync

스케줄된 syncable capability 관리. 각 서브커맨드는 capability 를 식별하는 `<key>` 를 받아요. 공통 플래그(`--json`/`--plain`/`--worker-id`) 적용.

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers sync status [key]` | 라이브 상태. `--no-watch`(1회 출력), `--interval <s>`(기본 2) |
| `ntn workers sync trigger <key>` | 스케줄 무시하고 즉시 실행. `--preview`(타겟에 쓰지 않고 호출), `--context <json>`(이전 preview 의 `nextContext`), `-l/--local`, `--dotenv`, `--no-dotenv` |
| `ntn workers sync pause <key>` | 스케줄 일시정지 (진행 중 실행은 중단 안 함) |
| `ntn workers sync resume <key>` | 일시정지된 sync 재개 |
| `ntn workers sync state get <key>` | 현재 커서·통계 출력 |
| `ntn workers sync state reset <key>` | 커서·통계 초기화 (다음 실행 시 처음부터) |

## Workers — env

worker 의 암호화 환경변수 관리. 값은 쓰기 전용이라 `list` 로 반환되지 않아요.

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers env set <KEY=VALUE>...` | 환경변수 설정 |
| `ntn workers env list` (alias `ls`) | 키 목록 (값 숨김) |
| `ntn workers env unset <key>` (alias `delete`/`rm`) | 환경변수 제거 |
| `ntn workers env pull` | 원격 → 로컬 `.env`. `--file <path>`(기본 `.env`), `--no-file`(stdout), `--yes` |
| `ntn workers env push` | 로컬 `.env` → worker. `--file <path>`(기본 `.env`), `--yes` |

## Workers — OAuth

외부 provider 인증용 OAuth 연결 관리.

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers oauth start <key>` | OAuth 플로우 시작 (provider 인증 URL 열기) |
| `ntn workers oauth token <key>` | 액세스 토큰 출력(디버깅용). `--plain` 이면 토큰만 (파이프용) |
| `ntn workers oauth show-redirect-url` | provider 에 설정할 리다이렉트 URL 출력 |

## Workers — runs

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers runs list` (alias `ls`) | 최근 실행 목록 |
| `ntn workers runs logs <run-id>` | 특정 실행 로그 |

## Workers — webhooks

| 커맨드 | 설명 |
| :-- | :-- |
| `ntn workers webhooks list [worker-id]` (alias `ls`) | webhook capability 의 URL 목록 |
