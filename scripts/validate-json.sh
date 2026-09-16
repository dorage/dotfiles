#!/usr/bin/env bash
# JSON 파일이 문법적으로 유효한지 검사한다.
#
# 사용법: scripts/validate-json.sh [파일...]
#   인자를 주면 그 파일들만, 안 주면 git 이 추적 중인 모든 *.json 을 검사한다.
#   하나라도 깨져 있으면 1 로 종료한다.
set -o pipefail

# VSCode 스니펫은 주석과 후행 쉼표를 허용하는 JSONC 라서 엄격 검사에서 제외한다.
EXCLUDE_PATTERNS=(
  'configs/nvim/lua/dorage/snippets/vscode/'
)

if [ "$#" -eq 0 ]; then
  targets=$(git ls-files '*.json')
else
  targets=$(printf '%s\n' "$@")
fi

status=0
while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue

  skipped=0
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    case "$file" in
      *"$pattern"*) skipped=1 ;;
    esac
  done
  [ "$skipped" -eq 1 ] && continue

  if ! message=$(python3 -c '
import json, sys

try:
    with open(sys.argv[1], encoding="utf-8") as fp:
        json.load(fp)
except Exception as error:
    sys.stderr.write(str(error))
    sys.exit(1)
' "$file" 2>&1); then
    printf 'JSON 문법 오류: %s\n  %s\n' "$file" "$message" >&2
    status=1
  fi
done <<EOF
$targets
EOF

exit "$status"
