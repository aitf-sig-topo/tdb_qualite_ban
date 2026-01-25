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
# fichier de donnee
SOURCE_DIR="$BASEDIR/in/referentiel"
SOURCE_FILE="$SOURCE_DIR/referentiel_communal"

echo "decompression du fichier referentiel communal"
# ne decompresse le fichier que s'il n'existe pas déjà, et le dezippe
if [ ! -f "$SOURCE_FILE.geojson" ]; then
  echo "le fichier geojson n'existe pas --> on le decompresse"
  echo "[$(date '+%d/%m/%Y %H:%M:%S')] DECOMPRESSE $SOURCE_FILE"
  tar -xJvf "$SOURCE_FILE.tar.xz" -C "$SOURCE_DIR"
else
  echo "le fichier geojson existe déjà"
fi

# importe le fichier en base postgresql  
# -s_srs EPSG:2154 -t_srs EPSG:2154

echo ""
echo "suppression couche pré-existante"

DB_TABLE=referentiel_communal

PSQL_CMD="$PSQL_BASE_CMD -c 'DROP TABLE IF EXISTS $DB_TABLE;'"
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"


echo ""
echo "Chargement de la couche en base"

ogr2ogr_command="ogr2ogr -f \"PostgreSQL\" \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
$SOURCE_FILE.geojson -nln $DB_TABLE -lco GEOMETRY_NAME=geom_org -progress"
# echo "$ogr2ogr_command"
eval "$ogr2ogr_command"
echo "fait"
echo ""


echo ""
echo "Nettoyage de la géométrie"
# On a du polygone et et du multipolygone donc on force en multipolygone
PSQL_CMD="$PSQL_BASE_CMD -f ./sql/nettoyage_referentiel_communal.sql"
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
