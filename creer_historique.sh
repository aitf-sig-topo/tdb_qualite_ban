#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création d'un historique"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)


# On joue simplement une requête SQL qui va rajouter un historique
# dans la table historique

PSQL_CMD="$PSQL_BASE_CMD -f ./sql/creer_historique.sql"
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
