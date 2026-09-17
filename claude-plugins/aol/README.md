# aol (Append-Only Log)

마스터가 실제로 친 프롬프트를 원문 그대로 쌓아두고, 거기서 **반복되는 요청**을 찾아 스킬로 바꾸기 위한 Claude Code 플러그인이에요.

찾는 것은 요청의 형태예요. 대상이 아니에요. "정산 필드 추가하는 계획 세워줘" 와 "status 컬럼 제거할 계획 작성" 은 대상이 완전히 다르지만 같은 요청이고, 이런 게 여러 세션에서 반복되면 계획을 세우는 스킬로 만들 값어치가 있어요.

## 분류하지 않는다

이 플러그인의 핵심 규칙이에요. **로그를 쌓는 시점에 이름표를 붙이지 않아요.**

예전 버전은 LLM 이 응답 끝에 `[aol] intent=... object=... size=...` 마커를 달게 했어요. 16일 돌린 결과 `object` 가 작업마다 유일해서(브랜치 이름을 그대로 썼으니 당연했어요) 유일 라벨이 100개 넘게 생겼고, 같은 요청이 3번 이상 나온 단위는 2개뿐이었어요. "계획 세워줘" 요청 11건은 11개의 다른 라벨로 흩어져서 끝내 안 보였어요.

그렇다고 확정된 어휘집을 두고 거기서 고르게 하는 것도 안 돼요. 목록이 있으면 새로운 형태의 요청이 와도 "이거 기존 항목이랑 비슷하네" 하고 밀어넣게 돼요. 목록에 맞추는 압력은 언제나 새것을 지우는 쪽으로 작동해요.

그래서 훅은 원문만 남기고, 묶는 일은 `/aol:report` 가 돌 때마다 원문을 처음부터 다시 읽어서 해요. 원문이 남아 있으니 기준을 바꿔서 몇 번이고 다시 묶을 수 있어요. 라벨을 붙여버리면 그 자유가 사라져요.

## 동작

- `UserPromptSubmit` 훅이 마스터 프롬프트를 세 갈래로 갈라 남겨요. 슬래시 커맨드는 `SKILL`, `<task-notification>` 같은 시스템 주입은 `SYS`, 나머지가 `Q` 예요. `Q` 의 `prompt` 가 이 로그의 본체예요
- `SessionStart` 훅이 `hooks/rule.md` 를 컨텍스트로 주입해요. compact 뒤에도 다시 들어가요. 규칙은 한 줄짜리예요 — 마스터가 LLM 을 정정했을 때만 `[aol] corr="..." rule=...` 을 붙이는 것
- `Stop` 훅이 그 `corr` 을 읽어 `CORR` 레코드를 쓰고, 턴 통계를 `STOP` 으로 남겨요. **마커가 없는 것이 정상이고, 없다고 응답을 되돌리지 않아요**
- 서브에이전트 훅(입력에 `agent_id` 가 있는 경우)은 기록하지 않아요

정정만 LLM 에게 맡기는 이유는, 무엇을 왜 틀렸는지가 프롬프트 원문에 안 남기 때문이에요. 요청이 무엇이었는지는 원문이 말해주지만, LLM 이 그걸 어떻게 어긋나게 읽었는지는 그 자리의 LLM 만 알아요.

## 설치

```sh
claude plugin marketplace add ~/.config/claude-plugins
claude plugin install aol@dotfiles
```

hooks 폴더를 고친 뒤에는 `/reload-plugins` 또는 재시작이 필요해요. 마켓플레이스에서 설치한 플러그인은 캐시로 복사되므로 수정 후 `claude plugin update aol@dotfiles` 를 돌려요.

- 끄기: `claude plugin disable aol@dotfiles`
- 특정 프로세스에서만 끄기: 환경변수 `AOL_DISABLE=1` (배치 스크립트가 `claude -p` 를 돌릴 때 자기 로그를 남기지 않도록)
- 위치 바꾸기: 환경변수 `AOL_DIR`

## 로그 위치와 형식

`~/.claude/aol/{host}-{YYYY-MM}.jsonl`. 한 줄에 레코드 하나, append 만 해요. 머신마다 파일이 다르므로 동기화해도 충돌하지 않아요.

공통 필드는 `v`(스키마 버전), `ts`(UTC), `sid`, `host`, `repo`(origin URL 의 이름, 워크트리에서도 같은 값), `branch`, `type` 이에요. `sid` 와 `ts` 로 트랜스크립트(`~/.claude/projects/**/*.jsonl`)에 이어 붙일 수 있어요.

- `Q` — 마스터 프롬프트. `prompt` 원문. **이 로그의 본체예요**
- `SYS` — 시스템이 밀어넣은 프롬프트. `kind` 에 태그 이름(`task-notification` 등). 마스터 발화가 아니라서 갈라놨어요
- `SKILL` — 마스터가 친 슬래시 커맨드(`via: prompt`) 또는 Skill 툴 호출(`via: tool`). `skill`, `args`
- `SESSION` — SessionStart. `source`(startup/resume/clear/compact/fork). `fork` 인 세션은 LLM 이 만든 프롬프트를 받으므로 집계에서 빼요
- `ASK` — AskUserQuestion 직전. `headers`, `questions`
- `EDIT` — Edit/Write 직후. `tool`, `path`
- `CORR` — 응답 마커에 `corr=` 가 있을 때. `what`, `rule`
- `STOP` — 턴 종료. `turns`(distinct requestId), `tools`(tool_use 수), `sec`(직전 Q 부터 경과 초)
- `END` — SessionEnd. `reason`

### v1 에서 바뀐 것

`v:1` 레코드가 같은 파일에 섞여 있어요. 읽을 때 알아둘 것들이에요.

- `TAG`(intent/object/size)와 `BLOCK` 은 없어졌어요. `v:1` 에 남은 것들은 무시해요
- `SYS` 가 새로 생겼어요. `v:1` 에서는 `<task-notification>` 이 `Q` 에 섞여 있어요. 약 30건이에요
- `v:1` 은 `/` 로 시작하는 프롬프트를 전부 슬래시 커맨드로 읽어서, 마스터가 파일을 끌어다 놓은 `/Users/...` 프롬프트 4건이 `SKILL` 로 잘못 들어갔어요. 그 4건은 진짜 마스터 발화라서 되살려야 해요

`/aol:report` 가 이 둘을 알아서 처리해요.

## 읽기

`/aol:report` 로 돌려요. 커맨드가 하는 일과 지켜야 할 것은 `commands/report.md` 에 있어요.

손으로 볼 때 쓸 만한 것들이에요.

```sh
cd ~/.claude/aol

# 마스터 프롬프트 원문 (세션·리포와 함께)
jq -r 'select(.type=="Q") | [.sid, .repo // "-", (.prompt|gsub("\n";"⏎"))] | @tsv' *.jsonl

# 마스터가 말을 건 세션 수
jq -r 'select(.type=="Q") | .sid' *.jsonl | sort -u | wc -l

# 스킬 호출 실적 — 만들어둔 스킬이 실제로 발동하는지
jq -r 'select(.type=="SKILL") | "\(.via)\t\(.skill)"' *.jsonl | sort | uniq -c | sort -rn

# 반복해서 어긴 규칙 (훅 후보)
jq -r 'select(.type=="CORR") | .rule // "none"' *.jsonl | sort | uniq -c | sort -rn

# 반복해서 묻는 것 (CLAUDE.md 기본값 후보)
jq -r 'select(.type=="ASK") | .sid as $s | .headers[] | "\($s) \(.)"' *.jsonl | sort -u | awk '{print $2}' | sort | uniq -c | sort -rn
```

## 판단 기준

묶음 하나를 스킬로 만들지 판단할 때 보는 것들이에요.

- **빈도** — 서로 다른 세션 몇 개에서 나왔는가. 총 건수가 아니라 세션 수예요. 한 세션에서 5번 반복된 건 그 세션에서 일이 안 풀렸다는 뜻이지 반복 작업이라는 뜻이 아니에요
- **비용** — 그 구간 `STOP` 의 `tools`·`turns`·`sec` 중앙값. 빈도가 같으면 비싼 쪽이 먼저예요
- **마찰** — 그 구간의 `ASK` 수와 `CORR` 수. 매번 같은 걸 묻거나 같은 실수를 한다는 뜻이에요
- **이미 있는가** — 덮는 스킬이 이미 있으면 처방이 달라져요. 새로 만드는 게 아니라 발동 조건을 고치는 문제예요

마지막 항목을 빼먹으면 안 돼요. 2026년 9월 조사에서 "계획 작성" 요청 11건이 나왔는데 `/wt:plan` 은 이미 있었고 16일간 호출이 0건이었어요. 스킬이 없어서 반복한 게 아니라 있는데 안 쓰인 거였어요.

성공 판정은 하나예요. 스킬을 만든 뒤 같은 요청이 `Q` 에서 `SKILL` 로 옮겨가는가.

## 알려진 한계

- 태그가 없는 시스템 주입 문장은 `SYS` 로 안 갈라져요. `Your claude.ai usage limit has reset...`, `Background agent ... was stopped by the user` 같은 것들이 `Q` 에 남아요. 읽을 때 빼세요
- 마스터가 Esc 로 응답을 끊으면 Stop 훅이 안 돌아서 그 턴의 `STOP` 과 `CORR` 이 없어요
- `sec` 에는 AskUserQuestion 으로 마스터의 답을 기다린 시간이 섞여요. `ASK` 레코드 사이 구간을 빼고 보세요
- `SESSION` 대 `END` 가 안 맞아요. 세션 절반이 안 닫혀서 세션 단위 집계의 분모를 `END` 로 잡으면 안 돼요
- `EDIT` 의 `path` 는 대부분 `.claude/` 안쪽이에요. 에이전트 살림 파일이라 "무슨 코드를 고쳤는가" 의 근거로 쓸 수 없어요

## 다음 할 일

- 반기 점검에서 이 로그로 만든 스킬이 0건이면 플러그인을 내려요
