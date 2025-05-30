#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ./tests -name '*e2e.ts' | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

npm run debug-e2e -- $selected

