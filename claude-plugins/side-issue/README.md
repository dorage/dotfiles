# side-issue

작업 중 발견한 **지금 작업과 무관한 문제**를, 메인 세션의 컨텍스트를 방해하지 않고
자족적 GitHub 이슈로 올리는 플러그인이에요.

## 동작 원리

1. 플러그인의 **SessionStart 훅**이 매 세션 시작 시 `current session_id: {uuid}` 를
   컨텍스트에 주입해요 (환경변수에는 session_id 가 없어서 훅이 유일한 정확한 출처예요).
2. 작업 중 무관 문제를 발견하면 **side-issue 스킬**이 그 id 로
   `claude --resume {id} --fork-session --bg` 포크를 띄우고 즉시 본 작업으로 복귀해요.
3. 포크된 세션은 발견 맥락(파일:라인, 실측, 재현 경로)을 통째로 물려받아
   이슈 본문만 읽고도 해결에 착수할 수 있는 이슈를 `gh issue create` 로 올려요.

## 설치

이 플러그인은 dotfiles 리포의 로컬 마켓플레이스 `dotfiles`(`~/workspace/dotfiles/claude-plugins`)에 속해요.

```sh
claude plugin marketplace add ~/workspace/dotfiles/claude-plugins   # 이미 등록돼 있으면 생략
claude plugin install side-issue@dotfiles
```

설치 후 새 세션에서 `/prerequisite` 를 실행하면 OS에 맞는 환경 점검
(claude CLI 버전·포크 플래그, gh 인증, python3)과 부족한 것의 설치를 도와요.
CLAUDE.md 에 강제력 한 줄(발견 시 반드시 이 경로로)을 넣을지도 그때 물어봐요 —
글로벌(`~/.claude/CLAUDE.md`) / 프로젝트 / 추가 안 함 중에서 골라요.

## 전제 조건

- claude CLI — `--fork-session`, `--background` 플래그를 지원하는 버전
- `gh` CLI + `gh auth login` 인증
- `python3` (SessionStart 훅이 사용)

## 주의

- 포크의 session_id 는 반드시 훅이 주입한 값만 써요. "최신 transcript 파일" 같은
  휴리스틱은 병렬 세션 환경에서 **남의 세션을 포크**해요 (2026-08-26 실증).
- `--bg` 와 `--print` 는 충돌해요. 포크 프롬프트는 positional 인자로 줘요.
