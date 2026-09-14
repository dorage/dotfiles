#!/bin/bash
# gnothi - γνῶθι σεαυτόν (네 자신을 알라)
#
# LLM 이 "지금 나는 어느 세션에서, 어느 모델로 돌고 있는가"를 알게 한다.
#
#   SessionStart      session_id 와 model 을 컨텍스트에 주입하고, 모델에 맞는 룰(rules/*.md)을 함께 넣는다.
#                     startup/resume/clear/compact 모두 다시 주입한다. compact 뒤에도 룰이 남아야 하기 때문이다.
#   UserPromptSubmit  트랜스크립트의 마지막 assistant 메시지로 "실제로 답한 모델"을 확인한다.
#                     매칭되는 룰 집합이 바뀌었으면 룰을 다시 주입하고, 모델 이름만 바뀌었으면 한 줄로 알린다.
#   SessionEnd        세션 상태 파일을 지운다.
#
# 모델 판별 출처 (앞에서부터 처음 성공한 것을 쓴다):
#   hook        훅 입력의 .model  — Claude Code 가 넣어줄 때만 있다 (2.1.270 startup 에서는 없었다)
#   transcript  트랜스크립트의 마지막 assistant 메시지 .message.model — resume/compact 와 두 번째 프롬프트부터 확실하다
#   argv        부모 claude 프로세스의 --model 인자 — 별칭(opus, haiku, fable ...)일 수 있다
#   env         ANTHROPIC_MODEL
#   settings    {cwd}/.claude/settings.local.json → {cwd}/.claude/settings.json → ~/.claude/settings.json 의 .model
#   unknown     아무 데서도 못 찾음
#
# 룰 파일:
#   플러그인의 rules/*.md 와 $GNOTHI_RULES_DIR (기본 ~/.claude/gnothi/rules) 의 *.md.
#   같은 파일명이면 사용자 디렉터리의 것이 플러그인 것을 덮는다.
#   파일명(확장자 제외)이 모델 문자열에 대소문자 구분 없이 부분일치하면 주입한다. 예: fable.md ↔ claude-fable-5-1
#   default.md 는 다른 룰이 하나도 매칭되지 않을 때만 주입한다.
#
# 끄기: GNOTHI_DISABLE=1
# 상태 위치 바꾸기: GNOTHI_STATE_DIR (기본 ~/.claude/gnothi/state)
set -u

[ "${GNOTHI_DISABLE:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")
[ -z "$event" ] && exit 0

# 서브에이전트 안에서 도는 훅은 건너뛴다. 서브에이전트는 자기 컨텍스트가 따로 있고 세션 주인이 아니다.
[ -n "$(jq -r '.agent_id // empty' <<<"$input")" ] && exit 0

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RULES_DIR="$PLUGIN_DIR/rules"
USER_RULES_DIR="${GNOTHI_RULES_DIR:-$HOME/.claude/gnothi/rules}"
STATE_DIR="${GNOTHI_STATE_DIR:-$HOME/.claude/gnothi/state}"

sid=$(jq -r '.session_id // empty' <<<"$input")
[ -z "$sid" ] && sid="${CLAUDE_CODE_SESSION_ID:-}"
cwd=$(jq -r '.cwd // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
state_file="$STATE_DIR/${sid:-nosid}"

lower() { tr '[:upper:]' '[:lower:]'; }

# settings 의 model 값은 "claude-fable-5-1[1m]" 처럼 컨텍스트 윈도우 표기가 붙을 수 있다. 그 부분은 떼어낸다.
strip_suffix() { local m="$1"; printf '%s' "${m%%\[*}"; }

model_from_transcript() {
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 1
  local m
  m=$(grep -F '"type":"assistant"' "$transcript" 2>/dev/null | tail -n 20 \
      | jq -r '.message.model // empty' 2>/dev/null | grep -v '^<' | tail -n 1)
  [ -n "$m" ] && printf '%s' "$m"
}

model_from_argv() {
  local args m
  args=$(ps -o args= -p "$PPID" 2>/dev/null) || return 1
  m=$(sed -nE 's/.*--model[= ]+([^ ]+).*/\1/p' <<<"$args" | head -n 1)
  [ -n "$m" ] && printf '%s' "$m"
}

model_from_settings() {
  local f m
  for f in "$cwd/.claude/settings.local.json" "$cwd/.claude/settings.json" "$HOME/.claude/settings.json"; do
    [ -f "$f" ] || continue
    m=$(jq -r '.model // empty' "$f" 2>/dev/null)
    if [ -n "$m" ]; then strip_suffix "$m"; return 0; fi
  done
  return 1
}

# 출력: "모델<TAB>출처"
resolve_model() {
  local m
  m=$(jq -r '.model // empty' <<<"$input")
  if [ -n "$m" ]; then printf '%s\thook' "$(strip_suffix "$m")"; return; fi
  m=$(model_from_transcript) && { printf '%s\ttranscript' "$m"; return; }
  m=$(model_from_argv) && { printf '%s\targv' "$m"; return; }
  if [ -n "${ANTHROPIC_MODEL:-}" ]; then printf '%s\tenv' "$(strip_suffix "$ANTHROPIC_MODEL")"; return; fi
  m=$(model_from_settings) && { printf '%s\tsettings' "$m"; return; }
  printf 'unknown\tunknown'
}

# 룰 파일 목록. 파일명 기준으로 사용자 디렉터리가 플러그인 디렉터리를 덮는다. 출력은 파일명 정렬.
rule_files() {
  local dir f name
  for dir in "$RULES_DIR" "$USER_RULES_DIR"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      printf '%s\t%s\n' "$name" "$f"
    done
  done | sort -k1,1 -s | awk -F'\t' '{ path[$1]=$2 } END { for (n in path) print n "\t" path[n] }' | sort
}

# 모델에 매칭되는 룰 파일 경로들 (한 줄에 하나). 아무 것도 없으면 default.md.
match_rules() {
  local model_lc name path stem matched=0 default_path=""
  model_lc=$(printf '%s' "$1" | lower)
  while IFS=$'\t' read -r name path; do
    stem="${name%.md}"
    if [ "$stem" = "default" ]; then default_path="$path"; continue; fi
    case "$model_lc" in
      *"$(printf '%s' "$stem" | lower)"*) printf '%s\n' "$path"; matched=1 ;;
    esac
  done < <(rule_files)
  [ "$matched" = 0 ] && [ -n "$default_path" ] && printf '%s\n' "$default_path"
  return 0
}

# 룰 파일들을 이어 붙인다. 각 파일 앞에 어느 파일인지 한 줄 남긴다.
render_rules() {
  local path
  # 마지막 줄에 개행이 없어도 읽도록 `|| [ -n "$path" ]` 를 붙인다.
  while IFS= read -r path || [ -n "$path" ]; do
    [ -n "$path" ] || continue
    printf '\n(gnothi rule: %s)\n' "$(basename "$path")"
    cat "$path"
    printf '\n'
  done
}

emit() {
  # $1: 이벤트 이름, $2: 컨텍스트 본문
  jq -n --arg ev "$1" --arg ctx "$2" \
    '{hookSpecificOutput:{hookEventName:$ev, additionalContext:$ctx}}'
}

save_state() {
  # $1: 모델, $2: 룰 집합 (경로를 콤마로 이은 문자열)
  mkdir -p "$STATE_DIR"
  printf '%s\t%s\n' "$1" "$2" > "$state_file"
}

case "$event" in
  SessionStart)
    # 오래 남은 상태 파일 정리 (SessionEnd 가 안 불린 세션)
    [ -d "$STATE_DIR" ] && find "$STATE_DIR" -type f -mtime +7 -delete 2>/dev/null

    IFS=$'\t' read -r model source <<<"$(resolve_model)"
    rules=$(match_rules "$model")
    ruleset=$(printf '%s' "$rules" | tr '\n' ',')
    save_state "$model" "$ruleset"

    ctx="current session_id: ${sid:-unknown}"$'\n'"current model: $model (via $source)"
    # hook/transcript 는 실제로 답한(답할) 모델이다. 나머지는 추정이라, 시스템 프롬프트의 모델 ID 가 다르면 그쪽이 맞다.
    # 2.1.270 실측: `--model haiku` 로 띄운 세션이 실제로는 claude-opus-5 로 답했다 (argv 만 믿으면 틀린다).
    case "$source" in
      hook|transcript) ;;
      *) ctx="$ctx"$'\n'"(gnothi: 위 model 은 $source 에서 읽은 추정값이다. 시스템 프롬프트의 모델 ID 와 다르면 시스템 프롬프트가 맞다. 첫 응답 뒤부터는 실제로 답한 모델로 룰을 다시 준다.)" ;;
    esac
    body=$(printf '%s' "$rules" | render_rules)
    [ -n "$body" ] && ctx="$ctx"$'\n'"$body"
    emit SessionStart "$ctx"
    ;;

  UserPromptSubmit)
    model=$(model_from_transcript) || exit 0
    rules=$(match_rules "$model")
    ruleset=$(printf '%s' "$rules" | tr '\n' ',')

    prev_model=""; prev_ruleset=""
    [ -f "$state_file" ] && IFS=$'\t' read -r prev_model prev_ruleset < "$state_file"

    if [ "$ruleset" != "$prev_ruleset" ]; then
      save_state "$model" "$ruleset"
      ctx="current model: $model (switched from ${prev_model:-unknown}; via transcript)"
      body=$(printf '%s' "$rules" | render_rules)
      [ -n "$body" ] && ctx="$ctx"$'\n'"$body"
      emit UserPromptSubmit "$ctx"
    elif [ "$model" != "$prev_model" ]; then
      save_state "$model" "$ruleset"
      # 별칭이 실제 id 로 구체화된 것(opus → claude-opus-5)이면 조용히 넘어간다. 진짜 바뀐 것만 알린다.
      case "$(printf '%s' "$model" | lower)" in
        *"$(printf '%s' "$prev_model" | lower)"*) [ -n "$prev_model" ] && [ "$prev_model" != "unknown" ] && exit 0 ;;
      esac
      emit UserPromptSubmit "current model: $model (switched from ${prev_model:-unknown}; via transcript)"
    fi
    ;;

  SessionEnd)
    rm -f "$state_file" 2>/dev/null
    ;;
esac
exit 0
