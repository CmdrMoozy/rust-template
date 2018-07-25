#!/usr/bin/env bash

for COMMAND in kcov pgrep readlink; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
while [[ ! -f "$PROJECT_DIR/Cargo.toml" ]]; do
    if [[ "$PROJECT_DIR" == "/" ]]; then
        echo "Failed to locate project's Cargo.toml."
        exit 1
    fi
    PROJECT_DIR="$(dirname "$PROJECT_DIR")"
done

CHROME=$(command -v google-chrome-stable || echo -n "/dev/null")
FIREFOX=$(command -v firefox || echo -n "/dev/null")

"$SCRIPT_DIR/binaries.sh" test | while read -r BINARY_PATH; do
    BINARY="$(basename "$BINARY_PATH")"
    COVERAGE_DIR="$PROJECT_DIR/target/cov/$BINARY"
    COVERAGE_REPORT="$COVERAGE_DIR/index.html"

    mkdir -p "$COVERAGE_DIR" || exit 1
    kcov \
        --verify \
        --include-path="$PROJECT_DIR/src" \
        --exclude-path="$PROJECT_DIR/src/tests" \
        "$COVERAGE_DIR" \
        "$BINARY_PATH" || exit 1

    if [[ -x "$CHROME" ]] && pgrep -x "$(basename "$CHROME")" > /dev/null; then
        echo "Opening coverage report in Chrome."
        "$CHROME" "$COVERAGE_REPORT" chrome://newtab/
    elif [[ -x "$FIREFOX" ]] && pgrep -x "$(basename "$FIREFOX")" > /dev/null; then
        echo "Opening coverage report in Firefox."
        "$FIREFOX" -new-tab -url "$COVERAGE_REPORT"
    else
        echo "Coverage report: $COVERAGE_REPORT"
    fi
done
