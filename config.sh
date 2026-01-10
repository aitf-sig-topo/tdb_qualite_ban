#! /bin/bash

PG_HOST=localhost
PG_PORT=5432
PG_USERNAME=aitf_admin
PG_PASSWORD=vivelaterritoriale
PG_DB=ban

PSQL_BASE_CMD="psql -h $PG_HOST -p $PG_PORT -U $PG_USERNAME -d $PG_DB"

