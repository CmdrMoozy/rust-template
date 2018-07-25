#!/usr/bin/env bash

for COMMAND in cargo cut grep jq readlink; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

TYPE="$1"
if [[ "$TYPE" != "test" && "$TYPE" != "bench" ]]; then
    echo "Invalid binary type '$TYPE'; usage: '$0 [test|bench]'."
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
while [[ ! -f "$PROJECT_DIR/Cargo.toml" ]]; do
    if [[ "$PROJECT_DIR" == "/" ]]; then
        echo "Failed to locate project's Cargo.toml."
        exit 1
    fi
    PROJECT_DIR="$(dirname "$PROJECT_DIR")"
done

cd "$PROJECT_DIR" || exit 1
cargo "$TYPE" --no-run --message-format=json 2>/dev/null | \
        jq -r "select(.profile.test == true) | .filenames[]" | \
        while read -r BINARY_PATH ; do
    TEST_COUNT=$("$BINARY_PATH" --list | grep -P '^\d+ tests, \d+ benchmarks$' | cut -d ' ' -f 1)
    BENCH_COUNT=$("$BINARY_PATH" --list | grep -P '^\d+ tests, \d+ benchmarks$' | cut -d ' ' -f 3)

    if [[ "$TYPE" == "bench"  && "$BENCH_COUNT" == "" ]]; then
        # Running benchmarks on stable Rust happens with the bencher crate, but this
        # crate doesn't support the --list option, so $BENCH_COUNT would just be the
        # empty string. Detect this case, and replace it with a 1, to include this
        # binary as a fallback.
        BENCH_COUNT=1
    fi

    # Skip binaries which have 0 tests | benchmarks (depending on $TYPE).
    if [[ "$TYPE" == "test" && "$TEST_COUNT" -lt 1 ]]; then
        continue
    elif [[ "$TYPE" == "bench" && "$BENCH_COUNT" -lt 1 ]]; then
        continue
    fi

    echo "$BINARY_PATH"
done
