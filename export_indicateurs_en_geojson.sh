#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exporte la table des indicateurs. Pour exporter aussi les indicateurs historique, rajouter l'option -hist"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)

echo "Export des indicateurs"

ogr2ogr_command="ogr2ogr -f "GeoJSON" "$BASEDIR/out/bal_indicateurs.geojson" -t_srs EPSG:4326 \
PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
bal_indicateurs"

eval "$ogr2ogr_command"

echo "fait"
echo ""

# Vérification des arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -hist)
            shift 1
            echo "Export des indicateurs historique"
            ogr2ogr_command="ogr2ogr -f "GeoJSON" "$BASEDIR/out/bal_indicateurs_hist.geojson" -t_srs EPSG:4326 \
            PG:\"host=$PG_HOST port=$PG_PORT user=$PG_USERNAME dbname=$PG_DB\" \
            bal_indicateurs_hist"
               
            eval "$ogr2ogr_command"
            
            echo "fait"
            echo ""
            
            ;; 
        *)
            echo "Option inconnue : $1"
            exit 1
            ;;
    esac
done


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
