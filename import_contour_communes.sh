#!/bin/sh
set -e

# lecture du fichier de configuration
. config.sh

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
echo "suppression table des communes"
psql_command="psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -c 'DROP TABLE IF EXISTS commune_contour;'"
eval "$psql_command"
echo "fait"


echo "chargement de la couche des communes"
ogr2ogr_command="ogr2ogr -f \"PostgreSQL\" \
PG:\"host=$POSTGRES_HOST port=$POSTGRES_PORT user=$POSTGRES_USERNAME password=$PGPASSWORD dbname=$POSTGRES_DB\" \
$OUTPUT_FILE -nln $DB_TABLE -lco GEOMETRY_NAME=geom_org"
eval "$ogr2ogr_command"
echo "chargement fait"


# nettoie la géométrie des communes 
eval "psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DB -f ./sql/nettoie_table_contour_commune.sql"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] END IMPORTING $DB_TABLE"


