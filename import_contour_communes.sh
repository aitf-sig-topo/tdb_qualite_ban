#!/bin/sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)
# contour france entiere  :
SOURCE_URL="https://www.data.gouv.fr/api/1/datasets/r/00c0c560-3ad1-4a62-9a29-c34c98c3701e"
DB_TABLE=commune_contour
OUTPUT_FILE="$BASEDIR/in_bal_csv/commune_contour.geojson"
# acces base de données postgresql (a décommenter et renseigner)
POSTGRES_PORT=5432
# POSTGRES_HOST=mon_serveur_postgres
# POSTGRES_DB=ma_base_de_donnee
# POSTGRES_USERNAME=monutilisateur
# export PGPASSWORD="monmotdepasse"

export PSQL_CMD="psql -U $POSTGRES_USERNAME -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB"


echo "[$(date '+%d/%m/%Y %H:%M:%S')] START IMPORTING $DB_TABLE"

# supprime le fichier existant (à commmenter si on souhaite conserver le fichier existant)
# rm "$OUTPUT_FILE" 

# ne retelecharge le fichier que s'il n'existe pas déjà, et le dezippe
if [ ! -f "$OUTPUT_FILE" ]; then
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD $DB_TABLE"
	wget --no-clobber --progress=bar:force:noscroll -q --show-progress $SOURCE_URL -O "$OUTPUT_FILE"
  #      gzip -d "$OUTPUT_FILE".gz
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD FINISHED $DB_TABLE"
fi

# cree la table si elle n'existe pas dejà
# eval "$PSQL_CMD -f ./sql/create_table_bal.sql"

# importe le fichier en base postgresql
ogr2ogr -f "PostgreSQL" PG:"host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DB user=$POSTGRES_USERNAME password=$PGPASSWORD" "$OUTPUT_FILE" -nln $DB_TABLE -append

# echo "$PSQL_CMD -c '\copy $DB_TABLE FROM $OUTPUT_FILE WITH (delimiter \";\", format csv, header true)'"
# eval "$PSQL_CMD -c '\copy $DB_TABLE FROM $OUTPUT_FILE WITH (delimiter \";\", format csv, header true)'"
# echo "[$(date '+%d/%m/%Y %H:%M:%S')] END IMPORTING $DB_TABLE"



