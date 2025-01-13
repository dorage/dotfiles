#!/bin/bash

# Any abolute/relative path will be transformed to absolute path

path="$1"

if [[ "$path" = /* ]]; then
	cd "$path"
else
	cd "$PWD/$path"
fi

echo $PWD
