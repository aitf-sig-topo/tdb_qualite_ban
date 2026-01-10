#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche du référentiel communal"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)


echo ""
echo "Téléchargement de la couche simplifiée data.gouv"

# téléchargement
SOURCE_URL="https://www.data.gouv.fr/api/1/datasets/r/00c0c560-3ad1-4a62-9a29-c34c98c3701e"
OUTPUT_FILE="in_bal_csv/commune_contour.geojson"


# supprime le fichier existant (à commmenter si on souhaite conserver le fichier existant)
# rm "$OUTPUT_FILE" 

# ne retelecharge le fichier que s'il n'existe pas déjà, et le dezippe
if [ ! -f "$OUTPUT_FILE" ]; then
  echo "le fichier geojson n'existe pas --> on le télécharge"
  # echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD $DB_TABLE"
  wget --no-clobber --progress=bar:force:noscroll -q --show-progress $SOURCE_URL -O "$OUTPUT_FILE"
  # gzip -d "$OUTPUT_FILE".gz
else
  echo "le fichier geojson existe déjà"
fi

# importe le fichier en base postgresql  
# -s_srs EPSG:2154 -t_srs EPSG:2154

echo ""
echo "suppression couche pré-existante"

DB_TABLE=commune_contour

PSQL_CMD="$PSQL_BASE_CMD -c 'DROP TABLE IF EXISTS $DB_TABLE;'"
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"


echo ""
echo "Chargement de la couche en base"

ogr2ogr_command="ogr2ogr -f \"PostgreSQL\" \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
$OUTPUT_FILE -nln $DB_TABLE -lco GEOMETRY_NAME=geom_org -progress"
# echo "$ogr2ogr_command"
eval "$ogr2ogr_command"
echo "fait"
echo ""


echo ""
echo "Nettoyage de la géométrie"
# On a du polygone et et du multipolygone donc on force en multipolygone
PSQL_CMD="$PSQL_BASE_CMD -f ./sql/nettoie_table_contour_commune.sql"
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
