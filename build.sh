#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

EXERCISES_FOLDER="exercises"
SOLUTIONS_FOLDER="solutions"
SOLUTIONS=($(ls $SOLUTIONS_FOLDER | grep '^[0-9]'))
SUBFOLDERS=("vehicles")
COMMAND=${1:-"help"}

function help {
    echo "This script is intended to contain the commands that can be executed to"
    echo "build various components for the course."
    echo "Custom logic for the individual course may be embedded in this script."
    echo "Re-usable logic should be put into scripts in the build-scripts folder."
    echo ""
    echo "USAGE: build.sh command <args>"
    echo ""
    echo "Commands:"
    echo "  verify - Run all tests for all exercises."
    echo "  help - print this text."
}

# Loop through each exercise and execute the tests.
function verify_all_exercises {    
    local WORKING=$(pwd)

    echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    echo VERIFYING STUDENT FOLDER $EXERCISES_FOLDER
    echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    cd $EXERCISES_FOLDER
    run_all_tests
    cd $WORKING

    for solution in "${SOLUTIONS[@]}"
    do
        echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        echo VERIFYING SOLUTION $solution
        echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        cd $SOLUTIONS_FOLDER/$solution
        run_all_tests
        cd $WORKING
    
    done
}

# Execute the tests for a specific exercise.
function run_all_tests {
    local WORKING=$(pwd)

    # NOTE This is custom logic. This course has multiple microservices and so we need to
    # execute the tests for each service individually.
    for subfolder in "${SUBFOLDERS[@]}"
    do
        echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        echo RUNNING TESTS FOR $subfolder
        echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        cd $subfolder
        pwd
        ./test.sh
        cd $WORKING
    done
}

# Determine which command is being requested, and execute it.
if [ "$COMMAND" = "verify" ]; then
    verify_all_exercises
elif [ "$COMMAND" = "help" ]; then
    help
else
    echo "INVALID COMMAND: $COMMAND"
    help
    exit 1
fi
