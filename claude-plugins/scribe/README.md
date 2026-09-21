# scribe (문서화 게이트)

코드를 바꾼 뒤 README.md 와 docs/ 문서 갱신이 빠지지 않도록, 문서화 규칙을 세션에 주입하고 세션이 멈추기 직전 체크리스트를 한 번 지나가게 하는 Claude Code 플러그인이에요.

## 동작

- SessionStart 훅이 `hooks/rule.md` 의 문서화 규칙을 컨텍스트로 주입해요. compact 뒤에도 다시 들어가요.
- 같은 시점에 작업트리의 변경 지문을 기준선으로 저장해요. 세션 시작 전부터 더러웠던 작업트리는 이번 세션 책임이 아니라서 체크리스트를 띄우지 않아요.
- PostToolUse 훅이 Edit, Write, MultiEdit, NotebookEdit 로 고친 파일 경로를 상태 파일에 쌓아요. git 리포가 아닌 곳에서 변경을 알아내는 보조 수단이에요.
- Stop 훅이 기준선 이후 코드 변경이 있으면 `hooks/checklist.md` 를 reason 으로 넣어 `decision: block` 으로 응답을 되돌려요. LLM 은 체크리스트 각 항목에 "해당 없음" 또는 "갱신함 (파일명)" 으로 답하고, 필요한 문서를 고친 뒤 응답을 마무리해요.
- 되돌림에 답한 뒤의 Stop(`stop_hook_active=true`) 은 그 시점의 지문을 기준선으로 갱신하고 통과시켜요. 그래서 변경 묶음당 한 번만 뜨고, 문서 갱신으로 바뀐 파일 때문에 다시 뜨지 않아요.
- 서브에이전트 훅(입력에 `agent_id` 가 있는 경우)은 건너뛰어요.
- SessionEnd 훅이 상태 파일을 지워요.

### 변경 지문

- git 리포면 `git status --porcelain --untracked-files=all` 의 경로 목록이에요. 스테이지, 미스테이지, 미추적 파일을 모두 봐요. Bash 로 고친 파일도 잡혀요.
- git 리포가 아니면 PostToolUse 로 쌓은 경로 목록이에요.
- 두 경우 모두 `README.md`, `docs/` 아래, 확장자 `.md` 파일은 빼요. 문서만 고친 턴은 체크리스트를 띄우지 않기 위해서예요.

## 문서화 규칙

- 다음이 바뀌면 `README.md` 를 갱신해요.
  - 프로젝트 디렉터리 구조
  - 설치 방법, 가동 전 수동 절차
  - `package.json` 의 scripts
  - 요구사항
  - 사전설정
- 다음이 바뀌면 `docs/` 아래 문서를 갱신해요.
  - 코드 컨벤션 -> `docs/convention.md`
  - 테스팅 원칙 -> `docs/testing.md`
  - API 엔드포인트 -> `docs/api-endpoint.md`
  - API 버저닝 -> `docs/api-versioning.md`
  - 동작 방식 -> `docs/how_it_works.md`

규칙 본문은 `hooks/rule.md`, 체크리스트 본문은 `hooks/checklist.md` 에 있어요. 항목을 바꾸려면 두 파일을 함께 고쳐요.

## 설치

```sh
claude plugin marketplace add ~/.config/claude-plugins
claude plugin install scribe@dotfiles
```

`jq` 가 필요해요. hooks 폴더를 고친 뒤에는 `/reload-plugins` 또는 재시작이 필요해요. 마켓플레이스에서 설치한 플러그인은 캐시로 복사되므로 수정 후 `claude plugin update scribe@dotfiles` 를 돌려요.

- 끄기: `claude plugin disable scribe@dotfiles`
- 특정 프로세스에서만 끄기: 환경변수 `SCRIBE_DISABLE=1`
- 특정 프로젝트에서만 끄기: 프로젝트 루트(git 최상위, 없으면 cwd)에 `.scribe-ignore` 파일을 둬요. 문서화 대상이 아닌 리포용이에요.
- 상태 파일 위치 바꾸기: 환경변수 `SCRIBE_DIR` (기본 `~/.claude/scribe`)

## 상태 파일

`~/.claude/scribe/{session_id}.json` 하나예요. `checked_fp`(마지막으로 체크리스트를 지난 변경 지문)와 `edits`(PostToolUse 로 쌓은 경로)를 담고, 세션이 끝나면 지워져요.

## 검증

실제 세션 없이 가짜 훅 입력을 파이프로 넣어 확인할 수 있어요.

```sh
cd claude-plugins/scribe
export SCRIBE_DIR=/tmp/scribe-test; S=test-sid
ev() { printf '{"hook_event_name":"%s","session_id":"%s","cwd":"%s"%s}' "$1" "$S" "$PWD" "${2:-}"; }

ev SessionStart | hooks/scribe.sh | jq .                     # 규칙이 additionalContext 로 나온다
ev Stop ',"stop_hook_active":false' | hooks/scribe.sh        # 변경 없음: 출력 없음
touch dummy.ts
ev Stop ',"stop_hook_active":false' | hooks/scribe.sh | jq . # decision=block, reason 에 dummy.ts
ev Stop ',"stop_hook_active":true'  | hooks/scribe.sh        # 통과, 기준선 갱신
ev Stop ',"stop_hook_active":false' | hooks/scribe.sh        # 같은 변경: 출력 없음
rm dummy.ts
```

## 알려진 한계

- git 리포가 아니면서 Bash(sed, heredoc)로만 고친 변경은 잡지 못해요. git 리포에서는 지문으로 잡혀요.
- 되돌림 뒤 LLM 이 실제로 문서를 고쳤는지는 검증하지 않아요. 체크리스트를 지나가게 하는 것이 목적이고, 강제 검증은 마찰이 커서 넣지 않았어요.
- aol 의 Stop 훅과 같은 턴에 둘 다 되돌리면 두 reason 이 함께 들어와요. 되돌린 뒤의 응답에서 aol 마커가 빠져도 aol 은 다시 되돌리지 않아요(`stop_hook_active`).
- 마스터가 Esc 로 응답을 끊으면 Stop 훅이 돌지 않아 체크리스트가 뜨지 않아요. 다음 턴의 Stop 에서 뜨게 돼요.
