#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Execute in a subshell to maintain the working directory.
(
    cd vehicles
    ./test.sh
)