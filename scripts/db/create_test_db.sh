#!/bin/bash

./scripts/db/import_db.sh -H localhost -P 3306 -u test_bot -p pass -d test_results_db -l ./migration-0.sql
