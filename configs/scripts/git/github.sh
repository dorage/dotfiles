#!/bin/bash

function current_branch_issue_id() {
	git branch --show-current | sed 's/^\([0-9]*\).*/\1/'
}

function git-branch-name() {
    local name="$*"
    echo "$name" | sed '
        s/[[:space:]\/]\+/-/g
        s/[^a-zA-Z0-9._-]//g
        s/--\+/-/g
        s/\.\./-/g
        s/^[.-]\+//
        s/[.-]\+$//
    ' | tr '[:upper:]' '[:lower:]'
}

# Commit with Gitmoji
alias gcg="~/.config/scripts/git/gitmoji-commit.sh"

# Checkout branch with fzf
unalias gco 2>/dev/null  # 기존 alias 제거
function gco() {
	git checkout $(git branch | fzf)
}

# commit closing issue id
function gcr() {
	issue_id=$(current_branch_issue_id)
	if [ -n "$issue_id" ]; then
		git commit --allow-empty -m "Close #$issue_id"
	else
		echo "No issue ID found in current branch name"
	fi
}

# Issue - create
function ghic() {
	gh issue create
}
 
# Issue - create branch from issue, then checkout
function ghib() {
	gh issue develop $(gh issue list --state open | fzf | sed 's/\([0-9]*\).*/\1/') --base $( git branch --remotes | fzf | sed 's/origin\///' )  --checkout
}

# PR - create
function ghpr() {
	gcr
	git push
	# If current branch is created by `gh issue develop --base`, then base branch will be configured as the base for pr
	gh pr create --fill
}

# PR - create
function ghprc() {
	gh pr create --fill --base $(git branch --remotes | fzf | sed 's/origin\///')
}

# PR - edit
function ghpre() {
	gh pr edit $(gh pr list | fzf | sed 's/\([0-9]*\).*/\1/')
}

# PR - merge with squash
function ghprm() {
	gh pr merge --squash
}


# PR - create & squash merge automatically
function ghprma() {
	gcr
	git push
	# If current branch is created by `gh issue develop --base`, then base branch will be configured as the base for pr
	gh pr create --fill
	gh pr merge --squash --auto
}

function select_branch() {
	git branch | fzf | sed 's/. \(.*\)/\1/'
}

# Worktree - add git worktree with branch
function gwoa() {
	branch=$(select_branch)
	mkdir -p ~/worktrees # 디렉터리 없으면 생성
	git worktree add "$HOME/worktrees/$branch" "$branch"
	gum format -- "**$branch** 워크트리 생성"
}

function gwor() {
	branch=$(select_branch)
	git worktree remove "$branch"
	gum format -- "**$branch** 워크트리 삭제"
}
