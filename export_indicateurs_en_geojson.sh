#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exporte la table des indicateurs et celle des indicateurs historiques"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)

ogr2ogr_command="ogr2ogr -f "GeoJSON" "$BASEDIR/out/bal_indicateurs.geojson" -t_srs EPSG:4326 \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
bal_indicateurs"

ogr2ogr_command="ogr2ogr -f "GeoJSON" "$BASEDIR/out/bal_indicateurs_hist.geojson" -t_srs EPSG:4326 \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
bal_indicateurs_hist"

# echo "$ogr2ogr_command"
eval "$ogr2ogr_command"

echo "fait"
echo ""


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
