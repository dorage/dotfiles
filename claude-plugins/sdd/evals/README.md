# sdd 평가

스킬을 고치거나 버전을 올릴 때마다, 스킬마다 결과물이 `references/` 의 포맷 규칙을 지키는지 점수를 매기고 이전 버전보다 나빠졌는지(회귀) 찾는다.

```bash
# 리포 루트에서
npx tsx claude-plugins/sdd/evals/run.ts
```

## 무엇을 보는가

문서를 쓰는 아홉 스킬마다 case 하나를 둔다. 모두 같은 작은 도메인(제휴 카페 임직원 할인)을 쓴다.

| case | 스킬 | 결과물 | 미리 깔아 두는 입력 |
| --- | --- | --- | --- |
| `quick/receipt-line` | quick | 마지막 채팅 답 | 없음 |
| `draft/cafe-discount` | draft | `out/requirements.md` | 없음 |
| `persona-review/cafe-discount` | persona-review | `out/requirements.md` (같은 파일을 고침) | 골든 `requirements.md` 에서 「참여자별 검토 기록」을 지운 것 |
| `design/cafe-discount` | design | `out/design.md` | 골든 `requirements.md` |
| `flow/cafe-discount` | flow | `out/flow.md` | 골든 `requirements.md` |
| `task/cafe-discount` | task | `out/tasks.md` | 골든 `requirements.md`, `design.md` |
| `bdd/cafe-discount` | bdd | `out/features/**/*.feature` | 골든 `requirements.md`, `design.md` |
| `brief-dev/cafe-discount` | brief-dev | `out/brief-dev.md` | 골든 `requirements.md` |
| `brief-nondev/cafe-discount` | brief-nondev | `out/brief-nondev.md` | 골든 `requirements.md` |

- 골든 입력은 `_fixtures/` 에 한 번만 있다. 결정이 모두 닫힌 「완성」 상태라 task·bdd 가 멈추지 않는다. 각 case 의 `scaffold.sh` 가 `_fixtures/stage.sh` 를 불러 필요한 것만 `out/` 에 복사하고, `.eval-case` 에 case 이름을 적고, 빈 git 저장소를 만든다
    - 골든 `requirements.md` 는 검토까지 끝난 문서라 맨 끝에 「참여자별 검토 기록」이 있다. persona-review case 의 `scaffold.sh` 는 깔아 둔 뒤 이 절을 지운다. 기록이 있으면 검토할 참여자가 없기 때문이다
- 기준 trace 가 아직 없는 새 스킬의 case(지금은 persona-review, flow)는 `baseline` 채점기를 두지 않는다. `--save-baseline` 으로 `baseline/current/traces/{스킬}.jsonl` 이 생긴 뒤 더한다
- 프롬프트는 `/sdd:{스킬}` 로 부르고, 결과 경로를 적어 폴더를 묻지 않게 하고, 묻지 말고 열린 결정은 열린 채 추천안을 적어 두라고 한다
- case 마다 채점기
    - `file-output`: 결과 파일이 생겼다 (quick 은 대신 `write-none`: 파일을 만들지 않았다)
    - `ask-none`: `AskUserQuestion` 을 부르지 않았다
    - `regex-…`: 스킬의 references 문서에서 뽑은 규칙. 예: 인수 조건마다 마커 하나, 숫자 목록은 인수 조건에만, 요약·결론 헤딩 없음, 그룹마다 결정 5개 이하
    - `llm-…` 두 개: 같은 내용을 두 번 쓰지 않았는가, 입력의 마스터 문장·결정을 바꾸지 않았는가
    - `baseline`: 기준 실행의 trace 와 비교해 그만큼 잘했는가
- `cases.test.ts` 가 골든 문서를 regex 규칙에 대 보고, 규칙이 틀린 글을 실제로 잡는지 확인한다

### 실행 통과와 판정

- 실행 하나는 `baseline` 을 뺀 채점기가 모두 통과해야 통과다. `baseline` 결과는 기준 파일에 따라 달라서, 그 결과를 다음 비교의 기준으로 쓰면 앞 결과가 뒤 결과를 끌어내리는 순환이 생긴다. 표의 메모 칸에 참고로만 보여 준다
- case 판정 (`compare.ts`)
    - 이전과 같거나 나아지면 통과
    - 실행 1번만큼 떨어지면 경고 (3/3 → 2/3)
    - 실행 2번 이상 떨어지면 회귀 (3/3 → 1/3)
    - 새 실행에서 `regex-…` 나 `file-…` 가 한 번이라도 떨어지면, 통과 수와 상관없이 회귀
- 회귀가 하나라도 있으면 종료 코드 1, 비용 한도나 중단으로 끝난 부분 결과면 "부분 결과" 를 찍고 판정 없이 종료 코드 2

## 돌리는 법

### 처음 한 번 (기준 만들기)

- `npx tsx claude-plugins/sdd/evals/run.ts --runs 1` 로 한 번 돌려 본다. 기준이 없어서 비교 없이 돌리기만 한다
- `claude-plugins/sdd/evals/results/{버전}-{커밋}/runs/{case}/run-1/out/` 의 결과물과 표를 읽고, 떨어진 채점기가 스킬 잘못인지 채점기 잘못인지 가른다. 채점기 잘못이면 case.yaml 을 고친다
- 만족하면 `npx tsx claude-plugins/sdd/evals/run.ts --save-baseline` 으로 실행 3번짜리 기준을 저장한다
- `claude-plugins/sdd/evals/baseline/current/` 을 커밋한다

### 패치 모드와 전체 모드

- `run.ts` 는 `.claude-plugin/plugin.json` 의 버전과 `baseline/current/meta.json` 의 버전을 비교한다
    - 셋째 자리만 바뀌었다 (0.4.2 → 0.4.3) → 패치 모드: 지금 버전만 돌리고 `baseline/current/aggregate.json` 과 비교한다
    - 첫째·둘째 자리가 바뀌었다 (0.4.2 → 0.5.0, 0.9.1 → 1.0.0) → 전체 모드: 기준 커밋(`--base`, 없으면 `meta.json` 의 commit)을 임시 git 워크트리로 꺼내 두 버전을 모두 돌리고 비교한다. 옛 버전에는 평가 case 가 없을 수 있어서 지금 case 와 `_fixtures` 를 옛 플러그인에 복사해 쓴다
    - `meta.json` 이 없다 → 첫 실행: 돌리기만 한다
- 옵션
    - `--base <commit>`: 전체 모드에서 비교할 이전 커밋
    - `--save-baseline`: 이번 결과로 기준(`meta.json`, `aggregate.json`, case 마다 run-1 trace)을 바꾼다. `--case` 와 함께 쓰면 거부한다
    - `--runs N`, `-j N`, `--case <glob>`: `claude plugin eval` 에 그대로 넘긴다
- 실행 명령은 `claude plugin eval <플러그인> --ablation none --scaffold --allow-tools Write Edit Bash Agent --judge-model sonnet --keep-temp --no-publish --output-dir evals/results/{버전}-{커밋}` 이다. 처음에는 플러그인을 믿는지 묻는 질문이 나올 수 있어서 키보드 입력을 그대로 잇는다
- 남겨 둔 실행 폴더(`/tmp/e-XXXX`)에서 `home/cwd/out/` 과 `out/trace.jsonl` 을 `results/{버전}-{커밋}/runs/{case}/run-{n}/` 으로 옮기고 실행 폴더를 지운다

### 블라인드 비교 (전체 모드)

전체 모드는 끝에 `results/{버전}-{커밋}/benchmark/` 를 skill-creator 모양으로 만들고, LLM 이 할 다음 단계를 찍는다.

- `benchmark/eval-{i}/new_skill/run-{n}/`, `old_skill/run-{n}/`: `grading.json`(채점기 결과)과 `outputs/`(결과물)
- `benchmark/blind/eval-{i}/run-{n}/A`, `B`: 어느 쪽이 새 버전인지 감춘 사본. 정답표는 `blind/key.json` 이고 비교가 끝날 때까지 열지 않는다
- 자리마다 skill-creator 의 `agents/comparator.md` 를 따르는 하위 에이전트가 A·B 를 비교해 `comparison.json` 을 쓴다
- `npx tsx claude-plugins/sdd/evals/compare.ts blind <benchmark 폴더>` 로 승패를 센다. 새 버전 승 수가 패 수 이상이면 통과 (4:4 통과, 3:5 회귀). 비긴 것은 세지 않는다
- skill-creator 폴더에서 `uv run python -m scripts.aggregate_benchmark <benchmark 폴더> --skill-name sdd` 로 점수 요약(`benchmark.json`, `benchmark.md`)을 만든다

### 테스트

```bash
npx tsx --test claude-plugins/sdd/evals/*.test.ts
```

## 첫 실제 실행에서 확인할 가정

`claude plugin eval` 은 공개 문서가 없어 Claude Code 2.1.316 바이너리를 읽고 맞춘 것이다. 첫 실행에서 아래가 맞는지 본다.

- `baseline_file` 경로: case 폴더 기준 상대 경로(`../../baseline/current/traces/{스킬}.jsonl`)다. 바이너리가 case 폴더 기준으로 풀고 플러그인 안인지 확인하는 것을 코드에서 읽었다. 실제로 받아 주는지만 첫 실행에서 본다
- 첫 `baseline` 채점은 빈 자리 trace(`{"type":"placeholder"}`)와 비교하므로 뜻이 없다. 판정에서 빠지니 무시하고 `--save-baseline` 뒤부터 본다
- 기준 trace 크기: `baseline` 채점기는 10MB 넘는 기준 파일을 읽지 못한다. `--save-baseline` 은 넘는 trace 를 저장하지 않고 경고만 찍는다
- regex 규칙과 실제 결과물: 골든 문서로만 검증했다. regex·file 채점기는 한 번만 떨어져도 회귀라서, 엉뚱하게 떨어지면 규칙을 고친다. 먼저 볼 것
    - draft `regex-recommendation-shape`: 추천안을 `@초안 a안 —` 이 아닌 다른 모양으로 쓰면 떨어진다
    - design `regex-decision-has-arrow`: 볼드·이탤릭 D 결정 줄에 `->` 도 `@확정` 도 없으면 떨어진다. 정해진 결정을 다른 모양으로 쓰면 틀리게 잡을 수 있다
    - bdd `regex-korean-keywords`·`regex-no-english-blocks`: `references/bdd.md` 는 영어 문법 규칙과 한국어 키워드 예시(`# language: ko`)를 함께 둔다. 모델이 영어 키워드로 쓰면 둘 다 떨어진다
    - brief 의 `count:5`(번호 줄 수)와 `count:10`(헤딩 수)은 골든 문서 모양에 묶여 있어서 골든을 고치면 함께 고친다
- 윤문 단계: 프롬프트가 건너뛰라고 한다. 격리된 HOME 에서 `claude plugin list` 가 멈춰 시간 초과로 0점이 나는 것을 막으려는 것이다
- bdd 내용 검사: `files` 대상은 파일 내용이 아니라 새로 생긴 파일 경로 목록이다. 그래서 프롬프트 끝에서 `.feature` 를 `out/features-all.txt` 한 파일로 모으게 하고 그 파일을 검사한다. 스킬 밖 명령이 하나 더 들어간 것이다
- `scaffold.sh` 가 `_fixtures/` 를 읽을 수 있는지: scaffold 는 평가 격리 밖에서 사용자 권한으로 돈다고 보았다
- aggregate-result.json 모양: `cases[].name`, `cases[].graders[].type`, `cases[].arms.with[].graders[]`, `arms.with[].tracePath`, `partial` 을 읽는다. 모르는 필드는 무시한다. 결과 파일은 `--output-dir` 에 생긴다고 보았다 (`--json <파일>` 옵션은 이 버전에 없다)
- 실행 번호: `tracePath` 가 실행 폴더 안을 가리키면 그것으로, 아니면 도착 순서로 붙인다. 블라인드 비교와 `run-1` 기준 trace 는 이 번호에 기댄다
- 전체 모드의 임시 워크트리: `claude plugin eval` 은 같은 저장소의 다른 워크트리도 훑는다. 워크트리가 많아 "more than 20000 entries" 로 거부되면, 저장소를 따로 clone 한 곳에서 돌린다

## 범위 밖

- `sdd:setup`: HOME 을 건드리고 플러그인을 설치해서 평가 안에서 돌리지 않는다
- 스킬이 알맞은 말에 불리는지(트리거) 평가: 프롬프트가 `/sdd:{스킬}` 로 직접 부른다
- CI: 실행마다 비용이 들어서 사람이 버전을 올릴 때 직접 돌린다
- humanize-korean 윤문: 평가에는 sdd 플러그인만 올라가서 윤문 단계는 건너뛴다 (spec-format 「윤문」)
