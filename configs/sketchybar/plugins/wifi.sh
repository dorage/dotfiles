#!/bin/sh

NETWORK=$(hs -c "isWifiConnected()")
CONNECTION="CON"
ICON="󰤨"

if [ "$NETWORK" = "" ]; then
	ICON="󰤭"
	CONNECTION="DIS"
fi

sketchybar --set "$NAME" label="${ICON}  ${CONNECTION}"
