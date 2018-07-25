#!/usr/bin/env bash

for COMMAND in flamegraph grep perf pgrep readlink stackcollapse-perf; do
    if ! command -v "$COMMAND" > /dev/null; then
        echo "Required command '$COMMAND' not found"
        exit 1
    fi
done

>&2 echo "This tool requires the following in Cargo.toml:"
>&2 echo "[profile.release]"
>&2 echo "debug = true"
>&2 echo "lto = false"

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

"$SCRIPT_DIR/binaries.sh" bench | while read -r BINARY_PATH; do
    BINARY="$(basename "$BINARY_PATH")"
    PERF_DIR="$PROJECT_DIR/target/perf/$BINARY"
    PERF_RECORDING="$PERF_DIR/perf.data"
    FLAMEGRAPH="$PERF_DIR/flamegraph.svg"

    mkdir -p "$PERF_DIR" || exit 1

    perf record \
        -g \
        -o "$PERF_RECORDING" \
        --call-graph=dwarf \
        "$BINARY_PATH" --bench "$@"

    perf script \
        -i "$PERF_RECORDING" | \
        stackcollapse-perf | \
        flamegraph > "$FLAMEGRAPH"

    if [[ -x "$CHROME" ]] && pgrep -x "$(basename "$CHROME")" > /dev/null; then
        echo "Opening flamegraph in Chrome."
        "$CHROME" "$FLAMEGRAPH" chrome://newtab/
    elif [[ -x "$FIREFOX" ]] && pgrep -x "$(basename "$FIREFOX")" > /dev/null; then
        echo "Opening flamegraph in Firefox."
        "$FIREFOX" -new-tab -url "$FLAMEGRAPH"
    else
        echo "Flamegraph: $FLAMEGRAPH"
    fi
done
