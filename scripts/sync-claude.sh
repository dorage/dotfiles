#!/usr/bin/env bash
# configs/claude 를 ~/.claude 로 동기화한다.
# 리포에 있는 항목만 덮어쓰고, ~/.claude 의 나머지(agents, projects, plugins, sessions 등)는 그대로 남긴다.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)/configs/claude"
DEST="$HOME/.claude"

# 리포가 관리하지 않는 비밀 파일은 제외해 목적지에 남긴다.
# 웹훅 주소는 configs/claude/env.sh 로 옮겼다(목록은 configs/claude/env.example.sh).
# 그 파일은 .gitignore 로 커밋만 막을 뿐 이 SRC 트리 안에 있어서, 다른 파일과 함께
# 그대로 ~/.claude 로 복사된다. 아래 제외 규칙은 예전 방식으로 이미 파일을 둔
# 환경을 위한 이행 조치이고, 옮긴 걸 확인하면 걷어낸다.
EXCLUDES=(--exclude 'discord-webhook-url')

# settings.json 은 ~ 나 상대 경로를 못 읽으므로, 리포에는 $HOME 을 그대로 적어두고
# 내보낼 때 이 환경의 실제 홈 경로로 풀어서 쓴다.
# 셸 스크립트는 $HOME 을 실행 시점에 알아서 읽으니 치환 대상이 아니다.
EXPAND_HOME=(settings.json)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$DEST"

needs_expand() {
  local name="$1" target
  for target in "${EXPAND_HOME[@]}"; do
    [ "$name" = "$target" ] && return 0
  done
  return 1
}

for path in "$SRC"/*; do
  name="$(basename "$path")"
  if [ -d "$path" ]; then
    # 디렉터리는 그 디렉터리 안에서만 --delete 로 리포 상태를 그대로 반영한다.
    rsync -avh --delete "${EXCLUDES[@]}" "$path/" "$DEST/$name"
  elif needs_expand "$name"; then
    sed "s|\$HOME|$HOME|g" "$path" > "$TMP/$name"
    # 임시 파일은 mtime 이 늘 새로우니 -c 로 내용 기준 비교해 헛전송을 막는다.
    rsync -avhc "$TMP/$name" "$DEST/$name"
  else
    rsync -avh "$path" "$DEST/$name"
  fi
done
