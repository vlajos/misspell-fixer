#!/usr/bin/env bash

# Compatibility wrapper for the old name.

echo "misspell-fixer has been renamed. Please use the new name: misspell-fixer"
$(dirname "$BASH_SOURCE[0]")/misspell-fixer "$@"
