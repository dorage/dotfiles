# FreshRSS (portable)

어느 UNIX-like 머신에서든 같은 RSS 리더 환경을 재현하기 위한 구성.
리더 본체 + 1시간 주기 Cloudflare R2 백업 사이드카가 한 compose 파일에 들어있다.

```
services/freshrss/
├── docker-compose.yml   FreshRSS + 백업 스케줄러
├── .env.example         설정 템플릿 (.env 는 gitignore - 이 리포지토리는 public)
├── bootstrap-r2.sh      R2 버킷 생성 + 최초 업로드 (wrangler, 호스트에서 1회 실행)
└── backup/              사이드카 이미지 (alpine + rclone + sqlite)
    ├── Dockerfile
    ├── entrypoint.sh    loop | backup | snapshot | restore | list | verify | sh
    ├── backup.sh        스냅샷 생성 → R2 업로드 → 보존기간 정리
    ├── restore.sh       R2 스냅샷 → 볼륨 복원
    └── common.sh        공용 함수 / rclone 환경변수 구성
```

## 1. 최초 설정

```sh
cd services/freshrss
cp .env.example .env      # 값 채우기 (TZ, 포트, R2 자격증명)
docker compose up -d
open http://localhost:8080
```

기존 `docker run` 으로 띄운 컨테이너가 이미 있으면 먼저 치우고 올린다.
볼륨(`freshrss_data`, `freshrss_extensions`)은 이름을 명시해 두었으므로 **그대로
이어서 쓴다** — 데이터가 사라지지 않는다.

```sh
docker rm -f freshrss
docker compose up -d
```

> compose 가 `volume "freshrss_data" already exists but was not created by
> Docker Compose` 경고를 낸다. `docker run` 이 만든 볼륨에 compose 라벨이 없어서
> 나오는 것으로, 동작에는 영향이 없다. 없애고 싶으면 아래 "다른 머신으로 이동"
> 절차를 같은 머신에서 한 번 수행하면 된다 (백업 → 볼륨 삭제 → 복원).

## 2. Cloudflare R2 준비

### wrangler 로 어디까지 되는가 (검토 결과)

| 작업 | wrangler | 비고 |
| --- | --- | --- |
| 버킷 생성 | O `wrangler r2 bucket create <name>` | `--location apac` 로 지역 힌트 지정 |
| 객체 업로드 | O `wrangler r2 object put <bucket>/<key> --file=…` | 단일 PUT, 대용량엔 부적합 |
| 객체 조회/삭제 | O `r2 object get` / `r2 object delete` | |
| 객체 목록 | X | `list` 서브커맨드가 없다 |
| **S3 API 토큰 발급** | **X** | 대시보드에서 수동 생성 |

즉 **버킷 생성과 최초 업로드는 wrangler 로 가능**하지만, 주기적 백업에는 맞지
않는다. 목록 조회가 안 되니 보존기간 정리를 할 수 없고, Node + OAuth 토큰을
컨테이너에 넣어야 하며, 업로드는 멀티파트가 아니다.
그래서 사이드카는 **rclone + R2 의 S3 호환 API** 를 쓴다. 업로드·목록·조건부
삭제가 전부 되고, 이미지가 20MB대로 작다.

### 실행

```sh
npx wrangler login          # 브라우저 OAuth — TTY 가 있는 셸에서 직접 실행
./bootstrap-r2.sh           # 버킷 생성 + 최초 스냅샷 업로드까지
```

헤드리스 환경(SSH, CI, 에이전트 세션)에서는 `wrangler login` 이 안 된다. 이때는
대시보드 → My Profile → API Tokens 에서 **Workers R2 Storage: Edit** 권한 토큰을
만들어 넘긴다.

```sh
export CLOUDFLARE_API_TOKEN=<token>
./bootstrap-r2.sh
```

그 다음 S3 API 토큰만 수동으로 만들어 `.env` 에 넣는다.

- Cloudflare 대시보드 → R2 → API → **Manage API tokens**
- Permission: **Object Read & Write**
- Scope: 위에서 만든 버킷 하나로 한정

```
R2_ACCOUNT_ID=…        # R2 Overview 페이지 / `wrangler whoami`
R2_ACCESS_KEY_ID=…
R2_SECRET_ACCESS_KEY=…
```

```sh
docker compose up -d
docker compose run --rm backup list     # R2 와 통신되는지 확인
```

## 3. 운영 명령

```sh
docker compose logs -f backup                   # 스케줄러 로그
docker compose run --rm backup backup           # 즉시 1회 백업
docker compose run --rm backup list             # R2 의 스냅샷 목록
docker compose run --rm backup verify           # 최신 스냅샷 내려받아 무결성 검사
docker compose run --rm backup restore --force  # 최신 스냅샷으로 복원
```

## 4. 백업 동작 방식

`backup` 서비스는 크론 없이 `entrypoint.sh loop` 로 도는 스케줄러다.
`BACKUP_INTERVAL_SECONDS`(기본 3600) 경계에 맞춰 깨어나므로 매시 정각에 돈다.
컨테이너가 `restart: unless-stopped` 이라 재부팅 후에도 알아서 재개된다.

한 사이클:

1. `data` 볼륨을 스테이징으로 복사 — `*.sqlite*` 는 제외
2. SQLite 는 `sqlite3 .backup` (온라인 백업 API) 으로 따로 복사하고
   `PRAGMA integrity_check` 를 통과해야 진행. FreshRSS 를 **멈추지 않고도**
   깨지지 않은 스냅샷이 나오는 이유다. 단순히 tar 로 묶으면 쓰기 도중의 DB 를
   찢어 담을 수 있다
3. `MANIFEST` + `data/` + `extensions/` 를 `freshrss-<UTC timestamp>.tar.gz` 로 묶음
4. `r2:<bucket>/<prefix>/` 로 업로드
5. **업로드 성공 후에만** `BACKUP_RETENTION_DAYS` 보다 오래된 스냅샷을 정리
   (실패한 백업이 기존 이력을 깎아먹지 않도록)

보존 정리를 사이드카에 맡기지 않고 R2 쪽 lifecycle 규칙으로 돌릴 수도 있다.
사이드카가 안 도는 동안에도 적용되므로 더 튼튼하다. 이 경우 중복 삭제를 피하려면
`.env` 에서 `BACKUP_RETENTION_DAYS=0` 으로 끈다.

```sh
npx wrangler r2 bucket lifecycle add <bucket> expire-30d freshrss/ --expire-days 30
```

자격증명이 비어 있으면 매 사이클 에러를 로그에 남기고 다음 주기에 다시 시도한다.
`.env` 를 채우고 `docker compose up -d` 만 다시 하면 붙는다.

## 5. 다른 머신으로 이동

```sh
# 이전 머신 — 최신 상태를 R2 로 밀어 올린다
cd services/freshrss
docker compose run --rm backup backup
docker compose down

# 새 머신
git clone <this repo> && cd dotfiles/services/freshrss
cp .env.example .env        # 같은 R2 자격증명을 넣는다
docker compose create                    # 볼륨/컨테이너만 만들고 시작은 안 함
docker compose run --rm backup restore   # R2 최신 스냅샷 복원
docker compose up -d
```

복원 대상 볼륨이 비어있지 않으면 `restore` 는 거부한다. 덮어쓸 의도가 확실할
때만 `--force` 를 붙이고, **반드시 FreshRSS 를 먼저 멈춘다** (`docker compose
stop freshrss`).

R2 없이 USB/외장디스크에 있는 스냅샷에서 복원할 수도 있다:

```sh
docker compose run --rm -v /mnt/usb:/out -e REMOTE_DIR=/out backup restore
docker compose run --rm -v /mnt/usb:/out backup snapshot   # 반대로 내보내기
```

## 6. 주의사항

- **이 리포지토리는 public 이다.** 자격증명은 `.env` 에만 두고, 이 디렉터리의
  `.gitignore` 가 `.env` 와 `*.tar.gz` 를 막는다. `bootstrap-r2.sh` 는 wrangler
  가 만드는 `.wrangler/` 도 남기는데(계정 ID 캐시), 리포지토리 루트
  `.gitignore` 에서 막아둔다. 커밋 전에 `git status` 로 확인.
- 현재 FreshRSS 설정은 `auth_type => 'none'` 이다. 8080 포트에 닿을 수 있는
  누구나 전체 권한을 갖는다. LAN 밖으로 노출한다면 FreshRSS 쪽 인증을 켜거나
  (설정 → 인증) 리버스 프록시를 앞에 두는 편이 좋다.
- 백업 사이드카는 `data` 볼륨을 read-write 로 마운트한다. SQLite 온라인 백업이
  라이브 DB 를 열어야 하고 `-wal`/`-shm` 파일을 건드릴 수 있어서다. 스크립트
  자체는 볼륨에 쓰지 않는다 (`restore` 를 명시적으로 실행할 때만 쓴다).
