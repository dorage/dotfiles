---
description: 다 끝난 워크트리 정리. 머지 여부와 잠금 상태를 사실로 확인해 안전한 것만 지우고, 애매한 것은 사용자에게 묻는다. 나이로 판단하지 않는다.
argument-hint: {정리 대상 | 비워두면 전체 점검}
---

끝난 워크트리를 치우는 커맨드예요. 입력 인자: `$ARGUMENTS`

`${CLAUDE_PLUGIN_ROOT}/references/common.md` 의 "진행 방식에 대한 약속" 절을 먼저 읽어요. 단계마다 짧게 보고하고, 독립적인 확인은 한 번에 묶고, 이미 요청된 단계를 "진행할까요?" 로 되묻지 않는 약속이 거기 있어요. 나머지 절(브랜치명, 빈 커밋, PR 생성)은 clean 과 무관해요.

## clean 이 하는 일

`/wt:init` 과 `/wt:plan` 이 만들어 둔 워크트리 중 **일이 끝난 것만** 지워요. 기준은 하나예요: 그 워크트리의 작업 결과가 워크트리 밖에도 남아 있는가. 남아 있지 않으면 지우지 않아요.

지우는 것은 되돌릴 수 없어요. 그래서 이 커맨드는 "안 지움" 쪽으로 기울어져 있어요. 애매하면 남기고 사용자에게 물어요. 남겨서 생기는 비용은 디스크 몇 MB 지만, 잘못 지워서 생기는 비용은 사라진 작업이에요.

`$ARGUMENTS` 가 비어 있으면 전체 워크트리를 점검해요. 이름이 들어오면 그것만 봐요.

## 사실 수집

판단 전에 워크트리마다 사실을 모아요. 아래 확인은 서로 의존하지 않으니 한 번에 실행해요.

```bash
git fetch origin main                                  # 기준을 최신으로
git worktree list --porcelain                          # 경로, 브랜치, 잠금 이유
gh pr list --head {브랜치} --state all --json number,state,title
git merge-base --is-ancestor {브랜치} origin/main      # 머지 커밋 방식일 때만 참
git -C {워크트리 경로} status --porcelain              # 미커밋 변경
git ls-remote --heads origin {브랜치}                  # 원격에 사본이 있는가
git -C {워크트리 경로} log --oneline origin/main..HEAD # 이 워크트리에만 있는 커밋
```

`git fetch` 를 빼먹으면 방금 머지된 브랜치가 미머지로 보여요. 로컬 `main` 이 아니라 `origin/main` 을 기준으로 봐요.

기본 브랜치가 `main` 이 아닌 리포지토리도 있어요. `gh repo view --json defaultBranchRef` 로 확인하고 그 이름을 써요.

### 잠금 확인

이 리포지토리의 워크트리는 Claude Code 세션이 들어가면 잠겨요. 잠금 이유에 세션의 pid 가 들어 있어요.

```
locked claude session gnothi-plugin (pid 22828 start Mon Sep 14 04:50:19 2026)
```

pid 가 살아 있는지 `ps -p {pid}` 로 확인해요. 출력이 있으면 그 세션이 지금 그 디렉터리에서 일하고 있다는 뜻이에요. 출력이 없으면 세션이 죽고 잠금만 남은 거예요.

- 살아 있는 pid → 건드리지 않아요. 남의 작업 디렉터리를 발밑에서 치우는 일이에요.
- 죽은 pid → `git worktree unlock {경로}` 로 풀고 나머지 기준대로 판단해요.

잠금 이유에 pid 가 없으면(사람이 직접 잠갔으면) 이유를 그대로 보고하고 사용자에게 물어요.

## 분류

나이로 판단하지 않아요. `6d`, `1w` 는 버려도 된다는 근거가 아니에요.

- 지워도 되는 것
    - PR 상태가 `MERGED` 이고 미커밋 변경이 없는 워크트리
    - `origin/main` 의 조상이고 미커밋 변경이 없는 워크트리
    - 미커밋 변경이 `.DS_Store` 같은 잡티뿐인 워크트리
- 남기는 것
    - PR 상태가 `OPEN` 인 워크트리. 진행 중이에요
    - 잠금 pid 가 살아 있는 워크트리
    - 메인 체크아웃. 형제 워크트리들이 이 `.git` 을 함께 써요
- 멈추고 묻는 것
    - 이 워크트리에만 있는 커밋이 원격에 없는 경우. 사본이 하나뿐이에요
    - 미커밋 변경이 실제 작업인 경우
    - PR 상태가 `CLOSED` 인데 머지되지 않은 경우. 버린 작업인지 되살릴 작업인지는 사용자만 알아요
    - 원격에는 있지만 머지되지 않은 커밋이 있는 경우. 위험은 낮지만 한 번 확인해요

### 머지 판정은 PR 상태를 먼저 본다

`git merge-base --is-ancestor` 는 머지 커밋으로 합쳤을 때만 참이 돼요. GitHub 에서 squash merge 나 rebase merge 로 합치면 커밋 해시가 바뀌어서, 실제로는 머지된 브랜치가 "미머지" 로 나와요. 이 판정만 믿으면 끝난 워크트리가 영원히 안 지워지거나, 반대로 사용자에게 매번 쓸데없이 물어보게 돼요.

그래서 순서는 이래요. `gh pr list --head {브랜치} --state all` 로 PR 상태를 먼저 보고, PR 이 없을 때만 `--is-ancestor` 로 판단해요. `gh` 가 인증되지 않았거나 원격이 GitHub 이 아니면 그 사실을 보고하고, 조상 판정만으로는 "머지됨" 이라고 단정하지 않아요.

## 제거

```bash
git worktree remove {경로}              # 머지됨 + 깨끗함
git worktree unlock {경로}              # 죽은 세션의 잠금을 먼저 푼다
git worktree remove --force {경로}      # 잡티뿐인 미커밋 변경. 무엇이 바뀌었는지 보고 나서
git branch -d {브랜치}                  # 머지된 브랜치만. -d 는 미머지면 스스로 거부한다
```

`git branch -D` 는 미머지 브랜치도 지워요. 사용자가 명시적으로 승인했을 때만 써요.

squash 머지된 브랜치는 `-d` 가 거부해요. PR 이 `MERGED` 인 것을 확인했으면 그 근거를 한 줄 남기고 `-D` 를 써도 돼요. 확인하지 못했으면 브랜치는 남겨둬요. 워크트리 디렉터리만 지워도 목적은 대부분 달성돼요.

빌드 산출물처럼 워크트리 밖의 디렉터리를 직접 지워야 하면 `rm -rf` 대신 `trash` 를 써요(`command -v trash` 로 확인). 휴지통 이동은 같은 볼륨 안의 이동이라, 휴지통을 비우기 전에는 용량이 돌아오지 않아요.

## 미머지인데 치우고 싶을 때

사용자가 "PR 로 남기고 치우자" 를 고르면 작업을 원격에 먼저 올려요.

```bash
git -C {경로} push -u origin {브랜치}
gh pr create --draft --base main --head {브랜치} --title "..." --body "..."
git worktree remove --force {경로}
```

브랜치는 원격과 로컬에 남으니 잃는 게 없어요.

## 검증

```bash
git worktree prune     # 디렉터리가 사라진 항목의 관리 정보 정리
git worktree list      # 남아야 할 것만 남았는지 확인
```

## 보고

```
점검    : {n}개 워크트리
제거    : {이름} — {근거. 예: PR #4 MERGED, 미커밋 없음}
남김    : {이름} — {근거. 예: PR #12 OPEN}
보류    : {이름} — {물어야 하는 이유}
브랜치  : {지운 로컬 브랜치, 없으면 "없음"}
```

보류가 있으면 그 아래에 사용자가 고를 수 있는 선택지(남김 / PR 로 올림 / 버림)를 한 줄로 덧붙여요.

## 자주 하는 실수

- 머지 여부 대신 나이로 "낡았다" 고 판단하는 것. 오래된 것과 버려도 되는 것은 다른 말이에요.
- "미커밋 변경이 있다" 는 오류를 `--force` 로 넘기고 무엇이 바뀌었는지 보지 않는 것.
- 정리한다며 `-D` 로 미머지 브랜치를 지워서 유일한 사본을 없애는 것.
- 스태시 개수를 워크트리별 작업으로 착각하는 것. 스태시는 리포지토리 전역이라 모든 워크트리에서 같은 목록이 보여요. 지우기 전에 `git stash list` 로 내용은 확인하되, 개수가 같다는 것을 근거로 삼지 않아요.
- 살아 있는 Claude 세션이 잠근 워크트리를 `--force` 로 밀어버리는 것.

<example>
<user>/wt:clean</user>
<response>
[git fetch origin main / git worktree list --porcelain / gh pr list 동시 실행]
[잠금 pid 2개 생존 확인: 22828 없음(죽음), 42753 있음(9월 10일부터 실행 중)]

점검    : 3개 워크트리
제거    : gnothi-plugin — PR #4 MERGED, 미커밋 없음, 잠금 pid 22828 죽음(unlock 후 제거)
제거    : roguelike-skill — PR #5 MERGED, 미커밋 없음, 잠금 없음
남김    : wt-init-plan-split — PR #3 MERGED 이지만 잠금 pid 42753 이 살아 있음
브랜치  : feat/gnothi-plugin, feat/roguelike-skill 삭제

wt-init-plan-split 은 그 세션을 닫은 뒤에 다시 돌리면 정리돼요.
</response>
<rationale>올바른 이유: 머지 여부를 PR 상태로 확인했고, 잠금은 pid 생존까지 확인해 죽은 잠금과 살아 있는 잠금을 구분했다. 머지가 끝난 워크트리라도 세션이 살아 있으면 건드리지 않았다. 보고만 읽어도 무엇을 왜 지웠는지, 남은 하나는 언제 지워지는지 알 수 있다.</rationale>
</example>

<!--
출처: https://github.com/dataders/dotfiles/blob/main/.ai/skills/cleaning-stale-worktrees/SKILL.md
원문은 worktrunk(`wt`) CLI 를 전제로 쓰였어요. 이 리포지토리에는 그 CLI 가 없어서 순수 git + gh 로 옮겼고,
squash/rebase 머지 오판과 Claude 세션 잠금(pid) 처리를 더했어요.
-->
