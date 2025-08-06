#!/bin/bash


# Commit with Gitmoji
alias gcg="~/.config/scripts/git/gitmoji-commit.sh"

# Checkout branch with fzf
function gco() {
	git checkout $(git branch | fzf)
}

# Issue - create branch from issue, then checkout
function ghib() {
	# get issue id
	gh issue develop $( gh issue list | fzf | sed 's/\([0-9]*\).*/\1/' ) --base $( git branch -r | fzf | sed 's/origin\///' )  --checkout
}

# PR - create
function ghpr() {
	gh pr create --fill --base $(git branch -r | fzf | sed 's/origin\///')
}

# PR - merge with squash
function ghprm() {
	gh pr merge --squash
}


