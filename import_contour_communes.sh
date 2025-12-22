#!/bin/sh
set -e

# besoin de connexion postgresql
# definit paramètre base de donnée si ce n'est déjà fait
if [ -z "${POSTGRES_HOST}" ]; then
    # Paramètres de connexion à la base de données
    export POSTGRES_PORT=5432
    export POSTGRES_HOST=mon_serveur_postgres
    export POSTGRES_DB=ma_base_de_donnee
    export POSTGRES_USERNAME=monutilisateur
    export PGPASSWORD="monmotdepasse"
fi
PSQL_CMD="psql -U $POSTGRES_USERNAME -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB"

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)
# contour france entiere  :
SOURCE_URL="https://www.data.gouv.fr/api/1/datasets/r/00c0c560-3ad1-4a62-9a29-c34c98c3701e"
DB_TABLE=commune_contour
OUTPUT_FILE="$BASEDIR/in_bal_csv/commune_contour.geojson"

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

# importe le fichier en base postgresql  
# -s_srs EPSG:2154 -t_srs EPSG:2154

## enlève éventuelle données déjà présentes
eval "$PSQL_CMD -c 'truncate commune_contour'"

ogr2ogr -f "PostgreSQL" PG:"host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DB user=$POSTGRES_USERNAME password=$PGPASSWORD" "$OUTPUT_FILE" -nln $DB_TABLE  -append

# nettoie la géométrie des communes 
eval "$PSQL_CMD -f ./sql/nettoie_table_contour_commune.sql"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] END IMPORTING $DB_TABLE"



