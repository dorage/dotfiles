#!/bin/bash
# aol - Append-Only Log
#
# Claude Code 훅 하나로 여러 이벤트를 받아 ~/.claude/aol/{host}-{YYYY-MM}.jsonl 에 한 줄씩 남긴다.
# 목적은 하나다: 마스터가 실제로 친 프롬프트 원문을 빠짐없이, 오염 없이 남긴다.
# 반복되는 요청을 찾는 일은 /aol:report 가 그때그때 원문을 다시 읽어서 한다.
# 이 훅은 분류하지 않는다. 라벨을 붙이는 순간 나중에 다르게 볼 자유가 사라진다.
#
# 공통 필드: v ts sid host repo branch type
# type 별 추가 필드:
#   SESSION  SessionStart                       source
#   Q        UserPromptSubmit(마스터 발화)      prompt
#   SYS      UserPromptSubmit(시스템 주입)      kind
#   SKILL    UserPromptSubmit(슬래시 커맨드)    skill args via=prompt
#            PreToolUse(Skill)                  skill args via=tool
#   ASK      PreToolUse(AskUserQuestion)        headers questions
#   EDIT     PostToolUse(Edit|Write)            tool path
#   CORR     Stop, 응답에 [aol] corr= 가 있음   what rule
#   STOP     Stop                               turns tools sec
#   END      SessionEnd                         reason
#
# 끄기: AOL_DISABLE=1 (배치 스크립트가 claude -p 를 돌릴 때 자기 로그를 남기지 않도록)
# 위치 바꾸기: AOL_DIR=/path
set -u

[ "${AOL_DISABLE:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")
[ -z "$event" ] && exit 0

# 서브에이전트 안에서 도는 훅은 기록하지 않는다. 훅 입력에 agent_id 가 있으면 서브에이전트다.
[ -n "$(jq -r '.agent_id // empty' <<<"$input")" ] && exit 0

AOL_DIR="${AOL_DIR:-$HOME/.claude/aol}"
RULE_FILE="$(cd "$(dirname "$0")" && pwd)/rule.md"

sid=$(jq -r '.session_id // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
host=$(hostname -s 2>/dev/null || hostname)
file="$AOL_DIR/${host}-$(date -u +%Y-%m).jsonl"
mkdir -p "$AOL_DIR"

# 리포 이름. 워크트리에서도, 클론 위치가 달라도 같은 값이 나오도록 origin URL을 먼저 본다.
repo_name() {
  [ -d "$cwd" ] || return 0
  local url common
  url=$(git -C "$cwd" remote get-url origin 2>/dev/null) || url=""
  if [ -n "$url" ]; then
    basename "${url%.git}"
    return
  fi
  common=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null) || return 0
  [ -n "$common" ] && basename "$(cd "$cwd" && cd "$(dirname "$common")" && pwd)"
}
repo=$(repo_name)
branch=$( [ -d "$cwd" ] && git -C "$cwd" branch --show-current 2>/dev/null || true)

# append TYPE FILTER [jq 인자...]
#   FILTER 는 훅 입력 JSON을 받아 추가 필드 객체를 만드는 jq 필터.
#   공통 필드와 합쳐 한 줄로 append 한다.
append() {
  local type="$1" filter="$2"
  shift 2
  jq -c "$@" --arg ts "$ts" --arg sid "$sid" --arg host "$host" --arg repo "$repo" --arg branch "$branch" --arg type "$type" \
    '{v:2, ts:$ts, sid:$sid, host:$host,
      repo:(if $repo=="" then null else $repo end),
      branch:(if $branch=="" then null else $branch end),
      type:$type} + ('"$filter"')' <<<"$input" >>"$file"
}

# 직전 Q 이후의 턴 수, tool 호출 수, 경과 초를 JSON 으로 돌려준다.
stop_stats() {
  local transcript q_ts sec stats q_epoch now_epoch
  transcript=$(jq -r '.transcript_path // empty' <<<"$input")
  sec=null
  q_ts=$( [ -f "$file" ] && tail -n 3000 "$file" | jq -r --arg sid "$sid" 'select(.sid==$sid and .type=="Q") | .ts' 2>/dev/null | tail -n 1)
  if [ -n "$q_ts" ]; then
    q_epoch=$(date -j -u -f %Y-%m-%dT%H:%M:%SZ "$q_ts" +%s 2>/dev/null || date -u -d "$q_ts" +%s 2>/dev/null || echo "")
    now_epoch=$(date -u +%s)
    [ -n "$q_epoch" ] && sec=$((now_epoch - q_epoch))
  fi
  stats='{"turns":null,"tools":null}'
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    stats=$(tail -n 4000 "$transcript" | jq -cs '
      [ .[] | select(.type=="user" or .type=="assistant") ] as $m
      | ([ range(0; $m|length) | select(
            $m[.].type=="user" and (($m[.].isMeta // false)|not)
            and ( ($m[.].message.content|type)=="string"
                  or (($m[.].message.content|type)=="array" and any($m[.].message.content[]; .type=="text")) )
        ) ] | last) as $i
      | (if $i==null then $m else $m[$i+1:] end | map(select(.type=="assistant"))) as $a
      | { turns: ([$a[].requestId] | unique | length),
          tools: ([$a[] | .message.content[]? | select(.type=="tool_use")] | length) }' 2>/dev/null) \
      || stats='{"turns":null,"tools":null}'
  fi
  echo "$stats + {sec: $sec}"
}

# 마스터의 프롬프트를 세 갈래로 가른다.
#   슬래시 커맨드  -> SKILL
#   시스템 주입    -> SYS   (<task-notification> 같은 것. 마스터 발화가 아니다)
#   그 외          -> Q     (원문 그대로)
#
# 슬래시 판정은 "/" 하나로 하지 않는다. 마스터가 파일을 끌어다 놓으면 프롬프트가
# "/Users/..." 로 시작하는데, 예전 판정은 이걸 커맨드로 잘못 읽어 원문을 통째로 날렸다.
# 커맨드 이름 뒤에 공백이나 줄끝이 와야 커맨드로 본다.
prompt_handler() {
  local prompt
  prompt=$(jq -r '.prompt // ""' <<<"$input")

  if [[ "$prompt" =~ ^/[A-Za-z][A-Za-z0-9:_-]*([[:space:]]|$) ]]; then
    append SKILL '{skill:(.prompt | ltrimstr("/") | sub("\\s[\\s\\S]*$";"")),
                   args:(.prompt | ltrimstr("/") | sub("^\\S+\\s*";"")),
                   via:"prompt"}'
    return
  fi

  if [[ "$prompt" == \<* ]]; then
    append SYS '{kind:(.prompt | try (capture("^<(?<t>[A-Za-z][A-Za-z0-9_-]*)").t) catch null)}'
    return
  fi

  append Q '{prompt:(.prompt // "")}'
}

# 응답 마지막 줄의 [aol] 마커는 정정(corr)일 때만 붙는다.
# 없는 것이 정상이므로 되돌리지 않는다. 무엇을 왜 틀렸는지는 프롬프트 원문에서
# 복원할 수 없어서, 이 한 줄만 LLM 에게 맡긴다.
stop_handler() {
  local last line corr rule
  last=$(jq -r '.last_assistant_message // ""' <<<"$input")
  line=$(printf '%s\n' "$last" | grep -E '^\[aol\] ' | tail -n 1)

  if [ -n "$line" ]; then
    corr=$(sed -nE 's/.*[[:space:]]corr="([^"]*)".*/\1/p' <<<"$line")
    rule=$(sed -nE 's/.*[[:space:]]rule=([^[:space:]]+).*/\1/p' <<<"$line")
    if [ -n "$corr" ]; then
      append CORR '{what:$what, rule:(if $rule=="" or $rule=="none" then null else $rule end)}' \
        --arg what "$corr" --arg rule "$rule"
    fi
  fi

  append STOP "$(stop_stats)"
}

case "$event" in
  SessionStart)
    append SESSION '{source:(.source // null)}'
    if [ -f "$RULE_FILE" ]; then
      jq -n --rawfile rule "$RULE_FILE" \
        '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$rule}}'
    fi
    ;;
  UserPromptSubmit)
    prompt_handler
    ;;
  PreToolUse)
    case "$(jq -r '.tool_name // empty' <<<"$input")" in
      AskUserQuestion)
        append ASK '{headers:[.tool_input.questions[]?.header], questions:[.tool_input.questions[]?.question]}' ;;
      Skill)
        append SKILL '{skill:(.tool_input.skill // null), args:(.tool_input.args // null), via:"tool"}' ;;
    esac
    ;;
  PostToolUse)
    append EDIT '{tool:(.tool_name // null), path:(.tool_input.file_path // null)}'
    ;;
  Stop)
    stop_handler
    ;;
  SessionEnd)
    append END '{reason:(.reason // null)}'
    ;;
esac
exit 0
