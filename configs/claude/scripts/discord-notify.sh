#!/bin/bash
# Claude Code hook → Discord 웹훅 알림
# PreToolUse(AskUserQuestion): 질문 내용 전송
# Stop: 마지막 응답 요약 전송
# 웹훅 URL은 같은 폴더의 discord-webhook-url 파일에서 읽는다.

WEBHOOK_URL=$(cat "$(dirname "$0")/discord-webhook-url" 2>/dev/null)
[ -z "$WEBHOOK_URL" ] && exit 0

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
session=$(echo "$input" | jq -r '.session_id // empty' | cut -c1-8)

case "$event" in
  PreToolUse)
    questions=$(echo "$input" | jq -r '[.tool_input.questions[]?.question] | join("\n")' 2>/dev/null)
    msg="❓ **질문 대기 중** — \`${session}\` (${cwd})
${questions}"
    ;;
  Stop)
    transcript=$(echo "$input" | jq -r '.transcript_path // empty')
    last=""
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
      last=$(tail -n 200 "$transcript" | jq -rs \
        '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | last // empty' \
        2>/dev/null | head -c 1500)
    fi
    msg="✅ **응답 완료** — \`${session}\` (${cwd})
${last}"
    ;;
  *)
    msg="🔔 Claude Code 알림 (${event}) — \`${session}\`"
    ;;
esac

echo "$msg" | jq -Rs '{content: (.[0:1900])}' | \
  curl -s -m 10 -X POST -H "Content-Type: application/json" -d @- "$WEBHOOK_URL" >/dev/null 2>&1

exit 0
