# side-issue

작업 중 발견한 **지금 작업과 무관한 문제**를, 메인 세션의 컨텍스트를 방해하지 않고
자족적 GitHub 이슈로 올리는 플러그인이에요.

## 동작 원리

- `gnothi` 플러그인의 **SessionStart 훅**이 매 세션 시작 시 `current session_id: {uuid}` 를
  컨텍스트에 주입해요. side-issue 는 이 값을 읽기만 해요.
- 작업 중 무관 문제를 발견하면 **side-issue 스킬**이 그 id 로
  `claude --resume {id} --fork-session --bg` 포크를 띄우고 즉시 본 작업으로 복귀해요.
- 포크된 세션은 발견 맥락(파일:라인, 실측, 재현 경로)을 통째로 물려받아
  이슈 본문만 읽고도 해결에 착수할 수 있는 이슈를 `gh issue create` 로 올려요.
- **Stop 훅**이 매 응답 직전에 한 번 끼어들어 점검표를 주입해요. LLM 은 이번 턴에서
  미뤄둔 **후속 작업**과 손대지 않은 **무관 문제**를 골라 위 스킬로 포크를 띄우고,
  `[side-issue] none` 또는 `[side-issue] forked=N` 한 줄로 점검을 마쳐요.
  발견을 LLM 의 기억에 맡기지 않고 응답마다 강제로 되짚게 하는 장치예요.

## Stop 훅이 침묵하는 경우

훅은 다음 상황이면 아무것도 하지 않고 응답을 그대로 보내요.

- Claude Code 가 Stop 훅 때문에 이미 이어가는 중(`stop_hook_active`)일 때. 무한 반복 방지예요.
- 서브에이전트 안의 Stop 일 때 (훅 입력에 `agent_id` 가 있어요).
- 포크 세션일 때. 스킬이 포크를 `SIDE_ISSUE_FORK=1` 로 띄우고, 훅은 마지막 프롬프트가
  `/side-issue` 커맨드인지도 함께 봐요. 포크가 포크를 낳지 않도록 이중으로 막아요.
- 이번 턴에 도구 호출이 없었을 때 (단순 질답). 기준은 `SIDE_ISSUE_MIN_TOOLS` 로 조정해요 (기본 1).
- 응답 안에 이미 `[side-issue]` 마커가 있을 때.
- `SIDE_ISSUE_DISABLE=1` 일 때. 배치 스크립트가 `claude -p` 를 돌릴 때 써요.

## 파일

- `hooks/hooks.json` — Stop 훅 등록
- `hooks/stop.sh` — 침묵 조건을 판정하고, 통과하면 `decision: block` 과 점검표를 돌려줘요
- `hooks/checklist.md` — 주입되는 점검표 본문. 골라낼 것, 제외할 것, 절차
- `skills/side-issue/SKILL.md` — 포크 띄우기(A)와 이슈 작성(B)
- `commands/prerequisite.md` — 환경 점검

## 설치

이 플러그인은 dotfiles 리포의 로컬 마켓플레이스 `dotfiles`(`~/.config/claude-plugins`)에 속해요.
session_id 주입은 같은 마켓플레이스의 `gnothi` 가 맡으므로 둘을 함께 설치해요.

```sh
claude plugin marketplace add ~/.config/claude-plugins   # 이미 등록돼 있으면 생략
claude plugin install gnothi@dotfiles
claude plugin install side-issue@dotfiles
```

설치 후 새 세션에서 `/prerequisite` 를 실행하면 OS에 맞는 환경 점검
(claude CLI 버전·포크 플래그, gh 인증, gnothi 설치 여부)과 부족한 것의 설치를 도와요.
CLAUDE.md 에 강제력 한 줄(발견 시 반드시 이 경로로)을 넣을지도 그때 물어봐요 —
글로벌(`~/.claude/CLAUDE.md`) / 프로젝트 / 추가 안 함 중에서 골라요.

## 전제 조건

- claude CLI — `--fork-session`, `--background` 플래그를 지원하는 버전
- `gh` CLI + `gh auth login` 인증
- `gnothi@dotfiles` 플러그인 (session_id 주입) 과 그 훅이 쓰는 `bun`
- `jq` (Stop 훅이 훅 입력과 트랜스크립트를 읽는 데 써요. 없으면 훅은 조용히 통과해요)

## 주의

- 포크의 session_id 는 반드시 훅이 주입한 값만 써요. "최신 transcript 파일" 같은
  휴리스틱은 병렬 세션 환경에서 **남의 세션을 포크**해요 (2026-08-26 실증).
- `--bg` 와 `--print` 는 충돌해요. 포크 프롬프트는 positional 인자로 줘요.
