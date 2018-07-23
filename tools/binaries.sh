#!/usr/bin/env bash

for COMMAND in cargo cut grep jq; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

BASE_DIR="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )")"
cd "$BASE_DIR" || exit 1

TYPE="$1"
if [[ "$TYPE" != "test" && "$TYPE" != "bench" ]]; then
    echo "Invalid binary type '$TYPE'; usage: '$0 [test|bench]'."
    exit 1
fi

cargo "$TYPE" --no-run --message-format=json 2>/dev/null | \
        jq -r "select(.profile.test == true) | .filenames[]" | \
        while read -r BINARY_PATH ; do
    TEST_COUNT=$("$BINARY_PATH" --list | grep -P '^\d+ tests, \d+ benchmarks$' | cut -d ' ' -f 1)
    BENCH_COUNT=$("$BINARY_PATH" --list | grep -P '^\d+ tests, \d+ benchmarks$' | cut -d ' ' -f 3)

    # Skip binaries which have 0 tests | benchmarks (depending on $TYPE).
    if [[ "$TYPE" == "test" && "$TEST_COUNT" -lt 1 ]]; then
        continue
    elif [[ "$TYPE" == "bench" && "$BENCH_COUNT" -lt 1 ]]; then
        continue
    fi

    echo "$BINARY_PATH"
done
