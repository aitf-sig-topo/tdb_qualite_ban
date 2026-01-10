#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Calcul des indicateurs de qualité"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)


# Initialisation de la variable BAL_TO_TREAT
BAL_TO_TREAT="france"

# Vérification des arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -dpt)
            if [ -n "$2" ]; then
                BAL_TO_TREAT="$2"
                shift 2
            else
                echo "Erreur : L'argument pour -dpt est manquant."
                exit 1
            fi
            ;;
        *)
            echo "Option inconnue : $1"
            exit 1
            ;;
    esac
done

if [ "$BAL_TO_TREAT" = "france" ]; then
    echo "On va travailler sur la France entière"
else
    echo "On va travailler sur le département $BAL_TO_TREAT"
fi


echo ""

# script SQL de creation des indicateur
PSQL_CMD="$PSQL_BASE_CMD -f ./sql/create_table_bal_indicateurs.sql"
echo "$PSQL_CMD"
eval "$PSQL_CMD"


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
