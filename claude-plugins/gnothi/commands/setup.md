---
description: gnothi 훅의 실행기 bun 을 점검하고, 없으면 마스터 확인을 받아 설치한다. 설치 뒤 훅이 실제로 동작하는지 파이프 테스트로 확인한다.
---

# gnothi 환경 준비 (setup)

gnothi 훅은 `hooks/gnothi.ts` 를 bun 으로 실행한다. bun 이 없으면 훅이 세션 시작 때
"bun 을 찾지 못했다"는 컨텍스트만 남기고 모델별 룰 주입을 건너뛴다. 이 커맨드는 그 상태를 고친다.

## 1. bun 확인

```bash
command -v bun && bun --version
```

훅은 `~/.bun/bin`, `/opt/homebrew/bin`, `/usr/local/bin` 도 PATH 에 덧붙여 찾는다.
위 명령이 실패해도 `ls ~/.bun/bin/bun` 이 있으면 설치는 된 것이고, 셸 PATH 만 빠진 것이다.
그 경우 설치를 반복하지 말고 마스터에게 셸 rc 에 `export PATH="$HOME/.bun/bin:$PATH"` 를 넣도록 안내한다.

## 2. 없으면 설치

**설치 명령은 어떤 것을 실행할지 먼저 보여주고 마스터의 확인을 받은 뒤에 실행한다.**
`uname -s` 로 OS 를 보고 하나를 고른다.

- 공통(macOS, Linux): `curl -fsSL https://bun.sh/install | bash`
- macOS 에서 Homebrew 를 쓰고 있으면: `brew install oven-sh/bun/bun`

설치가 끝나면 `~/.bun/bin/bun --version` 으로 확인한다.

## 3. 훅 동작 확인

플러그인 루트는 `claude plugin list` 에서 gnothi 의 설치 경로로 알 수 있다
(마켓플레이스 설치는 보통 `~/.claude/plugins/cache/dotfiles/gnothi/{버전}`).

```bash
echo '{"hook_event_name":"SessionStart","session_id":"test","model":"claude-haiku-4-5"}' \
  | sh {플러그인 루트}/hooks/run.sh
```

출력 JSON 의 `additionalContext` 에 `current model: claude-haiku-4-5 (via hook)` 와
`(gnothi rule: haiku.md)` 가 있으면 정상이다. `bun 을 찾지 못해` 문구가 그대로 나오면
훅 환경의 PATH 에 bun 이 없는 것이니 1번으로 돌아간다.

## 4. 보고

- bun 유무, 설치했으면 방법, 훅 테스트 결과를 목록으로 보고한다.
- 지금 세션에는 룰이 주입되지 않았으므로 "새 세션부터 모델별 룰이 들어간다"고 알린다.
