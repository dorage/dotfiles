# aol (Append-Only Label log)

마스터의 반복 요청, LLM이 마스터에게 묻는 내용, 자주 하는 작업을 나중에 배치로 분석해 스킬로 바꾸기 위한 라벨 로그를 남기는 Claude Code 플러그인이에요.

원문은 트랜스크립트(`~/.claude/projects/**/*.jsonl`)에 이미 있어요. 이 로그는 트랜스크립트에 없는 라벨(의도, 대상, 예상 크기, 정정 여부)과 집계용 이벤트만 담고, `sid`(session_id)와 `ts`로 트랜스크립트에 이어 붙여요.

## 동작

- SessionStart 훅이 `hooks/rule.md`의 기록 규칙을 컨텍스트로 주입해요. compact 뒤에도 다시 들어가요.
- LLM은 마스터 프롬프트에 답하는 응답의 마지막 줄에 마커 한 줄을 붙여요: `[aol] intent=fix object=fcm-ios-sound size=1h`
- Stop 훅이 `last_assistant_message`에서 마커를 읽어 TAG(와 CORR) 레코드를 쓰고, 턴 통계(STOP)를 함께 남겨요.
- 마커가 빠지거나 형식이 틀리면 Stop 훅이 `decision: block`으로 응답을 되돌려요. 같은 턴에서 한 번만 되돌리고(`stop_hook_active`), 되돌린 사실은 BLOCK 레코드로 남아요. BLOCK 건수가 곧 "LLM이 규칙을 얼마나 지키는가"의 측정값이에요.
- 서브에이전트 훅(입력에 `agent_id`가 있는 경우)은 기록하지 않아요.

## 설치

```sh
claude plugin marketplace add ~/.config/claude-plugins
claude plugin install aol@dotfiles
```

hooks 폴더를 고친 뒤에는 `/reload-plugins` 또는 재시작이 필요해요. 마켓플레이스에서 설치한 플러그인은 캐시로 복사되므로 수정 후 `claude plugin update aol@dotfiles`를 돌려요.

- 끄기: `claude plugin disable aol@dotfiles`
- 특정 프로세스에서만 끄기: 환경변수 `AOL_DISABLE=1` (배치 스크립트가 `claude -p`를 돌릴 때 자기 로그를 남기지 않도록)
- 위치 바꾸기: 환경변수 `AOL_DIR`

## 로그 위치와 형식

`~/.claude/aol/{host}-{YYYY-MM}.jsonl`. 한 줄에 레코드 하나, append만 해요. 머신마다 파일이 다르므로 동기화해도 충돌하지 않아요.

공통 필드는 `v`(스키마 버전), `ts`(UTC), `sid`, `host`, `repo`(origin URL의 이름, 워크트리에서도 같은 값), `branch`, `type`이에요.

- `SESSION` — SessionStart. `source`(startup/resume/clear/compact/fork). `fork`인 세션은 LLM이 만든 프롬프트를 받으므로 집계에서 빼요.
- `Q` — UserPromptSubmit. `prompt` 원문.
- `SKILL` — 마스터가 친 슬래시 커맨드(`via: prompt`) 또는 Skill 툴 호출(`via: tool`). `skill`, `args`.
- `ASK` — AskUserQuestion 직전. `headers`, `questions`.
- `EDIT` — Edit/Write 직후. `tool`, `path`.
- `TAG` — 응답 마커. `intent`, `object`, `size`.
- `CORR` — 마커에 `corr=`가 있을 때. `what`, `rule`.
- `STOP` — 턴 종료. `turns`(distinct requestId), `tools`(tool_use 수), `sec`(직전 Q부터 경과 초).
- `BLOCK` — 마커 문제로 되돌린 턴. `reason`(marker-missing/marker-invalid), `line`.
- `END` — SessionEnd. `reason`.

## 자동화 단위와 지표

단위는 `(intent, object)`예요. 배치는 브랜치 이름의 설명 부분이나 EDIT의 주 파일 경로를 기계 키로 우선 쓰고, object는 참고 라벨로 써요.

- 빈도 F: 최근 30일, 서로 다른 세션 기준 TAG 건수. `continue`는 빼요.
- 비용 C: 그 단위 구간의 STOP `tools`, `turns`, `sec` 중앙값.
- 마찰 K: 단위 1건당 ASK 수 + CORR 수.
- 스킬 후보: F ≥ 3인 단위를 F × C로 정렬한 상위 10개.
- CLAUDE.md 기본값 후보: 같은 ASK `header`가 서로 다른 세션 3개 이상.
- 훅 후보: 같은 CORR `rule`이 2회 이상.
- 성공 판정: 스킬 도입 뒤 같은 단위의 C와 K가 떨어지고, F가 SKILL 레코드로 옮겨가요.

바로 써볼 수 있는 집계 예시예요.

```sh
# intent+object 빈도 (세션 중복 제거)
cat ~/.claude/aol/*.jsonl | jq -r 'select(.type=="TAG" and .intent!="continue") | "\(.sid) \(.intent) \(.object)"' | sort -u | awk '{print $2, $3}' | sort | uniq -c | sort -rn | head

# 자주 묻는 질문
cat ~/.claude/aol/*.jsonl | jq -r 'select(.type=="ASK") | .sid as $s | .headers[] | "\($s) \(.)"' | sort -u | awk '{print $2}' | sort | uniq -c | sort -rn | head

# 마커 준수율
cat ~/.claude/aol/*.jsonl | jq -r 'select(.type=="TAG" or .type=="BLOCK") | .type' | sort | uniq -c
```

## 알려진 한계

- 마커 누락 검사는 이번 달 파일만 봐요. 월이 바뀌는 순간의 턴 하나는 검사에서 빠질 수 있어요.
- 마스터가 Esc로 응답을 끊으면 Stop 훅이 돌지 않아 그 턴의 TAG와 STOP이 없어요.
- `sec`에는 AskUserQuestion으로 마스터의 답을 기다린 시간이 섞여요. ASK 레코드 사이 구간을 빼고 보세요.
- 기존 Discord Stop 훅과 병렬로 돌아요. 되돌린 턴에도 "응답 완료" 알림이 한 번 더 갈 수 있어요.

## 다음 할 일

- 월간 집계를 돌리는 `aol-report` 스킬.
- intent 분류 판정 문제 10개를 `~/calibration`에 두고 라벨 일관성 검사.
- 반기 점검에서 이 로그로 만든 스킬이 0건이면 플러그인을 내려요.
