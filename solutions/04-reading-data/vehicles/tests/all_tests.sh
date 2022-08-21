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
end

scenario "insert.sql"
    execute_script "insert.sql"
    load_table_data $TABLE 6

    test "should insert the first record with some predefined values"
        INDEX=$(get_index_of "id" "03d0a3a4-ae36-4178-819c-0c1b08e59afc")
        assert_equals $INDEX "id" "03d0a3a4-ae36-4178-819c-0c1b08e59afc"
        assert_equals $INDEX "vehicle_type" "Scooter"
        assert_equals $INDEX "purchase_date" "2022-03-07"
        assert_equals $INDEX "serial_number" "SC9757543886484387"
        assert_equals $INDEX "make" "Spitfire"
        assert_equals $INDEX "model" "Inferno"
        assert_equals $INDEX "year" "2021"
        assert_equals $INDEX "color" "Red"
        assert_equals $INDEX "description" "Scratch on the left side"
    end

    test "should insert the second record with some predefined values"
        INDEX=$(get_index_of "id" "648aefea-9fbc-11ec-b909-0242ac120002")
        assert_equals $INDEX "id" "648aefea-9fbc-11ec-b909-0242ac120002"
        assert_equals $INDEX "vehicle_type" "Skateboard"
        assert_not_null $INDEX "purchase_date"
        assert_equals $INDEX "serial_number" "SB6694627626486622"
        assert_equals $INDEX "make" "Street Slider"
        assert_equals $INDEX "model" "Motherboard"
        assert_equals $INDEX "year" "2020"
        assert_equals $INDEX "color" "Slate Grey"
        assert_null $INDEX "description"
    end

    test "should insert only 5 records"
        assert_row_count_equals 5
    end
end

scenario "select_all.sql"
    load_from_query "$(<select_all.sql)"

    test "should return all 5 records."
        assert_row_count_equals 5
    end

    test "should return the correct first record"
        INDEX=$(get_index_of "id" "03d0a3a4-ae36-4178-819c-0c1b08e59afc")
        assert_equals $INDEX "id" "03d0a3a4-ae36-4178-819c-0c1b08e59afc"
        assert_equals $INDEX "vehicle_type" "Scooter"
        assert_equals $INDEX "make" "Spitfire"
        assert_equals $INDEX "model" "Inferno"
        assert_equals $INDEX "color" "Red"
        assert_column_does_not_exist "purchase_datex"
        assert_column_does_not_exist "serial_number"
        assert_column_does_not_exist "year"
        assert_column_does_not_exist "description"
    end
end

echo "ALL TESTS PASSED"

terminate_cockroachdb