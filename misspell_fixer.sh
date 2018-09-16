#!/usr/bin/env bash

# Compatibility wrapper for the old name.

echo "misspell-fixer has been renamed. Please use the new name: misspell-fixer"
current_file="${BASH_SOURCE[0]}"
dir_name=$(dirname "$current_file")
"$dir_name/misspell-fixer" "$@"
