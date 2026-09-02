#!/bin/bash
# 외부에서 주입해야 하는 값들의 목록.
# 이 파일은 키 이름과 설명만 담는다. 실제 값은 리포 밖에 두고 커밋하지 않는다.
#
#   mkdir -p ~/.config/dotfiles
#   cp configs/env.example.sh ~/.config/dotfiles/env.sh
#   chmod 600 ~/.config/dotfiles/env.sh
#   $EDITOR ~/.config/dotfiles/env.sh   # 각 값을 채운다
#
# 읽는 쪽이 둘이다.
# - configs/zsh/.zshrc          : 대화형 셸을 열 때 source 한다.
# - configs/claude/scripts/*.sh : 물려받은 환경이 비어 있으면 이 파일을 직접 읽는다.
#   Claude Code 훅은 터미널을 거치지 않고 실행될 수 있어서 .zshrc 를 타지 않는다.
#   그래서 셸 쪽 한 곳만 걸어두면 훅에서 값이 비는 경우가 생긴다.
#
# 값을 새로 추가하면 이 예시 파일에도 같은 줄을 남긴다. 다른 기기를 세팅할 때
# 무엇을 채워야 하는지 알려주는 목록이 이 파일뿐이다.
#
# 파일 위치를 옮기고 싶으면 DOTFILES_ENV_FILE 로 경로를 지정할 수 있다.

# Claude Code 훅이 알림을 보낼 Discord 웹훅 주소.
# 받는 방법: Discord 채널 설정 → 연동 → 웹후크 → 새 웹후크 → 웹후크 URL 복사
# 비워두면 configs/claude/scripts/discord-notify.sh 가 조용히 아무것도 보내지 않는다.
export DISCORD_WEBHOOK_URL=""

# Notion API 토큰. notion-po 플러그인의 ntn CLI 가 쓴다.
# 기본적으로 ntn 은 OS 키체인의 인증 정보를 쓰고, 이 값이 있으면 키체인보다 우선한다.
# 키체인이 없는 환경에서만 주석을 풀고 채운다. 빈 값으로 내보내면 키체인 인증을
# 가로막을 수 있어서 일부러 주석으로 남겨둔다.
# export NOTION_API_TOKEN=""
