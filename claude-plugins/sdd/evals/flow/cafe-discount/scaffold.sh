#!/usr/bin/env bash
# 이 case 의 작업 폴더를 준비한다. 설명은 _fixtures/stage.sh 에 있다.
set -euo pipefail
CASE_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$CASE_DIR/../../_fixtures/stage.sh" flow-cafe-discount requirements.md
