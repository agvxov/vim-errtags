#!/bin/bash
self=$(readlink -f $0)
cc=$(basename $0)

set -o pipefail

next_cc=$(
    which -a $cc |
    while IFS= read -r p; do
        [ "$(readlink -f "$p")" != "$self" ] && {
            echo "$p"
            break
        }
    done
)

fifo=$(mktemp -u)
mkfifo "$fifo"

sed -e 's/\x1b\[[0-9;]*m//g' \
    -e 's/\x1b\[K//g' \
    < "$fifo" | errtags &

logger_pid=$!

tee "$fifo" < <(
    "$next_cc" -fdiagnostics-color=always "$@" 2>&1
)

cc_status=${PIPESTATUS[0]}

exec 3>&-

wait "$logger_pid"

rm -f "$fifo"

exit "$cc_status"
