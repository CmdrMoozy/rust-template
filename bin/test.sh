#!/usr/bin/env bash

for COMMAND in find readlink shellcheck; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"

find "$TEMPLATE_DIR" -type f -iname "*.sh" -print0 | while IFS= read -r -d $'\0' FILE; do
    echo "Testing '$FILE'..."
    shellcheck "$FILE"
done
