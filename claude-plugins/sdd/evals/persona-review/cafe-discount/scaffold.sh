#!/usr/bin/env bash
# 이 case 의 작업 폴더를 준비한다. 설명은 _fixtures/stage.sh 에 있다.
# 골든 requirements.md 는 검토가 끝난 「완성」 문서라 「참여자별 검토 기록」이 있다.
# 기록이 있으면 persona-review 가 검토할 참여자가 없으므로, 깔아 둔 뒤 그 절(문서 맨 끝)을 지운다.
set -euo pipefail
CASE_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$CASE_DIR/../../_fixtures/stage.sh" persona-review-cafe-discount requirements.md
perl -0pi -e 's/\n+## 참여자별 검토 기록\n.*\z/\n/s' out/requirements.md
