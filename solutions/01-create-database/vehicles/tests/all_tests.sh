#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

TABLE="movr_vehicles.vehicles"

source ./tests/sql_testkit.sh

start_cockroachdb

execute_script "create_database.sql"

scenario "create_database.sql"
    test "should create the database"
        assert_database_exists "movr_vehicles"
    end
end

echo "ALL TESTS PASSED"

terminate_cockroachdb