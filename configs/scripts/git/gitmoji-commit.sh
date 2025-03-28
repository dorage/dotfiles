#!/bin/bash

gum style \
	--foreground 212 --align left --width 50 \
"👉 It's commit time! 👈"

GITMOJI=$(cat ~/.config/scripts/git/gitmoji | fzf | sed 's/^\(.\).*/\1/' )

content="$GITMOJI 
# Description

"
template=$(mktemp)
echo "$content" > "$template"

git commit --template "$template"
