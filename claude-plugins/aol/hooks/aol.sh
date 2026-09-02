#!/bin/bash
# aol - Append-Only Label log
#
# Claude Code 훅 하나로 여러 이벤트를 받아 ~/.claude/aol/{host}-{YYYY-MM}.jsonl 에 한 줄씩 남긴다.
# 이 로그는 트랜스크립트(~/.claude/projects/**/*.jsonl)에 없는 "라벨"만 담는다. 원문 보존이 목적이 아니다.
# 트랜스크립트와는 sid(session_id)와 ts로 잇는다.
#
# 공통 필드: v ts sid host repo branch type
# type 별 추가 필드:
#   SESSION  SessionStart                       source
#   Q        UserPromptSubmit                   prompt
#   SKILL    UserPromptSubmit(/로 시작)         skill args via=prompt
#            PreToolUse(Skill)                  skill args via=tool
#   ASK      PreToolUse(AskUserQuestion)        headers questions
#   EDIT     PostToolUse(Edit|Write)            tool path
#   TAG      Stop, 마지막 줄 [aol] 마커         intent object size
#   CORR     Stop, 마커에 corr= 가 있을 때      what rule
#   STOP     Stop                               tools turns sec
#   BLOCK    Stop, 마커가 없거나 틀려 되돌림    reason
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
INTENTS='^(explore|plan|implement|fix|refactor|test|review|git|docs|config|ops|ask|continue)$'

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
    '{v:1, ts:$ts, sid:$sid, host:$host,
      repo:(if $repo=="" then null else $repo end),
      branch:(if $branch=="" then null else $branch end),
      type:$type} + ('"$filter"')' <<<"$input" >>"$file"
}

# 이 세션에서 가장 최근의 Q / TAG / BLOCK 레코드 type. Q 이면 마커가 있어야 한다.
last_marker_state() {
  [ -f "$file" ] || return 0
  tail -n 3000 "$file" | jq -r --arg sid "$sid" \
    'select(.sid==$sid and (.type=="Q" or .type=="TAG" or .type=="BLOCK")) | .type' 2>/dev/null | tail -n 1
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

block() {
  local rule=""
  [ -f "$RULE_FILE" ] && rule=$(cat "$RULE_FILE")
  jq -n --arg head "$1" --arg rule "$rule" '{decision:"block", reason:($head + "\n\n" + $rule)}'
}

stop_handler() {
  local active last line intent object size corr rule state
  active=$(jq -r '.stop_hook_active // false' <<<"$input")
  last=$(jq -r '.last_assistant_message // ""' <<<"$input")
  line=$(printf '%s\n' "$last" | grep -E '^\[aol\] ' | tail -n 1)
  state=$(last_marker_state)

  if [ -n "$line" ]; then
    intent=$(sed -nE 's/.*[[:space:]]intent=([a-z]+).*/\1/p' <<<"$line")
    object=$(sed -nE 's/.*[[:space:]]object=([A-Za-z0-9._\/-]+).*/\1/p' <<<"$line")
    size=$(sed -nE 's/.*[[:space:]]size=(5m|1h|3d).*/\1/p' <<<"$line")
    corr=$(sed -nE 's/.*[[:space:]]corr="([^"]*)".*/\1/p' <<<"$line")
    rule=$(sed -nE 's/.*[[:space:]]rule=([^[:space:]]+).*/\1/p' <<<"$line")

    if [[ "$intent" =~ $INTENTS ]] && [ -n "$object" ] && [ -n "$size" ]; then
      append TAG '{intent:$intent, object:$object, size:$size}' \
        --arg intent "$intent" --arg object "$object" --arg size "$size"
      if [ -n "$corr" ]; then
        append CORR '{what:$what, rule:(if $rule=="" or $rule=="none" then null else $rule end)}' \
          --arg what "$corr" --arg rule "$rule"
      fi
      append STOP "$(stop_stats)"
      return
    fi

    # 마커는 있는데 형식이 틀림
    if [ "$active" != "true" ]; then
      append BLOCK '{reason:"marker-invalid", line:$line}' --arg line "$line"
      block "응답 마지막 줄의 [aol] 마커 형식이 틀렸습니다: ${line}. intent는 정해진 목록 중 하나, object는 kebab-case, size는 5m/1h/3d 여야 합니다. 아래 규칙대로 고쳐서 응답을 마무리하세요."
      return
    fi
    append STOP "$(stop_stats)"
    return
  fi

  # 마커 없음. 이 세션의 마지막 마스터 프롬프트(Q)에 아직 TAG 가 없으면 되돌린다.
  if [ "$state" = "Q" ] && [ "$active" != "true" ]; then
    append BLOCK '{reason:"marker-missing"}'
    block "응답 마지막 줄에 [aol] 마커가 없습니다. 아래 규칙대로 마커 한 줄을 붙여 응답을 마무리하세요."
    return
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
    if [[ "$(jq -r '.prompt // ""' <<<"$input")" == /* ]]; then
      append SKILL '{skill:(.prompt | split(" ")[0] | ltrimstr("/")), args:(.prompt | split(" ")[1:] | join(" ")), via:"prompt"}'
    else
      append Q '{prompt:(.prompt // "")}'
    fi
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
