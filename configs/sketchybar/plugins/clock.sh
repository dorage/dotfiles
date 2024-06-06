#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

# sketchybar --set "$NAME" label="$(date '+%d/%m %H:%M')"
sketchybar --set '/.*year/' label="年 $(date '+%Y')"
sketchybar --set '/.*month/' label="月 $(date '+%m')"
sketchybar --set '/.*day/' label="日 $(date '+%d')"
sketchybar --set '/.*time/' label="時 $(date '+%H:%M')"

