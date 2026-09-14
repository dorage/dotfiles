#!/bin/sh
# gnothi 훅 진입점.
#
# bun 이 있으면 hooks/gnothi.ts 를 실행한다.
# bun 이 없으면 (SessionStart 에 한해) LLM 에게 "bun 이 없다, 설치해 달라"는 컨텍스트를 준다.
# 그러면 에이전트가 마스터 확인을 받아 bun 을 설치하고, 다음 세션부터 정상 동작한다.
# 이 파일은 POSIX sh 만 쓰고 외부 도구(jq, bun, python)에 의존하지 않는다.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"

# 훅은 로그인 셸이 아닐 수 있어 ~/.bun/bin 이 PATH 에 없을 수 있다.
PATH="${BUN_INSTALL:-$HOME/.bun}/bin:$HOME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

# GNOTHI_BUN 이 있으면 그 바이너리만 쓴다 (경로 고정, 테스트에서 "bun 없음" 재현).
if [ -n "${GNOTHI_BUN:-}" ]; then
  bun_bin="$GNOTHI_BUN"
else
  bun_bin=$(command -v bun 2>/dev/null || true)
fi

if [ -n "$bun_bin" ] && [ -x "$bun_bin" ]; then
  exec "$bun_bin" "$root/hooks/gnothi.ts"
fi

# ---- bun 이 없을 때 ----
[ "${GNOTHI_DISABLE:-0}" = "1" ] && exit 0

input=$(cat)

# 서브에이전트 훅은 건너뛴다.
case "$input" in *'"agent_id"'*) exit 0 ;; esac

# 알릴 곳은 SessionStart 뿐이다. 프롬프트마다 반복하면 소음이다.
case "$input" in *'"hook_event_name":"SessionStart"'* | *'"hook_event_name": "SessionStart"'*) ;; *) exit 0 ;; esac

# jq 없이 session_id 를 꺼낸다. 훅 입력이 없으면 환경변수(2.1.270 에서 확인)를 쓴다.
sid=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
[ -z "$sid" ] && sid="${CLAUDE_CODE_SESSION_ID:-unknown}"

ctx="current session_id: $sid\ncurrent model: unknown (via none)\n(gnothi: 훅 실행기 bun 을 찾지 못해 모델 판별과 모델별 룰 주입을 건너뛰었다. 마스터에게 알리고 확인을 받은 뒤 \`curl -fsSL https://bun.sh/install | bash\` 로 설치하라. macOS 는 \`brew install oven-sh/bun/bun\` 도 된다. 설치 뒤 새 세션부터 정상 동작한다. /gnothi:setup 커맨드가 같은 일을 안내한다.)"

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
exit 0
