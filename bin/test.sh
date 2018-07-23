#!/usr/bin/env bash

for COMMAND in find shellcheck; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

BASE_DIR="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")"
cd "$BASE_DIR" || exit 1

find "$BASE_DIR" -type f -iname "*.sh" -print0 | while IFS= read -r -d $'\0' FILE; do
    echo "Testing '$FILE'..."
    shellcheck "$FILE"
done
