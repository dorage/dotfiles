#!/usr/bin/env bash
# configs/claude 를 ~/.claude 로 동기화한다.
# 리포에 있는 파일만 덮어쓴다. 지우는 일은 하지 않는다.
# ~/.claude 에는 리포 밖 항목(projects, sessions, skills/synced, 로컬에서 만든 스킬 등)이
# 같은 디렉터리 안에도 섞여 있어서, --delete 를 쓰면 그것들이 함께 지워진다.
# 리포에서 지운 파일은 ~/.claude 에 남으니, 필요하면 손으로 지운다.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)/configs/claude"
DEST="$HOME/.claude"

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
    rsync -avh "$path/" "$DEST/$name"
  elif needs_expand "$name"; then
    sed "s|\$HOME|$HOME|g" "$path" > "$TMP/$name"
    # 임시 파일은 mtime 이 늘 새로우니 -c 로 내용 기준 비교해 헛전송을 막는다.
    rsync -avhc "$TMP/$name" "$DEST/$name"
  else
    rsync -avh "$path" "$DEST/$name"
  fi
done

# ~/.config/claude-plugins 를 리포 claude-plugins 를 가리키는 링크로 둔다.
# 복사본을 따로 두면 리포와 설치본이 어긋나기 때문이다.
# 워크트리에서 실행해도 메인 체크아웃을 가리키도록 git 공용 디렉터리에서 리포 루트를 찾는다.
REPO_MAIN="$(dirname "$(git -C "$SRC" rev-parse --path-format=absolute --git-common-dir)")"
PLUGINS_SRC="$REPO_MAIN/claude-plugins"
PLUGINS_DEST="$HOME/.config/claude-plugins"

mkdir -p "$(dirname "$PLUGINS_DEST")"
if [ -L "$PLUGINS_DEST" ]; then
  if [ "$(readlink "$PLUGINS_DEST")" != "$PLUGINS_SRC" ]; then
    ln -sfn "$PLUGINS_SRC" "$PLUGINS_DEST"
    echo "링크 갱신: $PLUGINS_DEST -> $PLUGINS_SRC"
  fi
else
  if [ -e "$PLUGINS_DEST" ]; then
    # 지우지 않고 옮겨 둔다. 리포에 없는 수정이 있으면 여기서 되찾는다.
    BACKUP="$PLUGINS_DEST.bak-$(date +%Y%m%d%H%M%S)"
    mv "$PLUGINS_DEST" "$BACKUP"
    echo "기존 디렉터리를 옮겨 둠: $BACKUP"
  fi
  ln -s "$PLUGINS_SRC" "$PLUGINS_DEST"
  echo "링크 생성: $PLUGINS_DEST -> $PLUGINS_SRC"
fi
