#!/bin/sh

function initialize(){
	local sleepType=$1
	local value=$(hs -c "hs.caffeinate.get('${sleepType}')")

	if [[ "$value" = "true" ]]; then
			local text="on"
			local toggle="false"
	else
			local text="off"
			local toggle="true"
	fi
	
	sketchybar --set caffeinate.label.${sleepType} label="$sleepType"
	# sketchybar --set caffeinate.label.${sleepType} label="$SENDER"
	sketchybar --set caffeinate.item.${sleepType} label="$text" 
}


sleepTypes=("displayIdle" "systemIdle" "system")
for sleepType in ${sleepTypes[@]}; do
	initialize ${sleepType}
done
