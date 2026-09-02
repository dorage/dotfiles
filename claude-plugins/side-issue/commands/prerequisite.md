---
description: side-issue 플러그인의 실행 환경을 OS에 맞게 점검하고, 부족한 것의 설치를 돕고, CLAUDE.md 강제력 한 줄의 추가 여부를 물어 반영한다.
---

# side-issue 환경 점검 (prerequisite)

side-issue 플러그인이 동작하려면 네 가지가 필요하다. 아래를 순서대로 점검하고,
부족한 항목은 OS에 맞는 설치를 도운 뒤, 마지막에 결과를 표로 요약해 보고한다.

## 1. OS 판별

`uname -s` 로 판별한다 (Darwin = macOS, Linux = 리눅스). 설치 도움 명령은 이 결과에 맞춘다.
리눅스는 `command -v apt-get || command -v dnf` 로 패키지 매니저까지 가려낸다.

## 2. 점검 항목

각 항목은 "확인 명령 → 실패 시 설치 도움" 순서다. **설치 명령은 어떤 것을 실행할지
먼저 보여주고 마스터의 확인을 받은 뒤에 실행한다.**

| 항목 | 확인 | 실패 시 |
| --- | --- | --- |
| claude CLI | `claude --version` | https://claude.com/claude-code 설치 안내 |
| 포크 플래그 지원 | `claude --help` 출력에 `--fork-session` 과 `--background` 가 모두 있는지 | `claude update` 제안 |
| gh CLI | `command -v gh` | macOS: `brew install gh` / apt: `sudo apt-get install gh` / dnf: `sudo dnf install gh` |
| gh 인증 | `gh auth status` | `gh auth login` 을 마스터가 직접 실행하도록 안내 (대화형이라 대신 실행 불가) |
| python3 | `command -v python3` | macOS: `xcode-select --install` 또는 `brew install python3` / apt: `sudo apt-get install python3` |
| git | `command -v git` | OS 패키지 매니저로 설치 안내 |

## 3. SessionStart 훅 주입 확인

현재 세션의 컨텍스트에 `current session_id: {uuid}` 가 있는지 본다.

- 있으면: 훅 정상 작동.
- 없으면: 이 세션이 플러그인 설치(또는 활성화) 전에 시작된 것이다.
  "환경 점검은 통과했고, 훅 주입은 새 세션부터 적용돼요 — 새 세션에서
  `/prerequisite` 를 한 번 더 돌리면 최종 확인돼요"라고 안내한다.
  훅 명령 자체는 다음 pipe-test 로 즉시 검증할 수 있다:

  ```bash
  echo '{"session_id":"test"}' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"current session_id: "+d["session_id"]}}))'
  ```

## 4. CLAUDE.md 강제력 한 줄 (선택)

스킬 description 만으로도 모델이 side-issue 를 인지하지만, "무관 문제를 발견하면
반드시 이 경로로" 라는 강제력은 CLAUDE.md 규칙이 더 강하다. AskUserQuestion 으로
다음 세 가지 중 하나를 묻고, 답에 따라 반영한다:

- **글로벌에 추가** (`~/.claude/CLAUDE.md`) — 모든 프로젝트에 적용
- **이 프로젝트에 추가** (프로젝트 루트 `CLAUDE.md`) — 이 리포에서만, 팀원에게도 커밋으로 전파됨
- **추가 안 함** — 스킬 description 트리거만으로 운용

추가할 한 줄 (이미 같은 내용의 줄이 있으면 중복 추가하지 않는다):

```markdown
- 작업 중 지금 작업과 무관한 문제를 발견하면 그 자리에서 고치지 않고 side-issue 스킬(`/side-issue {문제 한 줄}`)로 백그라운드 포크를 띄워 GitHub 이슈로 만든다. 발견 맥락은 포크가 물려받으므로 메인 작업의 컨텍스트를 지킬 수 있다.
```

대상 파일이 없으면 만들지 말고, 어느 파일에 어떻게 만들지 마스터에게 되묻는다.

## 5. 결과 요약

항목별 통과/실패/조치 내용을 표로 보고하고, 실패가 남아 있으면
"이것이 해결되기 전에는 side-issue 가 {구체적으로 어떤 단계에서} 실패한다"를 명시한다.
