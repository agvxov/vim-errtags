#!/bin/bash
cc -fdiagnostics-color=always "$@" 2>&1 \
| tee >(\
        sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\x1b\[K//g' \
        | errtags
)
exit ${PIPESTATUS[0]}
