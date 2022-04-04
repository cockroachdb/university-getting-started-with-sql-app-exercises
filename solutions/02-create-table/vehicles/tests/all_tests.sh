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

scenario "create_table.sql"
    execute_script "create_table.sql"
    load_table_definition $TABLE

    test "should correctly define the id"
        assert_column_defined "id"
        assert_column_type "id" "UUID"
        assert_column_is_not_nullable "id"
        assert_column_default "id" "gen_random_uuid()"
    end

    test "should correctly define the vehicle_type"
        assert_column_defined "vehicle_type"
        assert_column_type "vehicle_type" "STRING"
        assert_column_is_not_nullable "vehicle_type"
    end

    test "should correctly define the purchase_date"
        assert_column_defined "purchase_date"
        assert_column_type "purchase_date" "DATE"
        assert_column_is_not_nullable "purchase_date"
        assert_column_default "purchase_date" "current_date()"
    end

    test "should correctly define the serial_number"
        assert_column_defined "serial_number"
        assert_column_type "serial_number" "STRING"
        assert_column_is_not_nullable "serial_number"
    end

    test "should correctly define the make"
        assert_column_defined "make"
        assert_column_type "make" "STRING"
        assert_column_is_not_nullable "make"
    end

    test "should correctly define the model"
        assert_column_defined "model"
        assert_column_type "model" "STRING"
        assert_column_is_not_nullable "model"
    end

    test "should correctly define the year"
        assert_column_defined "year"
        assert_column_type "year" "INT2"
        assert_column_is_not_nullable "year"
    end

    test "should correctly define the color"
        assert_column_defined "color"
        assert_column_type "color" "STRING"
        assert_column_is_not_nullable "color"
    end

    test "should correctly define the description."
        assert_column_defined "description"
        assert_column_type "description" "STRING"
        assert_column_is_nullable "description"
    end

    test "should correctly define the primary key"
        assert_primary_key "id ASC"
    end
end

echo "ALL TESTS PASSED"

terminate_cockroachdb