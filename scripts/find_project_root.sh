#!/bin/bash

# find a project root with filename
#
# example: 
# Finding a JS project root
# find_project_root.sh ~/workspace/dev-env/ package.json

current_dir=$1
file=$2

while [[ "$current_dir" != "/" ]]; do
		if [[ -f "$current_dir/$file" ]]; then
				echo "$current_dir"
				exit
		fi
		current_dir="$(dirname "$current_dir")"
done

