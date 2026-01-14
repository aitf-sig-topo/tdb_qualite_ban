#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche du classement communal en catégorie selon l'insee"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)


echo ""
echo "Téléchargement de la couche simplifiée data.gouv"

# téléchargement
SOURCE_URL="https://www.insee.fr/fr/statistiques/fichier/8571524/fichier_diffusion_2025.xlsx"
OUTPUT_FILE="in_bal_csv/commune_classement.xlsx"


# supprime le fichier existant (à commmenter si on souhaite conserver le fichier existant)
# rm "$OUTPUT_FILE" 

# ne retelecharge le fichier que s'il n'existe pas déjà, et le dezippe
if [ ! -f "$OUTPUT_FILE" ]; then
  echo "le fichier xlsx n'existe pas --> on le télécharge"
  # echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD $DB_TABLE"
  wget --no-clobber --progress=bar:force:noscroll -q --show-progress $SOURCE_URL -O "$OUTPUT_FILE"
  # gzip -d "$OUTPUT_FILE".gz
else
  echo "le fichier xlsx existe déjà"
fi

# importe le fichier en base postgresql  
# -s_srs EPSG:2154 -t_srs EPSG:2154

echo ""
echo "suppression couche pré-existante"

DB_TABLE=commune_classement

PSQL_CMD="$PSQL_BASE_CMD -c 'DROP TABLE IF EXISTS $DB_TABLE;'"
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"


echo ""
echo "Chargement de la couche en base"

ogr2ogr_command="ogr2ogr -f \"PostgreSQL\" \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
-skipfailures $OUTPUT_FILE -nln $DB_TABLE -sql \"SELECT  field1 as codgeo,field2 as libgeo, field3 as dens, field4 as libdens, field5 as pmun22, field6 as p1, field7 as p2, field8 as p3, field9 as dens_aav, field10 as libdens_aav,field11 as dens7,field12 as libdens7 FROM \\\"Maille communale\\\" WHERE FID >=5 \" "
echo "$ogr2ogr_command"
eval "$ogr2ogr_command"
echo "fait"
echo ""

echo ""
echo "Creation index sur code insee de la commune"
# On a du polygone et et du multipolygone donc on force en multipolygone
PSQL_CMD="$PSQL_BASE_CMD -f ./sql/nettoie_table_classement_commune.sql"
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
