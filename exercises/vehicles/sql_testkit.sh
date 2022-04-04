#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

COCKROACH_URL="postgresql://root@localhost:26257/defaultdb?sslmode=disable"
COCKROACH_DATA_DIR="./cockroach_db_tmp_store"
COCKROACH_COMMAND="cockroach start-single-node --insecure --store '$COCKROACH_DATA_DIR'"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_NONE='\033[0m'

TABLE_HEADERS=()
TABLE_DATA=()
TABLE_ROW_COUNT=0
TABLE_COL_COUNT=0

CURRENT_SCENARIO=""
CURRENT_TEST=""
INDENT_LEVEL=0

# LOGGING
log() {
    if [[ $INDENT_LEVEL == 0 ]]; then
        echo -e "$1"
    else
        LOG_PREFIX=$(head -c $INDENT_LEVEL < /dev/zero | tr '\0' '\t') # Create a number of tabs dependent on the indent level.
        echo -e "$LOG_PREFIX$1"
    fi
}

# RUN COCKROACHDB

_get_cockroach_pid() {
    local PID=$(pgrep -f "$COCKROACH_DATA_DIR")

    echo $PID
}

start_cockroachdb() {
    log "-----------------------"
    log "STARTING COCKROACHDB"
    log "-----------------------"

    local PID=$(_get_cockroach_pid)

    if [[ $PID != "" ]]; then
        log "PREVIOUS INSTANCE OF COCKROACH WAS NOT TERMINATED CORRECTLY. TERMINATING AND CLEANING UP."
        terminate_cockroachdb
    fi

    rm -rf $COCKROACH_DATA_DIR

    mkdir -p ./test_tmp
    eval "$COCKROACH_COMMAND &"

    local ATTEMPTS=0
    
    until cockroach sql --url "$COCKROACH_URL" --execute "SHOW DATABASES;" &> /dev/null
    do
        ATTEMPTS=$(($ATTEMPTS + 1))
        log "WAITING FOR COCKROACHDB"
        
        if [ $ATTEMPTS -ge 5 ]; then
            log "UNABLE TO START COCKROACHDB"
            exit 1
        else
            log "WAITING FOR COCKROACHDB"
            local SLEEP_TIME=$((1 * $ATTEMPTS))
            sleep $SLEEP_TIME
        fi
    done

    log "-----------------------"
    log "COCKROACHDB IS RUNNING"
    log "-----------------------"
}

terminate_cockroachdb() {
    log "-----------------------"
    log "TERMINATING COCKROACHDB"
    log "-----------------------"

    local PID=$(_get_cockroach_pid)
    kill -9 $PID
    rm -rf $COCKROACH_DATA_DIR
}

# LOAD/EXECUTE SQL

execute_script() {
    local SCRIPT=$1

    local RESULTS=$(cockroach sql --url $COCKROACH_URL < $SCRIPT)
    success "EXECUTED $SCRIPT"
    log ""
}

load_from_query() {
    local QUERY=$1

    local ROWS=($(cockroach sql --url $COCKROACH_URL --execute "$QUERY" --format csv))
    
    SAVEIFS=$IFS
    IFS=$','

    TABLE_HEADERS=(${ROWS[0]})
    unset ROWS[0]
    
    TABLE_ROW_COUNT=${#ROWS[@]}
    TABLE_COL_COUNT=${#TABLE_HEADERS[@]}

    TABLE_DATA=()
    
    for ROW in "${ROWS[@]}"
    do 
        VALUES=($ROW)
        
        local ROW_DATA=""

        for COL in "${!TABLE_HEADERS[@]}"
        do 
            ROW_DATA="$ROW_DATA|${TABLE_HEADERS[$COL]}=${VALUES[$COL]}"
        done

        TABLE_DATA+=($ROW_DATA)

    done

    IFS=$SAVEIFS
}

load_table_definition() {
    local COCKROACH_TABLE=$1

    load_from_query "SHOW COLUMNS FROM $COCKROACH_TABLE;"

    local CREATE_TABLE=$(cockroach sql --url $COCKROACH_URL --execute "SHOW CREATE TABLE $COCKROACH_TABLE;")
    local REGEX=".* PRIMARY KEY \((.*)\),.*"

    if [[ $CREATE_TABLE =~ $REGEX ]]
    then
        TABLE_PRIMARY_KEY="${BASH_REMATCH[1]}"
    else
        log "NO PRIMARY KEY FOUND"
    fi
}

load_table_data() {
    local COCKROACH_TABLE=$1
    local MAX_ROWS=$2

    load_from_query "SELECT * FROM $COCKROACH_TABLE LIMIT $MAX_ROWS;"
}

load_table_indexes() {
    local COCKROACH_TABLE=$1

    load_from_query "SHOW INDEXES FROM $COCKROACH_TABLE;"
}

load_query_results_from_file() {
    local FILE=$1
    local QUERY=$(<$FILE)

    load_from_query "$QUERY"
}

# RETRIEVE RECORDS

get_column_index() {
    local COLUMN=$1

    for i in "${!TABLE_HEADERS[@]}"; do
        if [[ "${TABLE_HEADERS[$i]}" == "$COLUMN" ]]; then
            echo $i
            return 0
        fi
    done

    echo -1
}

get_index_of() {
    local COLUMN=$1
    local VALUE=$2

    for i in "${!TABLE_DATA[@]}"; do
        if [[ ${TABLE_DATA[$i]} == *"$COLUMN=$VALUE"* ]]; then
            echo $i
            return 0
        fi
    done

    echo -1;
}

get_value_of() {
    local ROW=$1
    local COLUMN=$2

    local ROW_DATA=${TABLE_DATA[$ROW]}

    SAVEIFS=$IFS
    IFS=$'|'
    ENTRIES=($ROW_DATA)
    IFS=$SAVEIFS

    for ENTRY in "${ENTRIES[@]}"; do
        local KEY=$(echo $ENTRY | cut -d '=' -f 1)
        local VALUE=$(echo $ENTRY | cut -d '=' -f 2)

        if [[ $KEY == $COLUMN ]]; then
            echo $VALUE
            return 0
        fi
    done

    echo -1
}

# TEST FIXTURES

scenario() {
    if [[ $CURRENT_SCENARIO != "" ]]; then
        fail "THE PREVIOUS SCENARIO WAS NOT ENDED: $CURRENT_SCENARIO"
    fi

    CURRENT_SCENARIO=$1
    log "${COLOR_BLUE}SCENARIO:${COLOR_NONE} $CURRENT_SCENARIO"
    log ""
    INDENT_LEVEL=$(($INDENT_LEVEL + 1))
}

test() {
    if [[ $CURRENT_TEST != "" ]]; then
        fail "THE PREVIOUS TEST WAS NOT ENDED: $CURRENT_TEST"
    fi

    CURRENT_TEST=$1
    log "${COLOR_BLUE}TEST:${COLOR_NONE} $CURRENT_TEST"
    INDENT_LEVEL=$(($INDENT_LEVEL + 1))
}

end() {
    if [[ $CURRENT_TEST != "" ]]; then
        INDENT_LEVEL=$(($INDENT_LEVEL - 1))
        log "${COLOR_BLUE}END:${COLOR_NONE} $CURRENT_TEST"
        log ""
        CURRENT_TEST=""    
    elif [[ $CURRENT_SCENARIO != "" ]]; then
        INDENT_LEVEL=$(($INDENT_LEVEL - 1))
        log "${COLOR_BLUE}END:${COLOR_NONE} $CURRENT_SCENARIO"
        log ""
        CURRENT_SCENARIO="" 
    else
        fail "NO SCENARIO OR TEST WAS STARTED"
    fi
}

fail() {
    MESSAGE=$1

    log "${COLOR_RED}FAILURE - $MESSAGE${COLOR_NONE}"
    INDENT_LEVEL=0
    terminate_cockroachdb
    exit 1
}

success() {
    MESSAGE=$1

    log "${COLOR_GREEN}SUCCESS - $MESSAGE${COLOR_NONE}"
}

# GENERIC ASSERTIONS

assert_equals() {
    local INDEX=$1
    local COLUMN=$2
    local EXPECTED_VALUE=$3
    local MESSAGE=${4:-"assert_equals: $COLUMN == $EXPECTED_VALUE AT INDEX $1"}

    local ACTUAL_VALUE=$(get_value_of $INDEX $COLUMN)

    if [[ $ACTUAL_VALUE == $EXPECTED_VALUE ]]; then
        success "$MESSAGE"
    else
        fail "$MESSAGE"
    fi
}

assert_not_equals() {
    local INDEX=$1
    local COLUMN=$2
    local EXPECTED_VALUE=$3
    local MESSAGE=${4:-"assert_not_equals: $COLUMN != $EXPECTED_VALUE AT INDEX $1"}

    local ACTUAL_VALUE=$(get_value_of $INDEX $COLUMN)

    if [[ $ACTUAL_VALUE == $EXPECTED_VALUE ]]; then
        fail "$MESSAGE"
    else
        success "$MESSAGE"
    fi
}

assert_not_null() {
    local INDEX=$1
    local COLUMN=$2
    local MESSAGE=${4:-"assert_not_null: $COLUMN != NULL AT INDEX $1"}

    assert_not_equals "$INDEX" "$COLUMN" "NULL" "$MESSAGE"
}

assert_null() {
    local INDEX=$1
    local COLUMN=$2
    local MESSAGE=${4:-"assert_null: $COLUMN == NULL AT INDEX $1"}

    assert_equals "$INDEX" "$COLUMN" "NULL" "$MESSAGE" 
}

assert_column_exists() {
    local COLUMN=$1
    local MESSAGE=${2:-"assert_column_exists: $COLUMN EXISTS"}

    for i in "${!TABLE_HEADERS[@]}"; do
        if [[ "${TABLE_HEADERS[$i]}" == "$COLUMN" ]]; then
            success "$MESSAGE"
            return 0        
        fi
    done

    fail "$MESSAGE"
}

assert_column_does_not_exist() {
    local COLUMN=$1
    local MESSAGE=${2:-"assert_column_does_not_exist: $COLUMN DOES NOT EXIST"}

    for i in "${!TABLE_HEADERS[@]}"; do
        if [[ "${TABLE_HEADERS[$i]}" == "$COLUMN" ]]; then
            fail "$MESSAGE"
        fi
    done

    success "$MESSAGE"
    return 0
}

assert_record_exists() {
    local COLUMN=$1
    local VALUE=$2
    local MESSAGE=${3:-"assert_record_exists: RECORD EXISTS WHERE $COLUMN == $VALUE"}
    
    local INDEX=$(get_index_of $COLUMN $VALUE)

    if [[ $INDEX != -1 ]]; then
        success "$MESSAGE"
    else
        fail "$MESSAGE"
    fi
}

assert_row_count_equals() {
    local EXPECTED_COUNT=$1
    local MESSAGE="assert_row_count_equals: ROW COUNT EQUALS $EXPECTED_COUNT"

    if [[ $TABLE_ROW_COUNT != $EXPECTED_COUNT ]]; then
        fail "$MESSAGE"
    fi

    success "$MESSAGE"
    return 0
}

# TABLE DEFINITION ASSERTIONS

assert_column_defined() {
    local COLUMN=$1

    assert_record_exists "column_name" "$COLUMN" "assert_column_defined: COLUMN $COLUMN IS DEFINED"
}

assert_column_type() {
    local COLUMN=$1
    local TYPE=$2

    local INDEX=$(get_index_of "column_name" $COLUMN) 

    assert_equals "$INDEX" "data_type" "$TYPE" "assert_column_type: COLUMN $COLUMN HAS TYPE $2"
}

assert_column_is_nullable() {
    local COLUMN=$1  

    local INDEX=$(get_index_of "column_name" $COLUMN) 

    assert_equals "$INDEX" "is_nullable" "true" "assert_column_is_nullable: COLUMN $COLUMN IS NULLABLE"
}

assert_column_is_not_nullable() {
    local COLUMN=$1  

    local INDEX=$(get_index_of "column_name" $COLUMN) 

    assert_equals "$INDEX" "is_nullable" "false" "assert_column_is_not_nullable: COLUMN $COLUMN IS NOT NULLABLE"
}

assert_column_default() {
    local COLUMN=$1  
    local DEFAULT=$2

    local INDEX=$(get_index_of "column_name" $COLUMN) 

    assert_equals "$INDEX" "column_default" "$DEFAULT" "assert_column_default: COLUMN $COLUMN HAS DEFAULT VALUE $DEFAULT"
}

assert_primary_key() {
    local KEY=$1
    local MESSAGE="assert_primary_key: PRIMARY KEY EXISTS FOR $KEY"
    
    if [[ "$TABLE_PRIMARY_KEY" == "$KEY" ]]; then
        success "$MESSAGE"
        return 0;
    fi

    fail "$MESSAGE"
}

# DATABASE DEFINITION ASSERTIONS

assert_database_exists() {
    local DATABASE=$1
    local MESSAGE="assert_database_exists: DATABASE $DATABASE EXISTS"

    local RESULTS=$(cockroach sql --url $COCKROACH_URL --execute "SHOW DATABASES;")

    if [[ "$RESULTS" == *"$DATABASE"* ]]; then
        success "$MESSAGE"
        return 0
    fi

    fail "$MESSAGE"
}

# INDEX ASSERTIONS

assert_index_exists() {
    local INDEX_NAME=$1
    local NON_UNIQUE=$2
    local SEQUENCE_NUMBER=$3
    local COLUMN_NAME=$4
    local DIRECTION=$5
    local MESSAGE="assert_index_exists: INDEX EXISTS NAMED $INDEX_NAME WITH NON_UNIQUE=$NON_UNIQUE, SEQUENCE_NUMBER=$SEQUENCE_NUMBER, COLUMN=$COLUMN_NAME, DIRECTION=$DIRECTION"

    for ROW in "${TABLE_DATA[@]}"; do
        if [[ "$ROW" == *"index_name=$INDEX_NAME|non_unique=$NON_UNIQUE|seq_in_index=$SEQUENCE_NUMBER|column_name=$COLUMN_NAME|direction=$DIRECTION|"* ]]; then
            success "$MESSAGE"
            return 0
        fi
    done

    fail "$MESSAGE"
}
