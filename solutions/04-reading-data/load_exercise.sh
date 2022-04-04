#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

function help {
    echo "This command will copy the provided tests into your exercises directory."
    echo ""
    echo "USAGE: load_exercise.sh <search string>"
    echo ""
    echo "<search string>   A string that makes up all, or part, of the exercise name. Exercise numbers (eg. 01) are the simplest form of search."
    echo "WARNING:          RUNNING THIS COMMAND WILL OVERWRITE YOUR TESTS. IF YOU HAVE MADE CHANGES TO THE TESTS, YOU WILL LOSE THEM."
}

EXERCISE=${1:-}

if [ -z $EXERCISE ]
then
    help
    exit 0
fi

SUB_FOLDERS=(
    "movr/rides/src/test"
    "movr/vehicles/src/test"
    "movr/users/src/test"
    "movr/ui_gateway/src/test"
)

SOLUTION_FOLDER=../solutions

EXERCISE_FOLDER=$(find $SOLUTION_FOLDER -maxdepth 1 -type d -name "*$EXERCISE*" -print -quit)

if [ -z $EXERCISE_FOLDER ]
then
    echo "Unable to find a solution for the requested exercise: $EXERCISE"
    help
    exit 0
fi

for folder in ${SUB_FOLDERS[@]};
do
    SOLUTION=$EXERCISE_FOLDER/$folder
    EXERCISE=./$folder
    
    echo "Loading Tests from $SOLUTION to $EXERCISE"

    if [ ! -d $SOLUTION ]
    then
        echo "WARNING: Unable to find tests for in the requested folder: $SOLUTION...skipping"
    fi
  
    rm -rf $EXERCISE
    mkdir $EXERCISE
    cp -rp $SOLUTION/* $EXERCISE
done