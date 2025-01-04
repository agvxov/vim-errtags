#!/bin/bash
ERRTAGS_SESSION=$RANDOM
export ERRTAGS_SESSION
make "$@"
