#!/bin/bash

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# Commit with Gitmoji
alias gcg="~/.config/scripts/git/gitmoji-commit.sh"

# Checkout branch with fzf
function gco() {
	git checkout $(git branch | fzf)
}

# PR - create
function ghpr() {
	gh pr create --fill --base $(git branch -r | fzf | sed 's/origin\///')
}

# PR - merge with squash
function ghprm() {
	gh pr merge --squash
}


