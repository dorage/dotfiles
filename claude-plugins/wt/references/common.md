# wt 공통 절차

`/wt:init` 과 `/wt:plan` 이 함께 쓰는 절차예요. 두 커맨드 모두 워크트리·브랜치·draft PR 을 만들고, 코드는 손대지 않아요. 산출물은 PR 본문에만 들어가요. `/wt:clean` 은 워크트리를 만들지 않으니 아래 "진행 방식에 대한 약속" 절만 가져다 써요.

## 진행 방식에 대한 약속

이 플러그인은 사용자가 지켜보지 않는 사이 끝까지 돌아가는 것을 전제로 해요. 그래서 다음을 지켜요.

- 시작할 때 무엇을 할지 한 줄로 말하고, 단계가 넘어갈 때 짧게 진행 상황을 알려요. 마지막 보고는 그것만 읽어도 전체 그림이 잡히게 써요. 도구 호출 사이에 말이 없으면 사용자는 세션이 멈춘 줄 알아요.
- 서로 의존하지 않는 확인(`git fetch`, `gh auth status`, `gh issue view`, 여러 파일 읽기)은 한 번에 요청해요. 한 턴에 하나씩 하면 왕복 시간만 늘어요.
- Draft PR URL 이 나오기 전에는 턴을 끝내지 않아요. "다음으로 PR 을 만들겠습니다"처럼 예고로 끝내는 것은 그 일을 안 한 것과 같아요. 이미 요청된 단계에 대해 "진행할까요?"라고 묻지도 않아요.
- 멈춰야 하는 경우는 정해져 있어요: 같은 이름의 브랜치·워크트리가 이미 있을 때, `gh` 가 실패했을 때(미인증·이슈 미존재·권한 없음). 이때는 추측으로 이어가지 않고 상황을 보고해요. plan 에서 사용자가 골라야 하는 갈림길은 멈추는 이유가 아니에요. 추측으로 메우지 않고 PR 본문 "결정사항" 에 선택지로 올린 뒤 PR 까지 만들고, 보고에서 답을 받아요.
- 코드 파일은 두 커맨드 모두 수정하지 않아요. 조사 중 발견한 무관한 문제도 고치지 않고 PR 본문의 "범위 밖 발견" 절이나 `/side-issue` 로 넘겨요. 이 플러그인의 산출물은 출발점이고, 구현은 후속 세션의 몫이에요.

## 이슈 단독 입력

입력이 `#123`, `이슈 123`, `123` 처럼 이슈 번호 외 설명이 거의 없으면 먼저 이슈를 읽어요.

```bash
gh issue view {번호} --json number,title,body,labels,state
```

- `state` 가 `CLOSED` 면 사용자에게 계속할지 한 번 물어요. 답을 받을 수 없는 배경 세션이면 그대로 진행하고 PR 본문 "참고" 에 닫힌 이슈였음을 적어요.
- `labels` 로 type 을 먼저 정해요: `bug` → `fix`, `enhancement`/`feature` → `feat`, `documentation` → `docs`, `refactor` → `refactor`, `chore` → `chore`. 라벨이 없으면 아래 type 추론으로 넘어가요.
- 브랜치명에는 이슈 번호를 앞에 붙여요: `feat/123-cafe-order-pagination`.
- PR 본문 "관련 이슈" 에 `- 해결할 이슈: #{번호}` 를 넣어요. PR 이 머지되면 이슈가 함께 닫히게 하려는 거예요.

`gh issue view` 가 실패하면 멈추고 보고해요. 이슈 내용을 추측해서 채우면 브랜치명과 PR 본문이 전부 틀어져요.

## 브랜치명 결정

전역 규칙 `<type>/<short-description>` 을 따라요.

- type 은 `{이유}` 의 동사·명사로 골라요.
    - 추가 / 구현 / 만들어 / 신규 / 새 기능 → `feat`
    - 버그 / 수정 / 오류 / 고침 / 안 됨 → `fix`
    - 문서 / README / 주석 / 가이드 → `docs`
    - 리팩토링 / 정리 / 구조 변경 → `refactor`
    - 테스트 추가 / 커버리지 → `test`
    - 성능 / 최적화 → `perf`
    - 빌드 / 의존성 → `build`
    - CI / 워크플로우 / 액션 → `ci`
    - 그 외 설정·환경·잡일 → `chore`
    - 어느 것도 아니면 `feat`
- description 은 영문 kebab-case 50자 이내예요. 한글은 영어로 옮기고 핵심 명사구만 남겨요.
    - `포인트 결제 환불 기능 추가` → `point-payment-refund`
    - `fcm ios 알림 사운드 버그 수정` → `fcm-ios-sound`
    - 이슈 번호가 있으면 앞에 붙여요: `feat/344-kiosk-cafe-order-api`
    - 패키지명은 넣지 않아요. scope 는 커밋 메시지가 표현해요.

## 워크트리 생성

먼저 `origin/main` 을 받아요. 묵은 base 로 워크트리를 만들면 PR 이 오래된 코드를 기준으로 서요.

```bash
git fetch origin main
```

`EnterWorktree` 도구로 워크트리를 만들어요. 스키마는 `ToolSearch query="select:EnterWorktree"` 로 불러요. 이 도구는 `.claude/worktrees/{name}/` 에 `worktree-{name}` 브랜치를 만들기 때문에, 진입 후 브랜치명을 바꿔요.

```bash
git branch -m {type}/{description}
```

`EnterWorktree` 가 실패하면 직접 만들어요.

```bash
git worktree add -b {type}/{description} .claude/worktrees/{description} origin/main
```

같은 이름의 브랜치나 워크트리가 이미 있으면 여기서 멈추고 보고해요. 덮어쓰면 다른 세션의 진행 중 작업이 사라질 수 있어요.

## 빈 커밋과 푸시

두 커맨드 모두 코드 변경이 없으므로 빈 커밋 하나를 두고 푸시해요. PR 을 만들려면 브랜치에 커밋이 하나는 있어야 해요.

```bash
git commit --allow-empty -m "$(cat <<'EOF'
{type}: {한국어 이유 요약 50자 이내}

작업 시작용 빈 커밋. 실제 변경은 후속 커밋에서 들어간다.
EOF
)"
git push -u origin {type}/{description}
```

빈 커밋에는 AI 공동저자 트레일러를 붙이지 않아요. 변경 내용이 없어서 공동저자가 의미가 없어요.

## 세션 ID 확인

PR 본문에 이 세션의 ID 를 남겨요. 후속 작업자가 `claude --resume {세션 ID}` 나 `/qa {세션 ID}, ...` 로 이 세션에 돌아와 "왜 그렇게 정했는지"를 물을 수 있게 하려는 거예요. plan 에서는 조사 컨텍스트를 전부 가진 세션이라 특히 값이 커요.

- 컨텍스트에 `current session_id: {uuid}` 줄이 있으면 그 값을 써요. side-issue 플러그인의 SessionStart 훅이 넣어줘요.
- 없으면 `ls -t ~/.claude/projects/{프로젝트 슬러그}/*.jsonl | head -1` 의 파일명(확장자 제외)을 써요. 가장 최근에 쓰인 트랜스크립트가 현재 세션이에요.
- 둘 다 안 되면 `세션 ID: 확인 불가` 로 적어요. 지어내지 않아요.

## Draft PR 생성

`gh pr create --draft --base main` 으로 올려요. 제목은 빈 커밋 헤더와 같은 `{type}: {요약}` 이에요. 본문은 각 커맨드 파일의 형식을 따르고, 길면 임시 파일에 써서 `--body-file` 로 올린 뒤 파일을 지워요. 셸 here-doc 에 긴 마크다운을 넣으면 따옴표와 백틱이 깨지기 쉬워요.

이슈가 없으면 "관련 이슈" 절을 통째로 빼요. 빈 절은 읽는 사람에게 "채워야 하나" 하는 의문만 남겨요.

## 보고

끝나면 다음을 한 블록으로 보고해요. 이 보고만 읽은 사람이 바로 워크트리로 들어가 일할 수 있어야 해요.

```
브랜치  : {type}/{description}
워크트리: {절대 경로}
커밋    : {short sha} (empty)
PR      : {URL} (draft)
세션    : {uuid}
산출물  : {plan 만. 본문에 담은 내용 한 줄}
```

닫힌 이슈였거나 확인 못 한 항목이 있으면 그 아래 한 줄씩 덧붙여요.
