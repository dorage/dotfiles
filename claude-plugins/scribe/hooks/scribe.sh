#!/bin/bash
# scribe - 문서화 게이트
#
# Claude Code 훅 하나로 여러 이벤트를 받는다.
#   SessionStart  rule.md(문서화 규칙)를 컨텍스트로 주입하고, 작업트리 변경 지문을 기준선으로 저장한다.
#   PostToolUse   Edit|Write|MultiEdit|NotebookEdit 로 고친 파일 경로를 상태 파일에 쌓는다 (git 리포가 아닐 때의 보조 수단).
#   Stop          기준선 이후 코드 변경이 있으면 checklist.md 를 reason 으로 넣어 응답을 한 번 되돌린다.
#                 되돌림에 답한 뒤의 Stop(stop_hook_active=true) 은 지문을 기준선으로 갱신하고 통과시킨다.
#   SessionEnd    상태 파일을 지운다.
#
# 변경 지문: git 리포면 `git status --porcelain` 의 경로 목록, 아니면 상태 파일의 edits 목록.
#           README.md, docs/ 아래, *.md 는 제외한다 (문서만 고친 턴은 체크리스트를 띄우지 않는다).
#
# 끄기: SCRIBE_DISABLE=1, 또는 프로젝트 루트에 .scribe-ignore 파일
# 상태 위치 바꾸기: SCRIBE_DIR=/path (기본 ~/.claude/scribe)
set -u

[ "${SCRIBE_DISABLE:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")
[ -z "$event" ] && exit 0

# 서브에이전트 안에서 도는 훅은 건너뛴다.
[ -n "$(jq -r '.agent_id // empty' <<<"$input")" ] && exit 0

SCRIBE_DIR="${SCRIBE_DIR:-$HOME/.claude/scribe}"
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
RULE_FILE="$HOOK_DIR/rule.md"
CHECKLIST_FILE="$HOOK_DIR/checklist.md"

sid=$(jq -r '.session_id // empty' <<<"$input")
[ -z "$sid" ] && sid="${CLAUDE_CODE_SESSION_ID:-unknown}"
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -d "$cwd" ] || cwd="$PWD"
state="$SCRIBE_DIR/$sid.json"
mkdir -p "$SCRIBE_DIR"

# 프로젝트 루트: git 최상위, 없으면 cwd
project_root() {
  git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd"
}

read_state() {
  [ -f "$state" ] && cat "$state" || echo '{"checked_fp":"","edits":[]}'
}

write_state() {
  printf '%s\n' "$1" >"$state.tmp" && mv "$state.tmp" "$state"
}

# 문서 파일은 지문에서 뺀다: README.md, docs/ 아래, 확장자 .md
filter_docs() {
  grep -Ev '(^|/)README\.md$|(^|/)docs/|\.md$' || true
}

# 변경 파일 목록(한 줄에 하나, 정렬, 중복 제거)
changed_files() {
  if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # porcelain: "XY path" 또는 "R  old -> new". 새 경로만 쓴다.
    git -C "$cwd" status --porcelain --untracked-files=all 2>/dev/null \
      | cut -c4- | sed -E 's/^.* -> //'
  else
    read_state | jq -r '.edits[]?'
  fi | filter_docs | sort -u
}

fingerprint() {
  local files="$1"
  [ -z "$files" ] && { echo ""; return; }
  if command -v sha1sum >/dev/null 2>&1; then printf '%s\n' "$files" | sha1sum | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then printf '%s\n' "$files" | shasum | cut -d' ' -f1
  else printf '%s\n' "$files" | cksum | cut -d' ' -f1
  fi
}

set_checked() {
  write_state "$(read_state | jq -c --arg fp "$1" '.checked_fp = $fp')"
}

# 최대 30개까지 나열, 넘으면 "외 N개"
summarize_files() {
  local files="$1" n
  n=$(printf '%s\n' "$files" | grep -c .)
  if [ "$n" -le 30 ]; then
    printf '%s\n' "$files" | paste -sd, - | sed 's/,/, /g'
  else
    printf '%s, 외 %d개' "$(printf '%s\n' "$files" | head -n 30 | paste -sd, - | sed 's/,/, /g')" "$((n - 30))"
  fi
}

block_with_checklist() {
  local files="$1" summary reason
  summary=$(summarize_files "$files")
  reason=$(sed "s|{{CHANGED_FILES}}|$(printf '%s' "$summary" | sed 's/[&|\\]/\\&/g')|" "$CHECKLIST_FILE")
  jq -n --arg reason "$reason" '{decision:"block", reason:$reason}'
}

stop_handler() {
  local active files fp checked
  active=$(jq -r '.stop_hook_active // false' <<<"$input")
  files=$(changed_files)
  fp=$(fingerprint "$files")

  # 되돌림에 답한 뒤의 Stop: 다시 되돌리면 무한 루프. 지금 상태를 기준선으로 삼고 통과.
  if [ "$active" = "true" ]; then
    set_checked "$fp"
    return
  fi

  [ -f "$(project_root)/.scribe-ignore" ] && return
  [ -f "$CHECKLIST_FILE" ] || return

  checked=$(read_state | jq -r '.checked_fp // ""')
  [ "$fp" = "$checked" ] && return
  [ -z "$files" ] && { set_checked "$fp"; return; }

  block_with_checklist "$files"
}

case "$event" in
  SessionStart)
    # 세션 시작 전부터 더러웠던 작업트리는 이번 세션 책임이 아니다. 기준선으로 저장.
    write_state "$(jq -n --arg fp "$(fingerprint "$(changed_files)")" '{checked_fp:$fp, edits:[]}')"
    if [ -f "$RULE_FILE" ]; then
      jq -n --rawfile rule "$RULE_FILE" \
        '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$rule}}'
    fi
    ;;
  PostToolUse)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
    if [ -n "$path" ]; then
      write_state "$(read_state | jq -c --arg p "$path" '.edits = ((.edits // []) + [$p] | unique)')"
    fi
    ;;
  Stop)
    stop_handler
    ;;
  SessionEnd)
    rm -f "$state" "$state.tmp"
    ;;
esac
exit 0
