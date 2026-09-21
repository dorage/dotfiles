#!/bin/bash
# side-issue Stop 훅
#
# 응답이 끝나기 직전에 한 번 붙잡고, checklist.md 를 이유(reason)로 돌려준다.
# LLM 은 그 점검표를 보고 "추후 해야 할 일"과 "지금 작업과 무관한 문제"를 골라
# /side-issue 스킬로 백그라운드 포크를 띄운 뒤, [side-issue] 마커 한 줄로 끝낸다.
#
# 붙잡지 않는 경우 (조용히 exit 0):
#   - SIDE_ISSUE_DISABLE=1            배치·테스트에서 끄기
#   - jq 없음                         판정 불가
#   - agent_id 있음                   서브에이전트 안의 Stop
#   - stop_hook_active == true        이미 Stop 훅 때문에 이어가는 중 (무한 반복 방지)
#   - SIDE_ISSUE_FORK=1               /side-issue 가 띄운 포크 세션 (포크가 포크를 낳지 않도록)
#   - 마지막 마스터 프롬프트가 /side-issue 커맨드   포크 세션이거나 수동 이슈화 턴
#   - 마지막 마스터 프롬프트가 이 점검표 자체       훅 재진입
#   - 응답에 이미 [side-issue] 마커가 있음          LLM 이 스스로 점검을 마쳤음
#   - 이번 턴의 도구 호출 수 < SIDE_ISSUE_MIN_TOOLS (기본 1)   점검할 작업이 없는 단순 질답
set -u

[ "${SIDE_ISSUE_DISABLE:-0}" = "1" ] && exit 0
[ "${SIDE_ISSUE_FORK:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
[ "$(jq -r '.hook_event_name // empty' <<<"$input")" = "Stop" ] || exit 0
[ -n "$(jq -r '.agent_id // empty' <<<"$input")" ] && exit 0
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0

CHECKLIST="$(cd "$(dirname "$0")" && pwd)/checklist.md"
[ -f "$CHECKLIST" ] || exit 0
MIN_TOOLS="${SIDE_ISSUE_MIN_TOOLS:-1}"

# 응답 안에 마커가 이미 있으면 점검이 끝난 것이다.
last=$(jq -r '.last_assistant_message // ""' <<<"$input")
printf '%s\n' "$last" | grep -qE '^\[side-issue\] ' && exit 0

# 트랜스크립트에서 마지막 마스터 프롬프트(q)와 그 뒤의 도구 호출 수(tools)를 뽑는다.
# 마스터 프롬프트 = type=user, isMeta 아님, 본문이 문자열이거나 text 블록을 가진 배열.
# tool_result 만 담긴 user 메시지는 도구 결과라 프롬프트로 치지 않는다.
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
q=""
tools="$MIN_TOOLS"
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  stats=$(tail -n 4000 "$transcript" | jq -cs '
    [ .[] | select(.type=="user" or .type=="assistant") ] as $m
    | ([ range(0; $m|length) | select(
          $m[.].type=="user" and (($m[.].isMeta // false)|not)
          and ( ($m[.].message.content|type)=="string"
                or (($m[.].message.content|type)=="array" and any($m[.].message.content[]; .type=="text")) )
      ) ] | last) as $i
    | (if $i==null then ""
       else ($m[$i].message.content
             | if type=="string" then . else (map(select(.type=="text")|.text)|join("\n")) end)
       end) as $q
    | (if $i==null then $m else $m[$i+1:] end | map(select(.type=="assistant"))) as $a
    | { q: $q,
        tools: ([$a[] | .message.content[]? | select(.type=="tool_use")] | length) }' 2>/dev/null) || stats=""
  if [ -n "$stats" ]; then
    q=$(jq -r '.q' <<<"$stats")
    tools=$(jq -r '.tools' <<<"$stats")
  fi
fi

# /side-issue 커맨드로 시작한 턴: 포크 세션("/side-issue --fork ...")이거나 수동 이슈화다.
# 슬래시 커맨드는 트랜스크립트에 <command-name>/side-issue</command-name> 로도 남는다.
grep -qE '(^|<command-name>)/side-issue([[:space:]]|<|$)' <<<"$q" && exit 0
# 점검표 자체가 프롬프트로 들어온 턴(훅 재진입)
grep -q 'side-issue 점검' <<<"$q" && exit 0

[ "$tools" -lt "$MIN_TOOLS" ] 2>/dev/null && exit 0

jq -n --rawfile reason "$CHECKLIST" '{decision:"block", reason:$reason}'
exit 0
