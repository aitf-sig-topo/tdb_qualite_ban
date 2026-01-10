#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des tables"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)

# Ce script va créer les objets nécessaires dans la base de données

PSQL_CMD="$PSQL_BASE_CMD -f ./sql/create_tables.sql"
# echo "$PSQL_CMD"
eval "$PSQL_CMD"


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
