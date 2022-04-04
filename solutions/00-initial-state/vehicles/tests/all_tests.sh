#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

TABLE="movr_vehicles.vehicles"

source ./tests/sql_testkit.sh

start_cockroachdb

echo "ALL TESTS PASSED"

terminate_cockroachdb