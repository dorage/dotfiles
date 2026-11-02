---
name: setup
description: 스펙 문서를 모아 둘 `~/.sdd/{리포지토리 이름}/` 폴더(references/spec-format.md 「저장 위치」의 리포 폴더)가 있는지 확인하고, 없으면 만들어요. 이미 있으면 "SDD 준비완료!" 만 답해요. git 리포지토리가 아니면 지금 폴더 이름을 대신 써요. 트리거 - `/sdd:setup`, "sdd 준비해줘", "sdd 폴더 만들어줘"
---

# sdd:setup — 스펙 보관 폴더 준비

## 이름 정하기

폴더 이름은 아래 순서로 처음 얻은 값을 쓴다.

- git 리포지토리이고 `origin` 원격이 있으면, 원격 주소의 마지막 이름(`.git` 제외)
- git 리포지토리이면, 메인 체크아웃 폴더 이름 (워크트리 안이어도 워크트리 이름이 아니라 원래 리포지토리 이름)
- git 리포지토리가 아니면, 지금 폴더 이름

## 실행

아래 명령 하나를 그대로 실행한다.

```bash
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  name=$(basename "$(git remote get-url origin 2>/dev/null)" .git)
  [ -z "$name" ] && name=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
else
  name=$(basename "$PWD")
fi
dir="$HOME/.sdd/$name"
if [ -d "$dir" ]; then echo "EXISTS $dir"; else mkdir -p "$dir" && echo "CREATED $dir"; fi
```

## 답하기

- `EXISTS` 가 나오면 `SDD 준비완료!` 한 줄만 답한다. 다른 말을 붙이지 않는다
- `CREATED` 가 나오면 만든 경로를 한 줄로 답한다. 예: `~/.sdd/dotfiles/ 를 만들었습니다.`
- 명령이 실패하면 오류 줄과 원인을 한 줄로 답한다
