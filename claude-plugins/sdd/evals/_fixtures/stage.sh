#!/usr/bin/env bash
# 평가 작업 폴더를 준비하는 공용 스크립트다.
# 각 case 의 scaffold.sh 가 부른다. 지금 폴더(cwd)가 평가 작업 폴더다.
# 사용법: bash stage.sh <case 이름> [골든 파일 이름...]
#   - <case 이름> 을 .eval-case 에 적는다. run.ts 가 남겨 둔 실행 폴더가 어느 case 인지 알아내는 데 쓴다
#   - 골든 파일(requirements.md, design.md)을 out/ 에 복사한다. 결과 파일은 절대 미리 두지 않는다
#   - 스킬의 git 명령이 바로 실패하지 않도록 빈 git 저장소를 만든다
set -euo pipefail

FIXTURES="$(cd "$(dirname "$0")" && pwd)"
CASE_NAME="$1"
shift

printf '%s\n' "$CASE_NAME" > .eval-case
mkdir -p out
for f in "$@"; do
  cp "$FIXTURES/$f" "out/$f"
done

git init -q
git -c user.email=eval@example.invalid -c user.name=eval commit -q --allow-empty -m "평가 시작점"
