---
description: 작업 시작 기록. 워크트리 + 빈 커밋 + draft PR 을 만들고, 요청 원문과 세션 ID 를 PR 본문에 남긴다. 조사는 하지 않는다.
argument-hint: {이유 | #이슈번호}
---

작업의 출발점을 기록하는 커맨드예요. 입력 인자: `$ARGUMENTS`

먼저 `${CLAUDE_PLUGIN_ROOT}/references/common.md` 를 읽어요. 진행 방식에 대한 약속, 이슈 단독 입력 처리, 브랜치명 결정, 워크트리 생성, 빈 커밋과 푸시, 세션 ID 확인, Draft PR 생성, 보고 형식이 모두 거기 있어요. 이 파일은 init 이 채우는 PR 본문만 정해요.

## init 이 하는 일

워크트리를 만들고, 사용자가 무엇을 하려 했는지(요청 원문)와 이 세션의 ID 를 PR 본문에 남겨요. 조사도, 계획도 하지 않아요. 사용자가 다음에 이 PR 을 열었을 때 자기가 무엇을 하려 했는지 바로 떠올릴 수 있으면 충분해요.

`$ARGUMENTS` 가 비어 있으면 무엇을 시작하려는지 한 줄로 되묻고 멈춰요. 이유 없는 브랜치는 이름도 PR 본문도 만들 수 없어요.

미래형 의지 표현("고칠 거야", "만들 거야")이나 명령형("조사해줘", "계획 짜줘")이 섞여 있어도 init 은 init 이에요. 조사가 필요하면 사용자가 `/wt:plan` 을 고른 거예요. 어투로 모드를 바꾸지 않아요.

## PR 본문 형식

```markdown
## 개요

{요청을 한 문장으로 정리. 이슈 단독 입력이면 이슈 제목을 한국어로}

> 작업 시작용 부트스트랩 PR. 실제 변경은 후속 커밋에서 들어간다.

## 요청 원문

> {사용자가 `/wt:init` 뒤에 적은 문장을 한 글자도 바꾸지 않고 인용}

## 세션

- 시작 세션 ID: `{uuid}`
- 이어가기: `claude --resume {uuid}`

## 관련 이슈

- 해결할 이슈: #{번호}

## 작업사항

- [ ] (후속 세션에서 채움)
```

- 요청 원문은 인용 블록으로 그대로 옮겨요. 요약하거나 다듬으면 사용자의 의도가 LLM 의 해석으로 바뀌어요. 인용 표시가 있어야 읽는 사람이 "이건 사용자 말"이라는 걸 구분해요.
- 이슈 단독 입력이었으면 "요청 원문" 에 `/wt:init #123` 을 그대로 두고, 그 아래에 이슈 제목을 한 줄 덧붙여요.
- 이슈가 없으면 "관련 이슈" 절을 통째로 빼요.

<example>
<user>/wt:init fcm 알림 사운드 ios 에서 안 울리는 거 고칠 거야</user>
<response>
[git fetch origin main / gh auth status 동시 실행]
[EnterWorktree name="fcm-ios-sound" → git branch -m fix/fcm-ios-sound]
[빈 커밋, 푸시]
[gh pr create --draft --title "fix: fcm ios 알림 사운드 미재생 수정" --body-file ...]

브랜치  : fix/fcm-ios-sound
워크트리: /Users/me/repo/.claude/worktrees/fcm-ios-sound
커밋    : a1b2c3d (empty)
PR      : https://github.com/org/repo/pull/45 (draft)
세션    : 6acadf5d-9822-46a8-9e24-702a03dbc928
</response>
<rationale>올바른 이유: 미래형 의지 표현("고칠 거야")을 조사 요청으로 확대 해석하지 않고 init 그대로 처리했다. 요청 원문은 PR 본문에 인용 블록으로 원문 그대로 들어갔다. 코드는 읽지도 고치지도 않았고, 보고는 다섯 줄로 자기완결적이다.</rationale>
</example>
